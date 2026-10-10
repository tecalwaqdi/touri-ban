import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Languages shipped in the Touri Taxi apps.
const kLandmarkAppLocales = ['ar', 'en', 'fr', 'ky', 'pt', 'ru', 'ur'];

const kLandmarkMaxText = 10000;

String normalizeLandmarkLocale(String? locale) {
  final raw = (locale ?? '').trim();
  if (raw.isEmpty) return '';
  if (kLandmarkAppLocales.contains(raw)) return raw;
  final base = raw.split(RegExp(r'[-_]')).first;
  if (kLandmarkAppLocales.contains(base)) return base;
  return raw;
}

String _localeKey(String? locale) {
  final normalized = normalizeLandmarkLocale(locale);
  return normalized.isEmpty ? 'ar' : normalized;
}

/// Same digest the Cloud Function uses for `names_i18n_auto.sourceHash`.
String landmarkSourceHash(String locale, String text) {
  final payload = '${_localeKey(locale)}\n${text.trim()}';
  return sha256.convert(utf8.encode(payload)).toString();
}

Map<String, String> _stringMap(dynamic raw) {
  if (raw is! Map) return {};
  final out = <String, String>{};
  raw.forEach((key, value) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) out[key.toString()] = text;
  });
  return out;
}

/// True when at least one app language is missing or its machine translation
/// is stale. Existing manual values do not count as work.
bool needsLandmarkAzure({
  required String sourceLocale,
  required String sourceText,
  required Map<String, String> existing,
  Map<String, dynamic>? auto,
}) {
  final text = sourceText.trim();
  if (text.isEmpty || text.length > kLandmarkMaxText) return false;
  final source = _localeKey(sourceLocale);
  final hash = landmarkSourceHash(source, text);
  final storedHash = auto?['sourceHash']?.toString() ?? '';
  final autoValues = _stringMap(auto?['values']);
  for (final lang in kLandmarkAppLocales) {
    if (lang == source) continue;
    final current = (existing[lang] ?? '').trim();
    if (current.isEmpty) return true;
    if (autoValues.containsKey(lang) &&
        autoValues[lang] == current &&
        storedHash != hash) {
      return true;
    }
  }
  return false;
}

/// Copies [patch] onto [existing] without deleting extra locale keys and
/// without replacing the source language from a machine translation.
Map<String, String> mergeLandmarkI18nPatch(
  Map<String, String> existing,
  Map<String, String> patch, {
  String? sourceLocale,
}) {
  final out = <String, String>{};
  existing.forEach((key, value) {
    final text = value.trim();
    if (text.isNotEmpty) out[key] = text;
  });
  final source = _localeKey(sourceLocale);
  patch.forEach((key, value) {
    if (key == source) return;
    if (!kLandmarkAppLocales.contains(key)) return;
    final text = value.trim();
    if (text.isEmpty) return;
    out[key] = text;
  });
  return out;
}

/// Keeps the author's text on the source language. Other keys stay as stored.
Map<String, String> withLandmarkSourceText(
  Map<String, String> existing, {
  required String sourceLocale,
  required String sourceText,
}) {
  final out = <String, String>{};
  existing.forEach((key, value) {
    final text = value.trim();
    if (text.isNotEmpty) out[key] = text;
  });
  final text = sourceText.trim();
  final locale = normalizeLandmarkLocale(sourceLocale);
  if (text.isNotEmpty && kLandmarkAppLocales.contains(locale)) {
    out[locale] = text;
  }
  return out;
}
