import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_auth_nav_policy.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/flutter_flow/nav/nav.dart';

void main() {
  group('AUTH-NAV-P0 tri-state', () {
    test('AUTH_LOADING does not redirect to Login', () {
      expect(
        AdminAuthNavPolicy.shouldRedirectRequireAuthToLogin(
          authResolved: false,
          loggedIn: false,
        ),
        isFalse,
      );
    });

    test('definitive unauthenticated redirects to Login', () {
      expect(
        AdminAuthNavPolicy.shouldRedirectRequireAuthToLogin(
          authResolved: true,
          loggedIn: false,
        ),
        isTrue,
      );
    });

    test('authenticated does not redirect to Login', () {
      expect(
        AdminAuthNavPolicy.shouldRedirectRequireAuthToLogin(
          authResolved: true,
          loggedIn: true,
        ),
        isFalse,
      );
    });

    test('AppStateNotifier AUTH_LOADING vs UNAUTHENTICATED', () {
      final n = AppStateNotifier.instance;
      final prevResolved = n.authResolved;
      final prevUser = n.user;
      n.authResolved = false;
      n.user = null;
      expect(n.isAuthLoading, isTrue);
      expect(n.isUnauthenticated, isFalse);
      n.authResolved = true;
      expect(n.isUnauthenticated, isTrue);
      // restore
      n.authResolved = prevResolved;
      n.user = prevUser;
    });
  });

  group('AUTH-NAV-P0 security boundaries', () {
    test('authorization deny does not signOut', () {
      expect(AdminAuthNavPolicy.unauthorizedShouldSignOut(), isFalse);
    });

    test('Firestore errors do not signOut', () {
      expect(AdminAuthNavPolicy.firestoreErrorShouldSignOut(), isFalse);
    });

    test('Global Accountant with null country refs is valid', () {
      expect(
        AdminAuthNavPolicy.isValidGlobalAccountant(
          isAccountant: true,
          hasFinanceClaimOrRule: true,
          countryId: null,
          agentCountryPath: null,
        ),
        isTrue,
      );
    });

    test('normal route claim refresh is soft when claims present', () {
      expect(
        AdminAuthNavPolicy.shouldForceClaimRefreshOnTokenTick(
          hasClaimsPanelAccess: true,
        ),
        isFalse,
      );
    });

    test('idToken null alone does not clear session', () {
      expect(
        AdminAuthNavPolicy.shouldClearSessionOnIdTokenNull(
          idTokenUserNull: true,
          firebaseCurrentUserNull: false,
        ),
        isFalse,
      );
    });

    test('idToken null + no Firebase user clears session', () {
      expect(
        AdminAuthNavPolicy.shouldClearSessionOnIdTokenNull(
          idTokenUserNull: true,
          firebaseCurrentUserNull: true,
        ),
        isTrue,
      );
    });
  });

  group('AUTH-NAV-P0 Accountant routes', () {
    test('finance surfaces remain in accountant allow-list', () {
      const routes = [
        'AdminFinanceHub',
        'AdminFinanceReconciliation',
        'AdminFinanceChannels',
        'AdminSettlements',
        'AdminAgentFinance',
        'AdminFinanceReports',
      ];
      for (final r in routes) {
        expect(
          AdminRoleService.canAccessRouteForRole(AdminRole.accountant, r),
          isTrue,
          reason: r,
        );
      }
    });
  });
}
