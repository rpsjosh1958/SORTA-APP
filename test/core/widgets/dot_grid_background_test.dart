import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/core/widgets/dot_grid_background.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('DotGridBackground renders its child in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const Scaffold(
          body: DotGridBackground(
            child: Text('hello'),
          ),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('DotGridBackground renders its child in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.dark,
        home: const Scaffold(
          body: DotGridBackground(
            child: Text('dark'),
          ),
        ),
      ),
    );
    expect(find.text('dark'), findsOneWidget);
  });
}
