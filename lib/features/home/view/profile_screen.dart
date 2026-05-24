import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/navii_avatar.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';
import '../../auth/view_model/auth_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appColors.background,
        elevation: 0,
        title: Text('PROFILE',
            style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings_outlined, color: theme.appColors.onSurface),
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: theme.appColors.border!, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (val) {
              if (val == 'logout') {
                ref.read(authViewModelProvider.notifier).signOut();
              } else if (val == 'edit_name') {
                final profile = profileAsync.asData?.value;
                if (profile != null) {
                  showDialog(
                    context: context,
                    builder: (context) => _EditNameDialog(currentName: profile.displayName),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit_name',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 20, color: theme.appColors.onSurface),
                    const SizedBox(width: 12),
                    Text('EDIT NAME', style: theme.appTextTheme.body?.copyWith(fontSize: 13, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: theme.appColors.danger),
                    const SizedBox(width: 12),
                    Text('SIGN OUT', style: theme.appTextTheme.body?.copyWith(fontSize: 13, fontWeight: FontWeight.w900, color: theme.appColors.danger)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DotGridBackground(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (profile) {
            if (profile == null) return const Center(child: Text('Please log in'));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 32),
                  _StatsGrid(profile: profile),
                  const SizedBox(height: 32),
                  Text('RECENT MATCHES', style: theme.appTextTheme.subHeading),
                  const SizedBox(height: 16),
                  const _RecentMatchesList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(6, 6))
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showAvatarPicker(context, ref, profile.avatarSeed),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    color: theme.appColors.primary?.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.appColors.border!, width: 4),
                  ),
                  child: ClipOval(
                    child: NaviiAvatar(seed: profile.avatarSeed, size: 110),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.appColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.appColors.border!, width: 2.5),
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(profile.displayName.toUpperCase(),
              style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.appColors.accent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.appColors.border!, width: 2),
            ),
            child: Text(
              'LVL ${profile.level} · ${profile.levelLabel.toUpperCase()}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref, String currentSeed) {
    showDialog(
      context: context,
      builder: (context) => _ChooseAvatarDialog(currentSeed: currentSeed),
    );
  }
}

class _EditNameDialog extends ConsumerStatefulWidget {
  final String currentName;
  const _EditNameDialog({required this.currentName});

  @override
  ConsumerState<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<_EditNameDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name == widget.currentName) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await ref.read(userActionsProvider).updateDisplayName(name);
    
    if (mounted) {
      if (err != null) {
        setState(() {
          _loading = false;
          _error = err;
        });
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.appColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.appColors.border!, width: 4),
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text('EDIT NAME', style: theme.appTextTheme.heading?.copyWith(fontSize: 22)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.appColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.appColors.border!, width: 2),
              ),
              errorText: _error,
            ),
            style: theme.appTextTheme.body?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('CANCEL', style: theme.appTextTheme.button),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.appColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.appColors.border!, width: 2),
            ),
          ),
          child: _loading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _ChooseAvatarDialog extends ConsumerStatefulWidget {
  final String currentSeed;
  const _ChooseAvatarDialog({required this.currentSeed});

  @override
  ConsumerState<_ChooseAvatarDialog> createState() => _ChooseAvatarDialogState();
}

class _ChooseAvatarDialogState extends ConsumerState<_ChooseAvatarDialog> {
  late String _tempSeed;
  final _controller = TextEditingController();

  static const List<String> _presets = [
    'Sorta', 'Cool', 'Vibe', 'Champion', 'Hero', 'Ghost',
    'Neon', 'Cyber', 'Legend', 'Swift', 'Flash', 'Magic',
    'Star', 'Fire', 'Water', 'Earth', 'Wind', 'Storm'
  ];

