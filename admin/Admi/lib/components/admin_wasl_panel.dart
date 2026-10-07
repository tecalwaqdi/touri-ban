import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Saudi Wasl regulatory snapshot. Hidden for non-SA drivers with no snapshot.
class AdminWaslDriverSection extends StatelessWidget {
  const AdminWaslDriverSection({super.key, required this.user});

  final UserRecord user;

  bool get _saudi {
    final iso = (user.snapshotData['country_iso2'] ?? '').toString().toUpperCase();
    return iso == 'SA' || user.snapshotData['wasl'] is Map;
  }

  @override
  Widget build(BuildContext context) {
    if (!_saudi) return const SizedBox.shrink();
    final wasl = user.snapshotData['wasl'];
    final data = wasl is Map ? Map<String, dynamic>.from(wasl) : const <String, dynamic>{};
    String show(String key) {
      final value = data[key];
      if (value == null || value.toString().trim().isEmpty) return '—';
      return value.toString();
    }

    return AdminDriverSectionCard(
      title: uiTr(context, 'تنظيم وصل'),
      children: [
        AdminDriverKvRow(label: uiTr(context, 'حالة تسجيل وصل'), value: show('registration_status')),
        AdminDriverKvRow(label: uiTr(context, 'أهلية السائق'), value: show('driver_eligibility')),
        AdminDriverKvRow(label: uiTr(context, 'أهلية المركبة'), value: show('vehicle_eligibility')),
        AdminDriverKvRow(label: uiTr(context, 'انتهاء الأهلية'), value: show('eligibility_expiry_date')),
        AdminDriverKvRow(label: uiTr(context, 'انتهاء أهلية المركبة'), value: show('vehicle_eligibility_expiry_date')),
        AdminDriverKvRow(label: uiTr(context, 'انتهاء رخصة المركبة'), value: show('vehicle_license_expiry_date')),
        AdminDriverKvRow(label: uiTr(context, 'السجل الجنائي'), value: show('criminal_record_status')),
        AdminDriverKvRow(label: uiTr(context, 'أسباب الرفض'), value: show('rejection_reasons')),
        AdminDriverKvRow(label: uiTr(context, 'آخر فحص'), value: show('last_checked_at')),
        AdminDriverKvRow(label: uiTr(context, 'آخر مزامنة'), value: show('last_sync_at')),
        AdminDriverKvRow(label: uiTr(context, 'آخر موقع وصل'), value: show('last_wasl_location_success_at')),
        AdminDriverKvRow(label: uiTr(context, 'نتيجة الموقع'), value: show('last_location_result_code')),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => _refresh(context),
            child: Text(uiTr(context, 'تحديث الأهلية')),
          ),
        ),
      ],
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final identity = (user.snapshotData['iDHoyhMNDOB'] ?? '').toString();
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('waslRefreshDriverEligibility')
          .call({
        'driverUid': user.reference.id,
        'identityNumber': identity,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'تم طلب تحديث أهلية وصل'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'وصل غير مفعّل أو غير متاح'))),
        );
      }
    }
  }
}

class AdminWaslTripSection extends StatelessWidget {
  const AdminWaslTripSection({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final iso = (order.snapshotData['country_iso2'] ?? '').toString().toUpperCase();
    final raw = order.snapshotData['wasl_trip_sync'];
    if (iso != 'SA' && raw is! Map) return const SizedBox.shrink();
    final data = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    String show(String key) {
      final value = data[key];
      if (value == null || value.toString().trim().isEmpty) return '—';
      return value.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AdminDriverSectionCard(
        title: uiTr(context, 'مزامنة رحلة وصل'),
        children: [
          AdminDriverKvRow(label: uiTr(context, 'الحالة'), value: show('status')),
          AdminDriverKvRow(label: uiTr(context, 'رمز النتيجة'), value: show('last_result_code')),
          AdminDriverKvRow(label: uiTr(context, 'عدد المحاولات'), value: show('attempt_count')),
          AdminDriverKvRow(label: uiTr(context, 'آخر محاولة'), value: show('last_attempt_at')),
          AdminDriverKvRow(label: uiTr(context, 'وقت المزامنة'), value: show('synced_at')),
          AdminDriverKvRow(label: uiTr(context, 'تصنيف الخطأ'), value: show('last_error_class')),
          if ((show('status') == 'retryable_failure' ||
                  show('status') == 'blocked_missing_data' ||
                  show('status') == 'permanent_failure') &&
              show('last_error_class') != 'AUTH_FAILURE' &&
              show('last_error_class') != 'ACTIVITY_MISMATCH')
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => _retry(context),
                child: Text(uiTr(context, 'إعادة مزامنة الرحلة')),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _retry(BuildContext context) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('waslRetryTripSync')
          .call({'orderId': order.reference.id});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'تم طلب مزامنة رحلة وصل'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'وصل غير مفعّل أو غير متاح'))),
        );
      }
    }
  }
}
