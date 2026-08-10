import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/core/toury_geo_content_i18n.dart';
import '/core/toury_geo_i18n.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'aldol_model.dart';

export 'aldol_model.dart';

class AldolWidget extends StatefulWidget {
  const AldolWidget({super.key});

  static String routeName = 'aldol';
  static String routePath = '/aldol';

  @override
  State<AldolWidget> createState() => _AldolWidgetState();
}

class _AldolWidgetState extends State<AldolWidget> {
  late AldolModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AldolModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _openCountry(CountriesRecord country) async {
    TouryLocationService.applyManualCountry(country);
    unawaited(TouryLocationService.refreshCache());
    safeSetState(() {});

    context.pushNamed(
      Citie2Widget.routeName,
      queryParameters: {
        'coun': serializeParam(
          country.reference,
          ParamType.DocumentReference,
        ),
        'naim': serializeParam(
          touryCountryDisplayName(context, country),
          ParamType.String,
        ),
        'osfdolh': serializeParam(
          touryCountryDescription(context, country),
          ParamType.String,
        ),
        'idcit': serializeParam(
          country.reference,
          ParamType.DocumentReference,
        ),
        'imgDolh': serializeParam(
          country.img,
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _openFeaturedCountry(CountriesRecord country) async {
    TouryLocationService.applyManualCountry(country);
    unawaited(TouryLocationService.refreshCache());
    safeSetState(() {});

    context.pushNamed(
      Citie2Widget.routeName,
      queryParameters: {
        'coun': serializeParam(
          country.reference,
          ParamType.DocumentReference,
        ),
        'naim': serializeParam(
          touryCountryDisplayName(context, country),
          ParamType.String,
        ),
        'osfdolh': serializeParam(
          touryCountryDescription(context, country),
          ParamType.String,
        ),
        'imgDolh': serializeParam(
          country.img,
          ParamType.String,
        ),
      }.withoutNulls,
    );
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
                  title: 'Welcome to the Arra Watan app'.tr(),
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  leading: DsIconButton(
                    icon: DsIcons.back,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => context.safePop(),
                  ),
                ),
                body: SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: DsFadeSlide(
                          child: _FeaturedCountrySection(
                            onOpen: _openFeaturedCountry,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: DsFadeSlide(
                          delay: DsDurations.fast,
                          child: DsSectionHeader(
                            title: 'Other'.tr(),
                            subtitle: null,
                          ),
                        ),
                      ),
                      _OtherCountriesSliver(onOpen: _openCountry),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: DsSpacing.huge),
                      ),
                    ],
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

class _FeaturedCountrySection extends StatelessWidget {
  const _FeaturedCountrySection({required this.onOpen});

  final Future<void> Function(CountriesRecord country) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return StreamBuilder<List<CountriesRecord>>(
      stream: TouryFirestoreCache.countriesStream(
        cacheKey: 'saudi-single',
        queryBuilder: (countriesRecord) => countriesRecord.where(
          'saudi',
          isEqualTo: true,
        ),
        singleRecord: true,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(DsSpacing.md),
            child: SizedBox(
              height: 200,
              child: DsLoading(),
            ),
          );
        }

        if (snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final country = snapshot.data!.first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            DsSpacing.sm,
            DsSpacing.md,
            DsSpacing.md,
          ),
          child: DsScaleFade(
            child: Container(
              width: double.infinity,
              height: 220,
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
                  Hero(
                    tag: 'country-hero-${country.reference.id}',
                    child: TouryNetworkImage(
                      url: country.img,
                      fit: BoxFit.cover,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.scrim.withValues(alpha: 0.15),
                          colors.scrim.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(DsSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'first global saudi tourist taxi app'.tr(),
                          textAlign: TextAlign.center,
                          style: typography.titleMedium.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        DsButton.primary(
                          label: 'Browse cities/counties in'.tr(),
                          expanded: true,
                          size: DsButtonSize.md,
                          icon: DsIcons.map,
                          onPressed: () => onOpen(country),
                        ),
                      ],
                    ),
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

class _OtherCountriesSliver extends StatelessWidget {
  const _OtherCountriesSliver({required this.onOpen});

  final Future<void> Function(CountriesRecord country) onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CountriesRecord>>(
      stream: TouryFirestoreCache.countriesStream(
        cacheKey: 'active-saudi',
        queryBuilder: (countriesRecord) => countriesRecord
            .where(
              'acctev',
              isEqualTo: true,
            )
            .where(
              'saudi',
              isEqualTo: false,
            )
            .orderBy('num_trteb'),
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

        final countries = snapshot.data!;
        if (countries.isEmpty) {
          return SliverToBoxAdapter(
            child: DsEmptyState(
              title: 'Other'.tr(),
              icon: DsIcons.location,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          sliver: SliverList.separated(
            itemCount: countries.length,
            separatorBuilder: (_, __) => const SizedBox(height: DsSpacing.sm),
            itemBuilder: (context, index) {
              final country = countries[index];
              return DsFadeSlide(
                delay: Duration(milliseconds: 40 * (index.clamp(0, 8))),
                child: _CountryListTile(
                  country: country,
                  onTap: () => onOpen(country),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CountryListTile extends StatelessWidget {
  const _CountryListTile({
    required this.country,
    required this.onTap,
  });

  final CountriesRecord country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsPressable(
      onTap: onTap,
      child: DsCard(
        elevated: true,
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.sm,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'country-list-${country.reference.id}',
              child: ClipRRect(
                borderRadius: DsRadius.pill,
                child: TouryNetworkImage(
                  url: country.img,
                  width: DsConstants.avatarMd,
                  height: DsConstants.avatarMd,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Text(
                touryCountryNameEnFallback(context, country),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.titleMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DsIcon(
              Icons.chevron_right_rounded,
              color: colors.primary,
              size: DsIcons.md,
            ),
          ],
        ),
      ),
    );
  }
}
