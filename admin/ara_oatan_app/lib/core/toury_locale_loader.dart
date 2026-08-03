import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// يحمّل ملفات الترجمة مرة واحدة في الذاكرة — يمنع فشل ar.json أثناء التنقل.
class TouryCachedAssetLoader extends AssetLoader {
  const TouryCachedAssetLoader();

  static final Map<String, Map<String, dynamic>> _cache = {};

  static String localeFileName(Locale locale) {
    if (locale.scriptCode != null && locale.scriptCode!.isNotEmpty) {
      return '${locale.languageCode}-${locale.scriptCode}';
    }
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  static String assetPath(String basePath, Locale locale) =>
      '$basePath/${localeFileName(locale)}.json';

  static Future<void> preloadAll(
    String basePath,
    Iterable<Locale> locales,
  ) async {
    for (final locale in locales) {
      try {
        await const TouryCachedAssetLoader().load(basePath, locale);
      } catch (e) {
        debugPrint(
          'TouryCachedAssetLoader: skip ${assetPath(basePath, locale)}: $e',
        );
      }
    }
  }

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final key = assetPath(path, locale);
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString(key);
    if (raw.trim().isEmpty) {
      throw FlutterError('Translation file is empty: $key');
    }

    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FlutterError('Translation file must be a JSON object: $key');
    }

    _cache[key] = decoded;
    return decoded;
  }

  /// Sync lookup after [preloadAll]. Returns null if missing.
  static String? translate(String easyKey, Locale locale) {
    final file = assetPath('assets/langs', locale);
    final map = _cache[file];
    if (map == null) return null;
    final value = map[easyKey];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
