import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/question_model.dart';
import '../data/hardcoded_data.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';

const _kValidCategories = {
  'Sports',
  'Entertainment',
  'Pop Culture',
  'Social Media',
  'Science',
  'Math',
  'Tech',
  'World Facts'
};

const kMatchSize = 10;

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
  final List<String> selectedSubCategories;
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
    this.selectedSubCategories = const [
      'Sports',
      'Entertainment',
      'Pop Culture',
      'Social Media',
      'Science',
      'Math',
      'Tech',
      'World Facts'
    ],
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
    List<String>? selectedSubCategories,
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
      selectedSubCategories: selectedSubCategories ?? this.selectedSubCategories,
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

  Future<void> setCategory(String category, [List<String>? subCategories]) async {
    state = state.copyWith(
      selectedCategory: category,
      selectedSubCategories: subCategories ?? [],
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
      selectedSubCategories: [],
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
      final user = ref.read(currentUserProvider);
      List<Question> pool = [];

      if (category == 'Daily Sort') {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final dailySnap = await db.collection('dailySorts').doc(today).get();

        if (dailySnap.exists) {
          final ids = List<String>.from(dailySnap.data()!['questionIds'] ?? []);
          final snaps = await Future.wait(ids.map((id) => db.collection('questions').doc(id).get()));
          pool = snaps.where((s) => s.exists).map(Question.fromDoc).toList();
          pool = pool.where((q) => _kValidCategories.contains(q.category)).toList();
        }
        if (pool.isEmpty) pool = _hardcodedForCategory('ALL');
      } else if (category == 'ALL') {
        // Fetch ~2-3 questions from each selected sub-category to get a diverse mix for the match.
        final List<String> cats = state.selectedSubCategories.isNotEmpty
            ? state.selectedSubCategories
            : _kValidCategories.toList();

        final List<List<Question>> catPools = await Future.wait(cats.map((cat) async {
          // Get persistent answered IDs for this category
          Set<String> answered = {};
          if (user != null) {
            final p = await db.collection('users').doc(user.uid).collection('categoryProgress').doc(cat).get();
            if (p.exists) answered = Set<String>.from(p.data()?['answeredIds'] ?? []);
          }

          final snap = await db.collection('questions')
              .where('category', isEqualTo: cat)
              .where('isActive', isEqualTo: true)
              .limit(10) // Small limit per category to build the "ALL" pool
              .get();
          
          return snap.docs.map(Question.fromDoc)
              .where((q) => !answered.contains(q.id))
              .toList();
        }));

        pool = catPools.expand((x) => x).toList()..shuffle();
        if (pool.isEmpty) pool = _hardcodedForCategory('ALL');
      } else {
        // Single Category
        Set<String> persistentAnsweredIds = {};
        if (user != null) {
          final progressSnap = await db
              .collection('users')
              .doc(user.uid)
              .collection('categoryProgress')
              .doc(category)
              .get();
          if (progressSnap.exists) {
            persistentAnsweredIds = Set<String>.from(progressSnap.data()?['answeredIds'] ?? []);
          }
        }

        final snap = await db.collection('questions')
            .where('category', isEqualTo: category)
            .where('isActive', isEqualTo: true)
            .get();
        pool = snap.docs.map(Question.fromDoc)
            .where((q) => !persistentAnsweredIds.contains(q.id))
            .toList()..shuffle();
        
        if (pool.isEmpty) pool = _hardcodedForCategory(category);
      }

      // Guarantee at least kMatchSize (10) questions
      if (pool.length < kMatchSize) {
        final fallback = _hardcodedForCategory(
          (category == 'Daily Sort' || category == 'ALL') ? 'ALL' : category,
        )..shuffle();
        final existingIds = pool.map((q) => q.id).toSet();
        final extras = fallback
            .where((q) => !existingIds.contains(q.id))
            .take(kMatchSize - pool.length)
            .toList();
        pool = [...pool, ...extras];
      }

      // Session deduplication
      final seen = _seenIds.putIfAbsent(category, () => {});
      final unseen = pool.where((q) => !seen.contains(q.id)).toList();
      if (unseen.length >= kMatchSize) {
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
        if (_questionPool.isNotEmpty) loadNextQuestion();
      });
      return;
    }

    if (state.currentQuestionIndex < kMatchSize && state.currentQuestionIndex < _questionPool.length) {
      final question = _questionPool[state.currentQuestionIndex];
      _seenIds.putIfAbsent(state.selectedCategory, () => {}).add(question.id);
      
      // High stakes: 20 seconds for Math and Tech, 30 for others
      final initialTime = (question.category == 'Math' || question.category == 'Tech') ? 20 : 30;

      state = state.copyWith(
        currentQuestion: question,
        userOrder: List<String>.from(question.items)..shuffle(),
        cardScores: [],
        isAnswered: false,
        remainingTime: initialTime,
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

    // Track category progress in Firestore
    _recordQuestionProgress(state.currentQuestion!);

    if (state.currentQuestionIndex >= kMatchSize) {
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

  Future<void> _recordQuestionProgress(Question question) async {
    final user = ref.read(currentUserProvider);
    if (user == null || question.category == 'Daily Sort') return;

    final db = FirebaseFirestore.instance;
    final progressDoc = db
        .collection('users')
        .doc(user.uid)
        .collection('categoryProgress')
        .doc(question.category);

    try {
      await progressDoc.set({
        'answeredIds': FieldValue.arrayUnion([question.id]),
        'lastAnsweredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Check if category is now completed
      final totalSnap = await db
          .collection('questions')
          .where('category', isEqualTo: question.category)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      
      final currentSnap = await progressDoc.get();
      final answeredIds = List<String>.from(currentSnap.data()?['answeredIds'] ?? []);

      if (answeredIds.length >= totalSnap.count!) {
        await db.collection('users').doc(user.uid).update({
          'completedCategories.${question.category}': true,
        });
      }
    } catch (e) {
      // Silent fail
    }
  }
}
