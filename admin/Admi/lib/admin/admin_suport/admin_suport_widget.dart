import '/backend/admin_audit_log.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/admin/admin_suport/admin_support_adapter.dart';
import '/admin/admin_suport/admin_support_details_drawer.dart';
import '/admin/admin_suport/admin_support_filter_bar.dart';
import '/admin/admin_suport/admin_support_stats_loader.dart';
import '/admin/admin_suport/admin_support_summary_strip.dart';
import '/admin/admin_suport/admin_support_table.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'admin_suport_model.dart';
export 'admin_suport_model.dart';

class AdminSuportWidget extends StatefulWidget {
  const AdminSuportWidget({super.key});

  static String routeName = 'AdminSuport';
  static String routePath = '/adminSuport';

  @override
  State<AdminSuportWidget> createState() => _AdminSuportWidgetState();
}

class _AdminSuportWidgetState extends State<AdminSuportWidget> {
  late AdminSuportModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  AdminOpsFilterState _filters = const AdminOpsFilterState();
  AdminSupportExtraFilters _extra = AdminSupportExtraFilters.empty;
  int _pageSize = 20;
  AdminSupportStats _stats = const AdminSupportStats.empty();
  bool _statsLoading = true;
  bool _statsError = false;
  List<SupportRecord>? _serverSearchHits;
  int _searchGen = 0;
  bool _actionBusy = false;

