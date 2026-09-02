import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/financial_accounting_loader.dart';
import '/core/finance/finance_cash_online_summary.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/finance_exception_classifier.dart';
import '/core/finance/finance_runtime_gate.dart';
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

    final settlementStats = await _loadSettlementReadOnlyStats();
    return FinanceCompanySnapshot.fromReport(
      result,
      periodLabel: periodLabel,
      settledCount: settlementStats.settled,
      pendingSettlementCount: settlementStats.pending,
      outstandingSettlementMinor: settlementStats.outstandingMinor,
    );
  }

  static Future<({
    FinanceCompanySnapshot company,
    FinanceCashOnlineSummary channels,
    Map<FinanceExceptionCode, int> exceptions,
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
    final settlementStats = await _loadSettlementReadOnlyStats();

    return (
      company: FinanceCompanySnapshot.fromReport(
        result,
        periodLabel: periodLabel,
        settledCount: settlementStats.settled,
        pendingSettlementCount: settlementStats.pending,
        outstandingSettlementMinor: settlementStats.outstandingMinor,
      ),
      channels: FinanceCashOnlineSummary.fromTotals(
        t,
        lines: result.allMatchingLines,
        settledCompanyDueMinor: settlementStats.outstandingMinor,
      ),
      exceptions: FinanceExceptionClassifier.countByCode(
        result.allMatchingLines,
      ),
    );
  }

  static Future<({int settled, int pending, int outstandingMinor})>
      _loadSettlementReadOnlyStats() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('financial_settlements')
          .limit(500)
          .get();
      var settled = 0;
      var pending = 0;
      var outstanding = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final st = (d['status'] ?? '').toString();
        if (st == 'settled') settled++;
        if (st == 'draft' || st == 'locked' || st == 'partially_paid') {
          pending++;
        }
        outstanding += (d['outstandingMinor'] as num?)?.toInt() ?? 0;
      }
      return (settled: settled, pending: pending, outstandingMinor: outstanding);
    } catch (_) {
      return (settled: 0, pending: 0, outstandingMinor: 0);
    }
  }
}
