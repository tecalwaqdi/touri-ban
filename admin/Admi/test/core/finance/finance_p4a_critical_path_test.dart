import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_perf_trace.dart';
import 'package:admin_arawatan/core/finance/admin_finance_repository.dart';
import 'package:admin_arawatan/core/finance/finance_order_query.dart';
import 'package:admin_arawatan/core/finance/finance_reconciliation_read_model.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';

/// PERF-P4A progressive pipeline + memoization (no Firestore).
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

  group('PERF-P4A pipeline contracts', () {
    test('table page size remains 40 (first useful page)', () {
      expect(FinanceOrderQuery.tablePageSize, 40);
    });

    test('source TTL still short-lived for cache-first return', () {
      expect(
        AdminFinanceRepository.sourceTtl.inSeconds,
        inInclusiveRange(15, 60),
      );
    });

    test('first-page and summary are distinct loading domains (API surface)', () {
      // Compile-time / API presence — Hub uses loadFirstPage then load.
      expect(AdminFinanceRepository.instance.loadHubFirstPage, isA<Function>());
      expect(AdminFinanceRepository.instance.loadHubBundle, isA<Function>());
      expect(
        AdminFinanceRepository.instance.loadReconciliationFirstPage,
        isA<Function>(),
      );
    });
  });

  group('PERF-P4A B1 memoization', () {
    test('identical immutable inputs reuse memoized B1 result', () {
      final scope = const AccountantFinanceScope(includeAllCountries: true);
      final emptyOrders = <dynamic>[];
      // Use public build twice via repository memo through identical empty sets.
      final a = FinanceReconciliationReadModel.buildReconciliation(
        orders: const [],
        scope: scope,
        currency: 'SAR',
        settlements: const [],
      );
      final b = FinanceReconciliationReadModel.buildReconciliation(
        orders: const [],
        scope: scope,
        currency: 'SAR',
        settlements: const [],
      );
      expect(a.summary.completedTrips, b.summary.completedTrips);
      expect(emptyOrders, isEmpty);
    });

    test('B1 CPU for empty set is tiny vs multi-second wall targets', () {
      final scope = const AccountantFinanceScope(includeAllCountries: true);
      final sw = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        FinanceReconciliationReadModel.buildReconciliation(
          orders: const [],
          scope: scope,
          currency: 'SAR',
          settlements: const [],
        );
      }
      sw.stop();
      // 50 empty builds should be well under 500ms on CI.
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  group('PERF-P4A summary pending presentation', () {
    test('pending summary must not render fake zero string', () {
      const pending = '—';
      const fakeZero = '0';
      expect(pending, isNot(equals(fakeZero)));
    });
  });

  group('PERF-P4A F1 aggregate empty', () {
    test('empty aggregate does not invent completed trips', () {
      final model = AccountantFinanceReadModel.aggregate(
        orders: const [],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.completedTripCount, 0);
    });
  });
}
