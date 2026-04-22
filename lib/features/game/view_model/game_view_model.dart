import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/question_model.dart';
import '../data/hardcoded_data.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';

const _kValidCategories = {'Sports', 'Entertainment', 'Pop Culture', 'Social Media'};

class GameState {
  final Question? currentQuestion;
  final List<String> userOrder;
  final List<int> cardScores;
  final bool isAnswered;
  final bool isGameStarted;
  final bool isMatchComplete;
  final bool isLoadingQuestions;
  final int score;
  final int matchScore;
  final int totalScore;
  final int perfectCount;
  final int currentQuestionIndex;
  final int remainingTime;
  final int currentStreak;
  final String selectedCategory;
  final int skipsUsedToday;

  GameState({
    this.currentQuestion,
    this.userOrder = const [],
    this.cardScores = const [],
    this.isAnswered = false,
    this.isGameStarted = false,
    this.isMatchComplete = false,
    this.isLoadingQuestions = false,
    this.score = 0,
    this.matchScore = 0,
    this.totalScore = 0,
    this.perfectCount = 0,
    this.currentQuestionIndex = 0,
    this.remainingTime = 30,
    this.currentStreak = 0,
    this.selectedCategory = 'ALL',
    this.skipsUsedToday = 0,
  });

  int get skipsRemaining => (3 - skipsUsedToday).clamp(0, 3);

  GameState copyWith({
    Question? currentQuestion,
    List<String>? userOrder,
    List<int>? cardScores,
    bool? isAnswered,
    bool? isGameStarted,
    bool? isMatchComplete,
    bool? isLoadingQuestions,
    int? score,
    int? matchScore,
    int? totalScore,
    int? perfectCount,
    int? currentQuestionIndex,
    int? remainingTime,
    int? currentStreak,
    String? selectedCategory,
    int? skipsUsedToday,
    bool clearQuestion = false,
  }) {
    return GameState(
      currentQuestion: clearQuestion ? null : (currentQuestion ?? this.currentQuestion),
      userOrder: userOrder ?? this.userOrder,
      cardScores: cardScores ?? this.cardScores,
      isAnswered: isAnswered ?? this.isAnswered,
      isGameStarted: isGameStarted ?? this.isGameStarted,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      isLoadingQuestions: isLoadingQuestions ?? this.isLoadingQuestions,
      score: score ?? this.score,
      matchScore: matchScore ?? this.matchScore,
      totalScore: totalScore ?? this.totalScore,
      perfectCount: perfectCount ?? this.perfectCount,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      currentStreak: currentStreak ?? this.currentStreak,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      skipsUsedToday: skipsUsedToday ?? this.skipsUsedToday,
    );
  }
}

final gameViewModelProvider = NotifierProvider<GameViewModel, GameState>(() {
  return GameViewModel();
});

class GameViewModel extends Notifier<GameState> {
  Timer? _timer;
  List<Question> _questionPool = [];
  // Tracks seen question IDs per category so questions don't repeat within a session.
  // Resets automatically once the user has seen everything in that category.
  final Map<String, Set<String>> _seenIds = {};

  @override
  GameState build() {
    ref.onDispose(() => _timer?.cancel());
    Future.microtask(_loadInitialStats);
    return GameState();
  }

