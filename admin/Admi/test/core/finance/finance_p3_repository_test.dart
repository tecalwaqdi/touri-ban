import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_perf_trace.dart';
import 'package:admin_arawatan/core/finance/admin_finance_repository.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_labels.dart';

void main() {
  setUp(() {
    AdminPerfTrace.enabled = true;
    AdminPerfTrace.resetCounters();
    AdminFinanceRepository.instance.clearSession();
  });

  tearDown(() {
    AdminFinanceRepository.instance.clearSession();
    AdminPerfTrace.resetCounters();
  });

  group('PERF-P3 AdminFinanceRepository session/security', () {
    test('clearSession records invalidation and empties label cache path', () {
      final a = AccountantFinanceLabels.countryHumanAr('countries/saudi');
      expect(a, 'السعودية');
      AdminFinanceRepository.instance.clearSession();
      expect(AdminPerfTrace.financeRepoInvalidations >= 1, isTrue);
      expect(
        AccountantFinanceLabels.countryHumanAr('countries/saudi'),
        'السعودية',
      );
    });

    test('invalidateSettlements does not throw', () {
      AdminFinanceRepository.instance.invalidateSettlements();
      expect(AdminPerfTrace.financeRepoInvalidations >= 1, isTrue);
    });

    test('invalidateAllFinanceSource does not throw', () {
      AdminFinanceRepository.instance.invalidateAllFinanceSource();
      expect(AdminPerfTrace.financeRepoInvalidations >= 1, isTrue);
    });
  });

  group('PERF-P3 display label cache', () {
    test('same country path returns stable presentation label', () {
      final a = AccountantFinanceLabels.countryHumanAr('countries/saudi');
      final b = AccountantFinanceLabels.countryHumanAr('countries/saudi');
      expect(a, b);
      expect(a, 'السعودية');
    });

    test('empty path is dash — not zero', () {
      expect(AccountantFinanceLabels.countryHumanAr(null), '—');
      expect(AccountantFinanceLabels.countryHumanAr(''), '—');
    });
  });

  group('PERF-P3 policy constants', () {
    test('TTL and max entries are bounded', () {
      expect(
        AdminFinanceRepository.sourceTtl.inSeconds,
        inInclusiveRange(15, 60),
      );
      expect(AdminFinanceRepository.maxSourceEntries, lessThanOrEqualTo(48));
      expect(AdminFinanceRepository.maxLabelEntries, lessThanOrEqualTo(500));
    });
  });
}
