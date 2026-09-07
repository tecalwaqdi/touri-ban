import '/core/finance/admin_finance_repository.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_order_query.dart';
import '/core/finance/finance_reconciliation_read_model.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/backend/backend.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/core/admin_qa_fixture.dart';

/// Loads orders (scoped) and builds [AccountantFinanceViewBundle] via F1 only.
///
/// PERF-P2A: completed-candidate server queries + first-page callback.
/// PERF-P3: delegates Firestore source loading to [AdminFinanceRepository]
/// (coalescing + short session cache). Summary never uses visible page only.
/// PERF-P4A: explicit first-page fast path independent of period summary.
abstract final class AccountantFinanceLoader {
  AccountantFinanceLoader._();

  /// Retained for report/tests — hard scan ceiling (completed-only).
  static const int scanCap = FinanceOrderQuery.scanCap;

  static AccountantFinanceScope scopeForCurrentUser({
    DocumentReference? countryOverride,
  }) =>
      AccountantFinanceLoaderScope.scopeForCurrentUser(
        countryOverride: countryOverride,
      );

  /// PERF-P4A critical path — modern first page only (no summary / maps).
  static Future<List<AccountantTripRow>> loadFirstPage({
    AdminDatePreset datePreset = AdminDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    String currency = 'SAR',
    bool forceRefresh = false,
  }) {
    return AdminFinanceRepository.instance.loadHubFirstPage(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
      countryRef: countryRef,
      driverRef: driverRef,
      currency: currency,
      forceRefresh: forceRefresh,
    );
  }

  static Future<AccountantFinanceViewBundle> load({
    AdminDatePreset datePreset = AdminDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    String currency = 'SAR',
    String periodLabel = '',
    void Function(List<AccountantTripRow> firstRows, int docsRead)? onFirstPage,
    bool forceRefresh = false,
  }) {
    return AdminFinanceRepository.instance.loadHubBundle(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
      countryRef: countryRef,
      driverRef: driverRef,
      currency: currency,
      periodLabel: periodLabel,
      onFirstPage: onFirstPage,
      forceRefresh: forceRefresh,
    );
  }

  /// Broad completed-trip scan for B1 reconciliation workspace (scoped).
  static Future<List<OrderRecord>> loadOrdersForCurrentScope({
    AdminDatePreset datePreset = AdminDatePreset.thisYear,
    void Function(List<OrderRecord> firstPage, int docsRead)? onFirstPage,
    bool forceRefresh = false,
  }) async {
    final scan = await AdminFinanceRepository.instance.loadCompletedScan(
      datePreset: datePreset,
      onFirstPage: onFirstPage,
      forceRefresh: forceRefresh,
    );
    return scan.orders;
  }

  static bool usesCountryFinanceScopeSafe() =>
      AdminRoleService.usesCountryFinanceScope;

  /// Settlement docs as maps for B1 association (read-only, paginated chunks).
  static Future<List<Map<String, dynamic>>> loadSettlementsMaps({
    bool forceRefresh = false,
  }) {
    return AdminFinanceRepository.instance.loadSettlementsMaps(
      forceRefresh: forceRefresh,
    );
  }

  /// PERF-P4A: first-page reconciliation with settlement membership evidence.
  static Future<FinanceReconciliationResult> loadReconciliationFirstPage({
    AdminDatePreset datePreset = AdminDatePreset.thisYear,
    bool forceRefresh = false,
  }) {
    return AdminFinanceRepository.instance.loadReconciliationFirstPage(
      datePreset: datePreset,
      forceRefresh: forceRefresh,
    );
  }

  static Future<FinanceReconciliationResult> loadReconciliation({
    AdminDatePreset datePreset = AdminDatePreset.thisYear,
    void Function(FinanceReconciliationResult partial)? onFirstPage,
    bool forceRefresh = false,
  }) {
    return AdminFinanceRepository.instance.loadReconciliation(
      datePreset: datePreset,
      onFirstPage: onFirstPage,
      forceRefresh: forceRefresh,
    );
  }
}

/// Filter helpers for the money-movement table (presentation only).
abstract final class AccountantTripFilters {
  static List<AccountantTripRow> apply(
    List<AccountantTripRow> rows, {
    String? paymentMethod,
    String? collectionStatus,
    String? settlementStatus,
    FinancialDataQuality? quality,
    String? search,
  }) {
    return rows.where((r) {
      if (AdminQaFixture.isFixtureId(r.orderId) ||
          FinancialTripSemantics.isFinanceQaFixture(r.order)) {
        return false;
      }
      if (paymentMethod != null &&
          paymentMethod.isNotEmpty &&
          r.paymentMethodLabel != paymentMethod) {
        return false;
      }
      if (collectionStatus != null &&
          collectionStatus.isNotEmpty &&
          r.collectionStatusLabel != collectionStatus) {
        return false;
      }
      if (settlementStatus != null &&
          settlementStatus.isNotEmpty &&
          r.settlementStatusLabel != settlementStatus) {
        return false;
      }
      if (quality != null && r.dataQuality != quality) return false;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final hay =
            '${r.orderId} ${r.driverLabel} ${r.agentLabel} ${r.countryLabel}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}
