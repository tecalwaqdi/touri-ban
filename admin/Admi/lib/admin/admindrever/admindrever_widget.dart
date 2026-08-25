import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_dashboard_invalidate.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/admin_unknown_drivers_loader.dart';
import '/backend/backend.dart';
import '/backend/driver_admin_stats_loader.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_driver_counters_strip.dart';
import '/components/admin_driver_documents_panel.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_enterprise_kit.dart' hide showAdminConfirmDialog;
import '/components/admin_layout_widget.dart';
import '/components/admin_ops_filter_bar.dart';
import '/components/admin_status_badge.dart';
import '/components/admin_ui.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'admindrever_model.dart';
export 'admindrever_model.dart';

class AdmindreverWidget extends StatefulWidget {
  const AdmindreverWidget({super.key});

  static String routeName = 'Admindrever';
  static String routePath = '/drever';

  @override
  State<AdmindreverWidget> createState() => _AdmindreverWidgetState();
}

class _AdmindreverWidgetState extends State<AdmindreverWidget> {
  late AdmindreverModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  AdminOpsFilterState _filters = const AdminOpsFilterState();
  DriverAdminStats _stats = DriverAdminStats.empty;
  bool _statsLoading = true;
  bool _statsError = false;
  String _tableQaLabel = 'visible:0 total:0 empty:false loading:true';

