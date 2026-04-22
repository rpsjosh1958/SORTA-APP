import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';
import '../../../core/widgets/neo_dropdown.dart';
import '../../../features/auth/view_model/auth_view_model.dart';

const _settingsItems = [
  NeoDropdownItem(value: 'sign_out', label: 'Sign Out', icon: Icons.logout_rounded),
  NeoDropdownItem(value: 'edit_name', label: 'Edit Name', icon: Icons.edit_rounded),
  NeoDropdownItem(value: 'avatar', label: 'Choose Avatar', icon: Icons.face_rounded),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _onSettingSelected(BuildContext context, WidgetRef ref, String value) {
    if (value == 'sign_out') {
      ref.read(authViewModelProvider.notifier).signOut();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${value == 'edit_name' ? 'Edit name' : 'Avatar picker'} coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final matchesAsync = ref.watch(recentMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('ME', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        backgroundColor: theme.appColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NeoDropdown<String>(
              items: _settingsItems,
              onSelected: (v) => _onSettingSelected(context, ref, v),
              minMenuWidth: 180,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.appColors.surface,
                  border: Border.all(color: theme.appColors.border!, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: theme.appColors.shadow!, offset: const Offset(2, 2), blurRadius: 0),
                  ],
                ),
                child: Icon(Icons.settings_rounded, color: theme.appColors.onSurface, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: DotGridBackground(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => const Center(child: Text('Failed to load profile')),
          data: (profile) {
            if (profile == null) return const Center(child: CircularProgressIndicator());
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 24),
                  _StatsRow(profile: profile),
                  const SizedBox(height: 28),
                  Text('RECENT MATCHES', style: theme.appTextTheme.subHeading),
                  const SizedBox(height: 12),
                  matchesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (matches) => matches.isEmpty
                        ? _EmptyMatches(theme: theme)
                        : Column(
                            children: matches
                                .map((m) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _MatchRow(match: m),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final UserProfile profile;

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
            Text(profile.displayName, style: theme.appTextTheme.heading?.copyWith(fontSize: 28)),
            Text(
              'LVL ${profile.level} · ${profile.levelLabel.toUpperCase()}',
              style: theme.appTextTheme.body?.copyWith(fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            svgAsset: 'assets/icons/chart-bar.svg',
            label: 'TOTAL PTS',
            value: NumberFormat('#,###').format(profile.totalScore),
            color: theme.appColors.primary!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            svgAsset: 'assets/icons/trophy.svg',
            label: 'MATCHES',
            value: NumberFormat('#,###').format(profile.matchesPlayed),
            color: theme.appColors.secondary!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            svgAsset: 'assets/icons/fire.svg',
            label: 'STREAK',
            value: '${profile.currentStreak}',
            color: theme.appColors.accent!,
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
  final Color color;

  const _StatCard({
    required this.svgAsset,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
  final MatchRecord match;
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
                  match.isDailySort ? 'DAILY SORT' : match.category.toUpperCase(),
                  style: theme.appTextTheme.body?.copyWith(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                Text(
                  match.relativeDate,
                  style: theme.appTextTheme.body?.copyWith(
                    fontSize: 11,
                    color: theme.appColors.onSurface?.withOpacity(0.5),
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

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.appColors.surface,
        border: Border.all(color: theme.appColors.border!, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Text(
        'No matches yet. Hit PLAY to start!',
        textAlign: TextAlign.center,
        style: theme.appTextTheme.body?.copyWith(color: theme.appColors.onSurface?.withOpacity(0.5)),
      ),
    );
  }
}
