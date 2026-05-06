import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:avatar_plus/avatar_plus.dart';
import '../../../core/models/club_info.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';

class WorldRankScreen extends ConsumerWidget {
  const WorldRankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ranksAsync = ref.watch(worldRankProvider);
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

            final top3 = ranks.take(3).toList();
            final rest = ranks.skip(3).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PodiumRow(ranks: top3, myUid: myUid),
                  const SizedBox(height: 24),
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
    final textColor = isMe ? Colors.white : theme.appColors.onSurface!;

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
          Text('#${entry.rank}', style: theme.appTextTheme.heading?.copyWith(fontSize: 20, color: textColor)),
          const SizedBox(height: 6),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: textColor.withOpacity(0.5), width: 1.5),
            ),
            child: ClipOval(
              child: AvatarPlus(entry.avatarSeed, width: 40, height: 40),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMe ? '${entry.displayName} ★' : entry.displayName,
            style: theme.appTextTheme.body?.copyWith(fontSize: 11, color: textColor),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            NumberFormat('#,###').format(entry.totalScore),
            style: theme.appTextTheme.body?.copyWith(fontSize: 12, fontWeight: FontWeight.w900, color: textColor),
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
    final rowColor = isMe 
        ? theme.appColors.primary
        : theme.appColors.surface;
    final borderColor = isMe 
        ? theme.appColors.primary! 
        : theme.appColors.border!;
    final textColor = isMe ? Colors.white : theme.appColors.onSurface!;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border.all(
          color: borderColor,
          width: isMe ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.appColors.shadow!, 
            offset: isMe ? const Offset(4, 4) : const Offset(3, 3), 
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: theme.appTextTheme.body?.copyWith(
                fontSize: 13, 
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: textColor.withOpacity(0.3), width: 1),
            ),
            child: ClipOval(
              child: AvatarPlus(entry.avatarSeed, width: 28, height: 28),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? '${entry.displayName} (YOU)' : entry.displayName,
              style: theme.appTextTheme.body?.copyWith(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          Text(
            NumberFormat('#,###').format(entry.totalScore),
            style: theme.appTextTheme.body?.copyWith(
              fontSize: 14, 
              fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
