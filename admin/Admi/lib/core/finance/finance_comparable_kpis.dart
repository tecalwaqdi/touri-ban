import '/backend/financial_accounting_loader.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_ledger_service.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Comparable finance KPIs shared by Hub / Profits / V2 Reports (same meaning).
class FinanceComparableKpis {
  const FinanceComparableKpis({
    required this.currency,
    required this.collectedTripValue,
    required this.platformFees,
    required this.recordedVat,
    required this.driverNet,
    required this.settlementEligibleDue,
    required this.completedAndCollected,
    required this.completedButNotCollected,
    required this.cancelledOrExpired,
    required this.totalsSource,
  });

  final String currency;
  final MoneyAmount collectedTripValue;
  final MoneyAmount platformFees;
  final MoneyAmount recordedVat;
  final MoneyAmount driverNet;
  final MoneyAmount settlementEligibleDue;
  final int completedAndCollected;
  final int completedButNotCollected;
  final int cancelledOrExpired;
  final String totalsSource;

  static FinanceComparableKpis fromCurrencyTotals(
    FinancialCurrencyTotals t, {
    required String totalsSource,
  }) {
    return FinanceComparableKpis(
      currency: t.currency,
      collectedTripValue: t.customerPaidAll,
      platformFees: t.platformFeeAll,
      recordedVat: t.recordedVatAll,
      driverNet: t.driverEntitlementAll,
      settlementEligibleDue: t.cashDriversOweCompany,
      completedAndCollected: t.completedAndCollected,
      completedButNotCollected: t.completedButNotCollected,
      cancelledOrExpired: t.cancelledOrExpired,
      totalsSource: totalsSource,
    );
  }

  static FinanceComparableKpis fromHub(FinanceHubSnapshot hub) {
    return FinanceComparableKpis(
      currency: hub.primaryCurrency,
      collectedTripValue: hub.collectedTripValue,
      platformFees: hub.platformFees,
      recordedVat: hub.recordedVat,
      driverNet: hub.driverNet,
      settlementEligibleDue: hub.settlementEligibleDue,
      completedAndCollected: hub.completedAndCollected,
      completedButNotCollected: hub.completedButNotCollected,
      cancelledOrExpired: hub.cancelledOrExpired,
      totalsSource: hub.totalsSource,
    );
  }

  static FinanceComparableKpis fromReportResult(FinancialReportResult result) {
    final code = result.byCurrency.containsKey('SAR')
        ? 'SAR'
        : (result.byCurrency.keys.isEmpty
            ? 'SAR'
            : (result.byCurrency.keys.toList()..sort()).first);
    final t =
        result.byCurrency[code] ?? FinancialCurrencyTotals(currency: code);
    return fromCurrencyTotals(t, totalsSource: result.totalsSource);
  }

  /// Absolute money deltas (major units) vs [other] for same-currency KPIs.
  Map<String, double> deltasVs(FinanceComparableKpis other) {
    double d(MoneyAmount a, MoneyAmount b) =>
        (a.minorUnits - b.minorUnits).abs() / 100.0;
    return {
      'collected': d(collectedTripValue, other.collectedTripValue),
      'platform': d(platformFees, other.platformFees),
      'vat': d(recordedVat, other.recordedVat),
      'driverNet': d(driverNet, other.driverNet),
      'eligibleDue': d(settlementEligibleDue, other.settlementEligibleDue),
    };
  }

  bool equalsWithinTolerance(FinanceComparableKpis other, {int minorTol = 0}) {
    bool close(MoneyAmount a, MoneyAmount b) =>
        (a.minorUnits - b.minorUnits).abs() <= minorTol;
    return currency == other.currency &&
        close(collectedTripValue, other.collectedTripValue) &&
        close(platformFees, other.platformFees) &&
        close(recordedVat, other.recordedVat) &&
        close(driverNet, other.driverNet) &&
        close(settlementEligibleDue, other.settlementEligibleDue) &&
        completedAndCollected == other.completedAndCollected &&
        completedButNotCollected == other.completedButNotCollected;
  }

  String moneyLabel(MoneyAmount m) =>
      AdminOrderMoneyDisplay.formatMoneyAmount(m);
}
