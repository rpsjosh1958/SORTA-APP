import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_provider.dart';
import '../home/view/main_screen.dart';
import '../profile/view/setup_profile_screen.dart';

class ProfileGate extends ConsumerWidget {
  final int initialIndex;
  const ProfileGate({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text('Error loading profile: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const SetupProfileScreen();
        }
        return MainScreen(initialIndex: initialIndex);
      },
    );
  }
}
