import 'package:easy_localization/easy_localization.dart';
import '/core/toury_mkan_i18n.dart';
import '/core/toury_landmark_cart.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'list_vi_copy2_model.dart';
export 'list_vi_copy2_model.dart';

/// خانة للبحث اول الصفحة
class ListViCopy2Widget extends StatefulWidget {
  const ListViCopy2Widget({
    super.key,
    required this.cite,
  });

  final DocumentReference? cite;

  static String routeName = 'List_viCopy2';
  static String routePath = '/listViCopy2';

  @override
  State<ListViCopy2Widget> createState() => _ListViCopy2WidgetState();
}

class _ListViCopy2WidgetState extends State<ListViCopy2Widget> {
  late ListViCopy2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListViCopy2Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {});

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

  void _addLandmarkToCart(MkanRecord record) {
    touryAddLandmarkToCart(
      context: context,
      record: record,
      onChanged: () => safeSetState(() {}),
    );
  }

  void _openPlaceDetails(MkanRecord record) {
    context.pushNamed(
      PlacedetailsWidget.routeName,
      queryParameters: {
        'mk': serializeParam(
          record.reference,
          ParamType.DocumentReference,
        ),
        'textnaim': serializeParam(
          touryMkanName(context, record),
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(builder: _buildScreen),
    );
  }

  Widget _buildScreen(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: TouryAdaptiveScope(
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: colors.scaffold,
          drawer: WebViewAware(child: _buildDrawer(context)),
          appBar: DsAppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: '${FFAppState().naimmdenh}- ${FFAppState().naimvillatext}',
            leading: DsBackButton(
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              DsIconButton(
                icon: Icons.menu_rounded,
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                onPressed: () async {
                  scaffoldKey.currentState!.openDrawer();
                },
              ),
              const SizedBox(width: DsSpacing.xxs),
            ],
          ),
          body: SizedBox(
            height: TouryLayout.heroHeight(context),
            child: Stack(
              alignment: const AlignmentDirectional(0.0, -1.0),
              children: [
                Align(
                  alignment: const AlignmentDirectional(0.05, -1.0),
                  child: TouryVillageHeroBanner(
                    height: TouryLayout.heroHeight(context),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: TouryLayout.heroHeight(context),
                  decoration: BoxDecoration(color: colors.scrim),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (FFAppState().addcart >= 1) _buildCartBar(context),
                    const SizedBox(height: DsSpacing.xl),
                    Flexible(child: _buildLandmarksPanel(context)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartBar(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsFadeSlide(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.md,
          DsSpacing.md,
          DsSpacing.md,
          0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '${FFLocalizations.of(context).getVariableText(
                  enText: 'Added Destinations: ',
                  arText: 'الوجهات المضافة: ',
                  zh_HansText: 'Added Destinations: ',
                  trText: 'Added Destinations: ',
                  urText: 'Added Destinations: ',
                  ruText: 'Added Destinations: ',
                  azText: 'Added Destinations: ',
                  kaText: 'Added Destinations: ',
                )} ${FFAppState().addcart.toString()} ',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.titleSmall.copyWith(color: colors.onPrimary),
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            DsButton.primary(
              size: DsButtonSize.sm,
              icon: Icons.remove_red_eye_outlined,
              label: FFLocalizations.of(context).getText(
                'w52tdv15' /* View My Trip */,
              ),
              onPressed: () async {
                context.pushNamed(Checkout66Widget.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandmarksPanel(BuildContext context) {
    final colors = context.dsColors;

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
        children: [
          Padding(
            padding: const EdgeInsets.only(top: DsSpacing.xs),
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: DsRadius.pill,
              ),
            ),
          ),
          DsSectionHeader(
            title: FFLocalizations.of(context).getText(
              '6tfjgk3j' /* Tourist landmarks */,
            ),
            subtitle: FFAppState().naimvillatext,
          ),
          _buildCategoryChips(context),
          Flexible(child: _buildLandmarksList(context)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.xxs,
        DsSpacing.md,
        DsSpacing.xs,
      ),
      child: FlutterFlowChoiceChips(
        options: [
          ChipData(
              FFLocalizations.of(context).getText(
                'jdzcv8tg' /* معالم سياحية */,
              ),
              Icons.tour_outlined),
          ChipData("معالم دينية", Icons.tour_outlined),
          ChipData(
              FFLocalizations.of(context).getText(
                'x0q2rgyg' /* أماكن ترفيهية */,
              ),
              Icons.sentiment_satisfied_rounded),
          ChipData(
              FFLocalizations.of(context).getText(
                '4xw3hizj' /* مطاعم */,
              ),
              Icons.restaurant),
          ChipData(
              FFLocalizations.of(context).getText(
                '9m3877ws' /* مقهى */,
              ),
              Icons.coffee_outlined),
          ChipData(
              FFLocalizations.of(context).getText(
                'l0vqfiyp' /* أماكن سياحية */,
              ),
              Icons.place_sharp),
          ChipData(
              FFLocalizations.of(context).getText(
                'kcfatw07' /* أسواق */,
              ),
              Icons.shopping_cart_sharp),
          ChipData(
              FFLocalizations.of(context).getText(
                'mc5z8qe3' /* جولة برية */,
              ),
              Icons.forest_outlined),
          ChipData(
              FFLocalizations.of(context).getText(
                '439uyrfw' /* جولة بحرية */,
              ),
              Icons.support),
          ChipData(
              FFLocalizations.of(context).getText(
                'voqwzoqt' /* فنادق */,
              ),
              Icons.hotel_sharp)
        ],
        onChanged: (val) =>
            safeSetState(() => _model.choiceChipsValues = val),
        selectedChipStyle: ChipStyle(
          backgroundColor: colors.primary,
          textStyle: typography.labelMedium.copyWith(color: colors.onPrimary),
          iconColor: colors.onPrimary,
          iconSize: DsIcons.xs,
          elevation: 2.0,
          borderRadius: DsRadius.pill,
        ),
        unselectedChipStyle: ChipStyle(
          backgroundColor: colors.surfaceElevated,
          textStyle: typography.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
          iconColor: colors.iconMuted,
          iconSize: DsIcons.xs,
          elevation: 0.0,
          borderRadius: DsRadius.pill,
        ),
        chipSpacing: DsSpacing.xs,
        rowSpacing: DsSpacing.xs,
        multiselect: true,
        initialized: _model.choiceChipsValues != null,
        alignment: WrapAlignment.start,
        controller: _model.choiceChipsValueController ??=
            FormFieldController<List<String>>(
          [
            FFLocalizations.of(context).getText(
              'gyagpikr' /* معالم سياحية */,
            )
          ],
        ),
        wrapped: false,
      ),
    );
  }

  Widget _buildLandmarksList(BuildContext context) {
    return StreamBuilder<List<MkanRecord>>(
      stream: queryMkanRecord(
        queryBuilder: (mkanRecord) => mkanRecord
            .where(
              'acctev',
              isEqualTo: true,
            )
            .where(
              'id_vill',
              isEqualTo: FFAppState().villa,
            )
            .whereIn('tsnef', _model.choiceChipsValues),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const Center(child: DsLoading(size: 50.0));
        }
        List<MkanRecord> listViewMkanRecordList = snapshot.data!;

        if (listViewMkanRecordList.isEmpty) {
          return DsEmptyState(
            icon: Icons.travel_explore_outlined,
            title: FFLocalizations.of(context).getText(
              '6tfjgk3j' /* Tourist landmarks */,
            ),
            message: FFAppState().naimvillatext,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: DsSpacing.xxl),
          primary: false,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: listViewMkanRecordList.length,
          itemBuilder: (context, listViewIndex) {
            final listViewMkanRecord = listViewMkanRecordList[listViewIndex];
            return Padding(
              padding: TouryLayout.landmarkCardPadding(context),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: TouryLayout.landmarkListCardWidth(context),
                  child: DsFadeSlide(
                    delay: Duration(
                      milliseconds: 40 * listViewIndex.clamp(0, 6),
                    ),
                    child: _LandmarkCard(
                      record: listViewMkanRecord,
                      name: touryMkanName(context, listViewMkanRecord),
                      addLabel: FFLocalizations.of(context).getText(
                        '4oufujx8' /* Add */,
                      ),
                      onTap: () => _openPlaceDetails(listViewMkanRecord),
                      onAdd: () => _addLandmarkToCart(listViewMkanRecord),
                    ),
                  ),
                ),
              ),
            );
          },
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
        caption: 'browsing_now'.tr(namedArgs: {
          'country': FFAppState().naimdolh,
        }),
        countryName: FFAppState().naimdolh,
        changeLabel: FFLocalizations.of(context).getText(
          '11fc8581' /* Change country */,
        ),
        onChangeCountry: () async {
          context.pushNamed(AldolWidget.routeName);
        },
      ),
      items: [
        _DrawerActionTile(
          icon: Icons.my_location_rounded,
          iconTone: _DrawerTone.danger,
          title: FFLocalizations.of(context).getText(
            'ftt0b0de' /* Start */,
          ),
          subtitle: FFLocalizations.of(context).getText(
            'avgr2b4n' /* Start from your current locati... */,
          ),
          onTap: () async {
            context.pushNamed(
              DemoDWidget.routeName,
              queryParameters: {
                'isSpeed': serializeParam(
                  true,
                  ParamType.bool,
                ),
              }.withoutNulls,
            );
          },
        ),
        _DrawerActionTile(
          icon: DsIcons.location,
          title: FFAppState().naimvillatext,
          subtitle: FFLocalizations.of(context).getText(
            'lunzyfz1' /* Change city */,
          ),
          onTap: () async {
            context.pushNamed(ListWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: DsIcons.map,
          title: valueOrDefault<String>(
            FFAppState().naimmdenh,
            'تغيير المنطقة',
          ),
          subtitle: FFLocalizations.of(context).getText(
            'c6rqjbsc' /* Change region */,
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
        if (FFAppState().ismapview == false)
          _DrawerActionTile(
            icon: Icons.map_outlined,
            title: FFLocalizations.of(context).getText(
              'yhv8nku7' /* Browse the map */,
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
              'v529zppv' /* View list */,
            ),
            subtitle: 'places_in_city'.tr(namedArgs: {
              'city': FFAppState().naimvillatext,
            }),
            onTap: () async {
              context.pushNamed(
                ListViCopy2Widget.routeName,
                queryParameters: {
                  'cite': serializeParam(
                    FFAppState().vil,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              );

              FFAppState().ismapview = false;
              safeSetState(() {});
            },
          ),
        _DrawerActionTile(
          icon: Icons.playlist_add_check_rounded,
          title: FFLocalizations.of(context).getText(
            'lqgzkrss' /* Added destinations */,
          ),
          badge: FFAppState().addcart.toString(),
          onTap: () async {
            context.pushNamed(Checkout66Widget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: DsIcons.bookings,
          title: FFLocalizations.of(context).getText(
            '1fqh0c0y' /* My bookings */,
          ),
          subtitle: FFLocalizations.of(context).getText(
            'alakjsl4' /* Booking list. */,
          ),
          onTap: () async {
            context.pushNamed(List22TaskOverviewResponsiveWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.add_location_alt_outlined,
          title: FFLocalizations.of(context).getText(
            'onoctgh0' /* Suggest a Place */,
          ),
          subtitle: FFLocalizations.of(context).getText(
            'b2xzavy7' /* Add a Special Place */,
          ),
          onTap: () async {
            context.pushNamed(NewPlaceWidget.routeName);
          },
        ),
        _DrawerActionTile(
          icon: Icons.wb_sunny_outlined,
          iconTone: _DrawerTone.warning,
          title: FFLocalizations.of(context).getText(
            '712c5a4b' /* general information */,
          ),
          subtitle: FFAppState().naimvillatext,
          onTap: () async {
            context.pushNamed(AbutMdenhWidget.routeName);
          },
        ),
        FutureBuilder<int>(
          future: queryChatRecordCount(
            queryBuilder: (chatRecord) => chatRecord.where(
              'participants',
              arrayContains: currentUserReference,
            ),
          ),
          builder: (context, snapshot) {
            // Customize what your widget looks like when it's loading.
            if (!snapshot.hasData) {
              return const Center(child: DsLoading(size: 50.0));
            }
            int listTileCount = snapshot.data!;

            return _DrawerActionTile(
              icon: Icons.mail_outline_rounded,
              title: FFLocalizations.of(context).getText(
                'e4ayfj5q' /* رسائل جديدة */,
              ),
              badge: valueOrDefault<String>(
                listTileCount.toString(),
                '0',
              ),
              onTap: () async {
                context.pushNamed(List22TaskOverviewResponsiveWidget.routeName);
              },
            );
          },
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
            'svm7to1m' /* Settings */,
          ),
          onTap: () async {
            context.pushNamed(Profile05Widget.routeName);
          },
        ),
        DsDrawerItem(
          icon: Icons.help_outline_rounded,
          label: FFLocalizations.of(context).getText(
            'oe7s38pa' /* Help */,
          ),
          onTap: () async {
            context.pushNamed(SupportWidget.routeName);
          },
        ),
      ],
      footer: _DrawerLogoutButton(
        label: FFLocalizations.of(context).getText(
          'pbuuv9pc' /* Log Out */,
        ),
        onTap: () => _logout(context),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Landmark card
// -----------------------------------------------------------------------------

class _LandmarkCard extends StatelessWidget {
  const _LandmarkCard({
    required this.record,
    required this.name,
    required this.addLabel,
    required this.onTap,
    required this.onAdd,
  });

  final MkanRecord record;
  final String name;
  final String addLabel;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      padding: EdgeInsets.zero,
      elevated: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: record.reference.id,
            transitionOnUserGestures: true,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: DsRadius.lgRadius),
              child: TouryNetworkImage.fromPlaceImages(
                img1: record.img1,
                img2: record.img2,
                img3: record.img3,
                documentId: record.reference.id,
                placeName: name,
                latitude: record.location?.latitude,
                longitude: record.location?.longitude,
                width: double.infinity,
                height: TouryLayout.cardImageHeight(context),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: typography.titleMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xxs),
                      RatingBarIndicator(
                        itemBuilder: (context, index) => Icon(
                          Icons.star_rounded,
                          color: colors.warning,
                        ),
                        direction: Axis.horizontal,
                        rating: 4.0,
                        unratedColor: colors.divider,
                        itemCount: 5,
                        itemSize: 14.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                DsButton.primary(
                  size: DsButtonSize.sm,
                  icon: Icons.add_rounded,
                  label: addLabel,
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Drawer pieces
// -----------------------------------------------------------------------------

enum _DrawerTone { primary, danger, warning }

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
    this.iconTone = _DrawerTone.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final _DrawerTone iconTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final Color accent;
    switch (iconTone) {
      case _DrawerTone.danger:
        accent = colors.error;
      case _DrawerTone.warning:
        accent = colors.warning;
      case _DrawerTone.primary:
        accent = colors.primary;
    }

    return ListTile(
      leading: Container(
        width: DsConstants.avatarSm,
        height: DsConstants.avatarSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: DsRadius.small,
        ),
        child: Icon(icon, size: DsIcons.sm, color: accent),
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
