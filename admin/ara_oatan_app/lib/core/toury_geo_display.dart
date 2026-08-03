import '/backend/backend.dart';
import '/core/toury_i18n_text.dart';
import '/flutter_flow/internationalization.dart';
import '/core/toury_resolve_locale.dart';

/// Locale key for content written into FFAppState display fields.
String touryActiveContentLocaleKey() {
  final stored = FFLocalizations.getStoredLocale();
  if (stored != null) {
    return touryLocaleStorageKey(stored);
  }
  return 'en';
}

String touryLocalizedCountryLabel(CountriesRecord country, [String? localeKey]) {
  final key = localeKey ?? touryActiveContentLocaleKey();
  final legacy =
      key == 'ar' || country.naimEnglesh.isEmpty ? country.naim : country.naimEnglesh;
  return touryLocalizedText(
    country.namesI18n,
    legacy,
    localeKey: key,
  );
}

String touryLocalizedVillageLabel(VillagesRecord village, [String? localeKey]) {
  return touryLocalizedText(
    village.namesI18n,
    village.naim,
    localeKey: localeKey ?? touryActiveContentLocaleKey(),
  );
}

String touryLocalizedCityCiteLabel(VillagesRecord village, [String? localeKey]) {
  // Region/city cite text — fall back to village name.
  final key = localeKey ?? touryActiveContentLocaleKey();
  final cite = village.naimciteText.trim();
  if (cite.isEmpty) {
    return touryLocalizedVillageLabel(village, key);
  }
  // Prefer names_i18n for the village; cite may be Arabic-only admin text.
  final localizedVillage = touryLocalizedVillageLabel(village, key);
  if (key != 'ar' && _looksArabic(cite) && !_looksArabic(localizedVillage)) {
    return localizedVillage;
  }
  return cite;
}

bool _looksArabic(String value) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(value);
