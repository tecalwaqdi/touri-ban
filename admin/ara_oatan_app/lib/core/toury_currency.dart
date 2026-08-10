import '/app_state.dart';
import '/backend/schema/countries_record.dart';
import '/backend/schema/order_record.dart';

/// Country-driven currency display (never locale-driven).
abstract final class TouryCurrency {
  TouryCurrency._();

  static const _fallbackByIso = <String, String>{
    'SA': 'SAR',
    'KG': 'KGS',
    'KGZ': 'KGS',
    'RU': 'RUB',
    'UZ': 'UZS',
    'UZB': 'UZS',
  };

  static const _symbolByCode = <String, String>{
    'SAR': 'ر.س',
    'KGS': 'сом',
    'RUB': '₽',
    'UZS': "soʻm",
  };

  static String codeFromCountry(CountriesRecord? country) {
    if (country == null) return '';
    final fromDoc = (country.snapshotData['currency_code'] ??
            country.snapshotData['currencyCode'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    if (fromDoc.isNotEmpty) return fromDoc;
    final iso = country.isoCode.trim().toUpperCase();
    if (_fallbackByIso.containsKey(iso)) return _fallbackByIso[iso]!;
    return '';
  }

  static String symbolForCode(String code, {String? override}) {
    final o = (override ?? '').trim();
    if (o.isNotEmpty) return o;
    final c = code.trim().toUpperCase();
    return _symbolByCode[c] ?? (c.isEmpty ? '' : c);
  }

  /// Prefer order-stored fields, then app session (selected country), then ISO.
  static String displaySymbolForOrder(
    OrderRecord order, {
    CountriesRecord? country,
  }) {
    final storedSymbol =
        (order.snapshotData['currency_symbol'] ?? '').toString().trim();
    if (storedSymbol.isNotEmpty) return storedSymbol;

    final codeField = (order.snapshotData['currency_code'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    if (codeField.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(codeField)) {
      return symbolForCode(
        codeField,
        override: country?.currencySymbol,
      );
    }

    final countryCode = codeFromCountry(country);
    if (countryCode.isNotEmpty) {
      return symbolForCode(
        countryCode,
        override: country?.currencySymbol,
      );
    }

    // Session reflects the country the user selected (KGS/сом for KG).
    final session = FFAppState().RMZCurrency.trim();
    if (session.isNotEmpty) return session;

    final legacy = (order.snapshotData['currency'] ?? '').toString().trim();
    if (legacy.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(legacy.toUpperCase())) {
      return symbolForCode(legacy.toUpperCase());
    }
    if (legacy.isNotEmpty) return legacy;
    return '';
  }

  static Map<String, dynamic> fieldsForCreate({
    required CountriesRecord? country,
  }) {
    final code = codeFromCountry(country);
    final symbol = symbolForCode(code, override: country?.currencySymbol);
    final resolvedCode = code.isNotEmpty ? code : 'SAR';
    return {
      'currency': resolvedCode,
      'currency_code': resolvedCode,
      if (symbol.isNotEmpty) 'currency_symbol': symbol,
    };
  }
}
