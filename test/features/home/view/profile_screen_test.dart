import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/features/home/view/profile_screen.dart';
import 'package:sorta/core/theme/app_theme.dart';

void main() {
  testWidgets('ProfileScreen shows ME heading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppThemeNotifier.light,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ME'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows RECENT MATCHES section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppThemeNotifier.light,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('RECENT MATCHES'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows positive score delta with plus sign', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppThemeNotifier.light,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('+80'), findsWidgets);
    expect(find.text('-20'), findsOneWidget);
  });
}
