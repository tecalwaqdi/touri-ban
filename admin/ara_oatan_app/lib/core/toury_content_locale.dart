import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_resolve_locale.dart';
import '/core/toury_i18n_text.dart';

/// مفتاح لغة المحتوى (Firestore) من لغة واجهة المستخدم الحالية.
String touryContentLocaleKey([Locale? locale]) {
  final resolved = locale ??
      (WidgetsBinding.instance.platformDispatcher.locales.isNotEmpty
          ? WidgetsBinding.instance.platformDispatcher.locales.first
          : touryFallbackLocale);
  return touryLocaleStorageKey(resolved);
}

String touryContentLocaleFromContext(BuildContext context) {
  try {
    return touryLocaleStorageKey(context.locale);
  } catch (_) {
    return touryContentLocaleKey(Localizations.localeOf(context));
  }
}

/// يعرض المعلم إذا وُجد اسم بلغة المستخدم (أو fallback).
bool touryMkanVisibleForUser(MkanRecord record, String userLocaleKey) {
  final name = touryLocalizedText(
    record.namesI18n,
    record.naim,
    localeKey: userLocaleKey,
  );
  return name.isNotEmpty;
}

List<MkanRecord> touryFilterMkanForDisplay(
  Iterable<MkanRecord> items,
  String userLocaleKey,
) {
  return items
      .where((m) => touryMkanVisibleForUser(m, userLocaleKey))
      .toList(growable: false);
}

// للتوافق مع الكود السابق.
@Deprecated('Use touryFilterMkanForDisplay')
List<MkanRecord> touryFilterMkanByLocale(
  Iterable<MkanRecord> items,
  String userLocaleKey,
) =>
    touryFilterMkanForDisplay(items, userLocaleKey);
