import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/backend/backend.dart';
import '/components/admin_driver_documents_panel.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_ui.dart';
import '/components/admin_status_badge.dart';
import '/core/admin_driver_email_verification.dart';
import '/core/admin_driver_review_actions.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-first registration review layout for [DriverActivationWidget].
class DriverRegistrationReviewBody extends StatelessWidget {
  const DriverRegistrationReviewBody({
    super.key,
    required this.user,
    required this.nameController,
    required this.cityController,
    required this.carTypeController,
    required this.busy,
    this.awaitingReview = true,
    required this.onPickCity,
    required this.onPickCarType,
    this.onApprove,
    this.onReject,
    this.onRequestChanges,
  });

  final UserRecord user;
  final TextEditingController nameController;
  final TextEditingController cityController;
  final TextEditingController carTypeController;
  final bool busy;

  /// When false, show a clear status and hide decision actions (no blank screen).
  final bool awaitingReview;
  final VoidCallback onPickCity;
  final VoidCallback onPickCarType;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRequestChanges;

  @override
  Widget build(BuildContext context) {
    final row = AdminDriverRow.fromUser(user);
    final vehicle = row.vehicle;
    final data = user.snapshotData;
    final theme = FlutterFlowTheme.of(context);
    final isV2 = AdminDriverReviewActions.isRegistrationV2(data);
    final blockers = AdminDriverReviewActions.approvalBlockingReasons(data)
        .map((k) => appTr(context, k))
        .where((t) => t.trim().isNotEmpty)
        .toList();
    final emailVerification = AdminDriverEmailVerification.fromUserData(data);

    return ListView(
      padding: AdminUi.pagePadding(context).copyWith(top: 12, bottom: 24),
      children: [
        AdminDriverProfileHeader(row: row),
        if (!awaitingReview) ...[
          const SizedBox(height: 12),
          AdminDriverCompactTip(
            text: uiTr(context, 'هذا الطلب ليس بانتظار المراجعة'),
          ),
        ],
        const SizedBox(height: 12),
        AdminDriverSectionCard(
          title: uiTr(context, 'حالة الطلب'),
          children: [
            AdminDriverKvRow(
              label: uiTr(context, 'التسجيل'),
              value: AdminDriverStatusLabels.registration(context, row.review),
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'تاريخ الإرسال'),
              value: _formatTs(data['submittedAt'] ?? data['submitted_at']),
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'رقم المحاولة'),
              value:
                  '${data['reviewAttemptCount'] ?? data['review_attempt_count'] ?? '—'}',
            ),
            if (data['reviewVersion'] != null)
              AdminDriverKvRow(
                label: 'Review Version',
                value: '${data['reviewVersion']}',
                muted: true,
              ),
            if (isV2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  uiTr(context, 'Registration V2'),
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: AdminUi.brandTeal,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ),
          ],
        ),
        AdminDriverSectionCard(
          title: uiTr(context, 'البيانات الشخصية'),
          children: [
            AdminDriverKvRow(
              label: uiTr(context, 'رقم الهوية'),
              value: user.driverid.trim().isNotEmpty ? user.driverid : '—',
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'البريد'),
              value: user.email.trim().isNotEmpty ? user.email : '—',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      uiTr(context, 'حالة التحقق'),
                      style: theme.labelSmall.override(
                        fontFamily: theme.labelSmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.labelSmallIsCustom,
                      ),
                    ),
                  ),
                  AdminStatusBadgeUnified(
                    label: AdminDriverEmailVerification.labelArabic(
                      emailVerification,
                    ),
                    kind: switch (emailVerification) {
                      AdminDriverEmailVerificationDisplay.verified =>
                        AdminStatusKind.active,
                      AdminDriverEmailVerificationDisplay.unverified =>
                        AdminStatusKind.pending,
                      AdminDriverEmailVerificationDisplay.unknown =>
                        AdminStatusKind.unknown,
                    },
                  ),
                ],
              ),
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'الهاتف'),
              value: AdminDriverRow.formatPhoneDisplay(row.phone),
            ),
          ],
        ),
        AdminDriverSectionCard(
          title: uiTr(context, 'الموقع'),
          children: [
            AdminDriverKvRow(
              label: uiTr(context, 'مدينة التسجيل'),
              value: row.city,
            ),
            if (row.operatingCity != row.city)
              AdminDriverKvRow(
                label: uiTr(context, 'مدينة التشغيل'),
                value: row.operatingCity,
              ),
          ],
        ),
        AdminDriverSectionCard(
          title: uiTr(context, 'المركبة'),
          children: [
            if (vehicle.isLegacyIncomplete)
              Text(vehicle.missingLabel(context))
            else ...[
              if (vehicle.titleLine.isNotEmpty)
                AdminDriverKvRow(
                  label: uiTr(context, 'المركبة'),
                  value: vehicle.titleLine,
                ),
              if (vehicle.classLine.isNotEmpty)
                AdminDriverKvRow(
                  label: uiTr(context, 'التصنيف'),
                  value: vehicle.classLine,
                ),
              if (vehicle.plate.isNotEmpty)
                AdminDriverKvRow(
                  label: uiTr(context, 'اللوحة'),
                  value: vehicle.plate,
                ),
            ],
          ],
        ),
        AdminDriverSectionCard(
          title: uiTr(context, 'الوثائق'),
          children: [
            AdminDriverDocumentsPanel(user: user),
          ],
        ),
        if (blockers.isNotEmpty)
          AdminDriverSectionCard(
            title: uiTr(context, 'ملاحظات المراجعة'),
            children: [
              for (final b in blockers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange.shade800),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b)),
                    ],
                  ),
                ),
            ],
          ),
        if (awaitingReview) ...[
          AdminDriverSectionCard(
            title: uiTr(context, 'تعديل قبل الاعتماد'),
            children: [
              AdminDriverCompactTip(
                text: uiTr(
                  context,
                  'يمكنك تعديل الاسم ومدينة العمل ونوع المركبة قبل الاعتماد فقط.',
                ),
              ),
              const SizedBox(height: 12),
              AdminDriverFormGrid(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: uiTr(context, 'الاسم الكامل'),
                    ),
                  ),
                  const SizedBox.shrink(),
                  AdminEditPickerRow(
                    label: uiTr(context, 'مدينة العمل'),
                    value: cityController.text,
                    placeholder: uiTr(context, 'اختر مدينة العمل'),
                    onTap: onPickCity,
                  ),
                  AdminEditPickerRow(
                    label: uiTr(context, 'نوع المركبة'),
                    value: carTypeController.text,
                    placeholder: uiTr(context, 'اختر نوع المركبة'),
                    onTap: onPickCarType,
                  ),
                ],
              ),
            ],
          ),
          AdminDriverSectionCard(
            title: uiTr(context, 'إجراءات القرار'),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Semantics(
                    identifier: 'qa-driver-approve',
                    label: 'qa-driver-approve',
                    button: true,
                    child: AdminPrimaryButton(
                      label: uiTr(context, 'اعتماد المندوب'),
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: busy,
                      onPressed: busy ? null : onApprove,
                    ),
                  ),
                  Semantics(
                    identifier: 'qa-driver-request-changes',
                    label: 'qa-driver-request-changes',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onRequestChanges,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label:
                          Text(appTr(context, 'adm_drv_request_changes_btn')),
                    ),
                  ),
                  Semantics(
                    identifier: 'qa-driver-reject',
                    label: 'qa-driver-reject',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.error,
                      ),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: Text(appTr(context, 'adm_drv_reject_btn')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        AdminDriverTechnicalSection(user: user),
      ],
    );
  }

  static String _formatTs(dynamic v) {
    if (v == null) return '—';
    if (v is DateTime) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }
}

