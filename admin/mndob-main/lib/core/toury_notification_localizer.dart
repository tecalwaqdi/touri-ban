import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

/// Resolves push copy for a customer using their `preferred_locale`.
abstract final class TouryNotificationLocalizer {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static String localeFromPreferred(String? preferred) {
    final raw = (preferred ?? '').trim();
    return _assetLocale(raw.isEmpty ? 'en' : raw);
  }

  static Future<String> localeForUserRef(DocumentReference? userRef) async {
    if (userRef == null) return 'en';
    try {
      final snap = await userRef.get();
      final preferred = (snap.data() as Map<String, dynamic>?)?['preferred_locale'];
      return localeFromPreferred(preferred?.toString());
    } catch (_) {
      return 'en';
    }
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
    const production = {'ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'};
    if (production.contains(code)) return code;
    return 'en';
  }
}
