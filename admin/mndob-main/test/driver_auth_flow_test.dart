import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_auth_errors.dart';
import 'package:mndob/core/driver_phone_number_service.dart';

void main() {
  group('DriverPhoneNumberService', () {
    test('normalizes Saudi local and E.164 forms', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '0512345678', iso2: 'SA'),
        '+966512345678',
      );
      expect(
        DriverPhoneNumberService.toE164(raw: '512345678', iso2: 'SA'),
        '+966512345678',
      );
      expect(
        DriverPhoneNumberService.toE164(raw: '+966 51 234 5678', iso2: 'SA'),
        '+966512345678',
      );
      expect(
        DriverPhoneNumberService.toE164(raw: '٠٥١٢٣٤٥٦٧٨', iso2: 'SA'),
        '+966512345678',
      );
    });

    test('normalizes Kyrgyzstan numbers', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '700123456', iso2: 'KG'),
        '+996700123456',
      );
      expect(
        DriverPhoneNumberService.toE164(raw: '+996700123456', iso2: 'KG'),
        '+996700123456',
      );
    });

    test('rejects invalid Saudi mobile prefix', () {
      expect(
        DriverPhoneNumberService.toE164(raw: '0123456789', iso2: 'SA'),
        isNull,
      );
    });
  });

  group('DriverAuthErrors', () {
    test('maps known Firebase codes', () {
      expect(
        DriverAuthErrors.messageKeyForCode('wrong-password'),
        'Incorrect email or password.',
      );
      expect(
        DriverAuthErrors.messageKeyForCode('network-request-failed'),
        'No internet connection.',
      );
      expect(
        DriverAuthErrors.messageKeyForCode('email-already-in-use'),
        'This email is already registered.',
      );
      expect(
        DriverAuthErrors.messageKeyForCode('operation-not-allowed'),
        'This sign-in method is not enabled.',
      );
    });

    test('falls back for unknown codes', () {
      expect(
        DriverAuthErrors.messageKeyForCode('totally-unknown'),
        'Something went wrong. Please try again.',
      );
    });
  });
}
