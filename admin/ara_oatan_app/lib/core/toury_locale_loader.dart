import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// يحمّل ملفات الترجمة مرة واحدة في الذاكرة — يمنع فشل ar.json أثناء التنقل.
class TouryCachedAssetLoader extends AssetLoader {
  const TouryCachedAssetLoader();

  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, Map<String, String>> _overlays = {};

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
      await const TouryCachedAssetLoader().load('assets/langs', locale);
    } catch (e) {
      debugPrint('TouryCachedAssetLoader: overlay reload skipped: $e');
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
