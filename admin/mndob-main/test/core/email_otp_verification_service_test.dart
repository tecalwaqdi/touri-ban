import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/email_otp_verification_service.dart';

void main() {
  group('Driver Email OTP helpers', () {
    setUp(EmailOtpVerificationService.debugReset);

    test('maskEmail', () {
      expect(
        EmailOtpVerificationService.maskEmail('driver@touri-taxi.com'),
        'dr***@touri-taxi.com',
      );
    });

    test('mode defaults to emailLink (driver policy)', () {
      expect(
        EmailOtpVerificationService.mode,
        EmailVerificationMode.emailLink,
      );
    });
  });
}
