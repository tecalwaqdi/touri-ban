import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/money_amount.dart';

/// Immutable export payload — numbers copied from canonical UI snapshot only.
class FinanceExportSnapshot {
  const FinanceExportSnapshot({
    required this.generatedAt,
    required this.periodLabel,
    required this.currency,
    required this.filtersSummary,
    required this.company,
    required this.trips,
    required this.localeCode,
  });

  final DateTime generatedAt;
  final String periodLabel;
  final String currency;
  final String filtersSummary;
  final FinanceCompanySnapshot? company;
  final List<AccountantTripRow> trips;
  final String localeCode;

  List<AccountantTripRow> get cashTrips => trips
      .where((t) => t.paymentChannelLabel == 'نقدي')
      .toList(growable: false);

  List<AccountantTripRow> get onlineTrips => trips
      .where((t) => t.paymentChannelLabel == 'إلكتروني')
      .toList(growable: false);

  List<AccountantTripRow> get completeTrips => trips
      .where((t) => t.dataQuality == FinancialDataQuality.complete)
      .toList(growable: false);

  List<AccountantTripRow> get exceptionTrips => trips
      .where((t) => t.dataQuality != FinancialDataQuality.complete)
      .toList(growable: false);

  /// KPI lines for Summary sheet/PDF — from company snapshot when present.
  Map<String, String> summaryLabelsAr() {
    final c = company;
    if (c == null) {
      return {
        'رحلات مكتملة':
            '${trips.where((t) => t.operationallyCompleted).length}',
        'مصدر': 'trip_rows_only',
      };
    }
    String fmt(MoneyAmount m) =>
        '${m.majorUnits.toStringAsFixed(2)} ${m.currency}';
    return {
      'رحلات مكتملة': '${c.completedTrips}',
      'قيمة مكتملة': fmt(c.completedTripValue),
      'محصّل': fmt(c.collectedTripValue),
      'غير محصّل': fmt(c.unCollectedTripValue),
      'عمولة منصة محققة': fmt(c.realizedPlatformFee),
      'ضريبة محققة': fmt(c.realizedVat),
      'صافي مندوبين محقق': fmt(c.realizedDriverNet),
      'نقد محصّل': fmt(c.cashCollectedValue),
      'إلكتروني مدفوع': fmt(c.onlinePaidValue),
      'مستحق للشركة': fmt(c.companyReceivable),
      'مستحق على الشركة': fmt(c.companyPayable),
      'متبقي ذمم': fmt(c.outstandingReceivable),
    };
  }
}
