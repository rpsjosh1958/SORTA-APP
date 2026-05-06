import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:avatar_plus/avatar_plus.dart';
import '../../../core/models/challenge.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/challenge_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';
import '../view_model/versus_game_vm.dart';

class VersusScreen extends ConsumerWidget {
  const VersusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(activeChallengeProvider);

    return challengeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _VersusSearchView(),
      data: (challenge) {
        if (challenge == null) return const _VersusSearchView();

        final myUid = ref.read(currentUserProvider)?.uid ?? '';

        return switch (challenge.status) {
          ChallengeStatus.pending when challenge.challengerUid == myUid =>
            _VersusWaitingView(challenge: challenge),
          ChallengeStatus.pending => _VersusIncomingView(challenge: challenge),
          ChallengeStatus.accepted => _VersusLobbyView(challenge: challenge),
          ChallengeStatus.countdown =>
            _VersusCountdownView(challenge: challenge),
          ChallengeStatus.active => _VersusGameView(challenge: challenge),
          ChallengeStatus.complete ||
          ChallengeStatus.rematchRequested =>
            _VersusResultView(challenge: challenge),
          _ => const _VersusSearchView(),
        };
      },
    );
  }
}

// ─── Search ───────────────────────────────────────────────────────────────────

class _VersusSearchView extends ConsumerStatefulWidget {
  const _VersusSearchView();

  @override
  ConsumerState<_VersusSearchView> createState() => _VersusSearchViewState();
}

