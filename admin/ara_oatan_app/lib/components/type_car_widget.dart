import '/backend/backend.dart';
import '/core/toury_car_i18n.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_image.dart';
import '/core/toury_vehicle_catalog.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'type_car_model.dart';
export 'type_car_model.dart';

/// Legacy vehicle list — routes through country-scoped cache (never global).
class TypeCarWidget extends StatefulWidget {
  const TypeCarWidget({super.key});

  @override
  State<TypeCarWidget> createState() => _TypeCarWidgetState();
}

class _TypeCarWidgetState extends State<TypeCarWidget> {
  late TypeCarModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TypeCarModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final bookingCountry = FFAppState().dolh;

    if (bookingCountry == null) {
      return DsEmptyState(
        title: 'ux_vehicle_select_country_title'.tr(),
        message: 'ux_vehicle_select_country_msg'.tr(),
        icon: DsIcons.car,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        StreamBuilder<List<TypeCarRecord>>(
          key: ValueKey('typecar:${bookingCountry.path}'),
          stream: TouryFirestoreCache.typeCarStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const DsLoading();
            }
            final cars = touryDeduplicateTypeCars(snapshot.data!);
            if (cars.isEmpty) {
              return DsEmptyState(
                title: 'ux_car_list_empty_title'.tr(),
                message: 'ux_car_list_empty_msg'.tr(),
                icon: DsIcons.car,
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemCount: cars.length,
              itemBuilder: (context, listViewIndex) {
                final listViewTypeCarRecord = cars[listViewIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                  child: DsCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md,
                      vertical: DsSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: DsRadius.small,
                          child: TouryNetworkImage(
                            url: listViewTypeCarRecord.img,
                            width: 72.0,
                            height: 54.0,
                            fit: BoxFit.cover,
                            fallbackAsset: 'assets/images/car.png',
                            useBrandedFallback: true,
                          ),
                        ),
                        const SizedBox(width: DsSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                touryVehicleCategoryDisplayName(
                                  listViewTypeCarRecord,
                                  context,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: typography.titleMedium.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xxs),
                              Text(
                                FFLocalizations.of(context).getText(
                                  'fkqe7gw6' /* تحديد */,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.labelMedium.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colors.iconMuted,
                          size: DsIcons.sm,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
