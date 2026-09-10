import '/core/finance/money_amount.dart';

/// Explicit country/driver scope for accountant aggregations.
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

/// Read-only accountant projection (V2-backed counters for bundle fallback).
///
/// Money KPIs on Hub/Agent/Reports come from [FinanceCompanyService].
/// This model is built via [FinanceV2ReadProjection.fromV2TripRows].
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

  final MoneyAmount completedGross;
  final MoneyAmount collectedAmount;
  final MoneyAmount uncollectedAmount;
  final MoneyAmount companyCommission;
  final MoneyAmount vat;
  final MoneyAmount driverNet;
  final MoneyAmount companyReceivable;
  final MoneyAmount driverPayable;

  /// Legacy field retained for bundle shape — settlement money is ledger SoT.
  final MoneyAmount settledAmount;
  final MoneyAmount outstandingAmount;
  final MoneyAmount refundAmount;
  final MoneyAmount chargebackAmount;

  final int qaFixturesExcluded;
  final int unattributedAgentCompleted;
  final String currency;
  final String source;
  final String confidenceNote;

  static AccountantFinanceReadModel empty(String currency) {
    final code = CurrencyMoneyPolicy.normalizeCode(currency);
    MoneyAmount z() => MoneyAmount.zero(code);
    return AccountantFinanceReadModel(
      completedTripCount: 0,
      completedTripsWithCompleteFinancialData: 0,
      completedTripsWithPartialFinancialData: 0,
      completedTripsWithUnresolvedFinancialData: 0,
      completedGross: z(),
      collectedAmount: z(),
      uncollectedAmount: z(),
      companyCommission: z(),
      vat: z(),
      driverNet: z(),
      companyReceivable: z(),
      driverPayable: z(),
      settledAmount: z(),
      outstandingAmount: z(),
      refundAmount: z(),
      chargebackAmount: z(),
      qaFixturesExcluded: 0,
      unattributedAgentCompleted: 0,
      currency: code,
      source: 'financial_accounting_v2_trip_rows',
      confidenceNote: 'empty',
    );
  }
}
