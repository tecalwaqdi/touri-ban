import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/dashboard_metric_keys.dart';
import 'package:admin_arawatan/backend/dashboard_stats_loader.dart';

void main() {
  group('buildDashboardStatsFromResultsForTest', () {
    List<int> allPassBase() => [
          128, // attractions
          4, // partners
          10, // countries
          29, // regions
          34, // cities
          1, // agents
          13, // representatives
          28, // app users
          3, // transport companies
          0, // active bookings
          3, // support tickets
        ];

    test('all metrics success — fully reliable', () {
      final stats = buildDashboardStatsFromResultsForTest(
        allPassBase(),
        driversActive: 6,
        driversInactive: 7,
        bookingsTotal: 15,
        bookingsCompleted: 1,
        bookingsCancelled: 7,
        bookingsExpired: 5,
        supportOpenTickets: 1,
      );

      expect(stats.countsReliable, isTrue);
      expect(stats.unreliableMetrics, isEmpty);
      expect(stats.representatives, 13);
      expect(stats.countries, 10);
      expect(stats.attractions, 128);
      expect(stats.activeBookings, 0);
      expect(stats.driversUnknown, 0);
    });

    test('one failed metric does not mark others unreliable', () {
      final base = allPassBase();
      base[0] = -1; // landmarks catalog timeout

      final stats = buildDashboardStatsFromResultsForTest(
        base,
        driversActive: 6,
        driversInactive: 7,
        bookingsTotal: 15,
      );

      expect(stats.countsReliable, isFalse);
      expect(stats.unreliableMetrics, {DashboardMetricKeys.attractions});
      expect(stats.metricReliable(DashboardMetricKeys.representatives), isTrue);
      expect(stats.metricReliable(DashboardMetricKeys.countries), isTrue);
      expect(stats.representatives, 13);
      expect(stats.countries, 10);
      expect(stats.attractions, 0);
    });

    test('failed metric is not confused with reliable zero', () {
      final stats = buildDashboardStatsFromResultsForTest(
        allPassBase(),
        driversActive: 6,
        driversInactive: 7,
      );

      expect(stats.metricReliable(DashboardMetricKeys.activeBookings), isTrue);
      expect(stats.activeBookings, 0);
    });

    test('driversUnknown unreliable when driver split fails', () {
      final stats = buildDashboardStatsFromResultsForTest(
        allPassBase(),
        driversActive: -1,
        driversInactive: 7,
      );

      expect(stats.metricReliable(DashboardMetricKeys.driversActive), isFalse);
      expect(stats.metricReliable(DashboardMetricKeys.driversUnknown), isFalse);
      expect(stats.metricReliable(DashboardMetricKeys.representatives), isTrue);
    });

    test('extended booking lifecycle failure is isolated', () {
      final stats = buildDashboardStatsFromResultsForTest(
        allPassBase(),
        bookingsCompleted: -1,
      );

      expect(
        stats.metricReliable(DashboardMetricKeys.bookingsCompleted),
        isFalse,
      );
      expect(stats.metricReliable(DashboardMetricKeys.bookingsTotal), isTrue);
      expect(stats.bookingsTotal, 0);
    });
  });
}
