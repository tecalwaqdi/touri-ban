import 'dart:async';

import '/backend/admin_agent_stats_loader.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/backend.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/components/profile_photo_image.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'admin_agent_report_model.dart';
export 'admin_agent_report_model.dart';

/// Agent Report
///
/// This report provides a comprehensive overview of an agentâ€™s profile,
/// including personal information, booking statistics, and sales data.
///
/// It is designed to help administrators assess agent performance and manage
/// their activities effectively.
///
/// 1. Agent Information:
///
/// Name: The full name of the agent.
/// Address: The physical address of the agent.
/// Phone Number: The landline number (if available) for the agent.
/// Mobile Number: The agentâ€™s mobile contact number.
/// Email Address: The agentâ€™s email for communication.
/// Registration Date: The date the agent was registered in the system.
/// Expiration Date: The date the agentâ€™s registration or contract is set to
/// expire.
/// Country: The country in which the agent is operating.
/// 2. Booking and Sales Overview:
///
/// Number of Bookings: The total number of bookings the agent has processed.
/// Total Bookings: A sum of all bookings made by the agent, including both
/// completed and pending ones.
/// Total Sales: The total sales generated from all the bookings made by the
/// agent.
class AdminAgentReportWidget extends StatefulWidget {
  const AdminAgentReportWidget({
    super.key,
    required this.iduser,
  });

  final DocumentReference? iduser;

  static String routeName = 'AdminAgentReport';
  static String routePath = '/adminAgentReport';

  @override
  State<AdminAgentReportWidget> createState() => _AdminAgentReportWidgetState();
}

class _AdminAgentReportWidgetState extends State<AdminAgentReportWidget> {
  late AdminAgentReportModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAgentReportModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminSuperAdminGate.isAllowed) {
      return AdminSuperAdminGate.deniedEditScaffold(
        context: context,
        title: appTr(context, 'scr_agent_report'),
      );
    }

    if (widget.iduser == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          leading: FlutterFlowIconButton(
            buttonSize: 48,
            icon: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).info,
            ),
            onPressed: () => context.safePop(),
          ),
          title: Text(uiTr(context, 'تقرير الوكيل')),
        ),
        body: Center(child: Text(uiTr(context, 'تعذر تحميل بيانات الوكيل'))),
      );
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(widget.iduser!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 55.0,
                height: 55.0,
                child: SpinKitThreeBounce(
                  color: FlutterFlowTheme.of(context).primary,
                  size: 55.0,
                ),
              ),
            ),
          );
        }

        final adminAgentReportUserRecord = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: AdminUi.brandTeal,
              automaticallyImplyLeading: false,
              leading: FlutterFlowIconButton(
                buttonSize: 48.0,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24.0,
                ),
                onPressed: () => context.safePop(),
              ),
              title: Text(
                'تقرير الوكيل',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      fontFamily:
                          FlutterFlowTheme.of(context).titleLargeFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      useGoogleFonts:
                          !FlutterFlowTheme.of(context).titleLargeIsCustom,
                    ),
              ),
              centerTitle: false,
              elevation: 0.0,
            ),
            body: AdminSafeScrollBody(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AgentReportHero(agent: adminAgentReportUserRecord),
                  const SizedBox(height: 16),
                  _AgentDatesCard(agent: adminAgentReportUserRecord),
                  const SizedBox(height: 16),
                  _AgentContactCard(agent: adminAgentReportUserRecord),
                  const SizedBox(height: 16),
                    _AgentFirestoreStatsSection(
                      agent: adminAgentReportUserRecord,
                    ),
                ],
                ),
            ),
          ),
        );
      },
    );
  }
}

class _AgentFirestoreStatsSection extends StatefulWidget {
  const _AgentFirestoreStatsSection({required this.agent});

  final UserRecord agent;

  @override
  State<_AgentFirestoreStatsSection> createState() =>
      _AgentFirestoreStatsSectionState();
}

