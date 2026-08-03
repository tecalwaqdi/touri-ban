import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_debounce/easy_debounce.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminSuportModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<SupportRecord> _filterTickets(List<SupportRecord> tickets) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return tickets;

    return tickets.where((t) {
      return t.naim.toLowerCase().contains(q) ||
          t.tsnef.toLowerCase().contains(q) ||
          t.osf.toLowerCase().contains(q) ||
          t.phone.toString().contains(q) ||
          t.id.toString().contains(q);
    }).toList();
  }

  Future<void> _updateTicketStatus(
    SupportRecord ticket,
    HalhSupport status, {
    required String confirmMessage,
    required String successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(uiTr(context, 'تأكيد')),
            content: Text(confirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(uiTr(context, 'نعم')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ticket.reference.update(
        createSupportRecordData(halh: status),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appTr(context, 'adm_update_ticket_failed')}: $e')),
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
        title: l10n.getText('8d66hs1w'),
        child: AdminPageBody(
          title: l10n.getText('wpcwo7sq'),
          subtitle: appTr(context, 'scr_support_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: _buildSearch(l10n),
              ),
              const SizedBox(height: 16),
              AdminFirestoreList<SupportRecord>(
                refreshScope: AdminListScope.support,
                query: SupportRecord.collection,
                recordBuilder: SupportRecord.fromSnapshot,
                queryBuilder: (q) {
                  var query = AdminCountryScope.applySupportQuery(q)
                      as Query<Map<String, dynamic>>;
                  return query.orderBy('data', descending: true);
                },
                builder: (context, allTickets, listState) {
                  final tickets = _filterTickets(allTickets);

                  return AdminContentCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(
                            'العدد: ${tickets.length}'
                            '${tickets.length != allTickets.length ? ' من ${allTickets.length}' : ''}'
                            '${listState.hasMore ? '+' : ''}',
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                        ),
                        if (tickets.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.support_agent_outlined,
                                  size: 48,
                                  color: AdminUi.brandTeal.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'لا توجد تذاكر دعم'
                                      : 'لا توجد نتائج للبحث',
                                  style: theme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        else if (isWide)
                          _TicketsTable(
                            tickets: tickets,
                            l10n: l10n,
                            onResolve: (t) => _updateTicketStatus(
                              t,
                              HalhSupport.Resolved,
                              confirmMessage:
                                  'هل أنت متأكد أنه تم حل هذه التذكرة؟',
                              successMessage: 'تم وضع التذكرة كمحلولة',
                            ),
                            onClose: (t) => _updateTicketStatus(
                              t,
                              HalhSupport.Closed,
                              confirmMessage:
                                  'هل أنت متأكد من إغلاق هذه التذكرة؟',
                              successMessage: 'تم إغلاق التذكرة',
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tickets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _TicketCard(
                              ticket: tickets[index],
                              l10n: l10n,
                              onResolve: () => _updateTicketStatus(
                                tickets[index],
                                HalhSupport.Resolved,
                                confirmMessage:
                                    'هل أنت متأكد أنه تم حل هذه التذكرة؟',
                                successMessage: 'تم وضع التذكرة كمحلولة',
                              ),
                              onClose: () => _updateTicketStatus(
                                tickets[index],
                                HalhSupport.Closed,
                                confirmMessage:
                                    'هل أنت متأكد من إغلاق هذه التذكرة؟',
                                successMessage: 'تم إغلاق التذكرة',
                              ),
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
        '_admin_support_search',
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
        label: uiTr(context, 'بحث'),
        hint: l10n.getText('olbmog91'),
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }
}

class _TicketsTable extends StatelessWidget {
  const _TicketsTable({
    required this.tickets,
    required this.l10n,
    required this.onResolve,
    required this.onClose,
  });

  final List<SupportRecord> tickets;
  final FFLocalizations l10n;
  final Future<void> Function(SupportRecord) onResolve;
  final Future<void> Function(SupportRecord) onClose;

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
                  _HeaderCell('العميل', flex: 2, theme: theme),
                  _HeaderCell('التصنيف', flex: 2, theme: theme),
                  _HeaderCell('الوصف', flex: 3, theme: theme),
                  _HeaderCell('الحالة', flex: 2, theme: theme),
                  _HeaderCell('إجراءات', flex: 2, theme: theme),
                ],
              ),
            ),
            const Divider(height: 1),
            ...tickets.map(
              (ticket) => _TicketTableRow(
                ticket: ticket,
                onResolve: () => onResolve(ticket),
                onClose: () => onClose(ticket),
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

class _TicketTableRow extends StatelessWidget {
  const _TicketTableRow({
    required this.ticket,
    required this.onResolve,
    required this.onClose,
  });

  final SupportRecord ticket;
  final VoidCallback onResolve;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isClosed = ticket.halh == HalhSupport.Closed ||
        ticket.halh == HalhSupport.Resolved;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.naim.isNotEmpty ? ticket.naim : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: !theme.bodyMediumIsCustom,
                  ),
                ),
                if (ticket.phone > 0)
                  Text(
                    ticket.phone.toString(),
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ticket.tsnef.isNotEmpty ? ticket.tsnef : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              ticket.osf.isNotEmpty ? ticket.osf : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: _TicketStatusBadge(status: ticket.halh),
          ),
          Expanded(
            flex: 2,
            child: _TicketActions(
              isClosed: isClosed,
              onResolve: onResolve,
              onClose: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.l10n,
    required this.onResolve,
    required this.onClose,
  });

  final SupportRecord ticket;
  final FFLocalizations l10n;
  final VoidCallback onResolve;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isClosed = ticket.halh == HalhSupport.Closed ||
        ticket.halh == HalhSupport.Resolved;

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
                  Icons.confirmation_number_outlined,
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
                      ticket.naim.isNotEmpty ? ticket.naim : '—',
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        color: AdminUi.brandTeal,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    if (ticket.id > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'تذكرة #${ticket.id}',
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _TicketStatusBadge(status: ticket.halh),
                  ],
                ),
              ),
              if (!isClosed)
                _TicketActions(
                  isClosed: isClosed,
                  onResolve: onResolve,
                  onClose: onClose,
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (ticket.tsnef.isNotEmpty)
            _InfoTile(
              icon: Icons.category_outlined,
              label: uiTr(context, 'التصنيف'),
              value: ticket.tsnef,
            ),
          if (ticket.tsnef.isNotEmpty) const SizedBox(height: 8),
          if (ticket.phone > 0)
            _InfoTile(
              icon: Icons.phone_rounded,
              label: uiTr(context, 'الجوال'),
              value: ticket.phone.toString(),
            ),
          if (ticket.phone > 0) const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.description_outlined,
            label: uiTr(context, 'الوصف'),
            value: ticket.osf.isNotEmpty ? ticket.osf : '—',
          ),
          if (ticket.data != null) ...[
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.schedule_rounded,
              label: uiTr(context, 'التاريخ'),
              value: dateTimeFormat(
                'd/M/y – HH:mm',
                ticket.data,
                locale: 'ar',
              ),
            ),
          ],
          if (isClosed) ...[
            const SizedBox(height: 12),
            _TicketActions(
              isClosed: isClosed,
              onResolve: onResolve,
              onClose: onClose,
              fullWidth: true,
            ),
          ],
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
  });

  final IconData icon;
  final String label;
  final String value;

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
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketStatusBadge extends StatelessWidget {
  const _TicketStatusBadge({required this.status});

  final HalhSupport? status;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = _statusLabel(status);
    final colors = _statusColors(status, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
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

String _statusLabel(HalhSupport? status) {
  switch (status) {
    case HalhSupport.Open:
      return 'مفتوحة';
    case HalhSupport.Resolved:
      return 'تم الحل';
    case HalhSupport.Closed:
      return 'مغلقة';
    case null:
      return 'غير معرفة';
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

_StatusColors _statusColors(HalhSupport? status, FlutterFlowTheme theme) {
  switch (status) {
    case HalhSupport.Open:
      return _StatusColors(
        background: const Color(0xFFFFF3E0),
        foreground: const Color(0xFFE65100),
      );
    case HalhSupport.Resolved:
      return _StatusColors(
        background: const Color(0xFFE8F5E9),
        foreground: const Color(0xFF2E7D32),
      );
    case HalhSupport.Closed:
      return _StatusColors(
        background: const Color(0xFFFFEBEE),
        foreground: theme.error,
      );
    case null:
      return _StatusColors(
        background: theme.accent4,
        foreground: theme.secondaryText,
      );
  }
}

class _TicketActions extends StatelessWidget {
  const _TicketActions({
    required this.isClosed,
    required this.onResolve,
    required this.onClose,
    this.fullWidth = false,
  });

  final bool isClosed;
  final VoidCallback onResolve;
  final VoidCallback onClose;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);

    if (isClosed) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          'تمت المعالجة',
          style: FlutterFlowTheme.of(context).labelMedium.override(
                fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                color: FlutterFlowTheme.of(context).secondaryText,
                useGoogleFonts:
                    !FlutterFlowTheme.of(context).labelMediumIsCustom,
              ),
        ),
      );
    }

    final buttons = [
      Expanded(
        child: AdminPrimaryButton(
          label: l10n.getText('0iw3wb8t'),
          icon: Icons.check_circle_outline_rounded,
          onPressed: onResolve,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: AdminPrimaryButton(
          label: l10n.getText('uon0jgl1'),
          icon: Icons.close_rounded,
          outlined: true,
          onPressed: onClose,
        ),
      ),
    ];

    if (fullWidth) {
      return Row(children: buttons);
    }

    return Column(
      children: [
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFE8F5E9),
          icon: Icon(
            Icons.check_circle_outline_rounded,
            color: FlutterFlowTheme.of(context).success,
            size: 18,
          ),
          onPressed: onResolve,
        ),
        const SizedBox(height: 6),
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFFFEBEE),
          icon: Icon(
            Icons.close_rounded,
            color: FlutterFlowTheme.of(context).error,
            size: 18,
          ),
          onPressed: onClose,
        ),
      ],
    );
  }
}
