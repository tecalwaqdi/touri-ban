import 'package:flutter/widgets.dart';

import '/app_state.dart';
import '/backend/schema/countries_record.dart';
import '/backend/schema/order_record.dart';

/// Country selects the currency *code*; UI locale selects how SAR is *shown*.
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
    // Neutral ISO for SAR when locale is unknown/non-Arabic.
    // Arabic/Urdu UI uses official Riyal Sign (U+20C1) / SAMA SVG instead.
    'SAR': 'SAR',
    'KGS': 'сом',
    'RUB': '₽',
    'UZS': "soʻm",
  };

  static const officialRiyalSign = '\u20C1';

  /// Arabic-script UI languages show the official Riyal glyph; all others use
  /// Latin "SAR" so scripts never mix inside a single string/row.
  static bool prefersOfficialRiyalGlyph([Locale? locale]) {
    final lang = (locale?.languageCode ?? '').toLowerCase();
    return lang == 'ar' || lang == 'ur';
  }

  static bool _isSaudiRiyalToken(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return false;
    if (t == 'ر.س' || t == 'ر.س.' || t == officialRiyalSign) return true;
    final u = t.toUpperCase();
    return u == 'SAR' || u == 'RS' || u == 'SR';
  }

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

  /// Display symbol for a currency code. Pass [locale] so SAR follows UI
  /// language (glyph in ar/ur, Latin "SAR" elsewhere). Without locale, SAR
  /// stays the neutral ISO code so stored order fields never bake in Arabic.
  static String symbolForCode(
    String code, {
    String? override,
    Locale? locale,
  }) {
    final o = (override ?? '').trim();
    if (_isSaudiRiyalToken(o) || _isSaudiRiyalToken(code)) {
      return prefersOfficialRiyalGlyph(locale) ? officialRiyalSign : 'SAR';
    }
    if (o.isNotEmpty) return o;
    final c = code.trim().toUpperCase();
    return _symbolByCode[c] ?? (c.isEmpty ? '' : c);
  }

  /// Prefer order-stored fields, then app session (selected country), then ISO.
  static String displaySymbolForOrder(
    OrderRecord order, {
    CountriesRecord? country,
    Locale? locale,
  }) {
    final storedSymbol =
        (order.snapshotData['currency_symbol'] ?? '').toString().trim();
    if (_isSaudiRiyalToken(storedSymbol)) {
      return symbolForCode('SAR', locale: locale);
    }
    if (storedSymbol.isNotEmpty) return storedSymbol;

    final codeField = (order.snapshotData['currency_code'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    if (codeField.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(codeField)) {
      return symbolForCode(
        codeField,
        override: country?.currencySymbol,
        locale: locale,
      );
    }

    final countryCode = codeFromCountry(country);
    if (countryCode.isNotEmpty) {
      return symbolForCode(
        countryCode,
        override: country?.currencySymbol,
        locale: locale,
      );
    }

    // Session reflects the country the user selected (KGS/сом for KG).
    final session = FFAppState().RMZCurrency.trim();
    if (_isSaudiRiyalToken(session)) {
      return symbolForCode('SAR', locale: locale);
    }
    if (session.isNotEmpty) return session;

    final legacy = (order.snapshotData['currency'] ?? '').toString().trim();
    if (legacy.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(legacy.toUpperCase())) {
      return symbolForCode(legacy.toUpperCase(), locale: locale);
    }
    if (_isSaudiRiyalToken(legacy)) {
      return symbolForCode('SAR', locale: locale);
    }
    if (legacy.isNotEmpty) return legacy;
    return '';
  }

  static Map<String, dynamic> fieldsForCreate({
    required CountriesRecord? country,
  }) {
    final code = codeFromCountry(country);
    final resolvedCode = code.isNotEmpty ? code : 'SAR';
    // Persist neutral ISO for SAR; UI localizes the glyph at render time.
    final symbol = symbolForCode(
      resolvedCode,
      override: country?.currencySymbol,
    );
    return {
      'currency': resolvedCode,
      'currency_code': resolvedCode,
      if (symbol.isNotEmpty) 'currency_symbol': symbol,
    };
  }
}
