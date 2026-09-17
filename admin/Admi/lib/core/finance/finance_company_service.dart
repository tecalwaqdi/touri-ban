import '/backend/admin_ops_filters.dart';
import '/backend/financial_accounting_loader.dart';
import '/core/finance/finance_cash_online_summary.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/finance_exception_classifier.dart';
import '/core/finance/finance_runtime_gate.dart';
import '/core/finance/finance_sot_settlement_stats.dart';
import '/core/finance/financial_accounting_engine.dart';

/// Loads FIN-2 company snapshot + FIN-5/6 helpers (server-authoritative totals).
abstract final class FinanceCompanyService {
  FinanceCompanyService._();

  static Future<FinanceCompanySnapshot> load({
    required AdminDatePreset datePreset,
    String periodLabel = '',
    DateTime? customStart,
    DateTime? customEnd,
    FinancialReportFilter? extraFilters,
  }) async {
    final filter = extraFilters ??
        FinancialReportFilter(
          datePreset: datePreset,
          customStart: customStart,
          customEnd: customEnd,
        );
    final result = await FinancialAccountingLoader.load(
      filter,
      requireCanonicalServer: true,
    );
    FinanceRuntimeGate.setAuthoritativeBackendData(
      result.totalsSource != 'client_full',
    );

    final settlementStats = await FinanceSotSettlementStats.load();
    return FinanceCompanySnapshot.fromReport(
      result,
      periodLabel: periodLabel,
      settledCount: settlementStats.available ? settlementStats.settled : 0,
      pendingSettlementCount:
          settlementStats.available ? settlementStats.pending : 0,
      // Keep outstanding only when the SoT rollup succeeded; otherwise 0 is
      // a counter placeholder and UI must check [settlementStatsAvailable].
      outstandingSettlementMinor: settlementStats.available
          ? settlementStats.outstandingMinor
          : 0,
      settlementStatsAvailable: settlementStats.available,
    );
  }

  static Future<({
    FinanceCompanySnapshot company,
    FinanceCashOnlineSummary channels,
    Map<FinanceExceptionCode, int> exceptions,
    bool settlementStatsAvailable,
  })> loadFull({
    required AdminDatePreset datePreset,
    String periodLabel = '',
  }) async {
    final filter = FinancialReportFilter(datePreset: datePreset);
    final result = await FinancialAccountingLoader.load(
      filter,
      requireCanonicalServer: true,
    );
    final code = result.byCurrency.containsKey('SAR')
        ? 'SAR'
        : (result.byCurrency.keys.isEmpty
            ? 'SAR'
            : result.byCurrency.keys.first);
    final t = result.byCurrency[code] ??
        FinancialCurrencyTotals(currency: code);
    final settlementStats = await FinanceSotSettlementStats.load();

    // settledCompanyDueMinor = confirmed payments toward company due,
    // NEVER outstanding (expected − paid). Confusing the two understates
    // remaining cash liability.
    final settledCompanyDueMinor = settlementStats.available
        ? settlementStats.paidConfirmedMinor
        : 0;

    return (
      company: FinanceCompanySnapshot.fromReport(
        result,
        periodLabel: periodLabel,
        settledCount: settlementStats.available ? settlementStats.settled : 0,
        pendingSettlementCount:
            settlementStats.available ? settlementStats.pending : 0,
        outstandingSettlementMinor: settlementStats.available
            ? settlementStats.outstandingMinor
            : 0,
        settlementStatsAvailable: settlementStats.available,
      ),
      channels: FinanceCashOnlineSummary.fromTotals(
        t,
        lines: result.allMatchingLines,
        settledCompanyDueMinor: settledCompanyDueMinor,
        settlementStatsAvailable: settlementStats.available,
      ),
      exceptions: FinanceExceptionClassifier.countByCode(
        result.allMatchingLines,
      ),
      settlementStatsAvailable: settlementStats.available,
    );
  }
}