  void _syncTableQaLabel(String next) {
    if (_tableQaLabel == next || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tableQaLabel == next) return;
      setState(() => _tableQaLabel = next);
    });
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdmindreverModel());

    if (AdminRoleService.isCountryAgent) {
      AdminAgentCountryLock.applyToAppState();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeSetState(() {});
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = false;
      _tableQaLabel = 'visible:0 total:0 empty:false loading:true';
    });
    try {
      final s = await DriverAdminStatsLoader.load(
        filters: _filters,
      );
      if (!mounted) return;
      setState(() {
        _stats = s;
        _statsLoading = false;
        _tableQaLabel =
            'visible:0 total:${s.total} empty:${s.total == 0}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statsError = true;
        _statsLoading = false;
      });
    }
  }

  List<UserRecord> _filterReps(List<UserRecord> reps) {
    var out = reps;

    // Unknown legacy review remains client-side (no single equality query).
    if (_filters.driverReview == AdminDriverReviewFilter.unknownLegacy) {
      out = out
          .where(
            (r) =>
                AdminDriverProfileView.reviewBucket(r) ==
                AdminDriverReviewBucket.unknownLegacy,
          )
          .toList(growable: false);
    }

    final q = _filters.searchQuery.trim().toLowerCase();
    if (q.isEmpty) return out;
    return out.where((r) {
      final vehicle = AdminDriverProfileView.vehicle(r);
      return r.displayName.toLowerCase().contains(q) ||
          r.phoneNumber.toLowerCase().contains(q) ||
          r.mndobVillText.toLowerCase().contains(q) ||
          r.transportCompanyText.toLowerCase().contains(q) ||
          r.email.toLowerCase().contains(q) ||
          r.reference.id.toLowerCase().contains(q) ||
          r.driverid.toLowerCase().contains(q) ||
          vehicle.plate.toLowerCase().contains(q) ||
          vehicle.name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _toggleActivation(UserRecord user, {required bool activate}) async {
    final title = activate ? uiTr(context, 'تأكيد التفعيل') : uiTr(context, 'تأكيد الإيقاف');
    final content = activate
        ? uiTr(context, 'هل أنت متأكد من تفعيل المندوب؟')
        : uiTr(context, 'هل أنت متأكد من إيقاف المندوب؟');

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: title,
      whatHappens: content,
      subject: user.displayName.isNotEmpty ? user.displayName : user.reference.id,
      impact: activate
          ? uiTr(context, 'Driver can receive bookings again')
          : uiTr(context, 'Driver will no longer receive bookings'),
      confirmLabel: uiTr(context, 'نعم'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: !activate,
      irreversible: false,
      reference: user.reference.id,
    );

    if (!confirmed) return;

    try {
      await user.reference.update(
        createUserRecordData(actevMndob: activate),
      );
      AdminStatsCoordinator.instance.invalidateAfterUserChange();
      flushAdminDashboardStatsNow();
      await AdminAuditLog.recordToggle(
        targetType: 'driver',
        targetId: user.reference.id,
        targetLabel: user.displayName,
        activated: activate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate ? uiTr(context, 'تم تفعيل المندوب بنجاح') : uiTr(context, 'تم إيقاف المندوب بنجاح'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);
    final isWide = AdminUi.useTableLayout(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        padContent: false,
        title: l10n.getText('xqeazwes'),
        child: AdminPageBody(
          title: l10n.getText('xqeazwes'),
          subtitle: appTr(context, 'scr_reps_subtitle'),
          scrollable: true,
          child: Semantics(
            identifier: 'qa-driver-list',
            label: 'qa-driver-list',
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminOpsFilterBar(
                value: _filters,
                config: const AdminOpsFilterConfig(
                  showDate: true,
                  showDriverActivation: true,
                  showDriverReview: true,
                  showDriverDocuments: true,
                  showDriverVehicleType: true,
                  showCountry: true,
                  showRegion: true,
                  showCity: true,
                  showSearch: true,
                  searchHint:
                      'بحث: اسم / هاتف / بريد / معرف / لوحة (الاسم على الصفحة الحالية)',
                ),
                onChanged: (next) {
                  setState(() => _filters = next);
                  _loadStats();
                },
              ),
              Semantics(
                identifier: 'qa-driver-filter-signature',
                container: true,
                label: _filters.qaEvidenceSignature,
                child: const SizedBox.shrink(),
              ),
              Semantics(
                identifier: 'qa-driver-filter-country',
                container: true,
                label: _filters.qaCountryToken,
                child: const SizedBox.shrink(),
              ),
              Semantics(
                identifier: 'qa-driver-filter-status',
                container: true,
                label: _filters.qaStatusToken,
                child: const SizedBox.shrink(),
              ),
              Semantics(
                identifier: 'qa-driver-filter-vehicle',
                container: true,
                label: _filters.qaVehicleToken,
                child: const SizedBox.shrink(),
              ),
              Semantics(
                identifier: 'qa-driver-filter-documents',
                container: true,
                label: _filters.qaDocumentsToken,
                child: const SizedBox.shrink(),
              ),
              Semantics(
                identifier: 'qa-driver-filter-date',
                container: true,
                label: _filters.qaDateToken,
                child: const SizedBox.shrink(),
              ),
              Semantics(
                identifier: 'qa-driver-filter-activation',
                container: true,
                label: _filters.qaActivationToken,
                child: const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              AdminDriverCountersStrip(
                stats: _stats,
                loading: _statsLoading,
                error: _statsError,
                onRetry: _loadStats,
              ),
              Semantics(
                identifier: 'qa-driver-table-total',
                container: true,
                label: _tableQaLabel,
                child: const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _buildAddButton(l10n),
              ),
              const SizedBox(height: 16),
              if (_filters.driverActivation ==
                  AdminDriverActivationFilter.unknown)
                _UnknownDriversPanel(
                  filters: _filters,
                  l10n: l10n,
                  isWide: isWide,
                  onToggle: _toggleActivation,
                )
              else
                AdminFirestoreList<UserRecord>(
                  key: ValueKey('drivers_${_filters.signature}'),
                  reloadKey: _filters.signature,
                  refreshScope: AdminListScope.representatives,
                  query: UserRecord.collection,
                  recordBuilder: UserRecord.fromSnapshot,
                  queryBuilder: (q) =>
                      AdminOpsQueryBuilder.applyDriverFilters(q, _filters),
                  loading: Semantics(
                    identifier: 'qa-driver-table-total',
                    container: true,
                    label: 'visible:0 total:0 empty:false loading:true',
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  ),
                  builder: (context, allReps, listState) {
                    final reps = _filterReps(allReps);

                    final serverTotal =
                        listState.totalAvailable ?? allReps.length;
                    final tableSemanticsLabel =
                        'visible:${reps.length} total:$serverTotal empty:${reps.isEmpty}';
                    _syncTableQaLabel(tableSemanticsLabel);

                    return AdminContentCard(
                      padding: reps.isEmpty
                          ? const EdgeInsets.all(16)
                          : const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Semantics(
                              identifier: 'qa-driver-table-total',
                              container: true,
                              label: tableSemanticsLabel,
                              child: Text(
                                adminListCountLabel(
                                  context,
                                  listState,
                                  visibleCount: reps.length,
                                  pageFetched: allReps.length,
                                ),
                                style: theme.labelLarge.override(
                                  fontFamily: theme.labelLargeFamily,
                                  color: theme.secondaryText,
                                  useGoogleFonts: !theme.labelLargeIsCustom,
                                ),
                              ),
                            ),
                          ),
                          if (reps.isEmpty)
                            Semantics(
                              identifier: 'qa-driver-empty-state',
                              container: true,
                              label: 'qa-driver-empty-state=true',
                              child: AdminEmptyState(
                                title: _filters.searchQuery.isEmpty
                                    ? uiTr(context, 'لا يوجد مناديب مسجلون')
                                    : uiTr(context, 'لا توجد نتائج للبحث'),
                                message: _filters.searchQuery.isEmpty
                                    ? uiTr(
                                        context,
                                        'أضف مندوبًا جديدًا أو راجع فلتر الدولة',
                                      )
                                    : uiTr(context, 'جرّب كلمة بحث أخرى'),
                                icon: Icons.directions_car_outlined,
                              ),
                            )
                          else if (isWide)
                            _RepresentativesTable(
                              reps: reps,
                              l10n: l10n,
                              onToggle: _toggleActivation,
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: reps.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) => _RepresentativeCard(
                                user: reps[index],
                                l10n: l10n,
                                onToggle: _toggleActivation,
                              ),
                            ),
                          if (reps.isNotEmpty)
                            AdminListLoadMoreFooter(state: listState),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: uiTr(context, 'إضافة مندوب جديد'),
      icon: Icons.person_add_rounded,
      onPressed: () => context.pushNamed(AddDrevWidget.routeName),
    );
  }
}

/// Scans drivers missing `actev_mndob` with correct [totalUnknown] Aggregate.
class _UnknownDriversPanel extends StatefulWidget {
  const _UnknownDriversPanel({
    required this.filters,
    required this.l10n,
    required this.isWide,
    required this.onToggle,
  });

  final AdminOpsFilterState filters;
  final FFLocalizations l10n;
  final bool isWide;
  final Future<void> Function(UserRecord user, {required bool activate}) onToggle;

  @override
  State<_UnknownDriversPanel> createState() => _UnknownDriversPanelState();
}

class _UnknownDriversPanelState extends State<_UnknownDriversPanel> {
  final List<UserRecord> _items = [];
  DocumentSnapshot? _cursor;
  int _scanned = 0;
  int _totalUnknown = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _hitCap = false;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant _UnknownDriversPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.signature != widget.filters.signature) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _cursor = null;
      _scanned = 0;
      _hasMore = true;
      _hitCap = false;
    });
    try {
      final page = await AdminUnknownDriversLoader.loadPage(
        filters: widget.filters,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.drivers);
        _cursor = page.scanCursor;
        _scanned = page.docsScanned;
        _totalUnknown = page.totalUnknown;
        _hasMore = page.hasMore;
        _hitCap = page.hitScanCap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _hitCap) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await AdminUnknownDriversLoader.loadPage(
        filters: widget.filters,
        after: _cursor,
        alreadyScanned: _scanned,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(page.drivers);
        _cursor = page.scanCursor;
        _scanned = page.docsScanned;
        _totalUnknown = page.totalUnknown;
        _hasMore = page.hasMore;
        _hitCap = page.hitScanCap;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (_loading) {
      return AdminContentCard(
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null && _items.isEmpty) {
      return AdminContentCard(
        child: Column(
          children: [
            Text(uiTr(context, 'تعذر تحميل المناديب غير المحددين')),
            TextButton(onPressed: _reload, child: Text(appTr(context, 'adm_retry'))),
          ],
        ),
      );
    }

    return AdminContentCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${uiTr(context, 'حالة غير محددة')}: ${_items.length} / $_totalUnknown',
            style: theme.labelLarge.override(
              fontFamily: theme.labelLargeFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelLargeIsCustom,
            ),
          ),
          if (_hitCap)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                uiTr(context, 'تم بلوغ حد المسح — راجع لاحقًا أو صفّ الحقل actev_mndob'),
                style: theme.labelSmall,
              ),
            ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            AdminEmptyState(
              title: uiTr(context, 'لا يوجد مناديب بحالة غير محددة'),
              message: uiTr(context, 'جميع المندوبين لديهم actev_mndob'),
              icon: Icons.verified_outlined,
            )
          else if (widget.isWide)
            _RepresentativesTable(
              reps: _items,
              l10n: widget.l10n,
              onToggle: widget.onToggle,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _RepresentativeCard(
                user: _items[index],
                l10n: widget.l10n,
                onToggle: widget.onToggle,
              ),
            ),
          if (_hasMore && !_hitCap)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(uiTr(context, 'تحميل المزيد')),
              ),
            ),
        ],
      ),
    );
  }
}

