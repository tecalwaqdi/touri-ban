import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_auth_nav_policy.dart';

/// AUTH + locale: changing UI locale must never be modeled as logout.
void main() {
  group('AUTH+LOCALE switch matrix (policy)', () {
    const roles = ['super_admin', 'accountant', 'country_agent'];
    const localeChains = [
      ['ar', 'en', 'ar'],
      ['ar', 'fr', 'en'],
      ['ar', 'ky', 'ru', 'ar'],
    ];

    for (final role in roles) {
      for (final chain in localeChains) {
        test('$role survives locale chain ${chain.join("→")}', () {
          // Locale values are intentionally unused — policy must stay panel/loading
          // for a still-present Firebase session across every hop.
          for (final _locale in chain) {
            expect(
              AdminAuthNavPolicy.decidePanelHome(
                loggedIn: true,
                firebaseUserPresent: true,
                hasUserDocument: true,
                hasPanelAccess: true,
                isRoleResolving: false,
                rbacAuthoritative: true,
                profileHasPanelRole: true,
              ),
              AuthPanelHomeDecision.panel,
              reason: 'role=$role locale=$_locale',
            );
            expect(
              AdminAuthNavPolicy.shouldRedirectRequireAuthToLogin(
                authResolved: true,
                loggedIn: true,
              ),
              isFalse,
            );
            // Mid-rebuild blip: AppState may briefly look logged-out.
            expect(
              AdminAuthNavPolicy.decidePanelHome(
                loggedIn: false,
                firebaseUserPresent: true,
                hasUserDocument: true,
                hasPanelAccess: false,
                isRoleResolving: true,
                rbacAuthoritative: false,
                profileHasPanelRole: true,
              ),
              isNot(AuthPanelHomeDecision.login),
            );
          }
        });
      }
    }
  });
}
