import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/features/home/view/world_rank_screen.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('WorldRankScreen shows WORLD RANK heading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const WorldRankScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('WORLD RANK'), findsOneWidget);
  });

  testWidgets('WorldRankScreen shows your position banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const WorldRankScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('YOUR POSITION'), findsOneWidget);
  });
}