class _AgentFirestoreStatsSectionState
    extends State<_AgentFirestoreStatsSection> {
  late Future<AgentReportStats> _statsFuture;
  StreamSubscription<int>? _statsInvalidationSub;

  @override
  void initState() {
    super.initState();
    _statsFuture = loadAgentReportStats(widget.agent);
    _statsInvalidationSub =
        AdminStatsCoordinator.instance.stream(StatsDomain.agent).listen((_) {
      if (!mounted) return;
      setState(() {
        _statsFuture = loadAgentReportStats(widget.agent);
      });
    });
  }

  @override
  void dispose() {
    _statsInvalidationSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = loadAgentReportStats(widget.agent);
    });
    await _statsFuture;
  }

  String _money(double value) => formatNumber(
        value,
        formatType: FormatType.decimal,
        decimalType: DecimalType.automatic,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);

    return FutureBuilder<AgentReportStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? AgentReportStats.empty;

        return Column(
          children: [
            AdminContentCard(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                  children: [
                      const Icon(Icons.bar_chart_rounded,
                          color: AdminUi.brandTeal, size: 22),
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                      l10n.getText('yw6zaf93'),
                        style: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          fontWeight: FontWeight.w700,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: uiTr(context, 'تحديث'),
                      onPressed: _refreshStats,
                      icon: const Icon(Icons.refresh_rounded,
                          color: AdminUi.brandTeal),
                    ),
                    ],
                    ),
                    const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 520 ? 3 : 1;
                      final gap = 10.0;
                      final w = cols == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap * 2) / 3;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                      children: [
                          SizedBox(
                            width: w,
                            child: _StatBox(
                          label: l10n.getText('63q98jre'),
                          value: '${stats.totalBookings}',
                              color: const Color(0xFF5C6BC0),
                            ),
                        ),
                          SizedBox(
                            width: w,
                            child: _StatBox(
                          label: l10n.getText('ty7kis1x'),
                          value: '${stats.activeBookings}',
                              color: AdminUi.brandTeal,
                            ),
                        ),
                          SizedBox(
                            width: w,
                            child: _StatBox(
                          label: l10n.getText('0lm704xz'),
                          value: '${stats.completionRate.toStringAsFixed(0)}%',
                              color: const Color(0xFF39D2C0),
                            ),
                        ),
                      ],
                      );
                    },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                      color: AdminUi.brandTeal.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                      border: Border.all(
                        color: AdminUi.brandTeal.withValues(alpha: 0.15),
                      ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                        _MoneyRow(
                          label: l10n.getText('uw5ozgrs'),
                          value: _money(stats.totalSales),
                          valueColor: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: theme.alternate.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                        _MoneyRow(
                          label: l10n.getText('c4tprvvk'),
                          value: _money(stats.commissionEarned),
                          valueColor: AdminUi.brandTeal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            AdminContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: AdminUi.brandTeal, size: 22),
                      const SizedBox(width: 8),
                    Text(
                      l10n.getText('c6f8vf28'),
                        style: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          fontWeight: FontWeight.w700,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
                      ),
                    ],
                    ),
                    const SizedBox(height: 16),
                    if (stats.recentOrders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 44,
                            color: AdminUi.brandTeal.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 10),
                      Text(
                        'لا توجد حجوزات في دولة هذا الوكيل',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          fontFamily: theme.bodyMediumFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.bodyMediumIsCustom,
                            ),
                          ),
                        ],
                        ),
                      )
                    else
                      ...stats.recentOrders.map(
                        (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            decoration: BoxDecoration(
                            color: theme.primaryBackground,
                            borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                            border: Border.all(
                              color: theme.alternate.withValues(alpha: 0.6),
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AdminUi.brandTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_rounded,
                                  color: AdminUi.brandTeal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orderDisplayTitle(order),
                                        style: theme.bodyMedium.override(
                                          fontFamily: theme.bodyMediumFamily,
                                          fontWeight: FontWeight.w600,
                                          useGoogleFonts:
                                              !theme.bodyMediumIsCustom,
                                        ),
                                      ),
                                      if (order.dataOrder != null)
                                        Text(
                                          dateTimeFormat(
                                            'yMMMd',
                                            order.dataOrder,
                                            locale: l10n.languageCode,
                                          ),
                                        style: theme.labelSmall.override(
                                          fontFamily: theme.labelSmallFamily,
                                            color: theme.secondaryText,
                                            useGoogleFonts:
                                              !theme.labelSmallIsCustom,
                                        ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _money(order.total),
                                style: theme.titleSmall.override(
                                  fontFamily: theme.titleSmallFamily,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                  useGoogleFonts: !theme.titleSmallIsCustom,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                      ),
                  ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: theme.headlineMedium.override(
              fontFamily: theme.headlineMediumFamily,
              fontWeight: FontWeight.w800,
              color: color,
              useGoogleFonts: !theme.headlineMediumIsCustom,
            ),
          ),
          const SizedBox(height: 4),
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

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: theme.bodyMedium)),
        Text(
          value,
          style: theme.titleMedium.override(
            fontFamily: theme.titleMediumFamily,
            fontWeight: FontWeight.w800,
            color: valueColor,
            useGoogleFonts: !theme.titleMediumIsCustom,
          ),
        ),
      ],
    );
  }
}

