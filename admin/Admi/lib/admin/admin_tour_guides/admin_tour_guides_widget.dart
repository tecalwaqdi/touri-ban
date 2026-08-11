import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/tour_guide_status.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// مراجعة طلبات المرشدين السياحيين (موافقة / رفض / إيقاف).
class AdminTourGuidesWidget extends StatefulWidget {
  const AdminTourGuidesWidget({super.key});

  static const String routeName = 'AdminTourGuides';
  static const String routePath = '/adminTourGuides';

  @override
  State<AdminTourGuidesWidget> createState() => _AdminTourGuidesWidgetState();
}

class _AdminTourGuidesWidgetState extends State<AdminTourGuidesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  final _searchCtrl = TextEditingController();
  String _filter = TourGuideStatus.pending;
  String _query = '';
  Timer? _searchDebounce;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _menu2Model.dispose();
    super.dispose();
  }

  Query _guidesQuery(Query collection) {
    var query = (collection as Query<Map<String, dynamic>>)
        .where(TourGuideStatus.fieldIsTourGuide, isEqualTo: true);
    if (_filter != 'all') {
      query = query.where(
        TourGuideStatus.fieldStatus,
        isEqualTo: _filter,
      );
    }
    final country = AdminCountryScope.activeCountryRef;
    if (AdminRoleService.isCountryAgent && country != null) {
      query = query.where('Rev_dolh', isEqualTo: country);
    }
    return query.orderBy(FieldPath.documentId);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _setFilter(String value) {
    if (_filter == value) return;
    setState(() => _filter = value);
  }

  bool _inScope(UserRecord user) {
    if (!AdminRoleService.isCountryAgent) return true;
    final country = AdminCountryScope.activeCountryRef;
    if (country == null) return false;
    final rev = user.revDolh;
    final agent = user.revDlohAgent;
    return rev?.path == country.path || agent?.path == country.path;
  }

  List<UserRecord> _filtered(List<UserRecord> users) {
    final scoped = users.where(_inScope);
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return scoped.toList();
    return scoped.where((u) {
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phoneNumber.toLowerCase().contains(q) ||
          u.transportCompanyText.toLowerCase().contains(q) ||
          u.mndobVillText.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _guardedAction(
    UserRecord user,
    Future<void> Function() action,
  ) async {
    if (!_inScope(user)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'ent_guides_out_of_scope'))),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(UserRecord user) async {
    await _guardedAction(user, () async {
      final ok = await showAdminConfirmDialog(
        context,
        title: appTr(context, 'ent_guides_approve_title'),
        message: appTrFormat(context, 'ent_guides_approve_msg', user.displayName),
        confirmLabel: appTr(context, 'ent_guides_approve'),
        cancelLabel: appTr(context, 'ent_cancel'),
      );
      if (!ok) return;
      await user.reference.update({
        TourGuideStatus.fieldIsTourGuide: true,
        TourGuideStatus.fieldStatus: TourGuideStatus.approved,
        TourGuideStatus.fieldReviewedAt: FieldValue.serverTimestamp(),
        TourGuideStatus.fieldRejectionReason: '',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'ent_guides_approved_snack'))),
      );
    });
  }

  Future<void> _reject(UserRecord user) async {
    await _guardedAction(user, () async {
      final reasonCtrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(appTr(ctx, 'ent_guides_reject_title')),
          content: TextField(
            controller: reasonCtrl,
            decoration: InputDecoration(
              labelText: appTr(ctx, 'ent_guides_reject_reason'),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(appTr(ctx, 'ent_cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(appTr(ctx, 'ent_guides_reject')),
            ),
          ],
        ),
      );
      if (ok != true) {
        reasonCtrl.dispose();
        return;
      }
      await user.reference.update({
        TourGuideStatus.fieldStatus: TourGuideStatus.rejected,
        TourGuideStatus.fieldReviewedAt: FieldValue.serverTimestamp(),
        TourGuideStatus.fieldRejectionReason: reasonCtrl.text.trim(),
      });
      reasonCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'ent_guides_rejected_snack'))),
      );
    });
  }

  Future<void> _suspend(UserRecord user) async {
    await _guardedAction(user, () async {
      final ok = await showAdminConfirmDialog(
        context,
        title: appTr(context, 'ent_guides_suspend_title'),
        message:
            appTrFormat(context, 'ent_guides_suspend_msg', user.displayName),
        confirmLabel: appTr(context, 'ent_guides_suspend'),
        cancelLabel: appTr(context, 'ent_cancel'),
      );
      if (!ok) return;
      await user.reference.update({
        TourGuideStatus.fieldStatus: TourGuideStatus.suspended,
        TourGuideStatus.fieldReviewedAt: FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'ent_guides_suspended_snack'))),
      );
    });
  }

  Future<void> _reactivate(UserRecord user) async {
    await _guardedAction(user, () async {
      final ok = await showAdminConfirmDialog(
        context,
        title: appTr(context, 'ent_guides_reactivate_title'),
        message: appTrFormat(
          context,
          'ent_guides_reactivate_msg',
          user.displayName,
        ),
        confirmLabel: appTr(context, 'ent_guides_reactivate'),
        cancelLabel: appTr(context, 'ent_cancel'),
      );
      if (!ok) return;
      await user.reference.update({
        TourGuideStatus.fieldIsTourGuide: true,
        TourGuideStatus.fieldStatus: TourGuideStatus.approved,
        TourGuideStatus.fieldReviewedAt: FieldValue.serverTimestamp(),
        TourGuideStatus.fieldRejectionReason: '',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'ent_guides_reactivated_snack'))),
      );
    });
  }

  AdminBadgeTone _tone(String status) {
    switch (status) {
      case TourGuideStatus.approved:
        return AdminBadgeTone.success;
      case TourGuideStatus.pending:
        return AdminBadgeTone.warning;
      case TourGuideStatus.rejected:
      case TourGuideStatus.suspended:
        return AdminBadgeTone.danger;
      default:
        return AdminBadgeTone.neutral;
    }
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case TourGuideStatus.approved:
        return appTr(context, 'ent_guides_approved');
      case TourGuideStatus.pending:
        return appTr(context, 'ent_guides_pending');
      case TourGuideStatus.rejected:
        return appTr(context, 'ent_guides_rejected');
      case TourGuideStatus.suspended:
        return appTr(context, 'ent_guides_suspended');
      default:
        return status;
    }
  }

  String _countryLabel(UserRecord user) {
    final scoped = AdminCountryScope.activeCountryLabel;
    if (AdminRoleService.isCountryAgent && scoped.isNotEmpty) return scoped;
    final path = user.revDolh?.id ?? user.revDlohAgent?.id ?? '';
    if (path.isEmpty) return '—';
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: appTr(context, 'ent_guides_title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            title: appTr(context, 'ent_guides_title'),
            subtitle: appTr(context, 'ent_guides_subtitle'),
          ),
          AdminFilterBar(
            controller: _searchCtrl,
            hint: appTr(context, 'ent_guides_search_hint'),
            onChanged: _onSearchChanged,
            chips: [
              AdminFilterChip(
                label: appTr(context, 'ent_guides_pending'),
                selected: _filter == TourGuideStatus.pending,
                onSelected: (_) => _setFilter(TourGuideStatus.pending),
              ),
              AdminFilterChip(
                label: appTr(context, 'ent_guides_approved_plural'),
                selected: _filter == TourGuideStatus.approved,
                onSelected: (_) => _setFilter(TourGuideStatus.approved),
              ),
              AdminFilterChip(
                label: appTr(context, 'ent_guides_rejected_plural'),
                selected: _filter == TourGuideStatus.rejected,
                onSelected: (_) => _setFilter(TourGuideStatus.rejected),
              ),
              AdminFilterChip(
                label: appTr(context, 'ent_guides_suspended_plural'),
                selected: _filter == TourGuideStatus.suspended,
                onSelected: (_) => _setFilter(TourGuideStatus.suspended),
              ),
              AdminFilterChip(
                label: appTr(context, 'ent_all'),
                selected: _filter == 'all',
                onSelected: (_) => _setFilter('all'),
              ),
            ],
          ),
          Expanded(
            child: AdminFirestoreList<UserRecord>(
              key: ValueKey('tour_guides_$_filter'),
              query: UserRecord.collection,
              recordBuilder: UserRecord.fromSnapshot,
              pageSize: kAdminPageSize,
              queryBuilder: _guidesQuery,
              builder: (context, allGuides, listState) {
                final list = _filtered(allGuides);
                if (list.isEmpty && !listState.isLoading) {
                  return AdminEmptyState(
                    title: appTr(context, 'ent_guides_empty'),
                    message: appTr(context, 'ent_guides_empty_hint'),
                    icon: Icons.tour_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: list.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == list.length) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              adminListCountLabel(
                                context,
                                listState,
                                visibleCount: list.length,
                                pageFetched: allGuides.length,
                              ),
                              style: theme.labelMedium,
                            ),
                          ),
                          AdminListLoadMoreFooter(state: listState),
                        ],
                      );
                    }
                    final user = list[index];
                    final data = user.snapshotData;
                    final status = (data[TourGuideStatus.fieldStatus]
                            as String?) ??
                        user.tourGuideStatus;
                    final permit = user.tourGuidePermitUrl.isNotEmpty
                        ? user.tourGuidePermitUrl
                        : ((data[TourGuideStatus.fieldPermitUrl] as String?) ??
                            '');
                    final idDoc = user.imgIdRksh.isNotEmpty
                        ? user.imgIdRksh
                        : user.imgId;
                    final registered = user.createdTime;
                    return AdminContentCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                AdminUi.brandTeal.withValues(alpha: 0.12),
                            backgroundImage: user.photoUrl.isNotEmpty
                                ? NetworkImage(user.photoUrl)
                                : null,
                            child: user.photoUrl.isEmpty
                                ? const Icon(Icons.person,
                                    color: AdminUi.brandTeal)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName
                                      : appTr(context, 'ent_guides_unnamed'),
                                  style: theme.titleMedium.override(
                                    fontFamily: theme.titleMediumFamily,
                                    fontWeight: FontWeight.w700,
                                    useGoogleFonts:
                                        !theme.titleMediumIsCustom,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    '${appTr(context, 'ent_guides_country')}: ${_countryLabel(user)}',
                                    if (user.phoneNumber.isNotEmpty)
                                      user.phoneNumber,
                                    if (user.email.isNotEmpty) user.email,
                                    if (user.transportCompanyText.isNotEmpty)
                                      user.transportCompanyText,
                                    if (user.textTypeCarMndob.isNotEmpty ||
                                        user.mndobVillText.isNotEmpty)
                                      '${appTr(context, 'ent_guides_vehicle')}: ${[
                                        if (user.textTypeCarMndob.isNotEmpty)
                                          user.textTypeCarMndob,
                                        if (user.mndobVillText.isNotEmpty)
                                          user.mndobVillText,
                                      ].join(' · ')}',
                                    if (registered != null)
                                      '${appTr(context, 'ent_guides_registered')}: ${dateTimeFormat('yMMMd', registered)}',
                                  ].join('\n'),
                                  style: theme.bodySmall.override(
                                    fontFamily: theme.bodySmallFamily,
                                    color: theme.secondaryText,
                                    useGoogleFonts: !theme.bodySmallIsCustom,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AdminStatusBadge(
                                  label: _statusLabel(context, status),
                                  tone: _tone(status),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (permit.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () => launchURL(permit),
                                        icon: const Icon(Icons.badge_outlined),
                                        label: Text(appTr(
                                            context, 'ent_guides_view_permit')),
                                      ),
                                    if (idDoc.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () => launchURL(idDoc),
                                        icon: const Icon(Icons.credit_card),
                                        label: Text(appTr(
                                            context, 'ent_guides_id_doc')),
                                      ),
                                    if (user.imgIdCar.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () =>
                                            launchURL(user.imgIdCar),
                                        icon: const Icon(
                                            Icons.directions_car_outlined),
                                        label: Text(appTr(
                                            context, 'ent_guides_vehicle')),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (status == TourGuideStatus.pending) ...[
                                AdminPrimaryButton(
                                  label: appTr(context, 'ent_guides_approve'),
                                  icon: Icons.check_rounded,
                                  onPressed:
                                      _busy ? null : () => _approve(user),
                                ),
                                const SizedBox(height: 8),
                                AdminPrimaryButton(
                                  label: appTr(context, 'ent_guides_reject'),
                                  outlined: true,
                                  icon: Icons.close_rounded,
                                  onPressed:
                                      _busy ? null : () => _reject(user),
                                ),
                              ],
                              if (status == TourGuideStatus.approved) ...[
                                AdminPrimaryButton(
                                  label: appTr(context, 'ent_guides_suspend'),
                                  outlined: true,
                                  icon: Icons.pause_circle_outline,
                                  onPressed:
                                      _busy ? null : () => _suspend(user),
                                ),
                              ],
                              if (status == TourGuideStatus.suspended ||
                                  status == TourGuideStatus.rejected) ...[
                                AdminPrimaryButton(
                                  label:
                                      appTr(context, 'ent_guides_reactivate'),
                                  icon: Icons.play_circle_outline,
                                  onPressed:
                                      _busy ? null : () => _reactivate(user),
                                ),
                              ],
                              TextButton(
                                onPressed: () => context.pushNamed(
                                  DriverProfileWidget.routeName,
                                  queryParameters: {
                                    'iduser': serializeParam(
                                      user.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                ),
                                child: Text(
                                    appTr(context, 'ent_guides_profile')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
