import '/admin/admindrever/admin_drivers_adapter.dart';
import '/admin/admindrever/admin_drivers_details_drawer.dart';
import '/admin/admindrever/admin_drivers_filter_bar.dart';
import '/admin/admindrever/admin_drivers_query.dart';
import '/admin/admindrever/admin_drivers_summary_strip.dart';
import '/admin/admindrever/admin_drivers_table.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_dashboard_invalidate.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/admin_unknown_drivers_loader.dart';
import '/backend/backend.dart';
import '/backend/driver_admin_stats_loader.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_driver_documents_panel.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_enterprise_kit.dart' hide showAdminConfirmDialog;
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
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
  AdminDriversExtraFilters _extra = AdminDriversExtraFilters.empty;
  int _pageSize = 20;
  DriverAdminStats _stats = DriverAdminStats.empty;
  bool _statsLoading = true;
  bool _statsError = false;
  String _tableQaLabel = 'visible:0 total:0 empty:false loading:true';
  List<UserRecord>? _serverSearchHits;
  bool _serverSearching = false;

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
      // Load summary stats only — do not empty setState (that rebuilt the
      // list tree and historically retriggered full reloads).
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = false;
    });
    try {
      final s = await DriverAdminStatsLoader.load(filters: _filters);
      if (!mounted) return;
      setState(() {
        _stats = s;
        _statsLoading = false;
        final match = RegExp(r'visible:(\d+)').firstMatch(_tableQaLabel);
        final visible = match?.group(1) ?? '0';
        _tableQaLabel =
            'visible:$visible total:${s.total} empty:${s.total == 0}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statsError = true;
        _statsLoading = false;
      });
    }
  }

  Future<void> _onFiltersChanged(AdminOpsFilterState next) async {
    setState(() {
      _filters = next;
      _serverSearchHits = null;
    });
    _loadStats();
    await _maybeServerSearch(next);
  }

  Future<void> _maybeServerSearch(AdminOpsFilterState filters) async {
    final plan = AdminOpsSearch.classify(filters.searchQuery);
    if (!plan.isServerSide) {
      if (_serverSearchHits != null) {
        setState(() => _serverSearchHits = null);
      }
      return;
    }
    setState(() => _serverSearching = true);
    try {
      final hits = await AdminOpsSearch.searchUsersServer(plan, filters);
      if (!mounted) return;
      // Keep drivers only.
      // Driver App treats ismndob || ismndom as driver.
      final drivers = hits
          .where((u) => u.ismndob == true || u.ismndom == true)
          .toList();
      setState(() {
        _serverSearchHits = drivers;
        _serverSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serverSearchHits = null;
        _serverSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _toggleActivation(
    UserRecord user, {
    required bool activate,
  }) async {
    final title = activate
        ? uiTr(context, 'تأكيد التفعيل')
        : uiTr(context, 'تأكيد الإيقاف');
    final content = activate
        ? uiTr(context, 'هل أنت متأكد من تفعيل المندوب؟')
        : uiTr(context, 'هل أنت متأكد من إيقاف المندوب؟');

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: title,
      whatHappens: content,
      subject: user.displayName.isNotEmpty
          ? user.displayName
          : user.reference.id,
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
      await user.reference.update(createUserRecordData(actevMndob: activate));
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
            activate
                ? uiTr(context, 'تم تفعيل المندوب بنجاح')
                : uiTr(context, 'تم إيقاف المندوب بنجاح'),
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

  void _openDetails(UserRecord user) {
    showAdminDriverDetailsDrawer(context: context, user: user);
  }

  void _openEdit(UserRecord user) {
    context.pushNamed(
      AddDrevWidget.routeName,
      queryParameters: {
        'editUser': serializeParam(user.reference, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  void _openReview(UserRecord user) {
    context.pushNamed(
      DriverActivationWidget.routeName,
      queryParameters: {
        'dre': serializeParam(user.reference, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  void _openDocuments(UserRecord user) {
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);

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
          title: uiTr(context, 'المناديب'),
          subtitle: uiTr(
            context,
            'إدارة حسابات المناديب، التسجيل، المركبات، الوثائق والحالة التشغيلية.',
          ),
          actions: AdminPrimaryButton(
            label: uiTr(context, 'إضافة مندوب'),
            icon: Icons.person_add_rounded,
            onPressed: () => context.pushNamed(AddDrevWidget.routeName),
          ),
          scrollable: true,
          child: Semantics(
            identifier: 'qa-driver-list',
            label: 'qa-driver-list',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminDriversFilterBar(
                  value: _filters,
                  extra: _extra,
                  pageSize: _pageSize,
                  onChanged: _onFiltersChanged,
                  onExtraChanged: (e) => setState(() => _extra = e),
                  onPageSizeChanged: (n) => setState(() => _pageSize = n),
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
                const SizedBox(height: 10),
                Semantics(
                  identifier: 'qa-driver-table-total',
                  container: true,
                  label: _tableQaLabel,
                  child: const SizedBox.shrink(),
                ),
                if (_filters.driverActivation ==
                    AdminDriverActivationFilter.unknown)
                  _UnknownDriversPanel(
                    filters: _filters,
                    extra: _extra,
                    searchQuery: _filters.searchQuery,
                    onToggle: _toggleActivation,
                    onOpenDetails: _openDetails,
                    onEdit: _openEdit,
                    onReview: _openReview,
                    onDocuments: _openDocuments,
                  )
                else if (_serverSearchHits != null || _serverSearching)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminDriversSummaryStrip(
                        stats: _stats,
                        loading: _statsLoading,
                        error: _statsError,
                        onRetry: _loadStats,
                      ),
                      const SizedBox(height: 10),
                      _buildSearchResults(theme),
                    ],
                  )
                else
                  AdminFirestoreList<UserRecord>(
                    key: ValueKey(
                      'drivers_${_filters.signature}_${_pageSize}_${_extra.signature}',
                    ),
                    reloadKey:
                        '${_filters.signature}|${_pageSize}|${_extra.signature}',
                    refreshScope: AdminListScope.representatives,
                    pageSize: _pageSize,
                    query: UserRecord.collection,
                    recordBuilder: UserRecord.fromSnapshot,
                    queryBuilder: (q) =>
                        AdminOpsQueryBuilder.applyDriverFilters(q, _filters),
                    countQueryBuilder: (q) =>
                        AdminOpsQueryBuilder.applyDriverFiltersCore(
                          q,
                          _filters,
                        ),
                    loading: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdminDriversSummaryStrip(
                          stats: _stats,
                          loading: true,
                          error: _statsError,
                          onRetry: _loadStats,
                        ),
                        const SizedBox(height: 10),
                        _skeleton(),
                      ],
                    ),
                    builder: (context, allReps, listState) {
                      if (listState.hasError) {
                        return AdminContentCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(uiTr(context, 'تعذر تحميل المناديب')),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: listState.refresh,
                                child: Text(uiTr(context, 'إعادة')),
                              ),
                            ],
                          ),
                        );
                      }

                      final sorted = sortDriversNewestFirst(allReps);
                      final filtered = applyAdminDriversClientFilters(
                        sorted,
                        searchQuery: _filters.searchQuery,
                        extra: _extra,
                        unknownLegacyReview: _filters.driverReview,
                      );
                      final rows = filtered
                          .map(AdminDriverRow.fromUser)
                          .toList(growable: false);

                      final online = rows
                          .where(
                            (r) =>
                                r.connection ==
                                AdminDriverConnectionStatus.online,
                          )
                          .length;
                      final available = rows
                          .where(
                            (r) =>
                                r.availability ==
                                AdminDriverAvailabilityStatus.available,
                          )
                          .length;
                      final busy = rows
                          .where(
                            (r) =>
                                r.availability ==
                                AdminDriverAvailabilityStatus.busy,
                          )
                          .length;

                      final serverTotal =
                          listState.totalAvailable ?? allReps.length;
                      final tableSemanticsLabel =
                          'visible:${rows.length} total:$serverTotal empty:${rows.isEmpty}';
                      _syncTableQaLabel(tableSemanticsLabel);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AdminDriversSummaryStrip(
                            stats: _stats,
                            loading: _statsLoading,
                            error: _statsError,
                            onRetry: _loadStats,
                            onlineHint: online,
                            availableHint: available,
                            busyHint: busy,
                          ),
                          const SizedBox(height: 10),
                          AdminContentCard(
                            padding: rows.isEmpty
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    0,
                                    4,
                                    10,
                                  ),
                                  child: Semantics(
                                    identifier: 'qa-driver-table-total',
                                    container: true,
                                    label: tableSemanticsLabel,
                                    child: Text(
                                      adminListCountLabel(
                                        context,
                                        listState,
                                        visibleCount: rows.length,
                                        pageFetched: allReps.length,
                                      ),
                                      style: theme.labelLarge.override(
                                        fontFamily: theme.labelLargeFamily,
                                        color: theme.secondaryText,
                                        useGoogleFonts:
                                            !theme.labelLargeIsCustom,
                                      ),
                                    ),
                                  ),
                                ),
                                if (rows.isEmpty)
                                  Semantics(
                                    identifier: 'qa-driver-empty-state',
                                    container: true,
                                    label: 'qa-driver-empty-state=true',
                                    child: AdminEmptyState(
                                      title: _filters.searchQuery.isEmpty
                                          ? uiTr(
                                              context,
                                              'لا يوجد مناديب مسجلون',
                                            )
                                          : uiTr(
                                              context,
                                              'لا توجد نتائج للبحث',
                                            ),
                                      message: _filters.searchQuery.isEmpty
                                          ? uiTr(
                                              context,
                                              'أضف مندوبًا جديدًا أو راجع فلتر الدولة',
                                            )
                                          : uiTr(context, 'جرّب كلمة بحث أخرى'),
                                      icon: Icons.directions_car_outlined,
                                    ),
                                  )
                                else
                                  AdminDriversTable(
                                    rows: rows,
                                    onToggle: _toggleActivation,
                                    onOpenDetails: _openDetails,
                                    onEdit: _openEdit,
                                    onReview: _openReview,
                                    onDocuments: _openDocuments,
                                  ),
                                if (rows.isNotEmpty)
                                  AdminListLoadMoreFooter(state: listState),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildSearchResults(FlutterFlowTheme theme) {
    if (_serverSearching) return _skeleton();
    final hits = _serverSearchHits ?? const <UserRecord>[];
    final filtered = applyAdminDriversClientFilters(
      hits,
      searchQuery: _filters.searchQuery,
      extra: _extra,
      unknownLegacyReview: _filters.driverReview,
    );
    final rows = filtered.map(AdminDriverRow.fromUser).toList(growable: false);
    return AdminContentCard(
      padding: const EdgeInsets.all(12),
      child: rows.isEmpty
          ? AdminEmptyState(
              title: uiTr(context, 'لا توجد نتائج للبحث'),
              message: uiTr(context, 'جرّب كلمة بحث أخرى'),
              icon: Icons.search_off_rounded,
            )
          : AdminDriversTable(
              rows: rows,
              onToggle: _toggleActivation,
              onOpenDetails: _openDetails,
              onEdit: _openEdit,
              onReview: _openReview,
              onDocuments: _openDocuments,
            ),
    );
  }

  Widget _skeleton() {
    return AdminContentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            height: 52,
            margin: EdgeInsets.only(bottom: i == 5 ? 0 : 8),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(
                context,
              ).alternate.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnknownDriversPanel extends StatefulWidget {
  const _UnknownDriversPanel({
    required this.filters,
    required this.extra,
    required this.searchQuery,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onReview,
    required this.onDocuments,
  });

  final AdminOpsFilterState filters;
  final AdminDriversExtraFilters extra;
  final String searchQuery;
  final AdminDriverToggle onToggle;
  final AdminDriverOpenDetails onOpenDetails;
  final AdminDriverOpenDetails onEdit;
  final AdminDriverOpenDetails onReview;
  final AdminDriverOpenDetails onDocuments;

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
            TextButton(
              onPressed: _reload,
              child: Text(appTr(context, 'adm_retry')),
            ),
          ],
        ),
      );
    }

    final filtered = applyAdminDriversClientFilters(
      _items,
      searchQuery: widget.searchQuery,
      extra: widget.extra,
    );
    final rows = filtered.map(AdminDriverRow.fromUser).toList(growable: false);

    return AdminContentCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${uiTr(context, 'حالة غير محددة')}: ${rows.length} / $_totalUnknown',
            style: theme.labelLarge.override(
              fontFamily: theme.labelLargeFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelLargeIsCustom,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            AdminEmptyState(
              title: uiTr(context, 'لا يوجد مناديب بحالة غير محددة'),
              message: uiTr(context, 'جميع المندوبين لديهم actev_mndob'),
              icon: Icons.verified_outlined,
            )
          else
            AdminDriversTable(
              rows: rows,
              onToggle: widget.onToggle,
              onOpenDetails: widget.onOpenDetails,
              onEdit: widget.onEdit,
              onReview: widget.onReview,
              onDocuments: widget.onDocuments,
            ),
          if (_hasMore && !_hitCap)
            TextButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: Text(uiTr(context, 'تحميل المزيد')),
            ),
        ],
      ),
    );
  }
}