class _RepresentativesTable extends StatelessWidget {
  const _RepresentativesTable({
    required this.reps,
    required this.l10n,
    required this.onToggle,
  });

  final List<UserRecord> reps;
  final FFLocalizations l10n;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        width: AdminUi.adminTableMinWidth(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableHeaderRow(l10n: l10n, theme: theme),
            const Divider(height: 1),
            ...reps.map(
              (user) => _TableDataRow(
                user: user,
                l10n: l10n,
                theme: theme,
                onToggle: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.l10n, required this.theme});

  final FFLocalizations l10n;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _HeaderCell(uiTr(context, 'المندوب'), flex: 3, theme: theme),
          _HeaderCell(uiTr(context, 'الهاتف'), flex: 2, theme: theme),
          _HeaderCell(uiTr(context, 'المدينة'), flex: 2, theme: theme),
          _HeaderCell(uiTr(context, 'السيارة'), flex: 3, theme: theme),
          _HeaderCell(uiTr(context, 'المراجعة'), flex: 2, theme: theme),
          _HeaderCell(uiTr(context, 'التفعيل'), flex: 2, theme: theme),
          _HeaderCell(uiTr(context, 'إجراءات'), flex: 2, theme: theme),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, required this.theme});

  final String text;
  final int flex;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text.trim(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.labelLarge.override(
          fontFamily: theme.labelLargeFamily,
          fontWeight: FontWeight.w700,
          color: AdminUi.brandTeal,
          useGoogleFonts: !theme.labelLargeIsCustom,
        ),
      ),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.user,
    required this.l10n,
    required this.theme,
    required this.onToggle,
  });

  final UserRecord user;
  final FFLocalizations l10n;
  final FlutterFlowTheme theme;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    final vehicle = AdminDriverProfileView.vehicle(user);
    final review = AdminDriverProfileView.reviewBucket(user);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.alternate.withValues(alpha: 0.6),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _NameCell(user: user, theme: theme),
          ),
          Expanded(
            flex: 2,
            child: _DataCell(
              user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
              theme: theme,
              monospace: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: _DataCell(
              user.mndobVillText.isNotEmpty ? user.mndobVillText : '—',
              theme: theme,
            ),
          ),
          Expanded(
            flex: 3,
            child: _DataCell(
              vehicle.isLegacyIncomplete
                  ? uiTr(context, 'Missing / Legacy')
                  : vehicle.oneLine,
              theme: theme,
            ),
          ),
          Expanded(
            flex: 2,
            child: AdminStatusBadgeUnified(
              kind: AdminDriverProfileView.reviewBadgeKind(review),
              label: AdminDriverProfileView.reviewLabel(context, review),
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusBadge(active: user.actevMndob),
          ),
          Expanded(
            flex: 2,
            child: _ActionButtons(user: user, onToggle: onToggle),
          ),
        ],
      ),
    );
  }
}

