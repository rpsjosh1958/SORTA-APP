import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SortaApp());

    // Since we changed the app structure, the default counter test will fail.
    // For now, let's just check if SORTA text is present.
    expect(find.text('SORTA'), findsWidgets);
  });
}
