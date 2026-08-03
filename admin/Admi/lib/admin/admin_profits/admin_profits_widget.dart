import 'dart:async';

import '/backend/admin_stats_coordinator.dart';
import '/backend/profits_stats_loader.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'admin_profits_model.dart';
export 'admin_profits_model.dart';

class AdminProfitsWidget extends StatefulWidget {
  const AdminProfitsWidget({super.key});

  static String routeName = 'AdminProfits';
  static String routePath = '/adminProfits';

  @override
  State<AdminProfitsWidget> createState() => _AdminProfitsWidgetState();
}

class _AdminProfitsWidgetState extends State<AdminProfitsWidget>
    with SingleTickerProviderStateMixin {
  late AdminProfitsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  ProfitsPeriod _period = ProfitsPeriod.month;
  ProfitsSummary? _cache;
  late Future<ProfitsSummary> _statsFuture;
  int? _selectedBarIndex;
  late AnimationController _pulseController;
  StreamSubscription<int>? _statsInvalidationSub;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminProfitsModel());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _statsFuture = _loadStats(showStaleImmediately: true);
    _statsInvalidationSub =
        AdminStatsCoordinator.instance.stream(StatsDomain.profits).listen((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  @override
  void dispose() {
    _statsInvalidationSub?.cancel();
    _pulseController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<ProfitsSummary> _loadStats({bool showStaleImmediately = false}) async {
    final cached = _cache;
    if (cached != null && cached.period == _period && !cached.isExpired) {
      return cached;
    }

    if (showStaleImmediately && cached != null && cached.period == _period) {
      // ignore: unawaited_futures
      _fetchAndCacheStats().then((fresh) {
        if (mounted) {
          setState(() => _statsFuture = Future.value(fresh));
        }
      });
      return cached;
    }

    return _fetchAndCacheStats();
  }

  Future<ProfitsSummary> _fetchAndCacheStats() async {
    final fresh = await loadProfitsStats(period: _period);
    _cache = fresh;
    return fresh;
  }

  Future<void> _refresh() async {
    _cache = null;
    setState(() {
      _selectedBarIndex = null;
      _statsFuture = _fetchAndCacheStats();
    });
    await _statsFuture;
  }

  void _setPeriod(ProfitsPeriod period) {
    if (_period == period) {
      return;
    }
    setState(() {
      _period = period;
      _selectedBarIndex = null;
      _statsFuture = _loadStats(showStaleImmediately: true);
    });
  }

  String _formatMoney(double value) => formatNumber(
        value,
        formatType: FormatType.decimal,
        decimalType: DecimalType.automatic,
        currency: 'ر.س ',
      );

  void _openOrder(ProfitsOrderRow row) {
    context.pushNamed(
      AdminBookingDetailsWidget.routeName,
      queryParameters: {
        'idbokeng': serializeParam(
          row.order.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final l10n = FFLocalizations.of(context);

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
        title: l10n.getText('nn2n9yup'),
        child: RefreshIndicator(
          color: AdminUi.brandTeal,
          backgroundColor: theme.secondaryBackground,
          onRefresh: _refresh,
          child: FutureBuilder<ProfitsSummary>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AdminUi.pagePadding(context),
                  children: [
                    AdminContentCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 48,
                            color: AdminUi.brandTeal.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'تعذر تحميل بيانات الأرباح',
                            style: theme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(appTr(context, 'adm_retry')),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AdminUi.pagePadding(context),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: SpinKitThreeBounce(
                        color: AdminUi.brandTeal,
                        size: 42,
                      ),
                    ),
                  ],
                );
              }

              final stats = snapshot.data!;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: AdminUi.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfitsHeroBanner(
                      appProfit: stats.appProfit,
                      totalSales: stats.totalSales,
                      orderCount: stats.orderCount,
                      periodLabel: _period.arabicLabel,
                      formatMoney: _formatMoney,
                      pulse: _pulseController,
                      onRefresh: _refresh,
                    ),
                    const SizedBox(height: 18),
                    _PeriodFilterChips(
                      selected: _period,
                      onSelected: _setPeriod,
                    ),
                    const SizedBox(height: 18),
                    _ProfitsStatGrid(
                      stats: stats,
                      formatMoney: _formatMoney,
                      onBookingsTap: () =>
                          context.pushNamed(AdminALLhgZWidget.routeName),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 820;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _MonthlyBarChartCard(
                                  points: stats.monthlyTrend,
                                  selectedIndex: _selectedBarIndex,
                                  formatMoney: _formatMoney,
                                  onBarTap: (index) => setState(
                                    () => _selectedBarIndex =
                                        _selectedBarIndex == index
                                            ? null
                                            : index,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ProfitBreakdownCard(
                                  stats: stats,
                                  formatMoney: _formatMoney,
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _MonthlyBarChartCard(
                              points: stats.monthlyTrend,
                              selectedIndex: _selectedBarIndex,
                              formatMoney: _formatMoney,
                              onBarTap: (index) => setState(
                                () => _selectedBarIndex =
                                    _selectedBarIndex == index ? null : index,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ProfitBreakdownCard(
                              stats: stats,
                              formatMoney: _formatMoney,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _RecentTransactionsCard(
                      rows: stats.recentOrders,
                      formatMoney: _formatMoney,
                      onTap: _openOrder,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfitsHeroBanner extends StatelessWidget {
  const _ProfitsHeroBanner({
    required this.appProfit,
    required this.totalSales,
    required this.orderCount,
    required this.periodLabel,
    required this.formatMoney,
    required this.pulse,
    required this.onRefresh,
  });

  final double appProfit;
  final double totalSales;
  final int orderCount;
  final String periodLabel;
  final String Function(double) formatMoney;
  final AnimationController pulse;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color(0xFF0F5C5B),
            AdminUi.brandTeal,
            Color(0xFF39D2C0),
          ],
        ),
        borderRadius: BorderRadius.circular(AdminUi.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AdminUi.brandTeal.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + pulse.value * 0.08,
                  child: child,
                );
              },
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 130,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'حساب الأرباح · $periodLabel',
                              style: theme.labelSmall.override(
                                fontFamily: theme.labelSmallFamily,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                useGoogleFonts: !theme.labelSmallIsCustom,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'صافي أرباح التطبيق',
                        style: theme.bodyMedium.override(
                          fontFamily: theme.bodyMediumFamily,
                          color: Colors.white.withValues(alpha: 0.88),
                          useGoogleFonts: !theme.bodyMediumIsCustom,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: appProfit),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Text(
                              formatMoney(value),
                              style: theme.headlineMedium.override(
                                fontFamily: theme.headlineMediumFamily,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                useGoogleFonts: !theme.headlineMediumIsCustom,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _HeroChip(
                            icon: Icons.payments_rounded,
                            label: 'مبيعات ${formatMoney(totalSales)}',
                          ),
                          _HeroChip(
                            icon: Icons.receipt_long_rounded,
                            label: '$orderCount حجز',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'تحديث',
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.sync_rounded,
                    color: Colors.white.withValues(alpha: 0.92),
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodFilterChips extends StatelessWidget {
  const _PeriodFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final ProfitsPeriod selected;
  final ValueChanged<ProfitsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ProfitsPeriod.values.map((period) {
          final isSelected = period == selected;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(period),
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [
                                AdminUi.brandTeal,
                                Color(0xFF2A9D8A),
                              ],
                            )
                          : null,
                      color: isSelected ? null : theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : theme.alternate.withValues(alpha: 0.9),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AdminUi.brandTeal.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      period.arabicLabel,
                      style: theme.labelLarge.override(
                        fontFamily: theme.labelLargeFamily,
                        color: isSelected ? Colors.white : theme.primaryText,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        useGoogleFonts: !theme.labelLargeIsCustom,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProfitsStatGrid extends StatelessWidget {
  const _ProfitsStatGrid({
    required this.stats,
    required this.formatMoney,
    required this.onBookingsTap,
  });

  final ProfitsSummary stats;
  final String Function(double) formatMoney;
  final VoidCallback onBookingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final items = [
      (
        title: uiTr(context, 'إجمالي المبيعات'),
        value: formatMoney(stats.totalSales),
        icon: Icons.storefront_rounded,
        color: const Color(0xFF1F7372),
        onTap: null as VoidCallback?,
      ),
      (
        title: uiTr(context, 'رسوم التطبيق'),
        value: formatMoney(stats.appProfit),
        icon: Icons.phone_iphone_rounded,
        color: const Color(0xFF39D2C0),
        onTap: null,
      ),
      (
        title: uiTr(context, 'الضريبة'),
        value: formatMoney(stats.vat),
        icon: Icons.percent_rounded,
        color: const Color(0xFF7E57C2),
        onTap: null,
      ),
      (
        title: uiTr(context, 'عمولات المناديب'),
        value: formatMoney(stats.repCommission + stats.deliveryFees),
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFFFF8A65),
        onTap: null,
      ),
      (
        title: uiTr(context, 'حجوزات مدفوعة'),
        value: '${stats.paidCount}',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF43A047),
        onTap: onBookingsTap,
      ),
      (
        title: uiTr(context, 'قيد الانتظار'),
        value: '${stats.pendingCount}',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFFFB300),
        onTap: onBookingsTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 700 ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - (crossCount - 1) * 12) / crossCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _ProfitMetricTile(
                title: item.title,
                value: item.value,
                icon: item.icon,
                color: item.color,
                onTap: item.onTap,
                theme: theme,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProfitMetricTile extends StatefulWidget {
  const _ProfitMetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final FlutterFlowTheme theme;
  final VoidCallback? onTap;

  @override
  State<_ProfitMetricTile> createState() => _ProfitMetricTileState();
}

class _ProfitMetricTileState extends State<_ProfitMetricTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AdminUi.cardDecoration(context, accent: widget.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const Spacer(),
                if (widget.onTap != null)
                  Icon(
                    Icons.chevron_left_rounded,
                    color: widget.theme.secondaryText,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.theme.bodySmall.override(
                fontFamily: widget.theme.bodySmallFamily,
                color: widget.theme.secondaryText,
                useGoogleFonts: !widget.theme.bodySmallIsCustom,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.theme.titleMedium.override(
                fontFamily: widget.theme.titleMediumFamily,
                fontWeight: FontWeight.w800,
                color: widget.theme.primaryText,
                useGoogleFonts: !widget.theme.titleMediumIsCustom,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        child: content,
      ),
    );
  }
}

class _MonthlyBarChartCard extends StatelessWidget {
  const _MonthlyBarChartCard({
    required this.points,
    required this.selectedIndex,
    required this.formatMoney,
    required this.onBarTap,
  });

  final List<ProfitsMonthlyPoint> points;
  final int? selectedIndex;
  final String Function(double) formatMoney;
  final ValueChanged<int> onBarTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final maxProfit = points
        .map((p) => p.appProfit)
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: AdminUi.brandTeal,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'اتجاه الأرباح — آخر 6 أشهر',
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على العمود لعرض التفاصيل',
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.bodySmallIsCustom,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(points.length, (index) {
                final point = points[index];
                final ratio = point.appProfit / maxProfit;
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: index == 0 ? 0 : 4,
                      end: index == points.length - 1 ? 0 : 4,
                    ),
                    child: GestureDetector(
                      onTap: () => onBarTap(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AdminUi.brandTeal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                formatMoney(point.appProfit),
                                style: theme.labelSmall.override(
                                  fontFamily: theme.labelSmallFamily,
                                  color: Colors.white,
                                  fontSize: 10,
                                  useGoogleFonts: !theme.labelSmallIsCustom,
                                ),
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 24 + ratio * 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isSelected
                                    ? [
                                        AdminUi.brandTeal,
                                        AdminUi.brandMint,
                                      ]
                                    : [
                                        AdminUi.brandTeal.withValues(alpha: 0.55),
                                        AdminUi.brandMint.withValues(alpha: 0.35),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            AdminUi.brandTeal.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            point.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.labelSmall.override(
                              fontFamily: theme.labelSmallFamily,
                              color: isSelected
                                  ? AdminUi.brandTeal
                                  : theme.secondaryText,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 10,
                              useGoogleFonts: !theme.labelSmallIsCustom,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitBreakdownCard extends StatelessWidget {
  const _ProfitBreakdownCard({
    required this.stats,
    required this.formatMoney,
  });

  final ProfitsSummary stats;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final segments = [
      _BreakdownSegment(
        label: uiTr(context, 'رسوم التطبيق'),
        value: stats.appProfit,
        color: AdminUi.brandTeal,
      ),
      _BreakdownSegment(
        label: uiTr(context, 'الضريبة'),
        value: stats.vat,
        color: const Color(0xFF7E57C2),
      ),
      _BreakdownSegment(
        label: uiTr(context, 'عمولة المناديب'),
        value: stats.repCommission,
        color: const Color(0xFFFF8A65),
      ),
      _BreakdownSegment(
        label: uiTr(context, 'رسوم التوصيل'),
        value: stats.deliveryFees,
        color: const Color(0xFFFFB300),
      ),
    ];
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);

    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع الإيرادات',
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w700,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  segments: segments,
                  total: total > 0 ? total : 1,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الإجمالي',
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                      Text(
                        formatMoney(total),
                        style: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          fontWeight: FontWeight.w800,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...segments.map((segment) {
            final pct = total > 0 ? (segment.value / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BreakdownRow(
                label: segment.label,
                value: formatMoney(segment.value),
                percent: pct,
                color: segment.color,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BreakdownSegment {
  const _BreakdownSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.segments, required this.total});

  final List<_BreakdownSegment> segments;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const stroke = 22.0;
    var startAngle = -3.14159 / 2;

    for (final segment in segments) {
      if (segment.value <= 0) {
        continue;
      }
      final sweep = (segment.value / total) * 3.14159 * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.segments != segments;
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmallFamily,
                  useGoogleFonts: !theme.bodySmallIsCustom,
                ),
              ),
            ),
            Text(
              value,
              style: theme.labelMedium.override(
                fontFamily: theme.labelMediumFamily,
                fontWeight: FontWeight.w700,
                useGoogleFonts: !theme.labelMediumIsCustom,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({
    required this.rows,
    required this.formatMoney,
    required this.onTap,
  });

  final List<ProfitsOrderRow> rows;
  final String Function(double) formatMoney;
  final ValueChanged<ProfitsOrderRow> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: uiTr(context, 'آخر العمليات'),
            subtitle: uiTr(context, 'اضغط على أي عملية لعرض تفاصيل الحجز'),
            compact: true,
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 42,
                      color: theme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد عمليات في هذه الفترة',
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodyMediumIsCustom,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...rows.map((row) {
              final order = row.order;
              final title = order.naimUserText.isNotEmpty
                  ? order.naimUserText
                  : (order.iDorder.isNotEmpty
                      ? 'حجز #${order.iDorder}'
                      : 'حجز');
              final date = order.dataOrder;
              final dateLabel = date != null
                  ? dateTimeFormat(
                      'yMMMd · HH:mm',
                      date,
                      locale: FFLocalizations.of(context).languageCode,
                    )
                  : '—';

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(row),
                  borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AdminUi.brandTeal,
                                Color(0xFF2A9D8A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.paid_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.titleSmall.override(
                                  fontFamily: theme.titleSmallFamily,
                                  fontWeight: FontWeight.w600,
                                  useGoogleFonts: !theme.titleSmallIsCustom,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateLabel,
                                style: theme.bodySmall.override(
                                  fontFamily: theme.bodySmallFamily,
                                  color: theme.secondaryText,
                                  useGoogleFonts: !theme.bodySmallIsCustom,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(order.total),
                              style: theme.labelLarge.override(
                                fontFamily: theme.labelLargeFamily,
                                fontWeight: FontWeight.w800,
                                color: AdminUi.brandTeal,
                                useGoogleFonts: !theme.labelLargeIsCustom,
                              ),
                            ),
                            Text(
                              'ربح ${formatMoney(order.totalApp.toDouble())}',
                              style: theme.labelSmall.override(
                                fontFamily: theme.labelSmallFamily,
                                color: theme.secondaryText,
                                useGoogleFonts: !theme.labelSmallIsCustom,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_left_rounded,
                          color: theme.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
