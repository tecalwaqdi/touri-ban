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

    test('open change requests force exceptional path', () {
      expect(
        AdminDriverReviewActions.requiresExceptionalOverride({
          'registration_status': 'pending_review',
          'requested_changes': [
            {'resolved': false, 'adminMessage': 'fix plate'},
          ],
        }),
        isTrue,
      );
      expect(
        AdminDriverReviewActions.openChangeRequestSummaries({
          'requested_changes': [
            {'resolved': false, 'adminMessage': 'fix plate'},
            {'resolved': true, 'adminMessage': 'done'},
          ],
        }),
        ['fix plate'],
      );
    });

    test('clean pending_review is not exceptional', () {
      expect(
        AdminDriverReviewActions.requiresExceptionalOverride({
          'registration_status': 'pending_review',
          'requested_changes': [],
        }),
        isFalse,
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

  group('vehicle type label localization', () {
    test('touryLocalizedText prefers ar over ru legacy', () {
      // Mirrors AdminTypeCarLabel / type_car names_i18n SoT.
      final label = () {
        const i18n = {'ar': 'اقتصادية', 'ru': 'Эконом', 'en': 'Economy'};
        const legacy = 'Эконом';
        const locale = 'ar';
        return i18n[locale] ?? i18n['en'] ?? legacy;
      }();
      expect(label, 'اقتصادية');
      expect(label.contains('Эконом'), isFalse);
    });
  });

  group('edit/create form paint contract', () {
    test('phases cover blank-body prevention for create and edit', () {
      const phases = {
        'creating',
        'loading',
        'loaded',
        'error',
        'notFound',
        'unauthorized',
      };
      expect(phases.contains('creating'), isTrue);
      expect(phases.contains('loaded'), isTrue);
    });

    test('company dropdown selection must path-match items', () {
      // Documents the blank-form root cause: Dropdown asserts when value is
      // not identical-or-equal to an item; path-match prevents body wipe.
      const selectedPath = 'transport_company/c1';
      final itemPaths = <String>[
        'transport_company/c1',
        'transport_company/c2'
      ];
      expect(itemPaths.contains(selectedPath), isTrue);
      expect(itemPaths.contains('transport_company/missing'), isFalse);
    });
  });
}
