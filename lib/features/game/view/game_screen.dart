import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../view_model/game_view_model.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';
import '../../../core/widgets/neo_dropdown.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late CurvedAnimation _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = ref.read(gameViewModelProvider).selectedCategory;
      if (selected.isNotEmpty && ref.read(gameViewModelProvider).currentQuestion == null && !ref.read(gameViewModelProvider).isMatchComplete) {
        ref.read(gameViewModelProvider.notifier).loadNextQuestion();
      }
    });
  }

  @override
  void dispose() {
    _pulseAnimation.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSubmission(GameViewModel notifier, GameState state) {
    notifier.submitAnswer();
    final correctCount = state.userOrder.where((item) {
      final index = state.userOrder.indexOf(item);
      return state.currentQuestion?.items[index] == item;
    }).length;

    if (correctCount == 5) {
      HapticFeedback.vibrate();
    } else if (correctCount == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          elevation: 0,
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameViewModelProvider);
    final gameNotifier = ref.read(gameViewModelProvider.notifier);

    if (gameState.remainingTime < 5 && !gameState.isAnswered && gameState.isGameStarted) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        centerTitle: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title: Row(
          children: [
            _CategoryDropdown(gameState: gameState, gameNotifier: gameNotifier),
            Expanded(
              child: Center(
                child: Text('SORTA', style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Match: ${gameState.currentQuestionIndex}/$kMatchSize',
                    style: theme.appTextTheme.body?.copyWith(fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                  Text(
                    'Score: ${NumberFormat('#,###').format(gameState.matchScore)}',
                    style: theme.appTextTheme.body?.copyWith(fontWeight: FontWeight.w900, fontSize: 14, color: theme.appColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: DotGridBackground(
        child: Stack(
          children: [
            _buildGameBody(context, gameState, gameNotifier, theme),
            if (!gameState.isGameStarted && !gameState.isMatchComplete && gameState.currentQuestion != null && !gameState.isAnswered)
              _StartOverlay(onStart: gameNotifier.startGame),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBody(BuildContext context, GameState gameState, GameViewModel gameNotifier, ThemeData theme) {
    if (gameState.isLoadingQuestions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('PREPARING PUZZLES...',
                style: theme.appTextTheme.body?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    if (gameState.isMatchComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('MATCH COMPLETE!', style: theme.appTextTheme.heading?.copyWith(fontSize: 32)),
              const SizedBox(height: 32),
              _ResultRow(label: 'MATCH SCORE', value: NumberFormat('#,###').format(gameState.matchScore), color: theme.appColors.primary!),
              const SizedBox(height: 16),
              _ResultRow(label: 'TOTAL SCORE', value: NumberFormat('#,###').format(gameState.totalScore), color: theme.appColors.secondary!),
              const SizedBox(height: 48),
              _CustomButton(
                onPressed: gameNotifier.resetGame,
                text: 'PLAY ANOTHER',
              ),
            ],
          ),
        ),
      );
    }

    if (gameState.currentQuestion == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 80, color: theme.appColors.onSurface?.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text('READY TO SORT?', style: theme.appTextTheme.heading),
            const SizedBox(height: 8),
            Text('Select a category to begin', style: theme.appTextTheme.body),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Text(
            gameState.currentQuestion!.prompt,
            style: theme.appTextTheme.heading?.copyWith(fontSize: 22),
          ),
        ),
        
        if (gameState.currentStreak > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 2),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${gameState.currentStreak}x STREAK',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

        if (!gameState.isAnswered && gameState.isGameStarted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final isEnding = gameState.remainingTime < 5;
                final color = isEnding
                    ? Color.lerp(theme.appColors.danger!, Colors.redAccent.shade700, _pulseAnimation.value)
                    : theme.appColors.primary!;
                final opacity = isEnding ? (0.6 + (0.4 * _pulseAnimation.value)) : 1.0;

                return Opacity(
                  opacity: opacity,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: theme.appColors.border!, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: gameState.remainingTime / 30,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(color!),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final availableHeight = constraints.maxHeight - 16;
              final cardHeight = (availableHeight - (spacing * 4)) / 5;

              return ReorderableListView(
                buildDefaultDragHandles: false,
                proxyDecorator: _proxyDecorator,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.heavyImpact();
                  gameNotifier.reorderItems(oldIndex, newIndex);
                },
                children: [
                  for (int i = 0; i < gameState.userOrder.length; i++)
                    ReorderableDragStartListener(
                      key: ValueKey(gameState.userOrder[i]),
                      index: i,
                      enabled: !gameState.isAnswered && gameState.isGameStarted,
                      child: _SortCard(
                        text: gameState.userOrder[i],
                        height: cardHeight,
                        isAnswered: gameState.isAnswered,
                        isCorrect: gameState.isAnswered &&
                            gameState.currentQuestion != null &&
                            gameState.userOrder[i] == gameState.currentQuestion!.items[i],
                        score: gameState.isAnswered && gameState.cardScores.isNotEmpty
                            ? gameState.cardScores[i]
                            : null,
                        margin: i == gameState.userOrder.length - 1 ? 0 : spacing,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              if (gameState.isGameStarted && !gameState.isAnswered && !gameState.isMatchComplete) ...[
                _SkipButton(
                  remaining: gameState.skipsRemaining,
                  onTap: gameState.skipsRemaining > 0 ? gameNotifier.skipQuestion : null,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _CustomButton(
                  onPressed: gameState.isAnswered
                      ? (gameState.currentQuestionIndex < kMatchSize ? gameNotifier.loadNextQuestion : null)
                      : (gameState.isGameStarted ? () => _handleSubmission(gameNotifier, gameState) : () {}),
                  text: gameState.isAnswered ? (gameState.currentQuestionIndex < kMatchSize ? 'NEXT' : 'FINISHING...') : 'SUBMIT',
                  enabled: (gameState.isGameStarted || gameState.isAnswered) && !(gameState.isAnswered && gameState.currentQuestionIndex == kMatchSize),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        ],
      ),
    );
  }
}

const _kCategories = [
  'ALL',
  'Sports',
  'Entertainment',
  'Pop Culture',
  'Social Media',
  'Science',
  'Math',
  'Tech',
  'World Facts'
];

class _CategoryDropdown extends ConsumerWidget {
  final GameState gameState;
  final GameViewModel gameNotifier;

  const _CategoryDropdown({required this.gameState, required this.gameNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final enabled = !gameState.isGameStarted || gameState.isAnswered || gameState.isMatchComplete;

    String label = gameState.selectedCategory.isEmpty ? 'SELECT' : gameState.selectedCategory.toUpperCase();
    if (gameState.selectedCategory == 'ALL' && gameState.selectedSubCategories.isNotEmpty) {
      label = 'ALL (${gameState.selectedSubCategories.length})';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Center(
        child: NeoDropdown<String>(
          items: _kCategories.map((c) {
            final isCompleted = profile?.completedCategories[c] ?? false;
            return NeoDropdownItem(
              value: c,
              label: c,
              isCompleted: isCompleted,
            );
          }).toList(),
          currentValue: gameState.selectedCategory,
          onSelected: (cat) {
            if (cat == 'ALL') {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => _CategorySelectorDialog(
                  initialSelected: gameState.selectedSubCategories,
                  onSelected: (selected) {
                    gameNotifier.setCategory('ALL', selected);
                  },
                ),
              );
            } else {
              gameNotifier.setCategory(cat);
            }
          },
          enabled: enabled,
          minMenuWidth: 160,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.appColors.secondary,
              border: Border.all(color: theme.appColors.border!, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: theme.appColors.shadow!, offset: const Offset(2, 2), blurRadius: 0),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySelectorDialog extends StatefulWidget {
  final List<String> initialSelected;
  final Function(List<String>) onSelected;

  const _CategorySelectorDialog({
    required this.onSelected,
    this.initialSelected = const [],
  });

  @override
  State<_CategorySelectorDialog> createState() => _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<_CategorySelectorDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initialSelected);
  }

  void _toggle(String cat) {
    setState(() {
      if (_selected.contains(cat)) {
        _selected.remove(cat);
      } else {
        _selected.add(cat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProviderScope.containerOf(context).read(userProfileProvider).asData?.value;
    final validCategories = _kCategories.where((c) => c != 'ALL').toList();
    final canStart = _selected.length >= 5;

    return AlertDialog(
      backgroundColor: theme.appColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text('PICK 5+ CATEGORIES',
          style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: validCategories.map((cat) {
              final isSelected = _selected.contains(cat);
              final isDone = profile?.completedCategories[cat] ?? false;

              return GestureDetector(
                onTap: () => _toggle(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.appColors.primary : theme.appColors.surface,
                    border: Border.all(
                      color: isSelected ? Colors.black : theme.appColors.border!.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [BoxShadow(color: theme.appColors.shadow!, offset: const Offset(2, 2))]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.toUpperCase(),
                        style: theme.appTextTheme.body?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.black : theme.appColors.onSurface?.withOpacity(0.5),
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: theme.appTextTheme.button?.copyWith(fontSize: 14)),
        ),
        ElevatedButton(
          onPressed: canStart
              ? () {
                  widget.onSelected(_selected);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.appColors.primary,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text(canStart ? 'OK' : 'PICK ${5 - _selected.length} MORE',
              style: theme.appTextTheme.button?.copyWith(fontSize: 14)),
        ),
      ],
    );
  }
}

class _StartOverlay extends StatefulWidget {
  final VoidCallback onStart;
  const _StartOverlay({required this.onStart});

  @override
  State<_StartOverlay> createState() => _StartOverlayState();
}

class _StartOverlayState extends State<_StartOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onStart();
              },
              child: Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: theme.appColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.appColors.border!, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: theme.appColors.shadow!,
                      offset: const Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 56, color: Colors.black),
                    SizedBox(height: 2),
                    Text(
                      'START',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool enabled;

  const _CustomButton({required this.onPressed, required this.text, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.appColors.primary,
        foregroundColor: theme.appColors.onSurface,
        disabledBackgroundColor: Colors.grey,
        elevation: enabled ? 4 : 0,
        shadowColor: theme.appColors.shadow,
        side: BorderSide(color: theme.appColors.border!, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: theme.appTextTheme.button?.copyWith(fontSize: 18),
      ),
      child: Text(text),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final int remaining;
  final VoidCallback? onTap;
  const _SkipButton({required this.remaining, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? theme.appColors.surface : Colors.grey.shade200,
          border: Border.all(color: theme.appColors.border!, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: enabled
              ? [BoxShadow(color: theme.appColors.shadow!, offset: const Offset(3, 3))]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SKIP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: enabled ? theme.appColors.onSurface : Colors.grey,
              ),
            ),
            Text(
              '$remaining left',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: enabled ? theme.appColors.onSurface?.withOpacity(0.6) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortCard extends StatelessWidget {
  final String text;
  final double height;
  final bool isAnswered;
  final bool isCorrect;
  final int? score;
  final double margin;

  const _SortCard({
    required this.text,
    required this.height,
    required this.isAnswered,
    this.isCorrect = false,
    this.score,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color cardColor = theme.appColors.surface!;
    if (isAnswered) {
      cardColor = isCorrect ? theme.appColors.success! : theme.appColors.danger!;
    }

    return Container(
      key: key,
      height: height,
      margin: EdgeInsets.only(bottom: margin),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.appColors.shadow!,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Center(
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: theme.appTextTheme.body?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.appColors.onSurface,
                    ),
                  ),
                ),
                trailing: Icon(Icons.drag_handle, color: theme.appColors.onSurface, size: 28),
              ),
            ),
            if (isAnswered && score != null)
              Positioned(
                bottom: 0,
                right: 10,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -(value * height)),
                      child: Opacity(
                        opacity: value < 0.7 ? 1.0 : (1.0 - ((value - 0.7) / 0.3)).clamp(0.0, 1.0),
                        child: Text(
                          score! > 0 ? '+$score' : '$score',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

