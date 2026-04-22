import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../game/view/game_screen.dart';
import '../../game/view_model/game_view_model.dart';
import '../../versus/view/versus_screen.dart';
import 'clubs_screen.dart';
import 'profile_screen.dart';
import 'world_rank_screen.dart';
import 'club_rank_screen.dart';
import 'how_to_play_screen.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/models/club_info.dart';
import '../../../core/theme/app_theme.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onPlayTapped() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screens = [
      HomeScreen(onPlayDaily: _onPlayTapped),
      const GameScreen(),
      const VersusScreen(),
      const ClubsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.appColors.border!, width: 3)),
        ),
        child: Theme(
          data: theme.copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.appColors.surface,
            selectedItemColor: theme.appColors.accent,
            unselectedItemColor: theme.appColors.onSurface,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'HOME'),
              BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'PLAY'),
              BottomNavigationBarItem(icon: Icon(Icons.sports_kabaddi), label: 'VS'),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'CLUBS'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'ME'),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  final VoidCallback onPlayDaily;
  const HomeScreen({super.key, required this.onPlayDaily});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final clubs = ref.watch(userClubsProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo/sort_word_logo.png',
          height: 32,
          errorBuilder: (context, error, stackTrace) =>
              Text('SORTA', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        ),
        backgroundColor: theme.appColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
            ),
            icon: Icon(Icons.help_outline_rounded, color: theme.appColors.onSurface),
          ),
          
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (profile == null || !profile.hasPlayedDailySort)
              _DailySortCard(
                onTap: () {
                  ref.read(gameViewModelProvider.notifier).playDailySort();
                  onPlayDaily();
                },
              )
            else
              _BigStatCard(
                title: 'DAILY SORT SCORE',
                value: NumberFormat('#,###').format(profile.dailySortScore),
                color: theme.appColors.accent!,
                icon: Icons.bolt,
              ),
            const SizedBox(height: 24),
            _BigStatCard(
              title: 'TOTAL SCORE',
              value: NumberFormat('#,###').format(profile?.totalScore ?? 0),
              color: theme.appColors.primary!,
              icon: Icons.emoji_events,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorldRankScreen()),
              ),
              child: _BigStatCard(
                title: 'WORLD RANK',
                value: '#${NumberFormat('#,###').format(profile?.worldRank ?? 0)}',
                color: theme.appColors.secondary!,
                icon: Icons.public,
              ),
            ),
            if (clubs.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('MY CLUBS', style: theme.appTextTheme.subHeading),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: clubs
                      .map((club) => Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClubRankScreen(clubId: club.id),
                                ),
                              ),
                              child: _ClubBadge(club: club),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailySortCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DailySortCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.appColors.accent,
          border: Border.all(color: theme.appColors.border!, width: 4),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.appColors.shadow!,
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DAILY SORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('PLAY NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
                ],
              ),
            ),
            Icon(Icons.bolt, size: 64, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _BigStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: theme.appColors.border!, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.appColors.shadow!,
            offset: const Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.appTextTheme.body?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(value, style: theme.appTextTheme.heading?.copyWith(fontSize: 40)),
            ],
          ),
          Icon(icon, size: 48, color: Colors.black),
        ],
      ),
    );
  }
}

class _ClubBadge extends StatelessWidget {
  final ClubInfo club;

  const _ClubBadge({required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = club.code.isNotEmpty
        ? club.code.substring(0, club.code.length.clamp(0, 3))
        : club.name.substring(0, 1).toUpperCase();

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: theme.appColors.border!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: theme.appColors.shadow!,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.appColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: theme.appColors.border!, width: 2),
              ),
              child: Text(
                '#${club.rank}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(club.name, style: theme.appTextTheme.body?.copyWith(fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
