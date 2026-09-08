/// Pure Admin global-shell rules (testable, no Flutter widgets).
///
/// Phase 1 — presentational / navigation-shell only. No RBAC business changes.
class AdminShellRules {
  AdminShellRules._();

  /// Hide sidebar destination items until auth profile/role is safe to show.
  ///
  /// Prevents unauthorized or wrong-role menu flash during bootstrap.
  static bool shouldHideNavItems({
    required bool loggedIn,
    required bool isRoleResolving,
    required bool hasUserDocument,
  }) {
    if (!loggedIn) return false;
    if (isRoleResolving) return true;
    if (!hasUserDocument) return true;
    return false;
  }

  /// Pages that apply [AdminUi.pagePadding] themselves must disable layout padding.
  static bool layoutShouldPadContent({required bool pageOwnsPadding}) =>
      !pageOwnsPadding;

  /// Compact content max width for the global shell column.
  static double contentMaxWidth(double viewportWidth) {
    if (viewportWidth >= 1600) return 1400;
    if (viewportWidth >= 1280) return 1280;
    return 1200;
  }
}

/// Whether [routeName] should appear active in the admin sidebar for [location].
///
/// Picks the single best match among [pathByName]: exact path equality or
/// `location.endsWith(path)`, preferring the longest matching path. Shorter or
/// unrelated mapped items stay inactive. Unmapped / unmatched locations never
/// activate a tile (avoids Dashboard-style prefix traps and stale name matches).
bool adminSidebarRouteIsActive({
  required String location,
  required String routeName,
  required Map<String, String> pathByName,
}) {
  final loc = location.split('?').first;
  String? bestName;
  var bestLen = -1;
  for (final entry in pathByName.entries) {
    final path = entry.value;
    if (path.isEmpty) continue;
    if (loc != path && !loc.endsWith(path)) continue;
    if (path.length > bestLen) {
      bestLen = path.length;
      bestName = entry.key;
    }
  }
  return bestName == routeName;
}
