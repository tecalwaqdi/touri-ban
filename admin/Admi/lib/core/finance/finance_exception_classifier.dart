import '/core/finance/financial_accounting_engine.dart';

/// FIN-6 exception codes — client-side classification from canonical lines.
enum FinanceExceptionCode {
  completedMissingMoney,
  cancelledWithStalePendingCash,
  collectedBeforeCompleted,
  onlinePaidNotCompleted,
  driverNetMissing,
  platformFeeMissing,
  vatInvalid,
  moneyMismatch,
  unknownPaymentMethod,
  agentAttributionMissing,
  agentRateMissing,
  settlementMismatch,
  incompleteFinancialRecord,
  reconciliationDifference,
  unsupportedCurrency,
}

class FinanceExceptionHit {
  const FinanceExceptionHit({
    required this.code,
    required this.orderId,
    this.detail,
  });

  final FinanceExceptionCode code;
  final String orderId;
  final String? detail;
}

/// Classifies a single order line into zero or more exception hits.
abstract final class FinanceExceptionClassifier {
  FinanceExceptionClassifier._();

  static List<FinanceExceptionHit> classify(FinancialOrderLine line) {
    final hits = <FinanceExceptionHit>[];

    if (line.confidence == FinancialConfidence.incomplete) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.incompleteFinancialRecord,
        orderId: line.orderId,
        detail: line.exclusionReason,
      ));
    }

    if (line.lifecycle == FinancialLifecycle.completed &&
        line.confidence == FinancialConfidence.incomplete) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.completedMissingMoney,
        orderId: line.orderId,
      ));
    }

    if (line.bucket == FinancialCollectionBucket.cancelledOrExpired &&
        line.payment == FinancialPaymentState.pendingCash) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.cancelledWithStalePendingCash,
        orderId: line.orderId,
      ));
    }

    if (line.bucket == FinancialCollectionBucket.paidButNotCompleted) {
      hits.add(FinanceExceptionHit(
        code: line.channel == FinancialPaymentChannel.online
            ? FinanceExceptionCode.onlinePaidNotCompleted
            : FinanceExceptionCode.collectedBeforeCompleted,
        orderId: line.orderId,
      ));
    }

    if (line.platformFee == null &&
        line.confidence != FinancialConfidence.incomplete &&
        line.lifecycle == FinancialLifecycle.completed) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.platformFeeMissing,
        orderId: line.orderId,
      ));
    }

    if (line.driverNet == null &&
        line.lifecycle == FinancialLifecycle.completed &&
        line.customerPaid != null) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.driverNetMissing,
        orderId: line.orderId,
      ));
    }

    if (line.reconciliationDifference != null &&
        line.reconciliationDifference!.minorUnits.abs() >
            FinancialAccountingEngine.matchToleranceMinor) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.moneyMismatch,
        orderId: line.orderId,
      ));
    }

    if (line.reconStatus == FinancialReconStatus.difference) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.reconciliationDifference,
        orderId: line.orderId,
      ));
    }

    if (line.channel == FinancialPaymentChannel.unknown) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.unknownPaymentMethod,
        orderId: line.orderId,
      ));
    }

    if (!line.currencySupported) {
      hits.add(FinanceExceptionHit(
        code: FinanceExceptionCode.unsupportedCurrency,
        orderId: line.orderId,
      ));
    }

    for (final note in line.notes) {
      if (note.contains('DRIVER_NET_MISMATCH') ||
          note.contains('RECONCILIATION_DIFFERENCE')) {
        hits.add(FinanceExceptionHit(
          code: FinanceExceptionCode.vatInvalid,
          orderId: line.orderId,
          detail: note,
        ));
      }
    }

    return hits;
  }

  static Map<FinanceExceptionCode, int> countByCode(
    Iterable<FinancialOrderLine> lines,
  ) {
    final counts = <FinanceExceptionCode, int>{};
    for (final line in lines) {
      for (final hit in classify(line)) {
        counts[hit.code] = (counts[hit.code] ?? 0) + 1;
      }
    }
    return counts;
  }
}
