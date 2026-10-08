import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// يحمّل ملفات الترجمة مرة واحدة في الذاكرة.
class DriverCachedAssetLoader extends AssetLoader {
  const DriverCachedAssetLoader();

  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, Map<String, String>> _overlays = {};

  /// Drop bundled maps so the next [load]/[preloadAll] re-reads assets.
  /// Remote overlays stay and are applied again inside [load].
  static void clearCache() => _cache.clear();

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

    final overlay = _overlays[key];
    if (overlay != null && overlay.isNotEmpty) {
      decoded.addAll(overlay);
    }
    _cache[key] = decoded;
    return decoded;
  }

  /// Replaces the remote overlay for [locale] and re-reads the bundled file.
  static Future<void> setOverlay(
    Locale locale,
    Map<String, String> overlay,
  ) async {
    final key = assetPath('assets/langs', locale);
    final cleaned = <String, String>{};
    overlay.forEach((rawKey, rawValue) {
      final text = rawValue.trim();
      final id = rawKey.trim();
      if (id.isEmpty || text.isEmpty) return;
      cleaned[id] = text;
    });
    if (cleaned.isEmpty) {
      _overlays.remove(key);
    } else {
      _overlays[key] = cleaned;
    }
    _cache.remove(key);
    try {
      await const DriverCachedAssetLoader().load('assets/langs', locale);
    } catch (e) {
      debugPrint('DriverCachedAssetLoader: overlay reload skipped: $e');
    }
  }

  static Map<String, dynamic>? cachedMap(Locale locale) =>
      _cache[assetPath('assets/langs', locale)];

  /// Saved server override only. Bundled text is not treated as an override.
  static String? remoteText(Locale locale, String key) {
    final id = key.trim();
    if (id.isEmpty) return null;
    final value = _overlays[assetPath('assets/langs', locale)]?[id]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
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
