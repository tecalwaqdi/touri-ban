import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/i18n/toury_i18n_locales.dart';

/// نتيجة تعبئة الترجمات للبيانات القديمة.
class I18nBackfillResult {
  const I18nBackfillResult({
    required this.landmarks,
    required this.cities,
    required this.villages,
    required this.countries,
    this.cars = 0,
    this.error,
  });

  final int landmarks;
  final int cities;
  final int villages;
  final int countries;
  final int cars;
  final String? error;

  bool get success => error == null;
  int get total => landmarks + cities + villages + countries + cars;
}

typedef I18nBackfillProgress = void Function(String message);

/// يملأ `names_i18n` و `osf_i18n` من الحقول القديمة (`naim`, `osf`, `naimEnglesh`).
abstract final class AdminI18nBackfill {
  AdminI18nBackfill._();

  static Future<I18nBackfillResult> run({
    int batchSize = 400,
    I18nBackfillProgress? onProgress,
  }) async {
    try {
      onProgress?.call('بدء تعبئة ترجمات المعالم…');
      final landmarks = await _backfillCollection(
        collection: 'mkan',
        batchSize: batchSize,
        onProgress: (n) => onProgress?.call('معالم: $n'),
        buildUpdates: _updatesForMkan,
      );

      onProgress?.call('تعبئة ترجمات المناطق…');
      final cities = await _backfillCollection(
        collection: 'cities',
        batchSize: batchSize,
        onProgress: (n) => onProgress?.call('مناطق: $n'),
        buildUpdates: _updatesForTextFields,
      );

      onProgress?.call('تعبئة ترجمات المدن…');
      final villages = await _backfillCollection(
        collection: 'villages',
        batchSize: batchSize,
        onProgress: (n) => onProgress?.call('مدن: $n'),
        buildUpdates: _updatesForTextFields,
      );

      onProgress?.call('تعبئة ترجمات الدول…');
      final countries = await _backfillCollection(
        collection: 'countries',
        batchSize: batchSize,
        onProgress: (n) => onProgress?.call('دول: $n'),
        buildUpdates: _updatesForCountry,
      );

      onProgress?.call('تعبئة ترجمات أنواع المركبات…');
      final cars = await _backfillCollection(
        collection: 'type_car',
        batchSize: batchSize,
        onProgress: (n) => onProgress?.call('مركبات: $n'),
        buildUpdates: _updatesForTypeCar,
      );

      onProgress?.call(
        'اكتمل: $landmarks معلم، $cities منطقة، $villages مدينة، $countries دولة، $cars مركبة',
      );

      return I18nBackfillResult(
        landmarks: landmarks,
        cities: cities,
        villages: villages,
        countries: countries,
        cars: cars,
      );
    } catch (e) {
      return I18nBackfillResult(
        landmarks: 0,
        cities: 0,
        villages: 0,
        countries: 0,
        error: e.toString(),
      );
    }
  }

  /// يترجم أسماء معالم ناقصة الترجمة عبر Gemini (دفعات صغيرة).
  static Future<I18nBackfillResult> runGeminiTranslateBatch({
    int maxLandmarks = 15,
    I18nBackfillProgress? onProgress,
  }) async {
    try {
      onProgress?.call('جاري البحث عن معالم تحتاج ترجمة…');
      final ref = FirebaseFirestore.instance.collection('mkan');
      final snap = await ref.orderBy(FieldPath.documentId).limit(500).get();

      var updated = 0;
      for (final doc in snap.docs) {
        if (updated >= maxLandmarks) break;

        final data = doc.data();
        final naim = (data['naim'] as String?)?.trim() ?? '';
        if (naim.isEmpty) continue;

        final existing = _readStringMap(data['names_i18n']);
        if (_hasFullLocales(existing)) continue;

        onProgress?.call('ترجمة: $naim');
        final sourceLocale = existing['ar'] == naim
            ? 'ar'
            : (existing['en'] != null ? 'en' : 'ar');
        final sourceText = existing[sourceLocale] ?? naim;

        final translated = await _translateWithGemini(
          sourceLocale: sourceLocale,
          sourceText: sourceText,
          fieldLabel: 'landmark name',
        );
        if (translated == null || translated.isEmpty) continue;

        final merged = {...existing, ...translated};
        await doc.reference.update({'names_i18n': merged});
        updated++;
      }

      onProgress?.call('اكتمل: $updated معلم');
      return I18nBackfillResult(
        landmarks: updated,
        cities: 0,
        villages: 0,
        countries: 0,
      );
    } catch (e) {
      return I18nBackfillResult(
        landmarks: 0,
        cities: 0,
        villages: 0,
        countries: 0,
        error: e.toString(),
      );
    }
  }

