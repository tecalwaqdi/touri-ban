import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_content_locale.dart';
import '/core/toury_i18n_text.dart';

String touryCityName(BuildContext context, CitiesRecord record) {
  return touryLocalizedText(
    record.namesI18n,
    record.naim,
    localeKey: touryContentLocaleFromContext(context),
  );
}

String touryCityDescription(BuildContext context, CitiesRecord record) {
  return touryLocalizedText(
    record.osfI18n,
    record.osf,
    localeKey: touryContentLocaleFromContext(context),
  );
}

String touryVillageName(BuildContext context, VillagesRecord record) {
  return touryLocalizedText(
    record.namesI18n,
    record.naim,
    localeKey: touryContentLocaleFromContext(context),
  );
}

String touryCountryName(BuildContext context, CountriesRecord record) {
  return touryLocalizedText(
    record.namesI18n,
    record.naim,
    localeKey: touryContentLocaleFromContext(context),
  );
}

String touryCountryNameEnFallback(BuildContext context, CountriesRecord record) {
  final locale = touryContentLocaleFromContext(context);
  if (locale == 'ar') return record.naim;
  final fromMap = touryLocalizedText(
    record.namesI18n,
    record.naimEnglesh.isNotEmpty ? record.naimEnglesh : record.naim,
    localeKey: locale,
  );
  return fromMap;
}
