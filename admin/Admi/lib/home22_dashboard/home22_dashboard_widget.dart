import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_push_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_operational_alerts.dart';
import '/components/admin_ui.dart';
import '/backend/admin_role_service.dart';
import '/components/dashboard_stats_section.dart';
import '/components/profile_photo_image.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/home22_dashboard/dashboard_presentation.dart';
import '/index.dart';
import '/l10n/nav_translations.dart';
import 'package:flutter/material.dart';
import 'home22_dashboard_model.dart';
export 'home22_dashboard_model.dart';

class Home22DashboardWidget extends StatefulWidget {
  const Home22DashboardWidget({super.key});

  static String routeName = 'Home22Dashboard';
  static String routePath = '/home22Dashboard';

  @override
  State<Home22DashboardWidget> createState() => _Home22DashboardWidgetState();
}

class _Home22DashboardWidgetState extends State<Home22DashboardWidget> {
  late Home22DashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _statsKey = GlobalKey<DashboardStatsSectionState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Home22DashboardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      AdminAgentCountryLock.applyToAppState();
      AdminPushService.flushPendingNavigation(context);
      AdminPushService.scheduleTokenSync();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return uiTr(context, 'صباح الخير');
    if (hour < 17) return uiTr(context, 'مساء الخير');
    return uiTr(context, 'مساء النور');
  }

  Future<void> _onRefresh() async {
    await _statsKey.currentState?.refresh();
  }

  void _navigate(String routeName) {
    closeDrawerIfOpen(context);
    context.goNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);
    final displayName = currentUserDisplayName.trim();
    final name = displayName.isNotEmpty
        ? displayName
        : l10n.getText('hrrt489c');
    final photo = currentUserPhoto;

    final role = AdminRoleService.currentRole;
    final statsTitle = role == AdminRole.countryAgent
        ? uiTr(context, 'إحصائيات دولتك')
        : uiTr(context, 'إحصائيات المنصة');
    final statsSubtitle = role == AdminRole.countryAgent
        ? (AdminRoleService.scopedCountryName.isNotEmpty
              ? '${uiTr(context, 'أرقام')} ${AdminRoleService.scopedCountryName} ${uiTr(context, 'فقط')}'
              : uiTr(context, 'أرقام دولتك فقط'))
        : uiTr(context, 'أرقام متزامنة مع صفحات الإدارة');

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
        title: l10n.getText('s8yhig27'),
        child: RefreshIndicator(
          color: AdminUi.brandTeal,
          backgroundColor: theme.secondaryBackground,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: AdminUi.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DashboardHeroBanner(
                  greeting: _greeting(),
                  name: name,
                  photoUrl: photo,
                ),
                const SizedBox(height: 14),
                const AdminOperationalAlerts(),
                const SizedBox(height: 14),
                _DashboardQuickActionsGrid(onNavigate: _navigate),
                const SizedBox(height: 16),
                AdminPageHeader(
                  title: statsTitle,
                  subtitle: statsSubtitle,
                  compact: true,
                  trailing: IconButton(
                    tooltip: uiTr(context, 'تحديث'),
                    onPressed: _onRefresh,
                    icon: Icon(Icons.refresh_rounded, color: theme.primary),
                  ),
                ),
                const SizedBox(height: 6),
                DashboardStatsSection(key: _statsKey),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeroBanner extends StatelessWidget {
  const _DashboardHeroBanner({
    required this.greeting,
    required this.name,
    required this.photoUrl,
  });

  final String greeting;
  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final now = DateTime.now();
    final dateLabel = dateTimeFormat(
      'yMMMd',
      now,
      locale: FFLocalizations.of(context).languageCode,
    );

    return Container(
      decoration: BoxDecoration(
        color: AdminUi.brandTeal,
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AdminUi.brandTeal.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            ProfilePhotoImage(
              photoUrl: photoUrl,
              size: 40,
              borderRadius: BorderRadius.circular(20),
              loadingColor: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting، $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${uiTr(context, 'لوحة تحكم أرى وطن')} · $dateLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: Colors.white.withValues(alpha: 0.88),
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: uiTr(context, 'الإشعارات'),
              onPressed: () {
                if (!AdminRoleService.canAccessRoute(
                  AdminNotificationsWidget.routeName,
                )) {
                  return;
                }
                context.pushNamed(AdminNotificationsWidget.routeName);
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardQuickActionsGrid extends StatelessWidget {
  const _DashboardQuickActionsGrid({required this.onNavigate});

  final void Function(String routeName) onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);

    final catalog = <String, ({IconData icon, String label})>{
      AdminaddMkanWidget.routeName: (
        icon: Icons.add_location_alt_rounded,
        label: appTr(context, 'dash_add_landmark'),
      ),
      AdminAddAgentWidget.routeName: (
        icon: Icons.person_add_alt_1_rounded,
        label: appTr(context, 'dash_add_agent'),
      ),
      AdminALLhgZWidget.routeName: (
        icon: Icons.event_note_rounded,
        label: l10n.getText('kw5c519x'),
      ),
      AdminFinanceHubWidget.routeName: (
        icon: Icons.account_balance_rounded,
        label: navLabel(context, AdminFinanceHubWidget.routeName),
      ),
      AdminAgentFinanceWidget.routeName: (
        icon: Icons.handshake_outlined,
        label: navLabel(context, AdminAgentFinanceWidget.routeName),
      ),
      AdminProfitsWidget.routeName: (
        icon: Icons.account_balance_wallet_rounded,
        label: l10n.getText('nn2n9yup'),
      ),
      AdminTourGuidesWidget.routeName: (
        icon: Icons.tour_rounded,
        label: navLabel(context, AdminTourGuidesWidget.routeName),
      ),
      AdminSuportWidget.routeName: (
        icon: Icons.support_agent_rounded,
        label: l10n.getText('8d66hs1w'),
      ),
    };

    final routes = DashboardPresentation.filterQuickActionRoutes(
      candidates: catalog.keys,
      canAccess: AdminRoleService.canAccessRoute,
    );

    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appTr(context, 'dash_quick_actions'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.titleSmall.override(
            fontFamily: theme.titleSmallFamily,
            fontWeight: FontWeight.w700,
            color: AdminUi.brandTeal,
            useGoogleFonts: !theme.titleSmallIsCustom,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final columns = isWide ? 4 : 2;
            final gap = 8.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final route in routes)
                  SizedBox(
                    width: itemWidth,
                    child: _QuickActionTile(
                      icon: catalog[route]!.icon,
                      label: catalog[route]!.label,
                      onTap: () => onNavigate(route),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(AdminUi.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminUi.radiusSm),
            border: Border.all(
              color: AdminUi.brandTeal.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AdminUi.brandTeal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelMedium.override(
                    fontFamily: theme.labelMediumFamily,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: !theme.labelMediumIsCustom,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
