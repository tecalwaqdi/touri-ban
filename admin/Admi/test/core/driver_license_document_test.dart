import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/driver_license_document.dart';
import 'package:admin_arawatan/core/driver_registration_document_status.dart';

void main() {
  group('DriverLicenseDocument', () {
    test('submit requires front and back by default', () {
      final data = <String, dynamic>{
        'doc_driver_license_front': {
          'storagePath': 'users/u/front.jpg',
        },
      };
      expect(DriverLicenseDocument.isCompleteForSubmit(data), isFalse);
      data['doc_driver_license_back'] = {
        'storagePath': 'users/u/back.jpg',
      };
      expect(DriverLicenseDocument.isCompleteForSubmit(data), isTrue);
    });

    test('approved legacy single-image remains complete for status', () {
      final data = <String, dynamic>{
        'registration_status': 'approved',
        'actev_mndob': true,
        'doc_driver_license': {
          'url': 'https://example.com/legacy.jpg',
        },
      };
      expect(DriverLicenseDocument.isApprovedLegacyLicenseOnly(data), isTrue);
      expect(
        DriverRegistrationDocumentStatus.statusForType(data, 'driver_license'),
        DriverRegistrationDocStatus.complete,
      );
    });

    test('legacy-only without approval is missing', () {
      final data = <String, dynamic>{
        'doc_driver_license': {
          'storagePath': 'users/u/lic.jpg',
        },
      };
      expect(
        DriverRegistrationDocumentStatus.statusForType(data, 'driver_license'),
        DriverRegistrationDocStatus.missing,
      );
    });
  });
}
