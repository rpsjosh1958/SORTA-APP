import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/models/club_info.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';

class ClubRankScreen extends ConsumerWidget {
  final String clubId;
  const ClubRankScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clubAsync = ref.watch(clubInfoProvider(clubId));
    final membersAsync = ref.watch(clubMembersProvider(clubId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: clubAsync.when(
          data: (club) => Text(
            club?.name.toUpperCase() ?? 'CLUB',
            style: theme.appTextTheme.heading?.copyWith(fontSize: 20),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text('CLUB'),
        ),
        backgroundColor: theme.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          clubAsync.when(
            data: (club) => club == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.copy_outlined, color: theme.appColors.onSurface),
                    tooltip: 'Copy invite code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: club.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Code ${club.code} copied!')),
                      );
                    },
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: DotGridBackground(
        child: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Failed to load members')),
          data: (members) {
            if (members.isEmpty) {
              return Center(
                child: Text('No members yet', style: theme.appTextTheme.body),
              );
            }

            final myUid = currentUser?.uid;
            final memberCount = clubAsync.asData?.value?.memberCount ?? members.length;
            final clubRank = clubAsync.asData?.value?.rank ?? 0;
            final top3 = members.take(3).toList();
            final rest = members.skip(3).toList();

            // Find the current user's entry so we can show their position
            final myMember = myUid != null
                ? members.where((m) => m.uid == myUid).firstOrNull
                : null;

            return Column(
              children: [
                _ClubStatsHeader(
                  memberCount: memberCount,
                  clubRank: clubRank,
                  categories: clubAsync.asData?.value?.categories ?? ['ALL'],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _PodiumRow(members: top3, myUid: myUid),
                        const SizedBox(height: 16),
                        if (myMember != null) ...[
                          _YourPositionBanner(
                            rank: myMember.rank,
                            score: myMember.clubScore,
                          ),
                          const SizedBox(height: 16),
                        ],
                        ...rest.asMap().entries.map((e) => _MemberRow(
                              member: e.value,
                              isMe: e.value.uid == myUid,
                              isLast: e.key == rest.length - 1,
                            )),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClubStatsHeader extends StatelessWidget {
  final int memberCount;
  final int clubRank;
  final List<String> categories;
  const _ClubStatsHeader({
    required this.memberCount,
    required this.clubRank,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          color: theme.appColors.background,
          child: Row(
            children: [
              _StatPill(label: '$memberCount MEMBERS', color: theme.appColors.secondary!),
              const SizedBox(width: 8),
              _StatPill(
                label: clubRank == 0 ? 'UNRANKED' : 'RANK #$clubRank',
                color: theme.appColors.primary!,
              ),
            ],
          ),
        ),
        Container(
          height: 34,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.appColors.surface,
                  border: Border.all(color: theme.appColors.border!, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    categories[i].toUpperCase(),
                    style: theme.appTextTheme.body?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

class _YourPositionBanner extends StatelessWidget {
  final int rank;
  final int score;
  const _YourPositionBanner({required this.rank, required this.score});

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

class _PodiumRow extends StatelessWidget {
  final List<ClubMember> members;
  final String? myUid;
  const _PodiumRow({required this.members, required this.myUid});

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
            child: _PodiumCard(
              member: members[i],
              color: colors[i],
              isMe: members[i].uid == myUid,
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final ClubMember member;
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
            isMe ? '${member.displayName} ★' : member.displayName,
            style: theme.appTextTheme.body?.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            NumberFormat('#,###').format(member.clubScore),
            style: theme.appTextTheme.body?.copyWith(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ClubMember member;
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
              isMe ? '${member.displayName} ★' : member.displayName,
              style: theme.appTextTheme.body?.copyWith(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
          Text(
            NumberFormat('#,###').format(member.clubScore),
            style: theme.appTextTheme.body?.copyWith(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
