import '/backend/schema/order_record.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_v2_read_projection.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/money_amount.dart';

/// One metric delta between trip-row V2 projection and V2 engine totals.
class FinanceF1V2Mismatch {
  const FinanceF1V2Mismatch({
    required this.metric,
    required this.f1Value,
    required this.v2Value,
    required this.rootCause,
  });

  final String metric;
  final String f1Value;
  final String v2Value;
  final String rootCause;
}

/// Same-order-ID comparison of V2 trip-row projection vs engine aggregate.
class FinanceF1V2ParityResult {
  const FinanceF1V2ParityResult({
    required this.orderIds,
    required this.currency,
    required this.fixturesExcluded,
    required this.f1TripCount,
    required this.v2TripCount,
    required this.f1GrossMinor,
    required this.v2GrossMinor,
    required this.f1PlatformFeeMinor,
    required this.v2PlatformFeeMinor,
    required this.f1VatMinor,
    required this.v2VatMinor,
    required this.f1DriverNetMinor,
    required this.v2DriverNetMinor,
    required this.f1CashMinor,
    required this.v2CashMinor,
    required this.f1OnlineMinor,
    required this.v2OnlineMinor,
    required this.mismatches,
  });

  final List<String> orderIds;
  final String currency;
  final int fixturesExcluded;

  final int f1TripCount;
  final int v2TripCount;

  final int f1GrossMinor;
  final int v2GrossMinor;
  final int f1PlatformFeeMinor;
  final int v2PlatformFeeMinor;
  final int f1VatMinor;
  final int v2VatMinor;
  final int f1DriverNetMinor;
  final int v2DriverNetMinor;
  final int f1CashMinor;
  final int v2CashMinor;
  final int f1OnlineMinor;
  final int v2OnlineMinor;

  final List<FinanceF1V2Mismatch> mismatches;

  bool get matches => mismatches.isEmpty;
}

/// Builds a V2 trip-row ↔ engine aggregate parity report over the same orders.
abstract final class FinanceF1V2Parity {
  FinanceF1V2Parity._();

