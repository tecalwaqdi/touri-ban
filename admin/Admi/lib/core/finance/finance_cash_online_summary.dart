import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Cash vs online operational summary (FIN-5).
class FinanceCashOnlineSummary {
  const FinanceCashOnlineSummary({
    required this.currency,
    required this.cashCompletedPending,
    required this.cashCompletedPendingValue,
    required this.cashCollectedTrips,
    required this.cashCollectedValue,
    required this.cashHeldByDrivers,
    required this.companyDueFromDrivers,
    required this.settledCompanyDueMinor,
    required this.outstandingCompanyDue,
    required this.onlineCompletedPaid,
    required this.onlineCompletedUnpaid,
    required this.onlineCancelledPaid,
    required this.refundPendingCount,
    required this.refundedCount,
    required this.capturedCount,
    required this.driverPayable,
    required this.paidToDriver,
    required this.outstandingToDriver,
    required this.cancelledStalePendingCash,
  });

  final String currency;

  final int cashCompletedPending;
  final MoneyAmount cashCompletedPendingValue;
  final int cashCollectedTrips;
  final MoneyAmount cashCollectedValue;
  final MoneyAmount cashHeldByDrivers;
  final MoneyAmount companyDueFromDrivers;
  final int settledCompanyDueMinor;
  final MoneyAmount outstandingCompanyDue;

  final int onlineCompletedPaid;
  final int onlineCompletedUnpaid;
  final int onlineCancelledPaid;
  final int refundPendingCount;
  final int refundedCount;
  final int capturedCount;
  final MoneyAmount driverPayable;
  final MoneyAmount paidToDriver;
  final MoneyAmount outstandingToDriver;

  final int cancelledStalePendingCash;

  static FinanceCashOnlineSummary fromTotals(
    FinancialCurrencyTotals t, {
    Iterable<FinancialOrderLine> lines = const [],
    int settledCompanyDueMinor = 0,
    int paidToDriverMinor = 0,
  }) {
    var onlineCompletedPaid = 0;
    var onlineCompletedUnpaid = 0;
    var onlineCancelledPaid = 0;
    var refundPending = 0;
    var refunded = 0;
    var captured = 0;
    var cancelledStale = 0;

    for (final line in lines) {
      if (line.channel != FinancialPaymentChannel.online) continue;
      if (line.lifecycle == FinancialLifecycle.completed &&
          line.payment == FinancialPaymentState.paid) {
        onlineCompletedPaid++;
      } else if (line.lifecycle == FinancialLifecycle.completed &&
          line.payment != FinancialPaymentState.paid) {
        onlineCompletedUnpaid++;
      } else if (line.bucket == FinancialCollectionBucket.cancelledOrExpired &&
          line.payment == FinancialPaymentState.paid) {
        onlineCancelledPaid++;
      }
      if (line.payment == FinancialPaymentState.refunded) refunded++;
      if (line.payment == FinancialPaymentState.processing) refundPending++;
      if (line.payment == FinancialPaymentState.captured) captured++;
      if (line.bucket == FinancialCollectionBucket.cancelledOrExpired &&
          line.payment == FinancialPaymentState.pendingCash) {
        cancelledStale++;
      }
    }

    if (lines.isEmpty) {
      onlineCompletedPaid = t.onlinePaidTrips;
      onlineCompletedUnpaid = t.onlineCompletedPending;
    }

    final driverPayable = t.onlineDriverEntitlements;
    final outstanding = MoneyAmount(
      currency: t.currency,
      minorUnits: (driverPayable.minorUnits - paidToDriverMinor)
          .clamp(0, 1 << 31),
    );

    return FinanceCashOnlineSummary(
      currency: t.currency,
      cashCompletedPending: t.cashCompletedPending,
      cashCompletedPendingValue: t.cashCompletedPendingMinor,
      cashCollectedTrips: t.cashCollectedTrips,
      cashCollectedValue: t.cashCustomerCollected,
      cashHeldByDrivers: t.cashHeldByDrivers,
      companyDueFromDrivers: t.cashDriversOweCompany,
      settledCompanyDueMinor: settledCompanyDueMinor,
      outstandingCompanyDue: MoneyAmount(
        currency: t.currency,
        minorUnits: (t.cashDriversOweCompany.minorUnits - settledCompanyDueMinor)
            .clamp(0, 1 << 31),
      ),
      onlineCompletedPaid: onlineCompletedPaid,
      onlineCompletedUnpaid: onlineCompletedUnpaid,
      onlineCancelledPaid: onlineCancelledPaid,
      refundPendingCount: refundPending,
      refundedCount: refunded,
      capturedCount: captured,
      driverPayable: driverPayable,
      paidToDriver: MoneyAmount(
        currency: t.currency,
        minorUnits: paidToDriverMinor,
      ),
      outstandingToDriver: outstanding,
      cancelledStalePendingCash: cancelledStale,
    );
  }
}
