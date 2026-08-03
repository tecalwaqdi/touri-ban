import 'toury_i18n_locales.dart';

Map<String, String> touryParseI18nMap(dynamic raw) {
  if (raw == null || raw is! Map) return {};
  final out = <String, String>{};
  raw.forEach((key, value) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      out[key.toString()] = text;
    }
  });
  return out;
}

/// يعيد النص بلغة المستخدم مع fallback ذكي.
String touryLocalizedText(
  Map<String, String> i18n,
  String legacy, {
  required String localeKey,
}) {
  final direct = i18n[localeKey]?.trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final langOnly = localeKey.split('_').first;
  if (langOnly != localeKey) {
    final partial = i18n[langOnly]?.trim();
    if (partial != null && partial.isNotEmpty) return partial;
  }

  for (final key in ['en', 'ar']) {
    final v = i18n[key]?.trim();
    if (v != null && v.isNotEmpty) return v;
  }

  for (final v in i18n.values) {
    if (v.trim().isNotEmpty) return v.trim();
  }

  return legacy.trim();
}

/// يبني خريطة ترجمة من الحقول مع تعبئة الحقول الفارغة من المصدر.
Map<String, String> touryBuildI18nMap({
  required Map<String, String> values,
  required String sourceLocale,
  required String sourceText,
}) {
  final out = Map<String, String>.from(values);
  final source = sourceText.trim();
  if (source.isNotEmpty) {
    out[sourceLocale] = source;
  }
  for (final key in touryI18nLocaleKeys) {
    out.putIfAbsent(key, () => '');
  }
  return out
    ..removeWhere((_, v) => v.trim().isEmpty);
}

String touryPrimaryLegacyText(
  Map<String, String> i18n,
  String fallback, {
  String prefer = 'ar',
}) {
  final preferred = i18n[prefer]?.trim();
  if (preferred != null && preferred.isNotEmpty) return preferred;
  final en = i18n['en']?.trim();
  if (en != null && en.isNotEmpty) return en;
  for (final v in i18n.values) {
    if (v.trim().isNotEmpty) return v.trim();
  }
  return fallback.trim();
}
