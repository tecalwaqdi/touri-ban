import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_record.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/toury_system_status_codes.dart';

/// F1 trip / payment / collection / settlement semantic axes.
///
/// Forbidden equivalences (never collapse):
/// - operationalCompleted ↔ paymentPaid
/// - operationalCompleted ↔ cashCollected
/// - operationalCompleted ↔ settlementExists
abstract final class FinancialTripSemantics {
  FinancialTripSemantics._();

  /// Alias for live KPI exclusion — reuses [AdminQaFixture].
  static bool isFinanceQaFixture(OrderRecord order) =>
      AdminQaFixture.isFixtureOrder(order);

  static bool isFinanceQaFixtureSnapshot(FinancialOrderSnapshot o) =>
      AdminQaFixture.isFixtureId(o.orderId);

  static bool isOperationallyCompletedSnapshot(FinancialOrderSnapshot o) {
    return FinancialAccountingEngine.normalizedLifecycleStatus(o) ==
        FinancialLifecycle.completed;
  }

  static bool isOperationallyCompleted(OrderRecord order) =>
      isOperationallyCompletedSnapshot(FinancialOrderAdapter.fromOrder(order));

  static bool isPaymentPaidSnapshot(FinancialOrderSnapshot o) {
    final pay = FinancialAccountingEngine.normalizedPaymentStatus(o);
    return pay == FinancialPaymentState.paid ||
        pay == FinancialPaymentState.cashCollected ||
        pay == FinancialPaymentState.captured;
  }

  /// Payment axis only — never uses Arabic trip-complete copy.
  static bool isPaymentPaid(OrderRecord order) {
    final snap = FinancialOrderAdapter.fromOrder(order);
    if (isPaymentPaidSnapshot(snap)) return true;
    // Legacy Paid enum / string — payment-ish, not trip complete.
    if (order.halhOrder == Halh.Paid) return true;
    final halh = order.halh.trim().toLowerCase();
    if (halh == 'paid') return true;
    return false;
  }

  static bool isCashCollectedSnapshot(FinancialOrderSnapshot o) {
    final pay = (o.paymentStatus ?? '').trim().toLowerCase();
    if (pay == TourySystemStatusCodes.cashCollected ||
        pay == 'cash_collected') {
      return true;
    }
    // cash_collection_status is not on FinancialOrderSnapshot — OrderRecord path.
    return false;
  }

  static bool isCashCollected(OrderRecord order) {
    final pay = (order.snapshotData['payment_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (pay == TourySystemStatusCodes.cashCollected || pay == 'cash_collected') {
      return true;
    }
    final cash = (order.snapshotData['cash_collection_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return cash == 'collected';
  }

  /// Settlement is a separate axis — F1 does not invent settlement from trip fields.
  static bool isSettlementCompleteOnOrder(OrderRecord order) {
    final status = (order.snapshotData['settlement_status'] ??
            order.snapshotData['financial_settlement_status'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    return status == 'settled' || status == 'complete' || status == 'completed';
  }

  static String? paymentMethodRaw(OrderRecord order) {
    if (order.hasPaymentMethod()) return order.paymentMethod!.name;
    final raw = order.snapshotData['PaymentMethod'];
    final s = (raw ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? paymentStatusRaw(OrderRecord order) {
    final raw = order.snapshotData['payment_status'];
    final s = (raw ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// Agent attribution confidence for a historical trip (read-only).
enum FinancialAgentAttribution {
  confident,
  missing,
  legacy,
}

abstract final class FinancialAgentAttributionResolver {
  FinancialAgentAttributionResolver._();

  static FinancialAgentAttribution classify(FinancialOrderSnapshot o) {
    final id = (o.agentId ?? '').trim();
    final amount = o.agentAmountMinor;
    final status = (o.agentAttributionStatus ?? '').trim().toLowerCase();
    if (id.isNotEmpty &&
        (amount != null || status == 'attributed' || status == 'snapshot')) {
      return FinancialAgentAttribution.confident;
    }
    if (id.isNotEmpty) return FinancialAgentAttribution.legacy;
    return FinancialAgentAttribution.missing;
  }

  /// Never backfill current country agent when snapshot missing.
  static String? historicalAgentId(FinancialOrderSnapshot o) {
    final id = (o.agentId ?? '').trim();
    return id.isEmpty ? null : id;
  }
}
