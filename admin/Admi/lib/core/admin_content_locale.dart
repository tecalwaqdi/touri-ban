import 'package:flutter/material.dart';

import '/flutter_flow/internationalization.dart';

/// مفتاح لغة المحتوى عند إنشاء معلم/مدينة من لوحة الإدارة.
String adminContentLocaleKey(BuildContext context) {
  final locale = FFLocalizations.of(context).locale;
  if (locale.scriptCode != null && locale.scriptCode!.isNotEmpty) {
    return '${locale.languageCode}_${locale.scriptCode}';
  }
  return locale.languageCode;
}