  static FinanceF1V2ParityResult compareOrders(
    Iterable<OrderRecord> orders, {
    AccountantFinanceScope scope = const AccountantFinanceScope(
      includeAllCountries: true,
    ),
    String currency = 'SAR',
  }) {
    final list = orders.toList(growable: false);
    final ids = <String>[];
    final clean = <OrderRecord>[];
    var fixturesExcluded = 0;

    for (final o in list) {
      ids.add(o.reference.id);
      if (AdminQaFixture.isFixtureOrder(o)) {
        fixturesExcluded++;
        continue;
      }
      clean.add(o);
    }

    final trips = <AccountantTripRow>[];
    for (final o in clean) {
      final snap = FinancialOrderAdapter.fromOrder(o);
      if (!scope.allowsCountry(snap.countryPath)) continue;
      if (!scope.allowsDriver(snap.driverId)) continue;
      final row = AccountantTripRow.fromOrder(o);
      if (!row.operationallyCompleted) continue;
      trips.add(row);
    }

    final rowModel = FinanceV2ReadProjection.fromV2TripRows(
      trips: trips,
      currency: currency,
      fixturesExcluded: fixturesExcluded,
    );

    final lines = <FinancialOrderLine>[];
    var rowCash = 0;
    var rowOnline = 0;
    for (final o in clean) {
      final snap = FinancialOrderAdapter.fromOrder(o);
      if (!scope.allowsCountry(snap.countryPath)) continue;
      if (!scope.allowsDriver(snap.driverId)) continue;
      final line = FinancialAccountingEngine.analyze(snap);
      if (CurrencyMoneyPolicy.normalizeCode(line.currency) !=
          CurrencyMoneyPolicy.normalizeCode(currency)) {
        continue;
      }
      lines.add(line);

      final opCompleted =
          FinancialAccountingEngine.normalizedLifecycleStatus(snap) ==
              FinancialLifecycle.completed;
      if (!opCompleted) continue;
      if (line.confidence == FinancialConfidence.incomplete) continue;
      final g = line.grossBase?.minorUnits ?? 0;
      if (line.isFinanciallyPaid) {
        if (line.channel == FinancialPaymentChannel.cash) {
          rowCash += g;
        } else if (line.channel == FinancialPaymentChannel.online) {
          rowOnline += g;
        }
      }
    }

    final v2map = FinancialAccountingEngine.aggregateByCurrency(lines);
    final v2 = v2map[CurrencyMoneyPolicy.normalizeCode(currency)] ??
        FinancialCurrencyTotals(
          currency: CurrencyMoneyPolicy.normalizeCode(currency),
        );

    final v2Gross = v2.completedAndCollectedMinor.minorUnits +
        v2.completedButNotCollectedMinor.minorUnits;
    final v2Cash = v2.cashCustomerCollected.minorUnits;
    final v2Online = v2.onlineCustomerPaid.minorUnits;

    final mismatches = <FinanceF1V2Mismatch>[];

    void checkInt(String metric, int a, int b, String root) {
      if (a != b) {
        mismatches.add(FinanceF1V2Mismatch(
          metric: metric,
          f1Value: '$a',
          v2Value: '$b',
          rootCause: root,
        ));
      }
    }

    void checkMoney(String metric, int a, int b, String root) {
      if (a != b) {
        mismatches.add(FinanceF1V2Mismatch(
          metric: metric,
          f1Value: MoneyAmount(currency: currency, minorUnits: a).toString(),
          v2Value: MoneyAmount(currency: currency, minorUnits: b).toString(),
          rootCause: root,
        ));
      }
    }

    checkInt(
      'trip_count',
      rowModel.completedTripCount,
      v2.lifecycleCompleted,
      'Trip-row projection counts operationally completed rows; engine uses lifecycleCompleted on all analyzable lines',
    );
    checkMoney(
      'gross',
      rowModel.completedGross.minorUnits,
      v2Gross,
      'Trip rows sum COMPLETE resolutions only; engine completed face value uses collection-bucket customerPaid',
    );
    checkMoney(
      'platform_fee',
      rowModel.companyCommission.minorUnits,
      v2.platformFeeAll.minorUnits,
      'Trip rows: complete completed only; engine: platformFeeAll across economics lines',
    );
    checkMoney(
      'vat',
      rowModel.vat.minorUnits,
      v2.recordedVatAll.minorUnits,
      'Trip rows: complete completed only; engine: recordedVatAll across economics lines',
    );
    checkMoney(
      'driver_net',
      rowModel.driverNet.minorUnits,
      v2.driverEntitlementAll.minorUnits,
      'Trip rows: complete completed only; engine: driverEntitlementAll across economics lines',
    );
    checkMoney(
      'cash',
      rowCash,
      v2Cash,
      'Row cash ≈ paid completed gross on cash channel; engine cashCustomerCollected is qualifiesCollectedCash only',
    );
    checkMoney(
      'online',
      rowOnline,
      v2Online,
      'Row online ≈ paid completed gross on online channel; engine onlineCustomerPaid is qualifies online paid',
    );

    return FinanceF1V2ParityResult(
      orderIds: ids,
      currency: CurrencyMoneyPolicy.normalizeCode(currency),
      fixturesExcluded: fixturesExcluded,
      f1TripCount: rowModel.completedTripCount,
      v2TripCount: v2.lifecycleCompleted,
      f1GrossMinor: rowModel.completedGross.minorUnits,
      v2GrossMinor: v2Gross,
      f1PlatformFeeMinor: rowModel.companyCommission.minorUnits,
      v2PlatformFeeMinor: v2.platformFeeAll.minorUnits,
      f1VatMinor: rowModel.vat.minorUnits,
      v2VatMinor: v2.recordedVatAll.minorUnits,
      f1DriverNetMinor: rowModel.driverNet.minorUnits,
      v2DriverNetMinor: v2.driverEntitlementAll.minorUnits,
      f1CashMinor: rowCash,
      v2CashMinor: v2Cash,
      f1OnlineMinor: rowOnline,
      v2OnlineMinor: v2Online,
      mismatches: mismatches,
    );
  }
}
