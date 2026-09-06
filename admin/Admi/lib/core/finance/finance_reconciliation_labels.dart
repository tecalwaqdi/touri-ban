import '/core/finance/finance_reconciliation_read_model.dart';

/// Arabic business labels for F3-B1 reconciliation axes (Accountant UI).
/// Never expose raw enums in normal surfaces.
abstract final class FinanceReconciliationLabels {
  FinanceReconciliationLabels._();

  static String financialAr(RecFinancialSnapshotStatus s) => switch (s) {
        RecFinancialSnapshotStatus.complete => 'مكتملة ماليًا',
        RecFinancialSnapshotStatus.partial => 'بيانات مالية ناقصة',
        RecFinancialSnapshotStatus.unresolved => 'تحتاج تحقق',
      };

  static String collectionAr(RecCollectionStatus s) => switch (s) {
        RecCollectionStatus.collected => 'تم التحصيل',
        RecCollectionStatus.uncollected => 'بانتظار التحصيل',
        RecCollectionStatus.notApplicable => 'غير مطبق',
        RecCollectionStatus.unknown => 'غير معروف',
      };

  static String agentAr(RecAgentStatus s) => switch (s) {
        RecAgentStatus.complete => 'موثق',
        RecAgentStatus.none => 'لا يوجد وكيل وقت الرحلة',
        RecAgentStatus.ambiguous => 'تعارض في الوكيل',
        RecAgentStatus.missing => 'بيانات الوكيل التاريخية ناقصة',
        RecAgentStatus.unresolved => 'يحتاج تحقق',
      };

  static String settlementAr(RecSettlementStatus s) => switch (s) {
        RecSettlementStatus.unsettled => 'غير مسددة',
        RecSettlementStatus.partial => 'مسددة جزئيًا',
        RecSettlementStatus.settled => 'مسددة',
        RecSettlementStatus.notRequired => 'لا تتطلب تسوية',
        RecSettlementStatus.unknown => 'غير معروف',
      };

  static String reconciliationAr(RecReconciliationStatus s) => switch (s) {
        RecReconciliationStatus.reconciled => 'تمت المصالحة',
        RecReconciliationStatus.needsReview => 'تحتاج مراجعة',
        RecReconciliationStatus.blockedByMissingData =>
          'محجوبة بسبب نقص البيانات',
      };

  static String paymentMethodAr(RecPaymentMethod m) => switch (m) {
        RecPaymentMethod.cash => 'نقدي',
        RecPaymentMethod.online => 'إلكتروني',
        RecPaymentMethod.unknown => 'غير معروف',
      };

  static String issueAr(String code) {
    switch (code) {
      case RecIssueCode.missingGross:
        return 'الأجرة الأساسية غير محفوظة';
      case RecIssueCode.missingDriverNet:
        return 'صافي السائق غير محفوظ';
      case RecIssueCode.missingAgentHistory:
        return 'بيانات الوكيل وقت الرحلة غير محفوظة';
      case RecIssueCode.financialSnapshotMismatch:
        return 'يوجد عدم تطابق في بيانات الرحلة المالية';
      case RecIssueCode.settlementMismatch:
        return 'يوجد عدم تطابق في بيانات التسوية';
      case RecIssueCode.agentAmountMismatch:
        return 'حصة الوكيل لا تطابق نسبة العمولة المحفوظة';
      case RecIssueCode.ambiguousAgent:
        return 'تعارض في تحديد الوكيل وقت الرحلة';
      case RecIssueCode.unresolvedAgent:
        return 'بيانات الوكيل غير مكتملة أو غير متسقة';
      case RecIssueCode.partialFinancial:
        return 'بيانات مالية ناقصة';
      case RecIssueCode.unresolvedFinancial:
        return 'تعذر التحقق من البيانات المالية';
      case RecIssueCode.cashNotCollected:
        return 'بانتظار تحصيل النقد';
      case RecIssueCode.noSettlement:
        return 'رحلة مؤهلة بلا تسوية بعد';
      case RecIssueCode.settlementPartial:
        return 'تسوية مسددة جزئيًا';
      case RecIssueCode.unallocatedPayment:
        return 'دفعة شركة غير مخصصة';
      default:
        return 'يحتاج مراجعة محاسبية';
    }
  }

  /// Prefer data-quality explanations for the exception panel.
  static bool isExceptionWorthy(RecIssue issue) =>
      issue.kind == RecIssueKind.dataQuality ||
      issue.code == RecIssueCode.settlementPartial ||
      issue.code == RecIssueCode.noSettlement;
}
