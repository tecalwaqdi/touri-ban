import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_financial_summary_service.dart';

void main() {
  group('DriverFinancialSummary parsing', () {
    test('50 SAR sample maps fractional fields', () {
      final summary = DriverFinancialSummary.fromResponse({
        'today': {
          'completedTrips': 1,
          'gross': 50.0,
          'platformFee': 7.5,
          'vat': 0.0,
          'driverNet': 42.5,
          'companyDue': 7.5,
        },
        'week': {'driverNet': 42.5},
        'month': {'driverNet': 42.5},
        'lifetime': {'driverNet': 42.5},
        'settlements': {'paid': 0, 'pending': 0, 'outstanding': 7.5},
      });

      expect(summary.today.platformFee, 7.5);
      expect(summary.today.driverNet, 42.5);
      expect(summary.today.driverNetLabel, '42.50');
      expect(summary.settlements.outstanding, 7.5);
    });

    test('cancelled-only payload yields zero today earnings', () {
      final summary = DriverFinancialSummary.fromResponse({
        'today': {'completedTrips': 0, 'driverNet': 0},
        'week': {},
        'month': {},
        'lifetime': {},
        'settlements': {},
      });
      expect(summary.today.completedTrips, 0);
      expect(summary.today.driverNet, 0);
    });
  });
}
