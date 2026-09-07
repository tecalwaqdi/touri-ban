/// Pure Dashboard presentation helpers (Phase 2 — testable, no widgets).
class DashboardPresentation {
  DashboardPresentation._();

  /// Canonical Drivers list route (menu SoT). Never legacy AdminDrivers.
  static const String canonicalDriversRoute = 'Admindrever';

  /// Routes allowed as Dashboard quick actions (must still pass canAccess).
  static const List<String> quickActionRouteOrder = [
    'AdminaddMkan',
    'AdminAddAgent',
    'AdminALLhgZ',
    'AdminFinanceHub',
    'AdminAgentFinance',
    'AdminProfits',
    'AdminTourGuides',
    'AdminSuport',
  ];

  /// Filter + order quick actions by canonical list and role allow-list.
  static List<String> filterQuickActionRoutes({
    required Iterable<String> candidates,
    required bool Function(String route) canAccess,
  }) {
    final allowed = <String>{};
    for (final r in candidates) {
      if (canAccess(r)) allowed.add(r);
    }
    return [
      for (final r in quickActionRouteOrder)
        if (allowed.contains(r)) r,
    ];
  }

  /// Map a KPI identity to its navigation target.
  static String routeForDriverActivationKpi({required bool inactiveSplit}) {
    // Both active and inactive belong on the canonical Drivers list.
    return canonicalDriversRoute;
  }

  static bool isLegacyDashboardRoute(String routeName) {
    return routeName == 'AdminHome' ||
        routeName == 'Home' ||
        routeName == 'home3' ||
        routeName == 'AdminDrivers';
  }
}
