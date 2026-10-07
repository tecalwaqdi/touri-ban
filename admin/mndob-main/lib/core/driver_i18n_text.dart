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
    if (langOnly != 'ar' && langOnly != 'ur' && driverLooksArabic(v)) return null;
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
    if (langOnly != 'ar' && langOnly != 'ur' && driverLooksArabic(v)) continue;
    return v;
  }

  if (legacyTrim.isEmpty) return '';
  // Non-Arabic UI must not surface an Arabic-only canonical name.
  if (langOnly != 'ar' && langOnly != 'ur' && driverLooksArabic(legacyTrim)) {
    return '';
  }
  return legacyTrim;
}

/// Cached profile text is a registration snapshot, often Arabic.
/// Non-Arabic UI must not show it when it is Arabic script.
String driverSafeCachedGeoLabel(
  String cached, {
  required String localeKey,
}) {
  final lang = localeKey.split(RegExp(r'[_-]')).first.toLowerCase();
  final text = cached.trim();
  if (text.isEmpty) return '';
  if (lang != 'ar' && lang != 'ur' && driverLooksArabic(text)) return '';
  return text;
}

/// Area name for the available-orders search line.
///
/// Prefer names_i18n for the requested locale, then English, then another
/// non-Arabic locale. The Arabic legacy/cached field is not used before English.
String driverSearchingAreaLabel({
  required String localeKey,
  Map<String, String> namesI18n = const {},
  String legacyNaim = '',
  String cachedText = '',
}) {
  if (namesI18n.isNotEmpty || legacyNaim.trim().isNotEmpty) {
    final resolved = driverLocalizedText(
      namesI18n,
      legacyNaim,
      localeKey: localeKey,
    );
    if (resolved.isNotEmpty) return resolved;
  }
  return driverSafeCachedGeoLabel(cachedText, localeKey: localeKey);
}
