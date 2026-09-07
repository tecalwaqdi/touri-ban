/// AUTH-NAV-P0 — pure policy helpers for Admin auth navigation (unit-testable).
///
/// Authentication state tri-state:
/// 1. AUTH_LOADING
/// 2. AUTHENTICATED
/// 3. UNAUTHENTICATED
abstract final class AdminAuthNavPolicy {
  AdminAuthNavPolicy._();

  /// requireAuth routes redirect to Login only after definitive unauthenticated.
  static bool shouldRedirectRequireAuthToLogin({
    required bool authResolved,
    required bool loggedIn,
  }) {
    if (!authResolved) return false; // AUTH_LOADING
    return !loggedIn; // UNAUTHENTICATED
  }

  /// Authorization deny must never be treated as logout.
  static bool unauthorizedShouldSignOut() => false;

  /// Firestore permission / index / network errors must not sign out.
  static bool firestoreErrorShouldSignOut() => false;

  /// Global Accountant with no country / agent refs is a valid session.
  static bool isValidGlobalAccountant({
    required bool isAccountant,
    required bool hasFinanceClaimOrRule,
    String? countryId,
    String? agentCountryPath,
  }) {
    if (!isAccountant && !hasFinanceClaimOrRule) return false;
    // country/agent refs may be null — still valid.
    return true;
  }

  /// Claim soft-refresh on natural token ticks should not force every route.
  static bool shouldForceClaimRefreshOnTokenTick({
    required bool hasClaimsPanelAccess,
  }) =>
      !hasClaimsPanelAccess;

  /// Clear AuthClaims / role session only on definitive Firebase sign-out.
  static bool shouldClearSessionOnIdTokenNull({
    required bool idTokenUserNull,
    required bool firebaseCurrentUserNull,
  }) =>
      idTokenUserNull && firebaseCurrentUserNull;
}
