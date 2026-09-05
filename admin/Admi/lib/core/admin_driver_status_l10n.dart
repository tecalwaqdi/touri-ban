import 'package:flutter/material.dart';

import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Human-readable Arabic labels for registration / audit status values.
abstract final class AdminDriverStatusL10n {
  AdminDriverStatusL10n._();

  static String registrationRaw(BuildContext context, String? rawIn) {
    final raw = (rawIn ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '—';
    switch (raw) {
      case 'draft':
        return uiTr(context, 'مسودة');
      case 'pending_review':
      case 'submitted':
      case 'pending':
        return uiTr(context, 'بانتظار المراجعة');
      case 'needs_changes':
      case 'changes_requested':
      case 'changesrequested':
        return uiTr(context, 'طلب تعديلات');
      case 'approved':
        return uiTr(context, 'تمت الموافقة');
      case 'rejected':
        return uiTr(context, 'تم الرفض');
      case 'suspended':
        return uiTr(context, 'موقوف');
      case 'blocked':
        return uiTr(context, 'محظور');
      default:
        return rawIn!.trim();
    }
  }

  static String reviewBucket(BuildContext context, AdminDriverReviewBucket b) {
    switch (b) {
      case AdminDriverReviewBucket.draft:
        return uiTr(context, 'مسودة');
      case AdminDriverReviewBucket.pendingReview:
        return uiTr(context, 'بانتظار المراجعة');
      case AdminDriverReviewBucket.needsChanges:
        return uiTr(context, 'طلب تعديلات');
      case AdminDriverReviewBucket.approved:
        return uiTr(context, 'تمت الموافقة');
      case AdminDriverReviewBucket.rejected:
        return uiTr(context, 'تم الرفض');
      case AdminDriverReviewBucket.suspended:
        return uiTr(context, 'موقوف');
      case AdminDriverReviewBucket.unknownLegacy:
        return uiTr(context, 'غير مصنّف');
    }
  }

  static String auditAction(BuildContext context, String action) {
    switch (action) {
      case 'DRIVER_APPLICATION_SUBMITTED':
        return uiTr(context, 'تم إرسال الطلب');
      case 'DRIVER_APPLICATION_RESUBMITTED':
        return uiTr(context, 'تمت إعادة الإرسال');
      case 'DRIVER_APPLICATION_APPROVED':
        return uiTr(context, 'تمت الموافقة');
      case 'DRIVER_APPLICATION_REJECTED':
        return uiTr(context, 'تم الرفض');
      case 'DRIVER_CHANGES_REQUESTED':
        return uiTr(context, 'طلب تعديلات');
      case 'DRIVER_SUSPENDED':
        return uiTr(context, 'تم إيقاف الحساب');
      case 'DRIVER_REACTIVATED':
        return uiTr(context, 'تمت إعادة التفعيل');
      default:
        return action;
    }
  }

  /// Formats status change using localized registration labels (never raw enums).
  static String statusTransition(
    BuildContext context, {
    Object? oldStatus,
    Object? newStatus,
  }) {
    final o = oldStatus?.toString().trim() ?? '';
    final n = newStatus?.toString().trim() ?? '';
    if (o.isEmpty && n.isEmpty) return '';
    if (o.isEmpty) return registrationRaw(context, n);
    if (n.isEmpty) return registrationRaw(context, o);
    return '${registrationRaw(context, o)} ← ${registrationRaw(context, n)}';
  }
}
