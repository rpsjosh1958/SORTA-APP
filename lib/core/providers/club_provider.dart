import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import '../models/club_info.dart';

// ─── Read providers ───────────────────────────────────────────────────────────

final userClubsProvider = StreamProvider<List<ClubInfo>>((ref) async* {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null || profile.clubIds.isEmpty) {
    yield [];
    return;
  }
  final db = FirebaseFirestore.instance;
  final snaps = await Future.wait(
    profile.clubIds.map((id) => db.collection('clubs').doc(id).get()),
  );
  yield snaps.where((s) => s.exists).map(ClubInfo.fromDoc).toList();
});

final clubInfoProvider = StreamProvider.family<ClubInfo?, String>((ref, clubId) {
  return FirebaseFirestore.instance
      .collection('clubs')
      .doc(clubId)
      .snapshots()
      .map((s) => s.exists ? ClubInfo.fromDoc(s) : null);
});

final clubMembersProvider =
    StreamProvider.family<List<ClubMember>, String>((ref, clubId) {
  return FirebaseFirestore.instance
      .collection('clubs')
      .doc(clubId)
      .collection('members')
      .orderBy('clubScore', descending: true)
      .snapshots()
      .map((snap) => snap.docs.asMap().entries.map((e) {
            final d = e.value.data();
            return ClubMember(
              uid: e.value.id,
              displayName: d['displayName'] as String? ?? 'Player',
              clubScore: d['clubScore'] as int? ?? 0,
              rank: e.key + 1,
            );
          }).toList());
});

final worldRankProvider = StreamProvider<List<WorldRankEntry>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('totalScore', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.asMap().entries.map((e) {
            final d = e.value.data();
            return WorldRankEntry(
              rank: e.key + 1,
              uid: e.value.id,
              displayName: d['displayName'] as String? ?? 'Player',
              totalScore: d['totalScore'] as int? ?? 0,
            );
          }).toList());
});

// ─── Mutations ────────────────────────────────────────────────────────────────

final clubActionsProvider =
    AsyncNotifierProvider<ClubActions, void>(ClubActions.new);

class ClubActions extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> createClub(String name, List<String> categories) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not signed in');
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) throw Exception('Profile not loaded');

    final db = FirebaseFirestore.instance;
    final code = _generateCode();
    final clubRef = db.collection('clubs').doc();
    final batch = db.batch();

    batch.set(clubRef, {
      'name': name.trim(),
      'code': code,
      'creatorUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'memberCount': 0, // onMemberJoin Cloud Function increments this
      'clubRank': 0,
      'clubScore': 0,
      'categories': categories,
    });

    batch.set(clubRef.collection('members').doc(user.uid), {
      'uid': user.uid,
      'displayName': profile.displayName,
      'totalScore': profile.totalScore,
      'clubScore': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(db.collection('users').doc(user.uid), {
      'clubIds': FieldValue.arrayUnion([clubRef.id]),
      'primaryClubId': clubRef.id,
    });

    await batch.commit();
    return code; // caller shows this to the user
  }

  /// Returns null on success, error message on failure.
  Future<String?> joinClub(String code) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'Not signed in';
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) return 'Profile not loaded';

    final db = FirebaseFirestore.instance;
    final snap = await db
        .collection('clubs')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return 'No club found with that code';

    final clubDoc = snap.docs.first;
    if (profile.clubIds.contains(clubDoc.id)) return 'You are already in this club';

    final batch = db.batch();

    // memberCount is updated by the onMemberJoin Cloud Function trigger
    batch.set(clubDoc.reference.collection('members').doc(user.uid), {
      'uid': user.uid,
      'displayName': profile.displayName,
      'totalScore': profile.totalScore,
      'clubScore': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(db.collection('users').doc(user.uid), {
      'clubIds': FieldValue.arrayUnion([clubDoc.id]),
      if (profile.primaryClubId == null) 'primaryClubId': clubDoc.id,
    });

    await batch.commit();
    return null;
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
