import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_filter_bar.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_pagination_bar.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_summary_strip.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_table.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_dashboard_invalidate.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/backend.dart';
import '/backend/dashboard_stats_loader.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_booking_status_label.dart';
import '/core/finance/financial_engine.dart';
import '/core/toury_system_status_codes.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'admin_a_l_lhg_z_model.dart';
export 'admin_a_l_lhg_z_model.dart';

class AdminALLhgZWidget extends StatefulWidget {
  const AdminALLhgZWidget({super.key});

  static String routeName = 'AdminALLhgZ';
  static String routePath = '/adminALLhgZ';

  @override
  State<AdminALLhgZWidget> createState() => _AdminALLhgZWidgetState();
}

class _AdminALLhgZWidgetState extends State<AdminALLhgZWidget> {
  late AdminALLhgZModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Default: all statuses, newest first — ops can narrow with filters.
  AdminOpsFilterState _filters = const AdminOpsFilterState();
  AdminBookingsExtraFilters _extra = AdminBookingsExtraFilters.empty;
  AdminBookingsSortKey _sortKey = AdminBookingsSortKey.dateDesc;
  int _pageSize = 20;

  List<OrderRecord>? _serverSearchHits;
  int _searchGen = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminALLhgZModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool get _canCancelBooking =>
      AdminRoleService.isSuperAdmin || AdminRoleService.isCountryAgent;

  String get _listSignature =>
      '${_filters.signature}|${_extra.signature}|$_pageSize|${_sortKey.name}';

  Future<void> _onFiltersChanged(AdminOpsFilterState next) async {
    setState(() {
      _filters = next;
      _serverSearchHits = null;
    });
    final plan = AdminOpsSearch.classify(next.searchQuery);
    if (!plan.isServerSide) return;
    final gen = ++_searchGen;
    final hits = await AdminBookingsSearch.searchServer(plan, next);
    if (!mounted || gen != _searchGen) return;
    setState(() => _serverSearchHits = hits);
  }

  List<OrderRecord> _prepareBookings(List<OrderRecord> allBookings) {
    final scoped = AdminCountryScope.filterOrders(allBookings);
    final filtered = AdminBookingsQuery.applyClientFilters(
      scoped,
      filters: _filters,
      extra: _extra,
      serverSearchHits: _serverSearchHits,
    );
    // Server already sorts by data_order desc; re-sort when user picks other keys
    // or when search hits arrive unsorted.
    if (_sortKey == AdminBookingsSortKey.dateDesc &&
        _serverSearchHits == null) {
      return filtered;
    }
    return AdminBookingsSorter.sort(filtered, _sortKey);
  }

  AdminBookingsSummaryCounts _summaryFor({
    required int results,
    required int? queryTotal,
  }) {
    final stats = peekDashboardStats();
    if (stats == null) {
      return AdminBookingsSummaryCounts(
        results: results,
        total: queryTotal,
      );
    }
    return AdminBookingsSummaryCounts(
      results: results,
      total: queryTotal ?? stats.bookingsTotal,
      active: stats.activeBookings,
      completed: stats.bookingsCompleted,
      cancelled: stats.bookingsCancelled,
      expired: stats.bookingsExpired,
      fromDashboard: true,
    );
  }

