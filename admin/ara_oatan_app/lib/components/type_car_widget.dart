import '/backend/backend.dart';
import '/core/app_ux_widgets.dart';
import '/core/toury_car_i18n.dart';
import '/core/toury_vehicle_catalog.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'type_car_model.dart';
export 'type_car_model.dart';

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
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        StreamBuilder<List<TypeCarRecord>>(
          stream: queryTypeCarRecord(),
          builder: (context, snapshot) {
            // Customize what your widget looks like when it's loading.
            if (!snapshot.hasData) {
              return const DsLoading();
            }
            final cars = touryDeduplicateTypeCars(
              snapshot.data!
                  .where((car) => car.isAvailableForListing)
                  .toList(),
            );

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
