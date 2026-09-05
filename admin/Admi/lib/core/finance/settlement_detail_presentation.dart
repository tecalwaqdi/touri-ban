/// Accountant-facing settlement detail presentation (F2.2).
///
/// Read-only labels only — does not alter settlement amounts, ledger writes,
/// or F1 financial semantics.
library;

import 'package:flutter/material.dart' show Color;

import '/core/admin_qa_fixture.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/settlement_state_labels.dart';
import '/flutter_flow/flutter_flow_theme.dart';

abstract final class SettlementDetailPresentation {
  SettlementDetailPresentation._();

  static const List<String> _arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Dark readable ink on light accountant surfaces (never near-white).
  static Color readableInk(FlutterFlowTheme theme) {
    final c = theme.secondaryText;
    if (c.computeLuminance() <= 0.45) return c;
    // LightModeTheme.secondaryText — forced when dark-theme tokens leak onto
    // light finance cards (Safari white-on-white defect).
    return const Color(0xFF1F1F1F);
  }

  static bool isQaTripId(String? id) {
    final s = (id ?? '').trim();
    if (s.isEmpty) return false;
    return AdminQaFixture.isFixtureId(s);
  }

  static bool isQaTripLine(String lineId, Map<String, dynamic> data) {
    if (isQaTripId(lineId)) return true;
    return AdminQaFixture.isFixtureMap(data, orderId: lineId);
  }

  static String countryAr(String? countryIdOrPath) =>
      AccountantFinanceLabels.countryHumanAr(countryIdOrPath);

