import '/core/admin_qa_fixture.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/core/finance/money_amount.dart';
import '/backend/schema/order_record.dart';

/// Explicit country/driver scope for accountant aggregations (F1).
class AccountantFinanceScope {
  const AccountantFinanceScope({
    this.countryPaths = const [],
    this.driverIds = const [],
    this.includeAllCountries = false,
  });

  /// Super Admin: [includeAllCountries] true.
  /// Country Agent: single path in [countryPaths], includeAllCountries false.
  final bool includeAllCountries;
  final List<String> countryPaths;
  final List<String> driverIds;

  bool allowsCountry(String? countryPath) {
    if (includeAllCountries) return true;
    final p = (countryPath ?? '').trim();
    if (p.isEmpty) return false;
    return countryPaths.any((c) => c == p || c.endsWith('/${p.split('/').last}'));
  }

  bool allowsDriver(String? driverId) {
    if (driverIds.isEmpty) return true;
    final id = (driverId ?? '').trim();
    return driverIds.contains(id);
  }
}

/// Deterministic read-only accountant projection (no Firestore writes).
class AccountantFinanceReadModel {
  const AccountantFinanceReadModel({
    required this.completedTripCount,
    required this.completedTripsWithCompleteFinancialData,
    required this.completedTripsWithPartialFinancialData,
    required this.completedTripsWithUnresolvedFinancialData,
    required this.completedGross,
    required this.collectedAmount,
    required this.uncollectedAmount,
    required this.companyCommission,
    required this.vat,
    required this.driverNet,
    required this.companyReceivable,
    required this.driverPayable,
    required this.settledAmount,
    required this.outstandingAmount,
    required this.refundAmount,
    required this.chargebackAmount,
    required this.qaFixturesExcluded,
    required this.unattributedAgentCompleted,
    required this.currency,
    required this.source,
    required this.confidenceNote,
  });

  final int completedTripCount;
  final int completedTripsWithCompleteFinancialData;
  final int completedTripsWithPartialFinancialData;
  final int completedTripsWithUnresolvedFinancialData;

  /// Sum of gross only for COMPLETE financial resolutions on completed trips.
  final MoneyAmount completedGross;
  final MoneyAmount collectedAmount;
  final MoneyAmount uncollectedAmount;
  final MoneyAmount companyCommission;
  final MoneyAmount vat;
  final MoneyAmount driverNet;
  final MoneyAmount companyReceivable;
  final MoneyAmount driverPayable;

  /// Read-only from order settlement_status markers (not ledger mutation).
  final MoneyAmount settledAmount;
  final MoneyAmount outstandingAmount;
  final MoneyAmount refundAmount;
  final MoneyAmount chargebackAmount;

  final int qaFixturesExcluded;
  final int unattributedAgentCompleted;
  final String currency;
  final String source;
  final String confidenceNote;

  static AccountantFinanceReadModel aggregate({
    required Iterable<OrderRecord> orders,
    required AccountantFinanceScope scope,
    required String currency,
  }) {
    final code = CurrencyMoneyPolicy.normalizeCode(currency);
    var completed = 0;
    var completeFin = 0;
    var partialFin = 0;
    var unresolvedFin = 0;
    var fixturesExcluded = 0;
    var unattributed = 0;

    var gross = 0;
    var collected = 0;
    var uncollected = 0;
    var commission = 0;
    var vatSum = 0;
    var driverNetSum = 0;
    var companyRecv = 0;
    var driverPay = 0;
    var settled = 0;
    var outstanding = 0;
    var refunds = 0;
    var chargebacks = 0;

    for (final order in orders) {
      if (AdminQaFixture.isFixtureOrder(order) ||
          FinancialTripSemantics.isFinanceQaFixture(order)) {
        fixturesExcluded++;
        continue;
      }

      final snap = FinancialOrderAdapter.fromOrder(order);
      if (!scope.allowsCountry(snap.countryPath)) continue;
      if (!scope.allowsDriver(snap.driverId)) continue;

      final line = FinancialAccountingEngine.analyze(snap);
      final lineCurrency = CurrencyMoneyPolicy.normalizeCode(line.currency);
      if (lineCurrency != code) continue;

      final pay = FinancialAccountingEngine.normalizedPaymentStatus(snap);
      if (pay == FinancialPaymentState.refunded) {
        final amt = line.customerPaid?.minorUnits ?? line.grossBase?.minorUnits;
        if (amt != null) refunds += amt;
      }

      // Chargebacks: no first-class field in F0 — leave 0 unless explicit marker.
      final cb = (order.snapshotData['chargeback'] == true) ||
          (order.snapshotData['payment_status']?.toString().toLowerCase() ==
              'chargeback');
      if (cb) {
        final amt = line.customerPaid?.minorUnits ?? line.grossBase?.minorUnits;
        if (amt != null) chargebacks += amt;
      }

      final opCompleted =
          FinancialTripSemantics.isOperationallyCompletedSnapshot(snap);
      if (!opCompleted) continue;

      completed++;

      final agentClass = FinancialAgentAttributionResolver.classify(snap);
      if (agentClass == FinancialAgentAttribution.missing) {
        unattributed++;
      }

      final resolution = FinancialAmountResolution.fromLine(line);
      switch (resolution.quality) {
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

      // Money totals: only COMPLETE resolutions contribute amounts (no zero-fill).
      if (resolution.quality != FinancialDataQuality.complete) {
        continue;
      }

      final g = resolution.gross?.minorUnits ?? 0;
      final c = resolution.companyCommission?.minorUnits ?? 0;
      final v = resolution.vat?.minorUnits ?? 0;
      final d = resolution.driverNet?.minorUnits ?? 0;
      gross += g;
      commission += c;
      vatSum += v;
      driverNetSum += d;

      final paid = line.isFinanciallyPaid;
      if (paid) {
        collected += g;
        if (line.channel == FinancialPaymentChannel.cash) {
          companyRecv += line.signedCashPosition?.minorUnits ?? (c + v);
        } else if (line.channel == FinancialPaymentChannel.online) {
          driverPay += d;
        }
      } else {
        uncollected += g;
      }

      if (FinancialTripSemantics.isSettlementCompleteOnOrder(order)) {
        settled += g;
      } else if (paid) {
        outstanding += (line.channel == FinancialPaymentChannel.cash)
            ? (line.signedCashPosition?.minorUnits ?? (c + v)).abs()
            : d;
      }
    }

    MoneyAmount m(int minor) =>
        MoneyAmount(currency: code, minorUnits: minor);

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
      settledAmount: m(settled),
      outstandingAmount: m(outstanding),
      refundAmount: m(refunds),
      chargebackAmount: m(chargebacks),
      qaFixturesExcluded: fixturesExcluded,
      unattributedAgentCompleted: unattributed,
      currency: code,
      source: 'FinancialAccountingEngine+FinancialTripSemantics',
      confidenceNote:
          'Amounts include COMPLETE financial resolutions only; completed trip count includes PARTIAL/UNRESOLVED',
    );
  }
}
