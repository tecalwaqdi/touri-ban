import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_driver_email_verification.dart';

void main() {
  group('AdminDriverEmailVerification', () {
    test('verified mirror true → موثق', () {
      final state = AdminDriverEmailVerification.fromUserData({
        'email_verified_mirror': true,
      });
      expect(state, AdminDriverEmailVerificationDisplay.verified);
      expect(
        AdminDriverEmailVerification.labelArabic(state),
        'موثق',
      );
    });

    test('verified mirror false → غير موثق', () {
      final state = AdminDriverEmailVerification.fromUserData({
        'email_verified_mirror': false,
      });
      expect(state, AdminDriverEmailVerificationDisplay.unverified);
      expect(
        AdminDriverEmailVerification.labelArabic(state),
        'غير موثق',
      );
    });

    test('missing mirror → unknown, not unverified', () {
      final state = AdminDriverEmailVerification.fromUserData({});
      expect(state, AdminDriverEmailVerificationDisplay.unknown);
      expect(
        AdminDriverEmailVerification.labelArabic(state),
        'تعذر التحقق من الحالة',
      );
    });

    test('non-bool mirror → unknown', () {
      final state = AdminDriverEmailVerification.fromUserData({
        'email_verified_mirror': 'yes',
      });
      expect(state, AdminDriverEmailVerificationDisplay.unknown);
    });
  });
}