  Future<void> _loadInitialStats() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!snap.exists) return;
    final d = snap.data()!;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedSkipDate = d['dailySkipDate'] as String?;
    final skipsUsed = storedSkipDate == today ? (d['dailySkipsUsed'] as int? ?? 0) : 0;
    state = state.copyWith(
      totalScore: d['totalScore'] as int? ?? 0,
      currentStreak: d['currentStreak'] as int? ?? 0,
      skipsUsedToday: skipsUsed,
    );
  }

  void startGame() {
    state = state.copyWith(isGameStarted: true);
    _startTimer();
  }

  Future<void> setCategory(String category) async {
    state = state.copyWith(
      selectedCategory: category,
      currentQuestionIndex: 0,
      matchScore: 0,
      perfectCount: 0,
      isGameStarted: false,
      isMatchComplete: false,
      isLoadingQuestions: true,
      clearQuestion: true,
    );
    await _loadQuestions(category);
    state = state.copyWith(isLoadingQuestions: false);
    loadNextQuestion();
  }

  Future<void> playDailySort() async {
    state = state.copyWith(
      selectedCategory: 'Daily Sort',
      currentQuestionIndex: 0,
      matchScore: 0,
      perfectCount: 0,
      isGameStarted: false,
      isMatchComplete: false,
      isLoadingQuestions: true,
      clearQuestion: true,
    );
    await _loadQuestions('Daily Sort');
    state = state.copyWith(isLoadingQuestions: false);
    loadNextQuestion();
  }

  List<Question> _hardcodedForCategory(String category) {
    if (category == 'ALL' || category == 'Daily Sort') {
      return List<Question>.from(hardcodedQuestions)..shuffle();
    }
    final filtered = hardcodedQuestions.where((q) => q.category == category).toList()..shuffle();
    // If nothing matches (e.g. stale category name), return everything
    return filtered.isNotEmpty ? filtered : (List<Question>.from(hardcodedQuestions)..shuffle());
  }

  Future<void> _loadQuestions(String category) async {
    try {
      final db = FirebaseFirestore.instance;
      List<Question> pool;

      if (category == 'Daily Sort') {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final dailySnap = await db.collection('dailySorts').doc(today).get();

        if (dailySnap.exists) {
          final ids = List<String>.from(dailySnap.data()!['questionIds'] ?? []);
          final snaps = await Future.wait(ids.map((id) => db.collection('questions').doc(id).get()));
          pool = snaps.where((s) => s.exists).map(Question.fromDoc).toList();
          // Strip out any old-category questions from Firestore
          pool = pool.where((q) => _kValidCategories.contains(q.category)).toList();
        } else {
          pool = [];
        }
        if (pool.isEmpty) pool = _hardcodedForCategory('ALL');
      } else if (category == 'ALL') {
        final snap = await db.collection('questions').where('isActive', isEqualTo: true).limit(100).get();
        pool = snap.docs.map(Question.fromDoc).toList();
        pool = pool.where((q) => _kValidCategories.contains(q.category)).toList()..shuffle();
        if (pool.isEmpty) pool = _hardcodedForCategory('ALL');
      } else {
        final snap = await db.collection('questions')
            .where('category', isEqualTo: category)
            .where('isActive', isEqualTo: true)
            .get();
        pool = snap.docs.map(Question.fromDoc).toList()..shuffle();
        if (pool.isEmpty) pool = _hardcodedForCategory(category);
      }

      // Always guarantee at least 5 questions so a match can never end early
      if (pool.length < 5) {
        final fallback = _hardcodedForCategory(
          (category == 'Daily Sort' || category == 'ALL') ? 'ALL' : category,
        )..shuffle();
        final existingIds = pool.map((q) => q.id).toSet();
        final extras = fallback
            .where((q) => !existingIds.contains(q.id))
            .take(5 - pool.length)
            .toList();
        pool = [...pool, ...extras];
      }

      // Filter out questions already seen this session for this category.
      // If too few unseen remain, reset seen history and use the full pool.
      final seen = _seenIds.putIfAbsent(category, () => {});
      final unseen = pool.where((q) => !seen.contains(q.id)).toList();
      if (unseen.length >= 5) {
        _questionPool = unseen;
      } else {
        seen.clear();
        _questionPool = pool;
      }
    } catch (e) {
      _questionPool = _hardcodedForCategory(category);
    }
  }

  void loadNextQuestion() {
    _timer?.cancel();

    if (_questionPool.isEmpty && !state.isLoadingQuestions) {
      state = state.copyWith(isLoadingQuestions: true, clearQuestion: true);
      Future.microtask(() async {
        await _loadQuestions(state.selectedCategory);
        state = state.copyWith(isLoadingQuestions: false);
        // Only recurse if we actually got questions — prevents infinite loop
        if (_questionPool.isNotEmpty) loadNextQuestion();
      });
      return;
    }

    if (state.currentQuestionIndex < 5 && state.currentQuestionIndex < _questionPool.length) {
      final question = _questionPool[state.currentQuestionIndex];
      _seenIds.putIfAbsent(state.selectedCategory, () => {}).add(question.id);
      state = state.copyWith(
        currentQuestion: question,
        userOrder: List<String>.from(question.items)..shuffle(),
        cardScores: [],
        isAnswered: false,
        remainingTime: 30,
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
      if (state.isGameStarted) _startTimer();
    } else {
      _completeMatch();
    }
  }

  void _completeMatch() {
    state = state.copyWith(
      isMatchComplete: true,
      clearQuestion: true,
    );
    _saveMatch();
  }

  Future<void> _saveMatch() async {
    final user = ref.read(currentUserProvider);
    if (user == null || state.matchScore == 0 && state.currentQuestionIndex == 0) return;

    final db = FirebaseFirestore.instance;
    final isDailySort = state.selectedCategory == 'Daily Sort';

    try {
      // Record the match
      await db.collection('users').doc(user.uid).collection('matches').add({
        'category': state.selectedCategory,
        'scoreDelta': state.matchScore,
        'matchScore': state.matchScore,
        'finalScore': state.matchScore,
        'questionsAnswered': state.currentQuestionIndex,
        'perfectCount': state.perfectCount,
        'streakAtEnd': state.currentStreak,
        'playedAt': FieldValue.serverTimestamp(),
        'isDailySort': isDailySort,
      });

      // Update user profile so world rank leaderboard stays current
      await db.collection('users').doc(user.uid).update({
        'totalScore': FieldValue.increment(state.matchScore),
        'currentStreak': state.currentStreak,
        'matchesPlayed': FieldValue.increment(1),
        if (isDailySort) ...{
          'dailySortScore': state.matchScore,
          'dailySortDate': FieldValue.serverTimestamp(),
        },
      });

      // Update club member scores so club leaderboards stay current
      final profile = ref.read(userProfileProvider).asData?.value;
      if (profile != null && profile.clubIds.isNotEmpty) {
        await Future.wait(
          profile.clubIds.map((clubId) => db
              .collection('clubs')
              .doc(clubId)
              .collection('members')
              .doc(user.uid)
              .update({'clubScore': FieldValue.increment(state.matchScore)})),
        );
      }
    } catch (e) {
      // Silent fail — scores shown locally; Firestore sync can retry later
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime > 0 && !state.isAnswered) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
        timer.cancel();
        if (!state.isAnswered) submitAnswer();
      }
    });
  }

  void skipQuestion() {
    if (state.skipsRemaining <= 0 || state.isAnswered || !state.isGameStarted) return;
    _timer?.cancel();
    final newSkips = state.skipsUsedToday + 1;
    state = state.copyWith(skipsUsedToday: newSkips);
    _persistSkip(newSkips);
    loadNextQuestion();
  }

  Future<void> _persistSkip(int skipsUsed) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'dailySkipsUsed': skipsUsed,
        'dailySkipDate': today,
      });
    } catch (_) {}
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (state.isAnswered || !state.isGameStarted) return;
    final userOrder = List<String>.from(state.userOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = userOrder.removeAt(oldIndex);
    userOrder.insert(newIndex, item);
    state = state.copyWith(userOrder: userOrder);
  }

  void submitAnswer() {
    if (state.isAnswered || state.currentQuestion == null) return;
    _timer?.cancel();

    final correctOrder = state.currentQuestion!.items;
    final List<int> individualScores = [];
    int matches = 0;

    for (int i = 0; i < correctOrder.length; i++) {
      if (correctOrder[i] == state.userOrder[i]) {
        individualScores.add(10);
        matches++;
      } else {
        individualScores.add(-5);
      }
    }

    int totalRoundScore = individualScores.fold(0, (acc, s) => acc + s);
    final perfect = matches == correctOrder.length;
    if (perfect) {
      totalRoundScore += 30;
    } else if (matches == 0) {
      totalRoundScore -= 35;
    }

    final newStreak = perfect ? state.currentStreak + 1 : (matches >= 3 ? state.currentStreak : 0);
    final timeBonus = perfect ? state.remainingTime : 0;
    final multiplier = newStreak > 1 ? newStreak : 1;
    final finalRoundTotal = (totalRoundScore + timeBonus) * multiplier;

    state = state.copyWith(
      isAnswered: true,
      cardScores: individualScores,
      matchScore: state.matchScore + finalRoundTotal,
      totalScore: state.totalScore + finalRoundTotal,
      currentStreak: newStreak,
      perfectCount: state.perfectCount + (perfect ? 1 : 0),
    );

    if (state.currentQuestionIndex >= 5) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (state.isAnswered) _completeMatch();
      });
    }
  }

  void resetGame() {
    _timer?.cancel();
    _questionPool = [];
    state = state.copyWith(
      currentQuestionIndex: 0,
      matchScore: 0,
      perfectCount: 0,
      isGameStarted: false,
      isMatchComplete: false,
      clearQuestion: true,
    );
    loadNextQuestion();
  }
}

