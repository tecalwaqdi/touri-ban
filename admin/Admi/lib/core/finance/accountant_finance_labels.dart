import '/core/country/country_resolver.dart';
import '/core/finance/admin_finance_repository.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/core/finance/settlement_state_labels.dart';

/// Arabic accountant-facing labels (F2 / F2.1). Never expose raw enums in normal UI.
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
        return 'غير محدد';
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

  static String agentShareOfCommissionLabel() =>
      'حصة الوكيل من عمولة الشركة';

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

  static String countryHumanAr(String? countryPathOrId) {
    final raw = (countryPathOrId ?? '').trim();
    if (raw.isEmpty) return '—';
    return AdminFinanceRepository.instance.cachedLabel(
      'country:$raw',
      () => _countryHumanArUncached(raw),
    );
  }

  static String _countryHumanArUncached(String raw) {
    final id = raw.contains('/') ? raw.split('/').last : raw;
    final lower = id.toLowerCase();
    if (lower == CountryResolver.canonicalSaudiId ||
        CountryResolver.legacySaudiIds.contains(lower) ||
        lower.contains('saudi')) {
      return 'السعودية';
    }
    if (lower.contains('egypt') || lower == 'eg') return 'مصر';
    if (lower.contains('uae') || lower.contains('emirates')) {
      return 'الإمارات';
    }
    if (lower.contains('kuwait')) return 'الكويت';
    if (lower.contains('bahrain')) return 'البحرين';
    if (lower.contains('qatar')) return 'قطر';
    if (lower.contains('oman')) return 'عُمان';
    if (lower.contains('jordan')) return 'الأردن';
    if (lower.contains('iraq')) return 'العراق';
    if (lower.contains('niger') && !lower.contains('nigeria')) {
      return 'النيجر';
    }
    if (lower.contains('nigeria')) return 'نيجيريا';
    if (lower.contains('chad')) return 'تشاد';
    return id.replaceAll('_', ' ');
  }

  static String tripRefLabel(String orderId) {
    final id = orderId.trim();
    if (id.isEmpty) return '—';
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}…';
  }

  static String unavailableMoney() => 'غير متوفر';

  static String emDash() => '—';
}
