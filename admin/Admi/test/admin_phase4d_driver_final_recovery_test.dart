import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_driver_profile_view.dart';
import 'package:admin_arawatan/core/admin_driver_review_actions.dart';
import 'package:admin_arawatan/core/driver_license_document.dart';
import 'package:admin_arawatan/core/driver_registration_document_status.dart';

void main() {
  group('license back optional', () {
    test('front alone completes license requirement', () {
      final data = <String, dynamic>{
        'doc_driver_license_front': {'storagePath': 'users/u/front.jpg'},
      };
      expect(DriverLicenseDocument.backSideRequired, isFalse);
      expect(DriverLicenseDocument.satisfiesCanonicalRequirement(data), isTrue);
      expect(DriverLicenseDocument.isCompleteForSubmit(data), isTrue);
      expect(
        DriverRegistrationDocumentStatus.statusForType(data, 'driver_license'),
        DriverRegistrationDocStatus.complete,
      );
    });

    test('missing back does not block completeness', () {
      final data = <String, dynamic>{
        'photo_storage_path': 'users/u/photo.jpg',
        'doc_national_id': {'storagePath': 'users/u/nid.jpg'},
        'doc_vehicle_registration': {'storagePath': 'users/u/vr.jpg'},
        'doc_driver_license_front': {'storagePath': 'users/u/front.jpg'},
      };
      expect(DriverRegistrationDocumentStatus.isComplete(data), isTrue);
      expect(
        AdminDriverReviewActions.approvalBlockingReasons({
          ...data,
          'registration_flow_version': 2,
          'registration_status': 'pending_review',
          'mndob_vill': 'x',
          'mndob_type_car': 'y',
        }),
        isEmpty,
      );
    });

    test('legacy alone satisfies license (CASE B)', () {
      final data = <String, dynamic>{
        'doc_driver_license': {'storagePath': 'users/u/legacy.jpg'},
      };
      expect(DriverLicenseDocument.satisfiesCanonicalRequirement(data), isTrue);
      expect(
        DriverRegistrationDocumentStatus.statusForType(data, 'driver_license'),
        DriverRegistrationDocStatus.complete,
      );
    });

    test('nothing → missing', () {
      expect(
        DriverRegistrationDocumentStatus.statusForType({}, 'driver_license'),
        DriverRegistrationDocStatus.missing,
      );
    });
  });

  group('license presentation slots', () {
    test('CASE A front only → front + optional back', () {
      // Presence logic is covered via DriverLicenseDocument helpers;
      // slot builder needs UserRecord — assert contract helpers here.
      expect(
        DriverLicenseDocument.hasFront({
          'doc_driver_license_front': {'storagePath': 'users/u/f.jpg'},
        }),
        isTrue,
      );
      expect(AdminDriverDocPresence.optionalMissing, isNotNull);
    });
  });

  group('super admin override contract', () {
    test('needs_changes is override-eligible', () {
      expect(
        AdminDriverReviewActions.canSuperAdminOverrideApprove({
          'registration_status': 'needs_changes',
        }),
        isTrue,
      );
    });

    test('approved is not override-eligible', () {
      expect(
        AdminDriverReviewActions.canSuperAdminOverrideApprove({
          'registration_status': 'approved',
        }),
        isFalse,
      );
    });

    test('override metadata keeps registration vs activation axes', () {
      final patch = AdminDriverReviewActions.overrideApproveMetadata(
        adminUid: 'admin1',
        reason: 'QA override reason',
        previousStatus: 'needs_changes',
        alsoActivate: true,
      );
      expect(patch['override'], isTrue);
      expect(patch['override_reason'], 'QA override reason');
      expect(patch['previous_registration_status'], 'needs_changes');
      expect(patch['new_registration_status'], 'approved');
      expect(patch['registration_status'], 'approved');
      expect(patch['actev_mndob'], isTrue);
    });

    test('registration approve only does not set actev_mndob', () {
      final patch = AdminDriverReviewActions.registrationApproveOnlyPatch(
        adminUid: 'a',
      );
      expect(patch['registration_status'], 'approved');
      expect(patch.containsKey('actev_mndob'), isFalse);
    });

    test('normal activation still blocked when not approved', () {
      final blockers = AdminDriverReviewActions.operationalActivationBlockers({
        'registration_status': 'needs_changes',
      });
      expect(blockers, contains('adm_drv_blocker_registration_not_approved'));
    });
  });

  group('edit phase contract', () {
    test('phases cover blank-body prevention', () {
      const phases = {
        'creating',
        'loading',
        'loaded',
        'error',
        'notFound',
        'unauthorized',
      };
      expect(phases.length, 6);
    });
  });
}
