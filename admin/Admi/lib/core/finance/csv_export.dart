import 'package:flutter/services.dart';

import '/core/finance/admin_finance_date_range.dart';

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
///
/// Timestamps shown to accountants are Asia/Riyadh.
String financeCsvDocument({
  required String preparedBy,
  required String filters,
  required String currency,
  required String body,
  DateTime? generatedAtUtc,
}) {
  final at = AdminFinanceRiyadhClock.formatDateTime(
    generatedAtUtc ?? DateTime.now().toUtc(),
  );
  return [
    '# Internal accounting report — not a tax invoice / تقرير محاسبي داخلي — ليس فاتورة ضريبية',
    '# No ZATCA QR',
    '# Generated (Riyadh): $at / تم الإنشاء (الرياض): $at',
    '# Prepared by: $preparedBy / أعدّه: $preparedBy',
    '# Filters: $filters / الفلاتر: $filters',
    '# Currency: $currency / العملة: $currency',
    body,
  ].join('\n');
}

Future<void> copyFinanceCsv(String csv) {
  return Clipboard.setData(ClipboardData(text: csv));
}
