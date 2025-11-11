// Basic widget test for SenseTrail app
import 'package:flutter_test/flutter_test.dart';

import 'package:sense_trail_app/main.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SenseTrailApp());

    // Verify that the app title appears
    expect(find.text('SenseTrail'), findsOneWidget);
  });
}
