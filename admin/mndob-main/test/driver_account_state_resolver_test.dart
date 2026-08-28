import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_account_state_resolver.dart';
import 'package:mndob/core/driver_session_router.dart';

void main() {
  group('DriverAccountStateResolver', () {
    test('no auth → loggedOut', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: false,
          isAnonymous: false,
          driverDocumentExists: false,
        ),
        DriverLifecycle.loggedOut,
      );
    });

    test('anonymous → loggedOut', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: true,
          driverDocumentExists: false,
        ),
        DriverLifecycle.loggedOut,
      );
    });

    test('auth without document → incompleteProfile', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: false,
        ),
        DriverLifecycle.incompleteProfile,
      );
    });

    test('pending_review → pendingApproval', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          ismndom: true,
          actevMndob: false,
          registrationStatus: 'pending_review',
          displayName: 'Ali',
          hasCar: true,
        ),
        DriverLifecycle.pendingApproval,
      );
    });

    test('changes_requested → changesRequested', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: false,
          registrationStatus: 'changes_requested',
          displayName: 'Ali',
        ),
        DriverLifecycle.changesRequested,
      );
    });

    test('needs_changes → changesRequested', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: false,
          registrationStatus: 'needs_changes',
          displayName: 'Ali',
        ),
        DriverLifecycle.changesRequested,
      );
    });

    test('draft → incompleteProfile', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: false,
          registrationStatus: 'draft',
          displayName: 'Ali',
          hasCar: true,
        ),
        DriverLifecycle.incompleteProfile,
      );
    });

    test('rejected beats pending flags', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: false,
          registrationStatus: 'rejected',
          displayName: 'Ali',
        ),
        DriverLifecycle.rejected,
      );
    });

    test('suspended beats active', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: true,
          ngl: true,
          registrationStatus: 'suspended',
          displayName: 'Ali',
        ),
        DriverLifecycle.suspended,
      );
    });

    test('registration_status approved without actev → pendingApproval', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: false,
          registrationStatus: 'approved',
          displayName: 'Ali',
          hasCar: true,
        ),
        DriverLifecycle.pendingApproval,
      );
    });

    test('approved offline', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: true,
          ngl: false,
          displayName: 'Ali',
        ),
        DriverLifecycle.activeOffline,
      );
    });

    test('approved online', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: true,
          ngl: true,
          displayName: 'Ali',
        ),
        DriverLifecycle.activeOnline,
      );
    });

    test('onTrip beats online', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          ismndob: true,
          actevMndob: true,
          ngl: true,
          mndonNewacc: true,
          displayName: 'Ali',
        ),
        DriverLifecycle.onTrip,
      );
    });

    test('incomplete when empty profile', () {
      expect(
        DriverAccountStateResolver.resolveFromLegacyFields(
          hasAuthUser: true,
          isAnonymous: false,
          driverDocumentExists: true,
          actevMndob: false,
          displayName: '',
        ),
        DriverLifecycle.incompleteProfile,
      );
    });
  });

  group('DriverSessionRouter', () {
    test('pending → pending route', () {
      expect(
        DriverSessionRouter.namedRouteForLifecycle(
          DriverLifecycle.pendingApproval,
        ),
        DriverSessionRouter.pendingRoute,
      );
    });

    test('incomplete → register', () {
      expect(
        DriverSessionRouter.namedRouteForLifecycle(
          DriverLifecycle.incompleteProfile,
        ),
        DriverSessionRouter.registerRoute,
      );
    });

    test('loggedOut → login', () {
      expect(
        DriverSessionRouter.namedRouteForLifecycle(DriverLifecycle.loggedOut),
        DriverSessionRouter.loginRoute,
      );
    });

    test('active → home', () {
      expect(
        DriverSessionRouter.namedRouteForLifecycle(
          DriverLifecycle.activeOffline,
        ),
        DriverSessionRouter.homeRoute,
      );
    });
  });
}
