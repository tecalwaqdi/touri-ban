import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_auth_validation_service.dart';

void main() {
  group('DriverAuthValidationService', () {
    test('normalizeEmail trims lowercases removes spaces', () {
      expect(
        DriverAuthValidationService.normalizeEmail('  Ali@Mail.COM '),
        'ali@mail.com',
      );
      expect(DriverAuthValidationService.normalizeEmail(''), isNull);
      expect(DriverAuthValidationService.normalizeEmail(null), isNull);
    });

    test('validateEmail rejects invalid', () {
      expect(
        DriverAuthValidationService.validateEmail('not-an-email'),
        isNotNull,
      );
      expect(
        DriverAuthValidationService.validateEmail('ok@example.com'),
        isNull,
      );
    });

    test('validatePassword min length and confirm', () {
      expect(
        DriverAuthValidationService.validatePassword('123'),
        isNotNull,
      );
      expect(
        DriverAuthValidationService.validatePassword('123456'),
        isNull,
      );
      expect(
        DriverAuthValidationService.validatePassword(
          '123456',
          requireConfirm: true,
          confirm: '654321',
        ),
        isNotNull,
      );
    });
  });
}
