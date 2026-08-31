import '/backend/admin_audit_log.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/backend.dart';
import '/admin/adminuser/admin_customer_active_order.dart';
import '/admin/adminuser/admin_customers_adapter.dart';
import '/admin/adminuser/admin_customers_details_drawer.dart';
import '/admin/adminuser/admin_customers_filter_bar.dart';
import '/admin/adminuser/admin_customers_stats_loader.dart';
import '/admin/adminuser/admin_customers_summary_strip.dart';
import '/admin/adminuser/admin_customers_table.dart';
import '/components/add_yser_widget.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'adminuser_model.dart';
export 'adminuser_model.dart';

class AdminuserWidget extends StatefulWidget {
  const AdminuserWidget({super.key});

  static String routeName = 'Adminuser';
  static String routePath = '/adminuser';

  @override
  State<AdminuserWidget> createState() => _AdminuserWidgetState();
}

class _AdminuserWidgetState extends State<AdminuserWidget> {
  late AdminuserModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  AdminOpsFilterState _filters = const AdminOpsFilterState();
  AdminCustomerExtraFilters _extra = AdminCustomerExtraFilters.empty;
  int _pageSize = 20;
  AdminCustomerStats _stats = const AdminCustomerStats.empty();
  bool _statsLoading = true;
  bool _statsError = false;
  List<UserRecord>? _serverSearchHits;
  int _searchGen = 0;
  Map<String, AdminCustomerActiveOrderTruth> _tripTruth = const {};
  int _tripGen = 0;
  int _pageLiveTrip = 0;
  String _tripUsersKey = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminuserModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeSetState(() {});
      _loadStats();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = false;
    });
    try {
      final s = await AdminCustomerStatsLoader.load(filters: _filters);
      if (!mounted) return;
      setState(() {
        _stats = s;
        _statsLoading = false;
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
      _tripTruth = const {};
      _tripUsersKey = '';
      _pageLiveTrip = 0;
    });
    _loadStats();
    final plan = AdminOpsSearch.classify(next.searchQuery);
    if (!plan.isServerSide) return;
    final gen = ++_searchGen;
    final hits = await AdminOpsSearch.searchUsersServer(plan, next);
    if (!mounted || gen != _searchGen) return;
    setState(() {
      _serverSearchHits =
          hits.where(adminIsAppCustomer).toList(growable: false);
    });
  }

  Future<void> _resolveTrips(List<UserRecord> users) async {
    final gen = ++_tripGen;
    final map = await AdminCustomerActiveOrderTruth.resolvePage(users);
    if (!mounted || gen != _tripGen) return;
    var live = 0;
    for (final t in map.values) {
      if (t.hasLiveTrip) live++;
    }
    setState(() {
      _tripTruth = map;
      _pageLiveTrip = live;
    });
  }

  List<AdminCustomerRow> _buildRows(List<UserRecord> users) {
    final rows = users.map((u) {
      final truth = _tripTruth[u.reference.id];
      return AdminCustomerRow.fromUser(
        u,
        tripHint: truth?.tripHint ??
            (AdminCustomerRow.activeOrderIdOf(u).isNotEmpty
                ? AdminCustomerTripHint.lockPresent
                : AdminCustomerTripHint.none),
      );
    }).toList(growable: false);

    final q = _filters.searchQuery.trim();
    var filtered = rows;
    if (_serverSearchHits == null && q.isNotEmpty) {
      final plan = AdminOpsSearch.classify(q);
      if (!plan.isServerSide) {
        filtered = rows.where((r) => r.matchesSearch(q)).toList(growable: false);
      }
    }
    return _extra.apply(filtered);
  }

  List<UserRecord> _baseUsers(List<UserRecord> all) {
    if (_serverSearchHits != null) {
      return _serverSearchHits!;
    }
    return all.where(adminIsAppCustomer).toList(growable: false);
  }

  Future<void> _toggleActivation(
    UserRecord user, {
    required bool activate,
  }) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: activate
          ? uiTr(context, 'تأكيد تنشيط الحساب')
          : uiTr(context, 'تأكيد إيقاف الحساب'),
      whatHappens: activate
          ? uiTr(context, 'هل أنت متأكد من تنشيط حساب')
          : uiTr(context, 'هل أنت متأكد من إيقاف حساب'),
      subject:
          user.displayName.isNotEmpty ? user.displayName : user.reference.id,
      impact: activate
          ? uiTr(context, 'User can sign in and book again')
          : uiTr(context, 'User account will be disabled'),
      confirmLabel: activate
          ? uiTr(context, 'نعم، فعّل')
          : uiTr(context, 'نعم، أوقف'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: !activate,
      reference: user.reference.id,
    );

    if (!confirmed) return;

    try {
      await user.reference.update(
        createUserRecordData(actevUser: activate),
      );
      if (!mounted) return;
      await AdminAuditLog.recordToggle(
        targetType: 'app_user',
        targetId: user.reference.id,
        targetLabel: user.displayName,
        activated: activate,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? uiTr(context, 'تم تنشيط الحساب بنجاح')
                : uiTr(context, 'تم إيقاف الحساب بنجاح'),
          ),
        ),
      );
      AdminListRefresh.notify(AdminListScope.users);
      _loadStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    }
  }

  Future<void> _openAddUserSheet() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(top: 8),
              child: const AddYserWidget(),
            ),
          ),
        );
      },
    );
    safeSetState(() {});
    AdminListRefresh.notify(AdminListScope.users);
    _loadStats();
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
        title: l10n.getText('0qqjtlup'),
        child: AdminPageBody(
          title: uiTr(context, 'المستخدمون'),
          subtitle: uiTr(
            context,
            'إدارة حسابات العملاء وبياناتهم وحالتهم.',
          ),
          actions: AdminPrimaryButton(
            label: l10n.getText('ojvmhyny'),
            icon: Icons.person_add_rounded,
            onPressed: _openAddUserSheet,
          ),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminCustomersSummaryStrip(
                stats: _stats,
                loading: _statsLoading,
                error: _statsError,
                onRetry: _loadStats,
                pageLiveTripHint: _pageLiveTrip,
              ),
              const SizedBox(height: 8),
              AdminCustomersFilterBar(
                value: _filters,
                extra: _extra,
                pageSize: _pageSize,
                onChanged: _onFiltersChanged,
                onExtraChanged: (e) => setState(() => _extra = e),
                onPageSizeChanged: (n) => setState(() => _pageSize = n),
              ),
              const SizedBox(height: 8),
              AdminFirestoreList<UserRecord>(
                key: ValueKey(
                  'users_${_filters.signature}_${_pageSize}_${_extra.signature}',
                ),
                reloadKey:
                    '${_filters.signature}|$_pageSize|${_extra.signature}',
                refreshScope: AdminListScope.users,
                query: UserRecord.collection,
                recordBuilder: UserRecord.fromSnapshot,
                pageSize: _pageSize,
                queryBuilder: (q) =>
                    AdminOpsQueryBuilder.applyUserFilters(q, _filters),
                loading: AdminContentCard(
                  child: Column(
                    children: List.generate(
                      4,
                      (i) => Container(
                        height: 44,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.alternate.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                empty: AdminContentCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 48,
                        color: AdminUi.brandTeal.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        uiTr(context, 'لا يوجد مستخدمون مسجلون'),
                        style: theme.titleMedium,
                      ),
                    ],
                  ),
                ),
                builder: (context, allUsers, listState) {
                  if (listState.hasError) {
                    return AdminContentCard(
                      child: Column(
                        children: [
                          Text(
                            uiTr(context, 'تعذر تحميل المستخدمين'),
                            style: theme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (listState.errorMessage != null)
                            Text(
                              listState.errorMessage!,
                              style: theme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          TextButton(
                            onPressed: listState.refresh,
                            child: Text(uiTr(context, 'إعادة المحاولة')),
                          ),
                        ],
                      ),
                    );
                  }

                  final users = _baseUsers(allUsers);
                  final tripKey = users.map((u) => u.reference.id).join(',');
                  if (tripKey != _tripUsersKey) {
                    _tripUsersKey = tripKey;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _resolveTrips(users);
                    });
                  }

                  final rows = _buildRows(users);
                  if (rows.isEmpty) {
                    return AdminContentCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: theme.secondaryText,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _filters.searchQuery.isEmpty && !_extra.hasAny
                                ? uiTr(context, 'لا يوجد مستخدمون مسجلون')
                                : uiTr(context, 'لا توجد نتائج للبحث'),
                            style: theme.titleMedium,
                          ),
                          if (_extra.hasAny ||
                              _filters.searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _extra = AdminCustomerExtraFilters.empty;
                                  _filters = _filters.copyWith(searchQuery: '');
                                  _serverSearchHits = null;
                                });
                              },
                              child: Text(uiTr(context, 'إعادة تعيين')),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return AdminContentCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                          child: Text(
                            adminListCountLabel(
                              context,
                              listState,
                              visibleCount: rows.length,
                              pageFetched: allUsers.length,
                            ),
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AdminCustomersTable(
                          rows: rows,
                          onToggle: _toggleActivation,
                          onOpenDetails: (u) => showAdminCustomerDetailsDrawer(
                            context: context,
                            user: u,
                          ),
                        ),
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
    );
  }
}
