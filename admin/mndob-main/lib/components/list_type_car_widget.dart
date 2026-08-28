import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/core/driver_type_car_catalog.dart';
import '/core/driver_country_resolver.dart';
import '/core/driver_ux_widgets.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'list_type_car_model.dart';
export 'list_type_car_model.dart';

class ListTypeCarWidget extends StatefulWidget {
  const ListTypeCarWidget({
    super.key,
    required this.idNumber,
    this.countryRef,
    this.countryIso2,
    this.onSelected,
  });

  final String idNumber;
  final DocumentReference? countryRef;
  final String? countryIso2;
  final VoidCallback? onSelected;

  @override
  State<ListTypeCarWidget> createState() => _ListTypeCarWidgetState();
}

Widget _buildCarThumb(BuildContext context, String? url) {
  final colors = context.dsColors;
  final placeholder = Container(
    width: 64.0,
    height: 48.0,
    color: colors.primarySoft,
    alignment: Alignment.center,
    child: Icon(
      Icons.directions_car_rounded,
      color: colors.primaryStrong,
      size: 24.0,
    ),
  );
  final clean = (url ?? '').trim();
  return ClipRRect(
    borderRadius: DsRadius.small,
    child: clean.isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: clean,
            width: 64.0,
            height: 48.0,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (context, _) => placeholder,
            errorWidget: (context, _, __) => placeholder,
          ),
  );
}

class _ListTypeCarWidgetState extends State<ListTypeCarWidget> {
  late ListTypeCarModel _model;
  Future<List<TypeCarRecord>>? _carsFuture;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListTypeCarModel());
    _carsFuture = _loadCars();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<List<TypeCarRecord>> _loadCars() async {
    debugPrint('TYPE_CAR_QUERY_START');
    try {
      final rows = await queryTypeCarRecordOnce(limit: 120);
      debugPrint('TYPE_CAR_QUERY_COUNT=${rows.length}');
      return rows;
    } catch (e, st) {
      final code = e is FirebaseException ? e.code : e.runtimeType.toString();
      debugPrint('TYPE_CAR_QUERY_ERROR=$code');
      debugPrint('$st');
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _carsFuture = _loadCars();
    });
  }

  DriverTypeCarCatalogResult _filterCars(List<TypeCarRecord> raw) {
    final countryRef = widget.countryRef ?? FFAppState().dolh;
    final iso = DriverCountryResolver.resolveRegistrationIso(
      dolh: countryRef,
      locationIso2: widget.countryIso2,
    );
    final scopedRef = DriverCountryResolver.resolveRegistrationCountry(
      dolh: countryRef,
      locationIso2: widget.countryIso2,
    );
    final result = DriverTypeCarCatalog.filter(
      raw: raw,
      idNumber: widget.idNumber,
      countryRef: scopedRef,
      countryIso2: iso,
    );
    debugPrint('TYPE_CAR_RAW_COUNT=${result.rawCount}');
    debugPrint('TYPE_CAR_ACTIVE_COUNT=${result.activeCount}');
    debugPrint('TYPE_CAR_COUNTRY_COUNT=${result.countryMatchedCount}');
    debugPrint('TYPE_CAR_FILTERED_COUNT=${result.renderedCount}');
    return result;
  }

  String _errorMessage(BuildContext context, Object error) {
    if (error is FirebaseException) {
      debugPrint(
        'TYPE_CAR_QUERY_ERROR=${error.code} type=${error.runtimeType}',
      );
      switch (error.code) {
        case 'permission-denied':
          return driverTr(
            context,
            'Unable to load vehicle types due to permissions.',
          );
        case 'unavailable':
          return driverTr(
            context,
            'Unable to reach the service. Check your connection.',
          );
      }
    } else {
      debugPrint('TYPE_CAR_QUERY_ERROR=${error.runtimeType}');
    }
    return driverTr(context, 'Something went wrong. Please try again.');
  }

  ({String title, String message}) _emptyCopy(
    BuildContext context,
    DriverTypeCarEmptyReason? reason,
  ) {
    switch (reason) {
      case DriverTypeCarEmptyReason.noCatalogForCountry:
        return (
          title: driverTr(context, 'No vehicle types available'),
          message: driverTr(
            context,
            'No vehicle types are configured for this country yet. Contact support or try again later.',
          ),
        );
      case DriverTypeCarEmptyReason.noActiveTypes:
        return (
          title: driverTr(context, 'No vehicle types available'),
          message: driverTr(
            context,
            'No active vehicle types are available right now.',
          ),
        );
      case DriverTypeCarEmptyReason.network:
        return (
          title: driverTr(context, 'Error'),
          message: driverTr(
            context,
            'Unable to load vehicle types. Check your connection and try again.',
          ),
        );
      case DriverTypeCarEmptyReason.unknown:
      case null:
        return (
          title: driverTr(context, 'No vehicle types available'),
          message: driverTr(
            context,
            'No vehicle types are available right now.',
          ),
        );
    }
  }

  void _selectCar(BuildContext context, TypeCarRecord car, String title) {
    FFAppState().update(() {
      FFAppState().MNDOBTYPECARrev = car.reference;
      FFAppState().textTypeCar = title;
    });
    debugPrint('SELECTED_TYPE_PATH=${car.reference.path}');
    widget.onSelected?.call();
    Navigator.pop(context, car);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final lang = FFLocalizations.of(context).locale.languageCode;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DsSpacing.md,
              DsSpacing.sm,
              DsSpacing.md,
              DsSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    driverTr(context, 'Select vehicle type'),
                    style: typography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(DsIcons.close, color: colors.textPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TypeCarRecord>>(
              future: _carsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: DsLoading(size: 48));
                }
                if (snapshot.hasError) {
                  return DriverEmptyState(
                    title: driverTr(context, 'Error'),
                    message: _errorMessage(context, snapshot.error!),
                    icon: Icons.error_outline,
                    actionLabel: driverTr(context, 'Retry'),
                    onAction: _retry,
                  );
                }

                final filtered = _filterCars(snapshot.data ?? const []);
                final cars = filtered.cars;
                if (cars.isEmpty) {
                  final copy = _emptyCopy(context, filtered.emptyReason);
                  return DriverEmptyState(
                    title: copy.title,
                    message: copy.message,
                    icon: Icons.directions_car_outlined,
                    actionLabel: driverTr(context, 'Retry'),
                    onAction: _retry,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.sm,
                    0,
                    DsSpacing.sm,
                    DsSpacing.xl,
                  ),
                  itemCount: cars.length,
                  separatorBuilder: (_, __) => DsSpacing.gapXs,
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    final title = DriverTypeCarCatalog.displayLabel(car, lang);
                    return DsCard(
                      onTap: () => _selectCar(context, car, title),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.sm,
                        vertical: DsSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          _buildCarThumb(context, car.img),
                          DsSpacing.gapSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: typography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                if (car.codeCar.isNotEmpty)
                                  Text(
                                    car.codeCar,
                                    style: typography.bodySmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            driverTr(context, 'Select'),
                            style: typography.labelLarge.copyWith(
                              color: colors.primaryStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DsSpacing.gapXxs,
                          Icon(
                            Icons.chevron_left,
                            color: colors.primaryStrong,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
