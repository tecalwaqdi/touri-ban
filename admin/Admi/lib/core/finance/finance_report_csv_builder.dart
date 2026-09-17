import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/csv_export.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/money_amount.dart';

/// Builds accountant CSV from the **same** canonical snapshot + trip rows
/// shown on Finance Reports / Hub (no independent math).
abstract final class FinanceReportCsvBuilder {
  FinanceReportCsvBuilder._();

  static String build({
    required FinanceCompanySnapshot snapshot,
    required List<AccountantTripRow> trips,
    required String preparedBy,
    required String filters,
  }) {
    final currency = snapshot.currency;
    final kpiRows = [
      ['metric', 'value_minor', 'value_major', 'currency'],
      _kpi('gross_completed', snapshot.completedTripValue, currency),
      _kpi('collected', snapshot.collectedTripValue, currency),
      _kpi('uncollected', snapshot.unCollectedTripValue, currency),
      _kpi('platform_commission', snapshot.realizedPlatformFee, currency),
      _kpi('vat', snapshot.realizedVat, currency),
      _kpi('driver_net', snapshot.realizedDriverNet, currency),
      _kpi('company_receivable', snapshot.companyReceivable, currency),
      [
        'outstanding_settlement_minor',
        snapshot.settlementStatsAvailable
            ? '${snapshot.outstandingSettlementMinor}'
            : '',
        snapshot.settlementStatsAvailable
            ? MoneyAmount(
                currency: currency,
                minorUnits: snapshot.outstandingSettlementMinor,
              ).majorUnits.toString()
            : 'UNAVAILABLE',
        currency,
      ],
      ['completed_trips', '${snapshot.completedTrips}', '', ''],
      ['cash_collected_trips', '${snapshot.cashCollectedTrips}', '', ''],
    ];

    final tripHeader = [
      'order_id',
      'ordered_at',
      'country',
      'driver',
      'agent',
      'currency',
      'payment_channel',
      'payment_status',
      'trip_status',
      'gross',
      'touri_commission',
      'vat',
      'driver_net',
      'agent_share',
      'data_quality',
      'settlement_status',
    ];

    final tripBody = <List<String>>[
      for (final t in trips)
        [
          t.orderId,
          t.orderedAt?.toUtc().toIso8601String() ?? '',
          t.countryLabel,
          t.driverLabel,
          t.agentLabel,
          t.currency,
          t.paymentChannelLabel,
          t.paymentStatusLabel,
          t.tripStatusLabel,
          t.grossDisplay,
          t.companyCommissionDisplay,
          t.vatDisplay,
          t.driverNetDisplay,
          t.agentAmountDisplay,
          t.dataQualityLabel,
          t.settlementStatusLabel,
        ],
    ];

    String table(List<List<String>> rows) => rows
        .map((r) => r.map(financeCsvEscape).join(','))
        .join('\n');

    final body = [
      '# KPI section (canonical FinanceCompanySnapshot)',
      table(kpiRows.map((r) => r.map((c) => '$c').toList()).toList()),
      '',
      '# Trip lines (same rows as on-screen report)',
      table([tripHeader, ...tripBody]),
    ].join('\n');

    return financeCsvDocument(
      preparedBy: preparedBy,
      filters: filters,
      currency: currency,
      body: body,
    );
  }

  static List<String> _kpi(String name, MoneyAmount amount, String currency) {
    return [
      name,
      '${amount.minorUnits}',
      '${amount.majorUnits}',
      currency,
    ];
  }
}