  bool get _canEdit {
    final role = AdminRoleService.currentRole;
    return role == AdminRole.superAdmin || role == AdminRole.countryAgent;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminSuportModel());
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
      final s = await AdminSupportStatsLoader.load(filters: _filters);
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
    });
    _loadStats();
    await _maybeServerSearch(next);
  }

  Future<void> _maybeServerSearch(AdminOpsFilterState filters) async {
    final q = filters.searchQuery.trim();
    if (q.length < 4) {
      if (_serverSearchHits != null) {
        setState(() => _serverSearchHits = null);
      }
      return;
    }
    final gen = ++_searchGen;
    try {
      final hits = <SupportRecord>[];
      try {
        final doc = await SupportRecord.collection.doc(q).get();
        if (doc.exists) hits.add(SupportRecord.fromSnapshot(doc));
      } catch (_) {}
      if (hits.isEmpty && int.tryParse(q) != null) {
        final byNum = await querySupportRecordOnce(
          queryBuilder: (qq) => qq.where('id', isEqualTo: int.parse(q)),
          limit: 5,
        );
        hits.addAll(byNum);
      }
      if (!mounted || gen != _searchGen) return;
      setState(() => _serverSearchHits = hits.isEmpty ? null : hits);
    } catch (_) {
      if (!mounted || gen != _searchGen) return;
      setState(() => _serverSearchHits = null);
    }
  }

  List<AdminSupportRow> _buildRows(List<SupportRecord> tickets) {
    var rows = tickets.map(AdminSupportRow.fromTicket).toList(growable: false);

    final range = _filters.resolvedDateRange;
    if (range != null) {
      rows = rows.where((r) {
        final c = r.createdAt;
        if (c == null) return false;
        return !c.isBefore(range.startInclusive) &&
            c.isBefore(range.endExclusive);
      }).toList(growable: false);
    }

    final q = _filters.searchQuery.trim();
    if (_serverSearchHits == null && q.isNotEmpty) {
      rows = rows.where((r) => r.matchesSearch(q)).toList(growable: false);
    }

    switch (_filters.supportStatus) {
      case AdminSupportStatusFilter.open:
        rows = rows
            .where((r) =>
                r.displayStatus == AdminSupportDisplayStatus.open ||
                r.displayStatus == AdminSupportDisplayStatus.newTicket)
            .toList(growable: false);
        break;
      case AdminSupportStatusFilter.closed:
        rows = rows
            .where((r) => r.displayStatus == AdminSupportDisplayStatus.closed)
            .toList(growable: false);
        break;
      case AdminSupportStatusFilter.resolved:
        rows = rows
            .where((r) => r.displayStatus == AdminSupportDisplayStatus.resolved)
            .toList(growable: false);
        break;
      case AdminSupportStatusFilter.all:
        break;
    }

    return _extra.apply(rows);
  }

  List<SupportRecord> _baseTickets(List<SupportRecord> all) {
    if (_serverSearchHits != null) return _serverSearchHits!;
    return all;
  }

  Future<void> _updateStatus(
    AdminSupportRow row,
    AdminSupportDisplayStatus target, {
    required String confirm,
    required String success,
  }) async {
    if (_actionBusy) return;
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'تأكيد'),
      whatHappens: confirm,
      subject: row.subject,
      impact: uiTr(context, 'Support ticket status will change.'),
      destructive: target == AdminSupportDisplayStatus.closed,
    );
    if (!confirmed) return;

    setState(() => _actionBusy = true);
    try {
      final patch = adminSupportStatusPatch(
        target: target,
        isDriverSchema: row.isDriverSchema,
      );
      await row.ticket.reference.update(patch);
      await AdminAuditLog.record(
        action: 'support_status_${target.name}',
        targetType: 'support_ticket',
        targetId: row.ticketId,
        targetLabel: row.subject,
        metadata: {'status': target.name},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      AdminListRefresh.notify(AdminListScope.support);
      _loadStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appTr(context, 'adm_update_ticket_failed')}: ${AdminUserFacingErrors.from(context, e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _addInternalNote(AdminSupportRow row, String text) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await row.ticket.reference.update({
        'admin_internal_notes': FieldValue.arrayUnion([
          {
            'text': text,
            'adminId': currentUserUid,
            'at': DateTime.now().toUtc().toIso8601String(),
          },
        ]),
        'updated_at': FieldValue.serverTimestamp(),
      });
      await AdminAuditLog.record(
        action: 'support_internal_note',
        targetType: 'support_ticket',
        targetId: row.ticketId,
        targetLabel: row.subject,
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: FFLocalizations.of(context).getText('8d66hs1w'),
        child: AdminPageBody(
          title: uiTr(context, 'الدعم والتذاكر'),
          subtitle: uiTr(
            context,
            'إدارة استفسارات وشكاوى العملاء والمناديب ومتابعة حالاتها.',
          ),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSupportFilterBar(
                value: _filters,
                extra: _extra,
                pageSize: _pageSize,
                onChanged: _onFiltersChanged,
                onExtraChanged: (e) => setState(() => _extra = e),
                onPageSizeChanged: (n) => setState(() => _pageSize = n),
              ),
              const SizedBox(height: 10),
              AdminSupportSummaryStrip(
                stats: _stats,
                loading: _statsLoading,
                error: _statsError,
                onRetry: _loadStats,
              ),
              const SizedBox(height: 12),
              AdminFirestoreList<SupportRecord>(
                key: ValueKey(
                  'support_${_filters.signature}_${_pageSize}_${_extra.signature}',
                ),
                reloadKey:
                    '${_filters.signature}|$_pageSize|${_extra.signature}',
                refreshScope: AdminListScope.support,
                pageSize: _pageSize,
                liveUpdates: true,
                query: SupportRecord.collection,
                recordBuilder: SupportRecord.fromSnapshot,
                queryBuilder: (q) =>
                    AdminOpsQueryBuilder.applySupportFilters(q, _filters),
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
                        Icons.support_agent_outlined,
                        size: 48,
                        color: AdminUi.brandTeal.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        uiTr(context, 'لا توجد تذاكر دعم'),
                        style: theme.titleMedium,
                      ),
                    ],
                  ),
                ),
                builder: (context, allTickets, listState) {
                  if (listState.hasError) {
                    return AdminContentCard(
                      child: Column(
                        children: [
                          Text(
                            uiTr(context, 'تعذر تحميل التذاكر'),
                            style: theme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: listState.refresh,
                            child: Text(uiTr(context, 'إعادة المحاولة')),
                          ),
                        ],
                      ),
                    );
                  }

                  final tickets = _baseTickets(allTickets);
                  final rows = _buildRows(tickets);

                  if (rows.isEmpty) {
                    return AdminContentCard(
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            _filters.searchQuery.isEmpty && !_extra.hasAny
                                ? uiTr(context, 'لا توجد تذاكر دعم')
                                : uiTr(context, 'لا توجد نتائج للبحث'),
                            style: theme.titleMedium,
                          ),
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
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Text(
                            adminListCountLabel(
                              context,
                              listState,
                              visibleCount: rows.length,
                              pageFetched: allTickets.length,
                            ),
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AdminSupportTable(
                          rows: rows,
                          canEdit: _canEdit,
                          onOpenDetails: (row) => showAdminSupportDetailsDrawer(
                            context: context,
                            row: row,
                            canEdit: _canEdit,
                            onStatusChange: (status) => _updateStatus(
                              row,
                              status,
                              confirm: uiTr(context, 'تأكيد تغيير الحالة'),
                              success: uiTr(context, 'تم تحديث الحالة'),
                            ),
                            onInternalNote: (note) =>
                                _addInternalNote(row, note),
                          ),
                          onResolve: (row) => _updateStatus(
                            row,
                            AdminSupportDisplayStatus.resolved,
                            confirm: uiTr(
                              context,
                              'هل أنت متأكد أنه تم حل هذه التذكرة؟',
                            ),
                            success: uiTr(context, 'تم وضع التذكرة كمحلولة'),
                          ),
                          onClose: (row) => _updateStatus(
                            row,
                            AdminSupportDisplayStatus.closed,
                            confirm: uiTr(
                              context,
                              'هل أنت متأكد من إغلاق هذه التذكرة؟',
                            ),
                            success: uiTr(context, 'تم إغلاق التذكرة'),
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
