import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/backend.dart';
import '/backend/gemini/gemini.dart';
import '/core/toury_car_i18n.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_image.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import 'car_model.dart';

export 'car_model.dart';

const double _kCarThumbWidth = DsConstants.carThumbWidth;
const double _kCarThumbHeight = DsConstants.carThumbHeight;
const int _kCarSkeletonCount = 4;

class CarWidget extends StatefulWidget {
  const CarWidget({super.key});

  static String routeName = 'car';
  static String routePath = '/car';

  @override
  State<CarWidget> createState() => _CarWidgetState();
}

class _CarWidgetState extends State<CarWidget> {
  late CarModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CarModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _minHoursLabel(int hours) {
    if (hours == 1) return 'ساعة واحدة';
    if (hours == 2) return 'ساعتان';
    return '$hours ساعات';
  }

  Future<void> _selectCar(TypeCarRecord record) async {
    final localizedName = touryTypeCarName(context, record);
    if (record.ishafelh == true) {
      FFAppState().tebycar = localizedName;
      FFAppState().typecarRev = record.reference;
      FFAppState().srtypecar = record.sr;
      FFAppState().totalsaatandcar = functions.total(record.sr, 8.0)!;
      FFAppState().notcar = touryTypeCarNote(context, record);
      FFAppState().saatcar = record.aglSaat;
      FFAppState().onsaahcar = record.sr;
      FFAppState().totalsaat = record.aglSaat;
      FFAppState().addhors = 0;
      FFAppState().TOTALmndob2 = 0;
      FFAppState().totalapp2 = 0;
      FFAppState().vat2 = 0;
      FFAppState().totalAllNow2 = 0;
      FFAppState().update(() {});
      FFAppState().TOTALmndob2 = functions.total(
        FFAppState().srtypecar,
        FFAppState().totalsaat.toDouble(),
      )!;
      FFAppState().totalapp2 = functions.vat(
        15.0,
        functions.total(
          FFAppState().srtypecar,
          FFAppState().totalsaat.toDouble(),
        ),
      )!;
      FFAppState().vat2 = functions.vat(
        15.0,
        functions.vat(
          15.0,
          functions.total(
            FFAppState().srtypecar,
            FFAppState().totalsaat.toDouble(),
          ),
        ),
      )!;
      FFAppState().totalAllNow2 =
          FFAppState().TOTALmndob2 + FFAppState().totalapp2 + FFAppState().vat2;
      safeSetState(() {});
      if (!mounted) return;
      touryOnCarSelected(context);
    } else {
      FFAppState().tebycar = localizedName;
      FFAppState().typecarRev = record.reference;
      FFAppState().srtypecar = record.sr;
      FFAppState().totalsaatandcar = functions.total(
        record.sr,
        FFAppState().cartPriceSummary.length.toDouble(),
      )!;
      FFAppState().saatcar = record.aglSaat;
      FFAppState().onsaahcar = record.sr;
      FFAppState().totalsaat = record.aglSaat;
      FFAppState().addhors = 0;
      safeSetState(() {});
      geminiGenerateText(
        context,
        'هل من المنطقي ان ينتقل السائح بسيارة بسرعة معقولة  من  ${FFAppState().villtextnow}إلى المدن${FFAppState().textallAlmdn}بـ${FFAppState().totalsaat.toString()}ساعاتإذا كانت  الرحلة اساسا تستغرق 0 ساعات ولايوجد سفر  أكتب فقط(  لايوجد ملاحظات على )الرحلة نتمنى لكم رحلة موفقة وسعيدة واذا كان الرحلة تتطلب السفر  اقترح على المستخدم ساعات معينة اكتب مختصر وواضح بالعربية والإنجليزية',
      ).then((generatedText) {
        if (!mounted || generatedText == null) return;
        safeSetState(() => _model.msegai2 = generatedText);
        FFAppState().msegAi = generatedText;
        FFAppState().update(() {});
      });

      if (!mounted) return;
      touryOnCarSelected(context);
    }
    safeSetState(() {});
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
                    '3ve8qodr' /* Choose the type of car. */,
                  ),
                  automaticallyImplyLeading: false,
                  leading: DsIconButton(
                    icon: DsIcons.back,
                    onPressed: () => context.pop(),
                  ),
                ),
                body: SafeArea(
                  child: StreamBuilder<List<TypeCarRecord>>(
                    stream: TouryFirestoreCache.typeCarStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return DsErrorState(
                          title: 'ux_car_list_error_title'.tr(),
                          message: 'ux_car_list_error_msg'.tr(),
                          retryLabel: 'ux_retry'.tr(),
                          onRetry: () {
                            TouryFirestoreCache.invalidateTypeCar();
                            safeSetState(() {});
                          },
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const _CarListSkeleton();
                      }

                      if (!snapshot.hasData) {
                        return const DsLoading();
                      }

                      final cars = snapshot.data!;
                      if (cars.isEmpty) {
                        return DsEmptyState(
                          title: 'ux_car_list_empty_title'.tr(),
                          message: 'ux_car_list_empty_msg'.tr(),
                          icon: DsIcons.car,
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          DsSpacing.md,
                          DsSpacing.sm,
                          DsSpacing.md,
                          DsSpacing.huge,
                        ),
                        cacheExtent: 480,
                        addRepaintBoundaries: true,
                        addAutomaticKeepAlives: false,
                        itemCount: cars.length + 1,
                        separatorBuilder: (_, index) => SizedBox(
                          height: index == 0 ? DsSpacing.md : DsSpacing.sm,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return DsFadeSlide(
                              child: DsInformationCard(
                                title: FFLocalizations.of(context).getText(
                                  '3ve8qodr' /* Choose the type of car. */,
                                ),
                                message: 'ux_car_list_hint'.tr(),
                                icon: DsIcons.car,
                              ),
                            );
                          }

                          final car = cars[index - 1];
                          final price = formatNumber(
                            car.sr,
                            formatType: FormatType.decimal,
                            decimalType: DecimalType.automatic,
                            currency: 'ر.س ',
                          );

                          return DsFadeSlide(
                            delay: Duration(
                              milliseconds: 40 * (index - 1).clamp(0, 8),
                            ),
                            child: _CarOptionCard(
                              title: touryTypeCarName(context, car),
                              imageUrl: car.img,
                              documentId: car.reference.id,
                              priceLabel: price,
                              perHourLabel: 'ux_per_hour'.tr(),
                              minHoursLabel:
                                  '${'ux_min_hours'.tr()}: ${_minHoursLabel(car.aglSaat)}',
                              onTap: () => _selectCar(car),
                            ),
                          );
                        },
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

class _CarOptionCard extends StatelessWidget {
  const _CarOptionCard({
    required this.title,
    required this.imageUrl,
    required this.documentId,
    required this.priceLabel,
    required this.perHourLabel,
    required this.minHoursLabel,
    required this.onTap,
  });

  final String title;
  final String? imageUrl;
  final String documentId;
  final String priceLabel;
  final String perHourLabel;
  final String minHoursLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return DsPressable(
      onTap: onTap,
      child: DsCard(
        elevated: true,
        padding: const EdgeInsets.all(DsSpacing.sm),
        child: Row(
          children: [
            Container(
              width: _kCarThumbWidth,
              height: _kCarThumbHeight,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: DsRadius.medium,
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.9),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: TouryNetworkImage(
                url: imageUrl,
                documentId: documentId,
                placeName: title,
                width: _kCarThumbWidth,
                height: _kCarThumbHeight,
                fit: BoxFit.cover,
                fallbackAsset: kTouryImageFallback,
                useBrandedFallback: true,
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xs),
                  Container(
                    padding: DsSpacing.chipPadding,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: DsRadius.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          priceLabel,
                          style: typography.labelLarge.copyWith(
                            color: colors.primaryStrong,
                          ),
                        ),
                        const SizedBox(width: DsSpacing.xxs),
                        Text(
                          '/ $perHourLabel',
                          style: typography.labelSmall.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: DsIcons.xs,
                        color: colors.iconMuted,
                      ),
                      const SizedBox(width: DsSpacing.xxs),
                      Expanded(
                        child: Text(
                          minHoursLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.xs),
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
    );
  }
}

class _CarListSkeleton extends StatelessWidget {
  const _CarListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.huge,
      ),
      itemCount: _kCarSkeletonCount,
      separatorBuilder: (_, __) => const SizedBox(height: DsSpacing.sm),
      itemBuilder: (context, index) => DsCard(
        padding: const EdgeInsets.all(DsSpacing.sm),
        child: Row(
          children: [
            DsShimmer(
              width: _kCarThumbWidth,
              height: _kCarThumbHeight,
              borderRadius: DsRadius.medium,
            ),
            const SizedBox(width: DsSpacing.sm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DsShimmer(height: DsSpacing.md),
                  SizedBox(height: DsSpacing.xs),
                  DsShimmer(
                    width: DsSpacing.colossal + DsSpacing.xl,
                    height: DsSpacing.sm,
                  ),
                  SizedBox(height: DsSpacing.xs),
                  DsShimmer(
                    width: DsSpacing.colossal + DsSpacing.huge,
                    height: DsSpacing.sm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
