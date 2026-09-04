import 'package:flutter/material.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_ui_shared.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_driver_documents_panel.dart';
import '/components/admin_driver_financial_panel.dart';
import '/components/admin_driver_review_history_panel.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_profile_view.dart';
import '/core/admin_driver_review_actions.dart';
import '/core/admin_user_facing_errors.dart';
import '/driver_profile/admin_driver_active_trip.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Full-page driver profile (read-first, Modern Classic Admin).
class DriverProfileBody extends StatefulWidget {
  const DriverProfileBody({
    super.key,
    required this.user,
    required this.userRef,
  });

  final UserRecord user;
  final DocumentReference userRef;

  @override
  State<DriverProfileBody> createState() => _DriverProfileBodyState();
}

class _DriverProfileBodyState extends State<DriverProfileBody> {
  late Future<AdminDriverActiveTripTruth> _activeTripFuture;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _activeTripFuture = AdminDriverActiveTripTruth.resolve(widget.user);
  }

  @override
  void didUpdateWidget(covariant DriverProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.reference != widget.user.reference) {
      _activeTripFuture = AdminDriverActiveTripTruth.resolve(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = AdminDriverRow.fromUser(widget.user);
    final vehicle = row.vehicle;
    final data = widget.user.snapshotData;
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return ListView(
      padding: AdminUi.pagePadding(context).copyWith(top: 12, bottom: 28),
      children: [
        _ProfileHeader(row: row),
        const SizedBox(height: 12),
        _QuickSummary(row: row),
        if (row.statusTruth.authFirestoreMismatch) ...[
          const SizedBox(height: 10),
          AdminDriverCompactTip(
            text: uiTr(
              context,
              'تحذير: تعارض بين حالة Auth وFirestore — راجع قبل أي إجراء.',
            ),
          ),
        ],
        if (row.statusTruth.registrationPendingWithActiveAccount) ...[
          const SizedBox(height: 10),
          AdminDriverCompactTip(
            text: uiTr(
              context,
              'التسجيل بانتظار المراجعة — الحساب نشط (محاور منفصلة)',
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: _leftSections(context, row, vehicle, data),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: _rightSections(context, row, vehicle, data),
                ),
              ),
            ],
          )
        else ...[
          ..._leftSections(context, row, vehicle, data),
          ..._rightSections(context, row, vehicle, data),
        ],
        AdminDriverTechnicalSection(user: widget.user),
      ],
    );
  }

  List<Widget> _leftSections(
    BuildContext context,
    AdminDriverRow row,
    AdminDriverVehicleSummary vehicle,
    Map<String, dynamic> data,
  ) {
    return [
      AdminDriverSectionCard(
        title: uiTr(context, 'البيانات الشخصية'),
        children: [
          // Name / email / phone owned by _ProfileHeader — avoid duplicates.
          AdminDriverKvRow(
            label: uiTr(context, 'الدولة'),
            value: _countryDisplay(data),
          ),
          if (_regionDisplay(data).isNotEmpty)
            AdminDriverKvRow(
              label: uiTr(context, 'المنطقة'),
              value: _regionDisplay(data),
            ),
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
        title: uiTr(context, 'حالة الحساب'),
        children: [
          // Registration/account chips live in header; this section owns
          // connection/availability detail.
          AdminDriverOperationalStatus(row: row),
        ],
      ),
      AdminDriverSectionCard(
        title: uiTr(context, 'المركبة'),
        children: [
          if (vehicle.isLegacyIncomplete)
            Text(vehicle.missingLabel(context))
          else ...[
            if (vehicle.classificationLabel.isNotEmpty)
              AdminDriverKvRow(
                label: uiTr(context, 'التصنيف'),
                value: vehicle.classificationLabel,
              ),
            if (vehicle.name.isNotEmpty)
              AdminDriverKvRow(
                label: uiTr(context, 'الماركة'),
                value: vehicle.name,
              ),
            if (vehicle.modelYear.isNotEmpty)
              AdminDriverKvRow(
                label: uiTr(context, 'السنة'),
                value: vehicle.modelYear,
              ),
            if (vehicle.color.isNotEmpty)
              AdminDriverKvRow(
                label: uiTr(context, 'اللون'),
                value: vehicle.color,
              ),
            if (vehicle.plate.isNotEmpty)
              AdminDriverKvRow(
                label: uiTr(context, 'اللوحة'),
                value: vehicle.plate,
              ),
          ],
        ],
      ),
    ];
  }

  List<Widget> _rightSections(
    BuildContext context,
    AdminDriverRow row,
    AdminDriverVehicleSummary vehicle,
    Map<String, dynamic> data,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AdminDriverDocumentsPanel(
          user: widget.user,
          // Header owns registration/account status chips.
          showLifecycleStrip: false,
        ),
      ),
      _ActiveTripSection(future: _activeTripFuture, row: row),
      AdminDriverSectionCard(
        title: uiTr(context, 'النشاط والرحلات'),
        children: [
          AdminDriverKvRow(
            label: uiTr(context, 'إجمالي الرحلات'),
            value: row.tripsLabel,
          ),
        ],
      ),
      AdminDriverSectionCard(
        title: uiTr(context, 'الأرباح'),
        children: [
          AdminDriverFinancialPanel(
            driverRef: widget.user.reference,
            countryRef: widget.user.revDolh,
          ),
          AdminDriverKvRow(
            label: uiTr(context, 'إجمالي الأرباح'),
            value: row.earningsLabel,
          ),
        ],
      ),
      AdminDriverSectionCard(
        title: uiTr(context, 'سجل التسجيل والمراجعات'),
        children: [
          AdminDriverKvRow(
            label: uiTr(context, 'تاريخ الإرسال'),
            value: _formatTs(data['submittedAt'] ?? data['submitted_at']),
          ),
          AdminDriverKvRow(
            label: uiTr(context, 'تاريخ الاعتماد'),
            value: _formatTs(data['approvedAt'] ?? data['approved_at']),
          ),
          AdminDriverKvRow(
            label: uiTr(context, 'تاريخ الرفض'),
            value: _formatTs(data['rejectedAt'] ?? data['rejected_at']),
          ),
          AdminDriverKvRow(
            label: uiTr(context, 'طلب تعديلات'),
            value: _formatTs(
              data['changesRequestedAt'] ?? data['changes_requested_at'],
            ),
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
          const SizedBox(height: 8),
          AdminDriverReviewHistoryPanel(driverId: widget.user.reference.id),
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
                onPressed: _actionBusy ? null : () => _openEdit(context),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(uiTr(context, 'تعديل')),
              ),
              if (row.review == AdminDriverReviewBucket.pendingReview ||
                  row.review == AdminDriverReviewBucket.needsChanges)
                AdminPrimaryButton(
                  label: uiTr(context, 'مراجعة التسجيل'),
                  icon: Icons.fact_check_outlined,
                  isLoading: _actionBusy,
                  onPressed: () => _openReview(context),
                ),
              OutlinedButton.icon(
                onPressed: _actionBusy ? null : () => _openDocuments(context),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(uiTr(context, 'عرض الوثائق')),
              ),
              if (row.accountActive)
                OutlinedButton.icon(
                  onPressed: _actionBusy ? null : () => _suspend(context),
                  icon: const Icon(Icons.person_off_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(uiTr(context, 'إيقاف الحساب')),
                )
              else
                AdminPrimaryButton(
                  label: uiTr(context, 'تفعيل الحساب'),
                  icon: Icons.check_circle_outline,
                  isLoading: _actionBusy,
                  onPressed: () => _activate(context),
                ),
            ],
          ),
        ],
      ),
    ];
  }

  String _countryDisplay(Map<String, dynamic> data) {
    final agent = '${data['dolh_agent'] ?? ''}'.trim();
    if (agent.isNotEmpty) return agent;
    final label = AdminDriverProfileView.countryLabel(widget.user);
    return label.isNotEmpty ? label : '—';
  }

  String _regionDisplay(Map<String, dynamic> data) {
    return '${data['region_display'] ?? data['city_display'] ?? ''}'.trim();
  }

  static String _formatTs(dynamic v) {
    if (v == null) return '—';
    if (v is DateTime) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }

  void _openEdit(BuildContext context) {
    context.pushNamed(
      AddDrevWidget.routeName,
      queryParameters: {
        'editUser': serializeParam(widget.userRef, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  void _openReview(BuildContext context) {
    context.pushNamed(
      DriverActivationWidget.routeName,
      queryParameters: {
        'dre': serializeParam(widget.userRef, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  void _openDocuments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: AdminDriverDocumentsPanel(user: widget.user),
          ),
        ),
      ),
    );
  }

  Future<void> _suspend(BuildContext context) async {
    if (_actionBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appTr(context, 'adm_drv_suspend_title')),
        content: Text(appTr(context, 'adm_drv_suspend_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appTr(context, 'adm_confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _actionBusy = true);
    try {
      final adminUid = currentUserUid.isNotEmpty ? currentUserUid : 'admin';
      await widget.userRef.update(
        AdminDriverReviewActions.suspendPatch(
          reason: 'suspended_by_admin',
          adminUid: adminUid,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_drv_suspend_success'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appTr(context, 'adm_deactivate_failed')}: ${AdminUserFacingErrors.from(context, e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _activate(BuildContext context) async {
    if (_actionBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appTr(context, 'adm_drv_activate_profile_title')),
        content: Text(appTr(context, 'adm_drv_activate_profile_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appTr(context, 'adm_confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _actionBusy = true);
    try {
      await widget.userRef.update(
        createUserRecordData(actevMndob: true, ismndob: true, ismndom: true),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_drv_activated_body'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.row});
  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AdminUi.cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminDriverAvatar(
            photoUrl: row.photoUrl,
            displayName: row.displayName,
            size: 72,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayName,
                  style: theme.titleLarge.override(
                    fontFamily: theme.titleLargeFamily,
                    fontWeight: FontWeight.w800,
                    useGoogleFonts: !theme.titleLargeIsCustom,
                  ),
                ),
                if (row.user.email.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AdminDriverEmailLine(
                    email: row.user.email,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  row.phone,
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...AdminDriverStatusStack(
                      row: row,
                      includeOperationalAxes: false,
                    ).buildBadges(context),
                    if (row.onActiveTrip)
                      AdminStatusBadgeUnified(
                        kind: AdminStatusKind.medium,
                        label: uiTr(context, 'في رحلة'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _AdminDriverStatusStackBadges on AdminDriverStatusStack {
  List<Widget> buildBadges(BuildContext context) {
    return [
      AdminStatusBadgeUnified(
        kind: AdminDriverStatusLabels.registrationKind(row.review),
        label: AdminDriverStatusLabels.registration(context, row.review),
      ),
      AdminStatusBadgeUnified(
        kind: AdminDriverStatusLabels.accountKind(row.accountActive),
        label: AdminDriverStatusLabels.account(context, row.accountActive),
      ),
      if (includeOperationalAxes &&
          row.connection != AdminDriverConnectionStatus.unknown)
        AdminStatusBadgeUnified(
          kind: AdminDriverStatusLabels.connectionKind(row.connection),
          label: AdminDriverStatusLabels.connection(context, row.connection),
        ),
      if (includeOperationalAxes &&
          row.availability != AdminDriverAvailabilityStatus.unknown)
        AdminStatusBadgeUnified(
          kind: AdminDriverStatusLabels.availabilityKind(row.availability),
          label: AdminDriverStatusLabels.availability(
            context,
            row.availability,
          ),
        ),
    ];
  }
}

class _QuickSummary extends StatelessWidget {
  const _QuickSummary({required this.row});
  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final chips = <(String, String)>[
      (uiTr(context, 'الرحلات'), row.tripsLabel),
      (uiTr(context, 'الأرباح'), row.earningsLabel),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AdminUi.brandTeal.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AdminUi.brandTeal.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.$1,
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.$2,
                    style: theme.labelLarge.override(
                      fontFamily: theme.labelLargeFamily,
                      fontWeight: FontWeight.w800,
                      color: AdminUi.brandTeal,
                      useGoogleFonts: !theme.labelLargeIsCustom,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActiveTripSection extends StatelessWidget {
  const _ActiveTripSection({required this.future, required this.row});

  final Future<AdminDriverActiveTripTruth> future;
  final AdminDriverRow row;

  @override
  Widget build(BuildContext context) {
    if (!row.onActiveTrip) {
      return AdminDriverSectionCard(
        title: uiTr(context, 'الرحلة الحالية'),
        children: [Text(uiTr(context, 'لا توجد رحلة نشطة'))],
      );
    }

    return FutureBuilder<AdminDriverActiveTripTruth>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return AdminDriverSectionCard(
            title: uiTr(context, 'الرحلة الحالية'),
            children: const [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          );
        }
        final trip = snap.data ?? AdminDriverActiveTripTruth.empty;
        if (!trip.hasLiveTrip || trip.order == null) {
          return AdminDriverSectionCard(
            title: uiTr(context, 'الرحلة الحالية'),
            children: [Text(uiTr(context, 'لا توجد رحلة نشطة'))],
          );
        }
        final o = trip.order!;
        return AdminDriverSectionCard(
          title: uiTr(context, 'الرحلة الحالية'),
          children: [
            AdminDriverKvRow(
              label: uiTr(context, 'رقم الحجز'),
              value: o.reference.id,
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'الحالة'),
              value: trip.statusLabel.isNotEmpty ? trip.statusLabel : '—',
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'العميل'),
              value: o.naimUserText.trim().isNotEmpty ? o.naimUserText : '—',
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'التاريخ'),
              value: o.hasDataOrder()
                  ? dateTimeFormat(
                      'yMMMd',
                      o.dataOrder!,
                      locale: FFLocalizations.of(context).languageCode,
                    )
                  : '—',
            ),
            AdminDriverKvRow(
              label: uiTr(context, 'المدينة'),
              value: trip.row?.city.trim().isNotEmpty == true
                  ? trip.row!.city
                  : (o.villText.trim().isNotEmpty ? o.villText : '—'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.pushNamed(
                  AdminBookingDetailsWidget.routeName,
                  queryParameters: {
                    'idbokeng': serializeParam(
                      o.reference,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(uiTr(context, 'عرض الحجز')),
            ),
          ],
        );
      },
    );
  }
}
