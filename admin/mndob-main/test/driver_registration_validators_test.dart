import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_phone_number_service.dart';
import 'package:mndob/core/driver_registration_validators.dart';

void main() {
  group('DriverNameValidator', () {
    test('accepts Arabic', () {
      expect(DriverNameValidator.validate('عبد الرحمن').isValid, isTrue);
    });
    test('accepts English with apostrophe', () {
      expect(DriverNameValidator.validate("O'Connor").isValid, isTrue);
    });
    test('accepts Russian', () {
      expect(DriverNameValidator.validate('Осмон').isValid, isTrue);
    });
    test('accepts Kyrgyz style', () {
      expect(DriverNameValidator.validate('Бакыт уулу').isValid, isTrue);
    });
    test('rejects digits', () {
      expect(DriverNameValidator.validate('Ali123').isValid, isFalse);
    });
    test('rejects empty', () {
      expect(DriverNameValidator.validate('   ').isValid, isFalse);
    });
  });

  group('DriverPhoneNumberService countries', () {
    test('SA', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '0512345678', iso2: 'SA'),
        '+966512345678',
      );
    });
    test('KG', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '700123456', iso2: 'KG'),
        '+996700123456',
      );
    });
    test('RU', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '9123456789', iso2: 'RU'),
        '+79123456789',
      );
    });
    test('UZ', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '901234567', iso2: 'UZ'),
        '+998901234567',
      );
    });
    test('Persian digits', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '۰۵۱۲۳۴۵۶۷۸', iso2: 'SA'),
        '+966512345678',
      );
    });
  });

  group('DriverBirthDateValidator', () {
    final now = DateTime(2026, 7, 28);
    test('rejects future', () {
      expect(
        DriverBirthDateValidator.validate(DateTime(2027, 1, 1), now: now)
            .isValid,
        isFalse,
      );
    });
    test('rejects under 18', () {
      expect(
        DriverBirthDateValidator.validate(DateTime(2012, 7, 28), now: now)
            .isValid,
        isFalse,
      );
    });
    test('accepts 25yo', () {
      expect(
        DriverBirthDateValidator.validate(DateTime(2001, 7, 28), now: now)
            .isValid,
        isTrue,
      );
    });
  });

  group('DriverPlateNormalizer', () {
    test('normalizes spaces and case', () {
      expect(DriverPlateNormalizer.normalize(' ab-12 c '), 'AB12C');
    });

    test('accepts long regional / VIN style plates', () {
      expect(
        DriverPlateNormalizer.validate('MROEX19G6C3444849').isValid,
        isTrue,
      );
    });
  });

  group('DriverVehicleYearValidator', () {
    test('parses string and int', () {
      expect(DriverVehicleYearValidator.parse('2020'), 2020);
      expect(DriverVehicleYearValidator.parse(2019), 2019);
    });
    test('rejects future year', () {
      expect(
        DriverVehicleYearValidator.validate(DateTime.now().year + 2).isValid,
        isFalse,
      );
    });
  });

  group('DriverSeatCountValidator', () {
    test('accepts 1-8', () {
      expect(DriverSeatCountValidator.validate(4).isValid, isTrue);
      expect(DriverSeatCountValidator.validate(0).isValid, isFalse);
    });
  });

  group('DriverDocumentValidator', () {
    test('size and url', () {
      expect(DriverDocumentValidator.validateSize(100).isValid, isTrue);
      expect(
        DriverDocumentValidator.validateSize(9 * 1024 * 1024).isValid,
        isFalse,
      );
      expect(
        DriverDocumentValidator.validateUploadedUrl(
          'https://example.com/a.jpg',
        ).isValid,
        isTrue,
      );
    });
  });

  group('DriverLocationValidator', () {
    test('requires country region city and gps', () {
      expect(
        DriverLocationValidator.validate(
          hasSelectedLocation: true,
          hasCountry: true,
          hasRegion: true,
          hasCity: true,
        ).isValid,
        isTrue,
      );
      expect(
        DriverLocationValidator.validate(
          hasSelectedLocation: true,
          hasCountry: true,
          hasRegion: false,
          hasCity: false,
        ).isValid,
        isFalse,
      );
    });
  });

  group('DriverVehicleValidator', () {
    test('accepts complete vehicle', () {
      expect(
        DriverVehicleValidator.validate(
          name: 'Camry',
          year: 2020,
          plate: 'ABC123',
          seats: 4,
          color: 'white',
          hasType: true,
        ).isValid,
        isTrue,
      );
    });
    test('rejects missing type', () {
      expect(
        DriverVehicleValidator.validate(
          name: 'Camry',
          year: 2020,
          plate: 'ABC123',
          seats: 4,
          color: 'white',
          hasType: false,
        ).isValid,
        isFalse,
      );
    });
  });

  group('DriverPhoneValidator', () {
    test('accepts SA', () {
      expect(
        DriverPhoneValidator.validate(raw: '0512345678', iso2: 'SA').isValid,
        isTrue,
      );
    });
  });

  group('DriverEmailValidator', () {
    test('normalizes', () {
      expect(
        DriverEmailValidator.normalize('  Foo@Bar.COM '),
        'foo@bar.com',
      );
    });
  });
}
