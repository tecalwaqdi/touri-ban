/// Locale keys used for Firestore content (`names_i18n`).
const List<String> driverI18nLocaleKeys = [
  'ar',
  'en',
  'ru',
  'ky',
  'fr',
  'ur',
  'pt',
];

Map<String, String> driverParseI18nMap(dynamic raw) {
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

final _arabicScript = RegExp(r'[\u0600-\u06FF]');

bool driverLooksArabic(String value) => _arabicScript.hasMatch(value);

/// Resolves content text for [localeKey].
///
/// Non-Arabic locales: current locale → `en` → first non-Arabic field.
/// Never prefer Arabic when alternatives exist.
String driverLocalizedText(
  Map<String, String> i18n,
  String legacy, {
  required String localeKey,
}) {
  final langOnly = localeKey.split(RegExp(r'[_-]')).first.toLowerCase();
  final legacyTrim = legacy.trim();

  String? pick(String key, {bool requireArabicScript = false}) {
    final v = i18n[key]?.trim();
    if (v == null || v.isEmpty) return null;
    if (requireArabicScript && !driverLooksArabic(v)) return null;
    if (langOnly != 'ar' && driverLooksArabic(v)) return null;
    return v;
  }

  String? firstArabicInMap() {
    for (final entry in i18n.entries) {
      final v = entry.value.trim();
      if (v.isNotEmpty && driverLooksArabic(v)) return v;
    }
    if (legacyTrim.isNotEmpty && driverLooksArabic(legacyTrim)) {
      return legacyTrim;
    }
    return null;
  }

  if (langOnly == 'ar') {
    final arScript =
        pick('ar', requireArabicScript: true) ?? firstArabicInMap();
    if (arScript != null) return arScript;
  } else {
    final direct = pick(localeKey) ?? pick(langOnly);
    if (direct != null) return direct;
  }

  final en = pick('en');
  if (en != null) return en;

  for (final entry in i18n.entries) {
    final v = entry.value.trim();
    if (v.isEmpty) continue;
    if (langOnly != 'ar' && driverLooksArabic(v)) continue;
    return v;
  }

  if (legacyTrim.isEmpty) return '';
  if (langOnly != 'ar' && driverLooksArabic(legacyTrim)) {
    return '';
  }
  return legacyTrim;
}
