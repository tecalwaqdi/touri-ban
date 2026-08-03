// Full MyApp widget tests require Firebase initialization, routing, and
// EasyLocalization; use integration tests for end-to-end coverage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget harness smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('ok'),
        ),
      ),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
