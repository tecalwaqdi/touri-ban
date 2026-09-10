import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/driver_admin_stats_loader.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Unified Drivers workspace — All / Pending / Documents / Expiring Soon.
///
/// Reuses existing roster + expiry queries and country scope. Does not change
/// registration or approval backends.
enum AdminDriversHubTab {
  all,
  pending,
  documents,
  expiringSoon,
}

class AdminDriversHubWidget extends StatefulWidget {
  const AdminDriversHubWidget({
    super.key,
    this.initialTab = AdminDriversHubTab.all,
  });

  final AdminDriversHubTab initialTab;

  static const String routeName = 'AdminDriversHub';
  static const String routePath = '/adminDriversHub';

  static AdminDriversHubTab tabFromQuery(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'pending':
        return AdminDriversHubTab.pending;
      case 'documents':
      case 'docs':
        return AdminDriversHubTab.documents;
      case 'expiring':
      case 'expiring_soon':
        return AdminDriversHubTab.expiringSoon;
      default:
        return AdminDriversHubTab.all;
    }
  }

  @override
  State<AdminDriversHubWidget> createState() => _AdminDriversHubWidgetState();
}

class _AdminDriversHubWidgetState extends State<AdminDriversHubWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  late AdminDriversHubTab _tab;
  DriverAdminStats _stats = DriverAdminStats.empty;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _tab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final s = await DriverAdminStatsLoader.load();
      if (!mounted) return;
      setState(() {
        _stats = s;
        _statsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  AdminOpsFilterState get _pendingFilters => const AdminOpsFilterState(
        driverReview: AdminDriverReviewFilter.pendingReview,
      );

  AdminOpsFilterState get _documentsFilters => const AdminOpsFilterState(
        driverDocuments: AdminDriverDocumentsFilter.missing,
      );

  int _countFor(AdminDriversHubTab tab) {
    switch (tab) {
      case AdminDriversHubTab.all:
        return _stats.total;
      case AdminDriversHubTab.pending:
        // Match list filter: registration_status == pending_review only.
        // Stats.pendingReview also includes `submitted`; chip uses pinned list
        // semantics via pendingReview when not reviewing — show pendingReview
        // for operator attention, list uses pending_review query.
        return _stats.pendingReview;
      case AdminDriversHubTab.documents:
        return _stats.docsMissing;
      case AdminDriversHubTab.expiringSoon:
        return _stats.expiringSoon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isAgent = AdminRoleService.isCountryAgent;

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      padContent: false,
      title: uiTr(context, 'السائقون'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AdminUi.pagePadding(context).copyWith(bottom: 0),
            child: AdminPageHeader(
              title: uiTr(context, 'السائقون'),
              subtitle: uiTr(
                context,
                isAgent
                    ? 'إدارة سائقي دولتك — قائمة ومراجعة ووثائق.'
                    : 'مساحة موحّدة للسائقين: الكل، بانتظار المراجعة، الوثائق، والتنتهي قريبًا.',
              ),
              trailing: AdminPrimaryButton(
                label: uiTr(context, 'إضافة سائق'),
                icon: Icons.person_add_rounded,
                onPressed: () => context.pushNamed(AddDrevWidget.routeName),
              ),
            ),
          ),
          Padding(
            padding: AdminUi.pagePadding(context).copyWith(top: 8, bottom: 8),
            child: AdminPeriodSegmented<AdminDriversHubTab>(
              values: AdminDriversHubTab.values,
              selected: _tab,
              labels: {
                for (final t in AdminDriversHubTab.values)
                  t: _tabLabel(context, t),
              },
              onChanged: (t) {
                setState(() => _tab = t);
                _loadStats();
              },
              onRefresh: _loadStats,
              refreshTooltip: uiTr(context, 'تحديث'),
            ),
          ),
          Padding(
            padding: AdminUi.pagePadding(context).copyWith(top: 0, bottom: 8),
            child: Semantics(
              identifier: 'qa-drivers-hub-counts',
              label:
                  'all:${_stats.total} pending:${_stats.pendingReview} docs:${_stats.docsMissing} expiring:${_stats.expiringSoon}',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in AdminDriversHubTab.values)
                    _CountChip(
                      label: _tabLabel(context, t),
                      value: _statsLoading ? '…' : '${_countFor(t)}',
                      selected: _tab == t,
                      onTap: () => setState(() => _tab = t),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: _tabBody(theme),
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(BuildContext context, AdminDriversHubTab tab) {
    switch (tab) {
      case AdminDriversHubTab.all:
        return uiTr(context, 'الكل');
      case AdminDriversHubTab.pending:
        return uiTr(context, 'بانتظار المراجعة');
      case AdminDriversHubTab.documents:
        return uiTr(context, 'الوثائق');
      case AdminDriversHubTab.expiringSoon:
        return uiTr(context, 'تنتهي قريبًا');
    }
  }

  Widget _tabBody(FlutterFlowTheme theme) {
    switch (_tab) {
      case AdminDriversHubTab.all:
        return AdmindreverWidget(
          embedded: true,
          showPageChrome: false,
        );
      case AdminDriversHubTab.pending:
        return AdmindreverWidget(
          embedded: true,
          showPageChrome: false,
          initialFilters: _pendingFilters,
        );
      case AdminDriversHubTab.documents:
        return AdmindreverWidget(
          embedded: true,
          showPageChrome: false,
          initialFilters: _documentsFilters,
        );
      case AdminDriversHubTab.expiringSoon:
        return const AdminDriverExpiryQueueWidget(
          embedded: true,
          initialBucket: 'expiring_soon',
        );
    }
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = selected ? AdminUi.brandTeal : theme.secondaryText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.labelSmall.copyWith(color: color)),
            const SizedBox(width: 6),
            Text(
              value,
              style: theme.labelLarge.override(
                fontFamily: theme.labelLargeFamily,
                fontWeight: FontWeight.w800,
                color: color,
                useGoogleFonts: !theme.labelLargeIsCustom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
