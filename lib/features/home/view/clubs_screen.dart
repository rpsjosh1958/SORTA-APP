import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/models/club_info.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';
import 'club_rank_screen.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clubsAsync = ref.watch(userClubsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('CLUBS', style: theme.appTextTheme.heading?.copyWith(fontSize: 24)),
        backgroundColor: theme.appColors.background,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOptions(context, ref),
        backgroundColor: theme.appColors.primary,
        foregroundColor: theme.appColors.onSurface,
        label: Text('ADD CLUB', style: theme.appTextTheme.button?.copyWith(fontSize: 14)),
        icon: const Icon(Icons.add),
      ),
      body: DotGridBackground(
        child: clubsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Failed to load clubs')),
          data: (clubs) => clubs.isEmpty
              ? _EmptyState(
                  onCreate: () => _showCreateDialog(context, ref),
                  onJoin: () => _showJoinDialog(context, ref),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('MY CLUBS', style: theme.appTextTheme.subHeading),
                      const SizedBox(height: 12),
                      ...clubs.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ClubCard(club: c),
                          )),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ADD CLUB', style: theme.appTextTheme.subHeading),
            const SizedBox(height: 16),
            _OptionTile(
              label: 'CREATE A CLUB',
              sub: 'Start your own club and invite friends',
              icon: Icons.add_circle_outline,
              color: theme.appColors.primary!,
              onTap: () {
                Navigator.pop(context);
                _showCreateDialog(context, ref);
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              label: 'JOIN WITH CODE',
              sub: 'Enter a 6-character invite code',
              icon: Icons.key_outlined,
              color: theme.appColors.secondary!,
              onTap: () {
                Navigator.pop(context);
                _showJoinDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _CreateClubDialog(ref: ref));
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _JoinClubDialog(ref: ref));
  }
}

// ─── Club card ────────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  final ClubInfo club;
  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClubRankScreen(clubId: club.id)),
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
                  Text(club.name, style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
                  Text(
                    '${club.memberCount} MEMBERS · RANK #${club.rank == 0 ? '—' : club.rank}',
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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyState({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/user-group.svg',
              width: 64,
              height: 64,
              colorFilter:
                  ColorFilter.mode(theme.appColors.onSurface!.withOpacity(0.2), BlendMode.srcIn),
            ),
            const SizedBox(height: 20),
            Text(
              'NO CLUBS YET',
              style: theme.appTextTheme.heading?.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a club or join one with a code.',
              style: theme.appTextTheme.body
                  ?.copyWith(color: theme.appColors.onSurface?.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _OptionTile(
              label: 'CREATE A CLUB',
              sub: 'Start your own, invite others',
              icon: Icons.add_circle_outline,
              color: theme.appColors.primary!,
              onTap: onCreate,
            ),
            const SizedBox(height: 12),
            _OptionTile(
              label: 'JOIN WITH CODE',
              sub: 'Enter a 6-character invite code',
              icon: Icons.key_outlined,
              color: theme.appColors.secondary!,
              onTap: onJoin,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Option tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: theme.appColors.border!, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: theme.appColors.shadow!, offset: const Offset(4, 4), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.appColors.onSurface, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.appTextTheme.body?.copyWith(fontWeight: FontWeight.w900)),
                  Text(
                    sub,
                    style: theme.appTextTheme.body
                        ?.copyWith(fontSize: 12, color: theme.appColors.onSurface?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.appColors.onSurface, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Create club dialog ───────────────────────────────────────────────────────

class _CreateClubDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CreateClubDialog({required this.ref});

  @override
  State<_CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends State<_CreateClubDialog> {
  final _controller = TextEditingController();
  final List<String> _selectedCategories = ['ALL'];
  bool _loading = false;
  String? _createdCode;
  String? _error;

  static const _allCategories = [
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCategory(String cat) {
    setState(() {
      if (cat == 'ALL') {
        _selectedCategories.clear();
        _selectedCategories.add('ALL');
      } else {
        _selectedCategories.remove('ALL');
        if (_selectedCategories.contains(cat)) {
          _selectedCategories.remove(cat);
          if (_selectedCategories.isEmpty) _selectedCategories.add('ALL');
        } else {
          _selectedCategories.add(cat);
        }
      }
    });
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await widget.ref
          .read(clubActionsProvider.notifier)
          .createClub(name, _selectedCategories);
      setState(() {
        _createdCode = code;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_createdCode != null) {
      return AlertDialog(
        backgroundColor: theme.appColors.surface,
        title: Text('CLUB CREATED!', style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code with friends to invite them:',
                style: theme.appTextTheme.body?.copyWith(fontSize: 13)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _createdCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.appColors.primary,
                  border: Border.all(color: theme.appColors.border!, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _createdCode!,
                      style: theme.appTextTheme.heading?.copyWith(fontSize: 28, letterSpacing: 6),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy, size: 18, color: theme.appColors.onSurface),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('DONE', style: theme.appTextTheme.button),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: theme.appColors.surface,
      title: Text('CREATE CLUB', style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Club name',
                hintStyle: theme.appTextTheme.body?.copyWith(
                  color: theme.appColors.onSurface?.withOpacity(0.4),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: theme.appTextTheme.body,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text('CATEGORIES',
                style: theme.appTextTheme.body?.copyWith(fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCategories.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return GestureDetector(
                  onTap: () => _toggleCategory(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.appColors.primary : theme.appColors.surface,
                      border: Border.all(color: theme.appColors.border!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [BoxShadow(color: theme.appColors.shadow!, offset: const Offset(2, 2))]
                          : [],
                    ),
                    child: Text(
                      cat.toUpperCase(),
                      style: theme.appTextTheme.body?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.black : theme.appColors.onSurface?.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.appColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('CANCEL', style: theme.appTextTheme.button?.copyWith(fontSize: 13)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.appColors.primary,
            foregroundColor: theme.appColors.onSurface,
            elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('CREATE', style: theme.appTextTheme.button?.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

// ─── Join club dialog ─────────────────────────────────────────────────────────

class _JoinClubDialog extends StatefulWidget {
  final WidgetRef ref;
  const _JoinClubDialog({required this.ref});

  @override
  State<_JoinClubDialog> createState() => _JoinClubDialogState();
}

class _JoinClubDialogState extends State<_JoinClubDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final error = await widget.ref.read(clubActionsProvider.notifier).joinClub(code);
    if (!mounted) return;
    if (error != null) {
      setState(() { _error = error; _loading = false; });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined club!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.appColors.surface,
      title: Text('JOIN WITH CODE', style: theme.appTextTheme.heading?.copyWith(fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: theme.appTextTheme.body?.copyWith(
                color: theme.appColors.onSurface?.withOpacity(0.4),
                letterSpacing: 6,
              ),
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: theme.appTextTheme.body?.copyWith(letterSpacing: 6, fontSize: 22),
            textAlign: TextAlign.center,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.appColors.danger, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('CANCEL', style: theme.appTextTheme.button?.copyWith(fontSize: 13)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.appColors.secondary,
            foregroundColor: theme.appColors.onSurface,
            elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('JOIN', style: theme.appTextTheme.button?.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}
