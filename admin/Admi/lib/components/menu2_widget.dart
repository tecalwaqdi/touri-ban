import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_perf_trace.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_theme_toggle.dart';
import '/components/admin_ui.dart';
import '/core/admin_shell_rules.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/nav_translations.dart';
import '/index.dart';
import '/components/profile_photo_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'menu2_model.dart';
export 'menu2_model.dart';

/// قائمة اللوحة — مجموعات Enterprise
class Menu2Widget extends StatefulWidget {
  const Menu2Widget({super.key});

  @override
  State<Menu2Widget> createState() => _Menu2WidgetState();
}

class _Menu2WidgetState extends State<Menu2Widget> {
  late Menu2Model _model;

  /// PERF-P1: stable badge streams — recreate only when role needs badges.
  Stream<QuerySnapshot<Map<String, dynamic>>>? _pendingPaymentsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _draftSettlementsStream;
  bool _badgeStreamsAttached = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _pendingPaymentsStream = null;
    _draftSettlementsStream = null;
    _badgeStreamsAttached = false;
    _model.maybeDispose();

    super.dispose();
  }

  void _ensureFinanceBadgeStreams() {
    if (!_showFinanceHubAttentionBadges) {
      _pendingPaymentsStream = null;
      _draftSettlementsStream = null;
      _badgeStreamsAttached = false;
      return;
    }
    if (_badgeStreamsAttached &&
        _pendingPaymentsStream != null &&
        _draftSettlementsStream != null) {
      return;
    }
    AdminPerfTrace.menuBadgeListenerBuild();
    _pendingPaymentsStream = FirebaseFirestore.instance
        .collection('financial_settlement_payments')
        .where('status', isEqualTo: 'pending')
        .limit(50)
        .snapshots();
    _draftSettlementsStream = FirebaseFirestore.instance
        .collection('financial_settlements')
        .where('status', isEqualTo: 'draft')
        .limit(50)
        .snapshots();
    _badgeStreamsAttached = true;
  }

  void _navigate(BuildContext context, String routeName) {
    closeDrawerIfOpen(context);
    // Replace stack (don't push) so prior pages/listeners are disposed.
    if (routeName == AdminM3almWidget.routeName) {
      context.goNamed(
        AdminM3almWidget.routeName,
        queryParameters: {
          'partnersOnly': serializeParam(false, ParamType.bool),
        }.withoutNulls,
      );
      return;
    }
    context.goNamed(routeName);
  }

  bool _isActive(BuildContext context, String routeName) {
    return adminSidebarRouteIsActive(
      location: adminCurrentLocation(context),
      routeName: routeName,
      pathByName: _routePathByName,
    );
  }

  /// Exact `routePath` values for every sidebar destination (longest-path wins).
  static const _routePathByName = <String, String>{
    // Operations
    'Home22Dashboard': '/home22Dashboard',
    'AdminALLhgZ': '/adminALLhgZ',
    'Adminuser': '/adminuser',
    'Admindrever': '/drever',
    'AdminSuport': '/adminSuport',
    // Reviews
    'AdminNotifications': '/adminNotifications',
    'AdminDriverExpiryQueue': '/driverDocExpiry',
    // Catalog
    'Admintypecar': '/admintypecar',
    'AdminDol': '/adminDol',
    'Adminregion': '/adminregion',
    'Adminvill': '/adminvill',
    'AdminM3alm': '/adminM3alm',
    // Partners
    'AdminAgent': '/adminAgent',
    'AdminTransportCompanies': '/adminTransportCompanies',
    'CompanyDrivers': '/companyDrivers',
    'AdminTourGuides': '/adminTourGuides',
    'AdminPartners': '/adminPartners',
    'PartnerBookings': '/partnerBookings',
    // Finance
    'AdminFinanceHub': '/adminFinanceHub',
    'AdminFinanceReconciliation': '/adminFinanceReconciliation',
    'AdminFinanceChannels': '/adminFinanceChannels',
    'AdminSettlements': '/adminSettlements',
    'AdminAgentFinance': '/adminFinanceAgents',
    'AdminFinanceReports': '/adminFinanceReports',
    'AdminFinanceAudit': '/adminFinanceAudit',
    'AdminReconciliation': '/adminReconciliation',
    // Reports
    'AdminReportsHub': '/adminReportsHub',
    'AdminAuditLog': '/adminAuditLog',
    // System
    'AdminDiagnostics': '/adminDiagnostics',
    'AdminSuperAdmins': '/adminSuperAdmins',
    'Settings': '/settings',
  };

  String _menuLabel(BuildContext context, String routeName) =>
      navLabel(context, routeName);

  String _sectionLabel(BuildContext context, String key) {
    const map = {
      'overview': 'ent_section_overview',
      'operations': 'ent_section_operations',
      'reviews': 'ent_section_reviews',
      'catalog': 'ent_section_catalog',
      'partners': 'ent_section_partners',
      'geography': 'ent_section_geography',
      'finance': 'ent_section_finance',
      'reports': 'ent_section_reports',
      'system': 'ent_section_system',
    };
    final trKey = map[key];
    if (trKey == null) return key;
    return appTr(context, trKey);
  }

  bool _canShow(String route) {
    if (route == CompanyDriversWidget.routeName) {
      return AdminRoleService.isTransportCompany;
    }
    if (route == PartnerBookingsWidget.routeName) {
      return AdminRoleService.isPartner;
    }
    if (route == AdminAuditLogWidget.routeName) {
      return AdminRoleService.isSuperAdmin;
    }
    if (route == AdminReportsHubWidget.routeName) {
      return AdminRoleService.isSuperAdmin;
    }
    if (route == AdminSuperAdminsWidget.routeName) {
      return AdminRoleService.isSuperAdmin;
    }
    if (route == AdminDriverWalletsWidget.routeName) {
      // LEGACY_WALLET_TOOL — not settlement V2; SuperAdmin only.
      return AdminRoleService.isSuperAdmin;
    }
    return AdminRoleService.canAccessRoute(route);
  }

  /// PERF-P1: settlement attention badges are Super Admin / Country Agent only.
  /// Accountant finance menu must not keep dual Firestore badge listeners alive.
  bool get _showFinanceHubAttentionBadges =>
      AdminRoleService.wantsFinanceHubAttentionBadges;

  Widget _financeHubTile(({String route, IconData icon}) item) {
    if (!_showFinanceHubAttentionBadges) {
      return AdminMenuTile(
        icon: item.icon,
        label: _menuLabel(context, item.route),
        isActive: _isActive(context, item.route),
        onTap: () => _navigate(context, item.route),
      );
    }

    _ensureFinanceBadgeStreams();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pendingPaymentsStream,
      builder: (context, paySnap) {
        final pending = paySnap.data?.size ?? 0;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _draftSettlementsStream,
          builder: (context, draftSnap) {
            final drafts = draftSnap.data?.size ?? 0;
            return AdminMenuTile(
              icon: item.icon,
              label: _menuLabel(context, item.route),
              isActive: _isActive(context, item.route),
              attentionCount: pending + drafts,
              onTap: () => _navigate(context, item.route),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);

    return AuthUserStreamWidget(
      builder: (context) {
        final role = AdminRoleService.currentRole;
        final countryLabel = AdminRoleService.scopedCountryName;
        final rolePending = AdminShellRules.shouldHideNavItems(
          loggedIn: loggedIn,
          isRoleResolving: AdminRoleService.isRoleResolving,
          hasUserDocument: currentUserDocument != null,
        );

        final sections =
            <({String key, List<({String route, IconData icon})> items})>[
          (
            key: 'operations',
            items: [
              (
                route: Home22DashboardWidget.routeName,
                icon: Icons.dashboard_rounded
              ),
              (
                route: AdminALLhgZWidget.routeName,
                icon: Icons.bookmark_added_rounded
              ),
              (route: AdminuserWidget.routeName, icon: Icons.groups_rounded),
              (
                route: AdmindreverWidget.routeName,
                icon: Icons.directions_car_rounded
              ),
              (
                route: AdminSuportWidget.routeName,
                icon: Icons.support_agent_rounded
              ),
            ],
          ),
          (
            key: 'reviews',
            items: [
              (
                route: AdminNotificationsWidget.routeName,
                icon: Icons.notifications_rounded
              ),
              (
                route: AdminDriverExpiryQueueWidget.routeName,
                icon: Icons.event_busy_rounded
              ),
            ],
          ),
          (
            key: 'catalog',
            items: [
              (
                route: AdmintypecarWidget.routeName,
                icon: Icons.airport_shuttle_rounded
              ),
              (route: AdminDolWidget.routeName, icon: Icons.flag_rounded),
              (
                route: AdminregionWidget.routeName,
                icon: Icons.filter_hdr_rounded
              ),
              (
                route: AdminvillWidget.routeName,
                icon: Icons.location_city_rounded
              ),
              (route: AdminM3almWidget.routeName, icon: Icons.place_rounded),
            ],
          ),
          (
            key: 'partners',
            items: [
              (
                route: AdminAgentWidget.routeName,
                icon: Icons.real_estate_agent_rounded
              ),
              (
                route: AdminTransportCompaniesWidget.routeName,
                icon: Icons.local_shipping_rounded
              ),
              (
                route: CompanyDriversWidget.routeName,
                icon: Icons.directions_car_filled_rounded
              ),
              (
                route: AdminTourGuidesWidget.routeName,
                icon: Icons.tour_rounded
              ),
              (
                route: AdminPartnersWidget.routeName,
                icon: Icons.handshake_rounded
              ),
              (
                route: PartnerBookingsWidget.routeName,
                icon: Icons.receipt_long_rounded
              ),
            ],
          ),
          (
            key: 'finance',
            items: [
              (
                route: AdminFinanceHubWidget.routeName,
                icon: Icons.account_balance_rounded
              ),
              (
                route: AdminFinanceReconciliationWidget.routeName,
                icon: Icons.fact_check_outlined
              ),
              (
                route: AdminFinanceChannelsWidget.routeName,
                icon: Icons.swap_horiz_rounded
              ),
              (
                route: AdminSettlementsWidget.routeName,
                icon: Icons.receipt_long_outlined
              ),
              (
                route: AdminAgentFinanceWidget.routeName,
                icon: Icons.handshake_outlined
              ),
              (
                route: AdminFinanceReportsWidget.routeName,
                icon: Icons.table_chart_outlined
              ),
              (
                route: AdminFinanceAuditWidget.routeName,
                icon: Icons.manage_search_rounded
              ),
            ],
          ),
          (
            key: 'reports',
            items: [
              (
                route: AdminReportsHubWidget.routeName,
                icon: Icons.assessment_rounded
              ),
              (
                route: AdminAuditLogWidget.routeName,
                icon: Icons.history_rounded
              ),
            ],
          ),
          (
            key: 'system',
            items: [
              (
                route: AdminDiagnosticsWidget.routeName,
                icon: Icons.monitor_heart_outlined
              ),
              (
                route: AdminSuperAdminsWidget.routeName,
                icon: Icons.admin_panel_settings_rounded
              ),
              (route: SettingsWidget.routeName, icon: Icons.settings_rounded),
            ],
          ),
        ];

        final visibleSections = rolePending
            ? <({String key, List<({String route, IconData icon})> items})>[]
            : sections
                .map((s) => (
                      key: s.key,
                      items: s.items.where((i) => _canShow(i.route)).toList(),
                    ))
                .where((s) => s.items.isNotEmpty)
                .toList();

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AdminUi.sidebarGradient(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: AdminUi.sidebarHeaderDecoration(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.getText('hrrt489c' /* Admin */),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleMedium.override(
                          fontFamily: theme.titleMediumFamily,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.0,
                          useGoogleFonts: !theme.titleMediumIsCustom,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: AuthUserStreamWidget(
                                builder: (context) => ProfilePhotoImage(
                                  photoUrl: currentUserPhoto,
                                  size: 36,
                                  borderRadius: BorderRadius.circular(7),
                                  loadingColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AuthUserStreamWidget(
                                  builder: (context) => Text(
                                    currentUserDisplayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.bodyMedium.override(
                                      fontFamily: theme.bodyMediumFamily,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      letterSpacing: 0.0,
                                      useGoogleFonts: !theme.bodyMediumIsCustom,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rolePending
                                        ? uiTr(context, 'Resolving role…')
                                        : (countryLabel.isNotEmpty
                                            ? '${AdminRoleService.roleLabelL10n(context, role)} · $countryLabel'
                                            : AdminRoleService.roleLabelL10n(
                                                context, role)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.labelSmall.override(
                                      fontFamily: theme.labelSmallFamily,
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.5,
                                      letterSpacing: 0.0,
                                      useGoogleFonts: !theme.labelSmallIsCustom,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentUserEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.labelSmall.override(
                                    fontFamily: theme.labelSmallFamily,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11.5,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: !theme.labelSmallIsCustom,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: () async {
                                    closeDrawerIfOpen(context);
                                    GoRouter.of(context).prepareAuthEvent();
                                    await authManager.signOut();
                                    GoRouter.of(context)
                                        .clearRedirectLocation();
                                    if (!context.mounted) return;
                                    context.goNamedAuth(
                                      HomePageWidget.routeName,
                                      context.mounted,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.logout_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                  label: Text(
                                    l10n.getText('wj2hxjyt' /* Log out */),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.labelMedium.override(
                                      fontFamily: theme.labelMediumFamily,
                                      color:
                                          Colors.white.withValues(alpha: 0.78),
                                      fontSize: 11.5,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !theme.labelMediumIsCustom,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    for (final section in visibleSections) ...[
                      AdminMenuSectionHeader(
                        label: _sectionLabel(context, section.key),
                      ),
                      for (final item in section.items)
                        item.route == AdminFinanceHubWidget.routeName
                            ? _financeHubTile(item)
                            : AdminMenuTile(
                                icon: item.icon,
                                label: _menuLabel(context, item.route),
                                isActive: _isActive(context, item.route),
                                onTap: () => _navigate(context, item.route),
                              ),
                    ],
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                child: const AdminThemeToggle(onTealChrome: true),
              ),
            ],
          ),
        );
      },
    );
  }
}
