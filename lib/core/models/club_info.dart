import 'package:cloud_firestore/cloud_firestore.dart';

class ClubInfo {
  final String id;
  final String name;
  final String code;
  final int rank;
  final int memberCount;

  const ClubInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.rank,
    required this.memberCount,
  });

  factory ClubInfo.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubInfo(
      id: doc.id,
      name: d['name'] as String? ?? 'Club',
      code: d['code'] as String? ?? '',
      rank: d['clubRank'] as int? ?? 0,
      memberCount: d['memberCount'] as int? ?? 0,
    );
  }
}

class ClubMember {
  final String uid;
  final String displayName;
  final int clubScore;
  final int rank;

  const ClubMember({
    required this.uid,
    required this.displayName,
    required this.clubScore,
    required this.rank,
  });
}

class WorldRankEntry {
  final int rank;
  final String uid;
  final String displayName;
  final int totalScore;

  const WorldRankEntry({
    required this.rank,
    required this.uid,
    required this.displayName,
    required this.totalScore,
  });
}
