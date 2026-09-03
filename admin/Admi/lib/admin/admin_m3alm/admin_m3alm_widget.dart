import '/admin/admin_m3alm/admin_landmarks_adapter.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_reports_country_scope.dart';
import '/backend/admin_landmark_catalog_stats.dart';
import '/backend/admin_landmark_list_filters.dart';
import '/backend/admin_landmark_search.dart';
import '/backend/admin_legacy_alias_filter.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_resource_guard.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_agent_landmark_list.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ops_filter_bar.dart';
import '/components/admin_ui.dart';
import '/backend/admin_ops_filters.dart';
import '/components/admin_location_service.dart';
import '/components/map_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'admin_m3alm_model.dart';
export 'admin_m3alm_model.dart';

class AdminM3almWidget extends StatefulWidget {
  const AdminM3almWidget({
    super.key,
    this.partnersOnly = false,
  });

  /// When true, shows only landmarks marked as partners (`isShrek`).
  final bool partnersOnly;

  static String routeName = 'AdminM3alm';
  static String routePath = '/adminM3alm';

  @override
  State<AdminM3almWidget> createState() => _AdminM3almWidgetState();
}

class _AdminM3almWidgetState extends State<AdminM3almWidget> {
  late AdminM3almModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  Future<List<MkanRecord>>? _searchFuture;
  int _searchRequestId = 0;
  Future<int>? _catalogCountFuture;
  bool _catalogCountPartnersOnly = false;
  AdminLandmarkListFilters _listFilters = const AdminLandmarkListFilters();
  AdminOpsFilterState _opsFilters = const AdminOpsFilterState();
  int? _excludedAliasHint;
  int _pageSize = kAdminPageSize;

  Query _landmarksQuery(Query collection) {
    var q = collection as Query<Map<String, dynamic>>;
    if (widget.partnersOnly) {
      q = q.where('isShrek', isEqualTo: true);
    }
    q = AdminCountryScope.applyLandmarkCountryFilter(q);

    // Server-side geo filters — do NOT rely on client filter of one page.
    // Africa landmarks (lm_ng_*/lm_td_*/lm_ne_*) sit mid/late in documentId order
    // and vanish when country is filtered only on the current page.
    final country = _listFilters.countryRef;
    if (country != null &&
        !(AdminRoleService.isCountryAgent ||
            AdminReportsCountryScope.isActive)) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    final region = _listFilters.regionRef;
    if (region != null) {
      q = q.where('id_cit', isEqualTo: region);
    }
    final city = _listFilters.cityRef;
    if (city != null) {
      q = q.where('id_vill', isEqualTo: city);
    }

    return q.orderBy(FieldPath.documentId);
  }

  String get _landmarksListSignature => [
        widget.partnersOnly ? 'p1' : 'p0',
        AdminRoleService.isCountryAgent ? 'agent' : 'sa',
        _listFilters.countryRef?.path ?? '',
        _listFilters.regionRef?.path ?? '',
        _listFilters.cityRef?.path ?? '',
        _pageSize,
      ].join('|');


  bool get _isCountryAgentList =>
      AdminRoleService.isCountryAgent && _searchFuture == null;

  String _landmarkThumbnail(MkanRecord record) =>
      AdminLandmarkRow.primaryImageOf(record);

  Future<List<MkanRecord>> _searchLandmarks(String query) async {
    final requestId = ++_searchRequestId;
    final results = await searchLandmarksFast(
      query: query,
      partnersOnly: widget.partnersOnly,
    );
    if (!mounted || requestId != _searchRequestId) {
      return const [];
    }
    return results;
  }

