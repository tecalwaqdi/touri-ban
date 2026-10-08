import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/core/toury_locale_loader.dart';

/// UI phrases for the customer app. Firestore overrides the bundled JSON
/// so a wording change does not need a store release.
abstract final class TouryRemoteUiStrings {
  static const appId = 'customer';
  static const locales = ['ar', 'en', 'fr', 'ky', 'pt', 'ru', 'ur'];
  static final revision = ValueNotifier<int>(0);

  static Future<void> applyPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    for (final code in locales) {
      final raw = prefs.getString(_prefsKey(code));
      final overlay = _decode(raw);
      if (overlay.isEmpty) continue;
      await TouryCachedAssetLoader.setOverlay(Locale(code), overlay);
    }
  }

  static Future<void> refresh({Locale? activeLocale}) async {
    final prefs = await SharedPreferences.getInstance();
    final changed = <String>[];
    await Future.wait(locales.map((code) async {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('app_ui_i18n')
            .doc('${appId}_$code')
            .get()
            .timeout(const Duration(seconds: 8));
        final overlay = _sorted(_stringMap(snap.data()?['strings']));
        final encoded = jsonEncode(overlay);
        final previous = prefs.getString(_prefsKey(code)) ?? '';
        if ((previous.isEmpty ? '{}' : previous) == encoded) return;
        await prefs.setString(_prefsKey(code), encoded);
        await TouryCachedAssetLoader.setOverlay(Locale(code), overlay);
        changed.add(code);
      } catch (e) {
        debugPrint('ui i18n $appId/$code skipped: $e');
      }
    }));
    if (changed.isEmpty) return;
    final locale = activeLocale ?? const Locale('en');
    _publish(locale);
    revision.value++;
  }

  static void _publish(Locale locale) {
    final current = TouryCachedAssetLoader.cachedMap(locale);
    if (current == null) return;
    final fallback = TouryCachedAssetLoader.cachedMap(const Locale('en'));
    Localization.load(
      locale,
      translations: Translations(Map<String, dynamic>.from(current)),
      fallbackTranslations: fallback == null
          ? null
          : Translations(Map<String, dynamic>.from(fallback)),
    );
  }

  static String _prefsKey(String code) => 'ui_i18n_${appId}_$code';

  static Map<String, String> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      return _stringMap(jsonDecode(raw));
    } catch (_) {
      return const {};
    }
  }

  static Map<String, String> _sorted(Map<String, String> overlay) {
    final keys = overlay.keys.toList()..sort();
    return {for (final key in keys) key: overlay[key]!};
  }

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((key, value) {
      final id = key.toString().trim();
      final text = value?.toString().trim() ?? '';
      if (id.isEmpty || text.isEmpty) return;
      out[id] = text;
    });
    return out;
  }
}
