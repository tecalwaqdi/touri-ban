import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_account_state_resolver.dart';
import 'package:mndob/core/driver_session_router.dart';

/// Phase 2 router matrix (no Firebase): lifecycle → named destination.
void main() {
  group('Phase2 route matrix', () {
    final cases = <DriverLifecycle, String>{
      DriverLifecycle.loggedOut: DriverSessionRouter.loginRoute,
      DriverLifecycle.loading: DriverSessionRouter.loginRoute,
      DriverLifecycle.incompleteProfile: DriverSessionRouter.registerRoute,
      DriverLifecycle.pendingApproval: DriverSessionRouter.pendingRoute,
      DriverLifecycle.changesRequested: DriverSessionRouter.pendingRoute,
      DriverLifecycle.rejected: DriverSessionRouter.pendingRoute,
      DriverLifecycle.suspended: DriverSessionRouter.pendingRoute,
      DriverLifecycle.activeOffline: DriverSessionRouter.homeRoute,
      DriverLifecycle.activeOnline: DriverSessionRouter.homeRoute,
      DriverLifecycle.onTrip: DriverSessionRouter.acceptedRoute,
    };

    for (final entry in cases.entries) {
      test('${entry.key.name} → ${entry.value}', () {
        expect(
          DriverSessionRouter.namedRouteForLifecycle(entry.key),
          entry.value,
        );
      });
    }

    test('register opens only for incompleteProfile', () {
      expect(
        DriverSessionRouter.opensRegistration(DriverLifecycle.incompleteProfile),
        isTrue,
      );
      expect(
        DriverSessionRouter.opensRegistration(DriverLifecycle.loggedOut),
        isFalse,
      );
      expect(
        DriverSessionRouter.opensRegistration(DriverLifecycle.pendingApproval),
        isFalse,
      );
    });

    test('home shell not for pending/loggedOut', () {
      expect(
        DriverSessionRouter.opensHomeShell(DriverLifecycle.pendingApproval),
        isFalse,
      );
      expect(
        DriverSessionRouter.opensHomeShell(DriverLifecycle.loggedOut),
        isFalse,
      );
      expect(
        DriverSessionRouter.opensHomeShell(DriverLifecycle.activeOnline),
        isTrue,
      );
    });
  });

  group('legacy field conflicts', () {
    test('registration_status rejected wins over actev true', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          actevMndob: true,
          ngl: true,
          registrationStatus: 'rejected',
          displayName: 'X',
          ismndob: true,
        ),
        DriverLifecycle.rejected,
      );
    });

    test('blocked maps to suspended', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          actevMndob: true,
          registrationStatus: 'blocked',
          displayName: 'X',
          ismndob: true,
        ),
        DriverLifecycle.suspended,
      );
    });

    test('activeTrip flag without mndon_newacc still onTrip', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          actevMndob: true,
          ngl: true,
          mndonNewacc: false,
          hasActiveTrip: true,
          displayName: 'X',
          ismndob: true,
        ),
        DriverLifecycle.onTrip,
      );
    });
  });
}
