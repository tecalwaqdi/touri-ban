/// Pure Dashboard presentation helpers (Phase 2 — testable, no widgets).
class DashboardPresentation {
  DashboardPresentation._();

  /// Canonical Drivers list route (menu SoT). Never legacy AdminDrivers.
  static const String canonicalDriversRoute = 'Admindrever';

  static const _rtlLanguageCodes = {'ar', 'ur', 'fa', 'he'};

  /// Compose hero greeting + display name without treating the line as a
  /// translation lookup key (dynamic `uiTr('$greeting، $name')` never matches).
  static String heroGreetingLine({
    required String greeting,
    required String name,
    required String languageCode,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return greeting;
    final rtl = _rtlLanguageCodes.contains(languageCode.toLowerCase());
    final sep = rtl ? '، ' : ', ';
    return '$greeting$sep$trimmed';
  }

  /// Stable KPI card identity — route is not unique (several driver KPIs
  /// share [canonicalDriversRoute]).
  static String statCardKey({
    required String groupTitle,
    required String metricId,
  }) =>
      '$groupTitle::$metricId';

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
