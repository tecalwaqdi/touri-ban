/// Phone number normalize / persist helpers for booking checkout.
abstract final class TouryPhoneUtil {
  TouryPhoneUtil._();

  /// Keep digits only (handles +, spaces, dashes, Arabic-Indic digits).
  static String digitsOnly(String raw) {
    final mapped = raw.replaceAllMapped(RegExp(r'[٠-٩]'), (m) {
      const ar = '٠١٢٣٤٥٦٧٨٩';
      return '${ar.indexOf(m.group(0)!)}';
    }).replaceAllMapped(RegExp(r'[۰-۹]'), (m) {
      const fa = '۰۱۲۳۴۵۶۷۸۹';
      return '${fa.indexOf(m.group(0)!)}';
    });
    return mapped.replaceAll(RegExp(r'[^\d]'), '');
  }

  static bool hasUsablePhone({
    String? phoneNumber,
    int? phoneN,
    String? authPhone,
  }) {
    final fromText = (phoneNumber ?? '').trim();
    if (_digitsUsable(fromText)) return true;
    if (phoneN != null && phoneN > 0) {
      if (_digitsUsable(phoneN.toString())) return true;
    }
    final auth = (authPhone ?? '').trim();
    return _digitsUsable(auth);
  }

  static bool _digitsUsable(String raw) {
    final digits = digitsOnly(raw);
    if (digits.length < 7) return false;
    if (RegExp(r'^0+$').hasMatch(digits)) return false;
    return true;
  }

  static String displayPhone({
    String? phoneNumber,
    int? phoneN,
    String? authPhone,
  }) {
    final fromText = (phoneNumber ?? '').trim();
    if (fromText.isNotEmpty) return fromText;
    if (phoneN != null && phoneN > 0) return phoneN.toString();
    return (authPhone ?? '').trim();
  }

  static ({String phoneNumber, int? phoneN}) normalizeForSave(String raw) {
    final trimmed = raw.trim();
    final digits = digitsOnly(trimmed);
    final parsed = int.tryParse(digits);
    final phoneN =
        (parsed != null && parsed > 0 && digits.length >= 7) ? parsed : null;
    return (
      phoneNumber: trimmed.isNotEmpty ? trimmed : digits,
      phoneN: phoneN,
    );
  }
}
