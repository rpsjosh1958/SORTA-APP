# SORTA UI Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dot-grid background, fix 3 animations in the game screen, and build 4 new screens (World Rank, Clubs, Club Rank, Profile) with clean Heroicon SVGs and mock data.

**Architecture:** `DotGridBackground` is a single reusable widget applied as the bottom layer in every new screen's Scaffold body. New screens are self-contained StatelessWidget / ConsumerWidget files in `lib/features/home/view/`. The three animation fixes are surgical edits to `game_screen.dart` — no structural changes.

**Tech Stack:** Flutter, Riverpod, flutter_svg ^2.0.10, Heroicons 2 outline SVGs, intl, Google Fonts (Space Grotesk)

---

## File Map

| File | Action |
|------|--------|
| `pubspec.yaml` | Add `flutter_svg`, register `assets/icons/` |
| `assets/icons/*.svg` | Create — 5 Heroicons (trophy, globe-alt, user-group, user, chart-bar, fire) |
| `lib/core/widgets/dot_grid_background.dart` | Create |
| `test/core/widgets/dot_grid_background_test.dart` | Create |
| `lib/features/game/view/game_screen.dart` | Modify — 3 animation fixes + DotGridBackground |
| `lib/features/home/view/world_rank_screen.dart` | Create |
| `test/features/home/view/world_rank_screen_test.dart` | Create |
| `lib/features/home/view/clubs_screen.dart` | Create |
| `test/features/home/view/clubs_screen_test.dart` | Create |
| `lib/features/home/view/club_rank_screen.dart` | Create |
| `test/features/home/view/club_rank_screen_test.dart` | Create |
| `lib/features/home/view/profile_screen.dart` | Create |
| `test/features/home/view/profile_screen_test.dart` | Create |
| `lib/features/home/view/main_screen.dart` | Modify — wire new screens + World Rank tap |
| `GEMINI.md` | Modify — update with new screens, icons, background |

---

## Task 1: Add flutter_svg dependency and register asset directory

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add flutter_svg to dependencies**

Open `pubspec.yaml` and add `flutter_svg: ^2.0.10` under `dependencies`, then add the asset directory under `flutter:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^3.3.1
  google_fonts: ^8.0.2
  isar: 4.0.0-dev.14
  isar_flutter_libs: 4.0.0-dev.14
  path_provider: ^2.1.5
  intl: ^0.20.2
  flutter_svg: ^2.0.10

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
```

- [ ] **Step 2: Create the icons directory**

```bash
mkdir -p assets/icons
```

- [ ] **Step 3: Run flutter pub get**

```bash
flutter pub get
```

Expected output ends with: `Got dependencies!`

---

## Task 2: Download Heroicon SVGs

**Files:**
- Create: `assets/icons/trophy.svg`
- Create: `assets/icons/globe-alt.svg`
- Create: `assets/icons/user-group.svg`
- Create: `assets/icons/user.svg`
- Create: `assets/icons/chart-bar.svg`
- Create: `assets/icons/fire.svg`

- [ ] **Step 1: Download the 6 SVGs from Heroicons 2 GitHub**

```bash
cd assets/icons
curl -sO https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/trophy.svg
curl -sO https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/globe-alt.svg
curl -sO https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/user-group.svg
curl -sO https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/user.svg
curl -sO https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/chart-bar.svg
curl -sO https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/outline/fire.svg
cd ../..
```

- [ ] **Step 2: Verify all 6 files exist and are valid SVG**

```bash
ls -la assets/icons/
head -1 assets/icons/trophy.svg
```

