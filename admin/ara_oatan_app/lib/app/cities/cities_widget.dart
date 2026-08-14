import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/core/toury_city_display_order.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_geo_i18n.dart';
import '/core/toury_image.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'cities_model.dart';

export 'cities_model.dart';

/// قائمة المدن
class CitiesWidget extends StatefulWidget {
  const CitiesWidget({
    super.key,
    required this.dol,
    required this.textstre,
  });

  final DocumentReference? dol;
  final String? textstre;

  static String routeName = 'Cities';
  static String routePath = '/cities';

  @override
  State<CitiesWidget> createState() => _CitiesWidgetState();
}

class _CitiesWidgetState extends State<CitiesWidget> {
  late CitiesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CitiesModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dsTheme =
        brightness == Brightness.dark ? DsTheme.dark() : DsTheme.light();

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
              value: brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: Scaffold(
                key: scaffoldKey,
                backgroundColor: colors.scaffold,
                appBar: DsAppBar(
                  title: FFLocalizations.of(context).getText(
                    'k9bjsxlx' /* saudi */,
                  ),
                  automaticallyImplyLeading: false,
                  leading: DsIconButton(
                    icon: DsIcons.back,
                    onPressed: () => context.safePop(),
                  ),
                ),
                body: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DsFadeSlide(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DsSpacing.md,
                            DsSpacing.sm,
                            DsSpacing.md,
                            DsSpacing.md,
                          ),
                          child: _CitiesHero(
                            countryRef: widget.dol,
                            title: valueOrDefault<String>(widget.textstre, '-'),
                            subtitle: FFLocalizations.of(context).getText(
                              '0byfhxm5' /* The Qibla for Islam and Muslim... */,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DsSectionHeader(
                        title: FFLocalizations.of(context).getText(
                          '1qtnw2om' /* List of regions */,
                        ),
                      ),
                    ),
                    _CitiesListSliver(countryRef: widget.dol),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: DsSpacing.huge),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CitiesHero extends StatelessWidget {
  const _CitiesHero({
    required this.countryRef,
    required this.title,
    required this.subtitle,
  });

  final DocumentReference? countryRef;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      height: DsConstants.heroHeight,
      decoration: BoxDecoration(
        borderRadius: DsRadius.extraLarge,
        boxShadow: DsShadows.card(
          dark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (countryRef != null)
            TouryCountryHeroBanner(
              countryRef: countryRef!,
              height: DsConstants.heroHeight,
            )
          else
            ColoredBox(color: colors.surfaceElevated),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.scrim.withValues(alpha: 0.2),
                  colors.scrim.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: typography.headlineMedium.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: DsSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodySmall.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.85),
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

class _CitiesListSliver extends StatelessWidget {
  const _CitiesListSliver({required this.countryRef});

  final DocumentReference? countryRef;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return StreamBuilder<List<CitiesRecord>>(
      stream: TouryFirestoreCache.citiesStream(
        cacheKey: 'country:${countryRef?.path ?? 'all'}',
        queryBuilder: (citiesRecord) => citiesRecord.where(Filter.or(
          Filter('dolh', isEqualTo: countryRef),
          Filter('acctev', isEqualTo: true),
        )),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(DsSpacing.xl),
              child: DsLoading(),
            ),
          );
        }

        final cities = TouryCityDisplayOrder.sort(snapshot.data!);
        if (cities.isEmpty) {
          return SliverToBoxAdapter(
            child: DsEmptyState(
              title: FFLocalizations.of(context).getText(
                '1qtnw2om' /* List of regions */,
              ),
              icon: DsIcons.location,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          sliver: SliverList.separated(
            itemCount: cities.length,
            separatorBuilder: (_, __) => const SizedBox(height: DsSpacing.md),
            itemBuilder: (context, index) {
              final city = cities[index];
              return DsFadeSlide(
                delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                child: DsCard(
                  elevated: true,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: DsRadius.lgRadius,
                        ),
                        child: TouryNetworkImage(
                          url: city.img,
                          documentId: city.reference.id,
                          placeName: touryCityName(context, city),
                          width: double.infinity,
                          height: DsConstants.cardImageHeight,
                          fit: BoxFit.cover,
                          fallbackAsset: kTouryImageFallback,
                          useBrandedFallback: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(DsSpacing.md),
                        child: Column(
                          children: [
                            Text(
                              touryCityName(context, city),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: typography.titleMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '7vrn6mb4' /* Number of destinations:  */,
                                  ),
                                  style: typography.labelSmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                TouryCityDestinationCount(
                                  cityRef: city.reference,
                                  style: typography.labelSmall.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: DsSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: const BorderRadius.vertical(
                            bottom: DsRadius.lgRadius,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          FFLocalizations.of(context).getText(
                            '8izo3c5y' /* Specify the region */,
                          ),
                          style: typography.labelLarge.copyWith(
                            color: colors.onPrimary,
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
      },
    );
  }
}
