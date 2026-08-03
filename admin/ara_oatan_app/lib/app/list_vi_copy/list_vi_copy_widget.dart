import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'list_vi_copy_model.dart';
export 'list_vi_copy_model.dart';

class ListViCopyWidget extends StatefulWidget {
  const ListViCopyWidget({super.key});

  static String routeName = 'List_viCopy';
  static String routePath = '/listViCopy';

  @override
  State<ListViCopyWidget> createState() => _ListViCopyWidgetState();
}

class _ListViCopyWidgetState extends State<ListViCopyWidget>
    with TickerProviderStateMixin {
  late ListViCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListViCopyModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Business logic — unchanged behaviour, DS-styled surfaces only.
  // ---------------------------------------------------------------------------

  Future<void> _logout(BuildContext context) async {
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    GoRouter.of(context).clearRedirectLocation();

    context.goNamedAuth(HomePagWidget.routeName, context.mounted);
  }

  void _openLandmark(BuildContext context, MkanRecord marker) {
    context.pushNamed(
      PlacedetailsWidget.routeName,
      queryParameters: {
        'mk': serializeParam(
          marker.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return TouryAdaptiveScope(
            child: Scaffold(
              key: scaffoldKey,
              resizeToAvoidBottomInset: false,
              backgroundColor: colors.scaffold,
              drawer: WebViewAware(child: _buildDrawer(context)),
              appBar: _buildAppBar(context),
              body: Stack(
                children: [
                  Positioned.fill(child: _buildMap(context)),
                  Align(
                    alignment: const AlignmentDirectional(0.0, -1.0),
                    child: PointerInterceptor(
                      intercepting: isWeb,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DsSpacing.md,
                            DsSpacing.xs,
                            DsSpacing.md,
                            0,
                          ),
                          child: Row(
                            children: [
                              _MapCircleAction(
                                icon: DsIcons.search,
                                onTap: () async {
                                  context.pushNamed(MapdemoWidget.routeName);
                                },
                              ),
                              const SizedBox(width: DsSpacing.sm),
                              Expanded(
                                child: DsFadeSlide(
                                  offset: const Offset(0, -0.6),
                                  child: _MapCartBar(
                                    cartCount: FFAppState().addcart,
                                    onTap: () async {
                                      context.pushNamed(DemoDWidget.routeName);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return DsAppBar(
      automaticallyImplyLeading: false,
      title: FFAppState().naimmdenh,
      leading: DsIconButton(
        icon: Icons.menu_rounded,
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: () async {
          scaffoldKey.currentState!.openDrawer();
        },
      ),
      actions: [
        DsIconButton(
          icon: DsIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        const SizedBox(width: DsSpacing.xxs),
      ],
    );
  }

  Widget _buildMap(BuildContext context) {
    return StreamBuilder<List<MkanRecord>>(
      stream: queryMkanRecord(
        queryBuilder: (mkanRecord) => mkanRecord
            .where(
              'id_vill',
              isEqualTo: FFAppState().villa,
            )
            .where(
              'acctev',
              isEqualTo: true,
            ),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const DsLoading(size: DsConstants.avatarMd);
        }
        List<MkanRecord> googleMapMkanRecordList = snapshot.data!;

        return FlutterFlowGoogleMap(
          controller: _model.googleMapsController,
          onCameraIdle: (latLng) =>
              safeSetState(() => _model.googleMapsCenter = latLng),
          initialLocation: _model.googleMapsCenter ??= FFAppState().latlngvill!,
          markers: googleMapMkanRecordList
              .where((e) => e.hasLocation())
              .toList()
              .map(
                (marker) => FlutterFlowMarker(
                  marker.reference.path,
                  marker.location!,
                  () async {
                    _openLandmark(context, marker);
                  },
                ),
              )
              .toList(),
          markerColor: GoogleMarkerColor.green,
          mapType: MapType.hybrid,
          style: GoogleMapStyle.standard,
          initialZoom: 8.0,
          allowInteraction: true,
          allowZoom: true,
          showZoomControls: true,
          showLocation: true,
          showCompass: true,
          showMapToolbar: true,
          showTraffic: true,
          centerMapOnMarkerTap: true,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------

  Widget _buildDrawer(BuildContext context) {
    return DsDrawer(
      header: _DrawerHeaderCard(
        caption: FFLocalizations.of(context).getText(
          'oin1oux3' /* YOU ARE BROWSING NOW */,
        ),
        countryName: FFAppState().naimdolh,
        changeLabel: FFLocalizations.of(context).getText(
          'txvor504' /* Change country */,
        ),
        onChangeCountry: () async {
          context.pushNamed(AldolWidget.routeName);
        },
      ),
      items: [
        _DrawerActionTile(
          icon: DsIcons.location,
          title: FFLocalizations.of(context).getText(
            '0f3gw3ik' /* You are currently browsing: */,
          ),
          subtitle: FFAppState().naimvillatext,
        ),
        if (FFAppState().ismapview == false)
          _DrawerActionTile(
            icon: Icons.map_outlined,
            title: FFLocalizations.of(context).getText(
              'zi8z4j52' /* Browse the map */,
            ),
            subtitle: FFAppState().naimvillatext,
            onTap: () async {
              context.pushNamed(ListViCopyWidget.routeName);

              FFAppState().ismapview = true;
              safeSetState(() {});
            },
          ),
        if (FFAppState().ismapview == true)
          _DrawerActionTile(
            icon: Icons.list_alt_rounded,
            title: FFLocalizations.of(context).getText(
              'egx26v25' /* View list */,
            ),
            subtitle: FFAppState().naimvillatext,
            onTap: () async {
              context.pushNamed(
                ListViWidget.routeName,
                queryParameters: {
                  'cite': serializeParam(
                    FFAppState().villa,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              );

              FFAppState().ismapview = true;
              safeSetState(() {});
            },
          ),
        _DrawerActionTile(
          icon: Icons.add_location_alt_outlined,
          title: FFLocalizations.of(context).getText(
            'm5zipm0w' /* Add a place from the map. */,
          ),
          subtitle: FFAppState().naimvillatext,
          onTap: () async {
            context.goNamed(MapdemoWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.wb_sunny_outlined,
          iconColor: context.dsColors.warning,
          title: FFLocalizations.of(context).getText(
            '3me0b29v' /* general information */,
          ),
          subtitle: FFAppState().naimvillatext,
          onTap: () async {
            context.pushNamed(AbutMdenhWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: DsIcons.map,
          title: FFAppState().naimmdenh,
          subtitle: FFLocalizations.of(context).getText(
            'k30z7j6a' /* Change city */,
          ),
          onTap: () async {
            context.pushNamed(
              Citie2Widget.routeName,
              queryParameters: {
                'coun': serializeParam(
                  FFAppState().dolh,
                  ParamType.DocumentReference,
                ),
                'naim': serializeParam(
                  FFAppState().naimdolh,
                  ParamType.String,
                ),
                'idcit': serializeParam(
                  FFAppState().dolh,
                  ParamType.DocumentReference,
                ),
                'imgDolh': serializeParam(
                  FFAppState().imgDolh,
                  ParamType.String,
                ),
              }.withoutNulls,
            );
          },
        ),
        _DrawerActionTile(
          icon: Icons.playlist_add_check_rounded,
          title: FFLocalizations.of(context).getText(
            '52c39uit' /* Added destinations */,
          ),
          badge: FFAppState().addcart.toString(),
          onTap: () async {
            context.pushNamed(Checkout66Widget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: DsIcons.bookings,
          title: FFLocalizations.of(context).getText(
            'om46c9cr' /* My bookings */,
          ),
          subtitle: FFLocalizations.of(context).getText(
            '5y7lg3l7' /* Booking list. */,
          ),
          onTap: () async {
            context.pushNamed(List22TaskOverviewResponsiveWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.add_to_photos_outlined,
          title: FFLocalizations.of(context).getText(
            'hca38mjg' /* Suggest a Place */,
          ),
          subtitle: FFLocalizations.of(context).getText(
            'j9obxr2h' /* Add a Special Place */,
          ),
          onTap: () async {
            context.pushNamed(NewPlaceWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.mail_outline_rounded,
          title: FFLocalizations.of(context).getText(
            '10hqamjj' /* رسائل جديدة */,
          ),
          badge: FFLocalizations.of(context).getText(
            '04vs6mor' /* 0 */,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.xs,
          ),
          child: DsDivider(),
        ),
        DsDrawerItem(
          icon: DsIcons.settings,
          label: FFLocalizations.of(context).getText(
            '8vc9c4ow' /* Settings */,
          ),
          onTap: () async {
            context.pushNamed(Profile05Widget.routeName);
          },
        ),
        DsDrawerItem(
          icon: Icons.help_outline_rounded,
          label: FFLocalizations.of(context).getText(
            'bvkgwr5t' /* Help */,
          ),
          onTap: () async {
            context.pushNamed(SupportWidget.routeName);
          },
        ),
      ],
      footer: _DrawerLogoutButton(
        label: FFLocalizations.of(context).getText(
          't5nfvyj4' /* Log Out */,
        ),
        onTap: () => _logout(context),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Map overlays
// -----------------------------------------------------------------------------

class _MapCircleAction extends StatelessWidget {
  const _MapCircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;

    return DsPressable(
      onTap: onTap,
      child: Container(
        width: DsConstants.avatarMd,
        height: DsConstants.avatarMd,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
          boxShadow: DsShadows.card(dark: context.dsIsDark),
        ),
        child: Icon(icon, size: DsIcons.sm, color: colors.primary),
      ),
    );
  }
}

class _MapCartBar extends StatelessWidget {
  const _MapCartBar({required this.cartCount, required this.onTap});

  final int cartCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsPressable(
      onTap: onTap,
      child: Container(
        height: DsConstants.buttonHeightSm,
        padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: DsRadius.pill,
          boxShadow: DsShadows.card(dark: context.dsIsDark),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: DsIcons.xs, color: colors.primary),
            const SizedBox(width: DsSpacing.xs),
            Flexible(
              child: Text(
                '${valueOrDefault<String>(
                  cartCount.toString(),
                  '0',
                )} وجهات   - حجز الآن  ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.labelLarge.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Drawer pieces
// -----------------------------------------------------------------------------

class _DrawerHeaderCard extends StatelessWidget {
  const _DrawerHeaderCard({
    required this.caption,
    required this.countryName,
    required this.changeLabel,
    required this.onChangeCountry,
  });

  final String caption;
  final String countryName;
  final String changeLabel;
  final VoidCallback onChangeCountry;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryStrong],
        ),
        borderRadius: DsRadius.large,
        boxShadow: DsShadows.primaryGlow(dark: context.dsIsDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: DsConstants.avatarMd,
                height: DsConstants.avatarMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.18),
                  borderRadius: DsRadius.medium,
                ),
                child: Icon(
                  Icons.public_rounded,
                  size: DsIcons.sm,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.labelSmall.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      countryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleLarge.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          DsPressable(
            onTap: onChangeCountry,
            child: Container(
              padding: DsSpacing.chipPadding,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.16),
                borderRadius: DsRadius.pill,
                border: Border.all(
                  color: colors.onPrimary.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: DsIcons.xs,
                    color: colors.onPrimary,
                  ),
                  const SizedBox(width: DsSpacing.xxs),
                  Text(
                    changeLabel,
                    style: typography.labelMedium.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return ListTile(
      leading: Container(
        width: DsConstants.avatarSm,
        height: DsConstants.avatarSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: DsRadius.small,
        ),
        child: Icon(
          icon,
          size: DsIcons.sm,
          color: iconColor ?? colors.primary,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: typography.titleSmall.copyWith(color: colors.textPrimary),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: DsRadius.pill,
              ),
              child: Text(
                badge!,
                style: typography.labelMedium.copyWith(
                  color: colors.primaryStrong,
                ),
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: DsSpacing.xxs),
            Icon(
              Icons.chevron_right_rounded,
              size: DsIcons.sm,
              color: colors.iconMuted,
            ),
          ],
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
      onTap: onTap,
    );
  }
}

class _DrawerLogoutButton extends StatelessWidget {
  const _DrawerLogoutButton({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xs,
            vertical: DsSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: DsIcons.sm,
                color: colors.error,
              ),
              const SizedBox(width: DsSpacing.sm),
              Text(
                label,
                style: typography.titleSmall.copyWith(color: colors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
