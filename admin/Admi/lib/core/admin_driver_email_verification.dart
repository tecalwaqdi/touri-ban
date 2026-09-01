/// Display-only email verification state for Admin driver review.
///
/// Canonical SoT: server-written [email_verified_mirror] on the user doc
/// (mirrors Firebase Auth `emailVerified` after Resend OTP).
enum AdminDriverEmailVerificationDisplay {
  verified,
  unverified,
  unknown,
}

abstract final class AdminDriverEmailVerification {
  AdminDriverEmailVerification._();

  static const mirrorField = 'email_verified_mirror';

  static AdminDriverEmailVerificationDisplay fromUserData(
    Map<String, dynamic> data,
  ) {
    if (!data.containsKey(mirrorField)) {
      return AdminDriverEmailVerificationDisplay.unknown;
    }
    final raw = data[mirrorField];
    if (raw is bool) {
      return raw
          ? AdminDriverEmailVerificationDisplay.verified
          : AdminDriverEmailVerificationDisplay.unverified;
    }
    return AdminDriverEmailVerificationDisplay.unknown;
  }

  static String labelArabic(AdminDriverEmailVerificationDisplay state) {
    return switch (state) {
      AdminDriverEmailVerificationDisplay.verified => 'موثق',
      AdminDriverEmailVerificationDisplay.unverified => 'غير موثق',
      AdminDriverEmailVerificationDisplay.unknown => 'تعذر التحقق من الحالة',
    };
  }
}
