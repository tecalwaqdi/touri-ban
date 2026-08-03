import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/backend/backend.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_geo_content_i18n.dart';
import '/core/toury_google_map_panel.dart';
import '/core/toury_location_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'citie2_model.dart';
export 'citie2_model.dart';

/// Height of the inline country map preview.
const double _kCountryMapHeight = DsConstants.heroHeightLg;

/// قائمة المدن
class Citie2Widget extends StatefulWidget {
  const Citie2Widget({
    super.key,
    required this.coun,
    this.naim,
    this.osfdolh,
    this.idcit,
    this.imgDolh,
  });

  final DocumentReference? coun;
  final String? naim;
  final String? osfdolh;
  final DocumentReference? idcit;
  final String? imgDolh;

  static String routeName = 'Citie2';
  static String routePath = '/citie2';

  @override
  State<Citie2Widget> createState() => _Citie2WidgetState();
}

class _Citie2WidgetState extends State<Citie2Widget> {
  late Citie2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _countryMapController =
      Completer<GoogleMapController>();
  DocumentReference? _activeCountryRef;
  String? _activeCountryName;
  String? _activeCountryImg;
  String? _activeCountryIso;

  ThemeData _dsThemeFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? DsTheme.dark()
          : DsTheme.light();

  double _countryMapZoom(CountriesRecord country) {
    final iso = TouryCountryRegistry.normalizeIso(country.isoCode) ??
        TouryCountryRegistry.normalizeIso(country.reference.id);
    final sw = country.boundsSw;
    final ne = country.boundsNe;
    if (sw != null && ne != null) {
      final latSpan = (ne.latitude - sw.latitude).abs();
      final lngSpan = (ne.longitude - sw.longitude).abs();
      final span = latSpan > lngSpan ? latSpan : lngSpan;
      if (span > 60) return 2.2;
      if (span > 30) return 2.8;
      if (span > 15) return 3.4;
      if (span > 8) return 4.2;
      if (span > 4) return 5;
      return 6;
    }
    return TouryCountryRegistry.mapZoomForIso(iso);
  }

  LatLng? _resolveCountryMapCenter(CountriesRecord country) {
    if (country.geoCenter != null) return country.geoCenter;
    final iso = TouryCountryRegistry.normalizeIso(country.isoCode) ??
        TouryCountryRegistry.normalizeIso(country.reference.id);
    return TouryCountryRegistry.mapCenterForIso(iso);
  }

