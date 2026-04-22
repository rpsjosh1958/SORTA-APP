import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/models/club_info.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';

class WorldRankScreen extends ConsumerWidget {
  const WorldRankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ranksAsync = ref.watch(worldRankProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);

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
        child: ranksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Failed to load rankings')),
          data: (ranks) {
            if (ranks.isEmpty) {
              return Center(child: Text('No rankings yet', style: theme.appTextTheme.body));
            }

            final myUid = currentUser?.uid;
            final profile = profileAsync.asData?.value;

            // Prefer the rank derived from the live query; fall back to stored field
            final myEntry = myUid != null
                ? ranks.where((r) => r.uid == myUid).firstOrNull
                : null;
            final showBanner = myEntry != null ||
                (profile != null && profile.worldRank > 0);
            final bannerRank = myEntry?.rank ?? profile?.worldRank ?? 0;
            final bannerScore = myEntry?.totalScore ?? profile?.totalScore ?? 0;
            final bannerName = myEntry?.displayName ?? profile?.displayName ?? '';

            final top3 = ranks.take(3).toList();
            final rest = ranks.skip(3).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PodiumRow(ranks: top3, myUid: myUid),
                  const SizedBox(height: 16),
                  if (showBanner) ...[
                    _YourPositionBanner(
                      rank: bannerRank,
                      score: bannerScore,
                      displayName: bannerName,
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...rest.asMap().entries.map((e) => _RankRow(
                        entry: e.value,
                        isMe: e.value.uid == myUid,
                        isLast: e.key == rest.length - 1,
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<WorldRankEntry> ranks;
  final String? myUid;
  const _PodiumRow({required this.ranks, required this.myUid});

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
            child: _PodiumCard(entry: ranks[i], color: colors[i], isMe: ranks[i].uid == myUid),
          ),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final WorldRankEntry entry;
  final Color color;
  final bool isMe;
  const _PodiumCard({required this.entry, required this.color, required this.isMe});

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
          Text('#${entry.rank}', style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          SvgPicture.asset(
            'assets/icons/user.svg',
            width: 26,
            height: 26,
            colorFilter: ColorFilter.mode(theme.appColors.onSurface!, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            isMe ? '${entry.displayName} ★' : entry.displayName,
            style: theme.appTextTheme.body?.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            NumberFormat('#,###').format(entry.totalScore),
            style: theme.appTextTheme.body?.copyWith(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _YourPositionBanner extends StatelessWidget {
  final int rank;
  final int score;
  final String displayName;
  const _YourPositionBanner({required this.rank, required this.score, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.appColors.secondary!.withOpacity(0.15),
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
            '#$rank',
            style: theme.appTextTheme.heading?.copyWith(fontSize: 20, color: theme.appColors.secondary),
          ),
          const SizedBox(width: 12),
          Text(
            '${NumberFormat('#,###').format(score)} pts',
            style: theme.appTextTheme.body?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final WorldRankEntry entry;
  final bool isMe;
  final bool isLast;
  const _RankRow({required this.entry, required this.isMe, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? theme.appColors.secondary!.withOpacity(0.15) : theme.appColors.surface,
        border: Border.all(
          color: isMe ? theme.appColors.secondary! : theme.appColors.border!,
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
            child: Text(
              isMe ? '${entry.displayName} ★' : entry.displayName,
              style: theme.appTextTheme.body?.copyWith(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
          Text(
            NumberFormat('#,###').format(entry.totalScore),
            style: theme.appTextTheme.body?.copyWith(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
