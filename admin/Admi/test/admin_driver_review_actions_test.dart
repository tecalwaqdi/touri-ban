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
    expect(blockers.any((b) => RegExp(r'[\u0600-\u06FF]').hasMatch(b)), isFalse);
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
}
