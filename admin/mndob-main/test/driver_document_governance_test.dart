import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_document_expiry_resolver.dart';
import 'package:mndob/core/driver_document_requirements.dart';
import 'package:mndob/core/driver_operational_eligibility_resolver.dart';
import 'package:mndob/core/driver_requirement_effective_state_resolver.dart';

void main() {
  final now = DateTime.utc(2026, 8, 26);

  group('DriverRequirementEffectiveStateResolver', () {
    test('new application is immediately effective', () {
      expect(
        DriverRequirementEffectiveStateResolver.resolve(
          requirementEnabled: true,
          requirementRequired: true,
          effectiveFrom: null,
          gracePeriodDays: null,
          driverApprovedAt: null,
          now: now,
        ),
        DriverRequirementEffectiveState.effective,
      );
    });

    test('existing approved without rollout config = incomplete (no mass-block)', () {
      expect(
        DriverRequirementEffectiveStateResolver.resolve(
          requirementEnabled: true,
          requirementRequired: true,
          effectiveFrom: null,
          gracePeriodDays: null,
          driverApprovedAt: DateTime.utc(2025, 1, 1),
          now: now,
        ),
        DriverRequirementEffectiveState.configurationIncomplete,
      );
      expect(
        DriverRequirementEffectiveStateResolver.mayBlockOperations(
          DriverRequirementEffectiveState.configurationIncomplete,
        ),
        isFalse,
      );
    });

    test('before effectiveFrom = notEffective', () {
      expect(
        DriverRequirementEffectiveStateResolver.resolve(
          requirementEnabled: true,
          requirementRequired: true,
          effectiveFrom: DateTime.utc(2026, 9, 1),
          gracePeriodDays: 14,
          driverApprovedAt: DateTime.utc(2025, 1, 1),
          now: now,
        ),
        DriverRequirementEffectiveState.notEffective,
      );
    });

    test('during grace = gracePeriod', () {
      expect(
        DriverRequirementEffectiveStateResolver.resolve(
          requirementEnabled: true,
          requirementRequired: true,
          effectiveFrom: DateTime.utc(2026, 8, 20),
          gracePeriodDays: 14,
          driverApprovedAt: DateTime.utc(2025, 1, 1),
          now: now,
        ),
        DriverRequirementEffectiveState.gracePeriod,
      );
    });

    test('after grace = effective', () {
      expect(
        DriverRequirementEffectiveStateResolver.resolve(
          requirementEnabled: true,
          requirementRequired: true,
          effectiveFrom: DateTime.utc(2026, 7, 1),
          gracePeriodDays: 14,
          driverApprovedAt: DateTime.utc(2025, 1, 1),
          now: now,
        ),
        DriverRequirementEffectiveState.effective,
      );
    });
  });

  group('DriverDocumentExpiryResolver', () {
    test('not applicable when expiry not required', () {
      expect(
        DriverDocumentExpiryResolver.resolve(
          expiryDate: DateTime.utc(2026, 1, 1),
          expiryRequired: false,
          now: now,
        ),
        DriverDocumentExpiryState.notApplicable,
      );
    });

    test('missing expiry when required', () {
      expect(
        DriverDocumentExpiryResolver.resolve(
          expiryDate: null,
          expiryRequired: true,
          now: now,
        ),
        DriverDocumentExpiryState.missingExpiry,
      );
    });

    test('future valid', () {
      expect(
        DriverDocumentExpiryResolver.resolve(
          expiryDate: DateTime.utc(2026, 12, 1),
          expiryRequired: true,
          warningDays: 30,
          now: now,
        ),
        DriverDocumentExpiryState.valid,
      );
    });

    test('exact warning boundary is expiring soon', () {
      expect(
        DriverDocumentExpiryResolver.resolve(
          expiryDate: DateTime.utc(2026, 9, 25),
          expiryRequired: true,
          warningDays: 30,
          now: now,
        ),
        DriverDocumentExpiryState.expiringSoon,
      );
    });

    test('inside warning window', () {
      expect(
        DriverDocumentExpiryResolver.resolve(
          expiryDate: DateTime.utc(2026, 9, 1),
          expiryRequired: true,
          warningDays: 30,
          now: now,
        ),
        DriverDocumentExpiryState.expiringSoon,
      );
    });

    test('expires today is expiring soon (still valid day)', () {
      expect(
        DriverDocumentExpiryResolver.resolve(
          expiryDate: DateTime.utc(2026, 8, 26),
          expiryRequired: true,
          warningDays: 30,
          now: now,
        ),
        DriverDocumentExpiryState.expiringSoon,
      );
    });

    test('expired yesterday', () {
      expect(
        DriverDocumentExpiryResolver.resolve(
          expiryDate: DateTime.utc(2026, 8, 25),
          expiryRequired: true,
          warningDays: 30,
          now: now,
        ),
        DriverDocumentExpiryState.expired,
      );
    });
  });

  group('DriverOperationalEligibilityResolver', () {
    const license = DriverDocumentRequirement(
      type: 'driverLicense',
      firestoreField: 'doc_driver_license',
      required: true,
      expiryRequired: true,
      operationalBlockingOnExpiry: true,
      expiryWarningDays: 30,
      localizedTitleKey: 'Driver license',
    );

    test('blocks expired critical document', () {
      final r = DriverOperationalEligibilityResolver.evaluate(
        emailVerified: true,
        actevMndob: true,
        suspended: false,
        onActiveTrip: false,
        requirements: const [license],
        userData: {
          'doc_driver_license': {
            'storagePath': 'users/u/uploads/lic.jpg',
            'reviewStatus': 'approved',
            'expiryDate': DateTime.utc(2026, 8, 1),
          },
        },
        now: now,
      );
      expect(r.allowed, isFalse);
      expect(r.reasonCode, 'document_expired');
    });

    test('active trip exception allows expired', () {
      final r = DriverOperationalEligibilityResolver.evaluate(
        emailVerified: true,
        actevMndob: true,
        suspended: false,
        onActiveTrip: true,
        requirements: const [license],
        userData: {
          'doc_driver_license': {
            'storagePath': 'users/u/uploads/lic.jpg',
            'reviewStatus': 'approved',
            'expiryDate': DateTime.utc(2026, 8, 1),
          },
        },
        now: now,
      );
      expect(r.allowed, isTrue);
    });

    test('replacement pending after expiry blocks', () {
      final r = DriverOperationalEligibilityResolver.evaluate(
        emailVerified: true,
        actevMndob: true,
        suspended: false,
        onActiveTrip: false,
        requirements: const [license],
        userData: {
          'doc_driver_license': {
            'storagePath': 'users/u/uploads/lic2.jpg',
            'reviewStatus': 'pending_review',
            'expiryDate': DateTime.utc(2026, 8, 1),
          },
        },
        now: now,
      );
      expect(r.allowed, isFalse);
      expect(r.reasonCode, 'document_expired');
    });

    test('early renewal pending keeps ops when still valid', () {
      final r = DriverOperationalEligibilityResolver.evaluate(
        emailVerified: true,
        actevMndob: true,
        suspended: false,
        onActiveTrip: false,
        requirements: const [license],
        userData: {
          'reviewed_at': DateTime.utc(2025, 1, 1),
          'doc_driver_license': {
            'storagePath': 'users/u/uploads/lic3.jpg',
            'reviewStatus': 'pending_review',
            'expiryDate': DateTime.utc(2026, 12, 1),
          },
        },
        now: now,
      );
      expect(r.allowed, isTrue);
    });

    test('incomplete rollout does not mass-block missing newly required doc', () {
      final insurance = DriverDocumentRequirement(
        type: 'vehicleInsurance',
        firestoreField: 'doc_vehicle_insurance',
        required: true,
        expiryRequired: false,
        localizedTitleKey: 'Insurance',
      );
      final r = DriverOperationalEligibilityResolver.evaluate(
        emailVerified: true,
        actevMndob: true,
        suspended: false,
        onActiveTrip: false,
        requirements: [insurance],
        userData: {
          'reviewed_at': DateTime.utc(2025, 1, 1),
        },
        now: now,
      );
      expect(r.allowed, isTrue);
    });

    test('COUNTRY_CONFIG empty requirements does not invent block', () {
      final r = DriverOperationalEligibilityResolver.evaluate(
        emailVerified: true,
        actevMndob: true,
        suspended: false,
        onActiveTrip: false,
        requirements: const [],
        userData: const {},
        now: now,
      );
      expect(r.allowed, isTrue);
    });
  });

  group('DriverDocumentRequirementResolver', () {
    test('missing config returns empty', () {
      expect(
        DriverDocumentRequirementResolver.resolveFromCountryData(null),
        isEmpty,
      );
      expect(
        DriverDocumentRequirementResolver.hasConfiguredRequirements({}),
        isFalse,
      );
    });

    test('enabled config merges', () {
      final list = DriverDocumentRequirementResolver.resolveFromCountryData({
        'driverLicense': {
          'enabled': true,
          'required': true,
          'expiryRequired': true,
          'operationalBlockingOnExpiry': true,
        },
        'nationalId': {'enabled': false},
      });
      expect(list.any((e) => e.type == 'driverLicense'), isTrue);
      expect(list.any((e) => e.type == 'nationalId'), isFalse);
    });
  });
}
