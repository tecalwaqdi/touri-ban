import 'package:flutter/material.dart';

import '/core/admin_content_locale.dart';
import '/core/i18n/admin_i18n_translate_service.dart';
import '/core/i18n/toury_i18n_locales.dart';
import '/core/i18n/toury_i18n_text.dart';

/// يبني خريطة ترجمة — يترجم تلقائياً إن لم تُملأ كل اللغات.
Future<Map<String, String>> adminEnsureI18nMap({
  required BuildContext context,
  required String sourceText,
  required String fieldLabel,
  Map<String, String>? existing,
  bool autoTranslate = true,
}) async {
  final sourceLocale = adminContentLocaleKey(context);
  final source = sourceText.trim();
  final map = touryBuildI18nMap(
    values: existing ?? const {},
    sourceLocale: sourceLocale,
    sourceText: source,
  );

  if (!autoTranslate || source.isEmpty) return map;

  final missing = touryI18nLocaleKeys.where((k) => !(map[k]?.trim().isNotEmpty ?? false));
  if (missing.length <= 2) return map;

  final translated = await AdminI18nTranslateService.translateText(
    context: context,
    sourceLocale: sourceLocale,
    sourceText: source,
    fieldLabel: fieldLabel,
  );
  if (translated != null) {
    map.addAll(translated);
  }
  return map;
}

String adminLegacyFromI18n(Map<String, String> map, String fallback) =>
    touryPrimaryLegacyText(map, fallback);
