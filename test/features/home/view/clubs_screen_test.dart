import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/features/home/view/clubs_screen.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('ClubsScreen shows MY CLUB section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubsScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('MY CLUB'), findsOneWidget);
  });

  testWidgets('ClubsScreen shows DISCOVER section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubsScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('DISCOVER'), findsOneWidget);
  });

  testWidgets('ClubsScreen shows Brain Squad club name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubsScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Brain Squad'), findsOneWidget);
  });

  testWidgets('ClubsScreen shows CREATE CLUB FAB', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubsScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('CREATE CLUB'), findsOneWidget);
  });
}
