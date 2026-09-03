import '/core/admin_currency.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/financial_state_labels.dart';
import '/core/finance/settlement_state_labels.dart';

/// Central Admin finance/ops presentation labels (Arabic production UI).
/// Prefer this over raw enums / English keys in widgets.
abstract final class AdminFinanceUiLabels {
  AdminFinanceUiLabels._();

  static String severityAr(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'critical':
        return 'حرجة';
      case 'high':
        return 'مرتفعة';
      case 'medium':
        return 'متوسطة';
      case 'low':
        return 'منخفضة';
      default:
        return 'غير مصنّفة';
    }
  }

  static String settlementStatusAr(String raw) =>
      SettlementStateLabels.statusAr(raw);

  static String periodStatusAr(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'open':
        return 'مفتوحة';
      case 'closed':
        return 'مغلقة';
      case 'locked':
        return 'مقفلة';
      default:
        return settlementStatusAr(raw);
    }
  }

  static String settlementDirectionAr(String raw) =>
      SettlementStateLabels.directionAr(raw);

  static String exceptionAr(String code) =>
      FinancialStateLabels.exceptionCodeAr(code);

  static String resetActionAr() => 'إعادة الضبط';

  static String orphanReportAr() => 'تقرير السجلات اليتيمة';

  static String orphanDetectionAr() => 'اكتشاف السجلات اليتيمة';

  static String receivablesAr() => 'المستحقات (على المندوبين)';

  static String payablesAr() => 'المستحقات (على الشركة)';

  static String collectedAr() => 'المحصّل';

  static String partiallyPaidAr() => 'مدفوع جزئيًا';

  static String diagnosticsTitleAr() => 'تشخيص النظام — للمسؤول التقني فقط';

  static String pilotBlockedAr() =>
      'تحذير تجريبي: لم يُضبط معتمد مالي مستقل';

  static String pilotOptionalWhenSelfApprovalAr() =>
      'الاعتماد الذاتي مفعّل — تحذير المعتمد المستقل معلوماتي فقط وليس حاجز تشغيل.';

  static String pilotMissingAr() => 'المعتمد المستقل: غير مضبوط';

  static String pilotConfiguredAr() => 'المعتمد المستقل: مضبوط';

  /// Formats minor-unit maps like `{SAR: 750}` → multi-line Arabic money.
  static String formatMinorByCurrency(
    Map<dynamic, dynamic>? byCurrency, {
    int fractionDigits = 2,
  }) {
    if (byCurrency == null || byCurrency.isEmpty) return '—';
    final parts = <String>[];
    byCurrency.forEach((k, v) {
      final code = k.toString();
      final minor = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      final symbol = AdminCurrency.symbolByCode[code] ?? code;
      final major = minor / 100.0;
      parts.add(
        AdminOrderMoneyDisplay.formatMajor(
          major,
          symbol: symbol,
          fractionDigits: fractionDigits,
        ),
      );
    });
    return parts.join(' · ');
  }

  static String formatCurrencyCountMap(Map<dynamic, dynamic>? byCurrency) {
    if (byCurrency == null || byCurrency.isEmpty) return '—';
    return byCurrency.entries
        .map((e) {
          final code = e.key.toString();
          final symbol = AdminCurrency.symbolByCode[code] ?? code;
          return '$symbol: ${e.value}';
        })
        .join(' · ');
  }
}
