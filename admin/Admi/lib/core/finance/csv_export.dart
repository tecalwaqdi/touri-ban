import 'package:flutter/services.dart';

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
