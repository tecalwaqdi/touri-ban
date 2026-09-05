import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/backend/backend.dart';
import '/components/admin_driver_documents_panel.dart';
import '/components/admin_driver_financial_panel.dart';
import '/components/admin_driver_review_history_panel.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Side drawer / sheet for quick driver details without leaving the list.
Future<void> showAdminDriverDetailsDrawer({
  required BuildContext context,
  required UserRecord user,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 900;
  if (wide) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'driver-details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) {
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Material(
            color: FlutterFlowTheme.of(ctx).primaryBackground,
            elevation: 8,
            child: SizedBox(
              width: 480,
              height: MediaQuery.sizeOf(ctx).height,
              child: AdminDriversDetailsPanel(user: user),
            ),
          ),
        );
      },
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.92,
      child: AdminDriversDetailsPanel(user: user),
    ),
  );
}

class AdminDriversDetailsPanel extends StatelessWidget {
  const AdminDriversDetailsPanel({super.key, required this.user});

  final UserRecord user;

  @override
  Widget build(BuildContext context) {
    final row = AdminDriverRow.fromUser(user);
    final vehicle = row.vehicle;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  uiTr(context, 'ملف المندوب'),
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !FlutterFlowTheme.of(
                      context,
                    ).titleMediumIsCustom,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: uiTr(context, 'إغلاق'),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              AdminDriverProfileHeader(
                row: row,
                // Operational axes owned by الحالة التشغيلية section below.
                includeOperationalAxes: false,
              ),
              if (row.statusTruth.registrationPendingWithActiveAccount)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AdminDriverCompactTip(
                    text: uiTr(
                      context,
                      'التسجيل بانتظار المراجعة — الحساب نشط (محاور منفصلة)',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              AdminDriverSectionCard(
                title: uiTr(context, 'البيانات الشخصية'),
                children: [
                  // Phone already shown in header — keep city ownership here.
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
              // Registration/account badges already live in AdminDriverProfileHeader
              // via AdminDriverStatusStack — do not render a second StatusStack.
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
                  AdminDriverDocumentsPanel(
                    user: user,
                    // Header already owns registration/activation chips.
                    showLifecycleStrip: false,
                  ),
                ],
              ),
              AdminDriverSectionCard(
                title: uiTr(context, 'الحالة التشغيلية'),
                children: [AdminDriverOperationalStatus(row: row)],
              ),
              AdminDriverSectionCard(
                title: uiTr(context, 'النشاط والرحلات'),
                children: [
                  AdminDriverKvRow(
                    label: uiTr(context, 'الرحلات'),
                    value: row.tripsLabel,
                  ),
                ],
              ),
              AdminDriverSectionCard(
                title: uiTr(context, 'الأرباح'),
                children: [
                  AdminDriverFinancialPanel(
                    driverRef: user.reference,
                    countryRef: user.revDolh,
                    profileCompact: true,
                  ),
                  AdminDriverKvRow(
                    label: uiTr(context, 'إجمالي الأرباح'),
                    value: row.earningsLabel,
                  ),
                ],
              ),
              AdminDriverSectionCard(
                title: uiTr(context, 'سجل المراجعات'),
                children: [
                  AdminDriverReviewHistoryPanel(driverId: user.reference.id),
                ],
              ),
              AdminDriverSectionCard(
                title: uiTr(context, 'الإجراءات الإدارية'),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).maybePop();
                          context.pushNamed(
                            DriverProfileWidget.routeName,
                            queryParameters: {
                              'iduser': serializeParam(
                                user.reference,
                                ParamType.DocumentReference,
                              ),
                            }.withoutNulls,
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(uiTr(context, 'عرض كامل')),
                      ),
                      if (row.review == AdminDriverReviewBucket.pendingReview ||
                          row.review == AdminDriverReviewBucket.needsChanges)
                        AdminPrimaryButton(
                          label: uiTr(context, 'مراجعة التسجيل'),
                          icon: Icons.fact_check_outlined,
                          onPressed: () {
                            Navigator.of(context).maybePop();
                            context.pushNamed(
                              DriverActivationWidget.routeName,
                              queryParameters: {
                                'dre': serializeParam(
                                  user.reference,
                                  ParamType.DocumentReference,
                                ),
                              }.withoutNulls,
                            );
                          },
                        ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).maybePop();
                          context.pushNamed(
                            AddDrevWidget.routeName,
                            queryParameters: {
                              'editUser': serializeParam(
                                user.reference,
                                ParamType.DocumentReference,
                              ),
                            }.withoutNulls,
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(uiTr(context, 'تعديل')),
                      ),
                    ],
                  ),
                ],
              ),
              AdminDriverTechnicalSection(user: user),
            ],
          ),
        ),
      ],
    );
  }
}
