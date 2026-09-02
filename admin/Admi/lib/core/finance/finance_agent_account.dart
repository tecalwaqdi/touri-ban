import '/backend/schema/user_record.dart';
import '/core/finance/finance_agent_attribution.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Agent finance account (FIN-4) — scope-based; no fabricated historical commission.
class AgentFinanceAccount {
  const AgentFinanceAccount({
    required this.agentId,
    required this.agentName,
    required this.countryPath,
    required this.scope,
    required this.attributionConfidence,
    required this.commissionRatePercent,
    required this.attributedTrips,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.attributedSales,
    required this.cashSales,
    required this.onlineSales,
    required this.provableCommission,
    required this.dueMinor,
    required this.paidMinor,
    required this.outstandingMinor,
    required this.statementRows,
    required this.unprovableHistorical,
  });

  final String agentId;
  final String agentName;
  final String? countryPath;
  final AgentAttributionScope scope;
  final AgentAttributionConfidence attributionConfidence;
  final double commissionRatePercent;
  final int attributedTrips;
  final int completedTrips;
  final int cancelledTrips;
  final MoneyAmount attributedSales;
  final MoneyAmount cashSales;
  final MoneyAmount onlineSales;
  final MoneyAmount provableCommission;
  final int dueMinor;
  final int paidMinor;
  final int outstandingMinor;
  final List<AgentStatementRow> statementRows;
  final bool unprovableHistorical;

  static AgentFinanceAccount fromAgentAndLines({
    required UserRecord agent,
    required List<FinancialOrderLine> countryLines,
    required String currency,
    bool exclusiveCountryAgent = false,
    int paidMinor = 0,
    int outstandingMinor = 0,
  }) {
    final code = currency;
    final filtered =
        countryLines.where((l) => l.currency == code).toList(growable: false);
    final totals =
        FinancialAccountingEngine.aggregateByCurrency(filtered)[code] ??
            FinancialCurrencyTotals(currency: code);

    final realizedSales = totals.completedAndCollectedMinor;
    final rate = agent.agentTotal;
    final confidence = exclusiveCountryAgent && rate > 0
        ? AgentAttributionConfidence.provable
        : AgentAttributionConfidence.scopeOnly;
    final scope = exclusiveCountryAgent
        ? AgentAttributionScope.countryExclusive
        : AgentAttributionScope.countryScopeOnly;

    MoneyAmount commission = MoneyAmount.zero(code);
    var snapshottedMinor = 0;
    for (final line in filtered) {
      if (line.agentId == agent.reference.id && line.hasProvableAgentSnapshot) {
        snapshottedMinor += line.agentAmount!.minorUnits;
      }
    }
    if (snapshottedMinor > 0) {
      commission = MoneyAmount(currency: code, minorUnits: snapshottedMinor);
    } else if (confidence == AgentAttributionConfidence.provable && rate > 0) {
      commission = MoneyAmount(
        currency: code,
        minorUnits: (realizedSales.minorUnits * rate / 100).round(),
      );
    }

    return AgentFinanceAccount(
      agentId: agent.reference.id,
      agentName: agent.displayName,
      countryPath: agent.revDlohAgent?.path,
      scope: scope,
      attributionConfidence: confidence,
      commissionRatePercent: rate,
      attributedTrips: filtered.length,
      completedTrips: totals.lifecycleCompleted,
      cancelledTrips: totals.lifecycleCancelled + totals.lifecycleExpired,
      attributedSales: MoneyAmount(
        currency: code,
        minorUnits: realizedSales.minorUnits +
            totals.completedButNotCollectedMinor.minorUnits,
      ),
      cashSales: MoneyAmount(
        currency: code,
        minorUnits: totals.cashCustomerCollected.minorUnits +
            totals.cashCompletedPendingMinor.minorUnits,
      ),
      onlineSales: MoneyAmount(
        currency: code,
        minorUnits: totals.onlineCustomerPaid.minorUnits +
            totals.onlineCompletedPendingMinor.minorUnits,
      ),
      provableCommission: commission,
      dueMinor: commission.minorUnits,
      paidMinor: paidMinor,
      outstandingMinor: outstandingMinor > 0
          ? outstandingMinor
          : (commission.minorUnits - paidMinor).clamp(0, 1 << 31),
      statementRows: filtered
          .map((l) => AgentStatementRow(line: l, agentRatePercent: rate))
          .toList(growable: false),
      unprovableHistorical: confidence != AgentAttributionConfidence.provable,
    );
  }
}

class AgentStatementRow {
  const AgentStatementRow({
    required this.line,
    required this.agentRatePercent,
  });

  final FinancialOrderLine line;
  final double agentRatePercent;

  MoneyAmount? agentCommission(String currency) {
    if (line.hasProvableAgentSnapshot && line.agentAmount != null) {
      return line.agentAmount;
    }
    if (agentRatePercent <= 0 || !line.qualifiesCollectedCash) return null;
    final base = line.platformFee ?? line.customerPaid;
    if (base == null) return null;
    return MoneyAmount(
      currency: currency,
      minorUnits: (base.minorUnits * agentRatePercent / 100).round(),
    );
  }
}
