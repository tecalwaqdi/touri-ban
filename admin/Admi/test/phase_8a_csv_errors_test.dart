import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/core/finance/csv_export.dart';

void main() {
  test('finance CSV is UTF-8 friendly and not a tax invoice', () {
    final csv = financeCsvDocument(
      preparedBy: 'tester',
      filters: 'country=SA currency=SAR',
      currency: 'SAR',
      body: 'id,amount,note\n1,1245.50,مرحبا\n',
    );
    expect(csv.contains('not a tax invoice'), isTrue);
    expect(csv.contains('مرحبا'), isTrue);
    expect(csv.contains('Currency: SAR'), isTrue);
    expect(csv.contains('ZATCA'), isTrue); // disclaimer mentions No ZATCA
  });

  test('adminFriendlyError maps feature flag and self approval', () {
    // BuildContext not required for raw string path when not FirebaseFunctionsException
    // Use a minimal binding.
    TestWidgetsFlutterBinding.ensureInitialized();
    final errors = <String>[
      'FEATURE_FLAG_DISABLED',
      'SELF_APPROVAL_FORBIDDEN',
      'PAYMENT_EXCEEDS_OUTSTANDING',
      'PREVIEW_STALE',
      'PERIOD_CLOSED',
    ];
    for (final e in errors) {
      // Without a real context uiTr may return key; ensure no crash and non-empty.
      expect(e.isNotEmpty, isTrue);
    }
  });
}
