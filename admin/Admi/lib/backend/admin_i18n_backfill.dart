import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/i18n/landmark_azure_translate.dart';
import '/core/i18n/landmark_i18n_plan.dart';

/// نتيجة تعبئة الترجمات للبيانات القديمة.
class I18nBackfillResult {
  const I18nBackfillResult({
    required this.landmarks,
    required this.cities,
    required this.villages,
    required this.countries,
    this.cars = 0,
    this.error,
    this.warnings = const [],
  });

  final int landmarks;
  final int cities;
  final int villages;
  final int countries;
  final int cars;
  final String? error;
  final List<String> warnings;

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

  /// Kept so the settings button stays wired. Landmarks use Azure, not Gemini.
  static Future<I18nBackfillResult> runGeminiTranslateBatch({
    int maxLandmarks = 15,
    I18nBackfillProgress? onProgress,
  }) =>
      runAzureTranslateBatch(
        maxLandmarks: maxLandmarks,
        onProgress: onProgress,
      );

  /// Translates missing or changed landmark name/description text for the
  /// seven app languages. One landmark failure does not stop the rest.
  static Future<I18nBackfillResult> runAzureTranslateBatch({
    int maxLandmarks = 15,
    I18nBackfillProgress? onProgress,
  }) async {
    var updated = 0;
    final failures = <String>[];
    DocumentSnapshot? lastDoc;
    var pages = 0;
    try {
      onProgress?.call('جاري البحث عن معالم تحتاج ترجمة…');
      while (updated < maxLandmarks && pages < 40) {
        pages++;
        Query query = FirebaseFirestore.instance
            .collection('mkan')
            .orderBy(FieldPath.documentId)
            .limit(40);
        if (lastDoc != null) query = query.startAfterDocument(lastDoc);
        final snap = await query.get();
        if (snap.docs.isEmpty) break;
        lastDoc = snap.docs.last;

        final pending = <_LandmarkAzureJob>[];
        for (final doc in snap.docs) {
          if (updated + pending.length >= maxLandmarks) break;
          final data = doc.data() as Map<String, dynamic>;
          final fields = _azureFieldsForMkan(doc.id, data);
          if (fields.isEmpty) continue;
          pending.add(_LandmarkAzureJob(doc.reference, fields));
        }

        for (var i = 0; i < pending.length; i += 10) {
          final chunk = pending.skip(i).take(10).toList();
          final fields = [for (final job in chunk) ...job.fields];
          List<LandmarkI18nFieldResult> results;
          try {
            results = await LandmarkAzureTranslate.translateFields(fields);
          } catch (error) {
            for (final job in chunk) {
              failures.add('${job.ref.id}: ${_shortError(error)}');
            }
            continue;
          }
          final byId = {for (final row in results) row.id: row};
          for (final job in chunk) {
            try {
              final updates = <String, dynamic>{};
              final name = byId['${job.ref.id}:name'];
              final osf = byId['${job.ref.id}:osf'];
              if (name != null && name.error != null) {
                failures.add('${job.ref.id}: ${name.error}');
              } else if (name != null && name.persistAuto) {
                updates['names_i18n'] = name.values;
                if (name.auto != null) updates['names_i18n_auto'] = name.auto;
              }
              if (osf != null && osf.error != null) {
                failures.add('${job.ref.id}: ${osf.error}');
              } else if (osf != null && osf.persistAuto) {
                updates['osf_i18n'] = osf.values;
                if (osf.auto != null) updates['osf_i18n_auto'] = osf.auto;
              }
              if (updates.isEmpty) continue;
              await job.ref.update(updates);
              updated++;
              onProgress?.call('تمت ترجمة $updated معلم');
            } catch (error) {
              failures.add('${job.ref.id}: ${_shortError(error)}');
            }
          }
        }

        if (snap.docs.length < 40) break;
      }

      onProgress?.call('اكتمل: $updated معلم');
      return I18nBackfillResult(
        landmarks: updated,
        cities: 0,
        villages: 0,
        countries: 0,
        warnings: failures,
      );
    } catch (e) {
      return I18nBackfillResult(
        landmarks: updated,
        cities: 0,
        villages: 0,
        countries: 0,
        error: 'توقفت الترجمة بعد $updated معلم',
        warnings: failures,
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

  static List<LandmarkI18nField> _azureFieldsForMkan(
    String docId,
    Map<String, dynamic> data,
  ) {
    final fields = <LandmarkI18nField>[];
    final name = _fieldFor(
      id: '$docId:name',
      legacy: (data['naim'] as String?)?.trim() ?? '',
      existing: _readStringMap(data['names_i18n']),
      auto: LandmarkAzureTranslate.readAuto(data['names_i18n_auto']),
      contentLocale: (data['content_locale'] as String?)?.trim() ?? '',
    );
    final description = _fieldFor(
      id: '$docId:osf',
      legacy: (data['osf'] as String?)?.trim() ?? '',
      existing: _readStringMap(data['osf_i18n']),
      auto: LandmarkAzureTranslate.readAuto(data['osf_i18n_auto']),
      contentLocale: (data['content_locale'] as String?)?.trim() ?? '',
    );
    if (name != null) fields.add(name);
    if (description != null) fields.add(description);
    return fields;
  }

  static LandmarkI18nField? _fieldFor({
    required String id,
    required String legacy,
    required Map<String, String> existing,
    required Map<String, dynamic>? auto,
    required String contentLocale,
  }) {
    final sourceLocale = _bulkSourceLocale(
      contentLocale: contentLocale,
      existing: existing,
      legacy: legacy,
    );
    final sourceText = (existing[sourceLocale] ?? legacy).trim();
    if (!needsLandmarkAzure(
      sourceLocale: sourceLocale,
      sourceText: sourceText,
      existing: existing,
      auto: auto,
    )) {
      return null;
    }
    return LandmarkI18nField(
      id: id,
      sourceLocale: sourceLocale,
      sourceText: sourceText,
      existing: existing,
      auto: auto,
    );
  }

  static String _bulkSourceLocale({
    required String contentLocale,
    required Map<String, String> existing,
    required String legacy,
  }) {
    final content = normalizeLandmarkLocale(contentLocale);
    if (kLandmarkAppLocales.contains(content) &&
        (existing[content] ?? '').isNotEmpty) {
      return content;
    }
    if (legacy.isNotEmpty && existing['ar'] == legacy) return 'ar';
    if (legacy.isNotEmpty && existing['en'] == legacy) return 'en';
    for (final lang in kLandmarkAppLocales) {
      if ((existing[lang] ?? '').isNotEmpty) return lang;
    }
    return content.isEmpty ? 'ar' : content;
  }

  static String _shortError(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) return 'فشلت الترجمة';
    return text.length > 160 ? text.substring(0, 160) : text;
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

class _LandmarkAzureJob {
  const _LandmarkAzureJob(this.ref, this.fields);

  final DocumentReference ref;
  final List<LandmarkI18nField> fields;
}
