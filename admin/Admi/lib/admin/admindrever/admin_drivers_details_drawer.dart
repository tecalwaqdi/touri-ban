import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/backend/backend.dart';
import '/components/admin_driver_documents_panel.dart';
import '/components/admin_driver_financial_panel.dart';
import '/components/admin_driver_lifecycle_strip.dart';
import '/components/admin_driver_review_history_panel.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/components/profile_photo_image.dart';
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
              width: 460,
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
    final theme = FlutterFlowTheme.of(context);
    final row = AdminDriverRow.fromUser(user);
    final vehicle = row.vehicle;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  uiTr(context, 'تفاصيل المندوب'),
                  style: theme.titleMedium.override(
                    fontFamily: theme.titleMediumFamily,
                    fontWeight: FontWeight.w800,
                    useGoogleFonts: !theme.titleMediumIsCustom,
                  ),
                ),
              ),
              IconButton(
                tooltip: uiTr(context, 'إغلاق'),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  ProfilePhotoImage(
                    photoUrl: row.photoUrl,
                    size: 64,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.displayName,
                          style: theme.titleMedium.override(
                            fontFamily: theme.titleMediumFamily,
                            fontWeight: FontWeight.w800,
                            useGoogleFonts: !theme.titleMediumIsCustom,
                          ),
                        ),
                        Text(row.secondaryLine,
                            style: theme.bodySmall
                                .override(
                                  fontFamily: theme.bodySmallFamily,
                                  color: theme.secondaryText,
                                  useGoogleFonts: !theme.bodySmallIsCustom,
                                )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AdminDriverLifecycleStrip(user: user),
              const SizedBox(height: 14),
              _section(
                context,
                uiTr(context, 'البيانات الأساسية'),
                [
                  _kv(context, uiTr(context, 'الهاتف'), row.phone),
                  _kv(context, uiTr(context, 'مدينة التسجيل'), row.city),
                  if (row.operatingCity != row.city)
                    _kv(
                      context,
                      uiTr(context, 'مدينة التشغيل'),
                      row.operatingCity,
                    ),
                  _kv(context, 'UID', user.reference.id),
                ],
              ),
              _section(
                context,
                uiTr(context, 'حالة التسجيل'),
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AdminStatusBadgeUnified(
                        kind: AdminDriverStatusLabels.registrationKind(
                          row.review,
                        ),
                        label: AdminDriverStatusLabels.registration(
                          context,
                          row.review,
                        ),
                      ),
                      AdminStatusBadgeUnified(
                        kind: AdminDriverStatusLabels.accountKind(
                          row.accountActive,
                        ),
                        label: AdminDriverStatusLabels.account(
                          context,
                          row.accountActive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(AdminDriverStatusLabels.operationalLine(context, row)),
                  if (row.statusTruth.registrationPendingWithActiveAccount)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        uiTr(
                          context,
                          'التسجيل بانتظار المراجعة — الحساب نشط (محاور منفصلة)',
                        ),
                        style: theme.bodySmall.override(
                          fontFamily: theme.bodySmallFamily,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          useGoogleFonts: !theme.bodySmallIsCustom,
                        ),
                      ),
                    ),
                  if (row.review == AdminDriverReviewBucket.pendingReview)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        uiTr(context, 'بانتظار المراجعة'),
                        style: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w800,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
                      ),
                    ),
                ],
              ),
              _section(
                context,
                uiTr(context, 'المركبة'),
                [
                  if (vehicle.isLegacyIncomplete)
                    Text(vehicle.missingLabel(context))
                  else ...[
                    if (vehicle.titleLine.isNotEmpty) Text(vehicle.titleLine),
                    if (vehicle.classLine.isNotEmpty) Text(vehicle.classLine),
                    if (vehicle.plate.isNotEmpty)
                      Text(vehicle.plateLine(context)),
                  ],
                ],
              ),
              _section(
                context,
                uiTr(context, 'الوثائق'),
                [AdminDriverDocumentsPanel(user: user)],
              ),
              _section(
                context,
                uiTr(context, 'الحالة التشغيلية'),
                [
                  _kv(
                    context,
                    uiTr(context, 'الاتصال'),
                    AdminDriverStatusLabels.connection(context, row.connection),
                  ),
                  _kv(
                    context,
                    uiTr(context, 'التوفر'),
                    AdminDriverStatusLabels.availability(
                      context,
                      row.availability,
                    ),
                  ),
                  if (row.onActiveTrip)
                    _kv(
                      context,
                      uiTr(context, 'رحلة نشطة'),
                      uiTr(context, 'نعم'),
                    ),
                ],
              ),
              _section(
                context,
                uiTr(context, 'الرحلات'),
                [
                  _kv(context, uiTr(context, 'الرحلات'), row.tripsLabel),
                ],
              ),
              _section(
                context,
                uiTr(context, 'الأرباح'),
                [
                  AdminDriverFinancialPanel(
                    driverRef: user.reference,
                    countryRef: user.revDolh,
                  ),
                  _kv(context, uiTr(context, 'الأرباح'), row.earningsLabel),
                ],
              ),
              _section(
                context,
                uiTr(context, 'سجل المراجعات'),
                [AdminDriverReviewHistoryPanel(driverId: user.reference.id)],
              ),
              _section(
                context,
                uiTr(context, 'إجراءات الإدارة'),
                [
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AdminContentCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.titleSmall.override(
                fontFamily: theme.titleSmallFamily,
                fontWeight: FontWeight.w800,
                useGoogleFonts: !theme.titleSmallIsCustom,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: theme.labelMedium.override(
                fontFamily: theme.labelMediumFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelMediumIsCustom,
              ),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
