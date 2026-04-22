import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/home/view/main_screen.dart';
import 'features/auth/view/login_screen.dart';
import 'features/splash/splash_screen.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission (iOS only — Android grants by default). Fails gracefully on simulator.
  try {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: SortaApp(),
    ),
  );
}

class SortaApp extends ConsumerWidget {
  const SortaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SORTA',
      debugShowCheckedModeBanner: false,
      theme: AppThemeNotifier.light,
      themeMode: ThemeMode.light,
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(onComplete: () => setState(() => _splashDone = true));
    }
    return const _AuthGate();
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  // index 2 = VS tab
  int _pendingNavIndex = -1;

  @override
  void initState() {
    super.initState();

    // Foreground push: show a SnackBar with the notification
    FirebaseMessaging.onMessage.listen((msg) {
      final notif = msg.notification;
      if (notif == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notif.title}: ${notif.body}'),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () => setState(() => _pendingNavIndex = 2),
          ),
        ),
      );
    });

    // Background/terminated tap: navigate to VS tab
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      if (mounted) setState(() => _pendingNavIndex = 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        _saveFcmToken(user.uid);
        return MainScreen(initialIndex: _pendingNavIndex >= 0 ? _pendingNavIndex : 0);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
    );
  }

  void _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
    } catch (_) {}
  }
}