/// Dialog for needs-changes with mandatory fieldsToFix + notes.
Future<({String reason, List<String> fields})?> showDriverNeedsChangesDialog({
  required BuildContext context,
}) async {
  final notes = TextEditingController();
  final selected = <String>{};

  const labels = <String, String>{
    'personal_info': 'البيانات الشخصية',
    'vehicle': 'المركبة',
    'national_id': 'الهوية',
    'vehicle_registration': 'استمارة المركبة',
    'driver_license': 'رخصة القيادة',
    'plate': 'اللوحة',
    'other': 'أخرى',
  };

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(appTr(context, 'adm_drv_request_changes_title')),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(uiTr(context, 'ما الذي يحتاج إلى تعديل؟')),
                    const SizedBox(height: 8),
                    for (final key
                        in AdminDriverReviewActions.fieldsToFixAllowlist)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(uiTr(context, labels[key] ?? key)),
                        value: selected.contains(key),
                        onChanged: (v) {
                          setLocal(() {
                            if (v == true) {
                              selected.add(key);
                            } else {
                              selected.remove(key);
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: uiTr(context, 'ملاحظات للمندوب'),
                        hintText: appTr(context, 'adm_drv_reason_hint'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_cancel')),
              ),
              TextButton(
                onPressed: () {
                  if (selected.isEmpty || notes.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text(appTr(context, 'adm_confirm')),
              ),
            ],
          );
        },
      );
    },
  );

  final reason = notes.text.trim();
  notes.dispose();
  if (ok != true || selected.isEmpty || reason.isEmpty) return null;
  return (reason: reason, fields: selected.toList(growable: false));
}

Future<String?> showDriverRejectDialog({required BuildContext context}) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(appTr(context, 'adm_drv_reject_title')),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: uiTr(context, 'سبب الرفض'),
          hintText: appTr(context, 'adm_drv_reason_hint'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(appTr(context, 'adm_cancel')),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) return;
            Navigator.pop(ctx, true);
          },
          child: Text(appTr(context, 'adm_confirm')),
        ),
      ],
    ),
  );
  final reason = controller.text.trim();
  controller.dispose();
  if (ok != true || reason.isEmpty) return null;
  return reason;
}
