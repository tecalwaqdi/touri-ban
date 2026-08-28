import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_legacy_field_compat.dart';
import 'package:mndob/core/driver_registration_submission_service.dart';

void main() {
  group('DriverLegacyFieldCompat approval prerequisites', () {
    test('blocks missing village and vehicle; photo/id optional', () {
      final blockers = DriverLegacyFieldCompat.approvalBlockingReasons({
        'registration_status': 'pending_review',
      });
      expect(blockers, contains('village_required'));
      expect(blockers, contains('vehicle_type_required'));
      expect(blockers, isNot(contains('profile_photo_required')));
      expect(blockers, isNot(contains('id_document_required')));
    });

    test('passes when required fields present without docs', () {
      final blockers = DriverLegacyFieldCompat.approvalBlockingReasons({
        'registration_status': 'pending_review',
        'mndob_vill': 'villages/v1',
        'mndob_type_car': 'type/1',
        'photo_url': '',
        'img_id_rksh': '',
        'requested_changes': <dynamic>[],
      });
      expect(blockers, isEmpty);
    });

    test('blocks open requested changes', () {
      final blockers = DriverLegacyFieldCompat.approvalBlockingReasons({
        'registration_status': 'changes_requested',
        'mndob_vill': 'x',
        'mndob_type_car': 'y',
        'requested_changes': [
          {'section': 'docs', 'resolved': false},
        ],
      });
      expect(blockers, contains('open_requested_changes'));
    });
  });

  group('DriverRequestedChange', () {
    test('parses list from map', () {
      final list = DriverRequestedChange.listFrom([
        {
          'section': 'vehicle',
          'adminMessage': 'Fix plate',
          'resolved': false,
        }
      ]);
      expect(list, hasLength(1));
      expect(list.first.section, 'vehicle');
      expect(list.first.adminMessage, 'Fix plate');
    });
  });

  group('DriverRegistrationCompletenessService', () {
    test('anonymous / empty uid blocked', () {
      const model = DriverRegistrationReviewModel(
        uid: '',
        displayName: 'Ali',
        email: 'a@b.com',
        phoneE164: '+966512345678',
        idNumber: '1234567890',
        birthDate: null,
        countryRef: null,
        regionRef: null,
        villageRef: null,
        regionName: '',
        villageName: '',
        vehicleTypeRef: null,
        vehicleTypeText: '',
        vehicleName: '',
        modelYear: '',
        plate: '',
        color: '',
        seats: null,
        photoUrl: '',
        idImageUrl: '',
        carImageUrl: '',
        licenseImageUrl: '',
        location: null,
        isResubmit: false,
        uploadInFlight: false,
      );
      final reasons =
          DriverRegistrationCompletenessService.blockingReasons(model);
      expect(reasons, isNotEmpty);
      expect(reasons.first, 'Please sign in first.');
    });

    test('tour guide requires permit url', () {
      const model = DriverRegistrationReviewModel(
        uid: '',
        displayName: 'Ali',
        email: 'a@b.com',
        phoneE164: '+966512345678',
        idNumber: '1234567890',
        birthDate: null,
        countryRef: null,
        regionRef: null,
        villageRef: null,
        regionName: '',
        villageName: '',
        vehicleTypeRef: null,
        vehicleTypeText: '',
        vehicleName: '',
        modelYear: '',
        plate: '',
        color: '',
        seats: null,
        photoUrl: '',
        idImageUrl: '',
        carImageUrl: '',
        licenseImageUrl: '',
        location: null,
        isResubmit: false,
        uploadInFlight: false,
        isTourGuide: true,
        guidePermitUrl: '',
      );
      final reasons =
          DriverRegistrationCompletenessService.blockingReasons(model);
      expect(reasons, contains('Tour guide permit'));
    });

    test('company affiliation requires company path', () {
      const model = DriverRegistrationReviewModel(
        uid: '',
        displayName: 'Ali',
        email: 'a@b.com',
        phoneE164: '+966512345678',
        idNumber: '1234567890',
        birthDate: null,
        countryRef: null,
        regionRef: null,
        villageRef: null,
        regionName: '',
        villageName: '',
        vehicleTypeRef: null,
        vehicleTypeText: '',
        vehicleName: '',
        modelYear: '',
        plate: '',
        color: '',
        seats: null,
        photoUrl: '',
        idImageUrl: '',
        carImageUrl: '',
        licenseImageUrl: '',
        location: null,
        isResubmit: false,
        uploadInFlight: false,
        affiliationType: 'company',
        companyPath: '',
      );
      final reasons =
          DriverRegistrationCompletenessService.blockingReasons(model);
      expect(reasons, contains('Transport company'));
    });
  });
}
