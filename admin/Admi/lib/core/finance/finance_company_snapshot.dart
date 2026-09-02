import '/backend/financial_accounting_loader.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Company finance KPI groups (FIN-2) — sales vs realization strictly separated.
class FinanceCompanySnapshot {
  const FinanceCompanySnapshot({
    required this.currency,
    required this.periodLabel,
    required this.totalsSource,
    required this.docsScanned,
    required this.isApproximate,
    // A — النشاط
    required this.totalTrips,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.financiallyIncomplete,
    // B — المبيعات
    required this.completedTripValue,
    required this.collectedTripValue,
    required this.unCollectedTripValue,
    required this.realizedRevenue,
    // C — قنوات الدفع
    required this.cashCompletedPending,
    required this.cashCompletedPendingValue,
    required this.cashCollectedTrips,
    required this.cashCollectedValue,
    required this.onlineCompletedPending,
    required this.onlineCompletedPendingValue,
    required this.onlinePaidTrips,
    required this.onlinePaidValue,
    // D — التوزيع (realized)
    required this.realizedPlatformFee,
    required this.realizedVat,
    required this.realizedDriverNet,
    required this.expectedPlatformAfterCollection,
    required this.expectedDriverNetAfterCollection,
    // E — الذمم (realized positions only)
    required this.companyReceivable,
    required this.companyPayable,
    required this.outstandingReceivable,
    // F — settlements read-only counters
    required this.settledCount,
    required this.pendingSettlementCount,
    required this.outstandingSettlementMinor,
    required this.completedAndCollected,
    required this.completedButNotCollected,
    required this.cancelledOrExpired,
    required this.quality,
  });

  final String currency;
  final String periodLabel;
  final String totalsSource;
  final int docsScanned;
  final bool isApproximate;

  final int totalTrips;
  final int completedTrips;
  final int cancelledTrips;
  final int financiallyIncomplete;

  final MoneyAmount completedTripValue;
  final MoneyAmount collectedTripValue;
  final MoneyAmount unCollectedTripValue;
  final MoneyAmount realizedRevenue;

  final int cashCompletedPending;
  final MoneyAmount cashCompletedPendingValue;
  final int cashCollectedTrips;
  final MoneyAmount cashCollectedValue;
  final int onlineCompletedPending;
  final MoneyAmount onlineCompletedPendingValue;
  final int onlinePaidTrips;
  final MoneyAmount onlinePaidValue;

  final MoneyAmount realizedPlatformFee;
  final MoneyAmount realizedVat;
  final MoneyAmount realizedDriverNet;
  final MoneyAmount expectedPlatformAfterCollection;
  final MoneyAmount expectedDriverNetAfterCollection;

  final MoneyAmount companyReceivable;
  final MoneyAmount companyPayable;
  final MoneyAmount outstandingReceivable;

  final int settledCount;
  final int pendingSettlementCount;
  final int outstandingSettlementMinor;

  final int completedAndCollected;
  final int completedButNotCollected;
  final int cancelledOrExpired;
  final FinancialQualityStats quality;

  static FinanceCompanySnapshot fromReport(
    FinancialReportResult result, {
    required String periodLabel,
    String currency = 'SAR',
    int settledCount = 0,
    int pendingSettlementCount = 0,
    int outstandingSettlementMinor = 0,
  }) {
    final code = result.byCurrency.containsKey(currency)
        ? currency
        : (result.byCurrency.containsKey('SAR')
            ? 'SAR'
            : (result.byCurrency.keys.isEmpty
                ? currency
                : result.byCurrency.keys.first));
    final t = result.byCurrency[code] ??
        FinancialCurrencyTotals(currency: code);

    final completedValue = MoneyAmount(
      currency: code,
      minorUnits: t.completedAndCollectedMinor.minorUnits +
          t.completedButNotCollectedMinor.minorUnits,
    );
    final collected = t.completedAndCollectedMinor;
    final uncollected = t.completedButNotCollectedMinor;
    final realized = t.customerPaidAll;

    return FinanceCompanySnapshot(
      currency: code,
      periodLabel: periodLabel,
      totalsSource: result.totalsSource,
      docsScanned: result.docsScanned,
      isApproximate: result.totalsSource == 'client_full',
      totalTrips: result.quality.totalLines > 0
          ? result.quality.totalLines
          : result.docsScanned,
      completedTrips: t.lifecycleCompleted,
      cancelledTrips: t.lifecycleCancelled + t.lifecycleExpired,
      financiallyIncomplete: result.quality.incomplete,
      completedTripValue: completedValue,
      collectedTripValue: collected,
      unCollectedTripValue: uncollected,
      realizedRevenue: realized,
      cashCompletedPending: t.cashCompletedPending,
      cashCompletedPendingValue: t.cashCompletedPendingMinor,
      cashCollectedTrips: t.cashCollectedTrips,
      cashCollectedValue: t.cashCustomerCollected,
      onlineCompletedPending: t.onlineCompletedPending,
      onlineCompletedPendingValue: t.onlineCompletedPendingMinor,
      onlinePaidTrips: t.onlinePaidTrips,
      onlinePaidValue: t.onlineCustomerPaid,
      realizedPlatformFee: t.platformFeeAll,
      realizedVat: t.recordedVatAll,
      realizedDriverNet: t.driverEntitlementAll,
      expectedPlatformAfterCollection: t.expectedPlatformAfterCollection,
      expectedDriverNetAfterCollection: t.expectedDriverNetAfterCollection,
      companyReceivable: t.cashDriversOweCompany,
      companyPayable: MoneyAmount(
        currency: code,
        minorUnits: t.cashCompanyOwesDrivers.minorUnits +
            t.onlineCompanyOwesDrivers.minorUnits,
      ),
      outstandingReceivable: t.cashDriversOweCompany,
      settledCount: settledCount,
      pendingSettlementCount: pendingSettlementCount,
      outstandingSettlementMinor: outstandingSettlementMinor,
      completedAndCollected: t.completedAndCollected,
      completedButNotCollected: t.completedButNotCollected,
      cancelledOrExpired: t.cancelledOrExpired,
      quality: result.quality,
    );
  }
}
