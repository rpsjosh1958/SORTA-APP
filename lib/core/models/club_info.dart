import 'package:cloud_firestore/cloud_firestore.dart';

class ClubInfo {
  final String id;
  final String name;
  final String code;
  final int rank;
  final int memberCount;
  final List<String> categories;

  const ClubInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.rank,
    required this.memberCount,
    this.categories = const ['ALL'],
  });

  factory ClubInfo.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubInfo(
      id: doc.id,
      name: d['name'] as String? ?? 'Club',
      code: d['code'] as String? ?? '',
      rank: d['clubRank'] as int? ?? 0,
      memberCount: d['memberCount'] as int? ?? 0,
      categories: List<String>.from(d['categories'] ?? ['ALL']),
    );
  }
}

class ClubMember {
  final String uid;
  final String displayName;
  final int clubScore;
  final int rank;
  final String avatarSeed;

  const ClubMember({
    required this.uid,
    required this.displayName,
    required this.clubScore,
    required this.rank,
    required this.avatarSeed,
  });

  factory ClubMember.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubMember(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? 'Player',
      clubScore: d['clubScore'] as int? ?? 0,
      rank: d['rank'] as int? ?? 0,
      avatarSeed: d['avatarSeed'] as String? ?? doc.id,
    );
  }
}

class WorldRankEntry {
  final int rank;
  final String uid;
  final String displayName;
  final int totalScore;
  final String avatarSeed;

  const WorldRankEntry({
    required this.rank,
    required this.uid,
    required this.displayName,
    required this.totalScore,
    required this.avatarSeed,
  });

  factory WorldRankEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WorldRankEntry(
      rank: d['worldRank'] as int? ?? 0,
      uid: doc.id,
      displayName: d['displayName'] as String? ?? 'Player',
      totalScore: d['totalScore'] as int? ?? 0,
      avatarSeed: d['avatarSeed'] as String? ?? doc.id,
    );
  }
}
