import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/nav_translations.dart';
import '/index.dart';
import '/components/profile_photo_image.dart';
import 'package:flutter/material.dart';
import 'menu2_model.dart';
export 'menu2_model.dart';

/// قائمة اللوحة
class Menu2Widget extends StatefulWidget {
  const Menu2Widget({super.key});

  @override
  State<Menu2Widget> createState() => _Menu2WidgetState();
}

class _Menu2WidgetState extends State<Menu2Widget> {
  late Menu2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Menu2Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  void _navigate(BuildContext context, String routeName) {
    closeDrawerIfOpen(context);
    if (routeName == AdminM3almWidget.routeName) {
      context.pushNamed(
        AdminM3almWidget.routeName,
        queryParameters: {
          'partnersOnly': serializeParam(false, ParamType.bool),
        }.withoutNulls,
      );
      return;
    }
    context.pushNamed(routeName);
  }

  bool _isActive(BuildContext context, String routeName) {
    return GoRouterState.of(context).name == routeName;
  }

  String _menuLabel(BuildContext context, String routeName) =>
      navLabel(context, routeName);

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);
    final role = AdminRoleService.currentRole;
    final countryLabel = AdminRoleService.scopedCountryName;

    final allMenuItems = <({String route, IconData icon})>[
      (route: Home22DashboardWidget.routeName, icon: Icons.dashboard_rounded),
      (route: AdminM3almWidget.routeName, icon: Icons.place_rounded),
      (route: AdminPartnersWidget.routeName, icon: Icons.handshake_rounded),
      (route: AdminDolWidget.routeName, icon: Icons.flag_rounded),
      (route: AdminregionWidget.routeName, icon: Icons.filter_hdr_rounded),
      (route: AdminvillWidget.routeName, icon: Icons.location_city_rounded),
      (route: AdminuserWidget.routeName, icon: Icons.groups_rounded),
      (route: AdminAgentWidget.routeName, icon: Icons.real_estate_agent_rounded),
      (route: AdminSuperAdminsWidget.routeName, icon: Icons.admin_panel_settings_rounded),
      (route: AdminTransportCompaniesWidget.routeName, icon: Icons.local_shipping_rounded),
      (route: AdmindreverWidget.routeName, icon: Icons.directions_car_rounded),
      (route: AdminALLhgZWidget.routeName, icon: Icons.bookmark_added_rounded),
      (route: AdminProfitsWidget.routeName, icon: Icons.account_balance_wallet_rounded),
      (route: AdminReportsHubWidget.routeName, icon: Icons.assessment_rounded),
      (route: AdminAuditLogWidget.routeName, icon: Icons.history_rounded),
      (route: CompanyDriversWidget.routeName, icon: Icons.directions_car_filled_rounded),
      (route: PartnerBookingsWidget.routeName, icon: Icons.receipt_long_rounded),
      (route: AdminSuportWidget.routeName, icon: Icons.support_agent_rounded),
      (route: SettingsWidget.routeName, icon: Icons.settings_rounded),
    ];

    final menuItems = allMenuItems.where((item) {
      if (item.route == CompanyDriversWidget.routeName) {
        return AdminRoleService.isTransportCompany;
      }
      if (item.route == PartnerBookingsWidget.routeName) {
        return AdminRoleService.isPartner;
      }
      if (item.route == AdminAuditLogWidget.routeName) {
        return AdminRoleService.isSuperAdmin;
      }
      if (item.route == AdminReportsHubWidget.routeName) {
        return AdminRoleService.isSuperAdmin;
      }
      if (item.route == AdminSuperAdminsWidget.routeName) {
        return AdminRoleService.isSuperAdmin;
      }
      return AdminRoleService.canAccessRoute(item.route);
    }).toList();

    return Container(
      width: 270.0,
      height: double.infinity,
      decoration: AdminUi.sidebarGradient(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: AdminUi.sidebarHeaderDecoration(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.getText('hrrt489c' /* Admin */),
                          style: theme.headlineSmall.override(
                            fontFamily: theme.headlineSmallFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.0,
                            useGoogleFonts: !theme.headlineSmallIsCustom,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AuthUserStreamWidget(
                            builder: (context) => ProfilePhotoImage(
                              photoUrl: currentUserPhoto,
                              size: 46,
                              borderRadius: BorderRadius.circular(10),
                              loadingColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !theme.bodyMediumIsCustom,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                countryLabel.isNotEmpty
                                    ? '${AdminRoleService.roleLabelL10n(context, role)} · $countryLabel'
                                    : AdminRoleService.roleLabelL10n(context, role),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.labelSmall.override(
                                  fontFamily: theme.labelSmallFamily,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !theme.labelSmallIsCustom,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUserEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.labelSmall.override(
                                fontFamily: theme.labelSmallFamily,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.0,
                                useGoogleFonts: !theme.labelSmallIsCustom,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () async {
                                closeDrawerIfOpen(context);
                                GoRouter.of(context).prepareAuthEvent();
                                await authManager.signOut();
                                GoRouter.of(context).clearRedirectLocation();
                                if (!context.mounted) return;
                                context.goNamedAuth(
                                  HomePageWidget.routeName,
                                  context.mounted,
                                );
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 16,
                                color: Color(0xFFFFB4B8),
                              ),
                              label: Text(
                                l10n.getText('wj2hxjyt' /* Log out */),
                                style: theme.labelMedium.override(
                                  fontFamily: theme.labelMediumFamily,
                                  color: const Color(0xFFFFB4B8),
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !theme.labelMediumIsCustom,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                for (final item in menuItems)
                  AdminMenuTile(
                    icon: item.icon,
                    label: _menuLabel(context, item.route),
                    isActive: _isActive(context, item.route),
                    onTap: () => _navigate(context, item.route),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
