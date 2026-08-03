import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_content_locale.dart';
import '/core/toury_i18n_text.dart';

String touryCountryName(BuildContext context, CountriesRecord record) {
  final localeKey = touryContentLocaleFromContext(context);
  return touryLocalizedText(
    record.namesI18n,
    localeKey.startsWith('en') && record.naimEnglesh.trim().isNotEmpty
        ? record.naimEnglesh
        : record.naim,
    localeKey: localeKey,
  );
}

String touryCountryFlag(CountriesRecord record) {
  final raw = record.snapshotData['flagEmoji'] ?? record.snapshotData['flag'];
  return raw?.toString().trim() ?? '';
}

String touryCountryDisplayName(BuildContext context, CountriesRecord record) {
  final flag = touryCountryFlag(record);
  final name = touryCountryName(context, record);
  if (flag.isEmpty) return name;
  return '$flag $name';
}

String touryCountryDescription(BuildContext context, CountriesRecord record) {
  return record.osf.trim();
}

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

String touryVillageDescription(BuildContext context, VillagesRecord record) {
  return touryLocalizedText(
    record.osfI18n,
    record.osf,
    localeKey: touryContentLocaleFromContext(context),
  );
}
