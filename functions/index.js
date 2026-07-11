const { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ─────────────────────────────────────────────────────────────────────────────
// AUTH: Create user document on first sign-in (callable via HTTPS trigger)
// Called from the Flutter app immediately after Firebase.createUserWithEmailAndPassword
// or signInWithGoogle succeeds for the first time.
// ─────────────────────────────────────────────────────────────────────────────
exports.initUserDocument = onRequest({ cors: false }, async (req, res) => {
  const { uid, displayName } = req.body;
  if (!uid) { res.status(400).json({ error: 'uid required' }); return; }

  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  if (snap.exists) { res.json({ status: 'already_exists' }); return; }

  await ref.set({
    uid,
    displayName: displayName || 'Player',
    avatarId: 'default',
    level: 1,
    totalScore: 0,
    worldRank: 0,
    matchesPlayed: 0,
    currentStreak: 0,
    bestStreak: 0,
    dailySortDate: null,
    dailySortScore: 0,
    clubIds: [],
    primaryClubId: null,
    createdAt: FieldValue.serverTimestamp(),
  });

  res.json({ status: 'created' });
});

// ─────────────────────────────────────────────────────────────────────────────
// VERSUS: Push notification when a challenge is created
// ─────────────────────────────────────────────────────────────────────────────
exports.onChallengeCreated = onDocumentCreated(
  'challenges/{challengeId}',
  async (event) => {
    const challenge = event.data.data();
    const { opponentUid, challengerName } = challenge;

    const opponentSnap = await db.collection('users').doc(opponentUid).get();
    if (!opponentSnap.exists) return;

    const fcmToken = opponentSnap.data().fcmToken;
    if (!fcmToken) return;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '⚡ VS Challenge!',
          body: `${challengerName} wants to battle you. Accept now!`,
        },
        data: {
          type: 'challenge',
          challengeId: event.params.challengeId,
        },
        apns: { payload: { aps: { sound: 'default' } } },
        android: { notification: { sound: 'default' } },
      });
    } catch (e) {
      console.error('FCM send failed:', e);
    }
  }
);