  static Map<String, String> _readStringMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, String>{};
    raw.forEach((k, v) {
      final text = v?.toString().trim() ?? '';
      if (text.isNotEmpty) out[k.toString()] = text;
    });
    return out;
  }

  static bool _hasFullLocales(Map<String, String> map) {
    if (map.isEmpty) return false;
    for (final key in touryI18nLocaleKeys) {
      if ((map[key] ?? '').isEmpty) return false;
    }
    return true;
  }

  static Future<Map<String, String>?> _translateWithGemini({
    required String sourceLocale,
    required String sourceText,
    required String fieldLabel,
  }) async {
    final keys = touryI18nLocaleKeys.join(', ');
    final prompt = '''
You are a professional translator for a tourism app.
Translate the following "$fieldLabel" into ALL of these locale keys: $keys
Source locale: $sourceLocale
Source text: "$sourceText"

Rules:
- Return ONLY a valid JSON object.
- Keys must be exactly: $keys
- Values must be natural translations for tourists.
- No markdown, no explanation.
''';

    final raw = await CloudFunctionsClient.geminiGenerateText(prompt);
    if (raw == null || raw.trim().isEmpty) return null;
    return _parseJsonMap(raw, sourceLocale: sourceLocale, sourceText: sourceText);
  }

  static Map<String, String> _parseJsonMap(
    String raw, {
    required String sourceLocale,
    required String sourceText,
  }) {
    try {
      var text = raw.trim();
      if (text.startsWith('```')) {
        text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
        text = text.replaceFirst(RegExp(r'\n?```$'), '');
      }
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        text = text.substring(start, end + 1);
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        return {sourceLocale: sourceText};
      }
      final out = <String, String>{};
      decoded.forEach((k, v) {
        final value = v?.toString().trim() ?? '';
        if (value.isNotEmpty) out[k.toString()] = value;
      });
      out.putIfAbsent(sourceLocale, () => sourceText);
      return out;
    } catch (_) {
      return {sourceLocale: sourceText};
    }
  }

  static Future<int> _backfillCollection({
    required String collection,
    required int batchSize,
    required Map<String, dynamic> Function(Map<String, dynamic> data)
        buildUpdates,
    void Function(int updated)? onProgress,
  }) async {
    final ref = FirebaseFirestore.instance.collection(collection);
    var updated = 0;
    DocumentSnapshot? lastDoc;

    while (true) {
      Query query = ref.orderBy(FieldPath.documentId).limit(batchSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      var batchCount = 0;

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final updates = buildUpdates(data);
        if (updates.isEmpty) continue;
        batch.update(doc.reference, updates);
        batchCount++;
        updated++;
      }

      if (batchCount > 0) {
        await batch.commit();
        onProgress?.call(updated);
      }

      lastDoc = snap.docs.last;
      if (snap.docs.length < batchSize) break;
    }

    return updated;
  }

  static Map<String, dynamic> _updatesForMkan(Map<String, dynamic> data) {
    final naim = (data['naim'] as String?)?.trim() ?? '';
    final osf = (data['osf'] as String?)?.trim() ?? '';
    final locale = (data['content_locale'] as String?)?.trim();
    final updates = <String, dynamic>{};

    if (data['names_i18n'] == null && naim.isNotEmpty) {
      updates['names_i18n'] = _nameMap(naim: naim, contentLocale: locale);
    }
    if (data['osf_i18n'] == null && osf.isNotEmpty) {
      updates['osf_i18n'] = _nameMap(naim: osf, contentLocale: locale);
    }
    return updates;
  }

  static Map<String, dynamic> _updatesForTextFields(Map<String, dynamic> data) {
    final naim = (data['naim'] as String?)?.trim() ?? '';
    final osf = (data['osf'] as String?)?.trim() ?? '';
    final updates = <String, dynamic>{};

    if (data['names_i18n'] == null && naim.isNotEmpty) {
      updates['names_i18n'] = _nameMap(naim: naim);
    }
    if (data['osf_i18n'] == null && osf.isNotEmpty) {
      updates['osf_i18n'] = _nameMap(naim: osf);
    }
    return updates;
  }

  static Map<String, dynamic> _updatesForCountry(Map<String, dynamic> data) {
    final naim = (data['naim'] as String?)?.trim() ?? '';
    final naimEnglesh = (data['naimEnglesh'] as String?)?.trim() ?? '';
    if (data['names_i18n'] != null || naim.isEmpty) return {};

    final map = <String, String>{'ar': naim};
    if (naimEnglesh.isNotEmpty) {
      map['en'] = naimEnglesh;
    }
    return {'names_i18n': map};
  }

  static Map<String, dynamic> _updatesForTypeCar(Map<String, dynamic> data) {
    final naim = (data['naim'] as String?)?.trim() ?? '';
    if (data['names_i18n'] != null || naim.isEmpty) return {};
    return {
      'names_i18n': _nameMap(naim: naim),
    };
  }

  static Map<String, String> _nameMap({
    required String naim,
    String? contentLocale,
  }) {
    final map = <String, String>{'ar': naim};
    if (contentLocale != null &&
        contentLocale.isNotEmpty &&
        contentLocale != 'ar') {
      map[contentLocale] = naim;
    }
    return map;
  }
}
