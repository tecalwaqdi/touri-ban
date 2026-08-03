/// Normalizes phone numbers to E.164 for supported countries.
abstract final class DriverPhoneNumberService {
  DriverPhoneNumberService._();

  static const Map<String, String> dialByIso = {
    'SA': '966',
    'KG': '996',
    'RU': '7',
    'UZ': '998',
  };

  /// Expected national significant number length (without country code).
  static const Map<String, int> nationalLengthByIso = {
    'SA': 9,
    'KG': 9,
    'RU': 10,
    'UZ': 9,
  };

  static String arabicDigitsToEnglish(String input) {
    const eastern = '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹'; // Arabic-Indic + Persian
    const english = '01234567890123456789';
    final buf = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final i = eastern.indexOf(ch);
      buf.write(i >= 0 ? english[i] : ch);
    }
    return buf.toString();
  }

  /// Digits only (after Arabic→English conversion).
  static String digitsOnly(String input) {
    final normalized = arabicDigitsToEnglish(input.trim());
    return normalized.replaceAll(RegExp(r'\D'), '');
  }

  /// Returns E.164 (`+9665…`) or null if invalid for [iso2].
  static String? toE164({
    required String raw,
    required String iso2,
  }) {
    final iso = iso2.trim().toUpperCase();
    final dial = dialByIso[iso];
    final expectedLen = nationalLengthByIso[iso];
    if (dial == null || expectedLen == null) return null;

    var digits = digitsOnly(raw);
    if (digits.isEmpty) return null;

    // Strip leading + already removed by digitsOnly; handle 00 prefix.
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    // Already includes country dial code.
    // startsWith() alone is not enough: a short partial input such as
    // "966" must not be sliced as if it contained a national number.
    if (digits.length >= dial.length && digits.startsWith(dial)) {
      final national = digits.substring(dial.length);
      final cleaned = _stripLocalTrunk(national, iso);
      if (cleaned.length != expectedLen) return null;
      if (!_validNational(cleaned, iso)) return null;
      return '+$dial$cleaned';
    }

    final national = _stripLocalTrunk(digits, iso);
    if (national.length != expectedLen) return null;
    if (!_validNational(national, iso)) return null;
    return '+$dial$national';
  }

  static bool isValid({required String raw, required String iso2}) =>
      toE164(raw: raw, iso2: iso2) != null;

  /// Display form without forcing a specific local trunk zero.
  static String displayLocal({
    required String e164OrRaw,
    required String iso2,
  }) {
    final e164 = toE164(raw: e164OrRaw, iso2: iso2) ?? e164OrRaw.trim();
    return e164;
  }

  static String _stripLocalTrunk(String national, String iso) {
    // SA / many MENA: drop leading 0 of 05xxxxxxxx
    if ((iso == 'SA' || iso == 'KG' || iso == 'UZ') &&
        national.startsWith('0') &&
        national.length == (nationalLengthByIso[iso]! + 1)) {
      return national.substring(1);
    }
    return national;
  }

  static bool _validNational(String national, String iso) {
    if (!RegExp(r'^\d+$').hasMatch(national)) return false;
    if (iso == 'SA') {
      // Mobile: starts with 5
      return national.startsWith('5');
    }
    return true;
  }
}
