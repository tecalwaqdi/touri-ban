import '/core/toury_phone_util.dart';

String? touryValidateSignupPhone(String raw) {
  final normalized = TouryPhoneUtil.normalizeForSave(raw);
  final digits = TouryPhoneUtil.digitsOnly(normalized.phoneNumber);
  if (digits.isEmpty) return 'PHONE_REQUIRED';
  if (digits.length < 7) return 'PHONE_REQUIRED';
  return null;
}
