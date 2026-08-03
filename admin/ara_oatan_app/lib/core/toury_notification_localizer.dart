import 'dart:convert';

import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/flutter_flow/internationalization.dart';

abstract final class TouryNotificationLocalizer {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static String currentLocale() {
    final stored = FFLocalizations.getStoredLocale();
    return _assetLocale(stored?.toString() ?? 'en');
  }

  static String localeForUser(UserRecord user) {
    final preferred = user.preferredLocale.trim();
    return _assetLocale(preferred.isEmpty ? 'en' : preferred);
  }

  static Future<String> text(
    String locale,
    String key, {
    Map<String, String> args = const {},
  }) async {
    final assetLocale = _assetLocale(locale);
    final values = await _load(assetLocale);
    var output = values[key]?.toString();
    if (output == null || output.trim().isEmpty) {
      // Never leak English into ar/ru/ky when the key is missing.
      if (assetLocale == 'en') {
        output = (await _load('en'))[key]?.toString() ?? key;
      } else {
        output = values['error_generic_user']?.toString() ??
            (await _load(assetLocale))['error_generic_user']?.toString() ??
            (await _load('en'))['error_generic_user']?.toString() ??
            key;
      }
    }
    for (final entry in args.entries) {
      output = output!.replaceAll('{${entry.key}}', entry.value);
    }
    return output!;
  }

  static Future<Map<String, dynamic>> _load(String locale) async {
    final cached = _cache[locale];
    if (cached != null) return cached;
    try {
      final source = await rootBundle.loadString('assets/langs/$locale.json');
      final values = jsonDecode(source) as Map<String, dynamic>;
      _cache[locale] = values;
      return values;
    } catch (_) {
      if (locale != 'en') return _load('en');
      rethrow;
    }
  }

  static String _assetLocale(String locale) {
    final normalized = locale.replaceAll('_', '-');
    final code = normalized.split('-').first.toLowerCase();
    const production = {'ar', 'en', 'ru', 'ky'};
    if (production.contains(code)) return code;
    return 'en';
  }
}
