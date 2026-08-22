/// Explicit currency minor-unit precision for admin financial math.
///
/// Never assume `* 100` for every currency.
abstract final class CurrencyMoneyPolicy {
  CurrencyMoneyPolicy._();

  /// ISO 4217 minor-unit exponents we support for reporting.
  static const Map<String, int> _exponentByCode = {
    'SAR': 2,
    'AED': 2,
    'QAR': 2,
    'EGP': 2,
    'USD': 2,
    'EUR': 2,
    'MAD': 2,
    'TND': 3,
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
    'JOD': 3,
    'KGS': 2,
    'INR': 2,
    'IDR': 2,
    'MYR': 2,
    'TRY': 2,
    'RUB': 2,
    'UZS': 2,
  };

  static String normalizeCode(String? raw) =>
      (raw ?? '').trim().toUpperCase();

  /// Returns exponent or `null` when unsupported.
  static int? exponentOrNull(String? currency) {
    final code = normalizeCode(currency);
    if (code.isEmpty) return null;
    return _exponentByCode[code];
  }

  static bool isSupported(String? currency) =>
      exponentOrNull(currency) != null;

  static const unsupportedPrecision = 'UNSUPPORTED_CURRENCY_PRECISION';
}

/// Immutable money value in **integer minor units**.
class MoneyAmount {
  const MoneyAmount({
    required this.currency,
    required this.minorUnits,
  });

  final String currency;
  final int minorUnits;

  String get code => CurrencyMoneyPolicy.normalizeCode(currency);

  int get exponent {
    final e = CurrencyMoneyPolicy.exponentOrNull(code);
    if (e == null) {
      throw StateError(CurrencyMoneyPolicy.unsupportedPrecision);
    }
    return e;
  }

  bool get isSupported => CurrencyMoneyPolicy.isSupported(code);

  double get majorUnits {
    final e = exponent;
    var div = 1;
    for (var i = 0; i < e; i++) {
      div *= 10;
    }
    return minorUnits / div;
  }

  MoneyAmount operator +(MoneyAmount other) {
    _sameCurrency(other);
    return MoneyAmount(currency: code, minorUnits: minorUnits + other.minorUnits);
  }

  MoneyAmount operator -(MoneyAmount other) {
    _sameCurrency(other);
    return MoneyAmount(currency: code, minorUnits: minorUnits - other.minorUnits);
  }

  MoneyAmount abs() => MoneyAmount(
        currency: code,
        minorUnits: minorUnits.abs(),
      );

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  void _sameCurrency(MoneyAmount other) {
    if (code != other.code) {
      throw ArgumentError(
        'Cannot combine currencies $code and ${other.code}',
      );
    }
  }

  /// Converts a major-unit number using the currency exponent.
  ///
  /// Returns `null` when currency precision is unsupported or [major] is null.
  static MoneyAmount? fromMajor(String? currency, num? major) {
    if (major == null) return null;
    final code = CurrencyMoneyPolicy.normalizeCode(currency);
    final exp = CurrencyMoneyPolicy.exponentOrNull(code);
    if (exp == null) return null;
    var factor = 1;
    for (var i = 0; i < exp; i++) {
      factor *= 10;
    }
    final minor = (major.toDouble() * factor).round();
    return MoneyAmount(currency: code, minorUnits: minor);
  }

  static MoneyAmount zero(String currency) =>
      MoneyAmount(currency: CurrencyMoneyPolicy.normalizeCode(currency), minorUnits: 0);

  @override
  bool operator ==(Object other) =>
      other is MoneyAmount &&
      other.code == code &&
      other.minorUnits == minorUnits;

  @override
  int get hashCode => Object.hash(code, minorUnits);

  @override
  String toString() => 'MoneyAmount($code, $minorUnits)';
}
