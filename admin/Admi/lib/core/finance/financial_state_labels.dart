import '/core/finance/financial_accounting_engine.dart';

/// Arabic user-facing labels for financial classification (not raw enum names).
abstract final class FinancialStateLabels {
  FinancialStateLabels._();

  static String lifecycleAr(FinancialLifecycle lc) => switch (lc) {
        FinancialLifecycle.completed => 'مكتملة',
        FinancialLifecycle.cancelled => 'ملغاة',
        FinancialLifecycle.expired => 'منتهية',
        FinancialLifecycle.pendingPayment => 'بانتظار الدفع',
        FinancialLifecycle.active => 'نشطة',
        FinancialLifecycle.unknown => 'غير معروف',
      };

  static String paymentAr(FinancialPaymentState p) => switch (p) {
        FinancialPaymentState.paid => 'مدفوع إلكترونيًا',
        FinancialPaymentState.cashCollected => 'نقد محصّل',
        FinancialPaymentState.captured => 'محجوز',
        FinancialPaymentState.pendingCash => 'بانتظار التحصيل النقدي',
        FinancialPaymentState.unpaid => 'غير مدفوع',
        FinancialPaymentState.processing => 'قيد المعالجة',
        FinancialPaymentState.failed => 'فشل الدفع',
        FinancialPaymentState.refunded => 'مسترد',
        FinancialPaymentState.unknown => 'غير معروف',
      };

  static String channelAr(FinancialPaymentChannel c) => switch (c) {
        FinancialPaymentChannel.cash => 'نقدي',
        FinancialPaymentChannel.online => 'إلكتروني',
        FinancialPaymentChannel.unknown => 'غير معروف',
      };

  static String bucketAr(FinancialCollectionBucket b) => switch (b) {
        FinancialCollectionBucket.completedAndCollected => 'مكتملة ومحصّلة',
        FinancialCollectionBucket.paidButNotCompleted => 'مدفوعة وغير مكتملة',
        FinancialCollectionBucket.completedButNotCollected =>
          'مكتملة بانتظار التحصيل',
        FinancialCollectionBucket.pendingPayment => 'بانتظار الدفع',
        FinancialCollectionBucket.cancelledOrExpired => 'ملغاة/منتهية',
        FinancialCollectionBucket.other => 'أخرى',
      };

  static String confidenceAr(FinancialConfidence c) => switch (c) {
        FinancialConfidence.high => 'مؤكد',
        FinancialConfidence.derived => 'مشتق',
        FinancialConfidence.incomplete => 'ناقص',
      };

  /// Combined financial state for table display.
  static String financialStatusAr(FinancialOrderLine line) {
    if (line.bucket == FinancialCollectionBucket.cancelledOrExpired) {
      return 'غير قابل للفوترة';
    }
    if (line.bucket == FinancialCollectionBucket.completedButNotCollected) {
      return 'بانتظار التحصيل';
    }
    if (line.bucket == FinancialCollectionBucket.completedAndCollected) {
      return 'محاسبة مكتملة';
    }
    if (line.confidence == FinancialConfidence.incomplete) {
      return 'بيانات مالية ناقصة';
    }
    return bucketAr(line.bucket);
  }

  static String legacyLedgerTypeAr(String raw) {
    final t = raw.trim().toLowerCase();
    if (t == 'company_payment') return 'دفعة شركة (سجل قديم)';
    if (t == 'admin_adjustment') return 'تعديل إداري';
    if (t == 'wallet_adjustment') return 'تعديل محفظة';
    return 'سجل مالي قديم';
  }

  static String exceptionCodeAr(String code) {
    switch (code) {
      case 'INCOMPLETE_FINANCIAL_RECORD':
        return 'بيانات مالية ناقصة';
      case 'CANCELLED_WITH_STALE_PENDING_CASH':
        return 'ملغاة مع تحصيل نقدي قديم';
      case 'COLLECTED_BEFORE_COMPLETED':
        return 'محصّل قبل الاكتمال';
      case 'ONLINE_PAID_NOT_COMPLETED':
        return 'مدفوع إلكترونيًا وغير مكتمل';
      case 'DRIVER_NET_MISSING':
        return 'صافي المندوب ناقص';
      case 'PLATFORM_FEE_MISSING':
        return 'عمولة المنصة ناقصة';
      case 'VAT_INVALID':
        return 'ضريبة غير صالحة';
      case 'MONEY_MISMATCH':
        return 'عدم تطابق مالي';
      case 'UNKNOWN_PAYMENT_METHOD':
        return 'طريقة دفع غير معروفة';
      case 'AGENT_ATTRIBUTION_MISSING':
        return 'إسناد الوكيل ناقص';
      case 'AGENT_RATE_MISSING':
        return 'نسبة الوكيل ناقصة';
      case 'SETTLEMENT_MISMATCH':
        return 'عدم تطابق التسوية';
      case 'RECONCILIATION_DIFFERENCE':
        return 'فرق مطابقة';
      case 'MISSING_PAYMENT_STATUS':
        return 'حالة الدفع ناقصة';
      case 'MISSING_STATUS_CODE':
        return 'حالة الرحلة ناقصة';
      case 'MISSING_DRIVER':
        return 'المندوب ناقص';
      case 'UNSUPPORTED_CURRENCY':
        return 'عملة غير مدعومة';
      default:
        return 'استثناء مالي';
    }
  }
}