  void _triggerSearch(String query) {
    final trimmed = query.trim();
    setState(() {
      _searchQuery = query;
      if (trimmed.isEmpty) {
        _searchFuture = null;
      } else {
        _searchFuture = _searchLandmarks(trimmed);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminM3almModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _refreshCatalogCount();
  }

  void _refreshCatalogCount() {
    _catalogCountPartnersOnly = widget.partnersOnly;
    _catalogCountFuture = AdminLandmarkCatalogStats.countCatalog(
      partnersOnly: widget.partnersOnly,
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdminM3almWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnersOnly != widget.partnersOnly) {
      _searchQuery = '';
      _searchFuture = null;
      AdminLandmarkIndex.clear();
      _model.textController?.clear();
      _refreshCatalogCount();
    }
  }

  bool get _isCountryScopedList => _isCountryAgentList;

  List<MkanRecord> _filterLandmarks(List<MkanRecord> items) {
    final list =
        _isCountryScopedList ? items : AdminCountryScope.filterLandmarks(items);
    final withoutAliases = AdminLegacyAliasFilter.keepWhereId(
      list,
      (m) => m.reference.id,
    );
    if (items.isNotEmpty && withoutAliases.length < list.length) {
      _excludedAliasHint = list.length - withoutAliases.length;
    }
    final filtered = widget.partnersOnly
        ? withoutAliases.where((m) => m.isShrek).toList()
        : withoutAliases;

    var scoped = _listFilters.apply(filtered);

    final q = _searchQuery.trim();
    if (q.isEmpty) return scoped;

    return scoped
        .where((m) => AdminLandmarkRow.fromRecord(m).matchesSearch(q))
        .toList();
  }

  Widget _buildPaginatedLandmarksList({
    required BuildContext context,
    required FFLocalizations l10n,
    required FlutterFlowTheme theme,
    int? catalogTotal,
  }) {
    // Country agents: geo-merge loader (matches dashboard landmark totals).
    if (AdminRoleService.isCountryAgent) {
      return AdminAgentLandmarkList(
        key: ValueKey(
          'm3alm_agent_${widget.partnersOnly}_${AdminCountryScope.activeCountryRef?.path}_$_pageSize',
        ),
        partnersOnly: widget.partnersOnly,
        pageSize: _pageSize,
        builder: (context, visibleLandmarks, listState) {
          AdminLandmarkIndex.ingest(visibleLandmarks);
          final landmarks = _filterLandmarks(visibleLandmarks);
          final total = listState.totalAvailable ?? visibleLandmarks.length;
          return _buildLandmarksCard(
            context: context,
            l10n: l10n,
            theme: theme,
            landmarks: landmarks,
            totalLabel: uiTr(context, 'العدد'),
            listState: listState,
            partnerTotal: widget.partnersOnly ? total : null,
            filteredFromTotal: visibleLandmarks.length != landmarks.length,
            displayTotal: catalogTotal ?? landmarks.length,
          );
        },
      );
    }

    return AdminFirestoreList<MkanRecord>(
      key: ValueKey('m3alm_list_$_landmarksListSignature'),
      reloadKey: _landmarksListSignature,
      refreshScope: AdminListScope.landmarks,
      query: MkanRecord.collection,
      recordBuilder: MkanRecord.fromSnapshot,
      pageSize: _pageSize,
      queryBuilder: _landmarksQuery,
      countQueryBuilder: _landmarksQuery,
      builder: (context, allLandmarks, listState) {
        AdminLandmarkIndex.ingest(allLandmarks);
        final landmarks = _filterLandmarks(allLandmarks);
        final partnerTotal = widget.partnersOnly
            ? allLandmarks.where((m) => m.isShrek).length
            : allLandmarks.length;

        return _buildLandmarksCard(
          context: context,
          l10n: l10n,
          theme: theme,
          landmarks: landmarks,
          totalLabel: uiTr(context, 'العدد'),
          listState: listState,
          partnerTotal: listState.totalAvailable ?? partnerTotal,
          filteredFromTotal:
              (listState.totalAvailable ?? allLandmarks.length) !=
                  (catalogTotal ?? landmarks.length),
          displayTotal: catalogTotal ?? landmarks.length,
        );
      },
    );
  }

  Future<void> _refreshLandmarksAfterCrud() async {
    if (_searchQuery.trim().isNotEmpty) {
      final future = _searchLandmarks(_searchQuery);
      if (mounted) {
        setState(() => _searchFuture = future);
      }
      await future;
    }
  }

  Future<void> _deleteLandmark(MkanRecord record) async {
    if (!AdminResourceGuard.canEditMkan(record)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'لا تملك صلاحية حذف هذا المعلم'))),
      );
      return;
    }

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: appTr(context, 'adm_delete_confirm_title'),
      whatHappens: uiTr(
        context,
        'Soft-disable this landmark (acctev=false). Historical bookings keep their reference.',
      ),
      subject: record.naim.isNotEmpty ? record.naim : record.reference.id,
      impact:
          uiTr(context, 'Landmark hidden from active lists; not hard-deleted'),
      confirmLabel: uiTr(context, 'تعطيل المعلم'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: true,
      irreversible: false,
      reference: record.reference.id,
    );

    if (!confirmed) return;

