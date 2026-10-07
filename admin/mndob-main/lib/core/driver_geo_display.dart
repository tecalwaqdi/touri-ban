import '/backend/schema/cities_record.dart';
import '/backend/schema/countries_record.dart';
import '/backend/schema/villages_record.dart';
import '/core/driver_i18n_text.dart';
import '/core/driver_resolve_locale.dart';
import '/flutter_flow/internationalization.dart';

/// Locale key for geo content written into FFAppState display fields.
String driverActiveContentLocaleKey() {
  final stored = FFLocalizations.getStoredLocale();
  if (stored != null) {
    return driverLocaleStorageKey(stored);
  }
  return 'en';
}

String driverLocalizedCountryLabel(
  CountriesRecord country, [
  String? localeKey,
]) {
  final key = localeKey ?? driverActiveContentLocaleKey();
  final lang = key.split(RegExp(r'[_-]')).first.toLowerCase();
  final legacy = (lang == 'ar' || country.naimEnglesh.trim().isEmpty)
      ? country.naim
      : country.naimEnglesh;
  final localized = driverLocalizedText(
    country.namesI18n,
    legacy,
    localeKey: key,
  );
  if (localized.isNotEmpty) return localized;
  if (country.naimEnglesh.trim().isNotEmpty &&
      (lang == 'ar' || lang == 'ur' || !driverLooksArabic(country.naimEnglesh))) {
    return country.naimEnglesh.trim();
  }
  if (lang == 'ar' || lang == 'ur') return country.naim.trim();
  return '';
}

String driverLocalizedRegionLabel(
  CitiesRecord region, [
  String? localeKey,
]) {
  return driverLocalizedText(
    region.namesI18n,
    region.naim,
    localeKey: localeKey ?? driverActiveContentLocaleKey(),
  );
}

String driverLocalizedCityLabel(
  VillagesRecord city, [
  String? localeKey,
]) {
  return driverSearchingAreaLabel(
    localeKey: localeKey ?? driverActiveContentLocaleKey(),
    namesI18n: city.namesI18n,
    legacyNaim: city.naim,
  );
}

/// Company / transport-org display from raw Firestore map.
String driverLocalizedMapLabel(
  Map<String, dynamic> data, {
  String? localeKey,
  String fallbackId = '',
}) {
  final key = localeKey ?? driverActiveContentLocaleKey();
  final i18n = driverParseI18nMap(data['names_i18n']);
  final naim = (data['naim'] as String?)?.trim() ?? '';
  final name = (data['name'] as String?)?.trim() ?? '';
  final companyName = (data['company_name'] as String?)?.trim() ?? '';
  final eng = (data['naimEnglesh'] as String?)?.trim() ??
      (data['name_en'] as String?)?.trim() ??
      '';
  final lang = key.split(RegExp(r'[_-]')).first.toLowerCase();
  final legacy = (lang == 'ar' || eng.isEmpty)
      ? (naim.isNotEmpty ? naim : (name.isNotEmpty ? name : companyName))
      : eng;
  final localized = driverLocalizedText(i18n, legacy, localeKey: key);
  if (localized.isNotEmpty) return localized;
  if (eng.isNotEmpty &&
      (lang == 'ar' || lang == 'ur' || !driverLooksArabic(eng))) {
    return eng;
  }
  if (lang == 'ar' || lang == 'ur') {
    if (naim.isNotEmpty) return naim;
    if (name.isNotEmpty) return name;
    if (companyName.isNotEmpty) return companyName;
  }
  return fallbackId;
}
