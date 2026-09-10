import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_trip_semantics.dart';

/// Incomplete / agent / settlement alerts derived from V2 trip rows + ledger.
abstract final class FinanceV2Alerts {
  FinanceV2Alerts._();

  static ({
    int incomplete,
    int unattributedAgent,
    List<String> alerts,
  }) build({
    required List<AccountantTripRow> trips,
    required int openSettlementsRemaining,
  }) {
    var incomplete = 0;
    var unattributed = 0;
    for (final t in trips) {
      if (!t.operationallyCompleted) continue;
      if (t.dataQuality == FinancialDataQuality.partial ||
          t.dataQuality == FinancialDataQuality.unresolved) {
        incomplete++;
      }
      if (t.agentAttribution == FinancialAgentAttribution.missing) {
        unattributed++;
      }
    }

    final alerts = <String>[];
    if (incomplete > 0) {
      alerts.add('$incomplete رحلات مكتملة تحتاج استكمال بيانات مالية');
    }
    if (unattributed > 0) {
      alerts.add('$unattributed رحلات بدون إسناد وكيل تاريخي موثوق');
    }
    if (openSettlementsRemaining > 0) {
      alerts.add('$openSettlementsRemaining تسويات بها مبلغ متبقٍ / غير مسددة');
    }
    return (
      incomplete: incomplete,
      unattributedAgent: unattributed,
      alerts: alerts,
    );
  }
}
