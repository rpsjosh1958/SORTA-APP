import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class UserProfile {
  final String uid;
  final String displayName;
  final int totalScore;
  final int worldRank;
  final int matchesPlayed;
  final int currentStreak;
  final int dailySortScore;
  final Timestamp? dailySortDate;
  final List<String> clubIds;
  final String? primaryClubId;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.totalScore,
    required this.worldRank,
    required this.matchesPlayed,
    required this.currentStreak,
    required this.dailySortScore,
    required this.dailySortDate,
    required this.clubIds,
    required this.primaryClubId,
  });

  bool get hasPlayedDailySort {
    if (dailySortDate == null) return false;
    final d = dailySortDate!.toDate();
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  int get level {
    if (totalScore >= 20000) return 25;
    if (totalScore >= 10000) return 20;
    if (totalScore >= 5000) return 15;
    if (totalScore >= 2000) return 10;
    if (totalScore >= 500) return 5;
    return 1;
  }

  String get levelLabel {
    if (totalScore >= 20000) return 'Legend';
    if (totalScore >= 10000) return 'Master';
    if (totalScore >= 5000) return 'Expert';
    if (totalScore >= 2000) return 'Strategist';
    if (totalScore >= 500) return 'Thinker';
    return 'Novice';
  }

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? 'Player',
      totalScore: d['totalScore'] as int? ?? 0,
      worldRank: d['worldRank'] as int? ?? 0,
      matchesPlayed: d['matchesPlayed'] as int? ?? 0,
      currentStreak: d['currentStreak'] as int? ?? 0,
      dailySortScore: d['dailySortScore'] as int? ?? 0,
      dailySortDate: d['dailySortDate'] as Timestamp?,
      clubIds: List<String>.from(d['clubIds'] ?? []),
      primaryClubId: d['primaryClubId'] as String?,
    );
  }
}

class MatchRecord {
  final String category;
  final int scoreDelta;
  final DateTime playedAt;
  final bool isDailySort;

  const MatchRecord({
    required this.category,
    required this.scoreDelta,
    required this.playedAt,
    required this.isDailySort,
  });

  String get relativeDate {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(playedAt.year, playedAt.month, playedAt.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  factory MatchRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MatchRecord(
      category: d['category'] as String? ?? 'Unknown',
      scoreDelta: d['scoreDelta'] as int? ?? 0,
      playedAt: (d['playedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDailySort: d['isDailySort'] as bool? ?? false,
    );
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.exists ? UserProfile.fromDoc(snap) : null);
});

final recentMatchesProvider = StreamProvider<List<MatchRecord>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('matches')
      .orderBy('playedAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map(MatchRecord.fromDoc).toList());
});

