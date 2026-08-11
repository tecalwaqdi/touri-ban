import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_geo_content_i18n.dart';
import '/core/toury_image.dart';
import '/core/toury_location_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'l_i_s_t_countries_model.dart';

export 'l_i_s_t_countries_model.dart';

class LISTCountriesWidget extends StatefulWidget {
  const LISTCountriesWidget({super.key});

  static String routeName = 'LIST_countries';
  static String routePath = '/lISTCountries';

  @override
  State<LISTCountriesWidget> createState() => _LISTCountriesWidgetState();
}

class _LISTCountriesWidgetState extends State<LISTCountriesWidget> {
  late LISTCountriesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LISTCountriesModel());

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
          country.osf,
          ParamType.String,
        ),
        'imgDolh': serializeParam(
          country.img,
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  Widget _buildCountriesSliver(BuildContext context) {
    return StreamBuilder<List<CountriesRecord>>(
      stream: TouryFirestoreCache.countriesStream(
        cacheKey: 'active-ordered',
        queryBuilder: (countriesRecord) => countriesRecord
            .where(
              'acctev',
              isEqualTo: true,
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
              title: FFLocalizations.of(context).getText(
                'njk06e5q' /* Select the country */,
              ),
              icon: DsIcons.map,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          sliver: SliverList.separated(
            itemCount: countries.length,
            separatorBuilder: (_, __) => const SizedBox(height: DsSpacing.md),
            itemBuilder: (context, index) {
              final country = countries[index];
              return DsFadeSlide(
                delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                child: _CountryCard(
                  title: touryCountryDisplayName(context, country),
                  description: country.osf.maybeHandleOverflow(
                    maxChars: 70,
                    replacement: '…',
                  ),
                  imageUrl: country.img,
                  documentId: country.reference.id,
                  onTap: () => _openCountry(country),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: FFLocalizations.of(context).getText(
                  'njk06e5q' /* Select the country */,
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
                  const SliverToBoxAdapter(
                    child: DsFadeSlide(child: _WelcomeBanner()),
                  ),
                  SliverToBoxAdapter(
                    child: DsSectionHeader(
                      title: FFLocalizations.of(context).getText(
                        'njk06e5q' /* Select the country */,
                      ),
                    ),
                  ),
                  _buildCountriesSliver(context),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DsSpacing.huge),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.lg,
        DsSpacing.xl,
        DsSpacing.lg,
        DsSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryStrong],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DsRadius.xl),
        ),
        boxShadow: DsShadows.card(dark: context.dsIsDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: DsConstants.avatarLg,
            height: DsConstants.avatarLg,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              DsIcons.map,
              size: DsIcons.lg,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          Text(
            FFLocalizations.of(context).getText(
              'bbumradi' /* Welcome to the Arra Watan app */,
            ),
            textAlign: TextAlign.center,
            style: typography.headlineSmall.copyWith(color: colors.onPrimary),
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            FFLocalizations.of(context).getText(
              'moydcuyp' /* first global saudi tourist tax... */,
            ),
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(
              color: colors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.documentId,
    required this.onTap,
  });

  final String title;
  final String description;
  final String? imageUrl;
  final String documentId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return DsCard(
      onTap: onTap,
      elevated: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: DsRadius.lgRadius),
            child: Container(
              color: colors.primarySoft,
              height: DsConstants.cardImageHeight,
              alignment: Alignment.center,
              child: TouryNetworkImage(
                url: imageUrl,
                documentId: documentId,
                placeName: title,
                width: double.infinity,
                height: DsConstants.cardImageHeight,
                fit: BoxFit.contain,
                fallbackAsset: kTouryImageFallback,
                useBrandedFallback: true,
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
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: typography.titleLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: DsSpacing.xxs),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Container(
                  width: DsConstants.avatarSm,
                  height: DsConstants.avatarSm,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: DsShadows.primaryGlow(dark: context.dsIsDark),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: DsIcons.sm,
                    color: colors.onPrimary,
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