class _VersusSearchViewState extends ConsumerState<_VersusSearchView> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _challenge() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref
        .read(challengeActionsProvider.notifier)
        .sendChallenge(_ctrl.text);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title:
            Text('VERSUS', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
      ),
      body: DotGridBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.appColors.accent,
                  border: Border.all(color: theme.appColors.border!, width: 4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: theme.appColors.shadow!,
                        offset: const Offset(6, 6))
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_kabaddi_rounded,
                        size: 64, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      '1 vs 1 BATTLE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Challenge a player by username',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _NeoField(
                controller: _ctrl,
                hint: 'Enter username',
                icon: Icons.person_search,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.appColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.appColors.border!, width: 2),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _NeoButton(
                label: _loading ? 'SENDING...' : 'CHALLENGE',
                onTap: _loading ? null : _challenge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Waiting (challenger) ─────────────────────────────────────────────────────

class _VersusWaitingView extends ConsumerWidget {
  final Challenge challenge;
  const _VersusWaitingView({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title:
            Text('VERSUS', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
      ),
      body: DotGridBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PlayerBadge(name: challenge.challengerName, isMe: true),
                const SizedBox(height: 16),
                Text('VS',
                    style: theme.appTextTheme.heading
                        ?.copyWith(fontSize: 40, color: theme.appColors.accent)),
                const SizedBox(height: 16),
                _PlayerBadge(name: challenge.opponentName, isMe: false),
                const SizedBox(height: 40),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Waiting for ${challenge.opponentName} to accept...',
                  style: theme.appTextTheme.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _NeoButton(
                  label: 'CANCEL',
                  color: theme.appColors.danger!,
                  onTap: () => ref
                      .read(challengeActionsProvider.notifier)
                      .cancelChallenge(challenge.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Incoming (opponent) ──────────────────────────────────────────────────────

class _VersusIncomingView extends ConsumerWidget {
  final Challenge challenge;
  const _VersusIncomingView({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.read(challengeActionsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title:
            Text('VERSUS', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
      ),
      body: DotGridBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.appColors.primary,
                    border:
                        Border.all(color: theme.appColors.border!, width: 4),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: theme.appColors.shadow!,
                          offset: const Offset(6, 6))
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.sports_kabaddi_rounded, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        '${challenge.challengerName} CHALLENGES YOU!',
                        style: theme.appTextTheme.heading?.copyWith(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _PlayerBadge(name: challenge.challengerName, isMe: false),
                const SizedBox(height: 12),
                Text('VS',
                    style: theme.appTextTheme.heading
                        ?.copyWith(fontSize: 40, color: theme.appColors.accent)),
                const SizedBox(height: 12),
                _PlayerBadge(name: challenge.opponentName, isMe: true),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _NeoButton(
                        label: 'DECLINE',
                        color: theme.appColors.danger!,
                        onTap: () =>
                            actions.declineChallenge(challenge.id),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _NeoButton(
                        label: 'ACCEPT',
                        color: theme.appColors.success!,
                        onTap: () =>
                            actions.acceptChallenge(challenge.id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lobby ────────────────────────────────────────────────────────────────────

class _VersusLobbyView extends ConsumerWidget {
  final Challenge challenge;
  const _VersusLobbyView({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myUid = ref.read(currentUserProvider)?.uid ?? '';
    final amChallenger = challenge.challengerUid == myUid;
    final myReady = challenge.isReadyFor(myUid);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title:
            Text('LOBBY', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
      ),
      body: DotGridBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LobbyPlayerRow(
                  name: challenge.challengerName,
                  isReady: challenge.challengerReady,
                  isMe: amChallenger,
                ),
                const SizedBox(height: 20),
                Text('VS',
                    style: theme.appTextTheme.heading
                        ?.copyWith(fontSize: 40, color: theme.appColors.accent)),
                const SizedBox(height: 20),
                _LobbyPlayerRow(
                  name: challenge.opponentName,
                  isReady: challenge.opponentReady,
                  isMe: !amChallenger,
                ),
                const SizedBox(height: 48),
                if (!myReady)
                  _NeoButton(
                    label: 'READY',
                    color: theme.appColors.success!,
                    onTap: () => ref
                        .read(challengeActionsProvider.notifier)
                        .setReady(challenge.id, amChallenger),
                  )
                else
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text('Waiting for opponent...',
                          style: theme.appTextTheme.body),
                    ],
                  ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => ref
                      .read(challengeActionsProvider.notifier)
                      .cancelChallenge(challenge.id),
                  child: Text('Leave',
                      style: TextStyle(color: theme.appColors.danger)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyPlayerRow extends StatelessWidget {
  final String name;
  final bool isReady;
  final bool isMe;
  const _LobbyPlayerRow(
      {required this.name, required this.isReady, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isReady ? theme.appColors.success : theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: theme.appColors.shadow!, offset: const Offset(4, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(isReady ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isReady ? Colors.white : theme.appColors.onSurface,
              size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name + (isMe ? ' (you)' : ''),
              style: theme.appTextTheme.body?.copyWith(
                fontSize: 16,
                color: isReady ? Colors.white : theme.appColors.onSurface,
              ),
            ),
          ),
          if (isReady)
            const Text('READY',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ─── Countdown ────────────────────────────────────────────────────────────────

class _VersusCountdownView extends ConsumerStatefulWidget {
  final Challenge challenge;
  const _VersusCountdownView({required this.challenge});

  @override
  ConsumerState<_VersusCountdownView> createState() =>
      _VersusCountdownViewState();
}

class _VersusCountdownViewState extends ConsumerState<_VersusCountdownView>
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late AnimationController _shakeCtrl;
  late Animation<Offset> _leftSlide;
  late Animation<Offset> _rightSlide;
  late Animation<double> _shake;

  int _countdown = 3;
  bool _showGo = false;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _leftSlide = Tween<Offset>(
            begin: const Offset(-1.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _rightSlide = Tween<Offset>(
            begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _shake = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _runSequence();

    // Load questions during countdown
    final ids = widget.challenge.questionIds;
    if (ids.isNotEmpty) {
      ref.read(versusGameVmProvider.notifier).loadQuestions(ids);
    }
  }

  void _runSequence() async {
    await _slideCtrl.forward();
    _shakeCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 500));
    _shakeCtrl.stop();
    _shakeCtrl.reset();

    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _showGo = true;
          t.cancel();
          _onCountdownDone();
        }
      });
    });
  }

  void _onCountdownDone() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _started) return;
    _started = true;

    final myUid = ref.read(currentUserProvider)?.uid ?? '';
    // Only the challenger sets status to avoid double write
    if (widget.challenge.challengerUid == myUid) {
      await ref
          .read(challengeActionsProvider.notifier)
          .startGame(widget.challenge.id);
    }
    // Opponent will react to the stream update (status → active)
    // but we start their timer anyway so there's no delay
    ref.read(versusGameVmProvider.notifier).startTimer();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _shakeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shakeOffset = sin(_shake.value * pi * 8) * 8;

    return Scaffold(
      backgroundColor: theme.appColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clash row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SlideTransition(
                    position: _leftSlide,
                    child: Transform.translate(
                      offset: Offset(shakeOffset, 0),
                      child: _ClashCard(
                          name: widget.challenge.challengerName,
                          avatarSeed: widget.challenge.challengerUid, // Fallback to UID for now
                          color: theme.appColors.primary!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _shakeCtrl,
                    builder: (_, __) => Text(
                      'VS',
                      style: theme.appTextTheme.heading?.copyWith(
                          fontSize: 32, color: theme.appColors.accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SlideTransition(
                    position: _rightSlide,
                    child: Transform.translate(
                      offset: Offset(-shakeOffset, 0),
                      child: _ClashCard(
                          name: widget.challenge.opponentName,
                          avatarSeed: widget.challenge.opponentUid, // Fallback to UID
                          color: theme.appColors.secondary!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _showGo ? 'SORT!' : '$_countdown',
                  key: ValueKey(_showGo ? 'go' : _countdown),
                  style: theme.appTextTheme.heading?.copyWith(
                    fontSize: _showGo ? 72 : 96,
                    color: _showGo
                        ? theme.appColors.success
                        : theme.appColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClashCard extends StatelessWidget {
  final String name;
  final String avatarSeed;
  final Color color;
  const _ClashCard({required this.name, required this.avatarSeed, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: theme.appColors.shadow!, offset: const Offset(4, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.5),
            ),
            child: ClipOval(
              child: AvatarPlus(avatarSeed, width: 40, height: 40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.black,
                overflow: TextOverflow.ellipsis),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ─── Game ─────────────────────────────────────────────────────────────────────

class _VersusGameView extends ConsumerStatefulWidget {
  final Challenge challenge;
  const _VersusGameView({required this.challenge});

  @override
  ConsumerState<_VersusGameView> createState() => _VersusGameViewState();
}

class _VersusGameViewState extends ConsumerState<_VersusGameView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late CurvedAnimation _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    // Start timer if game VM was loaded from countdown
    final vm = ref.read(versusGameVmProvider);
    if (!vm.isLoading && vm.currentQuestion != null && !vm.isAnswered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !ref.read(versusGameVmProvider).isAnswered) {
          ref.read(versusGameVmProvider.notifier).startTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> anim) {
    return Material(elevation: 0, color: Colors.transparent, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gs = ref.watch(versusGameVmProvider);
    final gn = ref.read(versusGameVmProvider.notifier);
    final myUid = ref.read(currentUserProvider)?.uid ?? '';
    final answersAsync = ref.watch(challengeAnswersProvider(widget.challenge.id));
    final busyIncoming = ref.watch(busyIncomingChallengeProvider).asData?.value;

    // Pulse timer when <5s left
    if (gs.remainingTime < 5 && !gs.isAnswered) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }

    final opponentUid = widget.challenge.opponentUidFor(myUid);
    final opponentProgress =
        answersAsync.asData?.value[opponentUid];
    final opponentScore = opponentProgress?.totalScore ?? 0;
    final opponentDone = opponentProgress?.isComplete ?? false;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: _OpponentStrip(
                name: widget.challenge.opponentNameFor(myUid),
                avatarSeed: opponentUid, // Fallback for now
                score: opponentScore,
                questionsDone: opponentProgress?.answers.length ?? 0,
                isDone: opponentDone,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Q${gs.currentQuestionIndex + 1}/10',
                      style: theme.appTextTheme.body
                          ?.copyWith(fontWeight: FontWeight.w900, fontSize: 10)),
                  Text(
                    NumberFormat('#,###').format(gs.matchScore),
                    style: theme.appTextTheme.body?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: theme.appColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          DotGridBackground(
            child: gs.isLoading || gs.currentQuestion == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                        child: Text(
                          gs.currentQuestion!.prompt,
                          style: theme.appTextTheme.heading
                              ?.copyWith(fontSize: 20),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!gs.isAnswered)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, __) {
                              final isEnding = gs.remainingTime < 5;
                              final color = isEnding
                                  ? Color.lerp(
                                      theme.appColors.danger!,
                                      Colors.redAccent.shade700,
                                      _pulse.value)
                                  : theme.appColors.primary!;
                              return Opacity(
                                opacity: isEnding
                                    ? (0.6 + 0.4 * _pulse.value)
                                    : 1.0,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: theme.appColors.border!,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: gs.remainingTime / 30,
                                      backgroundColor: Colors.transparent,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color!),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            const spacing = 10.0;
                            final cardH =
                                (constraints.maxHeight - 16 - spacing * 4) / 5;
                            return ReorderableListView(
                              proxyDecorator: _proxyDecorator,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              onReorder: (old, nw) {
                                HapticFeedback.heavyImpact();
                                gn.reorderItems(old, nw);
                              },
                              children: [
                                for (int i = 0; i < gs.userOrder.length; i++)
                                  _VersusSortCard(
                                    key: ValueKey(gs.userOrder[i]),
                                    text: gs.userOrder[i],
                                    height: cardH,
                                    isAnswered: gs.isAnswered,
                                    isCorrect: gs.isAnswered &&
                                        gs.currentQuestion != null &&
                                        gs.userOrder[i] ==
                                            gs.currentQuestion!.items[i],
                                    score: gs.isAnswered &&
                                            gs.cardScores.isNotEmpty
                                        ? gs.cardScores[i]
                                        : null,
                                    margin: i == gs.userOrder.length - 1
                                        ? 0
                                        : spacing,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: _NeoButton(
                          label: gs.isAnswered
                              ? (gs.isComplete
                                  ? 'WAITING FOR OPPONENT...'
                                  : 'NEXT')
                              : 'SUBMIT',
                          onTap: gs.isAnswered
                              ? (gs.isComplete ? null : gn.loadNextQuestion)
                              : () {
                                  gn.submitAnswer();
                                  HapticFeedback.mediumImpact();
                                },
                        ),
                      ),
                    ],
                  ),
          ),
          // Waiting overlay after player finishes
          if (gs.isComplete)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'YOUR SCORE: ${NumberFormat('#,###').format(gs.matchScore)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Waiting for opponent...',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          // In-game banner when someone new challenges you
          if (busyIncoming != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _IncomingBanner(challenge: busyIncoming),
            ),
        ],
      ),
    );
  }
}

class _OpponentStrip extends StatelessWidget {
  final String name;
  final String avatarSeed;
  final int score;
  final int questionsDone;
  final bool isDone;
  const _OpponentStrip({
    required this.name,
    required this.avatarSeed,
    required this.score,
    required this.questionsDone,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.appColors.secondary,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(2, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
            ),
            child: ClipOval(
              child: AvatarPlus(avatarSeed, width: 24, height: 24),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      overflow: TextOverflow.ellipsis)),
              Text(
                isDone
                    ? 'DONE · ${NumberFormat('#,###').format(score)}'
                    : 'Q$questionsDone/10 · ${NumberFormat('#,###').format(score)}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomingBanner extends ConsumerWidget {
  final Challenge challenge;
  const _IncomingBanner({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: theme.appColors.accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            const Icon(Icons.sports_kabaddi_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${challenge.challengerName} wants to challenge you — respond after your game!',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Result ───────────────────────────────────────────────────────────────────

class _VersusResultView extends ConsumerStatefulWidget {
  final Challenge challenge;
  const _VersusResultView({required this.challenge});

  @override
  ConsumerState<_VersusResultView> createState() => _VersusResultViewState();
}

class _VersusResultViewState extends ConsumerState<_VersusResultView> {
  final _msgCtrl = TextEditingController();
  bool _chatOpen = false;
  bool _answersOpen = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myUid = ref.read(currentUserProvider)?.uid ?? '';
    final profile = ref.read(userProfileProvider).asData?.value;
    final answersMap =
        ref.watch(challengeAnswersProvider(widget.challenge.id)).asData?.value ?? {};
    final messages = ref
        .watch(challengeMessagesProvider(widget.challenge.id))
        .asData
        ?.value ?? [];

    final myAnswers = answersMap[myUid];
    final opponentUid = widget.challenge.opponentUidFor(myUid);
    final opponentAnswers = answersMap[opponentUid];

    final myScore = myAnswers?.totalScore ?? 0;
    final opponentScore = opponentAnswers?.totalScore ?? 0;
    final iWon = myScore > opponentScore;
    final isDraw = myScore == opponentScore;

    final resultColor = isDraw
        ? theme.appColors.secondary!
        : (iWon ? theme.appColors.success! : theme.appColors.danger!);
    final resultLabel = isDraw ? 'DRAW' : (iWon ? 'YOU WIN!' : 'YOU LOSE');

    final iRequestedRematch =
        widget.challenge.rematchRequestedBy == myUid;
    final opponentRequestedRematch =
        widget.challenge.rematchRequestedBy == opponentUid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title: Text('RESULT',
            style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => setState(() => _chatOpen = !_chatOpen),
          ),
        ],
      ),
      body: Stack(
        children: [
          DotGridBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Result banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: resultColor,
                      border: Border.all(
                          color: theme.appColors.border!, width: 4),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: theme.appColors.shadow!,
                            offset: const Offset(6, 6))
                      ],
                    ),
                    child: Text(
                      resultLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Score comparison
                  _ScoreRow(
                    leftName: widget.challenge.challengerName,
                    leftAvatar: widget.challenge.challengerUid, // Fallback
                    rightName: widget.challenge.opponentName,
                    rightAvatar: widget.challenge.opponentUid, // Fallback
                    leftScore: answersMap[widget.challenge.challengerUid]
                            ?.totalScore ??
                        0,
                    rightScore:
                        answersMap[widget.challenge.opponentUid]?.totalScore ??
                            0,
                    myUid: myUid,
                    challengerUid: widget.challenge.challengerUid,
                  ),
                  const SizedBox(height: 24),

                  // View answers toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _answersOpen = !_answersOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.appColors.surface,
                        border: Border.all(
                            color: theme.appColors.border!, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: theme.appColors.shadow!,
                              offset: const Offset(3, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('VIEW ANSWERS',
                              style: theme.appTextTheme.body
                                  ?.copyWith(fontWeight: FontWeight.w900)),
                          Icon(_answersOpen
                              ? Icons.expand_less
                              : Icons.expand_more),
                        ],
                      ),
                    ),
                  ),
                  if (_answersOpen && myAnswers != null) ...[
                    const SizedBox(height: 12),
                    _AnswersComparison(
                      myAnswers: myAnswers,
                      opponentAnswers: opponentAnswers,
                      questions: ref.read(versusGameVmProvider).questions,
                      myName: profile?.displayName ?? 'You',
                      opponentName:
                          widget.challenge.opponentNameFor(myUid),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Play again
                  if (opponentRequestedRematch && !iRequestedRematch) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.appColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.appColors.border!, width: 2),
                      ),
                      child: Text(
                        '${widget.challenge.opponentNameFor(myUid)} wants a rematch!',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  _NeoButton(
                    label: iRequestedRematch
                        ? 'WAITING FOR OPPONENT...'
                        : (opponentRequestedRematch
                            ? 'ACCEPT REMATCH!'
                            : 'PLAY AGAIN'),
                    color: theme.appColors.primary!,
                    onTap: iRequestedRematch
                        ? null
                        : () => ref
                            .read(challengeActionsProvider.notifier)
                            .requestRematch(widget.challenge.id, myUid),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref
                        .read(challengeActionsProvider.notifier)
                        .dismissResult(widget.challenge.id),
                    child: const Text('DONE — find new opponent'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Chat panel
          if (_chatOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ChatPanel(
                challengeId: widget.challenge.id,
                messages: messages,
                myUid: myUid,
                displayName: profile?.displayName ?? 'Player',
                controller: _msgCtrl,
                onSend: () {
                  ref
                      .read(challengeActionsProvider.notifier)
                      .sendMessage(
                        widget.challenge.id,
                        _msgCtrl.text,
                        profile?.displayName ?? 'Player',
                      );
                  _msgCtrl.clear();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String leftName, rightName;
  final String leftAvatar, rightAvatar;
  final int leftScore, rightScore;
  final String myUid, challengerUid;
  const _ScoreRow({
    required this.leftName,
    required this.leftAvatar,
    required this.rightName,
    required this.rightAvatar,
    required this.leftScore,
    required this.rightScore,
    required this.myUid,
    required this.challengerUid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leftWins = leftScore > rightScore;
    final rightWins = rightScore > leftScore;

    return Row(
      children: [
        Expanded(
          child: _ScoreCard(
            name: leftName,
            avatarSeed: leftAvatar,
            score: leftScore,
            isWinner: leftWins,
            isMe: myUid == challengerUid,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('VS',
              style: theme.appTextTheme.heading
                  ?.copyWith(fontSize: 20, color: theme.appColors.accent)),
        ),
        Expanded(
          child: _ScoreCard(
            name: rightName,
            avatarSeed: rightAvatar,
            score: rightScore,
            isWinner: rightWins,
            isMe: myUid != challengerUid,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String name;
  final String avatarSeed;
  final int score;
  final bool isWinner, isMe;
  const _ScoreCard({
    required this.name,
    required this.avatarSeed,
    required this.score,
    required this.isWinner,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isWinner ? theme.appColors.success! : theme.appColors.danger!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: AvatarPlus(avatarSeed, width: 44, height: 44),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name + (isMe ? '\n(you)' : ''),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat('#,###').format(score),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28),
          ),
        ],
      ),
    );
  }
}

class _AnswersComparison extends StatelessWidget {
  final ChallengePlayerAnswers myAnswers;
  final ChallengePlayerAnswers? opponentAnswers;
  final List questions;
  final String myName, opponentName;
  const _AnswersComparison({
    required this.myAnswers,
    required this.opponentAnswers,
    required this.questions,
    required this.myName,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (int qi = 0; qi < myAnswers.answers.length; qi++) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.appColors.surface,
              border:
                  Border.all(color: theme.appColors.border!, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${qi + 1}${qi < questions.length ? ': ${(questions[qi] as dynamic).prompt}' : ''}',
                  style: theme.appTextTheme.body
                      ?.copyWith(fontWeight: FontWeight.w900, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _AnswerColumn(
                        name: myName,
                        record: myAnswers.answers[qi],
                        correctItems: qi < questions.length
                            ? List<String>.from(
                                (questions[qi] as dynamic).items)
                            : [],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: opponentAnswers != null &&
                              qi < opponentAnswers!.answers.length
                          ? _AnswerColumn(
                              name: opponentName,
                              record: opponentAnswers!.answers[qi],
                              correctItems: qi < questions.length
                                  ? List<String>.from(
                                      (questions[qi] as dynamic).items)
                                  : [],
                            )
                          : const Center(child: Text('—')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AnswerColumn extends StatelessWidget {
  final String name;
  final VersusAnswerRecord record;
  final List<String> correctItems;
  const _AnswerColumn({
    required this.name,
    required this.record,
    required this.correctItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name,
            style: theme.appTextTheme.body
                ?.copyWith(fontWeight: FontWeight.w900, fontSize: 11),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        for (int i = 0; i < record.userOrder.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: i < correctItems.length &&
                      record.userOrder[i] == correctItems[i]
                  ? theme.appColors.success
                  : theme.appColors.danger,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              record.userOrder[i],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          '${record.score > 0 ? '+' : ''}${record.score} pts',
          style: theme.appTextTheme.body
              ?.copyWith(fontSize: 11, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final String challengeId;
  final List<ChallengeMessage> messages;
  final String myUid, displayName;
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatPanel({
    required this.challengeId,
    required this.messages,
    required this.myUid,
    required this.displayName,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border:
            Border(top: BorderSide(color: theme.appColors.border!, width: 3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('CHAT',
                style: theme.appTextTheme.body
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: messages.map((m) {
                final isMe = m.uid == myUid;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.appColors.accent
                          : theme.appColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: theme.appColors.border!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Say something...'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.appColors.accent,
                      border: Border.all(
                          color: theme.appColors.border!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _PlayerBadge extends StatelessWidget {
  final String name;
  final bool isMe;
  const _PlayerBadge({required this.name, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isMe ? theme.appColors.primary : theme.appColors.secondary,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4))
        ],
      ),
      child: Text(
        name + (isMe ? ' (you)' : ''),
        style: theme.appTextTheme.body
            ?.copyWith(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _NeoField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _NeoField(
      {required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        style:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black38,
              fontSize: 16),
          prefixIcon:
              Icon(icon, color: theme.appColors.border, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _NeoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const _NeoButton({required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = color ?? theme.appColors.primary!;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? bg : Colors.grey.shade300,
          border: Border.all(color: theme.appColors.border!, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: enabled
              ? [BoxShadow(
                  color: theme.appColors.shadow!,
                  offset: const Offset(4, 4))]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: enabled ? Colors.black : Colors.black38,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _VersusSortCard extends StatelessWidget {
  final String text;
  final double height;
  final bool isAnswered;
  final bool isCorrect;
  final int? score;
  final double margin;

  const _VersusSortCard({
    super.key,
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
              blurRadius: 0),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  text,
                  style: theme.appTextTheme.body?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: theme.appColors.onSurface),
                ),
                trailing: Icon(Icons.drag_handle,
                    color: theme.appColors.onSurface, size: 28),
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
                  builder: (_, v, child) {
                    return Transform.translate(
                      offset: Offset(0, -(v * height)),
                      child: Opacity(
                        opacity: v < 0.7
                            ? 1.0
                            : (1.0 - ((v - 0.7) / 0.3)).clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    score! > 0 ? '+$score' : '$score',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
