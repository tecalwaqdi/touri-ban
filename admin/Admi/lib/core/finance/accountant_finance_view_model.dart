import '/backend/schema/order_record.dart';
import '/core/admin_currency.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/core/finance/money_amount.dart';

/// One accountant table row — derived only from F1 helpers (no widget math).
class AccountantTripRow {
  const AccountantTripRow({
    required this.orderId,
    required this.tripRefLabel,
    required this.order,
    required this.orderedAt,
    required this.countryPath,
    required this.countryLabel,
    required this.driverId,
    required this.driverLabel,
    required this.agentId,
    required this.agentLabel,
    required this.agentAttribution,
    required this.paymentMethodLabel,
    required this.paymentStatusLabel,
    required this.tripStatusLabel,
    required this.collectionStatusLabel,
    required this.moneyHolderLabel,
    required this.dueDirectionLabel,
    required this.settlementStatusLabel,
    required this.dataQuality,
    required this.dataQualityLabel,
    required this.operationallyCompleted,
    required this.grossDisplay,
    required this.companyCommissionDisplay,
    required this.vatDisplay,
    required this.driverNetDisplay,
    required this.agentAmountDisplay,
    required this.agentAmountIsShareOfCommission,
    required this.missingFields,
    required this.source,
    required this.confidenceLabel,
    required this.currency,
  });

  final String orderId;
  final String tripRefLabel;
  final OrderRecord order;
  final DateTime? orderedAt;
  final String? countryPath;
  final String countryLabel;
  final String? driverId;
  final String driverLabel;
  final String? agentId;
  final String agentLabel;
  final FinancialAgentAttribution agentAttribution;
  final String paymentMethodLabel;
  final String paymentStatusLabel;
  final String tripStatusLabel;
  final String collectionStatusLabel;
  final String moneyHolderLabel;
  final String dueDirectionLabel;
  final String settlementStatusLabel;
  final FinancialDataQuality dataQuality;
  final String dataQualityLabel;
  final bool operationallyCompleted;
  final String grossDisplay;
  final String companyCommissionDisplay;
  final String vatDisplay;
  final String driverNetDisplay;
  final String agentAmountDisplay;
  final bool agentAmountIsShareOfCommission;
  final List<String> missingFields;
  final String source;
  final String confidenceLabel;
  final String currency;

  static AccountantTripRow fromOrder(OrderRecord order, {String? symbol}) {
    final snap = FinancialOrderAdapter.fromOrder(order);
    final line = FinancialAccountingEngine.analyze(snap);
    final resolution = FinancialAmountResolution.fromLine(line);
    final completed =
        FinancialTripSemantics.isOperationallyCompletedSnapshot(snap);
    final paid = FinancialTripSemantics.isPaymentPaid(order);
    final cashCollected = FinancialTripSemantics.isCashCollected(order);
    final agentAttr = FinancialAgentAttributionResolver.classify(snap);
    final agentId = FinancialAgentAttributionResolver.historicalAgentId(snap);
    final sym = symbol ??
        AdminCurrency.symbolByCode[line.currency] ??
        line.currency;

    String money(MoneyAmount? m) {
      if (resolution.quality != FinancialDataQuality.complete) {
        return AccountantFinanceLabels.emDash();
      }
      return AdminOrderMoneyDisplay.formatMoneyAmount(m, symbolOverride: sym);
    }

    final channel = line.channel;
    final settlementRaw = (order.snapshotData['settlement_status'] ??
            order.snapshotData['financial_settlement_status'] ??
            '')
        .toString();

    final hasAgentAmount = snap.agentAmountMinor != null &&
        agentAttr == FinancialAgentAttribution.confident;
    final agentAmount = hasAgentAmount
        ? AdminOrderMoneyDisplay.formatMoneyAmount(
            MoneyAmount(
              currency: line.currency,
              minorUnits: snap.agentAmountMinor!,
            ),
          )
        : AccountantFinanceLabels.emDash();

    final driverName = order.naimMndobText.trim();
    final driverLabel = driverName.isNotEmpty
        ? driverName
        : AccountantFinanceLabels.emDash();

    return AccountantTripRow(
      orderId: order.reference.id,
      tripRefLabel: AccountantFinanceLabels.tripRefLabel(order.reference.id),
      order: order,
      orderedAt: order.dataOrder,
      countryPath: snap.countryPath,
      countryLabel: AccountantFinanceLabels.countryHumanAr(snap.countryPath),
      driverId: snap.driverId,
      driverLabel: driverLabel,
      agentId: agentId,
      agentLabel: agentAttr == FinancialAgentAttribution.missing
          ? AccountantFinanceLabels.agentAttributionAr(agentAttr)
          : (agentId == null || agentId.isEmpty
              ? AccountantFinanceLabels.emDash()
              : AccountantFinanceLabels.tripRefLabel(agentId)),
      agentAttribution: agentAttr,
      paymentMethodLabel:
          AccountantFinanceLabels.paymentMethodAr(snap.paymentMethodRaw),
      paymentStatusLabel:
          AccountantFinanceLabels.paymentStatusAr(snap.paymentStatus),
      tripStatusLabel:
          AccountantFinanceLabels.tripOperationalStatusAr(snap.statusCode),
      collectionStatusLabel: AccountantFinanceLabels.collectionStatusAr(
        cashChannel: channel == FinancialPaymentChannel.cash,
        collected: cashCollected,
      ),
      moneyHolderLabel: AccountantFinanceLabels.moneyHolderAr(
        channel: channel,
        operationallyCompleted: completed,
        cashCollected: cashCollected,
        paymentPaid: paid,
      ),
      dueDirectionLabel: AccountantFinanceLabels.dueDirectionAr(
        channel: channel,
        operationallyCompleted: completed,
        cashCollected: cashCollected,
        paymentPaid: paid,
      ),
      settlementStatusLabel:
          AccountantFinanceLabels.settlementStatusAr(settlementRaw),
      dataQuality: resolution.quality,
      dataQualityLabel:
          AccountantFinanceLabels.dataQualityAr(resolution.quality),
      operationallyCompleted: completed,
      grossDisplay: money(resolution.gross),
      companyCommissionDisplay: money(resolution.companyCommission),
      vatDisplay: money(resolution.vat),
      driverNetDisplay: money(resolution.driverNet),
      agentAmountDisplay: agentAmount,
      agentAmountIsShareOfCommission: hasAgentAmount,
      missingFields: resolution.missingFields,
      source: resolution.source,
      confidenceLabel: switch (resolution.confidence) {
        FinancialConfidence.high => 'مؤكد',
        FinancialConfidence.derived => 'مشتق',
        FinancialConfidence.incomplete => 'ناقص',
      },
      currency: line.currency,
    );
  }
}

/// Read-only accountant screen bundle (summary + trips + alerts).
class AccountantFinanceViewBundle {
  const AccountantFinanceViewBundle({
    required this.model,
    required this.trips,
    required this.alerts,
    required this.currency,
    required this.periodLabel,
    required this.docsScanned,
    required this.truncated,
    required this.openSettlementsRemaining,
    this.fixturesExcludedFromTable = 0,
  });

  final AccountantFinanceReadModel model;
  final List<AccountantTripRow> trips;
  final List<String> alerts;
  final String currency;
  final String periodLabel;
  final int docsScanned;
  final bool truncated;
  final int openSettlementsRemaining;
  final int fixturesExcludedFromTable;

  int get partialOrUnresolved =>
      model.completedTripsWithPartialFinancialData +
      model.completedTripsWithUnresolvedFinancialData;
}
