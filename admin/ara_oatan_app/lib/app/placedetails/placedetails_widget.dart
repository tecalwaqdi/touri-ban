import 'dart:ui' show ImageFilter;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;

import '/backend/backend.dart';
import '/core/toury_landmark_cart.dart';
import '/core/toury_landmark_filter.dart';
import '/core/toury_mkan_i18n.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'placedetails_model.dart';

export 'placedetails_model.dart';

/// تفاصيل المكان
class PlacedetailsWidget extends StatefulWidget {
  const PlacedetailsWidget({
    super.key,
    required this.mk,
    this.textnaim,
  });

  final DocumentReference? mk;
  final String? textnaim;

  static String routeName = 'Placedetails';
  static String routePath = '/placedetails';

  @override
  State<PlacedetailsWidget> createState() => _PlacedetailsWidgetState();
}

class _PlacedetailsWidgetState extends State<PlacedetailsWidget> {
  late PlacedetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlacedetailsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  PageController get _pageController =>
      _model.pageViewController ??= PageController(initialPage: 0);

  int _availableImages(MkanRecord record) => [
        record.img1,
        record.img2,
        record.img3,
      ].where((u) => u.trim().isNotEmpty).length.clamp(1, 3);

  Future<void> _addToTrip(
    BuildContext context,
    MkanRecord columnMkanRecord,
  ) async {
    touryAddLandmarkToCart(
      context: context,
      record: columnMkanRecord,
      onChanged: () => safeSetState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<FFAppState, int>(
      (s) => Object.hash(s.addcart, s.mkan.length),
    );

    final brightness = Theme.of(context).brightness;
    final dsTheme =
        brightness == Brightness.dark ? DsTheme.dark() : DsTheme.light();

    return Theme(
      data: dsTheme,
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

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
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  titleWidget: Text(
                    valueOrDefault<String>(
                      widget.textnaim,
                      'ux_step_details'.tr(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  leading: DsIconButton(
                    icon: DsIcons.back,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () async {
                      context.safePop();
                    },
                  ),
                ),
                body: StreamBuilder<MkanRecord>(
                  stream: MkanRecord.getDocument(widget.mk!),
                  builder: (context, snapshot) {
                    if (snapshot.hasError && !snapshot.hasData) {
                      return DsErrorState(
                        title: 'load_error_title'.tr(),
                        message: 'load_error_message'.tr(),
                        retryLabel: 'retry'.tr(),
                        onRetry: () => safeSetState(() {}),
                      );
                    }

                    // Customize what your widget looks like when it's loading.
                    if (!snapshot.hasData) {
                      return const Center(
                        child: DsLoading(size: DsIcons.xl),
                      );
                    }

                    final columnMkanRecord = snapshot.data!;

                    return TouryAdaptiveScope(
                      child: _buildContent(context, columnMkanRecord),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, MkanRecord record) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context, record),
          Transform.translate(
            offset: const Offset(0, -DsSpacing.xl),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
              child: DsFadeSlide(
                delay: DsDurations.fast,
                child: _buildDetailsCard(context, record),
              ),
            ),
          ),
          const SizedBox(height: DsSpacing.md),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, MkanRecord record) {
    final heroHeight = TouryLayout.detailHeroHeight(context);

    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: DsRadius.xlRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                onPageChanged: (_) => safeSetState(() {}),
                scrollDirection: Axis.horizontal,
                children: [
                  _heroImage(
                    context,
                    record,
                    url: record.img1,
                    alternateUrls: [record.img2, record.img3],
                    height: heroHeight,
                  ),
                  _heroImage(
                    context,
                    record,
                    url: record.img2,
                    alternateUrls: [record.img1, record.img3],
                    height: heroHeight,
                  ),
                  _heroImage(
                    context,
                    record,
                    url: record.img3,
                    alternateUrls: [record.img1, record.img2],
                    height: heroHeight,
                  ),
                ],
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: _HeroScrim()),
            ),
            PositionedDirectional(
              top: DsSpacing.sm,
              end: DsSpacing.md,
              child: DsFadeSlide(
                offset: const Offset(0.4, 0),
                child: _buildImageCounter(context, record),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: DsSpacing.huge,
              child: Center(child: _buildPageIndicator(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroImage(
    BuildContext context,
    MkanRecord record, {
    required String url,
    required List<String> alternateUrls,
    required double height,
  }) {
    return TouryNetworkImage(
      url: url,
      alternateUrls: alternateUrls,
      placeName: touryMkanName(context, record),
      documentId: record.reference.id,
      latitude: record.location?.latitude,
      longitude: record.location?.longitude,
      fallbackAsset: kTouryImageFallback,
      useBrandedFallback: true,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget _buildImageCounter(BuildContext context, MkanRecord record) {
    final typography = context.dsTypography;
    final total = _availableImages(record);

    return ClipRRect(
      borderRadius: DsRadius.pill,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: AnimatedContainer(
          duration: DsDurations.fast,
          curve: DsCurves.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm,
            vertical: DsSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: DsNeutralScale.shade900.withValues(alpha: 0.32),
            borderRadius: DsRadius.pill,
            border: Border.all(
              color: DsNeutralScale.shade0.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: DsIcons.xs,
                color: DsNeutralScale.shade0,
              ),
              const SizedBox(width: DsSpacing.xxs),
              Text(
                '${_model.pageViewCurrentIndex + 1} / $total',
                style: typography.labelMedium.copyWith(
                  color: DsNeutralScale.shade0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return smooth_page_indicator.SmoothPageIndicator(
      controller: _pageController,
      count: 3,
      axisDirection: Axis.horizontal,
      onDotClicked: (i) async {
        await _pageController.animateToPage(
          i,
          duration: DsDurations.slow,
          curve: DsCurves.emphasized,
        );
        safeSetState(() {});
      },
      effect: smooth_page_indicator.ExpandingDotsEffect(
        expansionFactor: 3.0,
        spacing: DsSpacing.xs,
        radius: DsRadius.full,
        dotWidth: DsSpacing.xs,
        dotHeight: DsSpacing.xxs,
        dotColor: DsNeutralScale.shade0.withValues(alpha: 0.45),
        activeDotColor: DsNeutralScale.shade0,
        paintStyle: PaintingStyle.fill,
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, MkanRecord record) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;

    final description = touryMkanDescription(context, record);
    final address = touryMkanAddress(context, record);
    final amenities = _buildAmenities(context, record);
    final alreadyAdded = touryLandmarkAlreadyInCart(record.reference);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: DsRadius.large,
        boxShadow: DsShadows.floating(dark: isDark),
      ),
      child: DsCard(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              touryMkanName(context, record),
              style: typography.headlineSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: DsSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DsIcon(
                    DsIcons.location,
                    size: DsIcons.sm,
                    color: colors.primary,
                  ),
                  const SizedBox(width: DsSpacing.xxs),
                  Expanded(
                    child: Text(
                      address,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: DsSpacing.md),
              ChipTheme(
                data: context.dsTheme.chipTheme.copyWith(
                  disabledColor: colors.primarySoft,
                ),
                child: Wrap(
                  spacing: DsSpacing.xs,
                  runSpacing: DsSpacing.xs,
                  children: amenities,
                ),
              ),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: DsSpacing.md),
              const DsDivider(),
              const SizedBox(height: DsSpacing.md),
              Text(
                FFLocalizations.of(context).getText(
                  'cbco6jcb' /* Description */,
                ),
                style: typography.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DsSpacing.xs),
              Text(
                description,
                style: typography.bodyLarge.copyWith(
                  color: colors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: DsSpacing.md),
            DsButton.primary(
              label: FFLocalizations.of(context).getText(
                'ci8fvgoc' /* Add */,
              ),
              icon: alreadyAdded ? DsIcons.success : DsIcons.add,
              size: DsButtonSize.md,
              expanded: true,
              onPressed: () async {
                await _addToTrip(context, record);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAmenities(BuildContext context, MkanRecord record) {
    return [
      if (record.ismsgd)
        _amenityChip(
          context,
          icon: Icons.meeting_room_outlined,
          label: FFLocalizations.of(context).getText(
            '70a6e617' /* Prayer room */,
          ),
        ),
      if (record.ishmam)
        _amenityChip(
          context,
          icon: Icons.bathtub_outlined,
          label: FFLocalizations.of(context).getText(
            'qzrnlkm8' /* Restroom */,
          ),
        ),
      if (record.isfood)
        _amenityChip(
          context,
          icon: Icons.restaurant_outlined,
          label: FFLocalizations.of(context).getText(
            'supsaupu' /* Restaurant */,
          ),
        ),
    ];
  }

  Widget _amenityChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return DsChip(
      label: label,
      leading: Icon(
        icon,
        size: DsIcons.xs,
        color: context.dsColors.primary,
      ),
    );
  }
}

/// Top-to-bottom scrim so overlay controls stay readable on bright photos.
class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45, 1.0],
          colors: [
            DsNeutralScale.shade900.withValues(alpha: 0.34),
            DsNeutralScale.shade900.withValues(alpha: 0.0),
            DsNeutralScale.shade900.withValues(alpha: 0.52),
          ],
        ),
      ),
    );
  }
}
