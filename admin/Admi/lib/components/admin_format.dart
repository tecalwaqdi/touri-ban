import 'package:intl/intl.dart';

import '/core/finance/admin_money_presentation.dart';
import '/core/finance/money_amount.dart';

/// Unified admin number / money / date formatting (LTR digits, no NaN/null flash).
abstract final class AdminFormat {
  AdminFormat._();

  static final _count = NumberFormat('#,##0');
  static final _pct = NumberFormat('#,##0.##');

  static const empty = '—';

  static String count(num? value) {
    if (value == null || value.isNaN) return empty;
    return _count.format(value.round());
  }

  static String money(MoneyAmount? amount, {int? minor, String? currency}) {
    if (amount != null) {
      return AdminOrderMoneyDisplay.formatMoneyAmount(amount);
    }
    if (minor == null || currency == null || currency.isEmpty) return empty;
    return AdminOrderMoneyDisplay.formatMoneyAmount(
      MoneyAmount(currency: currency, minorUnits: minor),
    );
  }

  static String moneyMinor(int? minor, String? currency) {
    if (minor == null || currency == null || currency.isEmpty) return empty;
    return money(null, minor: minor, currency: currency);
  }

  static String percent(num? value, {int digits = 1}) {
    if (value == null || value.isNaN) return empty;
    return '${_pct.format(value)}%';
  }

  static String date(DateTime? value, {bool withTime = false}) {
    if (value == null) return empty;
    final u = value.toUtc();
    if (withTime) {
      return DateFormat('yyyy-MM-dd HH:mm').format(u);
    }
    return DateFormat('yyyy-MM-dd').format(u);
  }

  static String dateIso(String? iso, {bool withTime = false}) {
    if (iso == null || iso.isEmpty) return empty;
    return date(DateTime.tryParse(iso)?.toUtc(), withTime: withTime);
  }
}
