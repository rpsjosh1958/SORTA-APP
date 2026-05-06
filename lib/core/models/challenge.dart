import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeStatus {
  pending,
  accepted,
  countdown,
  active,
  complete,
  rematchRequested,
  declined,
}

class Challenge {
  final String id;
  final String challengerUid;
  final String challengerName;
  final String opponentUid;
  final String opponentName;
  final ChallengeStatus status;
  final List<String> questionIds;
  final List<String> finishedUids;
  final bool challengerReady;
  final bool opponentReady;
  final Timestamp? createdAt;
  final Timestamp? startedAt;
  final String? rematchRequestedBy;

  const Challenge({
    required this.id,
    required this.challengerUid,
    required this.challengerName,
    required this.opponentUid,
    required this.opponentName,
    required this.status,
    required this.questionIds,
    this.finishedUids = const [],
    required this.challengerReady,
    required this.opponentReady,
    this.createdAt,
    this.startedAt,
    this.rematchRequestedBy,
  });

  factory Challenge.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      challengerUid: d['challengerUid'] as String? ?? '',
      challengerName: d['challengerName'] as String? ?? 'Player',
      opponentUid: d['opponentUid'] as String? ?? '',
      opponentName: d['opponentName'] as String? ?? 'Player',
      status: _statusFrom(d['status'] as String? ?? 'pending'),
      questionIds: List<String>.from(d['questionIds'] as List? ?? []),
      finishedUids: List<String>.from(d['finishedUids'] as List? ?? []),
      challengerReady: d['challengerReady'] as bool? ?? false,
      opponentReady: d['opponentReady'] as bool? ?? false,
      createdAt: d['createdAt'] as Timestamp?,
      startedAt: d['startedAt'] as Timestamp?,
      rematchRequestedBy: d['rematchRequestedBy'] as String?,
    );
  }

  static ChallengeStatus _statusFrom(String s) => switch (s) {
    'accepted' => ChallengeStatus.accepted,
    'countdown' => ChallengeStatus.countdown,
    'active' => ChallengeStatus.active,
    'complete' => ChallengeStatus.complete,
    'rematch_requested' => ChallengeStatus.rematchRequested,
    'declined' => ChallengeStatus.declined,
    _ => ChallengeStatus.pending,
  };

  static String statusString(ChallengeStatus s) => switch (s) {
    ChallengeStatus.accepted => 'accepted',
    ChallengeStatus.countdown => 'countdown',
    ChallengeStatus.active => 'active',
    ChallengeStatus.complete => 'complete',
    ChallengeStatus.rematchRequested => 'rematch_requested',
    ChallengeStatus.declined => 'declined',
    _ => 'pending',
  };

  String opponentNameFor(String myUid) =>
      myUid == challengerUid ? opponentName : challengerName;

  String opponentUidFor(String myUid) =>
      myUid == challengerUid ? opponentUid : challengerUid;

  bool isReadyFor(String myUid) =>
      myUid == challengerUid ? challengerReady : opponentReady;

  bool get bothReady => challengerReady && opponentReady;
}

class ChallengePlayerAnswers {
  final List<VersusAnswerRecord> answers;
  final int totalScore;
  final bool isComplete;

  const ChallengePlayerAnswers({
    required this.answers,
    required this.totalScore,
    required this.isComplete,
  });

  factory ChallengePlayerAnswers.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChallengePlayerAnswers(
      answers: (d['answers'] as List? ?? [])
          .map((a) => VersusAnswerRecord.fromMap(a as Map<String, dynamic>))
          .toList(),
      totalScore: d['totalScore'] as int? ?? 0,
      isComplete: d['completedAt'] != null,
    );
  }
}

class VersusAnswerRecord {
  final int questionIndex;
  final List<String> userOrder;
  final List<int> cardScores;
  final int score;
  final int timeRemaining;

  const VersusAnswerRecord({
    required this.questionIndex,
    required this.userOrder,
    required this.cardScores,
    required this.score,
    required this.timeRemaining,
  });

  factory VersusAnswerRecord.fromMap(Map<String, dynamic> m) => VersusAnswerRecord(
    questionIndex: m['questionIndex'] as int? ?? 0,
    userOrder: List<String>.from(m['userOrder'] as List? ?? []),
    cardScores: List<int>.from(m['cardScores'] as List? ?? []),
    score: m['score'] as int? ?? 0,
    timeRemaining: m['timeRemaining'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'questionIndex': questionIndex,
    'userOrder': userOrder,
    'cardScores': cardScores,
    'score': score,
    'timeRemaining': timeRemaining,
  };
}

class ChallengeMessage {
  final String id;
  final String uid;
  final String displayName;
  final String text;
  final Timestamp? sentAt;

  const ChallengeMessage({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.text,
    this.sentAt,
  });

  factory ChallengeMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChallengeMessage(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      displayName: d['displayName'] as String? ?? 'Player',
      text: d['text'] as String? ?? '',
      sentAt: d['sentAt'] as Timestamp?,
    );
  }
}