// VERSUS: Push notification when a rematch is requested
exports.onRematchRequested = onDocumentUpdated(
  'challenges/{challengeId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only fire when rematchRequestedBy is newly set
    if (before.rematchRequestedBy || !after.rematchRequestedBy) return;

    const requestedBy = after.rematchRequestedBy;
    const { challengerUid, opponentUid, challengerName, opponentName } = after;

    const notifyUid = requestedBy === challengerUid ? opponentUid : challengerUid;
    const requesterName = requestedBy === challengerUid ? challengerName : opponentName;

    const userSnap = await db.collection('users').doc(notifyUid).get();
    if (!userSnap.exists) return;

    const fcmToken = userSnap.data().fcmToken;
    if (!fcmToken) return;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🔄 Rematch!',
          body: `${requesterName} wants a rematch. Accept in VS!`,
        },
        data: { type: 'rematch', challengeId: event.params.challengeId },
        apns: { payload: { aps: { sound: 'default' } } },
        android: { notification: { sound: 'default' } },
      });
    } catch (e) {
      console.error('FCM rematch send failed:', e);
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// MATCH: Fan out score when a match document is created
// ─────────────────────────────────────────────────────────────────────────────
exports.onMatchComplete = onDocumentCreated(
  'users/{uid}/matches/{matchId}',
  async (event) => {
    const match = event.data.data();
    const uid = event.params.uid;
    const { scoreDelta, isDailySort, streakAtEnd, playedAt, finalScore } = match;

    const userRef = db.collection('users').doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) return;

    const user = userSnap.data();
    const newBest = Math.max(user.bestStreak || 0, streakAtEnd || 0);

    const userUpdate = {
      totalScore: FieldValue.increment(scoreDelta),
      matchesPlayed: FieldValue.increment(1),
      currentStreak: streakAtEnd || 0,
      bestStreak: newBest,
    };

    if (isDailySort) {
      userUpdate.dailySortDate = playedAt;
      userUpdate.dailySortScore = finalScore || scoreDelta;
    }

    await userRef.update(userUpdate);

    // Fan out score increment to every club the user belongs to
    const clubIds = user.clubIds || [];
    await Promise.all(
      clubIds.map((clubId) =>
        db.collection('clubs').doc(clubId)
          .collection('members').doc(uid)
          .update({ clubScore: FieldValue.increment(scoreDelta) })
          .catch(() => {})
      )
    );
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// CLUBS: Keep memberCount accurate on join / leave
// ─────────────────────────────────────────────────────────────────────────────
exports.onMemberJoin = onDocumentCreated(
  'clubs/{clubId}/members/{uid}',
  async (event) => {
    await db.collection('clubs').doc(event.params.clubId).update({
      memberCount: FieldValue.increment(1),
    });
  }
);

exports.onMemberLeave = onDocumentDeleted(
  'clubs/{clubId}/members/{uid}',
  async (event) => {
    const { clubId, uid } = event.params;
    await db.collection('clubs').doc(clubId).update({
      memberCount: FieldValue.increment(-1),
    });
    await db.collection('users').doc(uid).update({
      clubIds: FieldValue.arrayRemove(clubId),
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// RANKS: Recompute world ranks every 5 minutes
// ─────────────────────────────────────────────────────────────────────────────
exports.recomputeWorldRanks = onSchedule('every 5 minutes', async () => {
  const snap = await db
    .collection('users')
    .orderBy('totalScore', 'desc')
    .limit(500)
    .get();

  const BATCH_LIMIT = 490;
  let batch = db.batch();
  let opCount = 0;

  for (let i = 0; i < snap.docs.length; i++) {
    batch.update(snap.docs[i].ref, { worldRank: i + 1 });
    opCount++;
    if (opCount >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }
  if (opCount > 0) await batch.commit();
});

// ─────────────────────────────────────────────────────────────────────────────
// RANKS: Recompute club scores and ranks every 5 minutes
// ─────────────────────────────────────────────────────────────────────────────
exports.recomputeClubRanks = onSchedule('every 5 minutes', async () => {
  const clubsSnap = await db.collection('clubs').get();

  // Compute each club's total score from its members
  const clubTotals = await Promise.all(
    clubsSnap.docs.map(async (clubDoc) => {
      const membersSnap = await db
        .collection('clubs').doc(clubDoc.id)
        .collection('members')
        .orderBy('clubScore', 'desc')
        .get();

      const total = membersSnap.docs.reduce(
        (sum, m) => sum + (m.data().clubScore || 0), 0
      );
      return { clubDoc, membersSnap, total };
    })
  );

  // Sort clubs by total score desc, then write ranks
  clubTotals.sort((a, b) => b.total - a.total);

  for (let i = 0; i < clubTotals.length; i++) {
    const { clubDoc, membersSnap, total } = clubTotals[i];
    const BATCH_LIMIT = 490;
    let batch = db.batch();
    let opCount = 0;

    batch.update(clubDoc.ref, { clubScore: total, clubRank: i + 1 });
    opCount++;

    membersSnap.docs.forEach((memberDoc, j) => {
      batch.update(memberDoc.ref, { clubRank: j + 1 });
      opCount++;
      if (opCount >= BATCH_LIMIT) {
        batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    });

    if (opCount > 0) await batch.commit();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DAILY SORT: Seed next day's puzzle set at midnight UTC
// ─────────────────────────────────────────────────────────────────────────────
exports.seedDailySort = onSchedule('0 0 * * *', async () => {
  const tomorrow = new Date();
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  const dateStr = tomorrow.toISOString().split('T')[0];

  // Collect recently used question IDs (last 30 days)
  const recentSnaps = await db
    .collection('dailySorts')
    .orderBy('seededAt', 'desc')
    .limit(30)
    .get();

  const recentIds = new Set(
    recentSnaps.docs.flatMap((d) => d.data().questionIds || [])
  );

  const questionsSnap = await db
    .collection('questions')
    .where('isActive', '==', true)
    .limit(200)
    .get();

  const pool = questionsSnap.docs
    .filter((d) => !recentIds.has(d.id))
    .map((d) => d.id);

  if (pool.length < 5) {
    console.error('Not enough fresh questions for daily sort. Pool:', pool.length);
    return;
  }

  const picked = pool.sort(() => Math.random() - 0.5).slice(0, 5);

  await db.collection('dailySorts').doc(dateStr).set({
    date: dateStr,
    questionIds: picked,
    seededAt: FieldValue.serverTimestamp(),
  });

  console.log(`Seeded daily sort for ${dateStr}:`, picked);
});

// ─────────────────────────────────────────────────────────────────────────────
// ACTUALLY: tally a fact-submission vote and promote/reject at the threshold.
// This is the only path allowed to touch agreeCount/disagreeCount/status —
// clients can only create their own vote doc, never edit these fields.
// ─────────────────────────────────────────────────────────────────────────────
const ACTUALLY_VOTE_THRESHOLD = 10;

exports.actuallyOnFactVoteCreated = onDocumentCreated(
  'actuallyFactSubmissions/{submissionId}/votes/{voterUid}',
  async (event) => {
    const { submissionId } = event.params;
    const vote = event.data.data();
    const submissionRef = db.collection('actuallyFactSubmissions').doc(submissionId);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(submissionRef);
      if (!snap.exists) return;
      const submission = snap.data();
      if (submission.status !== 'pending') return;

      const agreeCount = (submission.agreeCount || 0) + (vote.agree ? 1 : 0);
      const disagreeCount = (submission.disagreeCount || 0) + (vote.agree ? 0 : 1);
      const voterUids = [...(submission.voterUids || []), event.params.voterUid];

      const updates = { agreeCount, disagreeCount, voterUids };

      if (agreeCount >= ACTUALLY_VOTE_THRESHOLD) {
        updates.status = 'approved';
        updates.resolvedAt = FieldValue.serverTimestamp();
        const factRef = db.collection('actuallyFacts').doc();
        tx.set(factRef, {
          statement: submission.statement,
          isTrue: submission.isTrue,
          why: submission.why,
          category: submission.category || null,
        });
      } else if (disagreeCount >= ACTUALLY_VOTE_THRESHOLD) {
        updates.status = 'rejected';
        updates.resolvedAt = FieldValue.serverTimestamp();
      }

      tx.update(submissionRef, updates);
    });
  }
);