  Future<void> _openCountryPicker() async {
    final countries = await queryCountriesRecordOnce(
      queryBuilder: (q) => q.where('acctev', isEqualTo: true).orderBy('naim'),
    );
    // Deduplicate by ISO so country_kg + kyrgyzstan don't both appear.
    final seenIso = <String>{};
    final unique = <CountriesRecord>[];
    for (final c in countries) {
      final iso = TouryCountryRegistry.normalizeIso(c.isoCode) ??
          TouryCountryRegistry.normalizeIso(c.reference.id) ??
          c.reference.id;
      final preferred = TouryCountryRegistry.preferredCountryDocId(iso);
      if (preferred != null && c.reference.id != preferred) {
        // Keep preferred id when present later; skip non-preferred duplicates.
        final hasPreferred =
            countries.any((x) => x.reference.id == preferred);
        if (hasPreferred) continue;
      }
      if (seenIso.contains(iso)) continue;
      seenIso.add(iso);
      unique.add(c);
    }
    unique.sort((a, b) => touryCountryDisplayName(context, a)
        .toLowerCase()
        .compareTo(touryCountryDisplayName(context, b).toLowerCase()));

    if (!mounted) return;
    // Overlay routes are pushed on the root navigator, so they never inherit
    // the page-level Theme — hand them the DS theme explicitly.
    final sheetColors = context.dsIsDark ? DsColors.dark : DsColors.light;
    final selected = await showModalBottomSheet<CountriesRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: DsRadius.xlRadius),
      ),
      builder: (sheetContext) => Theme(
        data: _dsThemeFor(sheetContext),
        child: _CountryPickerSheet(countries: unique),
      ),
    );

    if (selected == null || !mounted) return;
    TouryLocationService.applyManualCountry(selected);
    _countryMapController = Completer<GoogleMapController>();
    safeSetState(() {
      _activeCountryRef = selected.reference;
      _activeCountryName = touryCountryDisplayName(context, selected);
      _activeCountryImg = selected.img;
      _activeCountryIso = TouryCountryRegistry.normalizeIso(selected.isoCode) ??
          TouryCountryRegistry.normalizeIso(selected.reference.id);
    });
  }

  Future<void> _selectRegion(CitiesRecord columnCitiesRecord) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (alertDialogContext) {
            return Theme(
              data: _dsThemeFor(alertDialogContext),
              child: Builder(
                builder: (dialogContext) {
                  final colors = dialogContext.dsColors;
                  final typography = dialogContext.dsTypography;
                  return WebViewAware(
                    child: AlertDialog(
                      backgroundColor: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: DsRadius.extraLarge,
                      ),
                      title: Text(
                        'select_region_title'.tr(),
                        style: typography.headlineSmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      content: Text(
                        'select_region_msg'.tr(),
                        style: typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      actionsPadding: const EdgeInsets.fromLTRB(
                        DsSpacing.md,
                        0,
                        DsSpacing.md,
                        DsSpacing.md,
                      ),
                      actions: [
                        DsButton.text(
                          label: 'dialog_no'.tr(),
                          onPressed: () =>
                              Navigator.pop(alertDialogContext, false),
                        ),
                        DsButton.primary(
                          label: 'dialog_yes'.tr(),
                          onPressed: () =>
                              Navigator.pop(alertDialogContext, true),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ) ??
        false;
    if (!confirmed || !mounted) return;

    FFAppState().update(() {
      FFAppState().mdenh = columnCitiesRecord.reference;
      FFAppState().naimmdenh = touryCityName(context, columnCitiesRecord);
      // Village is chosen on the next screen.
      // Do not seed villa from city.vil (often null
      // for KG/RU/UZ regions).
      FFAppState().villa = null;
      FFAppState().vil = null;
      FFAppState().villnow = null;
      FFAppState().naimvillatext = '';
      FFAppState().villtextnow = '';
      FFAppState().mapNEW = null;
      FFAppState().ismapview = false;
    });

    if (!mounted) return;
    context.pushNamed(ListWidget.routeName);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Citie2Model());
    _activeCountryRef = widget.coun;
    _activeCountryName = widget.naim;
    _activeCountryImg = widget.imgDolh;
    _activeCountryIso = TouryCountryRegistry.normalizeIso(widget.coun?.id);

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
                  title: "Select region / city".tr(),
                  automaticallyImplyLeading: false,
                  leading: DsIconButton(
                    icon: DsIcons.back,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    // LEFT (MENU)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: DsSpacing.xs,
                      ),
                      child: DsIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        size: DsIcons.sm,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: TouryAdaptiveScope(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DsFadeSlide(child: _buildCountryHero(context)),
                          if (_activeCountryRef != null)
                            DsFadeSlide(
                              delay: DsDurations.fast,
                              child: _buildCountryMapSection(context),
                            ),
                          const SizedBox(height: DsSpacing.xl),
                          DsSectionHeader(title: "List of regions".tr()),
                          const SizedBox(height: DsSpacing.xs),
                          _buildRegionsSection(context),
                          const SizedBox(height: DsSpacing.massive),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountryHero(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;
    final heroHeight = TouryLayout.countryHeroHeight(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.md,
        DsSpacing.md,
        0,
      ),
      child: DsPressable(
        onTap: _openCountryPicker,
        child: Container(
          width: double.infinity,
          height: heroHeight,
          decoration: BoxDecoration(
            borderRadius: DsRadius.extraLarge,
            boxShadow: DsShadows.card(dark: isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_activeCountryRef != null)
                TouryCountryHeroBanner(
                  countryRef: _activeCountryRef!,
                  height: heroHeight,
                )
              else
                TouryNetworkImage(
                  url: _activeCountryImg ?? widget.imgDolh,
                  width: double.infinity,
                  height: heroHeight,
                  fit: BoxFit.cover,
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.scrim.withValues(alpha: 0.25),
                      colors.scrim.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DsSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      valueOrDefault<String>(
                        _activeCountryName ?? widget.naim,
                        '-',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.headlineSmall.copyWith(
                        color: DsNeutralScale.shade0,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.sm,
                        vertical: DsSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: DsNeutralScale.shade0.withValues(alpha: 0.16),
                        borderRadius: DsRadius.pill,
                        border: Border.all(
                          color: DsNeutralScale.shade0.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'tap_to_change_country'.tr(),
                            style: typography.labelMedium.copyWith(
                              color: DsNeutralScale.shade0,
                            ),
                          ),
                          const SizedBox(width: DsSpacing.xxs),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: DsNeutralScale.shade0,
                            size: DsIcons.sm,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryMapSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsSectionHeader(title: 'country_map'.tr()),
          const SizedBox(height: DsSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
            child: FutureBuilder<CountriesRecord>(
              future: CountriesRecord.getDocumentOnce(_activeCountryRef!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return DsCard(
                    elevated: true,
                    child: SizedBox(
                      height: _kCountryMapHeight,
                      child: DsLoading(message: 'loading_country_map'.tr()),
                    ),
                  );
                }
                final country = snapshot.data!;
                final center = _resolveCountryMapCenter(country);
                final iso =
                    TouryCountryRegistry.normalizeIso(country.isoCode) ??
                        TouryCountryRegistry.normalizeIso(
                            country.reference.id) ??
                        _activeCountryIso;
                if (center == null) {
                  return DsInformationCard(
                    title: 'country_map'.tr(),
                    message: 'country_map_missing_center'.tr(),
                    icon: DsIcons.map,
                    tone: DsInfoTone.warning,
                  );
                }
                return DsCard(
                  padding: EdgeInsets.zero,
                  elevated: true,
                  child: ClipRRect(
                    borderRadius: DsRadius.large,
                    child: TouryMapPanel(
                      key: ValueKey(
                          'country-map-$iso-${country.reference.id}'),
                      controller: _countryMapController,
                      initialLocation: center,
                      countryIso2: iso,
                      height: _kCountryMapHeight,
                      initialZoom: _countryMapZoom(country),
                      showCenterPin: false,
                      showMyLocation: false,
                      borderRadius: DsRadius.lg,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionsSection(BuildContext context) {
    if (_activeCountryRef == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.xl),
        child: DsEmptyState(
          title: 'select_country_manual'.tr(),
          icon: DsIcons.location,
          action: DsButton.primary(
            label: 'search_country'.tr(),
            icon: DsIcons.search,
            onPressed: _openCountryPicker,
          ),
        ),
      );
    }

    return StreamBuilder<List<CitiesRecord>>(
      stream: queryCitiesRecord(
        queryBuilder: (citiesRecord) {
          final refs =
              TouryCountryRegistry.regionCountryRefs(_activeCountryRef!);
          // Avoid orderBy('sorting'): KG/RU/UZ region docs may
          // omit that field and Firestore would exclude them.
          return citiesRecord
              .whereIn('dolh', refs)
              .where('acctev', isEqualTo: true);
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: DsSpacing.xl),
            child: DsErrorState(
              title: 'regions_load_error'.tr(),
              retryLabel: 'retry'.tr(),
              onRetry: () => safeSetState(() {}),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: DsSpacing.xxxl),
            child: DsLoading(message: 'loading_regions'.tr()),
          );
        }
        List<CitiesRecord> columnCitiesRecordList = snapshot.data!;
        columnCitiesRecordList = List<CitiesRecord>.from(columnCitiesRecordList)
          ..sort((a, b) {
            final bySort = a.sorting.compareTo(b.sorting);
            if (bySort != 0) return bySort;
            return touryCityName(context, a).toLowerCase().compareTo(
                  touryCityName(context, b).toLowerCase(),
                );
          });
        final seen = <String>{};
        columnCitiesRecordList = columnCitiesRecordList.where((r) {
          final key = r.naim.trim().toLowerCase();
          if (key.isEmpty) return true;
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();
        if (columnCitiesRecordList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: DsSpacing.xl),
            child: DsEmptyState(
              title: 'regions_empty'.tr(),
              icon: DsIcons.location,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children:
                List.generate(columnCitiesRecordList.length, (columnIndex) {
              final columnCitiesRecord = columnCitiesRecordList[columnIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                child: DsFadeSlide(
                  delay: Duration(
                    milliseconds: 40 * columnIndex.clamp(0, 8),
                  ),
                  child: _RegionCard(
                    record: columnCitiesRecord,
                    onTap: () => _selectRegion(columnCitiesRecord),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Region card — image, name, destination count and a primary CTA footer.
class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.record,
    required this.onTap,
  });

  final CitiesRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final name = touryCityName(context, record);

    return DsPressable(
      onTap: onTap,
      child: DsCard(
        padding: EdgeInsets.zero,
        elevated: true,
        child: ClipRRect(
          borderRadius: DsRadius.large,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TouryNetworkImage(
                url: record.img,
                documentId: record.reference.id,
                placeName: name,
                width: double.infinity,
                height: TouryLayout.cardImageHeight(context),
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(DsSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xxs),
                    FutureBuilder<int>(
                      future: TouryFirestoreCache.mkanCount(
                        cacheKey: 'city:${record.reference.path}',
                        queryBuilder: (mkanRecord) => mkanRecord
                            .where(
                              'id_cit',
                              isEqualTo: record.reference,
                            )
                            .where(
                              'acctev',
                              isEqualTo: true,
                            ),
                      ),
                      builder: (context, snapshot) {
                        // Customize what your widget looks like when it's loading.
                        if (!snapshot.hasData) {
                          return const DsShimmer(
                            width: DsSpacing.colossal + DsSpacing.xxxl,
                            height: DsSpacing.md,
                          );
                        }
                        int rowCount = snapshot.data!;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              DsIcons.location,
                              size: DsIcons.xs,
                              color: colors.primary,
                            ),
                            const SizedBox(width: DsSpacing.xxs),
                            Flexible(
                              child: RichText(
                                textScaler: MediaQuery.of(context).textScaler,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Number of destinations:".tr(),
                                      style: typography.labelMedium.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' $rowCount',
                                      style: typography.labelMedium.copyWith(
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                  style: typography.labelMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: DsConstants.buttonHeightMd,
                alignment: AlignmentDirectional.center,
                color: colors.primary,
                child: Text(
                  "Specify the region".tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.labelLarge.copyWith(
                    color: colors.onPrimary,
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

/// Searchable country list rendered inside the modal bottom sheet.
///
/// Pops the selected [CountriesRecord] back to `_openCountryPicker`.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.countries});

  final List<CountriesRecord> countries;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.countries.where((c) {
      if (_filter.trim().isEmpty) return true;
      final q = _filter.toLowerCase();
      final name = touryCountryDisplayName(context, c).toLowerCase();
      final iso = (TouryCountryRegistry.normalizeIso(c.isoCode) ??
              TouryCountryRegistry.normalizeIso(c.reference.id) ??
              '')
          .toLowerCase();
      return name.contains(q) || iso.contains(q);
    }).toList();

    final colors = context.dsColors;
    final typography = context.dsTypography;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.md,
          DsSpacing.sm,
          DsSpacing.md,
          DsSpacing.md,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: DsSpacing.huge,
                  height: DsSpacing.xxs,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: DsRadius.pill,
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              Text(
                'select_country_manual'.tr(),
                textAlign: TextAlign.center,
                style: typography.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              DsSearchField(
                hint: 'search_country'.tr(),
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: DsSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? DsEmptyState(
                        title: 'search_country'.tr(),
                        icon: DsIcons.search,
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: DsSpacing.md),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: DsSpacing.xs),
                        itemBuilder: (context, index) {
                          final country = filtered[index];
                          final iso = TouryCountryRegistry.normalizeIso(
                                  country.isoCode) ??
                              TouryCountryRegistry.normalizeIso(
                                  country.reference.id) ??
                              '';
                          return _CountryPickerTile(
                            country: country,
                            iso: iso,
                            onTap: () => Navigator.pop(context, country),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerTile extends StatelessWidget {
  const _CountryPickerTile({
    required this.country,
    required this.iso,
    required this.onTap,
  });

  final CountriesRecord country;
  final String iso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsPressable(
      onTap: onTap,
      child: DsCard(
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.sm,
          vertical: DsSpacing.xs,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: DsRadius.pill,
              child: country.img.isNotEmpty
                  ? TouryNetworkImage(
                      url: country.img,
                      width: DsConstants.avatarMd,
                      height: DsConstants.avatarMd,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: DsConstants.avatarMd,
                      height: DsConstants.avatarMd,
                      alignment: Alignment.center,
                      color: colors.primarySoft,
                      child: Text(
                        iso,
                        style: typography.labelMedium.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    touryCountryDisplayName(context, country),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (iso.isNotEmpty)
                    Text(
                      iso,
                      style: typography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: DsIcons.md,
              color: colors.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}
