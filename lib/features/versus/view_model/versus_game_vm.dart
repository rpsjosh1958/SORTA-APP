import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/challenge.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/challenge_provider.dart';
import '../../game/data/question_model.dart';

class VersusGameState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final List<String> userOrder;
  final List<int> cardScores;
  final bool isAnswered;
  final int remainingTime;
  final int matchScore;
  final int currentStreak;
  final bool isComplete;
  final bool isLoading;
  final List<VersusAnswerRecord> submittedAnswers;

  const VersusGameState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.userOrder = const [],
    this.cardScores = const [],
    this.isAnswered = false,
    this.remainingTime = 30,
    this.matchScore = 0,
    this.currentStreak = 0,
    this.isComplete = false,
    this.isLoading = true,
    this.submittedAnswers = const [],
  });

  Question? get currentQuestion =>
      currentQuestionIndex < questions.length ? questions[currentQuestionIndex] : null;

  VersusGameState copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    List<String>? userOrder,
    List<int>? cardScores,
    bool? isAnswered,
    int? remainingTime,
    int? matchScore,
    int? currentStreak,
    bool? isComplete,
    bool? isLoading,
    List<VersusAnswerRecord>? submittedAnswers,
  }) =>
      VersusGameState(
        questions: questions ?? this.questions,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        userOrder: userOrder ?? this.userOrder,
        cardScores: cardScores ?? this.cardScores,
        isAnswered: isAnswered ?? this.isAnswered,
        remainingTime: remainingTime ?? this.remainingTime,
        matchScore: matchScore ?? this.matchScore,
        currentStreak: currentStreak ?? this.currentStreak,
        isComplete: isComplete ?? this.isComplete,
        isLoading: isLoading ?? this.isLoading,
        submittedAnswers: submittedAnswers ?? this.submittedAnswers,
      );
}

final versusGameVmProvider =
    NotifierProvider<VersusGameVM, VersusGameState>(VersusGameVM.new);

class VersusGameVM extends Notifier<VersusGameState> {
  Timer? _timer;

  @override
  VersusGameState build() {
    ref.onDispose(() => _timer?.cancel());
    return const VersusGameState();
  }

  Future<void> loadQuestions(List<String> questionIds) async {
    state = const VersusGameState(isLoading: true);
    try {
      final db = FirebaseFirestore.instance;
      final snaps = await Future.wait(
        questionIds.map((id) => db.collection('questions').doc(id).get()),
      );
      final questions = snaps.where((s) => s.exists).map(Question.fromDoc).toList();
      if (questions.isEmpty) {
        state = const VersusGameState(isLoading: false);
        return;
      }
      state = VersusGameState(
        questions: questions,
        isLoading: false,
        userOrder: List<String>.from(questions.first.items)..shuffle(),
      );
    } catch (_) {
      state = const VersusGameState(isLoading: false);
    }
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.remainingTime > 0 && !state.isAnswered) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
        t.cancel();
        if (!state.isAnswered) submitAnswer();
      }
    });
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (state.isAnswered) return;
    final order = List<String>.from(state.userOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    state = state.copyWith(userOrder: order);
  }

  void submitAnswer() {
    if (state.isAnswered || state.currentQuestion == null) return;
    _timer?.cancel();

    final correct = state.currentQuestion!.items;
    final scores = <int>[];
    int matches = 0;

    for (int i = 0; i < correct.length; i++) {
      if (correct[i] == state.userOrder[i]) {
        scores.add(10);
        matches++;
      } else {
        scores.add(-5);
      }
    }

    int roundScore = scores.fold(0, (a, b) => a + b);
    final perfect = matches == correct.length;
    if (perfect) { roundScore += 30; }
    else if (matches == 0) { roundScore -= 35; }

    final newStreak =
        perfect ? state.currentStreak + 1 : (matches >= 3 ? state.currentStreak : 0);
    final timeBonus = perfect ? state.remainingTime : 0;
    final multiplier = newStreak > 1 ? newStreak : 1;
    final finalScore = (roundScore + timeBonus) * multiplier;

    final record = VersusAnswerRecord(
      questionIndex: state.currentQuestionIndex,
      userOrder: List<String>.from(state.userOrder),
      cardScores: scores,
      score: finalScore,
      timeRemaining: state.remainingTime,
    );

    final newAnswers = [...state.submittedAnswers, record];
    final newMatchScore = state.matchScore + finalScore;
    final isLast = state.currentQuestionIndex == state.questions.length - 1;

    state = state.copyWith(
      isAnswered: true,
      cardScores: scores,
      matchScore: newMatchScore,
      currentStreak: newStreak,
      submittedAnswers: newAnswers,
      isComplete: isLast,
    );

    if (isLast) {
      Future.delayed(
        const Duration(milliseconds: 1500),
        () => _saveToFirestore(newAnswers, newMatchScore),
      );
    }
  }

  void loadNextQuestion() {
    if (state.currentQuestionIndex >= state.questions.length - 1) return;
    final nextIndex = state.currentQuestionIndex + 1;
    final nextQ = state.questions[nextIndex];
    state = state.copyWith(
      currentQuestionIndex: nextIndex,
      userOrder: List<String>.from(nextQ.items)..shuffle(),
      cardScores: [],
      isAnswered: false,
      remainingTime: 30,
    );
    startTimer();
  }

  Future<void> _saveToFirestore(
    List<VersusAnswerRecord> answers,
    int totalScore,
  ) async {
    final user = ref.read(currentUserProvider);
    final active = ref.read(activeChallengeProvider).asData?.value;
    if (user == null || active == null) return;

    await ref.read(challengeActionsProvider.notifier).submitAnswers(
          active.id,
          user.uid,
          answers,
          totalScore,
        );
  }
}
