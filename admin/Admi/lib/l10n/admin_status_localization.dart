/// Localized presentation for internal status / enum codes.
/// Internal stored values remain unchanged.
library;

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/ui_catalog.dart';

/// Map raw operational / finance status codes to localized UI labels.
String adminStatusLabel(BuildContext context, String? raw) {
  final code = (raw ?? '').trim();
  if (code.isEmpty) {
    return uiTr(context, 'غير معروف');
  }

  switch (code.toLowerCase()) {
    case 'completed':
    case 'complete':
    case 'trip_completed':
      return uiTr(context, 'مكتمل');
    case 'cancelled':
    case 'canceled':
      return uiTr(context, 'ملغي');
    case 'pending':
      return uiTr(context, 'قيد الانتظار');
    case 'pending_cash':
      return uiTr(context, 'نقد معلّق');
    case 'pending_review':
    case 'needs_review':
      return uiTr(context, 'تحتاج مراجعة');
    case 'approved':
      return uiTr(context, 'موافق عليه');
    case 'rejected':
      return uiTr(context, 'مرفوض');
    case 'needs_changes':
      return uiTr(context, 'يحتاج تعديلات');
    case 'suspended':
      return uiTr(context, 'موقوف');
    case 'active':
      return uiTr(context, 'نشط');
    case 'inactive':
      return uiTr(context, 'غير نشط');
    case 'paid':
      return uiTr(context, 'مدفوع');
    case 'unpaid':
      return uiTr(context, 'غير مدفوع');
    case 'partial':
      return uiTr(context, 'جزئي');
    case 'reconciled':
      return uiTr(context, 'تمت المصالحة');
    case 'unresolved':
      return uiTr(context, 'غير محسوم');
    case 'settled':
      return uiTr(context, 'مسدد');
    case 'unsettled':
      return uiTr(context, 'غير مسدد');
    case 'blocked_by_missing_data':
      return uiTr(context, 'محظور بسبب نقص البيانات');
    case 'driver_pays_company':
      return uiTr(context, 'السائق يدفع للشركة');
    case 'company_pays_driver':
      return uiTr(context, 'الشركة تدفع للسائق');
    case 'unknown':
      return uiTr(context, 'غير معروف');
    default:
      // Prefer localized catalog entry when Arabic/English literal was used.
      final viaUi = uiTr(context, code);
      if (viaUi != code) return viaUi;
      final viaKey = appTr(context, code);
      if (viaKey.isNotEmpty && viaKey != code) return viaKey;
      return code;
  }
}

/// Safe user-facing error text — never expose stack traces or raw Firebase codes.
String adminSafeErrorMessage(BuildContext context, Object? error) {
  final raw = '$error'.toLowerCase();
  if (raw.contains('permission-denied') || raw.contains('permission_denied')) {
    return uiTr(context, 'ليس لديك صلاحية لتنفيذ هذا الإجراء');
  }
  if (raw.contains('unauthenticated') || raw.contains('requires-recent-login')) {
    return uiTr(context, 'يلزم تسجيل الدخول مرة أخرى للمتابعة');
  }
  if (raw.contains('failed-precondition')) {
    return uiTr(context, 'لا يمكن إكمال العملية في الحالة الحالية');
  }
  if (raw.contains('unavailable') || raw.contains('finance_query_unavailable')) {
    return uiTr(context, 'الخدمة غير متاحة حالياً. حاول مرة أخرى');
  }
  if (raw.contains('network') || raw.contains('socket') || raw.contains('timeout')) {
    return uiTr(context, 'تعذر الاتصال. تحقق من الشبكة وحاول مرة أخرى');
  }
  if (raw.contains('not-found') || raw.contains('not_found')) {
    return uiTr(context, 'العنصر غير موجود');
  }
  return uiTr(context, 'حدث خطأ غير متوقع. حاول مرة أخرى');
}
