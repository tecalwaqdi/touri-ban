import 'dart:async';

import '/backend/admin_reports_country_scope.dart';
import '/backend/admin_reports_loader.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/backend.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/core/admin_currency.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'admin_reports_hub_model.dart';

/// مركز التقارير الإدارية — سوبر أدمن مع فلترة حسب دولة الوكيل.
class AdminReportsHubWidget extends StatefulWidget {
  const AdminReportsHubWidget({super.key});

  static String routeName = 'AdminReportsHub';
  static String routePath = '/adminReportsHub';

  @override
  State<AdminReportsHubWidget> createState() => _AdminReportsHubWidgetState();
}

class _AdminReportsHubWidgetState extends State<AdminReportsHubWidget> {
  late AdminReportsHubModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<CountriesRecord> _countries = [];
  DocumentReference? _selectedCountry;
  String _countryLabel = 'جميع الدول';
  AdminReportsSummary? _report;
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  Timer? _countryDebounce;
  int _loadGeneration = 0;
  StreamSubscription<int>? _statsInvalidationSub;
  String _currencySymbol = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminReportsHubModel());
    AdminReportsCountryScope.onChanged = _onScopeChangedExternally;
    _report = peekAdminReportsSummary(
      countryRef: _selectedCountry,
      countryLabel: _countryLabel,
    );
    _isInitialLoad = _report == null;
    _loadCountries();
    _reloadReport();
    _refreshCurrencySymbol();
    _statsInvalidationSub =
        AdminStatsCoordinator.instance.stream(StatsDomain.reports).listen((_) {
      if (!mounted) return;
      _reloadReport();
    });
  }

  Future<void> _refreshCurrencySymbol() async {
    String symbol = '';
    if (_selectedCountry != null) {
      try {
        final country = await CountriesRecord.getDocumentOnce(_selectedCountry!);
        symbol = AdminCurrency.symbolFromCountry(country);
      } catch (_) {}
    }
    if (symbol.isEmpty) {
      symbol = await AdminCurrency.resolveSymbolForActiveScope();
    }
    if (!mounted) return;
    if (_currencySymbol != symbol) {
      setState(() => _currencySymbol = symbol);
    }
  }

  @override
  void dispose() {
    _countryDebounce?.cancel();
    _statsInvalidationSub?.cancel();
    if (AdminReportsCountryScope.onChanged == _onScopeChangedExternally) {
      AdminReportsCountryScope.onChanged = null;
    }
    _model.dispose();
    super.dispose();
  }

  void _onScopeChangedExternally() {
    if (!mounted) return;
    if (!AdminReportsCountryScope.isActive && _selectedCountry != null) {
      setState(() {
        _selectedCountry = null;
        _countryLabel = uiTr(context, 'جميع الدول');
      });
      _reloadReport();
    }
  }

  Future<void> _loadCountries() async {
    try {
      final list = await queryCountriesRecordOnce(
        queryBuilder: (q) => q.orderBy('naim'),
        limit: 200,
      );
      if (mounted) setState(() => _countries = list);
    } catch (_) {}
  }

  void _reloadReport() {
    final generation = ++_loadGeneration;
    final cached = peekAdminReportsSummary(
      countryRef: _selectedCountry,
      countryLabel: _countryLabel,
    );

    setState(() {
      _isRefreshing = true;
      if (cached != null && cached.loadComplete) {
        _report = cached;
        _isInitialLoad = false;
      } else if (cached != null) {
        _report = cached;
        _isInitialLoad = false;
      } else {
        _isInitialLoad = _report == null;
      }
    });

    loadAdminReportsSummaryProgressive(
      countryRef: _selectedCountry,
      countryLabel: _countryLabel,
      onPartial: (summary) {
        if (!mounted || generation != _loadGeneration) return;
        setState(() {
          _report = summary;
          _isInitialLoad = false;
        });
      },
      onComplete: (summary) {
        if (!mounted || generation != _loadGeneration) return;
        setState(() {
          _report = summary;
          _isInitialLoad = false;
          _isRefreshing = false;
        });
      },
    ).whenComplete(() {
      if (mounted && generation == _loadGeneration) {
        setState(() => _isRefreshing = false);
      }
    });
  }

  void _onCountryChanged(CountriesRecord? country) {
    _countryDebounce?.cancel();
    setState(() {
      _selectedCountry = country?.reference;
      _countryLabel = country?.naim ?? uiTr(context, 'جميع الدول');
      if (country != null) {
        _currencySymbol = AdminCurrency.symbolFromCountry(country);
      } else {
        _currencySymbol = '';
      }
    });
    _countryDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      AdminReportsCountryScope.syncFrom(
        countryRef: _selectedCountry,
        countryLabel: _countryLabel,
      );
      _reloadReport();
      if (_selectedCountry == null) {
        _refreshCurrencySymbol();
      }
    });
  }

  void _syncCountryScope() {
    AdminReportsCountryScope.syncFrom(
      countryRef: _selectedCountry,
      countryLabel: _countryLabel,
    );
  }

  void _openRoute(String routeName, {Map<String, String>? queryParameters}) {
    _syncCountryScope();
    if (queryParameters != null) {
      context.pushNamed(routeName, queryParameters: queryParameters);
    } else {
      context.pushNamed(routeName);
    }
  }

  void _openLandmarks({required bool partnersOnly}) {
    _syncCountryScope();
    context.pushNamed(
      AdminM3almWidget.routeName,
      queryParameters: {
        'partnersOnly': serializeParam(partnersOnly, ParamType.bool),
      }.withoutNulls,
    );
  }

  void _openAuditLog() {
    _syncCountryScope();
    if (_selectedCountry != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appTr(context, 'scr_audit_all_countries'),
          ),
        ),
      );
    }
    context.pushNamed(AdminAuditLogWidget.routeName);
  }

  String _formatMoney(double value) => formatNumber(
        value,
        formatType: FormatType.decimal,
        decimalType: DecimalType.automatic,
        currency: AdminCurrency.asFormatPrefix(_currencySymbol),
      );

  void _openAgentReport(UserRecord agent) {
    context.pushNamed(
      AdminAgentReportWidget.routeName,
      queryParameters: {
        'iduser': serializeParam(agent.reference, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = AdminSuperAdminGate.guardLayout(
      context: context,
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: appTr(context, 'nav_reports'),
    );
    if (blocked != null) return blocked;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: appTr(context, 'nav_reports'),
        child: AdminPageBody(
          title: appTr(context, 'nav_reports'),
          subtitle: appTr(context, 'scr_reports_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReportsFilterBar(
                countries: _countries,
                selectedCountryRef: _selectedCountry,
                countryLabel: _countryLabel,
                onCountryChanged: _onCountryChanged,
                onRefresh: _reloadReport,
              ),
              if (_isRefreshing) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 16),
              if (_isInitialLoad && _report == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else if (_report != null)
                _ReportsContent(
                  report: _report!,
                  countsLoading: _isRefreshing && !_report!.loadComplete,
                  formatMoney: _formatMoney,
                  onProfits: () => _openRoute(AdminProfitsWidget.routeName),
                  onAudit: _openAuditLog,
                  onLandmarks: () => _openLandmarks(partnersOnly: false),
                  onPartners: () => _openLandmarks(partnersOnly: true),
                  onBookings: () => _openRoute(AdminALLhgZWidget.routeName),
                  onAgents: () => _openRoute(AdminAgentWidget.routeName),
                  onUsers: () => _openRoute(AdminuserWidget.routeName),
                  onSupport: () => _openRoute(AdminSuportWidget.routeName),
                  hasCountryFilter: _selectedCountry != null,
                  openRoute: _openRoute,
                  openLandmarks: _openLandmarks,
                  openAgentReport: _openAgentReport,
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({
    required this.report,
    required this.countsLoading,
    required this.formatMoney,
    required this.hasCountryFilter,
    required this.onProfits,
    required this.onAudit,
    required this.onLandmarks,
    required this.onPartners,
    required this.onBookings,
    required this.onAgents,
    required this.onUsers,
    required this.onSupport,
    required this.openRoute,
    required this.openLandmarks,
    required this.openAgentReport,
  });

  final AdminReportsSummary report;
  final bool countsLoading;
  final String Function(double) formatMoney;
  final bool hasCountryFilter;
  final VoidCallback onProfits;
  final VoidCallback onAudit;
  final VoidCallback onLandmarks;
  final VoidCallback onPartners;
  final VoidCallback onBookings;
  final VoidCallback onAgents;
  final VoidCallback onUsers;
  final VoidCallback onSupport;
  final void Function(String routeName) openRoute;
  final void Function({required bool partnersOnly}) openLandmarks;
  final void Function(UserRecord agent) openAgentReport;

  List<Widget> _statGroups(BuildContext context) {
    final groups = [
      _ReportStatGroup(
        title: appTr(context, 'scr_reports_landmarks'),
        icon: Icons.place_rounded,
        items: [
          _ReportStatItem(
            uiTr(context, 'معالم سياحية'),
            report.landmarks,
            Icons.landscape_rounded,
            const Color(0xFF1F7372),
            onTap: () => openLandmarks(partnersOnly: false),
          ),
          _ReportStatItem(
            uiTr(context, 'شركاء'),
            report.partners,
            Icons.handshake_rounded,
            const Color(0xFF39D2C0),
            onTap: () => openLandmarks(partnersOnly: true),
          ),
        ],
      ),
      _ReportStatGroup(
        title: appTr(context, 'scr_reports_geo'),
        icon: Icons.map_rounded,
        items: [
          _ReportStatItem(
            uiTr(context, 'مناطق'),
            report.regions,
            Icons.filter_hdr_rounded,
            const Color(0xFF3A9E99),
            onTap: () => openRoute(AdminregionWidget.routeName),
          ),
          _ReportStatItem(
            uiTr(context, 'مدن'),
            report.cities,
            Icons.location_city_rounded,
            const Color(0xFF2A8580),
            onTap: () => openRoute(AdminvillWidget.routeName),
          ),
        ],
      ),
      _ReportStatGroup(
        title: appTr(context, 'scr_reports_users'),
        icon: Icons.groups_rounded,
        items: [
          _ReportStatItem(
            uiTr(context, 'مستخدمو التطبيق'),
            report.appUsers,
            Icons.people_rounded,
            const Color(0xFF5C6BC0),
            onTap: () => openRoute(AdminuserWidget.routeName),
          ),
          _ReportStatItem(
            uiTr(context, 'وكلاء'),
            report.agents,
            Icons.real_estate_agent_rounded,
            const Color(0xFF1F9A8A),
            onTap: () => openRoute(AdminAgentWidget.routeName),
          ),
          _ReportStatItem(
            uiTr(context, 'مناديب'),
            report.representatives,
            Icons.directions_car_rounded,
            const Color(0xFF4DB6AC),
            onTap: () => openRoute(AdmindreverWidget.routeName),
          ),
          _ReportStatItem(
            uiTr(context, 'شركات نقل'),
            report.transportCompanies,
            Icons.local_shipping_rounded,
            const Color(0xFF6D4C41),
            onTap: () => openRoute(AdminTransportCompaniesWidget.routeName),
          ),
        ],
      ),
      _ReportStatGroup(
        title: appTr(context, 'scr_reports_bookings'),
        icon: Icons.receipt_long_rounded,
        items: [
          _ReportStatItem(
            uiTr(context, 'حجوزات نشطة'),
            report.activeBookings,
            Icons.event_available_rounded,
            const Color(0xFF3F51B5),
            onTap: () => openRoute(AdminALLhgZWidget.routeName),
          ),
          _ReportStatItem(
            uiTr(context, 'إجمالي الحجوزات'),
            report.totalBookings,
            Icons.bookmark_added_rounded,
            const Color(0xFF5C6BC0),
            onTap: () => openRoute(AdminALLhgZWidget.routeName),
          ),
          _ReportStatItem(
            uiTr(context, 'حجوزات مدفوعة'),
            report.paidBookings,
            Icons.payments_rounded,
            const Color(0xFF2E7D32),
            onTap: onProfits,
          ),
          _ReportStatItem(
            uiTr(context, 'تذاكر الدعم'),
            report.supportTickets,
            Icons.support_agent_rounded,
            const Color(0xFFE64A19),
            onTap: () => openRoute(AdminSuportWidget.routeName),
          ),
        ],
      ),
    ];

    return [
      for (var i = 0; i < groups.length; i++) ...[
        _ReportGroupSection(group: groups[i]),
        if (i < groups.length - 1) const SizedBox(height: 20),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportsScopeBanner(
          countryLabel: report.countryLabel,
          loadedAt: report.loadedAt,
          countsLoading: countsLoading,
        ),
        const SizedBox(height: 16),
        _ReportsSummaryStrip(
          report: report,
          countsLoading: countsLoading,
        ),
        if (report.totalSales > 0) ...[
          const SizedBox(height: 14),
          _SalesHighlightCard(
            totalSales: report.totalSales,
            paidBookings: report.paidBookings,
            formatMoney: formatMoney,
          ),
        ],
        const SizedBox(height: 22),
        ..._statGroups(context),
        const SizedBox(height: 22),
        _QuickAccessSection(
          hasCountryFilter: hasCountryFilter,
          onProfits: onProfits,
          onAudit: onAudit,
          onLandmarks: onLandmarks,
          onPartners: onPartners,
          onBookings: onBookings,
          onAgents: onAgents,
          onUsers: onUsers,
          onSupport: onSupport,
        ),
        const SizedBox(height: 24),
        _AgentsReportSection(
          rows: report.agentRows,
          formatMoney: formatMoney,
          onOpenReport: openAgentReport,
        ),
      ],
    );
  }
}

// ─── Filter ─────────────────────────────────────────────────────────────────

class _ReportsFilterBar extends StatelessWidget {
  const _ReportsFilterBar({
    required this.countries,
    required this.selectedCountryRef,
    required this.countryLabel,
    required this.onCountryChanged,
    required this.onRefresh,
  });

  final List<CountriesRecord> countries;
  final DocumentReference? selectedCountryRef;
  final String countryLabel;
  final ValueChanged<CountriesRecord?> onCountryChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 560;

    CountriesRecord? selected;
    if (selectedCountryRef != null) {
      for (final c in countries) {
        if (c.reference.path == selectedCountryRef!.path) {
          selected = c;
          break;
        }
      }
    }

    final dropdown = DropdownButtonFormField<CountriesRecord?>(
      value: selected,
      isExpanded: true,
      decoration: AdminUi.inputDecoration(
        context,
        label: uiTr(context, 'دولة الوكيل'),
        hint: uiTr(context, 'اختر دولة للفلترة'),
        prefixIcon: Icons.public_rounded,
      ),
      items: [
        DropdownMenuItem<CountriesRecord?>(
          value: null,
          child: Text(uiTr(context, 'جميع الدول')),
        ),
        ...countries.map(
          (c) => DropdownMenuItem(
            value: c,
            child: Text(c.naim, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onCountryChanged,
    );

    final refreshBtn = OutlinedButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded, size: 20),
      label: Text(uiTr(context, 'تحديث')),
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminUi.brandTeal,
        side: BorderSide(color: AdminUi.brandTeal.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

    return AdminContentCard(
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dropdown,
                const SizedBox(height: 10),
                refreshBtn,
              ],
            )
          : Row(
              children: [
                Expanded(child: dropdown),
                const SizedBox(width: 12),
                refreshBtn,
              ],
            ),
    );
  }
}

// ─── Header banner ──────────────────────────────────────────────────────────

class _ReportsScopeBanner extends StatelessWidget {
  const _ReportsScopeBanner({
    required this.countryLabel,
    required this.loadedAt,
    this.countsLoading = false,
  });

  final String countryLabel;
  final DateTime loadedAt;
  final bool countsLoading;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final timeLabel = dateTimeFormat(
      'Hm',
      loadedAt,
      locale: FFLocalizations.of(context).languageCode,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [Color(0xFF1F7372), Color(0xFF185E5D)],
        ),
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AdminUi.brandTeal.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uiTr(context, 'ملخص التقرير'),
                  style: theme.labelMedium.override(
                    fontFamily: theme.labelMediumFamily,
                    color: Colors.white.withValues(alpha: 0.85),
                    useGoogleFonts: !theme.labelMediumIsCustom,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countryLabel,
                  style: theme.titleMedium.override(
                    fontFamily: theme.titleMediumFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    useGoogleFonts: !theme.titleMediumIsCustom,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: Colors.white.withValues(alpha: 0.9),
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary strip ───────────────────────────────────────────────────────────

class _ReportsSummaryStrip extends StatelessWidget {
  const _ReportsSummaryStrip({
    required this.report,
    this.countsLoading = false,
  });

  final AdminReportsSummary report;
  final bool countsLoading;

  @override
  Widget build(BuildContext context) {
    final pills = [
      _SummaryPill(
        icon: Icons.place_rounded,
        label: appTr(context, 'dash_chart_landmarks'),
        value: report.landmarks,
        color: AdminUi.brandTeal,
        loading: countsLoading && !report.loadComplete && report.landmarks == 0,
      ),
      _SummaryPill(
        icon: Icons.event_available_rounded,
        label: uiTr(context, 'حجوزات نشطة'),
        value: report.activeBookings,
        color: const Color(0xFF5C6BC0),
        loading:
            countsLoading && !report.loadComplete && report.activeBookings == 0,
      ),
      _SummaryPill(
        icon: Icons.real_estate_agent_rounded,
        label: uiTr(context, 'وكلاء'),
        value: report.agents,
        color: const Color(0xFF39D2C0),
      ),
      _SummaryPill(
        icon: Icons.groups_rounded,
        label: appTr(context, 'dash_chart_users'),
        value: report.appUsers,
        color: const Color(0xFF2A9D8A),
        loading: countsLoading && !report.loadComplete && report.appUsers == 0,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: AdminUi.cardDecoration(context, accent: AdminUi.brandTeal),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pills
                  .map(
                    (p) => SizedBox(
                      width: (constraints.maxWidth - 8) / 2,
                      child: p,
                    ),
                  )
                  .toList(),
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < pills.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AdminUi.brandTeal.withValues(alpha: 0.12),
                    ),
                  Expanded(child: pills[i]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          if (loading)
            SizedBox(
              width: 32,
              height: 16,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            )
          else
            Text(
              value.toString(),
              style: theme.titleMedium.override(
                fontFamily: theme.titleMediumFamily,
                fontWeight: FontWeight.w800,
                color: color,
                useGoogleFonts: !theme.titleMediumIsCustom,
              ),
            ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sales card ──────────────────────────────────────────────────────────────

class _SalesHighlightCard extends StatelessWidget {
  const _SalesHighlightCard({
    required this.totalSales,
    required this.paidBookings,
    required this.formatMoney,
  });

  final double totalSales;
  final int paidBookings;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uiTr(context, 'إجمالي المبيعات المدفوعة'),
                  style: theme.labelMedium.override(
                    fontFamily: theme.labelMediumFamily,
                    color: const Color(0xFF1B5E20),
                    useGoogleFonts: !theme.labelMediumIsCustom,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(totalSales),
                  style: theme.headlineSmall.override(
                    fontFamily: theme.headlineSmallFamily,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                    useGoogleFonts: !theme.headlineSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '$paidBookings',
                  style: theme.titleMedium.override(
                    fontFamily: theme.titleMediumFamily,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                    useGoogleFonts: !theme.titleMediumIsCustom,
                  ),
                ),
                Text(
                  uiTr(context, 'حجز مدفوع'),
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat groups ─────────────────────────────────────────────────────────────

class _ReportStatGroup {
  const _ReportStatGroup({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_ReportStatItem> items;
}

class _ReportStatItem {
  const _ReportStatItem(
    this.label,
    this.value,
    this.icon,
    this.color, {
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _ReportGroupSection extends StatelessWidget {
  const _ReportGroupSection({required this.group});

  final _ReportStatGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(group.icon, size: 18, color: AdminUi.brandTeal),
            const SizedBox(width: 8),
            Text(
              group.title,
              style: theme.titleSmall.override(
                fontFamily: theme.titleSmallFamily,
                fontWeight: FontWeight.w700,
                color: AdminUi.brandTeal,
                useGoogleFonts: !theme.titleSmallIsCustom,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700
                ? 4
                : constraints.maxWidth >= 420
                    ? 2
                    : 1;
            final gap = 10.0;
            final itemWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: group.items
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _ReportStatCard(item: item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  const _ReportStatCard({required this.item});

  final _ReportStatItem item;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: AdminUi.cardDecoration(context, accent: item.color, elevated: false)
          .copyWith(
        color: theme.secondaryBackground,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value.toString(),
                  style: theme.titleMedium.override(
                    fontFamily: theme.titleMediumFamily,
                    fontWeight: FontWeight.w800,
                    useGoogleFonts: !theme.titleMediumIsCustom,
                  ),
                ),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
          if (item.onTap != null)
            Icon(
              Icons.chevron_left_rounded,
              color: item.color.withValues(alpha: 0.7),
              size: 22,
            ),
        ],
      ),
    );

    if (item.onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        child: content,
      ),
    );
  }
}

// ─── Quick access ────────────────────────────────────────────────────────────

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.hasCountryFilter,
    required this.onProfits,
    required this.onAudit,
    required this.onLandmarks,
    required this.onPartners,
    required this.onBookings,
    required this.onAgents,
    required this.onUsers,
    required this.onSupport,
  });

  final bool hasCountryFilter;
  final VoidCallback onProfits;
  final VoidCallback onAudit;
  final VoidCallback onLandmarks;
  final VoidCallback onPartners;
  final VoidCallback onBookings;
  final VoidCallback onAgents;
  final VoidCallback onUsers;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final links = [
      _QuickLink(uiTr(context, 'المعالم'), Icons.place_rounded, onLandmarks),
      _QuickLink(uiTr(context, 'الشركاء'), Icons.handshake_rounded, onPartners),
      _QuickLink(uiTr(context, 'الحجوزات'), Icons.bookmark_added_rounded, onBookings),
      _QuickLink(uiTr(context, 'الأرباح'), Icons.account_balance_wallet_rounded, onProfits),
      _QuickLink(uiTr(context, 'الوكلاء'), Icons.real_estate_agent_rounded, onAgents),
      _QuickLink(uiTr(context, 'المستخدمون'), Icons.groups_rounded, onUsers),
      _QuickLink(uiTr(context, 'الدعم'), Icons.support_agent_rounded, onSupport),
      _QuickLink(appTr(context, 'nav_audit_log'), Icons.history_rounded, onAudit),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.open_in_new_rounded, size: 18, color: AdminUi.brandTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                uiTr(context, 'وصول سريع'),
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
        if (hasCountryFilter) ...[
          const SizedBox(height: 6),
          Text(
            uiTr(context, 'الأزرار تعرض بيانات الدولة المحددة فقط'),
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: links,
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        child: Ink(
          width: 108,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: AdminUi.cardDecoration(context, accent: AdminUi.brandTeal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AdminUi.brandTeal, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.labelMedium.override(
                  fontFamily: theme.labelMediumFamily,
                  fontWeight: FontWeight.w600,
                  useGoogleFonts: !theme.labelMediumIsCustom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Agents section ──────────────────────────────────────────────────────────

class _AgentsReportSection extends StatelessWidget {
  const _AgentsReportSection({
    required this.rows,
    required this.formatMoney,
    required this.onOpenReport,
  });

  final List<AdminReportAgentRow> rows;
  final String Function(double) formatMoney;
  final void Function(UserRecord) onOpenReport;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isWide = AdminUi.useTableLayout(context);

    return AdminContentCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AdminUi.brandTeal.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: theme.alternate.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.real_estate_agent_rounded,
                    color: AdminUi.brandTeal, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    uiTr(context, 'تقارير الوكلاء'),
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w700,
                      color: AdminUi.brandTeal,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminUi.brandTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${rows.length} ${uiTr(context, 'وكيل')}',
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
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: AdminUi.brandTeal.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    uiTr(context, 'لا يوجد وكلاء في النطاق المحدد'),
                    style: theme.bodyMedium.override(
                      fontFamily: theme.bodyMediumFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.bodyMediumIsCustom,
                    ),
                  ),
                ],
              ),
            )
          else if (isWide)
            ...rows.map(
              (row) => _AgentTableRow(
                row: row,
                formatMoney: formatMoney,
                onOpenReport: onOpenReport,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: rows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AgentCard(
                          row: row,
                          formatMoney: formatMoney,
                          onOpenReport: onOpenReport,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.row,
    required this.formatMoney,
    required this.onOpenReport,
  });

  final AdminReportAgentRow row;
  final String Function(double) formatMoney;
  final void Function(UserRecord) onOpenReport;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final agent = row.agent;
    final name =
        agent.displayName.isNotEmpty ? agent.displayName : agent.email;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.12),
                child: const Icon(Icons.person_rounded, color: AdminUi.brandTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    if (agent.dolhAgent.isNotEmpty)
                      Text(
                        agent.dolhAgent,
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AgentMetricChip(
                icon: Icons.receipt_long_rounded,
                label: '${row.bookings} ${uiTr(context, 'حجز')}',
              ),
              const SizedBox(width: 8),
              _AgentMetricChip(
                icon: Icons.payments_rounded,
                label: formatMoney(row.sales),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onOpenReport(agent),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: Text(uiTr(context, 'عرض التقرير التفصيلي')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminUi.brandTeal,
                side: BorderSide(color: AdminUi.brandTeal.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentTableRow extends StatelessWidget {
  const _AgentTableRow({
    required this.row,
    required this.formatMoney,
    required this.onOpenReport,
  });

  final AdminReportAgentRow row;
  final String Function(double) formatMoney;
  final void Function(UserRecord) onOpenReport;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final agent = row.agent;
    final name =
        agent.displayName.isNotEmpty ? agent.displayName : agent.email;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.55)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, color: AdminUi.brandTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w700,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                )),
                Text(
                  agent.dolhAgent.isNotEmpty ? agent.dolhAgent : '—',
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    color: theme.secondaryText,
                    useGoogleFonts: !theme.labelSmallIsCustom,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appTrFormat(context, 'adm_bookings_count', row.bookings),
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatMoney(row.sales),
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
                useGoogleFonts: !theme.bodySmallIsCustom,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => onOpenReport(agent),
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: Text(uiTr(context, 'تقرير')),
          ),
        ],
      ),
    );
  }
}

class _AgentMetricChip extends StatelessWidget {
  const _AgentMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AdminUi.brandTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              fontWeight: FontWeight.w600,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}
