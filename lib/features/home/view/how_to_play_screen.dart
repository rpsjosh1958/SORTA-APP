import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('HOW TO PLAY', style: theme.appTextTheme.heading?.copyWith(fontSize: 22)),
        backgroundColor: theme.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const DotGridBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                color: Color(0xFFFFD600),
                title: 'THE GAME',
                icon: Icons.videogame_asset_rounded,
                items: [
                  _InfoItem(
                    icon: Icons.drag_indicator,
                    text: 'You\'re given 5 items — tap and drag to sort them in the correct order.',
                  ),
                  _InfoItem(
                    icon: Icons.quiz_rounded,
                    text: 'Each match has 5 questions across your chosen category.',
                  ),
                  _InfoItem(
                    icon: Icons.timer_rounded,
                    text: '30 seconds per question. Run out of time and the answer auto-submits.',
                  ),
                  _InfoItem(
                    icon: Icons.bolt_rounded,
                    text: 'Daily Sort is a special puzzle that resets every day.',
                  ),
                ],
              ),
              SizedBox(height: 20),
              _SectionCard(
                color: Color(0xFF00E5FF),
                title: 'SCORING',
                icon: Icons.emoji_events_rounded,
                items: [
                  _InfoItem(icon: Icons.add_circle, text: '+10 pts — each correctly placed card.'),
                  _InfoItem(icon: Icons.stars_rounded, text: '+30 pts bonus — all 5 cards correct (perfect sort).'),
                  _InfoItem(icon: Icons.remove_circle, text: '−5 pts — each incorrectly placed card.'),
                  _InfoItem(icon: Icons.cancel, text: '−35 pts penalty — every card wrong.'),
                ],
              ),
              SizedBox(height: 20),
              _SectionCard(
                color: Color(0xFFFF4081),
                title: 'BONUSES',
                icon: Icons.local_fire_department_rounded,
                items: [
                  _InfoItem(
                    icon: Icons.speed_rounded,
                    text: 'Speed Bonus — remaining seconds added to your score on a perfect sort.',
                  ),
                  _InfoItem(
                    icon: Icons.trending_up_rounded,
                    text: 'Streak Multiplier — each consecutive perfect sort increases your multiplier (2×, 3×, ...).',
                  ),
                  _InfoItem(
                    icon: Icons.workspace_premium_rounded,
                    text: 'Max per question: (80 pts + seconds remaining) × streak multiplier.',
                  ),
                ],
              ),
              SizedBox(height: 20),
              _SectionCard(
                color: Color(0xFF69F0AE),
                title: 'RANKS & CLUBS',
                icon: Icons.public_rounded,
                items: [
                  _InfoItem(
                    icon: Icons.leaderboard_rounded,
                    text: 'Your total score determines your World Rank. Compete globally.',
                  ),
                  _InfoItem(
                    icon: Icons.group_rounded,
                    text: 'Join or create Clubs — compete on the Club leaderboard with friends.',
                  ),
                  _InfoItem(
                    icon: Icons.star_rounded,
                    text: 'Play every day to build your streak and climb the rankings.',
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color color;
  final String title;
  final IconData icon;
  final List<_InfoItem> items;

  const _SectionCard({
    required this.color,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: theme.appColors.shadow!, offset: const Offset(5, 5), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Icon(icon, size: 28, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.appTextTheme.heading?.copyWith(fontSize: 22, color: Colors.black),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final isLast = e.key == items.length - 1;
                return _InfoRow(item: e.value, isLast: isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String text;
  const _InfoItem({required this.icon, required this.text});
}

class _InfoRow extends StatelessWidget {
  final _InfoItem item;
  final bool isLast;

  const _InfoRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 20, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withOpacity(0.1),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