class _RepresentativeCard extends StatelessWidget {
  const _RepresentativeCard({
    required this.user,
    required this.l10n,
    required this.onToggle,
  });

  final UserRecord user;
  final FFLocalizations l10n;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: AdminUi.cardDecoration(context, elevated: false).copyWith(
        color: theme.primaryBackground,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(user: user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        color: theme.error,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(active: user.actevMndob),
                  ],
                ),
              ),
              _ActionButtons(user: user, onToggle: onToggle),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (user.transportCompanyText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfoTile(
                icon: Icons.local_shipping_outlined,
                label: uiTr(context, 'شركة النقل'),
                value: user.transportCompanyText,
              ),
            ),
          _InfoTile(
            icon: Icons.location_city_rounded,
            label: l10n.getText('py60u4hw'),
            value: user.mndobVillText.isNotEmpty ? user.mndobVillText : '—',
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.getText('u207wx5e'),
            value: user.totalApp.toStringAsFixed(0),
            highlight: true,
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.phone_rounded,
            label: l10n.getText('qrv84p3x'),
            value: user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AdminUi.brandTeal.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.trim(),
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: (highlight ? theme.titleSmall : theme.bodyMedium).override(
                  fontFamily: highlight
                      ? theme.titleSmallFamily
                      : theme.bodyMediumFamily,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  useGoogleFonts: highlight
                      ? !theme.titleSmallIsCustom
                      : !theme.bodyMediumIsCustom,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.user, required this.theme});

  final UserRecord user;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(user: user, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            user.displayName.isNotEmpty ? user.displayName : '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              fontWeight: FontWeight.w600,
              color: theme.error,
              useGoogleFonts: !theme.bodyMediumIsCustom,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.text, {
    required this.theme,
    this.monospace = false,
  }) : bold = false;

  final String text;
  final FlutterFlowTheme theme;
  final bool bold;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.bodyMedium.override(
          fontFamily: monospace ? 'monospace' : theme.bodyMediumFamily,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          useGoogleFonts: !monospace && !theme.bodyMediumIsCustom,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.size = 44});

  final UserRecord user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AdminUi.brandTeal.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdminRecordThumbnail(
        imageUrl: user.photoUrl,
        width: size,
        height: size,
        fallback: _AvatarFallback(size: size),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      color: AdminUi.brandTeal,
      size: size * 0.5,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = active ? const Color(0xFF2E7D32) : theme.error;
    final bg = active ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final label = active ? uiTr(context, 'نشط') : uiTr(context, 'موقوف');

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: color,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.user,
    required this.onToggle,
  });

  final UserRecord user;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFE3F2FD),
          icon: Icon(
            Icons.edit_outlined,
            color: FlutterFlowTheme.of(context).primary,
            size: 18,
          ),
          onPressed: () {
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
        ),
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
          icon: Icon(
            Icons.visibility_outlined,
            color: AdminUi.brandTeal,
            size: 18,
          ),
          onPressed: () {
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
        ),
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFFFF3E0),
          icon: const Icon(
            Icons.folder_open_outlined,
            color: Color(0xFFEF6C00),
            size: 18,
          ),
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: AdminDriverDocumentsPanel(user: user),
                  ),
                ),
              ),
            );
          },
        ),
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFE8EAF6),
          icon: const Icon(
            Icons.fact_check_outlined,
            color: Color(0xFF3949AB),
            size: 18,
          ),
          onPressed: () {
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
        if (user.actevMndob)
          FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 36,
            fillColor: const Color(0xFFFFEBEE),
            icon: Icon(
              Icons.block_rounded,
              color: FlutterFlowTheme.of(context).error,
              size: 18,
            ),
            onPressed: () => onToggle(user, activate: false),
          )
        else
          FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 36,
            fillColor: const Color(0xFFE8F5E9),
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: FlutterFlowTheme.of(context).success,
              size: 18,
            ),
            onPressed: () => onToggle(user, activate: true),
          ),
      ],
    );
  }
}
