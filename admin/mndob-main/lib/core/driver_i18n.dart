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

final _walletAmountFilled = RegExp(
  r'^Your wallet balance must be at least (.+) to accept cash orders\.$',
);

/// Localize trip/wallet gate messages that may already include substituted args.
String driverTrMessage(BuildContext? context, String? message) {
  final msg = (message ?? '').trim();
  if (msg.isEmpty) return msg;
  final filled = _walletAmountFilled.firstMatch(msg);
  if (filled != null) {
    return driverTrNamed(
      context,
      'Your wallet balance must be at least {amount} to accept cash orders.',
      {'amount': filled.group(1)!},
    );
  }
  if (msg.contains('{amount}')) {
    return driverTrNamed(context, msg, const {'amount': '—'});
  }
  return driverTr(context, msg);
}

String driverTrOrFallback(
  BuildContext? context,
  String? message,
  String fallbackKey,
) {
  final msg = (message ?? '').trim();
  if (msg.isEmpty) return driverTr(context, fallbackKey);
  return driverTrMessage(context, msg);
}
