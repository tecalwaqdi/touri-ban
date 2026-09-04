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
