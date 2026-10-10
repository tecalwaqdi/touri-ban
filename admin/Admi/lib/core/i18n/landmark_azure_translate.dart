import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/i18n/landmark_i18n_plan.dart';

class LandmarkI18nField {
  const LandmarkI18nField({
    required this.id,
    required this.sourceLocale,
    required this.sourceText,
    required this.existing,
    this.auto,
  });

  final String id;
  final String sourceLocale;
  final String sourceText;
  final Map<String, String> existing;
  final Map<String, dynamic>? auto;
}

class LandmarkI18nFieldResult {
  const LandmarkI18nFieldResult({
    required this.id,
    required this.values,
    required this.patch,
    required this.persistAuto,
    this.auto,
    this.error,
  });

  final String id;
  final Map<String, String> values;
  final Map<String, String> patch;
  final Map<String, dynamic>? auto;
  final bool persistAuto;
  final String? error;
}

/// Calls the Admin Cloud Function. The Azure key stays in Firebase Secrets.
abstract final class LandmarkAzureTranslate {
  LandmarkAzureTranslate._();

  static Map<String, dynamic>? readAuto(dynamic raw) {
    if (raw is! Map) return null;
    final values = <String, String>{};
    final valuesRaw = raw['values'];
    if (valuesRaw is Map) {
      valuesRaw.forEach((key, value) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) values[key.toString()] = text;
      });
    }
    return {
      'sourceLocale': raw['sourceLocale']?.toString() ?? '',
      'sourceHash': raw['sourceHash']?.toString() ?? '',
      'values': values,
    };
  }

  static Future<List<LandmarkI18nFieldResult>> translateFields(
    List<LandmarkI18nField> fields,
  ) async {
    final bases = <Map<String, String>>[];
    final payload = <Map<String, dynamic>>[];
    for (final field in fields) {
      final locale = normalizeLandmarkLocale(field.sourceLocale);
      final sourceLocale = locale.isEmpty ? 'ar' : locale;
      final base = withLandmarkSourceText(
        field.existing,
        sourceLocale: sourceLocale,
        sourceText: field.sourceText,
      );
      bases.add(base);
      payload.add({
        'id': field.id,
        'sourceLocale': sourceLocale,
        'sourceText': field.sourceText.trim(),
        'existing': base,
        if (field.auto != null) 'auto': field.auto,
      });
    }

    List<Map<String, dynamic>> rows;
    try {
      rows = await CloudFunctionsClient.translateLandmarkTexts(payload);
    } catch (error) {
      return [
        for (var i = 0; i < fields.length; i++)
          LandmarkI18nFieldResult(
            id: fields[i].id,
            values: bases[i],
            patch: const {},
            auto: fields[i].auto,
            persistAuto: false,
            error: _safeError(error),
          ),
      ];
    }

    final byId = <String, Map<String, dynamic>>{
      for (final row in rows) row['id']?.toString() ?? '': row,
    };
    return [
      for (var i = 0; i < fields.length; i++)
        _fromRow(fields[i], bases[i], byId[fields[i].id]),
    ];
  }

  static LandmarkI18nFieldResult _fromRow(
    LandmarkI18nField field,
    Map<String, String> base,
    Map<String, dynamic>? row,
  ) {
    if (row == null || row['ok'] != true) {
      return LandmarkI18nFieldResult(
        id: field.id,
        values: base,
        patch: const {},
        auto: field.auto,
        persistAuto: false,
        error: row?['error']?.toString() ?? 'فشلت الترجمة التلقائية',
      );
    }
    final locale = normalizeLandmarkLocale(field.sourceLocale);
    final sourceLocale = locale.isEmpty ? 'ar' : locale;
    final patch = _stringMap(row['patch']);
    patch.remove(sourceLocale);
    final merged = mergeLandmarkI18nPatch(
      base,
      patch,
      sourceLocale: sourceLocale,
    );
    return LandmarkI18nFieldResult(
      id: field.id,
      values: merged,
      patch: patch,
      auto: row['auto'] is Map ? readAuto(row['auto']) : field.auto,
      persistAuto: patch.isNotEmpty,
      error: null,
    );
  }

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, String>{};
    raw.forEach((key, value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) out[key.toString()] = text;
    });
    return out;
  }

  static String _safeError(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) return 'فشلت الترجمة التلقائية';
    return text.length > 180 ? text.substring(0, 180) : text;
  }
}
