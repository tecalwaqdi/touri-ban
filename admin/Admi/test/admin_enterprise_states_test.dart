import 'package:admin_arawatan/components/admin_enterprise_kit.dart';
import 'package:admin_arawatan/components/admin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _narrow(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminUi responsive helpers', () {
    testWidgets('dialogMaxWidth fits narrow mobile', (tester) async {
      late double maxW;
      await tester.pumpWidget(
        _narrow(
          Builder(
            builder: (context) {
              maxW = AdminUi.dialogMaxWidth(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(maxW, lessThan(390));
      expect(maxW, greaterThan(300));
    });

    testWidgets('drawerWidth is full width on 390', (tester) async {
      late double w;
      await tester.pumpWidget(
        _narrow(
          Builder(
            builder: (context) {
              w = AdminUi.drawerWidth(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(w, 390);
    });
  });

  group('AdminErrorState', () {
    testWidgets('shows retry when onRetry provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminErrorState(
              title: 'خطأ',
              retryLabel: 'إعادة',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('خطأ'), findsOneWidget);
      await tester.tap(find.text('إعادة'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('AdminSearchField', () {
    testWidgets('debounces onChanged', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSearchField(
              debounceTag: 'test_search',
              debounceMs: 50,
              hint: 'بحث',
              onChanged: values.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      expect(values, isEmpty);
      await tester.pump(const Duration(milliseconds: 60));
      expect(values, ['abc']);
    });

    testWidgets('clear button resets query', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSearchField(
              debounceTag: 'test_clear',
              debounceMs: 10,
              hint: 'بحث',
              onChanged: values.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(values.last, '');
    });
  });
}
