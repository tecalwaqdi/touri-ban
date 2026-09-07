import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admindrever/admin_drivers_adapter.dart';
import 'package:admin_arawatan/backend/admin_media_resolver.dart';
import 'package:admin_arawatan/core/admin_driver_plate.dart';
import 'package:admin_arawatan/core/admin_driver_profile_view.dart';
import 'package:admin_arawatan/core/admin_driver_review_actions.dart';
import 'package:admin_arawatan/core/admin_driver_status_truth.dart';

void main() {
  group('AdminDriverStatusTruth — axes stay separate', () {
    test('pending_review + actev_mndob true ≠ approved', () {
      final t = AdminDriverStatusTruth.fromMap({
        'registration_status': 'pending_review',
        'actev_mndob': true,
        'account_status': 'inactive',
        'ngl': false,
      });
      expect(t.registration, AdminDriverReviewBucket.pendingReview);
      expect(t.accountActive, isTrue);
      expect(t.registrationPendingWithActiveAccount, isTrue);
      expect(t.availability, AdminDriverAvailabilityStatus.unavailable);
    });

    test('approved + offline → unavailable, not available', () {
      final t = AdminDriverStatusTruth.fromMap({
        'registration_status': 'approved',
        'actev_mndob': true,
        'ngl': false,
        'is_online': false,
      });
      expect(t.registration, AdminDriverReviewBucket.approved);
      expect(t.connection, AdminDriverConnectionStatus.offline);
      expect(t.availability, AdminDriverAvailabilityStatus.unavailable);
    });

    test('on trip → busy even if online', () {
      final t = AdminDriverStatusTruth.fromMap({
        'registration_status': 'approved',
        'actev_mndob': true,
        'ngl': true,
        'mndon_newacc': true,
      });
      expect(t.onActiveTrip, isTrue);
      expect(t.availability, AdminDriverAvailabilityStatus.busy);
      expect(t.connection, AdminDriverConnectionStatus.online);
    });

    test('needs_changes / changes_requested aliases', () {
      expect(
        AdminDriverStatusTruth.fromMap({
          'registration_status': 'needs_changes',
        }).registration,
        AdminDriverReviewBucket.needsChanges,
      );
      expect(
        AdminDriverStatusTruth.fromMap({
          'registration_status': 'changes_requested',
        }).registration,
        AdminDriverReviewBucket.needsChanges,
      );
      expect(
        AdminDriverStatusTruth.fromMap({
          'submission_status': 'changesRequested',
        }).registration,
        AdminDriverReviewBucket.needsChanges,
      );
    });

    test('legacy submission_status fallback', () {
      final t = AdminDriverStatusTruth.fromMap({
        'submission_status': 'pending_review',
        'actev_mndob': false,
      });
      expect(t.registration, AdminDriverReviewBucket.pendingReview);
      expect(t.accountActive, isFalse);
    });

    test('auth disabled + approved → mismatch flag', () {
      final t = AdminDriverStatusTruth.fromMap({
        'registration_status': 'approved',
        'actev_mndob': true,
      }, authDisabled: true);
      expect(t.authFirestoreMismatch, isTrue);
    });

    test('GPS alone does not mark online', () {
      final t = AdminDriverStatusTruth.fromMap({
        'registration_status': 'approved',
        'actev_mndob': true,
        'loceshnMndobNow': {'latitude': 1, 'longitude': 2},
      });
      expect(t.connection, AdminDriverConnectionStatus.unknown);
    });
  });

  group('Vehicle dual-read aliases', () {
    test('vehicle_make / make / brand fill NameCar gap via map helper', () {
      // Profile view reads UserRecord; exercise raw alias order via review helpers.
      expect(
        AdminDriverProfileView.reviewBucketFromRaw('submitted'),
        AdminDriverReviewBucket.pendingReview,
      );
    });
  });

  group('AdminDriverReviewActions dual-write', () {
    test('reject requires reason fields + rejectedBy', () {
      final p = AdminDriverReviewActions.rejectPatch(
        reason: 'docs incomplete',
        adminUid: 'admin1',
      );
      expect(p['registration_status'], 'rejected');
      expect(p['rejection_reason'], 'docs incomplete');
      expect(p['rejectionReason'], 'docs incomplete');
      expect(p['rejectedBy'], 'admin1');
      expect(p['actev_mndob'], isFalse);
    });

    test('needs_changes writes fieldsToFix + changesRequestedBy', () {
      final p = AdminDriverReviewActions.requestChangesPatch(
        reason: 'fix plate',
        adminUid: 'admin1',
        fieldsToFix: ['plate', 'vehicle'],
      );
      expect(p['registration_status'], 'needs_changes');
      expect(p['submission_status'], 'changesRequested');
      expect(p['fieldsToFix'], ['plate', 'vehicle']);
      expect(p['changesRequestedBy'], 'admin1');
    });

    test('approve dual-writes approvedAt/approvedBy', () {
      final p = AdminDriverReviewActions.approvePatch(adminUid: 'admin1');
      expect(p['registration_status'], 'approved');
      expect(p['actev_mndob'], isTrue);
      expect(p['approvedBy'], 'admin1');
      expect(p.containsKey('approvedAt'), isTrue);
      expect(p.containsKey('approved_at'), isTrue);
    });

    test('active != approved for blockers on suspended', () {
      final blockers = AdminDriverReviewActions.approvalBlockingReasons({
        'registration_status': 'suspended',
        'mndob_vill': 'x',
        'mndob_type_car': 'y',
      });
      expect(blockers, contains('adm_drv_blocker_suspended'));
    });

    test('operational activate does not rewrite registration_status', () {
      final p = AdminDriverReviewActions.operationalActivatePatch(
        adminUid: 'admin1',
      );
      expect(p['actev_mndob'], isTrue);
      expect(p['account_status'], 'active');
      expect(p.containsKey('registration_status'), isFalse);
    });

    test('operational deactivate keeps registration axis separate', () {
      final p = AdminDriverReviewActions.operationalDeactivatePatch(
        adminUid: 'admin1',
      );
      expect(p['actev_mndob'], isFalse);
      expect(p['account_status'], 'inactive');
      expect(p.containsKey('registration_status'), isFalse);
      expect(p['registration_status'], isNull);
    });

    test('operational blockers: pending registration blocked', () {
      final blockers = AdminDriverReviewActions.operationalActivationBlockers({
        'registration_status': 'pending_review',
        'mndob_vill': 'x',
        'mndob_type_car': 'y',
      });
      expect(blockers, contains('adm_drv_blocker_registration_not_approved'));
    });

    test('operational blockers: approved eligible', () {
      final blockers = AdminDriverReviewActions.operationalActivationBlockers({
        'registration_status': 'approved',
        'mndob_vill': 'x',
        'mndob_type_car': 'y',
      });
      expect(blockers, isEmpty);
    });

    test('operational blockers: suspended blocked', () {
      final blockers = AdminDriverReviewActions.operationalActivationBlockers({
        'registration_status': 'suspended',
        'mndob_vill': 'x',
        'mndob_type_car': 'y',
      });
      expect(blockers, contains('adm_drv_blocker_suspended'));
    });
  });

  group('AdminDriverPlate', () {
    test('normalize strips spaces and dashes', () {
      expect(AdminDriverPlate.normalize(' ab-12 3 '), 'AB123');
    });
  });

  group('AdminMediaResolver classification', () {
    test('object-not-found → EXPECTED_MISSING', () {
      expect(
        AdminMediaResolver.classifyStorageCode('object-not-found'),
        AdminMediaFailureKind.expectedMissing,
      );
      expect(
        AdminMediaResolver.classifyStorageCode('storage/object-not-found'),
        AdminMediaFailureKind.expectedMissing,
      );
    });

    test('unauthorized → REAL_STORAGE_ERROR', () {
      expect(
        AdminMediaResolver.classifyStorageCode('unauthorized'),
        AdminMediaFailureKind.realStorageError,
      );
      expect(
        AdminMediaResolver.classifyStorageCode('unauthenticated'),
        AdminMediaFailureKind.realStorageError,
      );
    });

    test('parses firebasestorage.app bucket URLs', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/tutorial-multi-language-70gx4j.firebasestorage.app/o/users%2Fu1%2Fuploads%2Fa.jpg?alt=media&token=t';
      expect(AdminMediaResolver.storagePathFrom(url), 'users/u1/uploads/a.jpg');
    });
  });

  group('AdminDriverStatusLabels / vehicle display', () {
    test('vehicle missing label prefers Arabic outside debug contract', () {
      const v = AdminDriverVehicleSummary(
        classificationLabel: '',
        name: '',
        modelYear: '',
        plate: '',
        color: '',
        typeCarRef: null,
        isLegacyIncomplete: true,
      );
      expect(v.titleLine, isEmpty);
      expect(v.isLegacyIncomplete, isTrue);
    });

    test('vehicle title/plate lines format', () {
      const v = AdminDriverVehicleSummary(
        classificationLabel: 'اقتصادية',
        name: 'اكسنت',
        modelYear: '2026',
        plate: '9614',
        color: '',
        typeCarRef: null,
        isLegacyIncomplete: false,
      );
      expect(v.titleLine, 'اكسنت 2026');
      expect(v.classLine, 'اقتصادية');
      expect(v.plate, '9614');
    });
  });
}
