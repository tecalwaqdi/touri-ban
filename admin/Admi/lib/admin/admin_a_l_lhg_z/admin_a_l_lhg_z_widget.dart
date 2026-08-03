import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';
import '/backend/admin_audit_log.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_booking_status_label.dart';
import '/core/finance/financial_engine.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminALLhgZModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<OrderRecord> _filterBookings(List<OrderRecord> bookings) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return bookings;

    return bookings.where((b) {
      final statusLabel = AdminBookingStatusLabel.of(b).toLowerCase();
      return b.iDorder.toLowerCase().contains(q) ||
          b.naimUserText.toLowerCase().contains(q) ||
          b.naimMndobText.toLowerCase().contains(q) ||
          b.halhText.toLowerCase().contains(q) ||
          statusLabel.contains(q) ||
          b.villText.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _cancelBooking(OrderRecord order) async {
    if (OrderStatusHelper.isCanceled(order)) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(uiTr(context, 'تأكيد الإلغاء')),
            content: Text(
              'هل أنت متأكد من إلغاء الحجز #${order.iDorder}؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(uiTr(context, 'نعم، ألغِ')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await order.reference.update(
        createOrderRecordData(
          halhText: 'ملغي',
          halhOrder: Halh.Canceled,
          allnow: false,
        ),
      );

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
      AdminCrudFeedback.error(context, 'تعذر إلغاء الحجز: $e');
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
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: _buildSearch(l10n),
              ),
              const SizedBox(height: 16),
              AdminFirestoreList<OrderRecord>(
                refreshScope: AdminListScope.bookings,
                query: OrderRecord.collection,
                recordBuilder: OrderRecord.fromSnapshot,
                queryBuilder: (q) => AdminCountryScope.applyOrderQuery(q)
                    .where('ALLNOW', isEqualTo: true)
                    .orderBy('data_order', descending: true),
                builder: (context, allBookings, listState) {
                  final bookings =
                      _filterBookings(AdminCountryScope.filterOrders(allBookings));

                  return AdminContentCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(
                            'العدد: ${bookings.length}'
                            '${bookings.length != allBookings.length ? ' من ${allBookings.length}' : ''}'
                            '${listState.hasMore ? '+' : ''}',
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                        ),
                        if (bookings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_note_outlined,
                                  size: 48,
                                  color: AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'لا توجد حجوزات حالية'
                                      : 'لا توجد نتائج للبحث',
                                  style: theme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        else if (isWide)
                          _BookingsTable(
                            bookings: bookings,
                            l10n: l10n,
                            onDetails: _openDetails,
                            onCancel: _cancelBooking,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bookings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _BookingCard(
                              order: bookings[index],
                              l10n: l10n,
                              onDetails: () => _openDetails(bookings[index]),
                              onCancel: () => _cancelBooking(bookings[index]),
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

  Widget _buildSearch(FFLocalizations l10n) {
    return TextFormField(
      controller: _model.textController,
      focusNode: _model.textFieldFocusNode,
      onChanged: (_) => EasyDebounce.debounce(
        '_admin_bookings_search',
        const Duration(milliseconds: 300),
        () {
          if (mounted) {
            setState(() {
              _searchQuery = _model.textController?.text ?? '';
            });
          }
        },
      ),
      decoration: AdminUi.inputDecoration(
        context,
        label: l10n.getText('97vbpavm'),
        hint: l10n.getText('aa34zq8w'),
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }
}

class _BookingsTable extends StatelessWidget {
  const _BookingsTable({
    required this.bookings,
    required this.l10n,
    required this.onDetails,
    required this.onCancel,
  });

  final List<OrderRecord> bookings;
  final FFLocalizations l10n;
  final void Function(OrderRecord) onDetails;
  final Future<void> Function(OrderRecord) onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: AdminUi.adminTableMinWidth(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  _HeaderCell('رقم الحجز', flex: 2, theme: theme),
                  _HeaderCell('العميل', flex: 3, theme: theme),
                  _HeaderCell('المندوب', flex: 2, theme: theme),
                  _HeaderCell('المبلغ', flex: 2, theme: theme),
                  _HeaderCell('الحالة', flex: 2, theme: theme),
                  _HeaderCell('إجراءات', flex: 2, theme: theme),
                ],
              ),
            ),
            const Divider(height: 1),
            ...bookings.map(
              (order) => _BookingTableRow(
                order: order,
                onDetails: () => onDetails(order),
                onCancel: () => onCancel(order),
              ),
            ),
          ],
        ),
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
        text,
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

class _BookingTableRow extends StatelessWidget {
  const _BookingTableRow({
    required this.order,
    required this.onDetails,
    required this.onCancel,
  });

  final OrderRecord order;
  final VoidCallback onDetails;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isCanceled = OrderStatusHelper.isCanceled(order);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '#${order.iDorder.isNotEmpty ? order.iDorder : '—'}',
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                fontWeight: FontWeight.w700,
                color: AdminUi.brandTeal,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              order.naimUserText.isNotEmpty ? order.naimUserText : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              order.naimMndobText.isNotEmpty
                  ? order.naimMndobText
                  : 'لم يُربط',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatNumber(
                order.total,
                formatType: FormatType.decimal,
                decimalType: DecimalType.automatic,
                currency: 'ريال ',
              ),
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                fontWeight: FontWeight.w700,
                color: theme.success,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ),
          Expanded(flex: 2, child: _BookingStatusBadge(order: order)),
          Expanded(
            flex: 2,
            child: _BookingActions(
              isCanceled: isCanceled,
              onDetails: onDetails,
              onCancel: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.order,
    required this.l10n,
    required this.onDetails,
    required this.onCancel,
  });

  final OrderRecord order;
  final FFLocalizations l10n;
  final VoidCallback onDetails;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isCanceled = OrderStatusHelper.isCanceled(order);

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AdminUi.brandTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AdminUi.brandTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حجز #${order.iDorder.isNotEmpty ? order.iDorder : '—'}',
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        color: AdminUi.brandTeal,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.naimUserText.isNotEmpty
                          ? order.naimUserText
                          : '—',
                      style: theme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    _BookingStatusBadge(order: order),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.person_outline_rounded,
            label: l10n.getText('x3zd9pqx'),
            value: order.naimMndobText.isNotEmpty
                ? order.naimMndobText
                : 'لم يتم الربط مع مندوب',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.payments_outlined,
                  label: l10n.getText('rws65o2j'),
                  value: formatNumber(
                    order.total,
                    formatType: FormatType.decimal,
                    decimalType: DecimalType.automatic,
                    currency: 'ريال ',
                  ),
                  highlight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.percent_rounded,
                  label: l10n.getText('j433bzmg'),
                  value: formatNumber(
                    order.totalApp,
                    formatType: FormatType.decimal,
                    decimalType: DecimalType.automatic,
                    currency: 'ريال ',
                  ),
                ),
              ),
            ],
          ),
          if (order.dataOrder != null) ...[
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.calendar_today_rounded,
              label: uiTr(context, 'تاريخ الحجز'),
              value: dateTimeFormat(
                'd/M/y – HH:mm',
                order.dataOrder,
                locale: 'ar',
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminPrimaryButton(
                  label: l10n.getText('ecd9n9f5'),
                  icon: Icons.visibility_outlined,
                  onPressed: onDetails,
                ),
              ),
              if (!isCanceled) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AdminPrimaryButton(
                    label: l10n.getText('4g0u2fzy'),
                    icon: Icons.cancel_outlined,
                    outlined: true,
                    onPressed: onCancel,
                  ),
                ),
              ],
            ],
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
                label,
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (highlight ? theme.titleSmall : theme.bodyMedium).override(
                  fontFamily: highlight
                      ? theme.titleSmallFamily
                      : theme.bodyMediumFamily,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight ? theme.success : null,
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

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = AdminBookingStatusLabel.of(order);
    final colors = _statusColors(AdminBookingStatusLabel.toneOf(order), theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isNotEmpty ? status : 'غير محدد',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          color: colors.foreground,
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

_StatusColors _statusColors(AdminBookingStatusTone tone, FlutterFlowTheme theme) {
  switch (tone) {
    case AdminBookingStatusTone.pendingDriver:
      return const _StatusColors(
        background: Color(0xFFFFF3E0),
        foreground: Color(0xFFE65100),
      );
    case AdminBookingStatusTone.accepted:
      return const _StatusColors(
        background: Color(0xFFE3F2FD),
        foreground: AdminUi.brandTeal,
      );
    case AdminBookingStatusTone.canceled:
      return _StatusColors(
        background: const Color(0xFFFFEBEE),
        foreground: theme.error,
      );
    case AdminBookingStatusTone.completed:
      return _StatusColors(
        background: theme.success.withValues(alpha: 0.12),
        foreground: theme.success,
      );
    case AdminBookingStatusTone.unknown:
      return _StatusColors(
        background: theme.accent4,
        foreground: theme.secondaryText,
      );
  }
}

class _BookingActions extends StatelessWidget {
  const _BookingActions({
    required this.isCanceled,
    required this.onDetails,
    required this.onCancel,
  });

  final bool isCanceled;
  final VoidCallback onDetails;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
          icon: const Icon(
            Icons.visibility_outlined,
            color: AdminUi.brandTeal,
            size: 18,
          ),
          onPressed: onDetails,
        ),
        if (!isCanceled)
          FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 36,
            fillColor: const Color(0xFFFFEBEE),
            icon: Icon(
              Icons.cancel_outlined,
              color: FlutterFlowTheme.of(context).error,
              size: 18,
            ),
            onPressed: onCancel,
          ),
      ],
    );
  }
}
