import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/email_otp_verification_service.dart';
import 'package:ara_oatan_app/core/toury_email_verification_gate.dart';

void main() {
  group('EmailOtpVerificationService helpers', () {
    setUp(EmailOtpVerificationService.debugReset);

    test('maskEmail hides local part', () {
      expect(
        EmailOtpVerificationService.maskEmail('ara@touri-taxi.com'),
        'ar***@touri-taxi.com',
      );
    });

    test('default mode is emailLink (Customer release)', () {
      expect(
        EmailOtpVerificationService.mode,
        EmailVerificationMode.emailLink,
      );
    });

    test('6-digit validation pattern', () {
      expect(RegExp(r'^\d{6}$').hasMatch('483921'), isTrue);
      expect(RegExp(r'^\d{6}$').hasMatch('48392'), isFalse);
      expect(RegExp(r'^\d{6}$').hasMatch('48392a'), isFalse);
    });
  });

  group('Customer email gate SoT', () {
    test('blocks when emailVerified=false', () {
      expect(
        touryShouldBlockUnverifiedCustomer(emailVerified: false),
        isTrue,
      );
    });

    test('allows when emailVerified=true', () {
      expect(
        touryShouldBlockUnverifiedCustomer(emailVerified: true),
        isFalse,
      );
    });
  });
}
