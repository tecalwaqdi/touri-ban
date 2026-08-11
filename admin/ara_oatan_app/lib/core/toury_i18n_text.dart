/// مفاتيح اللغات المدعومة في محتوى Firestore.
const List<String> touryI18nLocaleKeys = [
  'ar',
  'en',
  'ru',
  'ky',
];

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

final _arabicScript = RegExp(r'[\u0600-\u06FF]');

bool touryLooksArabic(String value) => _arabicScript.hasMatch(value);

/// Resolves content text for [localeKey].
///
/// Order for Arabic UI:
/// 1. `names_i18n.ar` only if it contains Arabic script (OSM often pollutes `ar`
///    with English — ignore those)
/// 2. any i18n / legacy value that looks Arabic
/// 3. otherwise English / other / legacy
///
/// Non-Arabic locales: current locale → `en` → first available non-empty
/// non-Arabic field. Never prefer Arabic when alternatives exist.
String touryLocalizedText(
  Map<String, String> i18n,
  String legacy, {
  required String localeKey,
}) {
  final langOnly = localeKey.split(RegExp(r'[_-]')).first.toLowerCase();
  final legacyTrim = legacy.trim();

  String? pick(String key, {bool requireArabicScript = false}) {
    final v = i18n[key]?.trim();
    if (v == null || v.isEmpty) return null;
    if (requireArabicScript && !touryLooksArabic(v)) return null;
    if (langOnly != 'ar' && touryLooksArabic(v)) return null;
    return v;
  }

  String? firstArabicInMap() {
    for (final entry in i18n.entries) {
      final v = entry.value.trim();
      if (v.isNotEmpty && touryLooksArabic(v)) return v;
    }
    if (legacyTrim.isNotEmpty && touryLooksArabic(legacyTrim)) {
      return legacyTrim;
    }
    return null;
  }

  if (langOnly == 'ar') {
    final arScript =
        pick('ar', requireArabicScript: true) ?? firstArabicInMap();
    if (arScript != null) return arScript;
    // No Arabic available — fall through to en / other / legacy.
  } else {
    // Current locale first; never prefer Arabic when alternatives exist.
    final direct = pick(localeKey) ?? pick(langOnly);
    if (direct != null) return direct;
  }

  // Shared fallback: en, then first available non-empty non-Arabic field.
  final en = pick('en');
  if (en != null) return en;

  for (final entry in i18n.entries) {
    final v = entry.value.trim();
    if (v.isEmpty) continue;
    if (langOnly != 'ar' && touryLooksArabic(v)) continue;
    return v;
  }

  if (legacyTrim.isEmpty) return '';
  if (langOnly != 'ar' && touryLooksArabic(legacyTrim)) {
    return '';
  }
  return legacyTrim;
}

/// Display-safe address: hide Arabic-only address when UI locale is not Arabic.
String touryLocalizedAddress(
  String address, {
  required String localeKey,
  Map<String, String> addressI18n = const {},
}) {
  final localized = touryLocalizedText(
    addressI18n,
    address,
    localeKey: localeKey,
  );
  final lang = localeKey.split(RegExp(r'[_-]')).first.toLowerCase();
  if (lang != 'ar' && touryLooksArabic(localized)) {
    return '';
  }
  return localized;
}

List<String> touryI18nSearchTerms(Map<String, String> i18n, String legacy) {
  final terms = <String>{legacy.trim()};
  terms.addAll(i18n.values.map((e) => e.trim()).where((e) => e.isNotEmpty));
  return terms.toList(growable: false);
}
