import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import '../models/club_info.dart';

// ─── Read providers ───────────────────────────────────────────────────────────

final clubsProvider = StreamProvider<List<ClubInfo>>((ref) {
  return FirebaseFirestore.instance
      .collection('clubs')
      .orderBy('clubScore', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ClubInfo.fromDoc).toList());
});

final myClubsProvider = StreamProvider<List<ClubInfo>>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null || profile.clubIds.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('clubs')
      .where(FieldPath.documentId, whereIn: profile.clubIds)
      .snapshots()
      .map((snap) => snap.docs.map(ClubInfo.fromDoc).toList());
});

final userClubsProvider = myClubsProvider;

final clubInfoProvider = StreamProvider.family<ClubInfo?, String>((ref, clubId) {
  return FirebaseFirestore.instance
      .collection('clubs')
      .doc(clubId)
      .snapshots()
      .map((snap) => snap.exists ? ClubInfo.fromDoc(snap) : null);
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
            return ClubMember.fromDoc(e.value).copyWithRank(e.key + 1);
          }).toList());
});

extension on ClubMember {
  ClubMember copyWithRank(int newRank) => ClubMember(
        uid: uid,
        displayName: displayName,
        clubScore: clubScore,
        rank: newRank,
        avatarSeed: avatarSeed,
      );
}

final worldRankProvider = StreamProvider<List<WorldRankEntry>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('totalScore', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.asMap().entries.map((e) {
            return WorldRankEntry.fromDoc(e.value).copyWithRank(e.key + 1);
          }).toList());
});

extension on WorldRankEntry {
  WorldRankEntry copyWithRank(int newRank) => WorldRankEntry(
        rank: newRank,
        uid: uid,
        displayName: displayName,
        totalScore: totalScore,
        avatarSeed: avatarSeed,
      );
}

// ─── Mutations ────────────────────────────────────────────────────────────────

final clubActionsProvider =
    AsyncNotifierProvider<ClubActions, void>(ClubActions.new);

class ClubActions extends AsyncNotifier<void> {
  final _db = FirebaseFirestore.instance;

  @override
  Future<void> build() async {}

  Future<String> createClub(String name, List<String> categories) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not signed in');
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) throw Exception('Profile not loaded');

    final code = _generateCode();
    final clubRef = _db.collection('clubs').doc();
    final batch = _db.batch();

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
      'avatarSeed': profile.avatarSeed,
      'clubScore': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return code;
  }

  Future<String?> joinClub(String code) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'Not signed in';
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) return 'Profile not loaded';

    final snap = await _db
        .collection('clubs')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return 'Invalid code';
    final clubDoc = snap.docs.first;

    if (profile.clubIds.contains(clubDoc.id)) return 'Already in this club';

    final batch = _db.batch();
    batch.set(clubDoc.reference.collection('members').doc(user.uid), {
      'uid': user.uid,
      'displayName': profile.displayName,
      'avatarSeed': profile.avatarSeed,
      'clubScore': 0,
      'joinedAt': FieldValue.serverTimestamp(),
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
