import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DotGridBackground extends StatelessWidget {
  final Widget child;

  const DotGridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _DotGridPainter(
              backgroundColor: theme.appColors.background ?? theme.scaffoldBackgroundColor,
              dotColor: isDark ? const Color(0xFF383838) : const Color(0xFFC0C0C0),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color backgroundColor;
  final Color dotColor;

  const _DotGridPainter({required this.backgroundColor, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );
    final dotPaint = Paint()..color = dotColor;
    const spacing = 20.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.dotColor != dotColor;
}
