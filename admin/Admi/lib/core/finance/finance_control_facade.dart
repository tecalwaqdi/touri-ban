import '/backend/admin_ops_filters.dart';
import '/backend/backend.dart';
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/admin_finance_repository.dart';
import '/core/finance/finance_company_service.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/settlement_preview.dart';

/// Single read facade for Finance Control Center UI + exports.
///
/// **No money formulas here** — delegates to FIN V2 loaders/services only.
abstract final class FinanceControlFacade {
  FinanceControlFacade._();

  static AccountantFinanceScope scopeForCurrentUser({
    DocumentReference? countryOverride,
  }) =>
      AccountantFinanceLoader.scopeForCurrentUser(
        countryOverride: countryOverride,
      );

  /// Hub KPIs — CF aggregateFinancialAccountingV2 via [FinanceCompanyService].
  static Future<FinanceCompanySnapshot> loadCompanyKpis({
    required AdminDatePreset datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    String periodLabel = '',
  }) {
    return FinanceCompanyService.load(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
      periodLabel: periodLabel,
    );
  }

  /// Bounded first page for Hub / Trip Ledger (no full-history scan).
  static Future<List<AccountantTripRow>> loadTripLedgerPage({
    AdminDatePreset datePreset = AdminDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    String currency = 'SAR',
    bool forceRefresh = false,
  }) {
    return AccountantFinanceLoader.loadFirstPage(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
      countryRef: countryRef,
      driverRef: driverRef,
      currency: currency,
      forceRefresh: forceRefresh,
    );
  }

  /// Full accountant bundle (period summary + rows) — prefer for Reports.
  static Future<AccountantFinanceViewBundle> loadAccountantBundle({
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
    return AccountantFinanceLoader.load(
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

  static SettlementPreview buildSettlementPreview({
    required String driverId,
    required String currency,
    required Iterable<FinancialOrderLine> lines,
    DateTime? from,
    DateTime? to,
    String? countryPath,
  }) {
    return SettlementPreview.build(
      driverId: driverId,
      currency: currency,
      lines: lines,
      from: from,
      to: to,
      countryPath: countryPath,
    );
  }

  /// Clears short-lived repository caches (tests / force refresh).
  static void clearCaches() => AdminFinanceRepository.instance.clearSession();
}
