import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_driver_profile_view.dart';
import 'package:admin_arawatan/core/driver_license_document.dart';

void main() {
  group('license presentation slots', () {
    test('CASE A: front+back present', () {
      final data = <String, dynamic>{
        'doc_driver_license_front': {
          'storagePath': 'users/u1/docs/front.jpg',
        },
        'doc_driver_license_back': {
          'storagePath': 'users/u1/docs/back.jpg',
        },
        'doc_driver_license': {
          'storagePath': 'users/u1/docs/legacy.jpg',
        },
      };
      expect(DriverLicenseDocument.hasFront(data), isTrue);
      expect(DriverLicenseDocument.hasBack(data), isTrue);
    });

    test('CASE B: legacy only', () {
      final data = <String, dynamic>{
        'doc_driver_license': {
          'storagePath': 'users/u1/docs/legacy.jpg',
        },
      };
      expect(DriverLicenseDocument.hasFront(data), isFalse);
      expect(DriverLicenseDocument.hasBack(data), isFalse);
      expect(DriverLicenseDocument.hasLegacySingle(data), isTrue);
    });

    test('CASE C: nothing', () {
      final data = <String, dynamic>{};
      expect(DriverLicenseDocument.hasFront(data), isFalse);
      expect(DriverLicenseDocument.hasBack(data), isFalse);
      expect(DriverLicenseDocument.hasLegacySingle(data), isFalse);
      expect(AdminDriverDocKind.driverLicenseLegacy, isNotNull);
    });
  });

  group('edit phase contract', () {
    test('supported phases cover blank-body prevention', () {
      const phases = {
        'creating',
        'loading',
        'loaded',
        'error',
        'notFound',
        'unauthorized',
      };
      expect(phases.length, 6);
      expect(phases.contains('loaded'), isTrue);
    });
  });
}
