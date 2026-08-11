import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// ترجمة واجهة المندوب عبر EasyLocalization (نفس مسار تطبيق المستخدم).
/// المفتاح الإنجليزي يطابق مفتاح JSON في assets/langs.
/// [context] اختياري — الترجمة تعتمد على EasyLocalization العام.
String driverTr(BuildContext? context, String key) {
  if (key.isEmpty) return key;
  try {
    final translated = key.tr();
    if (translated.isNotEmpty) return translated;
  } catch (_) {
    // EasyLocalization not ready — fall through.
  }
  return key;
}

/// قالب مع متغيرات: `"Welcome, {name}"` + `{'name': 'Ahmed'}`.
String driverTrNamed(
  BuildContext? context,
  String template,
  Map<String, String> params,
) {
  if (template.isEmpty) return template;
  try {
    final translated = template.tr(namedArgs: params);
    if (translated.isNotEmpty) return translated;
  } catch (_) {
    var text = template;
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }
  var text = template;
  for (final entry in params.entries) {
    text = text.replaceAll('{${entry.key}}', entry.value);
  }
  return text;
}
