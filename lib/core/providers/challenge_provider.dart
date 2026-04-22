import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// ─── Read providers ───────────────────────────────────────────────────────────

/// IDs of challenges the local user has dismissed (results viewed).
final dismissedChallengesProvider = StateProvider<Set<String>>((ref) => {});

/// Status priority: lower index = higher priority.
const _statusPriority = [
  ChallengeStatus.active,
  ChallengeStatus.countdown,
  ChallengeStatus.accepted,
  ChallengeStatus.pending,
  ChallengeStatus.rematchRequested,
  ChallengeStatus.complete,
];

/// The one challenge the user is currently engaged in.
/// Active/countdown/accepted challenges take priority over pending ones,
/// so an ongoing game is never interrupted by a new incoming challenge.
final activeChallengeProvider = StreamProvider<Challenge?>((ref) {
  final user = ref.watch(currentUserProvider);
  final dismissed = ref.watch(dismissedChallengesProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('challenges')
      .where('playerUids', arrayContains: user.uid)
      .where('status', whereIn: [
        'pending',
        'accepted',
        'countdown',
        'active',
        'rematch_requested',
        'complete',
      ])
      .orderBy('createdAt', descending: false)
      .limit(5)
      .snapshots()
      .map((s) {
        final challenges = s.docs
            .map(Challenge.fromDoc)
            .where((c) => !dismissed.contains(c.id))
            .toList();
        if (challenges.isEmpty) return null;

        challenges.sort((a, b) {
          final ai = _statusPriority.indexOf(a.status);
          final bi = _statusPriority.indexOf(b.status);
          return ai.compareTo(bi);
        });
        return challenges.first;
      });
});

/// A NEW incoming challenge while the user is already in a game (for in-game banner).
final busyIncomingChallengeProvider = StreamProvider<Challenge?>((ref) {
  final user = ref.watch(currentUserProvider);
  final active = ref.watch(activeChallengeProvider).asData?.value;
  if (user == null || active == null) return Stream.value(null);
  if (active.status == ChallengeStatus.pending ||
      active.status == ChallengeStatus.accepted) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('challenges')
      .where('opponentUid', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        final c = Challenge.fromDoc(s.docs.first);
        return c.id == active.id ? null : c;
      });
});

/// Both players' submitted answers for a challenge.
final challengeAnswersProvider =
    StreamProvider.family<Map<String, ChallengePlayerAnswers>, String>(
        (ref, challengeId) {
  return FirebaseFirestore.instance
      .collection('challenges')
      .doc(challengeId)
      .collection('answers')
      .snapshots()
      .map((s) {
        final map = <String, ChallengePlayerAnswers>{};
        for (final doc in s.docs) {
          map[doc.id] = ChallengePlayerAnswers.fromDoc(doc);
        }
        return map;
      });
});

