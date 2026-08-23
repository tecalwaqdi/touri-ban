/// Local-only visual fixtures for Settlement Details (Phase 8E).
/// Never written to Firestore. IDs: fixture_locked | fixture_partially_paid | fixture_settled
abstract final class SettlementVisualFixture {
  SettlementVisualFixture._();

  static bool isFixtureId(String? id) =>
      id != null && id.startsWith('fixture_');

  static Map<String, dynamic>? dataFor(String id) {
    switch (id) {
      case 'fixture_locked':
        return _base(
          status: 'locked',
          paidMinor: 0,
          outstandingMinor: 80400,
        );
      case 'fixture_partially_paid':
        return _base(
          status: 'partially_paid',
          paidMinor: 50000,
          outstandingMinor: 30400,
        );
      case 'fixture_settled':
        return _base(
          status: 'settled',
          paidMinor: 80400,
          outstandingMinor: 0,
        );
      default:
        return null;
    }
  }

  static Map<String, dynamic> _base({
    required String status,
    required int paidMinor,
    required int outstandingMinor,
  }) {
    return {
      'settlementCode': 'FIX-8E-804',
      'status': status,
      'driverId': 'fixture_driver',
      'countryId': 'countries/sa',
      'currency': 'SAR',
      'direction': 'DRIVER_PAYS_COMPANY',
      'periodStart': '2026-08-01',
      'periodEnd': '2026-08-31',
      'eligibleTripCount': 5,
      'derivedCount': 0,
      'driverCashLiabilityMinor': 80400,
      'companyOnlineLiabilityMinor': 0,
      'netTripPositionMinor': 80400,
      'absoluteSettlementAmountMinor': 80400,
      'amountDueMinor': 80400,
      'paidMinor': paidMinor,
      'outstandingMinor': outstandingMinor,
      'fixture': true,
    };
  }
}
