import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_state_labels.dart';
import '/core/finance/money_amount.dart';

/// One row in كشف حساب المندوب (FIN-3).
class DriverStatementRow {
  const DriverStatementRow({
    required this.orderId,
    required this.line,
    this.bookedAt,
  });

  final String orderId;
  final FinancialOrderLine line;
  final DateTime? bookedAt;

  MoneyAmount? get tripValue => line.customerPaid;
  MoneyAmount? get platformFee => line.platformFee;
  MoneyAmount? get vat => line.recordedVat;
  MoneyAmount? get driverNet => line.driverNet;
  MoneyAmount? get cashCollected =>
      line.qualifiesCollectedCash ? line.customerPaid : null;
  MoneyAmount? get companyDue =>
      line.qualifiesCollectedCash ? line.signedCashPosition : null;

  String lifecycleLabel() => FinancialStateLabels.lifecycleAr(line.lifecycle);
  String paymentLabel() => FinancialStateLabels.paymentAr(line.payment);
  String financialStatusLabel() =>
      FinancialStateLabels.financialStatusAr(line);
  String channelLabel() => FinancialStateLabels.channelAr(line.channel);
}

/// Driver financial account snapshot (FIN-3) — parity with V2 engine fields.
class DriverFinanceAccount {
  const DriverFinanceAccount({
    required this.driverId,
    required this.currency,
    required this.totals,
    required this.statementRows,
    required this.cashHeld,
    required this.companyReceivable,
    required this.companyPayable,
    required this.settledMinor,
    required this.outstandingMinor,
  });

  final String driverId;
  final String currency;
  final FinancialCurrencyTotals totals;
  final List<DriverStatementRow> statementRows;
  final MoneyAmount cashHeld;
  final MoneyAmount companyReceivable;
  final MoneyAmount companyPayable;
  final int settledMinor;
  final int outstandingMinor;

  int get totalTrips => statementRows.length;
  int get completedTrips => totals.lifecycleCompleted;
  int get cancelledTrips =>
      totals.lifecycleCancelled + totals.lifecycleExpired;

  static DriverFinanceAccount fromLines({
    required String driverId,
    required String currency,
    required List<FinancialOrderLine> lines,
    int settledMinor = 0,
    int outstandingMinor = 0,
  }) {
    final filtered =
        lines.where((l) => l.currency == currency).toList(growable: false);
    final byCurrency =
        FinancialAccountingEngine.aggregateByCurrency(filtered);
    final t = byCurrency[currency] ?? FinancialCurrencyTotals(currency: currency);

    return DriverFinanceAccount(
      driverId: driverId,
      currency: currency,
      totals: t,
      statementRows: filtered
          .map((l) => DriverStatementRow(orderId: l.orderId, line: l))
          .toList(growable: false),
      cashHeld: t.cashHeldByDrivers,
      companyReceivable: t.cashDriversOweCompany,
      companyPayable: MoneyAmount(
        currency: currency,
        minorUnits: t.cashCompanyOwesDrivers.minorUnits +
            t.onlineCompanyOwesDrivers.minorUnits,
      ),
      settledMinor: settledMinor,
      outstandingMinor: outstandingMinor,
    );
  }
}