/// Chat messages for a challenge.
final challengeMessagesProvider =
    StreamProvider.family<List<ChallengeMessage>, String>((ref, challengeId) {
  return FirebaseFirestore.instance
      .collection('challenges')
      .doc(challengeId)
      .collection('messages')
      .orderBy('sentAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(ChallengeMessage.fromDoc).toList());
});

// ─── Mutations ────────────────────────────────────────────────────────────────

final challengeActionsProvider =
    AsyncNotifierProvider<ChallengeActions, void>(ChallengeActions.new);

class ChallengeActions extends AsyncNotifier<void> {
  final _db = FirebaseFirestore.instance;

  @override
  Future<void> build() async {}

  /// Returns null on success, error message on failure.
  Future<String?> sendChallenge(String opponentUsername) async {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).asData?.value;
    if (user == null || profile == null) return 'Not signed in';

    final username = opponentUsername.trim();
    if (username.isEmpty) return 'Enter a username';
    if (username == profile.displayName) return 'You can\'t challenge yourself';

    final snap = await _db
        .collection('users')
        .where('displayName', isEqualTo: username)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return 'No player found with that username';

    final opponentDoc = snap.docs.first;
    final opponentUid = opponentDoc.id;
    final opponentName = opponentDoc.data()['displayName'] as String? ?? 'Player';

    final qSnap = await _db
        .collection('questions')
        .where('isActive', isEqualTo: true)
        .limit(100)
        .get();

    if (qSnap.docs.length < 5) return 'Not enough questions available';

    final shuffled = qSnap.docs.toList()..shuffle();
    final questionIds = shuffled.take(5).map((d) => d.id).toList();

    await _db.collection('challenges').doc().set({
      'playerUids': [user.uid, opponentUid],
      'challengerUid': user.uid,
      'challengerName': profile.displayName,
      'opponentUid': opponentUid,
      'opponentName': opponentName,
      'status': 'pending',
      'questionIds': questionIds,
      'challengerReady': false,
      'opponentReady': false,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'rematchRequestedBy': null,
    });

    return null;
  }

  Future<void> acceptChallenge(String challengeId) async {
    await _db
        .collection('challenges')
        .doc(challengeId)
        .update({'status': 'accepted'});
  }

  Future<void> declineChallenge(String challengeId) async {
    await _db
        .collection('challenges')
        .doc(challengeId)
        .update({'status': 'declined'});
  }

  Future<void> setReady(String challengeId, bool amChallenger) async {
    final ref = _db.collection('challenges').doc(challengeId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final d = snap.data()!;
      final updates = <String, dynamic>{};

      if (amChallenger) {
        updates['challengerReady'] = true;
        if (d['opponentReady'] == true) { updates['status'] = 'countdown'; }
      } else {
        updates['opponentReady'] = true;
        if (d['challengerReady'] == true) { updates['status'] = 'countdown'; }
      }
      tx.update(ref, updates);
    });
  }

  Future<void> startGame(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitAnswers(
    String challengeId,
    String myUid,
    List<VersusAnswerRecord> answers,
    int totalScore,
  ) async {
    final answerRef = _db
        .collection('challenges')
        .doc(challengeId)
        .collection('answers')
        .doc(myUid);

    await answerRef.set({
      'answers': answers.map((a) => a.toMap()).toList(),
      'totalScore': totalScore,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // If opponent also done, close the challenge.
    final allAnswers = await _db
        .collection('challenges')
        .doc(challengeId)
        .collection('answers')
        .get();

    if (allAnswers.docs.length >= 2) {
      await _db
          .collection('challenges')
          .doc(challengeId)
          .update({'status': 'complete'});
    }
  }

  Future<void> requestRematch(String challengeId, String myUid) async {
    final ref = _db.collection('challenges').doc(challengeId);
    final snap = await ref.get();
    final d = snap.data()!;
    final other = d['rematchRequestedBy'] as String?;

    if (other != null && other != myUid) {
      // Both want it — create new challenge immediately.
      await _createRematch(d);
    } else {
      await ref.update({'rematchRequestedBy': myUid});
    }
  }

  Future<void> _createRematch(Map<String, dynamic> old) async {
    final qSnap = await _db
        .collection('questions')
        .where('isActive', isEqualTo: true)
        .limit(100)
        .get();

    final shuffled = qSnap.docs.toList()..shuffle();
    final questionIds = shuffled.take(5).map((d) => d.id).toList();

    await _db.collection('challenges').doc().set({
      'playerUids': old['playerUids'],
      'challengerUid': old['challengerUid'],
      'challengerName': old['challengerName'],
      'opponentUid': old['opponentUid'],
      'opponentName': old['opponentName'],
      'status': 'accepted',
      'questionIds': questionIds,
      'challengerReady': false,
      'opponentReady': false,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'rematchRequestedBy': null,
    });
  }

  Future<void> sendMessage(
    String challengeId,
    String text,
    String displayName,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null || text.trim().isEmpty) return;

    await _db
        .collection('challenges')
        .doc(challengeId)
        .collection('messages')
        .add({
      'uid': user.uid,
      'displayName': displayName,
      'text': text.trim(),
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelChallenge(String challengeId) async {
    await _db
        .collection('challenges')
        .doc(challengeId)
        .update({'status': 'declined'});
  }

  /// Locally removes the completed challenge from view (no Firestore write).
  void dismissResult(String challengeId) {
    ref.read(dismissedChallengesProvider.notifier).update(
          (s) => {...s, challengeId},
        );
  }
}
