import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_firestore_web_config.dart';
import 'package:admin_arawatan/backend/admin_settlements_query.dart';
import 'package:admin_arawatan/core/finance/admin_finance_repository.dart';
import 'package:admin_arawatan/core/finance/finance_order_query.dart';

void main() {
  test('PERF-P4C web persistence defaults ON (Settlements stop-rule)', () {
    expect(AdminFirestoreWebConfig.webPersistenceEnabled, isTrue);
    expect(AdminFirestoreWebConfig.webForceLongPolling, isFalse);
    expect(AdminFirestoreWebConfig.webAutoDetectLongPolling, isFalse);
    expect(
      AdminFirestoreWebConfig.financeOneShotGetOptions.source,
      Source.server,
    );
  });

  test('PERF-P4C web Settings: persistence enabled, no forced long-poll', () {
    final s = AdminFirestoreWebConfig.buildSettings(isWeb: true);
    expect(s.persistenceEnabled, isTrue);
    expect(s.webExperimentalForceLongPolling, isNull);
    expect(s.webExperimentalAutoDetectLongPolling, isNull);
  });

  test('PERF-P4C IO Settings keep native persistence', () {
    final s = AdminFirestoreWebConfig.buildSettings(isWeb: false);
    expect(s.persistenceEnabled, isTrue);
  });

  test('PERF-P4C fetch modes are get + diagnostic snapshotsFirst only', () {
    expect(FinanceOrderFetchMode.values.map((e) => e.name).toList(), [
      'get',
      'snapshotsFirst',
    ]);
  });

  test('PERF-P4C source TTL remains 180s (P4B)', () {
    expect(AdminFinanceRepository.sourceTtl, const Duration(seconds: 180));
  });

  test('PERF-P4C repository clearSession is account-switch safe', () {
    AdminFinanceRepository.instance.clearSession();
    expect(AdminFinanceRepository.sourceTtl.inSeconds, 180);
  });

  test('PERF-P4C settlements list remains live snapshots API', () {
    // Compile/API contract — P1 live listener must stay.
    expect(AdminSettlementsQuery.pageLimit, FinanceOrderQuery.tablePageSize);
    expect(AdminSettlementsQuery.snapshotsForCurrentUser, isA<Function>());
  });
}
