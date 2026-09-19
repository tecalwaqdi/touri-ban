import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_registration_profile_loader.dart';
import 'package:mndob/core/driver_registration_submission_service.dart';

void main() {
  group('DriverRegistrationProfileLoader', () {
    test('prefills vehicle, docs, and expiry from existing user map', () {
      final snap = DriverRegistrationProfileLoader.fromUserData({
        'display_name': 'Ahmed Driver',
        'ID_hoyh_MNDOB': '1234567890',
        'email': 'ahmed@test.com',
        'phone_number': '+966500000000',
        'NameCar': 'Camry',
        'ModelCar': '2020',
        'number_lohh_car': 'ABC1234',
        'vehicle_color': 'White',
        'seat_count': 4,
        'doc_driver_license_front': {
          'documentType': 'driver_license',
          'side': 'front',
          'storagePath': 'users/u1/license-front.jpg',
          'expiryDate': DateTime.utc(2027, 5, 1),
        },
        'doc_driver_license_back': {
          'documentType': 'driver_license',
          'side': 'back',
          'storagePath': 'users/u1/license-back.jpg',
        },
        'doc_vehicle_registration': {
          'documentType': 'vehicle_registration',
          'storagePath': 'users/u1/reg.jpg',
          'expiryDate': DateTime.utc(2026, 12, 15),
        },
        'doc_national_id': {
          'documentType': 'national_id',
          'storagePath': 'users/u1/id.jpg',
        },
        'photo_storage_path': 'users/u1/photo.jpg',
      });

      expect(snap.displayName, 'Ahmed Driver');
      expect(snap.vehicleName, 'Camry');
      expect(snap.modelYear, '2020');
      expect(snap.plate, 'ABC1234');
      expect(snap.licenseFrontStoragePath, 'users/u1/license-front.jpg');
      expect(snap.licenseBackStoragePath, 'users/u1/license-back.jpg');
      expect(snap.vehicleRegStoragePath, 'users/u1/reg.jpg');
      expect(
        snap.licenseFrontUrl,
        DriverRegistrationProfileLoader.existingAssetMarker,
      );
      expect(
        snap.licenseBackUrl,
        DriverRegistrationProfileLoader.existingAssetMarker,
      );
      expect(snap.licenseExpiry?.year, 2027);
      expect(snap.vehicleRegExpiry?.month, 12);
    });
  });

  group('DriverRegistrationSubmissionService update helpers', () {
    test('buildDocSlotUpdate keeps existing asset and sets expiry', () {
      final slot = DriverRegistrationSubmissionService.buildDocSlotUpdate(
        documentType: 'driver_license',
        existing: {
          'documentType': 'driver_license',
          'storagePath': 'users/u1/license.jpg',
          'status': 'uploaded',
        },
        expiryDate: DateTime(2028, 1, 10),
      );
      expect(slot['storagePath'], 'users/u1/license.jpg');
      expect(slot['documentType'], 'driver_license');
      expect(slot['expiryDate'], isNotNull);
    });

    test('protected update keys include approval and wallet fields', () {
      expect(
        DriverRegistrationSubmissionService.protectedUpdateKeys.contains(
          'registration_status',
        ),
        isTrue,
      );
      expect(
        DriverRegistrationSubmissionService.protectedUpdateKeys.contains(
          'actev_mndob',
        ),
        isTrue,
      );
      expect(
        DriverRegistrationSubmissionService.protectedUpdateKeys.contains(
          'wallet',
        ),
        isTrue,
      );
    });
  });
}