    try {
      await ensureCurrentUserDocument(forceRefresh: true);
      if (AdminRoleService.isCountryAgent) {
        await AdminAgentCountryLock.ensureCountryResolved();
      }
      await record.reference.update(createMkanRecordData(acctev: false));
      AdminLandmarkIndex.removeRecord(record);
      AdminLandmarkCatalogStats.invalidateCache();
      await AdminAuditLog.recordToggle(
        targetType: 'landmark',
        targetId: record.reference.id,
        targetLabel: record.naim,
        activated: false,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم تعطيل المعلم (حذف ناعم)'),
        refreshScope: AdminListScope.landmarks,
        refresh: _refreshLandmarksAfterCrud,
        invalidateStats: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(
          context, AdminCrudFeedback.updateFailed(context, e));
    }
  }

  void _openMap(MkanRecord record) {
    if (record.location == null) return;
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      context: context,
      builder: (ctx) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(ctx).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(ctx),
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.77,
              child: MapWidget(idmap: record.location!),
            ),
          ),
        );
      },
    ).then((_) => safeSetState(() {}));
  }

  void _editLandmark(MkanRecord record) {
    if (!AdminResourceGuard.canEditMkan(record)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(uiTr(context, 'لا تملك صلاحية تعديل هذا المعلم'))),
      );
      return;
    }

    context.pushNamed(
      AdminaddMkanCopyWidget.routeName,
      queryParameters: {
        'idmkan': serializeParam(
          record.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Widget _buildCatalogCountWrapper({
    required Widget Function(int? catalogTotal) builder,
  }) {
    if (_catalogCountFuture == null ||
        _catalogCountPartnersOnly != widget.partnersOnly) {
      _refreshCatalogCount();
    }
    return FutureBuilder<int>(
      future: _catalogCountFuture,
      builder: (context, snapshot) {
        return builder(snapshot.hasData ? snapshot.data : null);
      },
    );
  }

  Widget _buildScopeBanner() {
    final theme = FlutterFlowTheme.of(context);
    final scopeLabel = AdminLandmarkCatalogStats.scopeLabelForUi();
    final isScoped = AdminLandmarkCatalogStats.isCountryScoped;
    if (!isScoped && (_excludedAliasHint == null || _excludedAliasHint! <= 0)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminContentCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isScoped && scopeLabel.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.filter_alt_outlined,
                      size: 18, color: AdminUi.brandTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${uiTr(context, 'النطاق الحالي')}: $scopeLabel',
                      style: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodySmallIsCustom,
                      ),
                    ),
                  ),
                ],
              ),
            if (_excludedAliasHint != null && _excludedAliasHint! > 0) ...[
              if (isScoped && scopeLabel.isNotEmpty) const SizedBox(height: 6),
              Text(
                uiTr(
                  context,
                  '${_excludedAliasHint} سجلات توافق legacy مستبعدة من القائمة العادية',
                ),
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.bodySmallIsCustom,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _landmarkLocationText(MkanRecord record) {
    if (record.location == null) {
      return uiTr(context, 'الموقع غير محدد');
    }
    if (record.mdh.isNotEmpty && record.address.isNotEmpty) {
      return '${record.mdh} · ${record.address}';
    }
    if (record.mdh.isNotEmpty) return record.mdh;
    if (record.address.isNotEmpty) return record.address;
    return AdminLocationService.formatCoordinates(record.location!);
  }

  Widget _buildLandmarksCard({
    required BuildContext context,
    required FFLocalizations l10n,
    required FlutterFlowTheme theme,
    required List<MkanRecord> landmarks,
    required String totalLabel,
    AdminFirestoreListMeta<MkanRecord>? listState,
    int? partnerTotal,
    bool filteredFromTotal = false,
    int? displayTotal,
  }) {
    final hasMore = listState?.hasMore ?? false;
    final isWide = AdminUi.useTableLayout(context);
    final gridColumns =
        AdminUi.responsiveColumnCount(context, wide: 3, medium: 2, narrow: 1);
    final activeCount = landmarks.where((m) => m.acctev).length;
    final isSearching = _searchQuery.trim().isNotEmpty;
    final countryIds = <String>{};
    final cityIds = <String>{};
    for (final m in landmarks) {
      final c = m.revDolh?.id;
      if (c != null && c.isNotEmpty) countryIds.add(c);
      final city = m.idVill?.id;
      if (city != null && city.isNotEmpty) cityIds.add(city);
    }
    // Avoid flash: wait for catalogTotal (final scope) before showing a number.
    final countReady = isSearching || displayTotal != null;
    final count = displayTotal ??
        (isSearching
            ? landmarks.length
            : (listState?.totalAvailable ?? landmarks.length));

    final scopeNote = AdminLandmarkCatalogStats.isCountryScoped
        ? AdminLandmarkCatalogStats.scopeLabelForUi()
        : null;
    final aliasExcluded = _excludedAliasHint;
    final catalog = displayTotal;
    final hiddenAliasNote = aliasExcluded != null && aliasExcluded > 0
        ? uiTr(
            context,
            'تم استبعاد $aliasExcluded سجل توافق legacy من العدد الإجمالي',
          )
        : (partnerTotal != null && catalog != null && partnerTotal > catalog
            ? uiTr(
                context,
                'تم استبعاد ${partnerTotal - catalog} معلم alias قديم من العدد الإجمالي',
              )
            : null);

    return AdminContentCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LandmarksSummaryBar(
            totalLabel: totalLabel,
            count: countReady ? count : null,
            hasMore: hasMore &&
                displayTotal == null &&
                listState?.totalAvailable == null,
            activeCount: activeCount,
            inactiveCount: landmarks.length - activeCount,
            countriesOnPage: countryIds.length,
            citiesOnPage: cityIds.length,
            isSearching: isSearching,
            filteredFromTotal: filteredFromTotal,
            partnerTotal: partnerTotal,
            scopeNote: scopeNote?.isNotEmpty == true ? scopeNote : null,
            hiddenAliasNote: hiddenAliasNote,
          ),
          if (landmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                children: [
                  Icon(
                    widget.partnersOnly
                        ? Icons.handshake_outlined
                        : Icons.place_outlined,
                    size: 52,
                    color: AdminUi.brandTeal.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isSearching
                        ? uiTr(context, 'لا توجد نتائج للبحث')
                        : (widget.partnersOnly
                            ? uiTr(context, 'لا يوجد شركاء مسجلون')
                            : uiTr(context, 'لا توجد معالم مسجلة')),
                    style: theme.titleMedium,
                  ),
                  if (isSearching) ...[
                    const SizedBox(height: 6),
                    Text(
                      uiTr(context, 'جرّب البحث باسم آخر أو جزء من العنوان'),
                      style: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodySmallIsCustom,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else if (isWide)
            _LandmarksTable(
              landmarks: landmarks,
              thumbnailFor: _landmarkThumbnail,
              locationFor: _landmarkLocationText,
              onEdit: _editLandmark,
              onDelete: _deleteLandmark,
              onMap: _openMap,
            )
          else if (gridColumns > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: gridColumns >= 3 ? 0.7 : 0.78,
                ),
                itemCount: landmarks.length,
                itemBuilder: (context, index) {
                  final record = landmarks[index];
                  return _LandmarkGridCard(
                    record: record,
                    imageUrl: _landmarkThumbnail(record),
                    locationText: _landmarkLocationText(record),
                    onEdit: () => _editLandmark(record),
                    onDelete: () => _deleteLandmark(record),
                    onMap: () => _openMap(record),
                  );
                },
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: landmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = landmarks[index];
                return _LandmarkCard(
                  record: record,
                  imageUrl: _landmarkThumbnail(record),
                  locationText: _landmarkLocationText(record),
                  onEdit: () => _editLandmark(record),
                  onDelete: () => _deleteLandmark(record),
                  onMap: () => _openMap(record),
                );
              },
            ),
          if (listState != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: AdminListLoadMoreFooter(state: listState),
            ),
        ],
      ),
    );
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
        title: widget.partnersOnly
            ? l10n.getText('f0wi63xt')
            : l10n.getText('95vv0eea'),
        child: AdminPageBody(
          title: widget.partnersOnly
              ? uiTr(context, 'الشركاء السياحيون')
              : l10n.getText('7lduezp8'),
          subtitle: widget.partnersOnly
              ? uiTr(context, 'معالم الشركاء المعتمدة فقط')
              : uiTr(context, 'إدارة وعرض المعالم السياحية'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isWide
                        ? Row(
                            children: [
                              Expanded(child: _buildSearch(l10n)),
                              const SizedBox(width: 12),
                              _buildAddButton(l10n),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearch(l10n),
                              const SizedBox(height: 12),
                              _buildAddButton(l10n),
                            ],
                          ),
                    const SizedBox(height: 12),
                    AdminOpsFilterBar(
                      value: _opsFilters,
                      config: AdminOpsFilterConfig(
                        showDate: false,
                        showCountry: !AdminRoleService.isCountryAgent,
                        showRegion: true,
                        showCity: true,
                        showSearch: false,
                        collapseAdvancedByDefault: false,
                      ),
                      onChanged: (next) {
                        setState(() {
                          _opsFilters = next;
                          _listFilters = AdminLandmarkListFilters(
                            countryRef: next.effectiveCountryRef,
                            regionRef: next.regionRef,
                            cityRef: next.cityRef,
                            status: _listFilters.status,
                            imageMissingOnly: _listFilters.imageMissingOnly,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text(uiTr(context, 'الكل')),
                          selected: _listFilters.status ==
                                  AdminLandmarkStatusFilter.all &&
                              !_listFilters.imageMissingOnly,
                          onSelected: (_) => setState(() {
                            _listFilters = _listFilters.copyWith(
                              status: AdminLandmarkStatusFilter.all,
                              imageMissingOnly: false,
                            );
                          }),
                        ),
                        FilterChip(
                          label: Text(uiTr(context, 'نشط')),
                          selected: _listFilters.status ==
                              AdminLandmarkStatusFilter.active,
                          onSelected: (_) => setState(() {
                            _listFilters = _listFilters.copyWith(
                              status: AdminLandmarkStatusFilter.active,
                              imageMissingOnly: false,
                            );
                          }),
                        ),
                        FilterChip(
                          label: Text(uiTr(context, 'غير نشط')),
                          selected: _listFilters.status ==
                              AdminLandmarkStatusFilter.inactive,
                          onSelected: (_) => setState(() {
                            _listFilters = _listFilters.copyWith(
                              status: AdminLandmarkStatusFilter.inactive,
                              imageMissingOnly: false,
                            );
                          }),
                        ),
                        FilterChip(
                          label: Text(uiTr(context, 'بلا صورة')),
                          selected: _listFilters.imageMissingOnly,
                          onSelected: (_) => setState(() {
                            _listFilters = _listFilters.copyWith(
                              imageMissingOnly: !_listFilters.imageMissingOnly,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          uiTr(context, 'حجم الصفحة'),
                          style: theme.bodySmall,
                        ),
                        const SizedBox(width: 10),
                        for (final size in const [20, 50, 100]) ...[
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: ChoiceChip(
                              label: Text('$size'),
                              selected: _pageSize == size,
                              onSelected: (_) {
                                if (_pageSize == size) return;
                                setState(() => _pageSize = size);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildScopeBanner(),
              if (_searchQuery.trim().isNotEmpty)
                FutureBuilder<List<MkanRecord>>(
                  future: _searchFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return AdminContentCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        ),
                      );
                    }

                    final landmarks = snapshot.data ?? const <MkanRecord>[];
                    AdminLandmarkIndex.ingest(landmarks);
                    return _buildLandmarksCard(
                      context: context,
                      l10n: l10n,
                      theme: theme,
                      landmarks: landmarks,
                      totalLabel: uiTr(context, 'نتائج البحث'),
                      listState: null,
                    );
                  },
                )
              else
                _buildCatalogCountWrapper(
                  builder: (catalogTotal) => _buildPaginatedLandmarksList(
                    context: context,
                    l10n: l10n,
                    theme: theme,
                    catalogTotal: catalogTotal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(FFLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _model.textController,
          focusNode: _model.textFieldFocusNode,
          onChanged: (_) => EasyDebounce.debounce(
            '_admin_m3alm_search',
            const Duration(milliseconds: 450),
            () {
              if (mounted) {
                _triggerSearch(_model.textController?.text ?? '');
              }
            },
          ),
          decoration: AdminUi.compactSearchDecoration(
            context,
            hint: widget.partnersOnly
                ? appTr(context, 'adm_search_partners_hint')
                : appTr(context, 'adm_search_landmarks_hint'),
            helperText: uiTr(
              context,
              'بحث عالمي في المعالم (حد أقصى 40 نتيجة)؛ بدون بحث تُعرض الصفحة الحالية فقط',
            ),
          ),
          validator: _model.textControllerValidator.asValidator(context),
        ),
      ],
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: widget.partnersOnly
          ? appTr(context, 'adm_add_partner')
          : l10n.getText('uree1m4d'),
      icon: widget.partnersOnly
          ? Icons.handshake_rounded
          : Icons.add_location_alt_rounded,
      onPressed: () => context.pushNamed(
        widget.partnersOnly
            ? AdminAddPartnerWidget.routeName
            : AdminaddMkanWidget.routeName,
      ),
    );
  }
}

class _LandmarksSummaryBar extends StatelessWidget {
  const _LandmarksSummaryBar({
    required this.totalLabel,
    required this.count,
    required this.hasMore,
    required this.activeCount,
    required this.inactiveCount,
    required this.isSearching,
    this.countriesOnPage = 0,
    this.citiesOnPage = 0,
    this.filteredFromTotal = false,
    this.partnerTotal,
    this.scopeNote,
    this.hiddenAliasNote,
  });

  final String totalLabel;
  final int? count;
  final bool hasMore;
  final int activeCount;
  final int inactiveCount;
  final bool isSearching;
  final int countriesOnPage;
  final int citiesOnPage;
  final bool filteredFromTotal;
  final int? partnerTotal;
  final String? scopeNote;
  final String? hiddenAliasNote;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final countText = count == null ? '…' : '$count${hasMore ? '+' : ''}';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isSearching ? Icons.search_rounded : Icons.place_rounded,
                size: 20,
                color: AdminUi.brandTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$totalLabel: $countText'
                  '${filteredFromTotal && partnerTotal != null && count != null ? ' ${uiTr(context, 'من')} ${partnerTotal}' : ''}',
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    color: AdminUi.brandTeal,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
            ],
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: uiTr(context, 'نشط'),
                  value: activeCount.toString(),
                  color: const Color(0xFF2E7D32),
                  background: const Color(0xFFE8F5E9),
                ),
                _SummaryChip(
                  icon: Icons.pause_circle_outline_rounded,
                  label: uiTr(context, 'غير نشط'),
                  value: inactiveCount.toString(),
                  color: const Color(0xFFE65100),
                  background: const Color(0xFFFFF3E0),
                ),
                _SummaryChip(
                  icon: Icons.public_rounded,
                  label: uiTr(context, 'الدول'),
                  value: countriesOnPage.toString(),
                  color: const Color(0xFF1565C0),
                  background: const Color(0xFFE3F2FD),
                ),
                _SummaryChip(
                  icon: Icons.location_city_rounded,
                  label: uiTr(context, 'المدن'),
                  value: citiesOnPage.toString(),
                  color: const Color(0xFF6A1B9A),
                  background: const Color(0xFFF3E5F5),
                ),
              ],
            ),
          ],
          if (scopeNote != null && scopeNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${uiTr(context, 'نطاق')}: $scopeNote',
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodySmallIsCustom,
              ),
            ),
          ],
          if (hiddenAliasNote != null && hiddenAliasNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hiddenAliasNote!,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodySmallIsCustom,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: color,
              fontWeight: FontWeight.w600,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandmarksTable extends StatelessWidget {
  const _LandmarksTable({
    required this.landmarks,
    required this.thumbnailFor,
    required this.locationFor,
    required this.onEdit,
    required this.onDelete,
    required this.onMap,
  });

  final List<MkanRecord> landmarks;
  final String Function(MkanRecord) thumbnailFor;
  final String Function(MkanRecord) locationFor;
  final void Function(MkanRecord) onEdit;
  final Future<void> Function(MkanRecord) onDelete;
  final void Function(MkanRecord) onMap;

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  _TableHeaderCell(uiTr(context, 'المعلم'),
                      flex: 4, theme: theme),
                  _TableHeaderCell(uiTr(context, 'الموقع'),
                      flex: 3, theme: theme),
                  _TableHeaderCell(uiTr(context, 'التصنيف'),
                      flex: 2, theme: theme),
                  _TableHeaderCell(uiTr(context, 'الحالة'),
                      flex: 2, theme: theme),
                  _TableHeaderCell(uiTr(context, 'الخدمات'),
                      flex: 2, theme: theme),
                  _TableHeaderCell(uiTr(context, 'إجراءات'),
                      flex: 2, theme: theme),
                ],
              ),
            ),
            const Divider(height: 1),
            ...landmarks.map(
              (record) => _LandmarkTableRow(
                record: record,
                imageUrl: thumbnailFor(record),
                locationText: locationFor(record),
                onEdit: () => onEdit(record),
                onDelete: () => onDelete(record),
                onMap: () => onMap(record),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.text, {required this.flex, required this.theme});

  final String text;
  final int flex;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
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

class _LandmarkTableRow extends StatelessWidget {
  const _LandmarkTableRow({
    required this.record,
    required this.imageUrl,
    required this.locationText,
    required this.onEdit,
    required this.onDelete,
    required this.onMap,
  });

  final MkanRecord record;
  final String imageUrl;
  final String locationText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.55)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LandmarkImage(url: imageUrl, size: 52),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.naim.isNotEmpty ? record.naim : '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          fontFamily: theme.bodyMediumFamily,
                          fontWeight: FontWeight.w700,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.bodyMediumIsCustom,
                        ),
                      ),
                      if (record.osf.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          record.osf,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.override(
                            fontFamily: theme.bodySmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.bodySmallIsCustom,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              locationText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.tsnef.isNotEmpty ? record.tsnef : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: _LandmarkBadges(record: record, compact: true),
          ),
          Expanded(
            flex: 2,
            child: _LandmarkServices(record: record, compact: true),
          ),
          Expanded(
            flex: 2,
            child: _LandmarkActions(
              hasLocation: record.location != null,
              canModify: AdminResourceGuard.canEditMkan(record),
              onEdit: onEdit,
              onMap: onMap,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandmarkGridCard extends StatelessWidget {
  const _LandmarkGridCard({
    required this.record,
    required this.imageUrl,
    required this.locationText,
    required this.onEdit,
    required this.onDelete,
    required this.onMap,
  });

  final MkanRecord record;
  final String imageUrl;
  final String locationText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: AdminUi.cardDecoration(context, elevated: false).copyWith(
        color: theme.primaryBackground,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 118,
            child: AdminRecordThumbnail(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 118,
              fallback: Container(
                color: AdminUi.brandTeal.withValues(alpha: 0.08),
                child: const Center(
                  child: Icon(
                    Icons.landscape_rounded,
                    color: AdminUi.brandTeal,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    record.naim.isNotEmpty ? record.naim : '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w700,
                      color: AdminUi.brandTeal,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _LandmarkBadges(record: record, compact: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: theme.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.labelSmallIsCustom,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _LandmarkServices(record: record, compact: true),
                  const SizedBox(height: 10),
                  _LandmarkActions(
                    hasLocation: record.location != null,
                    canModify: AdminResourceGuard.canEditMkan(record),
                    onEdit: onEdit,
                    onMap: onMap,
                    onDelete: onDelete,
                    expanded: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandmarkCard extends StatelessWidget {
  const _LandmarkCard({
    required this.record,
    required this.imageUrl,
    required this.locationText,
    required this.onEdit,
    required this.onDelete,
    required this.onMap,
  });

  final MkanRecord record;
  final String imageUrl;
  final String locationText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: AdminUi.cardDecoration(context, elevated: false).copyWith(
        color: theme.primaryBackground,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LandmarkImage(url: imageUrl, size: 84),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.naim.isNotEmpty ? record.naim : '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          fontWeight: FontWeight.w700,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
                      ),
                      if (record.osf.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          record.osf,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.override(
                            fontFamily: theme.bodySmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.bodySmallIsCustom,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _LandmarkBadges(record: record, compact: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoLine(
                  icon: Icons.place_outlined,
                  text: locationText,
                ),
                if (record.tsnef.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoLine(
                    icon: Icons.category_outlined,
                    text: record.tsnef,
                  ),
                ],
                const SizedBox(height: 10),
                _LandmarkServices(record: record, compact: false),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              border: Border(
                top: BorderSide(color: theme.alternate.withValues(alpha: 0.7)),
              ),
            ),
            child: _LandmarkActions(
              hasLocation: record.location != null,
              canModify: AdminResourceGuard.canEditMkan(record),
              onEdit: onEdit,
              onMap: onMap,
              onDelete: onDelete,
              expanded: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AdminUi.brandSageDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.bodySmallIsCustom,
            ),
          ),
        ),
      ],
    );
  }
}

class _LandmarkBadges extends StatelessWidget {
  const _LandmarkBadges({required this.record, this.compact = false});

  final MkanRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: compact ? 4 : 6,
      children: [
        _StatusBadge(active: record.acctev),
        if (record.isShrek) const _PartnerBadge(),
        if (record.asAds) const _AdsBadge(),
      ],
    );
  }
}

class _LandmarkServices extends StatelessWidget {
  const _LandmarkServices({required this.record, this.compact = false});

  final MkanRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final services = <Widget>[
      if (record.ismsgd)
        _ServiceChip(
            icon: Icons.mosque_outlined,
            label: uiTr(context, 'مسجد'),
            compact: compact),
      if (record.isfood)
        _ServiceChip(
            icon: Icons.restaurant_outlined,
            label: uiTr(context, 'طعام'),
            compact: compact),
      if (record.ishmam)
        _ServiceChip(
            icon: Icons.wc_outlined,
            label: uiTr(context, 'حمامات'),
            compact: compact),
      if (record.rate > 0)
        _ServiceChip(
          icon: Icons.star_rounded,
          label: record.rate.toStringAsFixed(1),
          compact: compact,
        ),
    ];

    if (services.isEmpty) {
      return Text(
        '—',
        style: FlutterFlowTheme.of(context).bodySmall,
      );
    }

    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: compact ? 4 : 6,
      children: services,
    );
  }
}

class _LandmarkActions extends StatelessWidget {
  const _LandmarkActions({
    required this.hasLocation,
    required this.canModify,
    required this.onEdit,
    required this.onMap,
    required this.onDelete,
    this.expanded = false,
  });

  final bool hasLocation;
  final bool canModify;
  final VoidCallback onEdit;
  final VoidCallback onMap;
  final VoidCallback onDelete;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    Widget buildBtn({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
      Color? color,
      Color? bg,
    }) {
      if (expanded) {
        return Expanded(
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 16, color: color ?? AdminUi.brandTeal),
            label: Text(
              label,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: color ?? AdminUi.brandTeal,
                fontWeight: FontWeight.w600,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color ?? AdminUi.brandTeal,
              backgroundColor: bg,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              side: BorderSide(
                color: (color ?? AdminUi.brandTeal).withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      }

      return FlutterFlowIconButton(
        borderRadius: 8,
        buttonSize: 34,
        fillColor: bg ?? AdminUi.brandTeal.withValues(alpha: 0.1),
        icon: Icon(icon, color: color ?? AdminUi.brandTeal, size: 17),
        onPressed: onPressed,
      );
    }

    final children = <Widget>[
      if (canModify) ...[
        buildBtn(
          icon: Icons.edit_rounded,
          label: uiTr(context, 'تعديل'),
          onPressed: onEdit,
          bg: AdminUi.brandTeal.withValues(alpha: 0.08),
        ),
      ],
      if (hasLocation) ...[
        if (expanded && canModify) const SizedBox(width: 6),
        if (expanded && !canModify) const SizedBox.shrink(),
        buildBtn(
          icon: Icons.map_rounded,
          label: uiTr(context, 'الخريطة'),
          onPressed: onMap,
          bg: const Color(0xFFE3F2FD),
          color: const Color(0xFF1565C0),
        ),
      ],
      if (canModify) ...[
        if (expanded) const SizedBox(width: 6),
        buildBtn(
          icon: Icons.delete_rounded,
          label: uiTr(context, 'حذف'),
          onPressed: onDelete,
          bg: const Color(0xFFFFEBEE),
          color: theme.error,
        ),
      ],
    ];

    return expanded
        ? Row(children: children)
        : Wrap(spacing: 6, runSpacing: 6, children: children);
  }
}

class _LandmarkImage extends StatelessWidget {
  const _LandmarkImage({required this.url, this.size = 72});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AdminUi.radiusSm),
      child: Container(
        width: size,
        height: size,
        color: AdminUi.brandTeal.withValues(alpha: 0.08),
        child: AdminRecordThumbnail(
          key: ValueKey('lm_thumb_${url.hashCode}_$size'),
          imageUrl: url,
          width: size,
          height: size,
          fallback: const _ImageFallback(),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.landscape_rounded,
        color: AdminUi.brandTeal,
        size: 32,
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: AdminUi.brandTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              fontSize: compact ? 10 : null,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        active ? uiTr(context, 'نشط') : uiTr(context, 'غير نشط'),
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: active ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}

class _PartnerBadge extends StatelessWidget {
  const _PartnerBadge();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminUi.brandMint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        uiTr(context, 'شريك'),
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: AdminUi.brandTeal,
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}

class _AdsBadge extends StatelessWidget {
  const _AdsBadge();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        uiTr(context, 'إعلان'),
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: const Color(0xFF1565C0),
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}
