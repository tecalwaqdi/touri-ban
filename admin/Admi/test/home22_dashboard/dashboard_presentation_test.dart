import 'package:admin_arawatan/home22_dashboard/dashboard_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardPresentation', () {
    test('filters and orders quick actions by allow-list', () {
      final routes = DashboardPresentation.filterQuickActionRoutes(
        candidates: const [
          'AdminSuport',
          'AdminaddMkan',
          'Home',
          'AdminFinanceHub',
        ],
        canAccess: (r) => r != 'AdminFinanceHub',
      );
      expect(routes, ['AdminaddMkan', 'AdminSuport']);
    });

    test('driver activation KPIs use canonical Drivers route', () {
      expect(
        DashboardPresentation.routeForDriverActivationKpi(inactiveSplit: true),
        DashboardPresentation.canonicalDriversRoute,
      );
      expect(
        DashboardPresentation.isLegacyDashboardRoute('AdminDrivers'),
        isTrue,
      );
      expect(
        DashboardPresentation.isLegacyDashboardRoute('Admindrever'),
        isFalse,
      );
    });

    test('hero greeting is not used as a translation key', () {
      expect(
        DashboardPresentation.heroGreetingLine(
          greeting: 'Good morning',
          name: 'Ara',
          languageCode: 'en',
        ),
        'Good morning, Ara',
      );
      expect(
        DashboardPresentation.heroGreetingLine(
          greeting: 'صباح الخير',
          name: 'آرا',
          languageCode: 'ar',
        ),
        'صباح الخير، آرا',
      );
      expect(
        DashboardPresentation.heroGreetingLine(
          greeting: 'Good morning',
          name: '  ',
          languageCode: 'en',
        ),
        'Good morning',
      );
    });

    test('stat card keys stay unique when KPIs share a route', () {
      final keys = [
        DashboardPresentation.statCardKey(
          groupTitle: 'Users & operations',
          metricId: 'representatives',
        ),
        DashboardPresentation.statCardKey(
          groupTitle: 'Users & operations',
          metricId: 'driversActive',
        ),
        DashboardPresentation.statCardKey(
          groupTitle: 'Users & operations',
          metricId: 'driversInactive',
        ),
        DashboardPresentation.statCardKey(
          groupTitle: 'Users & operations',
          metricId: 'driversUnknown',
        ),
      ];
      expect(keys.toSet().length, keys.length);
    });
  });
}
