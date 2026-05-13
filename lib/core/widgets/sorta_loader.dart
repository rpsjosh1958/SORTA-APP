import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SortaLoader extends StatelessWidget {
  const SortaLoader({super.key});

  @override
  Widget build(BuildContext context) => const _PulsingPlanks();
}

class _PulsingPlanks extends StatefulWidget {
  const _PulsingPlanks();

  @override
  State<_PulsingPlanks> createState() => _PulsingPlanksState();
}

class _PulsingPlanksState extends State<_PulsingPlanks>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _colors = [
    Color(0xFFFFE566),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFA78BFA),
    Color(0xFFFF9F43),
  ];

  static const _labels = ['S', 'O', 'R', 'T', 'A'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final delay = i / 5.0;
            final t = (((_ctrl.value - delay) % 1.0 + 1.0) % 1.0);
            final bounce = (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Transform.translate(
              offset: Offset(0, -10 * bounce),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 32,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _colors[i],
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