class _AgentReportHero extends StatelessWidget {
  const _AgentReportHero({required this.agent});

  final UserRecord agent;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name = agent.displayName.isNotEmpty ? agent.displayName : agent.email;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [Color(0xFF1F7372), Color(0xFF185E5D)],
        ),
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: ProfilePhotoImage(
                photoUrl: agent.photoUrl,
                size: 68,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.titleLarge.override(
                    fontFamily: theme.titleLargeFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    useGoogleFonts: !theme.titleLargeIsCustom,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    agent.dolhAgent.isNotEmpty
                        ? 'وكيل — ${agent.dolhAgent}'
                        : 'وكيل دولة',
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: Colors.white.withValues(alpha: 0.95),
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
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

class _AgentDatesCard extends StatelessWidget {
  const _AgentDatesCard({required this.agent});

  final UserRecord agent;

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);

    return AdminContentCard(
      title: uiTr(context, 'تواريخ العقد'),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.event_available_rounded,
            label: l10n.getText('5hx3p2d6'),
            value: agent.hasAgentDateReg()
                ? dateTimeFormat(
                    'yMMMd',
                    agent.agentDateReg,
                    locale: l10n.languageCode,
                  )
                : '—',
            valueColor: AdminUi.brandTeal,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.event_busy_rounded,
            label: l10n.getText('3cnzqcjv'),
            value: agent.hasAgentDateEnd()
                ? dateTimeFormat(
                    'yMMMd',
                    agent.agentDateEnd,
                    locale: l10n.languageCode,
                  )
                : '—',
            valueColor: FlutterFlowTheme.of(context).error,
          ),
        ],
      ),
    );
  }
}

class _AgentContactCard extends StatelessWidget {
  const _AgentContactCard({required this.agent});

  final UserRecord agent;

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final phone = agent.phoneNumber.isNotEmpty
        ? agent.phoneNumber
        : agent.phoneN.toString();
    final address = agent.address.isNotEmpty
        ? agent.address.first.address
        : agent.dolhAgent;

    return AdminContentCard(
      title: l10n.getText('sg44q287'),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_rounded,
            label: uiTr(context, 'الهاتف'),
            value: phone.isNotEmpty ? phone : '—',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.email_rounded,
            label: uiTr(context, 'البريد الإلكتروني'),
            value: agent.email.isNotEmpty ? agent.email : '—',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: uiTr(context, 'العنوان'),
            value: address.isNotEmpty ? address : '—',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.flag_rounded,
            label: uiTr(context, 'الدولة'),
            value: agent.dolhAgent.isNotEmpty ? agent.dolhAgent : '—',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AdminUi.brandTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AdminUi.brandTeal),
        ),
        const SizedBox(width: 12),
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
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
