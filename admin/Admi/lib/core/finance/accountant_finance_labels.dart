import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/core/finance/settlement_state_labels.dart';

/// Arabic accountant-facing labels (F2). Never expose raw enums in normal UI.
abstract final class AccountantFinanceLabels {
  AccountantFinanceLabels._();

  static String dataQualityAr(FinancialDataQuality q) => switch (q) {
        FinancialDataQuality.complete => 'مكتملة ماليًا',
        FinancialDataQuality.partial => 'بيانات مالية ناقصة',
        FinancialDataQuality.unresolved => 'تحتاج مراجعة مالية',
      };

  static String paymentMethodAr(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.contains('cash') || s == 'نقدي') return 'نقدي';
    if (s.contains('online') || s.contains('card') || s.contains('إلكترون')) {
      return 'إلكتروني';
    }
    if (s.isEmpty) return 'غير محدد';
    return 'غير محدد';
  }

  static String paymentStatusAr(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    switch (s) {
      case 'paid':
      case 'captured':
        return 'مدفوع';
      case 'cash_collected':
        return 'محصّل نقدًا';
      case 'pending_cash':
      case 'cash_pending':
      case 'cash_due':
        return 'بانتظار التحصيل';
      case 'unpaid':
        return 'غير مدفوع';
      case 'processing':
        return 'قيد المعالجة';
      case 'refunded':
        return 'مسترد';
      case 'failed':
        return 'فشل الدفع';
      default:
        return s.isEmpty ? 'غير محدد' : 'غير محدد';
    }
  }

  static String collectionStatusAr({
    required bool cashChannel,
    required bool collected,
  }) {
    if (!cashChannel) return '—';
    return collected ? 'محصّل' : 'غير محصّل';
  }

  static String moneyHolderAr({
    required FinancialPaymentChannel channel,
    required bool operationallyCompleted,
    required bool cashCollected,
    required bool paymentPaid,
  }) {
    if (!operationallyCompleted) return '—';
    if (channel == FinancialPaymentChannel.cash) {
      if (cashCollected) return 'النقد لدى السائق';
      return 'لم يُحصّل بعد';
    }
    if (channel == FinancialPaymentChannel.online && paymentPaid) {
      return 'لدى الشركة / بوابة الدفع';
    }
    return '—';
  }

  static String dueDirectionAr({
    required FinancialPaymentChannel channel,
    required bool operationallyCompleted,
    required bool cashCollected,
    required bool paymentPaid,
  }) {
    if (!operationallyCompleted) return '—';
    if (channel == FinancialPaymentChannel.cash && cashCollected) {
      return 'مستحق للشركة على السائق';
    }
    if (channel == FinancialPaymentChannel.online && paymentPaid) {
      return 'مستحق للسائق على الشركة';
    }
    return '—';
  }

  /// Accountant settlement status — no developer workflow jargon.
  static String settlementStatusAr(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'settled':
      case 'complete':
      case 'completed':
        return 'مسددة';
      case 'partially_paid':
      case 'partial':
        return 'مسددة جزئيًا';
      case 'voided':
        return 'ملغاة';
      case 'draft':
      case 'open':
      case 'pending':
      case 'locked':
        return 'غير مسددة';
      case '':
        return 'غير مسددة';
      default:
        return SettlementStateLabels.statusAr(raw!);
    }
  }

  static String agentAttributionAr(FinancialAgentAttribution a) => switch (a) {
        FinancialAgentAttribution.confident => 'موثوق',
        FinancialAgentAttribution.legacy => 'قديم',
        FinancialAgentAttribution.missing => 'الوكيل التاريخي غير محدد',
      };

  static String tripOperationalStatusAr(String? statusCode) {
    final c = (statusCode ?? '').trim().toLowerCase();
    if (c == 'completed' || c == 'trip_completed') return 'مكتملة';
    if (c.startsWith('cancelled') || c.startsWith('canceled')) return 'ملغاة';
    if (c.contains('arrived')) return 'وصل السائق';
    if (c.contains('started') || c.contains('progress')) return 'جارية';
    if (c.contains('accepted') || c == 'pending_driver') return 'مقبولة';
    if (c.isEmpty) return 'غير محدد';
    return 'قيد التنفيذ';
  }

  static String unavailableMoney() => 'غير متوفر';

  static String emDash() => '—';
}