  Future<void> _cancelBooking(OrderRecord order) async {
    if (!_canCancelBooking) return;
    if (AdminBookingStatusLabel.isTerminal(order) ||
        OrderStatusHelper.isCanceled(order)) {
      return;
    }

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'تأكيد الإلغاء'),
      whatHappens: uiTr(context, 'هل أنت متأكد من إلغاء الحجز'),
      subject: '#${order.iDorder}',
      impact: uiTr(context, 'Customer can book again; order marked cancelled'),
      confirmLabel: uiTr(context, 'نعم، ألغِ'),
      cancelLabel: appTr(context, 'adm_no'),
      destructive: true,
      irreversible: true,
      reference: order.reference.id,
    );

    if (!confirmed) return;

    try {
      await order.reference.update({
        ...createOrderRecordData(
          halhText: 'ملغي',
          halhOrder: Halh.Canceled,
          allnow: false,
        ),
        'status_code': TourySystemStatusCodes.cancelledByAdmin,
        'cancelled_by_code': TourySystemStatusCodes.cancelledByAdmin,
        'cancelledAt': FieldValue.serverTimestamp(),
        'ALLNOW': false,
        'ActiveOrder': false,
        'NotSestem': 'admin_cancelled',
      });
      AdminStatsCoordinator.instance.invalidateAfterBookingChange();
      flushAdminDashboardStatsNow();

      final customerRef = order.user;
      if (customerRef != null) {
        try {
          await customerRef.set(
            {
              'active_order_id': FieldValue.delete(),
              'active_order_updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (_) {}
      }

      await AdminAuditLog.recordCancel(
        targetType: 'booking',
        targetId: order.reference.id,
        targetLabel: order.iDorder,
      );

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم إلغاء الحجز بنجاح'),
        refreshScope: AdminListScope.bookings,
        invalidateStats: true,
        deferHeavyWork: false,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(
        context,
        AdminCrudFeedback.updateFailed(context, e),
      );
    }
  }

  void _openDetails(OrderRecord order) {
    context.pushNamed(
      AdminBookingDetailsWidget.routeName,
      queryParameters: {
        'idbokeng': serializeParam(
          order.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
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
        title: l10n.getText('kw5c519x'),
        child: AdminPageBody(
          title: l10n.getText('kw5c519x'),
          subtitle: appTr(context, 'scr_bookings_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminBookingsFilterBar(
                value: _filters,
                extra: _extra,
                sortKey: _sortKey,
                pageSize: _pageSize,
                onChanged: _onFiltersChanged,
                onExtraChanged: (e) => setState(() => _extra = e),
                onSortChanged: (k) => setState(() => _sortKey = k),
                onPageSizeChanged: (n) => setState(() => _pageSize = n),
              ),
              const SizedBox(height: 10),
              AdminFirestoreList<OrderRecord>(
                key: ValueKey('bookings_$_listSignature'),
                reloadKey: _listSignature,
                pageSize: _pageSize,
                liveUpdates: false,
                refreshScope: AdminListScope.bookings,
                query: OrderRecord.collection,
                recordBuilder: OrderRecord.fromSnapshot,
                queryBuilder: (q) => AdminBookingsQuery.applyFilters(q, _filters),
                countQueryBuilder: (q) =>
                    AdminBookingsQuery.applyFiltersCore(q, _filters),
                loading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: AdminBookingsSkeleton(),
                ),
                builder: (context, allBookings, listState) {
                  final bookings = _prepareBookings(allBookings);
                  final summary = _summaryFor(
                    results: bookings.length,
                    queryTotal: listState.totalAvailable,
                  );
                  final waitingServerSearch = _filters.searchQuery
                          .trim()
                          .isNotEmpty &&
                      AdminOpsSearch.classify(_filters.searchQuery)
                          .isServerSide &&
                      _serverSearchHits == null;

                  return AdminContentCard(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdminBookingsSummaryStrip(
                          counts: summary,
                          isLoading: listState.isLoading && bookings.isEmpty,
                        ),
                        const SizedBox(height: 10),
                        if (waitingServerSearch)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          )
                        else if (bookings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_note_outlined,
                                  size: 44,
                                  color:
                                      AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _filters.searchQuery.isEmpty && !_extra.hasAny
                                      ? uiTr(context, 'لا توجد حجوزات')
                                      : uiTr(context, 'لا توجد نتائج للبحث'),
                                  style: theme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  uiTr(
                                    context,
                                    'جرّب تغيير الفلاتر أو إعادة الضبط',
                                  ),
                                  style: theme.bodySmall.override(
                                    fontFamily: theme.bodySmallFamily,
                                    color: theme.secondaryText,
                                    useGoogleFonts: !theme.bodySmallIsCustom,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isWide)
                          AdminBookingsTable(
                            bookings: bookings,
                            onDetails: _openDetails,
                            onCancel: _cancelBooking,
                            canCancel: _canCancelBooking,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bookings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) =>
                                AdminBookingListCard(
                              order: bookings[index],
                              onDetails: () =>
                                  _openDetails(bookings[index]),
                              onCancel: () =>
                                  _cancelBooking(bookings[index]),
                              canCancel: _canCancelBooking,
                            ),
                          ),
                        AdminBookingsPaginationBar(
                          state: listState,
                          pageSize: _pageSize,
                          visibleCount: bookings.length,
                        ),
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
