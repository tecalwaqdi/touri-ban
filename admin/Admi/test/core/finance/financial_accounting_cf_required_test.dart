import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/financial_accounting_unavailable.dart';

void main() {
  group('financeAllowsClientFullFallback', () {
    test('global authoritative views disallow client_full on CF failure', () {
      expect(
        financeAllowsClientFullFallback(
          requireCanonicalServer: true,
          driverScoped: false,
        ),
        isFalse,
      );
    });

    test('driver-scoped views still allow client_full', () {
      expect(
        financeAllowsClientFullFallback(
          requireCanonicalServer: true,
          driverScoped: true,
        ),
        isTrue,
      );
    });

    test('non-authoritative global views allow client_full', () {
      expect(
        financeAllowsClientFullFallback(
          requireCanonicalServer: false,
          driverScoped: false,
        ),
        isTrue,
      );
    });
  });

  group('FinancialAccountingUnavailableException', () {
    test('wraps underlying cause', () {
      final ex = FinancialAccountingUnavailableException('network');
      expect(ex.cause, 'network');
      expect(
          ex.toString(), contains('FinancialAccountingUnavailableException'));
    });
  });
}
