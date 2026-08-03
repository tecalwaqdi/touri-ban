import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_eligibility_service.dart';
import 'package:mndob/core/driver_account_state_resolver.dart';
import 'package:mndob/core/driver_legacy_field_compat.dart';

void main() {
  group('DriverEligibilityReason', () {
    test('covers workstream D codes', () {
      expect(
        DriverEligibilityReason.values.map((e) => e.name),
        containsAll([
          'eligible',
          'accountPending',
          'accountRejected',
          'accountSuspended',
          'accountBlocked',
          'profileIncomplete',
          'vehicleIncomplete',
          'documentsIncomplete',
          'gpsDisabled',
          'permissionDenied',
          'activeTripExists',
          'offline',
        ]),
      );
    });
  });

  group('DriverLegacyFieldCompat + eligibility coupling', () {
    test('approved lifecycle is operational', () {
      expect(
        DriverLegacyFieldCompat.isOperationallyApproved(
          DriverLifecycle.activeOffline,
        ),
        isTrue,
      );
      expect(
        DriverLegacyFieldCompat.isOperationallyApproved(
          DriverLifecycle.pendingApproval,
        ),
        isFalse,
      );
    });
  });

  group('DriverEligibilityResult', () {
    test('eligible flag', () {
      expect(
        const DriverEligibilityResult(
          reason: DriverEligibilityReason.eligible,
        ).isEligible,
        isTrue,
      );
      expect(
        const DriverEligibilityResult(
          reason: DriverEligibilityReason.gpsDisabled,
          messageKey: 'Turn on GPS to go online.',
        ).isEligible,
        isFalse,
      );
    });
  });
}
