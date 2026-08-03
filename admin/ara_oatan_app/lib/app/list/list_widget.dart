import 'package:easy_localization/easy_localization.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_geo_aliases.dart';
import '/core/toury_geo_display.dart';
import '/core/toury_image.dart';
import '/core/toury_location_service.dart';
import 'list_model.dart';
export 'list_model.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  static String routeName = 'List';
  static String routePath = '/list';

  @override
  State<ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> {
  late ListModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Open landmarks for a manually chosen city — never bounce to DemoD home.
  void _openCityLandmarks(VillagesRecord village, {required bool nodelet}) {
    final canonical = touryCanonicalVillageRef(village.reference);
    TouryLocationService.manualCountryLock = true;
    TouryFirestoreCache.prefetchMkanFirstPage(canonical);

    FFAppState().update(() {
      FFAppState().villa = canonical;
      FFAppState().vil = canonical;
      FFAppState().villnow = canonical;
      FFAppState().naimvillatext = touryLocalizedVillageLabel(village);
      FFAppState().villtextnow = FFAppState().naimvillatext;
      FFAppState().IMGVILL = village.img;
      FFAppState().latlngvill = village.latLing;
      FFAppState().tebycar = '';
      FFAppState().notcar = '';
      FFAppState().srtypecar = 0;
      FFAppState().ismapview = false;
      FFAppState().nodelet = nodelet;
      FFAppState().adressNaim = '';
      FFAppState().mkanuserorder = null;
      FFAppState().cartItems = [];
      FFAppState().cartPriceSummary = [];
      FFAppState().cartmkss = [];
      FFAppState().addcart = 0;
      FFAppState().mkan = [];
      FFAppState().totalsaatandcar = 0;
      FFAppState().AllowBooking = true;
    });

    if (!mounted) return;
    context.pushNamed(
      ListViWidget.routeName,
      queryParameters: {
        'cite': serializeParam(
          canonical,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        Future(() async {
          if (FFAppState().mdenh == null) {
            await showDialog(
              context: context,
              builder: (alertDialogContext) {
                return WebViewAware(
                  child: AlertDialog(
                    title: Text('ui_text_224b63d8e3'.tr()),
                    content: Text('ui_text_af02762d6d'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(alertDialogContext),
                        child: Text('ui_text_9072549574'.tr()),
                      ),
                    ],
                  ),
                );
              },
            );

            context.pushNamed(AldolWidget.routeName);
          }
        }),
        Future(() async {}),
      ]);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _openCitiesFromDrawer() {
    context.pushNamed(
      Citie2Widget.routeName,
      queryParameters: {
        'coun': serializeParam(
          FFAppState().dolh,
          ParamType.DocumentReference,
        ),
        'naim': serializeParam(
          FFAppState().naimmdenh,
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
  }

  void _openCitiesFromPanel() {
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
        'imgDolh': serializeParam(
          FFAppState().imgDolh,
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _logout() async {
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    GoRouter.of(context).clearRedirectLocation();

    context.goNamedAuth(HomePagWidget.routeName, context.mounted);
  }

  @override
  Widget build(BuildContext context) {
    context.select<FFAppState, int>(
      (s) => Object.hash(s.mdenh, s.naimvillatext, s.naimdolh),
    );

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final dsTheme = isDark ? DsTheme.dark() : DsTheme.light();

    final countryName = FFAppState().naimdolh;
    final regionName = FFAppState().naimmdenh;
    final cartCount = FFAppState().addcart.toString();

    return Theme(
      data: dsTheme,
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: TouryAdaptiveScope(
                child: Scaffold(
                  key: scaffoldKey,
                  backgroundColor: colors.scaffold,
                  drawer: DsDrawer(
                    header: _DrawerHeaderCard(
                      countryName: countryName,
                      onChangeCountry: () =>
                          context.pushNamed(AldolWidget.routeName),
                    ),
                    items: [
                      _DrawerActionTile(
                        icon: DsIcons.map,
                        title: regionName,
                        subtitle: 'Change region'.tr(),
                        onTap: _openCitiesFromDrawer,
                      ),
                      _DrawerActionTile(
                        icon: Icons.playlist_add_check_rounded,
                        title: 'Added destinations'.tr(),
                        badge: cartCount,
                        onTap: () =>
                            context.pushNamed(Checkout66Widget.routeName),
                      ),
                      _DrawerActionTile(
                        icon: Icons.add_location_alt_outlined,
                        title: 'Suggest a Place'.tr(),
                        subtitle: 'Add a Special Place'.tr(),
                        onTap: () =>
                            context.pushNamed(NewPlaceWidget.routeName),
                      ),
                      _DrawerActionTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Message...'.tr(),
                        badge: '0'.tr(),
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
                        label: 'Settings'.tr(),
                        onTap: () =>
                            context.pushNamed(Profile05Widget.routeName),
                      ),
                      DsDrawerItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help'.tr(),
                        onTap: () => context.pushNamed(SupportWidget.routeName),
                      ),
                    ],
                    footer: _DrawerLogoutButton(onTap: _logout),
                  ),
                  appBar: DsAppBar(
                    title: countryName,
                    automaticallyImplyLeading: false,
                    leading: DsIconButton(
                      icon: Icons.menu_rounded,
                      tooltip:
                          MaterialLocalizations.of(context).openAppDrawerTooltip,
                      onPressed: () => scaffoldKey.currentState?.openDrawer(),
                    ),
                    actions: [
                      DsIconButton(
                        icon: DsIcons.back,
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: DsSpacing.xxs),
                    ],
                  ),
                  body: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: TouryCityHeroBanner(
                              height: constraints.maxHeight,
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    colors.scrim.withValues(alpha: 0.35),
                                    colors.scrim.withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _CityHeroContent(
                                    regionName: regionName,
                                    countryName: countryName,
                                  ),
                                ),
                                _CitiesPanel(
                                  regionName: regionName,
                                  onChangeRegion: _openCitiesFromPanel,
                                  onOpenVillage: _openCityLandmarks,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hero copy always sits on a dark scrim, so it uses the dark palette tokens
/// regardless of the active theme.
class _CityHeroContent extends StatelessWidget {
  const _CityHeroContent({
    required this.regionName,
    required this.countryName,
  });

  final String regionName;
  final String countryName;

  @override
  Widget build(BuildContext context) {
    final typography = context.dsTypography;
    final onHero = DsColors.dark.textPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsFadeSlide(
              child: Container(
                padding: DsSpacing.chipPadding,
                decoration: BoxDecoration(
                  color: onHero.withValues(alpha: 0.16),
                  borderRadius: DsRadius.pill,
                  border: Border.all(color: onHero.withValues(alpha: 0.24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(DsIcons.location, size: DsIcons.xs, color: onHero),
                    const SizedBox(width: DsSpacing.xxs),
                    Flexible(
                      child: Text(
                        countryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.labelMedium.copyWith(color: onHero),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            DsFadeSlide(
              delay: DsDurations.fast,
              child: Text(
                regionName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.displaySmall.copyWith(color: onHero),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitiesPanel extends StatelessWidget {
  const _CitiesPanel({
    required this.regionName,
    required this.onChangeRegion,
    required this.onOpenVillage,
  });

  final String regionName;
  final VoidCallback onChangeRegion;
  final void Function(VillagesRecord village, {required bool nodelet})
      onOpenVillage;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final railHeight = min(
      TouryLayout.listPanelHeight(context),
      TouryLayout.villageThumbSize(context) + 128.0,
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: TouryLayout.panelMaxHeight(context),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: DsRadius.xlRadius),
        boxShadow: DsShadows.bottomSheet(dark: context.dsIsDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: DsSpacing.sm,
              bottom: DsSpacing.xs,
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: DsRadius.pill,
                ),
              ),
            ),
          ),
          DsSectionHeader(
            title: 'Cities/provinces'.tr(),
            subtitle: '${'Browse cities/counties in'.tr()} $regionName',
            actionLabel: 'Change'.tr(),
            onAction: onChangeRegion,
          ),
          Flexible(
            child: SizedBox(
              height: railHeight,
              child: _VillagesRail(onOpenVillage: onOpenVillage),
            ),
          ),
          SizedBox(height: DsSpacing.md + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

class _VillagesRail extends StatelessWidget {
  const _VillagesRail({required this.onOpenVillage});

  final void Function(VillagesRecord village, {required bool nodelet})
      onOpenVillage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillagesRecord>>(
      stream: TouryFirestoreCache.villagesStream(
        cacheKey: 'city:${FFAppState().mdenh?.path ?? 'none'}',
        queryBuilder: (villagesRecord) => villagesRecord
            .where(
              'cities',
              isEqualTo: FFAppState().mdenh,
            )
            .where(
              'acctev',
              isEqualTo: true,
            ),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const DsLoading();
        }
        List<VillagesRecord> listViewVillagesRecordList = snapshot.data!;

        if (listViewVillagesRecordList.isEmpty) {
          return DsEmptyState(
            title: 'Cities/provinces'.tr(),
            icon: DsIcons.location,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.xs,
          ),
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: listViewVillagesRecordList.length,
          separatorBuilder: (_, __) => const SizedBox(width: DsSpacing.sm),
          itemBuilder: (context, listViewIndex) {
            final listViewVillagesRecord =
                listViewVillagesRecordList[listViewIndex];
            return SizedBox(
              width: TouryLayout.villageHorizontalCardWidth(context),
              child: _VillageCard(
                village: listViewVillagesRecord,
                index: listViewIndex,
                onOpen: onOpenVillage,
              ),
            );
          },
        );
      },
    );
  }
}

class _VillageCard extends StatelessWidget {
  const _VillageCard({
    required this.village,
    required this.index,
    required this.onOpen,
  });

  final VillagesRecord village;
  final int index;
  final void Function(VillagesRecord village, {required bool nodelet}) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final label = touryLocalizedVillageLabel(village);

    return DsFadeSlide(
      delay: Duration(milliseconds: 50 * index.clamp(0, 6)),
      offset: const Offset(0.7, 0),
      child: DsPressable(
        onTap: () => onOpen(
          village,
          nodelet: village.noDeletePlace == true,
        ),
        child: DsCard(
          elevated: true,
          padding: const EdgeInsets.all(DsSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: village.img,
                  transitionOnUserGestures: true,
                  child: ClipRRect(
                    borderRadius: DsRadius.medium,
                    child: TouryNetworkImage(
                      key: ValueKey(
                        '${village.reference.id}:${village.img}',
                      ),
                      url: village.img,
                      documentId: village.reference.id,
                      placeName: label,
                      latitude: village.latLing?.latitude,
                      longitude: village.latLing?.longitude,
                      fit: BoxFit.cover,
                      fallbackAsset: kTouryImageFallback,
                      useBrandedFallback: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: DsSpacing.xxs),
              _LandmarkCountLabel(village: village),
              const SizedBox(height: DsSpacing.xs),
              Row(
                children: [
                  Text(
                    'View Now'.tr(),
                    style: typography.labelMedium.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: DsIcons.xs,
                    color: colors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandmarkCountLabel extends StatelessWidget {
  const _LandmarkCountLabel({required this.village});

  final VillagesRecord village;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return FutureBuilder<int>(
      future: TouryFirestoreCache.mkanCount(
        cacheKey: 'village:${village.reference.path}',
        queryBuilder: (mkanRecord) => mkanRecord
            .where(
              'id_vill',
              isEqualTo: village.reference,
            )
            .where(
              'acctev',
              isEqualTo: true,
            ),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const DsShimmer(width: 96, height: 12);
        }
        int rowCount = snapshot.data!;

        return Row(
          children: [
            Icon(
              DsIcons.location,
              size: DsIcons.xs,
              color: colors.primary,
            ),
            const SizedBox(width: DsSpacing.xxs),
            Expanded(
              child: Text(
                'landmarks_loaded_count'.tr(namedArgs: {
                  'count': rowCount.toString(),
                }),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.labelSmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerHeaderCard extends StatelessWidget {
  const _DrawerHeaderCard({
    required this.countryName,
    required this.onChangeCountry,
  });

  final String countryName;
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
                      'browsing_now'.tr(namedArgs: {'country': countryName}),
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
                    "Change country".tr(),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
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
        child: Icon(icon, size: DsIcons.sm, color: colors.primary),
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
  const _DrawerLogoutButton({required this.onTap});

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
                "Log Out".tr(),
                style: typography.titleSmall.copyWith(color: colors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