  @override
  void initState() {
    super.initState();
    _tempSeed = widget.currentSeed;
    _controller.text = _tempSeed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateRandom() {
    final newSeed = Random().nextInt(1000000).toString();
    setState(() {
      _tempSeed = newSeed;
      _controller.text = newSeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.appColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.appColors.border!, width: 4),
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text('CHOOSE YOUR VIBE',
          textAlign: TextAlign.center,
          style: theme.appTextTheme.heading?.copyWith(fontSize: 22)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: theme.appColors.secondary?.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.appColors.border!, width: 3),
                ),
                child: ClipOval(
                  child: NaviiAvatar(seed: _tempSeed, size: 120),
                ),
              ),
              const SizedBox(height: 24),
              // Preset Grid
              Text('PRESETS',
                  style: theme.appTextTheme.body?.copyWith(
                      fontSize: 10, fontWeight: FontWeight.w900, color: theme.appColors.onSurface?.withOpacity(0.5))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _presets.map((p) {
                  final isSelected = _tempSeed == p;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _tempSeed = p;
                      _controller.text = p;
                    }),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? theme.appColors.primary : theme.appColors.background,
                        border: Border.all(
                            color: theme.appColors.border!,
                            width: isSelected ? 2.5 : 1.5),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(child: NaviiAvatar(seed: p, size: 48)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Custom Input
              TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: theme.appTextTheme.body?.copyWith(fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  hintText: 'Type your name or any word...',
                  hintStyle: theme.appTextTheme.body?.copyWith(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: theme.appColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.appColors.border!, width: 2),
                  ),
                ),
                onChanged: (val) => setState(() => _tempSeed = val),
              ),
              const SizedBox(height: 12),
              _NeoSmallButton(
                label: 'SHUFFLE',
                icon: Icons.refresh,
                onTap: _generateRandom,
                color: theme.appColors.secondary!,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: _NeoSmallButton(
                label: 'CANCEL',
                onTap: () => Navigator.pop(context),
                color: theme.appColors.surface!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NeoSmallButton(
                label: 'SAVE',
                onTap: () {
                  ref.read(userActionsProvider).updateAvatar(_tempSeed);
                  Navigator.pop(context);
                },
                color: theme.appColors.primary!,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NeoSmallButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color;
  const _NeoSmallButton({
    required this.label,
    this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: theme.appColors.border!, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: theme.appColors.shadow!, offset: const Offset(3, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.black),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final UserProfile profile;
  const _StatsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'TOTAL PTS',
            value: NumberFormat('#,###').format(profile.totalScore),
            icon: 'assets/icons/chart-bar.svg',
            color: const Color(0xFFFFD600),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'MATCHES',
            value: profile.matchesPlayed.toString(),
            icon: 'assets/icons/trophy.svg',
            color: const Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'STREAK',
            value: profile.currentStreak.toString(),
            icon: 'assets/icons/fire.svg',
            color: const Color(0xFFFF4081),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4))
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(icon, width: 24, height: 24),
          const SizedBox(height: 8),
          Text(value, style: theme.appTextTheme.heading?.copyWith(fontSize: 18)),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 8)),
        ],
      ),
    );
  }
}

class _RecentMatchesList extends ConsumerWidget {
  const _RecentMatchesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(recentMatchesProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (matches) {
        if (matches.isEmpty) return const _NoMatchesPlaceholder();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _MatchRow(match: match, isLast: index == matches.length - 1);
          },
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  final MatchRecord match;
  final bool isLast;
  const _MatchRow({required this.match, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWin = match.scoreDelta > 0;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWin ? theme.appColors.success : theme.appColors.danger,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWin ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.category.toUpperCase(),
                    style: theme.appTextTheme.body
                        ?.copyWith(fontSize: 12, fontWeight: FontWeight.w900)),
                Text(match.relativeDate,
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.appColors.onSurface?.withOpacity(0.5))),
              ],
            ),
          ),
          Text(
            '${isWin ? '+' : ''}${match.scoreDelta}',
            style: theme.appTextTheme.body?.copyWith(
                fontWeight: FontWeight.w900,
                color: isWin ? theme.appColors.success : theme.appColors.danger),
          ),
        ],
      ),
    );
  }
}

class _NoMatchesPlaceholder extends StatelessWidget {
  const _NoMatchesPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!.withOpacity(0.1), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No matches yet. Hit PLAY to start!',
        textAlign: TextAlign.center,
        style: theme.appTextTheme.body
            ?.copyWith(color: theme.appColors.onSurface?.withOpacity(0.5)),
      ),
    );
  }
}
