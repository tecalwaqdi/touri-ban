import 'package:admin_arawatan/core/admin_finance_demo_mode.dart';
import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/core/finance/finance_reconciliation_qa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AdminFinanceDemoMode.debugReset);

  final demoTrip = <String, dynamic>{
    'is_demo': true,
    'admin_demo_fixture': true,
    'demo_seed_version': 'finance_ui_v1',
    'demo_seed_group': AdminFinanceDemoMode.seedGroup,
    'exclude_from_real_reporting': true,
    'total': 50,
  };

  final classicQa = <String, dynamic>{
    'is_test_fixture': true,
    'test_scope': 'finance',
  };

  final realTrip = <String, dynamic>{
    'total': 50,
    'status_code': 'completed',
  };

  test('normal mode excludes controlled demo fixtures', () {
    AdminFinanceDemoMode.debugSetEnabled(false);
    expect(
      AdminQaFixture.shouldExcludeFromFinanceReporting(
        demoTrip,
        orderId: 'demo_fin_trip_001',
      ),
      isTrue,
    );
    expect(
      AdminQaFixture.isFixtureMap(demoTrip, orderId: 'demo_fin_trip_001'),
      isTrue,
    );
  });

  test('demo mode includes only controlled demo group', () {
    AdminFinanceDemoMode.debugSetEnabled(true);
    expect(
      AdminQaFixture.shouldExcludeFromFinanceReporting(
        demoTrip,
        orderId: 'demo_fin_trip_001',
      ),
      isFalse,
    );
    expect(
      AdminQaFixture.shouldExcludeFromFinanceReporting({
        'admin_demo_fixture': true,
        'demo_seed_group': 'OTHER_GROUP',
      }),
      isTrue,
    );
  });

  test('real data remains included in both modes', () {
    AdminFinanceDemoMode.debugSetEnabled(false);
    expect(AdminQaFixture.shouldExcludeFromFinanceReporting(realTrip), isFalse);
    AdminFinanceDemoMode.debugSetEnabled(true);
    expect(AdminQaFixture.shouldExcludeFromFinanceReporting(realTrip), isFalse);
  });

  test('unrelated QA fixtures remain excluded even in demo mode', () {
    AdminFinanceDemoMode.debugSetEnabled(true);
    expect(
      AdminQaFixture.shouldExcludeFromFinanceReporting(
        classicQa,
        orderId: 'fin7_ctrl_1',
      ),
      isTrue,
    );
    expect(
      AdminQaFixture.isClassicQaFixtureMap(classicQa, orderId: 'fin7_ctrl_1'),
      isTrue,
    );
    expect(
      FinanceReconciliationQa.isReconciliationQaFixture(
        {'functional_test': true},
        orderId: 'x',
      ),
      isTrue,
    );
  });

  test('demo settlements are not Super Admin QA-diagnostics rows', () {
    expect(
      AdminQaFixture.isFinanceQaSettlement(
        demoTrip,
        settlementId: 'demo_fin_settlement_001',
      ),
      isFalse,
    );
  });

  test('demo mode default is OFF', () {
    expect(AdminFinanceDemoMode.enabled, isFalse);
  });
}
