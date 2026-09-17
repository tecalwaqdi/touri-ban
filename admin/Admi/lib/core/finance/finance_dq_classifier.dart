import '/core/finance/finance_exception_classifier.dart';
import '/core/finance/financial_accounting_engine.dart';

/// Severity for Financial Data Quality findings (flag-only; never auto-fix).
enum FinanceDqSeverity {
  critical,
  warning,
  info,
}

/// One DQ finding derived from canonical V2 lines / exception classifier.
class FinanceDqFinding {
  const FinanceDqFinding({
    required this.severity,
    required this.code,
    required this.orderId,
    required this.titleAr,
    required this.titleEn,
    this.detail,
  });

  final FinanceDqSeverity severity;
  final FinanceExceptionCode code;
  final String orderId;
  final String titleAr;
  final String titleEn;
  final String? detail;
}

/// Maps exception codes → DQ severity for the Financial Data Quality workspace.
abstract final class FinanceDqClassifier {
  FinanceDqClassifier._();

  static FinanceDqSeverity severityOf(FinanceExceptionCode code) {
    switch (code) {
      case FinanceExceptionCode.completedMissingMoney:
      case FinanceExceptionCode.incompleteFinancialRecord:
      case FinanceExceptionCode.moneyMismatch:
      case FinanceExceptionCode.settlementMismatch:
      case FinanceExceptionCode.unsupportedCurrency:
        return FinanceDqSeverity.critical;
      case FinanceExceptionCode.driverNetMissing:
      case FinanceExceptionCode.platformFeeMissing:
      case FinanceExceptionCode.platformCommissionRateMismatch:
      case FinanceExceptionCode.reconciliationDifference:
      case FinanceExceptionCode.vatInvalid:
      case FinanceExceptionCode.unknownPaymentMethod:
        return FinanceDqSeverity.warning;
      case FinanceExceptionCode.cancelledWithStalePendingCash:
      case FinanceExceptionCode.collectedBeforeCompleted:
      case FinanceExceptionCode.onlinePaidNotCompleted:
      case FinanceExceptionCode.agentAttributionMissing:
      case FinanceExceptionCode.agentRateMissing:
        return FinanceDqSeverity.info;
    }
  }

  static String titleAr(FinanceExceptionCode code) {
    switch (code) {
      case FinanceExceptionCode.completedMissingMoney:
        return 'رحلة مكتملة ببيانات مالية ناقصة';
      case FinanceExceptionCode.incompleteFinancialRecord:
        return 'سجل مالي غير مكتمل';
      case FinanceExceptionCode.moneyMismatch:
        return 'عدم تطابق المبالغ';
      case FinanceExceptionCode.settlementMismatch:
        return 'عدم تطابق التسوية';
      case FinanceExceptionCode.unsupportedCurrency:
        return 'عملة غير مدعومة';
      case FinanceExceptionCode.driverNetMissing:
        return 'صافي السائق مفقود';
      case FinanceExceptionCode.platformFeeMissing:
        return 'عمولة توري مفقودة';
      case FinanceExceptionCode.platformCommissionRateMismatch:
        return 'عمولة توري لا تطابق قاعدة 15٪ الحالية';
      case FinanceExceptionCode.reconciliationDifference:
        return 'فرق مطابقة';
      case FinanceExceptionCode.vatInvalid:
        return 'ضريبة غير متسقة';
      case FinanceExceptionCode.unknownPaymentMethod:
        return 'طريقة دفع غير معروفة';
      case FinanceExceptionCode.cancelledWithStalePendingCash:
        return 'ملغاة مع نقد معلّق قديم';
      case FinanceExceptionCode.collectedBeforeCompleted:
        return 'تحصيل قبل الإكمال';
      case FinanceExceptionCode.onlinePaidNotCompleted:
        return 'مدفوعة إلكترونيًا وغير مكتملة';
      case FinanceExceptionCode.agentAttributionMissing:
        return 'إسناد الوكيل مفقود';
      case FinanceExceptionCode.agentRateMissing:
        return 'نسبة الوكيل مفقودة';
    }
  }

  static String titleEn(FinanceExceptionCode code) {
    switch (code) {
      case FinanceExceptionCode.completedMissingMoney:
        return 'Completed trip with missing money fields';
      case FinanceExceptionCode.incompleteFinancialRecord:
        return 'Incomplete financial record';
      case FinanceExceptionCode.moneyMismatch:
        return 'Money mismatch';
      case FinanceExceptionCode.settlementMismatch:
        return 'Settlement mismatch';
      case FinanceExceptionCode.unsupportedCurrency:
        return 'Unsupported currency';
      case FinanceExceptionCode.driverNetMissing:
        return 'Driver net missing';
      case FinanceExceptionCode.platformFeeMissing:
        return 'Touri commission missing';
      case FinanceExceptionCode.platformCommissionRateMismatch:
        return 'Touri commission ≠ current 15% rule';
      case FinanceExceptionCode.reconciliationDifference:
        return 'Reconciliation difference';
      case FinanceExceptionCode.vatInvalid:
        return 'VAT inconsistent';
      case FinanceExceptionCode.unknownPaymentMethod:
        return 'Unknown payment method';
      case FinanceExceptionCode.cancelledWithStalePendingCash:
        return 'Cancelled with stale pending cash';
      case FinanceExceptionCode.collectedBeforeCompleted:
        return 'Collected before completed';
      case FinanceExceptionCode.onlinePaidNotCompleted:
        return 'Online paid not completed';
      case FinanceExceptionCode.agentAttributionMissing:
        return 'Agent attribution missing';
      case FinanceExceptionCode.agentRateMissing:
        return 'Agent rate missing';
    }
  }

  static List<FinanceDqFinding> fromLines(Iterable<FinancialOrderLine> lines) {
    final out = <FinanceDqFinding>[];
    for (final line in lines) {
      for (final hit in FinanceExceptionClassifier.classify(line)) {
        out.add(FinanceDqFinding(
          severity: severityOf(hit.code),
          code: hit.code,
          orderId: hit.orderId,
          titleAr: titleAr(hit.code),
          titleEn: titleEn(hit.code),
          detail: hit.detail,
        ));
      }
    }
    out.sort((a, b) {
      final s = a.severity.index.compareTo(b.severity.index);
      if (s != 0) return s;
      return a.orderId.compareTo(b.orderId);
    });
    return out;
  }

  static Map<FinanceDqSeverity, int> countBySeverity(
    Iterable<FinanceDqFinding> findings,
  ) {
    final counts = <FinanceDqSeverity, int>{
      for (final s in FinanceDqSeverity.values) s: 0,
    };
    for (final f in findings) {
      counts[f.severity] = (counts[f.severity] ?? 0) + 1;
    }
    return counts;
  }
}
