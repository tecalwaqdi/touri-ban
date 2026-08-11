import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_car_i18n.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_image.dart';
import '/core/toury_navigation.dart';
import '/core/toury_vehicle_catalog.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import 'list_car_model.dart';

export 'list_car_model.dart';

const double _kCarThumbWidth = DsConstants.carThumbWidth;
const double _kCarThumbHeight = DsConstants.carThumbHeight;
const int _kCarSkeletonCount = 4;

class ListCarWidget extends StatefulWidget {
  const ListCarWidget({super.key});

  static String routeName = 'ListCar';
  static String routePath = '/listCar';

  @override
  State<ListCarWidget> createState() => _ListCarWidgetState();
}

class _ListCarWidgetState extends State<ListCarWidget> {
  late ListCarModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListCarModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _minHoursLabel(int hours) {
    if (hours == 1) return 'ux_one_hour'.tr();
    if (hours == 2) return 'ux_two_hours'.tr();
    return 'ux_hours_count'.tr(namedArgs: {'count': '$hours'});
  }

  Future<void> _selectCar(TypeCarRecord record) async {
    try {
      final isHafelh = record.ishafelh == true;
      final appVatPercent = isHafelh ? 10.0 : 15.0;
      final sr = record.sr;
      final hours = record.aglSaat.toDouble();
      if (sr == null) {
        throw StateError('missing car price');
      }

      int lineTotal(int? price, double h) =>
          functions.total(price, h) ?? 0;

      int lineVat(double percent, int sum) {
        if (sum <= 0) return 0;
        return functions.vat(percent, sum) ?? 0;
      }

      final countryVatPercent = FFAppState().VatDolh > 0
          ? FFAppState().VatDolh.toDouble()
          : appVatPercent;
      final hoursTotal = lineTotal(sr, hours);
      final serviceVat = lineVat(appVatPercent, hoursTotal);
      final countryVat = lineVat(countryVatPercent, hoursTotal);

      FFAppState().tebycar = touryVehicleCategoryDisplayName(record, context);
      FFAppState().typecarRev = record.reference;
      FFAppState().srtypecar = record.sr;
      FFAppState().totalsaatandcar = lineTotal(sr, 8.0);
      FFAppState().notcar = touryTypeCarNote(context, record);
      FFAppState().saatcar = record.aglSaat;
      FFAppState().onsaahcar = record.sr;
      FFAppState().totalsaat = record.aglSaat;
      FFAppState().addhors = 0;
      FFAppState().TOTALmndob2 = 0;
      FFAppState().totalapp2 = 0;
      FFAppState().vat2 = 0;
      FFAppState().totalAllNow2 = 0;
      FFAppState().totalKsm = 0;
      FFAppState().UbKsm = record.totalKsmUb;
      FFAppState().NsbhKsm = record.nesbahkKsm;
      FFAppState().totalKsm2 = 0.0;
      FFAppState().totalmndob3 = lineTotal(FFAppState().srtypecar, hours).toDouble();

      FFAppState().TOTALmndob2 = hoursTotal;
      FFAppState().totalapp2 = serviceVat;
      FFAppState().vat2 = countryVat;
      FFAppState().totalAllNow2 =
          FFAppState().TOTALmndob2 + FFAppState().totalapp2 + FFAppState().vat2;

      FFAppState().TOTALmndob2 =
          FFAppState().TOTALmndob2 - FFAppState().totalapp2 - FFAppState().vat2;
      FFAppState().totalAllNow2 =
          FFAppState().TOTALmndob2 + FFAppState().totalapp2 + FFAppState().vat2;

      if (!isHafelh) {
        FFAppState().totalmndob3 = FFAppState().totalmndob3 -
            FFAppState().totalapp2 -
            FFAppState().vat2;
        FFAppState().totalAllnow3 = FFAppState().totalmndob3 +
            FFAppState().totalapp2 +
            FFAppState().vat2;
      } else {
        FFAppState().totalmndob3 = FFAppState().totalmndob3 +
            FFAppState().totalapp2 +
            FFAppState().vat2;
      }

      FFAppState().update(() {});

      if (!mounted) return;
      touryOnCarSelected(context);
    } catch (e, st) {
      debugPrint('_selectCar: $e\n$st');
      if (!mounted) return;
      TouryDialogs.showSnackBar(
        context,
        'ux_car_select_failed'.tr(),
        type: TouryMessageType.error,
      );
    }
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
                title: 'ux_list_of_cars'.tr(),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: SafeArea(
                child: StreamBuilder<List<TypeCarRecord>>(
                  stream: TouryFirestoreCache.typeCarStream(),
                  initialData: TouryFirestoreCache.peekTypeCars(),
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
                      return const _CarListSkeleton();
                    }

                    final sortedList = touryDeduplicateTypeCars(snapshot.data!);

                    if (sortedList.isEmpty) {
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
                      itemCount: sortedList.length + 1,
                      separatorBuilder: (_, index) => SizedBox(
                        height: index == 0 ? DsSpacing.md : DsSpacing.sm,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return DsFadeSlide(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DsInformationCard(
                                  title: 'ux_list_of_cars'.tr(),
                                  message: 'ux_car_list_hint'.tr(),
                                  icon: DsIcons.car,
                                ),
                                const SizedBox(height: DsSpacing.xs),
                                Text(
                                  'ux_cars_available_count'.tr(
                                    namedArgs: {
                                      'count': '${sortedList.length}',
                                    },
                                  ),
                                  textAlign: TextAlign.center,
                                  style: context.dsTypography.labelMedium
                                      .copyWith(color: colors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }

                        final car = sortedList[index - 1];
                        final price = formatNumber(
                          car.sr,
                          formatType: FormatType.decimal,
                          decimalType: DecimalType.automatic,
                          currency: '${FFAppState().RMZCurrency} ',
                        );

                        return DsFadeSlide(
                          delay: Duration(
                            milliseconds: 40 * (index - 1).clamp(0, 8),
                          ),
                          child: _CarOptionCard(
                            title: touryVehicleCategoryDisplayName(car, context),
                            localAsset: touryVehicleCategoryImage(car),
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
          );
        },
      ),
    );
  }
}

class _CarOptionCard extends StatelessWidget {
  const _CarOptionCard({
    required this.title,
    required this.localAsset,
    required this.imageUrl,
    required this.documentId,
    required this.priceLabel,
    required this.perHourLabel,
    required this.minHoursLabel,
    required this.onTap,
  });

  final String title;
  final String? localAsset;
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
              child: localAsset != null
                  ? ColoredBox(
                      color: colors.surface,
                      child: Image.asset(
                        localAsset!,
                        width: _kCarThumbWidth,
                        height: _kCarThumbHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    )
                  : TouryNetworkImage(
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
                        Flexible(
                          child: Text(
                            priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.labelLarge.copyWith(
                              color: colors.primaryStrong,
                            ),
                          ),
                        ),
                        const SizedBox(width: DsSpacing.xxs),
                        Text(
                          '/ $perHourLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