Expected: 6 files listed, first line of trophy.svg starts with `<svg`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/icons/
git commit -m "feat: add flutter_svg and Heroicons assets"
```

---

## Task 3: Create DotGridBackground widget + test

**Files:**
- Create: `lib/core/widgets/dot_grid_background.dart`
- Create: `test/core/widgets/dot_grid_background_test.dart`

- [ ] **Step 1: Write the failing test**

```bash
mkdir -p test/core/widgets
```

Create `test/core/widgets/dot_grid_background_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/core/widgets/dot_grid_background.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('DotGridBackground renders its child in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: Scaffold(
          body: DotGridBackground(
            child: const Text('hello'),
          ),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('DotGridBackground renders its child in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.dark,
        home: Scaffold(
          body: DotGridBackground(
            child: const Text('dark'),
          ),
        ),
      ),
    );
    expect(find.text('dark'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/core/widgets/dot_grid_background_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:sorta/core/widgets/dot_grid_background.dart'`

- [ ] **Step 3: Create the widget**

```bash
mkdir -p lib/core/widgets
```

Create `lib/core/widgets/dot_grid_background.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DotGridBackground extends StatelessWidget {
  final Widget child;

  const DotGridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _DotGridPainter(
              backgroundColor: theme.appColors.background!,
              dotColor: isDark ? const Color(0xFF383838) : const Color(0xFFC0C0C0),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color backgroundColor;
  final Color dotColor;

  const _DotGridPainter({required this.backgroundColor, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );
    final dotPaint = Paint()..color = dotColor;
    const spacing = 20.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.dotColor != dotColor;
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
flutter test test/core/widgets/dot_grid_background_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/dot_grid_background.dart test/core/widgets/dot_grid_background_test.dart
git commit -m "feat: add DotGridBackground widget with CustomPainter"
```

---

## Task 4: Fix timer pulse animation

**Files:**
- Modify: `lib/features/game/view/game_screen.dart:16-43`

The pulse controller currently uses a linear sweep (duration 500ms, no curve). This reads as a counting/stepping effect. Fix: add `CurvedAnimation` with `Curves.easeInOut` and increase duration to 800ms for a smooth sine-like oscillation.

- [ ] **Step 1: Add `_pulseAnimation` field to `_GameScreenState`**

Find the class field declaration on line 17:
```dart
late AnimationController _pulseController;
```
Replace with:
```dart
late AnimationController _pulseController;
late Animation<double> _pulseAnimation;
```

- [ ] **Step 2: Update `initState` to create `_pulseAnimation` and change duration**

Find in `initState` (lines 22–25):
```dart
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
```
Replace with:
```dart
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
```

- [ ] **Step 3: Dispose `_pulseAnimation` in `dispose`**

Find in `dispose` (line 36):
```dart
    _pulseController.dispose();
```
Replace with:
```dart
    _pulseAnimation.dispose();
    _pulseController.dispose();
```

- [ ] **Step 4: Update `AnimatedBuilder` to use `_pulseAnimation`**

Find in `build` (lines 169–198) the `AnimatedBuilder`:
```dart
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final isEnding = gameState.remainingTime < 5;
                final color = isEnding 
                    ? Color.lerp(theme.appColors.danger!, Colors.redAccent.shade700, _pulseController.value)
                    : theme.appColors.primary!;
                final opacity = isEnding ? (0.6 + (0.4 * _pulseController.value)) : 1.0;
```
Replace with:
```dart
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final isEnding = gameState.remainingTime < 5;
                final color = isEnding
                    ? Color.lerp(theme.appColors.danger!, Colors.redAccent.shade700, _pulseAnimation.value)
                    : theme.appColors.primary!;
                final opacity = isEnding ? (0.6 + (0.4 * _pulseAnimation.value)) : 1.0;
```

- [ ] **Step 5: Run the app and verify smooth pulse**

```bash
flutter run
```

Start a game, let the timer drop below 5 seconds. The progress bar should now smoothly oscillate (sine-like) between danger red and bright red — no stepping.

---

## Task 5: Fix start button animation

**Files:**
- Modify: `lib/features/game/view/game_screen.dart:335–411`

The current `_StartOverlayState` renders three expanding ring circles. Replace with a single breathe animation (scale + opacity) on the button itself. The three `List.generate` ring widgets are removed entirely.

- [ ] **Step 1: Add animation fields to `_StartOverlayState`**

Find the class body (line 336):
```dart
class _StartOverlayState extends State<_StartOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
```
Replace with:
```dart
class _StartOverlayState extends State<_StartOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
```

- [ ] **Step 2: Replace `initState` to set up breathe animations**

Find `initState` (lines 340–345):
```dart
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }
```
Replace with:
```dart
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
```

- [ ] **Step 3: Replace `build` — remove rings, wrap button in AnimatedBuilder**

Find the entire `build` method (lines 353–411):
```dart
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withValues(alpha: 0.2),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripples
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = (_controller.value - (index * 0.33)) % 1.0;
                    return Container(
                      height: 150 + (100 * progress),
                      width: 150 + (100 * progress),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.greenAccent.shade400.withValues(alpha: (1.0 - progress) * 0.5),
                          width: 4,
                        ),
                      ),
                    );
                  },
                );
              }),
              // Static Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onStart();
                },
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 60, color: Colors.black),
                      Text('START', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```
Replace with:
```dart
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withValues(alpha: 0.2),
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
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 60, color: Colors.black),
                    Text(
                      'START',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
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
```

- [ ] **Step 4: Run and verify**

```bash
flutter run
```

Start a new game. The START button should gently breathe (scale + opacity pulse). No expanding rings.

---

## Task 6: Fix score float-up animation + apply DotGridBackground to game screen

**Files:**
- Modify: `lib/features/game/view/game_screen.dart:443–533`

The score popup is `Positioned(top: -20)` with `Stack(clipBehavior: Clip.none)` — it escapes the card. Fix: add `ClipRRect` inside the card Container, change Stack to `Clip.hardEdge`, move score to `Positioned(bottom: 0)`, and travel the full card height.

- [ ] **Step 1: Add DotGridBackground import and wrap game screen body**

At the top of `game_screen.dart`, add the import after existing imports:
```dart
import '../../../core/widgets/dot_grid_background.dart';
```

In the `build` method of `_GameScreenState`, find:
```dart
      body: Stack(
        children: [
          _buildGameBody(context, gameState, gameNotifier, theme),
          if (!gameState.isGameStarted && !gameState.isMatchComplete && gameState.currentQuestion != null && !gameState.isAnswered)
            _StartOverlay(onStart: gameNotifier.startGame),
        ],
      ),
```
Replace with:
```dart
      body: DotGridBackground(
        child: Stack(
          children: [
            _buildGameBody(context, gameState, gameNotifier, theme),
            if (!gameState.isGameStarted && !gameState.isMatchComplete && gameState.currentQuestion != null && !gameState.isAnswered)
              _StartOverlay(onStart: gameNotifier.startGame),
          ],
        ),
      ),
```

- [ ] **Step 2: Fix `_SortCard.build` — add ClipRRect and fix score animation**

In `_SortCard.build`, find the `Container`'s child (the Stack with `clipBehavior: Clip.none`):
```dart
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                text,
                style: theme.appTextTheme.body?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.appColors.onSurface,
                ),
              ),
              trailing: Icon(Icons.drag_handle, color: theme.appColors.onSurface, size: 28),
            ),
          ),
          if (isAnswered && score != null)
            Positioned(
              top: -20,
              right: 10,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -40 * value),
                    child: Opacity(
                      opacity: (1.0 - value).clamp(0.0, 1.0),
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
```
Replace with:
```dart
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Center(
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  text,
                  style: theme.appTextTheme.body?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.appColors.onSurface,
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
                        opacity: value < 0.7 ? 1.0 : 1.0 - ((value - 0.7) / 0.3),
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
```

- [ ] **Step 3: Run and verify**

```bash
flutter run
```

Submit answers. Score text should float from the card's bottom edge to its top edge and fade out — never escaping outside the card boundary.

- [ ] **Step 4: Commit all game screen changes**

```bash
git add lib/features/game/view/game_screen.dart
git commit -m "fix: smooth timer pulse, breathe start button, clip score float-up; add dot grid to game screen"
```

---

## Task 7: Build WorldRankScreen + test

**Files:**
- Create: `lib/features/home/view/world_rank_screen.dart`
- Create: `test/features/home/view/world_rank_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```bash
mkdir -p test/features/home/view
```

Create `test/features/home/view/world_rank_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/features/home/view/world_rank_screen.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('WorldRankScreen shows WORLD RANK heading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const WorldRankScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('WORLD RANK'), findsOneWidget);
  });

  testWidgets('WorldRankScreen shows your position banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const WorldRankScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('YOUR POSITION'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/home/view/world_rank_screen_test.dart
```

Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Create WorldRankScreen**

Create `lib/features/home/view/world_rank_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';

class RankEntry {
  final int rank;
  final String username;
  final int score;
  const RankEntry({required this.rank, required this.username, required this.score});
}

const _mockRanks = <RankEntry>[
  RankEntry(rank: 1, username: 'SortKing99', score: 12840),
  RankEntry(rank: 2, username: 'RankMaster', score: 11200),
  RankEntry(rank: 3, username: 'QuizPro', score: 9750),
  RankEntry(rank: 4, username: 'SortFan', score: 9100),
  RankEntry(rank: 5, username: 'Thinker42', score: 8830),
  RankEntry(rank: 6, username: 'BrainWave', score: 8200),
  RankEntry(rank: 7, username: 'Luminary', score: 7950),
  RankEntry(rank: 8, username: 'SortGeek', score: 7600),
  RankEntry(rank: 9, username: 'NeoSorter', score: 7300),
  RankEntry(rank: 10, username: 'Axiom', score: 7100),
  RankEntry(rank: 11, username: 'MindSort', score: 6900),
  RankEntry(rank: 12, username: 'GridMind', score: 6750),
  RankEntry(rank: 13, username: 'PuzzleAce', score: 6500),
  RankEntry(rank: 14, username: 'ByteSorter', score: 6200),
  RankEntry(rank: 15, username: 'LogicZone', score: 6000),
  RankEntry(rank: 16, username: 'TopTier', score: 5800),
  RankEntry(rank: 17, username: 'RankPro', score: 5600),
  RankEntry(rank: 18, username: 'SortWiz', score: 5400),
  RankEntry(rank: 19, username: 'BrainBot', score: 5200),
  RankEntry(rank: 20, username: 'RankUp', score: 5000),
];

const _myPosition = RankEntry(rank: 142, username: 'You', score: 4280);

class WorldRankScreen extends StatelessWidget {
  const WorldRankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('WORLD RANK', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        backgroundColor: theme.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: DotGridBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PodiumRow(ranks: _mockRanks.take(3).toList()),
              const SizedBox(height: 16),
              _YourPositionBanner(entry: _myPosition),
              const SizedBox(height: 16),
              ..._mockRanks.skip(3).map(
                (e) => _RankRow(entry: e, isLast: e == _mockRanks.last),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<RankEntry> ranks;
  const _PodiumRow({required this.ranks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      theme.appColors.primary!,
      theme.appColors.secondary!,
      theme.appColors.accent!,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        ranks.length,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
            child: _PodiumCard(entry: ranks[i], color: colors[i]),
          ),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final RankEntry entry;
  final Color color;
  const _PodiumCard({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Text('#${entry.rank}', style: theme.appTextTheme.heading?.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          SvgPicture.asset(
            'assets/icons/user.svg',
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
          ),
          const SizedBox(height: 6),
          Text(
            entry.username,
            style: theme.appTextTheme.body?.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            NumberFormat('#,###').format(entry.score),
            style: theme.appTextTheme.body?.copyWith(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _YourPositionBanner extends StatelessWidget {
  final RankEntry entry;
  const _YourPositionBanner({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.appColors.secondary!.withValues(alpha: 0.15),
        border: Border.all(color: theme.appColors.secondary!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'YOUR POSITION',
            style: theme.appTextTheme.body?.copyWith(fontSize: 12, color: theme.appColors.secondary),
          ),
          const Spacer(),
          Text(
            '#${entry.rank}',
            style: theme.appTextTheme.heading?.copyWith(fontSize: 20, color: theme.appColors.secondary),
          ),
          const SizedBox(width: 12),
          Text(
            '${NumberFormat('#,###').format(entry.score)} pts',
            style: theme.appTextTheme.body?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final RankEntry entry;
  final bool isLast;
  const _RankRow({required this.entry, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: theme.appTextTheme.body?.copyWith(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          SvgPicture.asset(
            'assets/icons/user.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.username, style: theme.appTextTheme.body?.copyWith(fontSize: 14)),
          ),
          Text(
            NumberFormat('#,###').format(entry.score),
            style: theme.appTextTheme.body?.copyWith(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/features/home/view/world_rank_screen_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/view/world_rank_screen.dart test/features/home/view/world_rank_screen_test.dart
git commit -m "feat: add WorldRankScreen with mock leaderboard and podium cards"
```

---

## Task 8: Build ClubsScreen + test

**Files:**
- Create: `lib/features/home/view/clubs_screen.dart`
- Create: `test/features/home/view/clubs_screen_test.dart`

> **Dependency note:** `clubs_screen.dart` imports `club_rank_screen.dart` (created in Task 9). Create the stub below first so the file compiles during this task — Task 9 replaces it with the full implementation.

- [ ] **Step 0: Create ClubRankScreen stub**

Create `lib/features/home/view/club_rank_screen.dart` (stub — Task 9 overwrites this):

```dart
import 'package:flutter/material.dart';

class ClubRankScreen extends StatelessWidget {
  const ClubRankScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}
```

- [ ] **Step 1: Write the failing test**

Create `test/features/home/view/clubs_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/features/home/view/clubs_screen.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('ClubsScreen shows MY CLUB section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubsScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('MY CLUB'), findsOneWidget);
  });

  testWidgets('ClubsScreen shows DISCOVER section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubsScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('DISCOVER'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/home/view/clubs_screen_test.dart
```

Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Create ClubsScreen**

Create `lib/features/home/view/clubs_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';
import 'club_rank_screen.dart';

class ClubEntry {
  final String name;
  final int memberCount;
  final int rank;
  const ClubEntry({required this.name, required this.memberCount, required this.rank});
}

const _myClub = ClubEntry(name: 'Brain Squad', memberCount: 8, rank: 14);

const _discoverClubs = <ClubEntry>[
  ClubEntry(name: 'Sort Legends', memberCount: 24, rank: 3),
  ClubEntry(name: 'Quiz Masters', memberCount: 17, rank: 7),
  ClubEntry(name: 'Rankers United', memberCount: 12, rank: 11),
  ClubEntry(name: 'Mind Sorters', memberCount: 31, rank: 1),
  ClubEntry(name: 'The Grid', memberCount: 9, rank: 22),
  ClubEntry(name: 'Top Tier', memberCount: 14, rank: 18),
];

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('CLUBS', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        backgroundColor: theme.appColors.background,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: theme.appColors.primary,
        foregroundColor: theme.appColors.onSurface,
        label: Text('CREATE CLUB', style: theme.appTextTheme.button?.copyWith(fontSize: 14)),
        icon: const Icon(Icons.add),
      ),
      body: DotGridBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('MY CLUB', style: theme.appTextTheme.subHeading),
              const SizedBox(height: 12),
              _MyClubCard(club: _myClub),
              const SizedBox(height: 28),
              Text('DISCOVER', style: theme.appTextTheme.subHeading),
              const SizedBox(height: 12),
              ..._discoverClubs.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DiscoverClubCard(club: c),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyClubCard extends StatelessWidget {
  final ClubEntry club;
  const _MyClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClubRankScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.appColors.secondary,
          border: Border.all(color: theme.appColors.border!, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: theme.appColors.shadow!, offset: const Offset(5, 5), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/user-group.svg',
              width: 40,
              height: 40,
              colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.name, style: theme.appTextTheme.heading?.copyWith(fontSize: 22)),
                  Text(
                    '${club.memberCount} MEMBERS · RANK #${club.rank}',
                    style: theme.appTextTheme.body?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.appColors.onSurface, size: 28),
          ],
        ),
      ),
    );
  }
}

class _DiscoverClubCard extends StatelessWidget {
  final ClubEntry club;
  const _DiscoverClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/user-group.svg',
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  style: theme.appTextTheme.body?.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${club.memberCount} members · Rank #${club.rank}',
                  style: theme.appTextTheme.body?.copyWith(
                    fontSize: 12,
                    color: theme.appColors.onSurface?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.primary,
              foregroundColor: theme.appColors.onSurface,
              side: BorderSide(color: theme.appColors.border!, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 0,
              textStyle: theme.appTextTheme.button?.copyWith(fontSize: 12),
            ),
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/features/home/view/clubs_screen_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/view/clubs_screen.dart test/features/home/view/clubs_screen_test.dart
git commit -m "feat: add ClubsScreen with my club card and discover list"
```

---

## Task 9: Build ClubRankScreen + test

**Files:**
- Create: `lib/features/home/view/club_rank_screen.dart`
- Create: `test/features/home/view/club_rank_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/home/view/club_rank_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/features/home/view/club_rank_screen.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('ClubRankScreen shows club name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubRankScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('BRAIN SQUAD'), findsOneWidget);
  });

  testWidgets('ClubRankScreen shows member count stat pill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubRankScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('8 MEMBERS'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/home/view/club_rank_screen_test.dart
```

Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Create ClubRankScreen**

Create `lib/features/home/view/club_rank_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';

class MemberEntry {
  final int rank;
  final String username;
  final int score;
  const MemberEntry({required this.rank, required this.username, required this.score});
}

const _mockMembers = <MemberEntry>[
  MemberEntry(rank: 1, username: 'JoshT', score: 4280),
  MemberEntry(rank: 2, username: 'SarahK', score: 3900),
  MemberEntry(rank: 3, username: 'Mike22', score: 3400),
  MemberEntry(rank: 4, username: 'AlexR', score: 2900),
  MemberEntry(rank: 5, username: 'LiamS', score: 2600),
  MemberEntry(rank: 6, username: 'EmmaD', score: 2300),
  MemberEntry(rank: 7, username: 'NoahB', score: 2100),
  MemberEntry(rank: 8, username: 'OliviaP', score: 1800),
];

const _myRank = 1;

class ClubRankScreen extends StatelessWidget {
  const ClubRankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('BRAIN SQUAD', style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
        backgroundColor: theme.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: DotGridBackground(
        child: Column(
          children: [
            _ClubStatsHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _PodiumRow(members: _mockMembers.take(3).toList()),
                    const SizedBox(height: 16),
                    ..._mockMembers.skip(3).map(
                      (m) => _MemberRow(
                        member: m,
                        isMe: m.rank == _myRank,
                        isLast: m == _mockMembers.last,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubStatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: theme.appColors.background,
      child: Row(
        children: [
          _StatPill(label: '8 MEMBERS', color: theme.appColors.secondary!),
          const SizedBox(width: 8),
          _StatPill(label: 'RANK #14', color: theme.appColors.primary!),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Text(
        label,
        style: theme.appTextTheme.body?.copyWith(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<MemberEntry> members;
  const _PodiumRow({required this.members});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      theme.appColors.primary!,
      theme.appColors.secondary!,
      theme.appColors.accent!,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        members.length,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
            child: _PodiumCard(member: members[i], color: colors[i], isMe: members[i].rank == _myRank),
          ),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final MemberEntry member;
  final Color color;
  final bool isMe;
  const _PodiumCard({required this.member, required this.color, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: isMe ? 4 : 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Text('#${member.rank}', style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          SvgPicture.asset(
            'assets/icons/user.svg',
            width: 26,
            height: 26,
            colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            isMe ? '${member.username} \u2605' : member.username,
            style: theme.appTextTheme.body?.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            NumberFormat('#,###').format(member.score),
            style: theme.appTextTheme.body?.copyWith(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final MemberEntry member;
  final bool isMe;
  final bool isLast;
  const _MemberRow({required this.member, required this.isMe, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? theme.appColors.primary!.withValues(alpha: 0.2) : theme.appColors.surface,
        border: Border.all(
          color: isMe ? theme.appColors.primary! : theme.appColors.border!,
          width: isMe ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${member.rank}',
              style: theme.appTextTheme.body?.copyWith(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          SvgPicture.asset(
            'assets/icons/user.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? '${member.username} \u2605' : member.username,
              style: theme.appTextTheme.body?.copyWith(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
          Text(
            NumberFormat('#,###').format(member.score),
            style: theme.appTextTheme.body?.copyWith(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/features/home/view/club_rank_screen_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/view/club_rank_screen.dart test/features/home/view/club_rank_screen_test.dart
git commit -m "feat: add ClubRankScreen with podium and member leaderboard"
```

---

## Task 10: Build ProfileScreen + test

**Files:**
- Create: `lib/features/home/view/profile_screen.dart`
- Create: `test/features/home/view/profile_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/home/view/profile_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/features/home/view/profile_screen.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('ProfileScreen shows ME heading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppThemeNotifier.light,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ME'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows RECENT MATCHES section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppThemeNotifier.light,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('RECENT MATCHES'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/features/home/view/profile_screen_test.dart
```

Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Create ProfileScreen**

Create `lib/features/home/view/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';

class _MatchEntry {
  final String category;
  final int scoreDelta;
  final String date;
  const _MatchEntry({required this.category, required this.scoreDelta, required this.date});
}

const _recentMatches = <_MatchEntry>[
  _MatchEntry(category: 'Sports', scoreDelta: 80, date: 'Today'),
  _MatchEntry(category: 'Science', scoreDelta: 50, date: 'Today'),
  _MatchEntry(category: 'World Facts', scoreDelta: -20, date: 'Yesterday'),
  _MatchEntry(category: 'Tech', scoreDelta: 80, date: 'Yesterday'),
  _MatchEntry(category: 'Entertainment', scoreDelta: 30, date: '2 days ago'),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('ME', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        backgroundColor: theme.appColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(appThemeProvider.notifier).toggleTheme(),
            icon: Icon(
              theme.brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode,
              color: theme.appColors.onSurface,
            ),
          ),
        ],
      ),
      body: DotGridBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 24),
              const _StatsRow(),
              const SizedBox(height: 28),
              Text('RECENT MATCHES', style: theme.appTextTheme.subHeading),
              const SizedBox(height: 12),
              ..._recentMatches.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MatchRow(match: m),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.appColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: theme.appColors.border!, width: 3),
            boxShadow: [
              BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4), blurRadius: 0),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/user.svg',
              width: 36,
              height: 36,
              colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JoshT', style: theme.appTextTheme.heading?.copyWith(fontSize: 28)),
            Text('LVL 12 · BRAIN SQUAD', style: theme.appTextTheme.body?.copyWith(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            svgAsset: 'assets/icons/chart-bar.svg',
            label: 'TOTAL PTS',
            value: '4,280',
            colorIndex: 0,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            svgAsset: 'assets/icons/trophy.svg',
            label: 'MATCHES',
            value: '42',
            colorIndex: 1,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            svgAsset: 'assets/icons/fire.svg',
            label: 'STREAK',
            value: '5',
            colorIndex: 2,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String svgAsset;
  final String label;
  final String value;
  final int colorIndex;

  const _StatCard({
    required this.svgAsset,
    required this.label,
    required this.value,
    required this.colorIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [theme.appColors.primary!, theme.appColors.secondary!, theme.appColors.accent!];
    final color = colors[colorIndex];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            svgAsset,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.appTextTheme.heading?.copyWith(fontSize: 22)),
          Text(
            label,
            style: theme.appTextTheme.body?.copyWith(fontSize: 10, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final _MatchEntry match;
  const _MatchRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = match.scoreDelta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.category.toUpperCase(),
                  style: theme.appTextTheme.body?.copyWith(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                Text(
                  match.date,
                  style: theme.appTextTheme.body?.copyWith(
                    fontSize: 11,
                    color: theme.appColors.onSurface?.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            isPositive ? '+${match.scoreDelta}' : '${match.scoreDelta}',
            style: theme.appTextTheme.heading?.copyWith(
              fontSize: 20,
              color: isPositive ? theme.appColors.success : theme.appColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/features/home/view/profile_screen_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/view/profile_screen.dart test/features/home/view/profile_screen_test.dart
git commit -m "feat: add ProfileScreen with stats, avatar, and recent matches"
```

---

## Task 11: Wire new screens in main_screen.dart + World Rank navigation

**Files:**
- Modify: `lib/features/home/view/main_screen.dart`

- [ ] **Step 1: Add imports for the three new screens**

At the top of `main_screen.dart`, after the existing imports, add:
```dart
import 'clubs_screen.dart';
import 'profile_screen.dart';
import 'world_rank_screen.dart';
```

- [ ] **Step 2: Replace PlaceholderScreens with real screens in `_MainScreenState.build`**

Find in the `screens` list (lines 27–31):
```dart
    final screens = [
      HomeScreen(onPlayDaily: _onPlayTapped),
      const GameScreen(),
      const PlaceholderScreen(title: 'CLUBS'),
      const PlaceholderScreen(title: 'PROFILE'),
    ];
```
Replace with:
```dart
    final screens = [
      HomeScreen(onPlayDaily: _onPlayTapped),
      const GameScreen(),
      const ClubsScreen(),
      const ProfileScreen(),
    ];
```

- [ ] **Step 3: Add World Rank tap navigation in HomeScreen.build**

In `HomeScreen.build`, find the World Rank `_BigStatCard` (lines 119–123):
```dart
            _BigStatCard(
              title: 'WORLD RANK',
              value: '#${NumberFormat('#,###').format(gameState.worldRank)}',
              color: theme.appColors.secondary!,
              icon: Icons.public,
            ),
```
Replace with:
```dart
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorldRankScreen()),
              ),
              child: _BigStatCard(
                title: 'WORLD RANK',
                value: '#${NumberFormat('#,###').format(gameState.worldRank)}',
                color: theme.appColors.secondary!,
                icon: Icons.public,
              ),
            ),
```

- [ ] **Step 4: Run the app and verify all tabs work**

```bash
flutter run
```

Verify:
- HOME tab: existing home screen unchanged
- PLAY tab: game with dot grid, fixed animations
- CLUBS tab: Clubs screen with "MY CLUB" / "DISCOVER" sections; tapping club navigates to Club Rank
- ME tab: Profile screen with avatar, stats, recent matches
- Tapping WORLD RANK card on home navigates to World Rank leaderboard with back button

- [ ] **Step 5: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/view/main_screen.dart
git commit -m "feat: wire ClubsScreen, ProfileScreen, and WorldRankScreen navigation"
```

---

## Task 12: Update GEMINI.md

**Files:**
- Modify: `GEMINI.md`

- [ ] **Step 1: Update GEMINI.md with all new information**

Replace the entire `GEMINI.md` file content with:

```markdown
# SORTA - The Ultimate Ranking Game

## The Vibe
Modern, simple, colorful, cool. Neo-Brutalist UI with **Space Grotesk** typography, hard shadows, and thick black borders. Chunky drag-and-drop mechanics. Dot-grid background on all screens except home.

## Core Mechanic
Bold prompts with five massive text cards. Users drag and drop cards to sort them in the correct order.

---

## Technical Stack

### Frontend (Flutter)
- **State Management:** Riverpod (`flutter_riverpod`) using `Notifier` for robust, scalable state.
- **Local Database:** Isar v4 (High-performance NoSQL) for offline-first capabilities.
- **Theming:** Custom `ThemeExtension` (AppColors, AppTextTheme) with support for Light and Dark modes.
- **Typography:** `google_fonts` (Space Grotesk).
- **Architecture:** Feature-based MVVM (Model-View-ViewModel).
- **Number Formatting:** `intl` package for scores and ranks.
- **SVG Icons:** `flutter_svg` + Heroicons 2 outline (assets/icons/).

### Content Pipeline (External)
- **Generation:** Node.js script using **NVIDIA Nemotron-3 Super 120B** model via NVIDIA NIM API.
- **Categories:** Sports, Entertainment, World Facts, Science, Math, Tech, ALL.
- **Output:** Structured JSON batches for Firestore injection.

---

## Gameplay & Logic

### Match Structure
- **5-Question Match:** A single match consists of 5 ranking puzzles.
- **Start Overlay:** A blurred background with a pulsating START button (scale + opacity breathe effect) triggers the first question.
- **Auto-Advance:** Questions flow seamlessly until the "Match Complete" results screen.
- **Daily Sort:** A special daily challenge accessible from the Home screen.

### Scoring System (Competitive)
- **Correct Card:** +10 points.
- **Perfect Bonus:** +30 points (Total +80 for all correct).
- **Wrong Card:** -5 points.
- **All Wrong Penalty:** -35 points (Total -60 for all incorrect).
- **Streak Multiplier:** Perfect scores increase your streak, multiplying subsequent match scores.
- **Speed Bonus:** Remaining time (in seconds) is added to your score for perfect sorts.

### UI Features
- **Smooth Pulse Timer:** Progress bar oscillates smoothly (CurvedAnimation + easeInOut) and turns red/glows when time (30s) is running low.
- **Floating Scores:** Individual card scores (+10 / -5) float from the card's bottom to top with a fade-out — clipped inside the card bounds (ClipRRect + Clip.hardEdge).
- **Fixed Layout:** `LayoutBuilder` ensures the game is scroll-free on all devices.
- **Category Dropdown:** Quickly switch categories directly from the Play screen.
- **Dot Grid Background:** `DotGridBackground` widget (CustomPainter) applies a 1px dot on 20×20px grid behind all screens except home.

---

## Screens

| Screen | File | Tab | Notes |
|--------|------|-----|-------|
| Home | `main_screen.dart` (HomeScreen) | HOME | Stats, daily sort, clubs; world rank card navigates to WorldRankScreen |
| Play/Game | `game_screen.dart` | PLAY | Drag-and-drop, timer, start overlay |
| Clubs | `clubs_screen.dart` | CLUBS | My club card (→ ClubRankScreen) + discover list |
| Club Rank | `club_rank_screen.dart` | — (pushed) | Club leaderboard, podium cards |
| World Rank | `world_rank_screen.dart` | — (pushed from home) | Global leaderboard, podium, your position banner |
| Profile | `profile_screen.dart` | ME | Avatar, stats cards, recent matches, theme toggle |

---

## Icon System (Heroicons 2 Outline)

Icons stored in `assets/icons/`, rendered via `SvgPicture.asset()` with `colorFilter: ColorFilter.mode(color, BlendMode.srcIn)`.

| Asset | Usage |
|-------|-------|
| `user.svg` | User avatar in rank rows, profile header, podium cards |
| `user-group.svg` | Club cards in ClubsScreen |
| `trophy.svg` | Matches stat in ProfileScreen |
| `chart-bar.svg` | Total points stat in ProfileScreen |
| `fire.svg` | Streak stat in ProfileScreen |
| `globe-alt.svg` | Reserved for future world rank card icon |

---

## Project Structure

```text
lib/
├── core/
│   ├── theme/
│   │   ├── extensions/       # AppColorsExtension, AppTextThemeExtension
│   │   ├── app_palette.dart  # Raw color constants
│   │   ├── app_theme.dart    # Theme orchestrator (Riverpod Notifier)
│   │   └── app_typography.dart # Font styles (Space Grotesk)
│   ├── widgets/
│   │   └── dot_grid_background.dart  # DotGridPainter + DotGridBackground
│   ├── isar_service.dart
│   └── isar_provider.dart
├── features/
│   ├── game/
│   │   ├── data/
│   │   ├── view/game_screen.dart
│   │   └── view_model/
│   └── home/
│       └── view/
│           ├── main_screen.dart       # Shell, HomeScreen, BottomNav
│           ├── world_rank_screen.dart # Global leaderboard
│           ├── clubs_screen.dart      # My club + discover
│           ├── club_rank_screen.dart  # Club member leaderboard
│           └── profile_screen.dart   # User profile + stats
assets/
└── icons/
    ├── user.svg
    ├── user-group.svg
    ├── trophy.svg
    ├── chart-bar.svg
    ├── fire.svg
    └── globe-alt.svg
```

---

## Content Pipeline Usage
1. Navigate to `scripts/`.
2. Add your `NVIDIA_API_KEY` to `.env` (variable `OPENAI_API_KEY`).
3. Run `node generate_puzzles.js <CATEGORY>` or `node generate_puzzles.js ALL`.
```

- [ ] **Step 2: Commit**

```bash
git add GEMINI.md
git commit -m "docs: update GEMINI.md with new screens, icon system, and animation details"
```
