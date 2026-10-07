/// Support phone rule shared by driver screens. No Firestore.
class TourySupportResolution {
  const TourySupportResolution({this.digits, this.code, this.fallback = false});

  final String? digits;
  final String? code;
  final bool fallback;

  bool get ok => digits != null && digits!.length >= 8;
}

class TourySupportPolicy {
  static const saudiFallbackDigits = '966533356126';

  static String normalizeDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    return digits;
  }

  static bool isSaudi({String? iso2, String? countryPath}) {
    final iso = (iso2 ?? '').trim().toUpperCase();
    if (iso == 'SA' || iso == 'SAU') return true;
    final path = (countryPath ?? '').trim().toLowerCase();
    return path == 'countries/saudi_arabia' || path.endsWith('/saudi_arabia');
  }

  static TourySupportResolution resolve({
    String? iso2,
    String? countryPath,
    String? agentPhone,
  }) {
    final digits = normalizeDigits(agentPhone ?? '');
    if (digits.length >= 8) {
      return TourySupportResolution(digits: digits);
    }
    if (isSaudi(iso2: iso2, countryPath: countryPath)) {
      return const TourySupportResolution(
        digits: saudiFallbackDigits,
        fallback: true,
      );
    }
    return const TourySupportResolution(code: 'SUPPORT_NOT_CONFIGURED');
  }
}
