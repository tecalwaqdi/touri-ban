import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_content_locale.dart';
import '/core/toury_i18n_text.dart';

/// Built-in landmark labels when Firestore `names_i18n` is incomplete.
/// Keys are normalized English/Arabic aliases (lowercase).
const Map<String, Map<String, String>> kTouryLandmarkNameCatalog = {
  'makkah gate': {
    'ar': 'بوابة مكة',
    'en': 'Makkah Gate',
    'ru': 'Ворота Мекки',
    'ky': 'Мекке дарбазасы',
  },
  'mecca gate': {
    'ar': 'بوابة مكة',
    'en': 'Makkah Gate',
    'ru': 'Ворота Мекки',
    'ky': 'Мекке дарбазасы',
  },
  'jeddah regional museum of archaeology and ethnography': {
    'ar': 'متحف جدة الإقليمي للآثار والتراث الشعبي',
    'en': 'Jeddah Regional Museum of Archaeology and Ethnography',
  },
  'biet nassif': {
    'ar': 'بيت نصيف',
    'en': 'Beit Nassif',
  },
  'beit nassif': {
    'ar': 'بيت نصيف',
    'en': 'Beit Nassif',
  },
  'بيت نصيف': {
    'ar': 'بيت نصيف',
    'en': 'Beit Nassif',
  },
  'al-sharif museum': {
    'ar': 'متحف الشريف',
    'en': 'Al-Sharif Museum',
  },
  'al sharif museum': {
    'ar': 'متحف الشريف',
    'en': 'Al-Sharif Museum',
  },
  'قصر شبرا التاريخي': {
    'ar': 'قصر شبرا التاريخي',
    'en': 'Shubra Historical Palace',
  },
  'shubra historical palace': {
    'ar': 'قصر شبرا التاريخي',
    'en': 'Shubra Historical Palace',
  },
  'shubra palace': {
    'ar': 'قصر شبرا التاريخي',
    'en': 'Shubra Historical Palace',
  },
  'abraj al-bait': {
    'ar': 'أبراج البيت',
    'en': 'Abraj Al-Bait',
    'ru': 'Абрадж аль-Байт',
    'ky': 'Абраж Аль-Байт',
  },
  'abraj al bait': {
    'ar': 'أبراج البيت',
    'en': 'Abraj Al-Bait',
    'ru': 'Абрадж аль-Байт',
    'ky': 'Абраж Аль-Байт',
  },
  'أبراج البيت': {
    'ar': 'أبراج البيت',
    'en': 'Abraj Al-Bait',
    'ru': 'Абрадж аль-Байт',
    'ky': 'Абраж Аль-Байт',
  },
  'kaaba': {
    'ar': 'الكعبة',
    'en': 'Kaaba',
    'ru': 'Кааба',
    'ky': 'Кааба',
  },
  'الكعبة': {
    'ar': 'الكعبة',
    'en': 'Kaaba',
    'ru': 'Кааба',
    'ky': 'Кааба',
  },
  'masjid al-haram': {
    'ar': 'المسجد الحرام',
    'en': 'Masjid al-Haram',
    'ru': 'Масджид аль-Харам',
    'ky': 'Масжид аль-Харам',
  },
  'المسجد الحرام': {
    'ar': 'المسجد الحرام',
    'en': 'Masjid al-Haram',
    'ru': 'Масджид аль-Харам',
    'ky': 'Масжид аль-Харам',
  },
  'جسر الجمرات': {
    'ar': 'جسر الجمرات',
    'en': 'Jamarat Bridge',
  },
  'jamarat bridge': {
    'ar': 'جسر الجمرات',
    'en': 'Jamarat Bridge',
  },
};

String _normalizeLandmarkKey(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('—', '-')
      .replaceAll('–', '-');
}

Map<String, String>? _catalogForLandmark(MkanRecord record) {
  final candidates = <String>{
    record.naim,
    ...record.namesI18n.values,
  }.map(_normalizeLandmarkKey).where((e) => e.isNotEmpty);

  for (final key in candidates) {
    final direct = kTouryLandmarkNameCatalog[key];
    if (direct != null) return direct;
  }

  // Partial match for titles like "Abraj Al-Bait (Makkah Clock Tower)".
  for (final key in candidates) {
    for (final entry in kTouryLandmarkNameCatalog.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
  }
  return null;
}

Map<String, String> _mergedLandmarkNames(MkanRecord record) {
  final merged = Map<String, String>.from(record.namesI18n);
  final catalog = _catalogForLandmark(record);
  if (catalog != null) {
    for (final entry in catalog.entries) {
      merged.putIfAbsent(entry.key, () => entry.value);
    }
  }
  return merged;
}

String touryMkanName(BuildContext context, MkanRecord record) {
  return touryLocalizedText(
    _mergedLandmarkNames(record),
    record.naim,
    localeKey: touryContentLocaleFromContext(context),
  );
}

String touryMkanDescription(BuildContext context, MkanRecord record) {
  return touryLocalizedText(
    record.osfI18n,
    record.osf,
    localeKey: touryContentLocaleFromContext(context),
  );
}

/// Address for UI — hides Arabic-only addresses when browsing non-Arabic.
String touryMkanAddress(BuildContext context, MkanRecord record) {
  return touryLocalizedAddress(
    record.address,
    localeKey: touryContentLocaleFromContext(context),
  );
}

List<String> touryMkanSearchTerms(MkanRecord record) {
  return touryI18nSearchTerms(_mergedLandmarkNames(record), record.naim);
}
