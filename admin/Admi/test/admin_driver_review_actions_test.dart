import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_driver_review_actions.dart';

void main() {
  test('approvalBlockingReasons returns l10n keys not Arabic', () {
    final blockers = AdminDriverReviewActions.approvalBlockingReasons({
      'registration_status': 'suspended',
      'mndob_vill': null,
      'mndob_type_car': null,
      'photo_url': 'not-a-url',
      'img_id_rksh': '',
      'requested_changes': [
        {'resolved': false, 'adminMessage': 'fix docs'},
      ],
    });

    expect(blockers, contains('adm_drv_blocker_suspended'));
    expect(blockers, contains('adm_drv_blocker_work_area'));
    expect(blockers, contains('adm_drv_blocker_vehicle_type'));
    expect(blockers, isNot(contains('adm_drv_blocker_photo')));
    expect(blockers, isNot(contains('adm_drv_blocker_id_doc')));
    expect(blockers, contains('adm_drv_blocker_open_changes'));
    expect(
        blockers.any((b) => RegExp(r'[\u0600-\u06FF]').hasMatch(b)), isFalse);
  });

  test('approvalBlockingReasons empty when prerequisites met without docs', () {
    final blockers = AdminDriverReviewActions.approvalBlockingReasons({
      'registration_status': 'pending',
      'mndob_vill': 'cities/x',
      'mndob_type_car': 'type_car/y',
      'photo_url': '',
      'img_id_rksh': '',
      'requested_changes': [
        {'resolved': true},
      ],
    });
    expect(blockers, isEmpty);
  });

  test('V2 approval requires profile photo and required docs', () {
    final blockers = AdminDriverReviewActions.approvalBlockingReasons({
      'registration_status': 'pending_review',
      'registration_flow_version': 2,
      'mndob_vill': 'cities/x',
      'mndob_type_car': 'type_car/y',
      'photo_storage_path': '',
      'photo_url': '',
      'doc_national_id': {'storagePath': 'users/u/id.jpg'},
      'doc_vehicle_registration': {'storagePath': 'users/u/reg.jpg'},
      'doc_driver_license_front': {'storagePath': 'users/u/front.jpg'},
      'doc_driver_license_back': {'storagePath': 'users/u/back.jpg'},
    });
    expect(blockers, contains('adm_drv_blocker_photo'));
    expect(blockers, isNot(contains('adm_drv_blocker_national_id')));
    expect(blockers, isNot(contains('adm_drv_blocker_driver_license')));
  });
}
