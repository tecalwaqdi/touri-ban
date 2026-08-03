import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_push_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/backend/admin_role_service.dart';
import '/components/dashboard_stats_section.dart';
import '/components/profile_photo_image.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
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
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  Future<void> _onRefresh() async {
    await _statsKey.currentState?.refresh();
  }

  void _navigate(String routeName) {
    closeDrawerIfOpen(context);
    context.pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);
    final displayName = currentUserDisplayName.trim();
    final name = displayName.isNotEmpty ? displayName : l10n.getText('hrrt489c');
    final photo = currentUserPhoto;

    final role = AdminRoleService.currentRole;
    final statsTitle = role == AdminRole.countryAgent
        ? 'إحصائيات دولتك'
        : 'إحصائيات المنصة';
    final statsSubtitle = role == AdminRole.countryAgent
        ? (AdminRoleService.scopedCountryName.isNotEmpty
            ? 'أرقام ${AdminRoleService.scopedCountryName} فقط'
            : 'أرقام دولتك فقط')
        : 'أرقام متزامنة مع صفحات الإدارة';

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
                  onRefresh: _onRefresh,
                ),
                const SizedBox(height: 18),
                _DashboardQuickActionsGrid(onNavigate: _navigate),
                const SizedBox(height: 22),
                AdminPageHeader(
                  title: statsTitle,
                  subtitle: statsSubtitle,
                  compact: true,
                  trailing: IconButton(
                    tooltip: 'تحديث',
                    onPressed: _onRefresh,
                    icon: Icon(Icons.refresh_rounded, color: theme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                DashboardStatsSection(key: _statsKey),
                const SizedBox(height: 24),
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
    required this.onRefresh,
  });

  final String greeting;
  final String name;
  final String photoUrl;
  final Future<void> Function() onRefresh;

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
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AdminUi.brandTeal, Color(0xFF185E5D), Color(0xFF123F3E)],
        ),
        borderRadius: BorderRadius.circular(AdminUi.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AdminUi.brandTeal.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -20,
            child: Icon(
              Icons.landscape_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 2,
                    ),
                  ),
                  child: ProfilePhotoImage(
                    photoUrl: photoUrl,
                    size: 54,
                    borderRadius: BorderRadius.circular(27),
                    loadingColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting، $name',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleMedium.override(
                          fontFamily: theme.titleMediumFamily,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          useGoogleFonts: !theme.titleMediumIsCustom,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'لوحة تحكم أرى وطن',
                        style: theme.bodySmall.override(
                          fontFamily: theme.bodySmallFamily,
                          color: Colors.white.withValues(alpha: 0.88),
                          useGoogleFonts: !theme.bodySmallIsCustom,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
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
                ),
                IconButton(
                  tooltip: 'تحديث البيانات',
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

class _DashboardQuickActionsGrid extends StatelessWidget {
  const _DashboardQuickActionsGrid({required this.onNavigate});

  final void Function(String routeName) onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);

    final actions = <({
      String route,
      IconData icon,
      String label,
      List<Color> colors,
    })>[
      (
        route: AdminaddMkanWidget.routeName,
        icon: Icons.add_location_alt_rounded,
        label: appTr(context, 'dash_add_landmark'),
        colors: const [Color(0xFF1F7372), Color(0xFF2A9D8A)],
      ),
      (
        route: AdminAddAgentWidget.routeName,
        icon: Icons.person_add_alt_1_rounded,
        label: appTr(context, 'dash_add_agent'),
        colors: const [Color(0xFF39D2C0), Color(0xFF1F9A8A)],
      ),
      (
        route: AdminALLhgZWidget.routeName,
        icon: Icons.event_note_rounded,
        label: l10n.getText('kw5c519x'),
        colors: const [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
      ),
      (
        route: AdminProfitsWidget.routeName,
        icon: Icons.account_balance_wallet_rounded,
        label: l10n.getText('nn2n9yup'),
        colors: const [Color(0xFF1F7372), Color(0xFF39D2C0)],
      ),
      (
        route: AdminSuportWidget.routeName,
        icon: Icons.support_agent_rounded,
        label: l10n.getText('8d66hs1w'),
        colors: const [Color(0xFFFF8A65), Color(0xFFE64A19)],
      ),
    ].where((a) => AdminRoleService.canAccessRoute(a.route)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appTr(context, 'dash_quick_actions'),
          style: theme.titleSmall.override(
            fontFamily: theme.titleSmallFamily,
            fontWeight: FontWeight.w700,
            color: AdminUi.brandTeal,
            useGoogleFonts: !theme.titleSmallIsCustom,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final columns = isWide ? 3 : 2;
            final gap = 12.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: itemWidth,
                      child: _QuickActionTile(
                        icon: action.icon,
                        label: action.label,
                        colors: action.colors,
                        onTap: () => onNavigate(action.route),
                      ),
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

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 78),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors.first.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
