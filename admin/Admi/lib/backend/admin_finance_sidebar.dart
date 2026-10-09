import '/backend/admin_role_service.dart';

/// One sidebar row in the unified Finance section.
class FinanceSidebarEntry {
  const FinanceSidebarEntry({required this.route, required this.labelKey});

  final String route;
  final String labelKey;
}

/// Step 1 of the finance menu: five destinations, old screens stay routed.
///
/// Hidden routes are not deleted. Deep links still open the existing pages.
abstract final class AdminFinanceSidebar {
  static const today = FinanceSidebarEntry(
    route: 'AdminFinanceHub',
    labelKey: 'nav_finance_today',
  );
  static const trips = FinanceSidebarEntry(
    route: 'AdminFinanceTripLedger',
    labelKey: 'nav_finance_trips',
  );
  static const settlements = FinanceSidebarEntry(
    route: 'AdminSettlements',
    labelKey: 'nav_settlements',
  );
  static const reports = FinanceSidebarEntry(
    route: 'AdminFinanceReports',
    labelKey: 'nav_finance_reports_menu',
  );
  static const control = FinanceSidebarEntry(
    route: 'AdminFinanceControl',
    labelKey: 'nav_finance_control',
  );

  static const coreEntries = [today, trips, settlements, reports];

  /// Still registered. Removed from the sidebar so the same number is not
  /// listed twice. Country agents keep their own finance page.
  static const hiddenFromMenu = [
    'AdminFinanceReceivables',
    'AdminFinanceReconciliation',
    'AdminReconciliation',
    'AdminFinanceAdjustments',
    'AdminFinancialPeriods',
    'AdminFinanceDataQuality',
    'AdminFinanceAudit',
    'AdminFinanceChannels',
    'AdminDriverWallets',
    'AdminReportsHub',
    'AdminAuditLog',
    'AdminProfits',
  ];

  static List<FinanceSidebarEntry> entriesFor(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return const [...coreEntries, control];
      case AdminRole.accountant:
        return coreEntries;
      case AdminRole.countryAgent:
        return const [
          FinanceSidebarEntry(
            route: 'AdminAgentFinance',
            labelKey: 'nav_agent_finance',
          ),
        ];
      case AdminRole.partner:
      case AdminRole.transportCompany:
      case AdminRole.none:
        return const [];
    }
  }

  static String? labelKeyFor(String routeName) {
    for (final entry in const [...coreEntries, control]) {
      if (entry.route == routeName) return entry.labelKey;
    }
    if (routeName == 'AdminAgentFinance') return 'nav_agent_finance';
    return null;
  }
}
