import 'package:admin_arawatan/backend/admin_finance_sidebar.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('super admin finance menu is the five unified pages', () {
    final routes = AdminFinanceSidebar.entriesFor(AdminRole.superAdmin)
        .map((e) => e.route)
        .toList();
    expect(routes, [
      'AdminFinanceHub',
      'AdminFinanceTripLedger',
      'AdminSettlements',
      'AdminFinanceReports',
      'AdminFinanceControl',
    ]);
    for (final hidden in AdminFinanceSidebar.hiddenFromMenu) {
      expect(routes, isNot(contains(hidden)));
    }
  });

  test('accountant sees four finance pages and not control', () {
    final routes = AdminFinanceSidebar.entriesFor(AdminRole.accountant)
        .map((e) => e.route)
        .toList();
    expect(routes, [
      'AdminFinanceHub',
      'AdminFinanceTripLedger',
      'AdminSettlements',
      'AdminFinanceReports',
    ]);
  });

  test('country agent keeps only their own finance page', () {
    final routes = AdminFinanceSidebar.entriesFor(AdminRole.countryAgent)
        .map((e) => e.route)
        .toList();
    expect(routes, ['AdminAgentFinance']);
  });
}
