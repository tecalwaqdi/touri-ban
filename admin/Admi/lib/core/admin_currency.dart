import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';

/// Country-driven currency for the admin panel (never locale-driven).
abstract final class AdminCurrency {
  AdminCurrency._();

  static const fallbackByIso = <String, String>{
    'SA': 'SAR',
    'AE': 'AED',
    'KW': 'KWD',
    'BH': 'BHD',
    'QA': 'QAR',
    'OM': 'OMR',
    'EG': 'EGP',
    'JO': 'JOD',
    'KG': 'KGS',
    'KGZ': 'KGS',
    'RU': 'RUB',
    'UZ': 'UZS',
    'UZB': 'UZS',
    'US': 'USD',
    'TR': 'TRY',
  };

  static const symbolByCode = <String, String>{
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'KWD': 'د.ك',
    'BHD': 'د.ب',
    'QAR': 'ر.ق',
    'OMR': 'ر.ع',
    'EGP': 'ج.م',
    'JOD': 'د.أ',
    'KGS': 'сом',
    'RUB': '₽',
    'UZS': "soʻm",
    'USD': r'$',
    'EUR': '€',
    'TRY': '₺',
  };

  static final Map<String, CountriesRecord?> _countryCache = {};

  static String codeFromCountry(CountriesRecord? country) {
    if (country == null) return '';
    final fromDoc = country.currencyCode.trim().toUpperCase();
    if (fromDoc.isNotEmpty) return fromDoc;
    final iso = country.isoCode.trim().toUpperCase();
    return fallbackByIso[iso] ?? '';
  }

  static String symbolForCode(String code, {String? override}) {
    final o = (override ?? '').trim();
    if (o.isNotEmpty) return o;
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return '';
    return symbolByCode[c] ?? c;
  }

  static String symbolFromCountry(CountriesRecord? country) {
    final code = codeFromCountry(country);
    return symbolForCode(code, override: country?.currencySymbol);
  }

  static String symbolForIso(String? iso) {
    final code = fallbackByIso[(iso ?? '').trim().toUpperCase()] ?? '';
    return symbolForCode(code);
  }

  /// Prefer order-stored fields, then linked country, then ISO / active scope.
  static String displaySymbolForOrder(
    OrderRecord order, {
    CountriesRecord? country,
  }) {
    final storedSymbol =
        (order.snapshotData['currency_symbol'] ?? '').toString().trim();
    if (storedSymbol.isNotEmpty) return storedSymbol;

    final codeField = (order.snapshotData['currency_code'] ??
            order.snapshotData['currency'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    if (codeField.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(codeField)) {
      return symbolForCode(
        codeField,
        override: country?.currencySymbol,
      );
    }

    final fromCountry = symbolFromCountry(country);
    if (fromCountry.isNotEmpty) return fromCountry;

    final scoped = symbolForActiveScopeSync();
    if (scoped.isNotEmpty) return scoped;

    if (codeField.isNotEmpty) return codeField;
    return '';
  }

  static String codeForOrder(OrderRecord order, {CountriesRecord? country}) {
    final codeField = (order.snapshotData['currency_code'] ??
            order.snapshotData['currency'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    if (codeField.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(codeField)) {
      return codeField;
    }
    final fromCountry = codeFromCountry(country);
    if (fromCountry.isNotEmpty) return fromCountry;
    return codeField;
  }

  /// Sync hint from scoped country ISO only (no network). Prefer [resolveSymbolForActiveScope].
  static String symbolForActiveScopeSync() {
    // No country doc in memory here — ISO map only when we know agent country ISO.
    return '';
  }

  static Future<String> resolveSymbolForActiveScope() async {
    final ref = AdminCountryScope.activeCountryRef;
    if (ref == null) return '';
    final country = await _countryOnce(ref);
    return symbolFromCountry(country);
  }

  static Future<String> resolveSymbolForOrder(OrderRecord order) async {
    final direct = displaySymbolForOrder(order);
    if (direct.isNotEmpty &&
        (order.snapshotData['currency_symbol'] != null ||
            order.snapshotData['currency_code'] != null ||
            order.snapshotData['currency'] != null)) {
      // Still try country for better symbol when only code is stored.
      if ((order.snapshotData['currency_symbol'] ?? '')
          .toString()
          .trim()
          .isNotEmpty) {
        return direct;
      }
    }
    final ref = order.revDolh;
    if (ref != null) {
      final country = await _countryOnce(ref);
      final fromCountry = displaySymbolForOrder(order, country: country);
      if (fromCountry.isNotEmpty) return fromCountry;
    }
    final scoped = await resolveSymbolForActiveScope();
    if (scoped.isNotEmpty) return scoped;
    return direct;
  }

  static Future<CountriesRecord?> _countryOnce(DocumentReference ref) async {
    final key = ref.path;
    if (_countryCache.containsKey(key)) return _countryCache[key];
    try {
      final doc = await CountriesRecord.getDocumentOnce(ref);
      _countryCache[key] = doc;
      return doc;
    } catch (_) {
      _countryCache[key] = null;
      return null;
    }
  }

  /// Format amount with a trailing currency symbol/code.
  static String formatAmount(num amount, String symbol, {int decimals = 2}) {
    final s = symbol.trim();
    final n = amount.toStringAsFixed(decimals);
    if (s.isEmpty) return n;
    return '$n $s';
  }

  /// Prefix for [formatNumber] `currency:` (symbol + space).
  static String asFormatPrefix(String symbol) {
    final s = symbol.trim();
    return s.isEmpty ? '' : '$s ';
  }
}
