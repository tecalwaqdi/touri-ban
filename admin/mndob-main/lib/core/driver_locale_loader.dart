import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// يحمّل ملفات الترجمة مرة واحدة في الذاكرة.
class DriverCachedAssetLoader extends AssetLoader {
  const DriverCachedAssetLoader();

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
        await const DriverCachedAssetLoader().load(basePath, locale);
      } catch (e) {
        debugPrint(
          'DriverCachedAssetLoader: skip ${assetPath(basePath, locale)}: $e',
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

  /// ترجمة متزامنة من الذاكرة المؤقتة (بعد التحميل المسبق).
  static String? translate(
    String key,
    Locale locale, {
    String basePath = 'assets/langs',
  }) {
    final cacheKey = assetPath(basePath, locale);
    final map = _cache[cacheKey];
    if (map == null) return null;
    final value = map[key];
    return value is String ? value : null;
  }
}
