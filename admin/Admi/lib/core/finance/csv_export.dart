import 'package:flutter/services.dart';

/// Escape a CSV cell and neutralize spreadsheet formula injection (=, +, -, @).
String financeCsvEscape(Object? value) {
  var s = value == null ? '' : '$value';
  if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) {
    s = "'$s";
  }
  if (s.contains('"') || s.contains(',') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

/// Internal CSV only — not a tax invoice. No ZATCA QR.
String financeCsvDocument({
  required String preparedBy,
  required String filters,
  required String currency,
  required String body,
}) {
  final generatedAt = DateTime.now().toUtc().toIso8601String();
  return [
    '# Internal accounting report — not a tax invoice. No ZATCA QR.',
    '# Generated at: $generatedAt',
    '# Prepared by: $preparedBy',
    '# Filters: $filters',
    '# Currency: $currency',
    body,
  ].join('\n');
}

Future<void> copyFinanceCsv(String csv) {
  return Clipboard.setData(ClipboardData(text: csv));
}
