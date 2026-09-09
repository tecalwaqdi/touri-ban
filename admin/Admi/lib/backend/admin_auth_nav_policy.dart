/// AUTH-NAV-P0 — pure policy helpers for Admin auth navigation (unit-testable).
///
/// Authentication state tri-state:
/// 1. AUTH_LOADING
/// 2. AUTHENTICATED
/// 3. UNAUTHENTICATED
///
/// Panel home additionally uses [AuthPanelHomeDecision] so a signed-in user
/// never sees the login route during role/claims/bootstrap races.
enum AuthPanelHomeDecision {
  /// Show login — only when Firebase session is confirmed absent.
  login,

  /// Keep branded splash / session shell — role or profile still resolving.
  loading,

  /// Render panel home for the resolved role.
  panel,

  /// Signed-in but no panel role after claims are authoritative.
  unauthorized,
}

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

  /// Decide what `_loginOrPanelHome` / `/` auth stream builders may show.
  ///
  /// AUTH_LOADING / role bootstrap must NEVER map to [AuthPanelHomeDecision.login].
  static AuthPanelHomeDecision decidePanelHome({
    required bool loggedIn,
    required bool firebaseUserPresent,
    required bool hasUserDocument,
    required bool hasPanelAccess,
    required bool isRoleResolving,
    required bool rbacAuthoritative,
    required bool profileHasPanelRole,
  }) {
    // Locale rebuild / token tick can briefly clear AppStateNotifier.user while
    // Firebase Auth still has a session — keep loading, never login.
    if (!loggedIn) {
      return firebaseUserPresent
          ? AuthPanelHomeDecision.loading
          : AuthPanelHomeDecision.login;
    }
    if (!hasUserDocument || isRoleResolving) {
      return AuthPanelHomeDecision.loading;
    }
    if (hasPanelAccess) {
      return AuthPanelHomeDecision.panel;
    }
    // Claims race: profile already says panel role, or claims not final yet.
    if (!rbacAuthoritative || profileHasPanelRole) {
      return AuthPanelHomeDecision.loading;
    }
    return AuthPanelHomeDecision.unauthorized;
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
