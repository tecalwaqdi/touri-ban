import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_qa_fixtures.dart';

/// Run with:
/// `flutter test --dart-define=ADMIN_QA_FIXTURES=true test/admin_qa_fixtures_enabled_test.dart`
void main() {
  final enabled = AdminQaFixtures.enabled;
  test(
    'ADMIN_QA_FIXTURES=true enables fixtures',
    () {
      expect(enabled, isTrue);
    },
    skip: enabled
        ? false
        : 'Run with --dart-define=ADMIN_QA_FIXTURES=true',
  );
}
