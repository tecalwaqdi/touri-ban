import '/backend/schema/order_record.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/core/finance/money_amount.dart';

/// Builds [AccountantFinanceReadModel] from V2 trip rows (engine money only).
abstract final class FinanceV2ReadProjection {
  FinanceV2ReadProjection._();

  /// Test / bundle helper: filter fixtures + scope, then project from V2 rows.
  static AccountantFinanceReadModel fromOrders({
    required Iterable<OrderRecord> orders,
    required AccountantFinanceScope scope,
    required String currency,
  }) {
    var fixtures = 0;
    final trips = <AccountantTripRow>[];
    for (final o in orders) {
      if (AdminQaFixture.isFixtureOrder(o)) {
        fixtures++;
        continue;
      }
      final snap = FinancialOrderAdapter.fromOrder(o);
      if (!scope.allowsCountry(snap.countryPath)) continue;
      if (!scope.allowsDriver(snap.driverId)) continue;
      final row = AccountantTripRow.fromOrder(o);
      if (!row.operationallyCompleted) continue;
      trips.add(row);
    }
    return fromV2TripRows(
      trips: trips,
      currency: currency,
      fixturesExcluded: fixtures,
    );
  }

  static AccountantFinanceReadModel fromV2TripRows({
    required List<AccountantTripRow> trips,
    required String currency,
    int fixturesExcluded = 0,
  }) {
    final code = CurrencyMoneyPolicy.normalizeCode(currency);
    var completeFin = 0;
    var partialFin = 0;
    var unresolvedFin = 0;
    var unattributed = 0;
    var completed = 0;

    var gross = 0;
    var collected = 0;
    var uncollected = 0;
    var commission = 0;
    var vatSum = 0;
    var driverNetSum = 0;
    var companyRecv = 0;
    var driverPay = 0;
    var refunds = 0;
    var chargebacks = 0;

    for (final trip in trips) {
      if (!trip.operationallyCompleted) continue;
      completed++;

      switch (trip.dataQuality) {
        case FinancialDataQuality.complete:
          completeFin++;
          break;
        case FinancialDataQuality.partial:
          partialFin++;
          break;
        case FinancialDataQuality.unresolved:
          unresolvedFin++;
          break;
      }

      if (trip.agentAttribution == FinancialAgentAttribution.missing) {
        unattributed++;
      }

      final snap = FinancialOrderAdapter.fromOrder(trip.order);
      final line = FinancialAccountingEngine.analyze(snap);
      final lineCurrency = CurrencyMoneyPolicy.normalizeCode(line.currency);
      if (lineCurrency != code) continue;

      final pay = FinancialAccountingEngine.normalizedPaymentStatus(snap);
      if (pay == FinancialPaymentState.refunded) {
        final amt = line.customerPaid?.minorUnits ?? line.grossBase?.minorUnits;
        if (amt != null) refunds += amt;
      }
      final data = trip.order.snapshotData;
      final cb = (data['chargeback'] == true) ||
          (data['payment_status']?.toString().toLowerCase() == 'chargeback');
      if (cb) {
        final amt = line.customerPaid?.minorUnits ?? line.grossBase?.minorUnits;
        if (amt != null) chargebacks += amt;
      }

      if (trip.dataQuality != FinancialDataQuality.complete) continue;

      final resolution = FinancialAmountResolution.fromLine(line);
      final g = resolution.gross?.minorUnits ?? 0;
      final c = resolution.companyCommission?.minorUnits ?? 0;
      final v = resolution.vat?.minorUnits ?? 0;
      final d = resolution.driverNet?.minorUnits ?? 0;
      gross += g;
      commission += c;
      vatSum += v;
      driverNetSum += d;

      if (line.isFinanciallyPaid) {
        collected += g;
        if (line.channel == FinancialPaymentChannel.cash) {
          companyRecv += line.signedCashPosition?.minorUnits ?? (c + v);
        } else if (line.channel == FinancialPaymentChannel.online) {
          driverPay += d;
        }
      } else {
        uncollected += g;
      }
    }

    MoneyAmount m(int minor) => MoneyAmount(currency: code, minorUnits: minor);

    return AccountantFinanceReadModel(
      completedTripCount: completed,
      completedTripsWithCompleteFinancialData: completeFin,
      completedTripsWithPartialFinancialData: partialFin,
      completedTripsWithUnresolvedFinancialData: unresolvedFin,
      completedGross: m(gross),
      collectedAmount: m(collected),
      uncollectedAmount: m(uncollected),
      companyCommission: m(commission),
      vat: m(vatSum),
      driverNet: m(driverNetSum),
      companyReceivable: m(companyRecv),
      driverPayable: m(driverPay),
      settledAmount: m(0),
      outstandingAmount: m(0),
      refundAmount: m(refunds),
      chargebackAmount: m(chargebacks),
      qaFixturesExcluded: fixturesExcluded,
      unattributedAgentCompleted: unattributed,
      currency: code,
      source: 'financial_accounting_v2_trip_rows',
      confidenceNote:
          'Built from V2 trip rows; Hub/Agent/Reports KPIs use FinanceCompanyService',
    );
  }
}
