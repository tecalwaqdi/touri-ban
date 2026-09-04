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
  });
}
