import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    // Total: 400ms fade in | 800ms hold | 500ms fade out = 1700ms
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.24, curve: Curves.easeIn),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.71, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the logo so it appears instantly on the Login screen later
    precacheImage(const AssetImage('assets/logo/sort_word_logo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: (_fadeIn.value * _fadeOut.value).clamp(0.0, 1.0),
            child: Image.asset(
              'assets/logo/sort_word_logo.png',
              width: 200,
            ),
          ),
        ),
      ),
    );
  }
}
