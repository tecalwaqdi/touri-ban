import 'dart:convert';

import 'package:flutter/material.dart';

import '/backend/gemini/gemini.dart';
import '/core/i18n/toury_i18n_locales.dart';

/// ترجمة تلقائية لحقول المحتوى عبر Gemini (Cloud Function).
abstract final class AdminI18nTranslateService {
  AdminI18nTranslateService._();

  static Future<Map<String, String>?> translateText({
    required BuildContext context,
    required String sourceLocale,
    required String sourceText,
    required String fieldLabel,
  }) async {
    final source = sourceText.trim();
    if (source.isEmpty) return null;

    final keys = touryI18nLocaleKeys.join(', ');
    final prompt = '''
You are a professional translator for a tourism app.
Translate the following "$fieldLabel" into ALL of these locale keys: $keys
Source locale: $sourceLocale
Source text: "$source"

Rules:
- Return ONLY a valid JSON object.
- Keys must be exactly: $keys
- Values must be natural translations for tourists.
- Keep proper nouns when appropriate.
- No markdown, no explanation.

Example format:
{"ar":"...","en":"...","tr":"..."}
''';

    final raw = await geminiGenerateText(context, prompt);
    if (raw == null || raw.trim().isEmpty) return null;
    return _parseJsonMap(raw, sourceLocale: sourceLocale, sourceText: source);
  }

  static Future<Map<String, Map<String, String>>?> translateFields({
    required BuildContext context,
    required String sourceLocale,
    required Map<String, String> fields,
  }) async {
    final nonEmpty = <String, String>{};
    fields.forEach((k, v) {
      final t = v.trim();
      if (t.isNotEmpty) nonEmpty[k] = t;
    });
    if (nonEmpty.isEmpty) return null;

    final keys = touryI18nLocaleKeys.join(', ');
    final fieldsJson = jsonEncode(nonEmpty);
    final prompt = '''
You are a professional translator for a tourism app.
Translate each field below into ALL locale keys: $keys
Source locale: $sourceLocale
Fields (JSON): $fieldsJson

Return ONLY valid JSON:
{
  "fieldName": {"ar":"...","en":"...","tr":"..."},
  ...
}
Use the same field names as keys in the input. Locale keys must be: $keys
No markdown.
''';

    final raw = await geminiGenerateText(context, prompt);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final cleaned = _stripMarkdownJson(raw);
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map) return null;
      final out = <String, Map<String, String>>{};
      decoded.forEach((fieldKey, value) {
        if (value is Map) {
          final map = <String, String>{};
          value.forEach((k, v) {
            final text = v?.toString().trim() ?? '';
            if (text.isNotEmpty) map[k.toString()] = text;
          });
          if (map.isNotEmpty) out[fieldKey.toString()] = map;
        }
      });
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _parseJsonMap(
    String raw, {
    required String sourceLocale,
    required String sourceText,
  }) {
    try {
      final cleaned = _stripMarkdownJson(raw);
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map) {
        return {sourceLocale: sourceText};
      }
      final out = <String, String>{};
      decoded.forEach((k, v) {
        final text = v?.toString().trim() ?? '';
        if (text.isNotEmpty) out[k.toString()] = text;
      });
      out.putIfAbsent(sourceLocale, () => sourceText);
      return out;
    } catch (_) {
      return {sourceLocale: sourceText};
    }
  }

  static String _stripMarkdownJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      text = text.replaceFirst(RegExp(r'\n?```$'), '');
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }
}
