import '/backend/admin_country_scope.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'admin_agent_model.dart';
export 'admin_agent_model.dart';

class AdminAgentWidget extends StatefulWidget {
  const AdminAgentWidget({super.key});

  static String routeName = 'AdminAgent';
  static String routePath = '/adminAgent';

  @override
  State<AdminAgentWidget> createState() => _AdminAgentWidgetState();
}

class _AdminAgentWidgetState extends State<AdminAgentWidget> {
  late AdminAgentModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  bool _landmarkCountsPreloaded = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAgentModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<UserRecord> _filterAgents(List<UserRecord> agents) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return agents;
    return agents.where((a) {
      return a.displayName.toLowerCase().contains(q) ||
          a.dolhAgent.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q) ||
          a.phoneNumber.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteAgent(UserRecord agent) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appTr(context, 'adm_delete_confirm_title')),
            content: Text(appTrFormat(context, 'adm_delete_agent_body', agent.displayName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(appTr(context, 'adm_yes_delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await AdminFirestoreDelete.deleteDocument(agent.reference);
      await AdminAuditLog.recordDelete(
        targetType: 'agent',
        targetId: agent.reference.id,
        targetLabel: agent.displayName,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف الوكيل بنجاح'),
        refreshScope: AdminListScope.agents,
        removedDocumentId: agent.reference.id,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, 'تعذر حذف الوكيل: $e');
    }
  }

  void _preloadAgentLandmarkCounts(List<UserRecord> agents) {
    final refs = agents
        .map((a) => a.revDlohAgent)
        .whereType<DocumentReference>()
        .toSet();
    if (refs.isEmpty) return;
    AdminLandmarkCountCache.preloadCountries(refs).then((_) {
      if (mounted) safeSetState(() {});
    });
  }

  void _openReport(UserRecord agent) {
    context.pushNamed(
      AdminAgentReportWidget.routeName,
      queryParameters: {
        'iduser': serializeParam(
          agent.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  void _openEdit(UserRecord agent) {
    context.pushNamed(
      EdetAgentWidget.routeName,
      queryParameters: {
        'agentRef': serializeParam(
          agent.reference,
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

    if (!AdminSuperAdminGate.isAllowed) {
      final blocked = AdminSuperAdminGate.guardLayout(
        context: context,
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: l10n.getText('x1v93obz'),
        feature: uiTr(context, 'إدارة الوكلاء'),
      );
      if (blocked != null) return blocked;
    }

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
        title: l10n.getText('x1v93obz'),
        child: AdminPageBody(
          title: l10n.getText('x1v93obz'),
          subtitle: appTr(context, 'scr_agents_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: isWide
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
              ),
              const SizedBox(height: 16),
              AdminFirestoreList<UserRecord>(
                refreshScope: AdminListScope.agents,
                query: UserRecord.collection,
                recordBuilder: UserRecord.fromSnapshot,
                queryBuilder: (q) => AdminCountryScope.applyAgentUserQuery(q),
                builder: (context, allAgents, listState) {
                  final agents = _filterAgents(allAgents);
                  if (!_landmarkCountsPreloaded && agents.isNotEmpty) {
                    _landmarkCountsPreloaded = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _preloadAgentLandmarkCounts(agents);
                    });
                  }

                  if (agents.isEmpty) {
                    return AdminContentCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.real_estate_agent_outlined,
                            size: 48,
                            color: AdminUi.brandTeal.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'لا يوجد وكلاء مسجلون'
                                : 'لا توجد نتائج للبحث',
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
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Text(
                            'العدد: ${agents.length}'
                            '${agents.length != allAgents.length ? ' من ${allAgents.length}' : ''}'
                            '${listState.hasMore ? '+' : ''}',
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isWide)
                          _AgentsTable(
                            agents: agents,
                            l10n: l10n,
                            landmarkCounts: null,
                            onReport: _openReport,
                            onEdit: _openEdit,
                            onDelete: _deleteAgent,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: agents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _AgentCard(
                              agent: agents[index],
                              l10n: l10n,
                              landmarkCounts: null,
                              onReport: () => _openReport(agents[index]),
                              onEdit: () => _openEdit(agents[index]),
                              onDelete: () => _deleteAgent(agents[index]),
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
        '_admin_agent_search',
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
        hint: l10n.getText('3usvges2'),
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }

  Widget _buildAddButton(FFLocalizations l10n) {
    return AdminPrimaryButton(
      label: l10n.getText('6zv3ufaj'),
      icon: Icons.add_rounded,
      onPressed: () => context.pushNamed(AdminAddAgentWidget.routeName),
    );
  }
}

class _AgentsTable extends StatelessWidget {
  const _AgentsTable({
    required this.agents,
    required this.l10n,
    required this.landmarkCounts,
    required this.onReport,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UserRecord> agents;
  final FFLocalizations l10n;
  final Map<String, int>? landmarkCounts;
  final void Function(UserRecord) onReport;
  final void Function(UserRecord) onEdit;
  final Future<void> Function(UserRecord) onDelete;

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
                  _HeaderCell(l10n.getText('yin4wus7'), flex: 3, theme: theme),
                  _HeaderCell(l10n.getText('n82h1wal'), flex: 2, theme: theme),
                  _HeaderCell(l10n.getText('jieasbyx'), flex: 2, theme: theme),
                  _HeaderCell(l10n.getText('kdjv6uo1'), flex: 2, theme: theme),
                  _HeaderCell(l10n.getText('cwtxf8db'), flex: 2, theme: theme),
                ],
              ),
            ),
            const Divider(height: 1),
            ...agents.map(
              (agent) => _AgentTableRow(
                agent: agent,
                landmarkCounts: landmarkCounts,
                onReport: () => onReport(agent),
                onEdit: () => onEdit(agent),
                onDelete: () => onDelete(agent),
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

class _AgentTableRow extends StatelessWidget {
  const _AgentTableRow({
    required this.agent,
    required this.landmarkCounts,
    required this.onReport,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRecord agent;
  final Map<String, int>? landmarkCounts;
  final VoidCallback onReport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

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
            flex: 3,
            child: Row(
              children: [
                _AgentAvatar(user: agent, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    agent.displayName.isNotEmpty ? agent.displayName : '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.override(
                      fontFamily: theme.bodyMediumFamily,
                      fontWeight: FontWeight.w600,
                      useGoogleFonts: !theme.bodyMediumIsCustom,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              agent.dolhAgent.isNotEmpty ? agent.dolhAgent : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              agent.bookingsAgent.toString(),
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                fontWeight: FontWeight.w700,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _LandmarksCount(agent: agent),
          ),
          Expanded(
            flex: 2,
            child: _AgentActions(
              onEdit: onEdit,
              onReport: onReport,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.agent,
    required this.l10n,
    required this.landmarkCounts,
    required this.onReport,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRecord agent;
  final FFLocalizations l10n;
  final Map<String, int>? landmarkCounts;
  final VoidCallback onReport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
              _AgentAvatar(user: agent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.displayName.isNotEmpty ? agent.displayName : '—',
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
                    if (agent.dolhAgent.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AdminUi.brandTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          agent.dolhAgent,
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            color: AdminUi.brandTeal,
                            fontWeight: FontWeight.w600,
                            useGoogleFonts: !theme.labelSmallIsCustom,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _AgentActions(
                onEdit: onEdit,
                onReport: onReport,
                onDelete: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.event_available_rounded,
                  label: l10n.getText('jieasbyx'),
                  value: agent.bookingsAgent.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.place_rounded,
                  label: l10n.getText('kdjv6uo1'),
                  valueWidget: _LandmarksCount(agent: agent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AdminUi.brandTeal),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
          const SizedBox(height: 2),
          valueWidget ??
              Text(
                value ?? '—',
                style: theme.titleSmall.override(
                  fontFamily: theme.titleSmallFamily,
                  fontWeight: FontWeight.w700,
                  useGoogleFonts: !theme.titleSmallIsCustom,
                ),
              ),
        ],
      ),
    );
  }
}

class _LandmarksCount extends StatelessWidget {
  const _LandmarksCount({required this.agent});

  final UserRecord agent;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final cached = AdminLandmarkCountCache.peekCached(agent.revDlohAgent);

    if (cached != null) {
      return Text(
        cached.toString(),
        style: theme.bodyMedium.override(
          fontFamily: theme.bodyMediumFamily,
          fontWeight: FontWeight.w700,
          useGoogleFonts: !theme.bodyMediumIsCustom,
        ),
      );
    }

    return FutureBuilder<int>(
      future: AdminLandmarkCountCache.countForCountry(agent.revDlohAgent),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primary,
            ),
          );
        }

        return Text(
          snapshot.data.toString(),
          style: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            fontWeight: FontWeight.w700,
            useGoogleFonts: !theme.bodyMediumIsCustom,
          ),
        );
      },
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar({required this.user, this.size = 44});

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
      Icons.real_estate_agent_rounded,
      color: AdminUi.brandTeal,
      size: size * 0.5,
    );
  }
}

class _AgentActions extends StatelessWidget {
  const _AgentActions({
    required this.onEdit,
    required this.onReport,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFE8F5E9),
          icon: Icon(
            Icons.edit_rounded,
            color: AdminUi.brandTeal,
            size: 18,
          ),
          onPressed: onEdit,
        ),
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFE3F2FD),
          icon: Icon(
            Icons.bar_chart_rounded,
            color: FlutterFlowTheme.of(context).primary,
            size: 18,
          ),
          onPressed: onReport,
        ),
        FlutterFlowIconButton(
          borderRadius: 8,
          buttonSize: 36,
          fillColor: const Color(0xFFFFEBEE),
          icon: Icon(
            Icons.delete_rounded,
            color: FlutterFlowTheme.of(context).error,
            size: 18,
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
