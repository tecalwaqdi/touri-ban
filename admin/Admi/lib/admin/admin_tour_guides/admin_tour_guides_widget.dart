import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/tour_guide_status.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// مراجعة طلبات المرشدين السياحيين (موافقة / رفض).
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
  Stream<List<UserRecord>>? _stream;
  String? _streamKey;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _ensureStream();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _menu2Model.dispose();
    super.dispose();
  }

  void _ensureStream() {
    final key = _filter;
    if (_stream != null && _streamKey == key) return;
    _streamKey = key;
    _stream = queryUserRecord(
      queryBuilder: (q) {
        var query = q.where(TourGuideStatus.fieldIsTourGuide, isEqualTo: true);
        if (_filter != 'all') {
          query = query.where(
            TourGuideStatus.fieldStatus,
            isEqualTo: _filter,
          );
        }
        return query.limit(120);
      },
    );
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
    setState(() {
      _filter = value;
      _ensureStream();
    });
  }

  List<UserRecord> _scoped(List<UserRecord> users) {
    if (!AdminRoleService.isCountryAgent) return users;
    final country = AdminCountryScope.activeCountryRef;
    if (country == null) return users;
    return users.where((u) {
      final rev = u.revDolh;
      final agent = u.revDlohAgent;
      return rev?.path == country.path || agent?.path == country.path;
    }).toList();
  }

  List<UserRecord> _filtered(List<UserRecord> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phoneNumber.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _approve(UserRecord user) async {
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
  }

  Future<void> _reject(UserRecord user) async {
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
    if (ok != true) return;
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
  }

  AdminBadgeTone _tone(String status) {
    switch (status) {
      case TourGuideStatus.approved:
        return AdminBadgeTone.success;
      case TourGuideStatus.pending:
        return AdminBadgeTone.warning;
      case TourGuideStatus.rejected:
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
      default:
        return status;
    }
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
                label: appTr(context, 'ent_all'),
                selected: _filter == 'all',
                onSelected: (_) => _setFilter('all'),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<UserRecord>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AdminEmptyState(
                    title: appTr(context, 'ent_guides_load_failed'),
                    message: snapshot.error.toString(),
                    icon: Icons.error_outline,
                  );
                }
                if (!snapshot.hasData) {
                  return AdminLoadingState(
                      label: appTr(context, 'ent_loading'));
                }
                final list = _filtered(_scoped(snapshot.data!));
                if (list.isEmpty) {
                  return AdminEmptyState(
                    title: appTr(context, 'ent_guides_empty'),
                    message: appTr(context, 'ent_guides_empty_hint'),
                    icon: Icons.tour_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = list[index];
                    final data = user.snapshotData;
                    final status = (data[TourGuideStatus.fieldStatus]
                            as String?) ??
                        TourGuideStatus.none;
                    final permit =
                        (data[TourGuideStatus.fieldPermitUrl] as String?) ??
                            '';
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
                                    if (user.phoneNumber.isNotEmpty)
                                      user.phoneNumber,
                                    if (user.email.isNotEmpty) user.email,
                                    if (user.transportCompanyText.isNotEmpty)
                                      user.transportCompanyText,
                                  ].join(' · '),
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
                                if (permit.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: () {
                                      launchURL(permit);
                                    },
                                    icon: const Icon(Icons.badge_outlined),
                                    label: Text(
                                        appTr(context, 'ent_guides_view_permit')),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (status == TourGuideStatus.pending) ...[
                                AdminPrimaryButton(
                                  label: appTr(context, 'ent_guides_approve'),
                                  icon: Icons.check_rounded,
                                  onPressed: () => _approve(user),
                                ),
                                const SizedBox(height: 8),
                                AdminPrimaryButton(
                                  label: appTr(context, 'ent_guides_reject'),
                                  outlined: true,
                                  icon: Icons.close_rounded,
                                  onPressed: () => _reject(user),
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