  static String directionAr(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'DRIVER_PAYS_COMPANY':
      case 'DRIVER_OWES_COMPANY':
        return 'مستحق للشركة على السائق';
      case 'COMPANY_PAYS_DRIVER':
      case 'COMPANY_OWES_DRIVER':
        return 'مستحق للسائق على الشركة';
      case 'COMPANY_PAYS_AGENT':
      case 'COMPANY_OWES_AGENT':
        return 'مستحق للوكيل على الشركة';
      case 'AGENT_PAYS_COMPANY':
        return 'مستحق للشركة على الوكيل';
      case 'BALANCED':
        return 'متوازن';
      default:
        return SettlementStateLabels.directionAr(raw ?? '');
    }
  }

  static String settlementStatusAr(String? raw) =>
      AccountantFinanceLabels.settlementStatusAr(raw);

  /// Workflow status for transitions (مسودة / معتمدة / …).
  static String workflowStatusAr(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'draft':
        return 'مسودة';
      case 'locked':
        return 'معتمدة';
      case 'partially_paid':
        return 'مسددة جزئيًا';
      case 'settled':
        return 'مسددة';
      case 'voided':
        return 'ملغاة';
      case 'null':
      case '':
        return 'غير محددة';
      default:
        return settlementStatusAr(raw);
    }
  }

  static String paymentMethodAr(String? raw) =>
      SettlementStateLabels.methodAr(raw ?? '');

  static String paymentStatusAr(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'confirmed':
        return 'مؤكد';
      case 'pending':
        return 'غير مؤكد';
      case 'reversed':
        return 'معكوس';
      case 'failed':
        return 'فشل';
      case 'settled':
        return 'مسدد';
      default:
        return SettlementStateLabels.statusAr(raw ?? '');
    }
  }

  static String driverFallbackAr() => 'السائق غير محدد';

  static String driverDisplayName(Map<String, dynamic>? userData) {
    if (userData == null) return driverFallbackAr();
    for (final key in ['display_name', 'naim', 'naim_mndob_text', 'name']) {
      final v = userData[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return driverFallbackAr();
  }

  /// Never treat a bare UID as the primary driver label.
  static bool looksLikeRawUid(String? label, String? driverId) {
    final a = (label ?? '').trim();
    final b = (driverId ?? '').trim();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b;
  }

  static DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    try {
      final dyn = raw as dynamic;
      if (dyn.toDate is Function) return dyn.toDate() as DateTime;
    } catch (_) {}
    return null;
  }

  static String humanDateAr(dynamic raw) {
    final dt = parseDate(raw)?.toLocal();
    if (dt == null) return '—';
    final month = _arMonths[dt.month - 1];
    return '${dt.day} $month ${dt.year}';
  }

  static String periodAr(dynamic start, dynamic end) {
    final a = humanDateAr(start);
    final b = humanDateAr(end);
    if (a == '—' && b == '—') return '—';
    return 'من $a إلى $b';
  }

  static String auditEventAr(String? type) {
    switch ((type ?? '').trim().toUpperCase()) {
      case 'CREATED_DRAFT':
        return 'تم إنشاء مسودة التسوية';
      case 'LOCKED':
        return 'تم اعتماد التسوية';
      case 'SELF_APPROVAL':
        return 'اعتماد إداري';
      case 'PAYMENT_CREATED':
        return 'تم تسجيل دفعة';
      case 'PAYMENT_CONFIRMED':
        return 'تم تأكيد الدفعة';
      case 'CASH_PAYMENT_CONFIRMED':
        return 'تم تأكيد الدفعة النقدية';
      case 'SETTLEMENT_SETTLED_BY_PAYMENTS':
      case 'MARKED_SETTLED':
        return 'تم تسديد التسوية';
      case 'PAYMENT_REVERSED':
        return 'تم عكس دفعة';
      case 'VOIDED':
        return 'تم إلغاء التسوية';
      case 'PREVIEW_REFRESHED':
        return 'تم تحديث أرقام المسودة';
      case 'LEGACY_PAYMENT_ALLOCATED':
        return 'تم تخصيص دفعة سابقة';
      default:
        return 'عملية تسوية';
    }
  }

  static String actorRoleAr(String? role) {
    switch ((role ?? '').trim().toLowerCase()) {
      case 'super_admin':
        return 'السوبر أدمن';
      case 'finance':
        return 'المحاسبة';
      case 'country_admin':
        return 'مسؤول الدولة';
      case 'unknown':
      case '':
        return 'مستخدم النظام';
      default:
        return 'مستخدم النظام';
    }
  }

  static String statusTransitionAr(String? before, String? after) {
    final b = (before ?? '').trim().toLowerCase();
    final a = (after ?? '').trim().toLowerCase();
    if (b.isEmpty && a.isEmpty) return '';
    if (b == a) return '';
    final from = workflowStatusAr(b.isEmpty ? 'null' : b);
    final to = workflowStatusAr(a.isEmpty ? 'null' : a);
    return 'تغيرت الحالة من $from إلى $to';
  }

  /// Plain-language settlement outcome for the accountant header.
  static String settlementOutcomeAr({
    required String? direction,
    required String? status,
    required int dueMinor,
    required int paidMinor,
    required int outstandingMinor,
  }) {
    final st = (status ?? '').trim().toLowerCase();
    if (st == 'voided') return 'التسوية ملغاة';
    final dir = (direction ?? '').trim().toUpperCase();
    if (outstandingMinor <= 0 && paidMinor > 0 && dueMinor > 0) {
      if (dir == 'DRIVER_PAYS_COMPANY' || dir == 'DRIVER_OWES_COMPANY') {
        return 'السائق دفع كامل المستحق للشركة';
      }
      if (dir == 'COMPANY_PAYS_DRIVER' || dir == 'COMPANY_OWES_DRIVER') {
        return 'الشركة سددت كامل المستحق للسائق';
      }
      return 'تم تسديد المستحق بالكامل';
    }
    if (paidMinor > 0 && outstandingMinor > 0) {
      return 'تسوية مسددة جزئيًا';
    }
    if (dueMinor > 0 && paidMinor <= 0) {
      if (dir == 'DRIVER_PAYS_COMPANY' || dir == 'DRIVER_OWES_COMPANY') {
        return 'مستحق للشركة على السائق — غير مسدد';
      }
      if (dir == 'COMPANY_PAYS_DRIVER' || dir == 'COMPANY_OWES_DRIVER') {
        return 'مستحق للسائق على الشركة — غير مسدد';
      }
    }
    return settlementStatusAr(status);
  }

  static String unallocatedPaymentsAr({int? count}) {
    if (count != null && count > 0) {
      return 'توجد دفعات غير مخصصة تحتاج مراجعة ($count)';
    }
    return 'توجد دفعات غير مخصصة تحتاج مراجعة';
  }

  static String sourceVerificationMessageAr({
    required Object? flag,
    required Object? mutated,
  }) {
    if (flag == 'SOURCE_CHANGED_AFTER_LOCK') {
      return 'تغير المصدر بعد القفل — اللقطة دون تغيير';
    }
    if (mutated == true) {
      return 'تم تعديل المصدر';
    }
    return 'لم يتم تعديل المصدر';
  }

  /// True if [text] still exposes forbidden developer / raw technical content.
  static bool containsForbiddenAccountantCopy(String text) {
    final t = text.toLowerCase();
    if (t.contains('unallocated') && t.contains('heuristic')) return true;
    if (t.contains('legacy company_payments')) return true;
    if (t.contains('created_draft')) return true;
    if (t.contains('self_approval')) return true;
    if (t.contains('payment_created')) return true;
    if (t.contains('cash_payment_confirmed')) return true;
    if (t.contains('mutated=')) return true;
    if (t.contains('mutated=false') || t.contains('mutated=true')) return true;
    if (RegExp(r'\bdraft\s*→\s*locked\b').hasMatch(t)) return true;
    if (RegExp(r'countries/[a-z0-9_]+').hasMatch(t)) return true;
    if (RegExp(r'\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}').hasMatch(t)) {
      return true;
    }
    return false;
  }
}
