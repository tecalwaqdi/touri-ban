import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/app_state.dart';
import '/backend/backend.dart';
import '/core/driver_i18n.dart';
import '/core/driver_ux_widgets.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'list_type_car_model.dart';
export 'list_type_car_model.dart';

class ListTypeCarWidget extends StatefulWidget {
  const ListTypeCarWidget({super.key, required this.idNumber});
  final String idNumber;

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

  bool _canSeeSmallCar() => widget.idNumber.trim().startsWith('10');

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
    return queryTypeCarRecordOnce(limit: 120);
  }

  void _retry() {
    setState(() {
      _carsFuture = _loadCars();
    });
  }

  List<TypeCarRecord> _filterCars(List<TypeCarRecord> raw) {
    final allowSmallCar = _canSeeSmallCar();
    final countryRef = FFAppState().dolh;
    final iso = TouryCountryRegistry.normalizeIso(countryRef?.id);

    var list = raw.where((item) {
      if (!item.isAvailableForListing) return false;
      if (item.naim.trim() == 'سيارة صغيره' && !allowSmallCar) return false;
      return true;
    }).toList();

    if (countryRef != null || (iso != null && iso.isNotEmpty)) {
      final scoped = list
          .where(
            (item) => item.matchesCountry(
              countryRef: countryRef,
              iso2: iso,
            ),
          )
          .toList();
      if (scoped.isNotEmpty) {
        list = scoped;
      }
    }

    list.sort((a, b) => a.sr.compareTo(b.sr));
    return list;
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
                    message: driverTr(
                      context,
                      'Something went wrong. Please try again.',
                    ),
                    icon: Icons.error_outline,
                    actionLabel: driverTr(context, 'Retry'),
                    onAction: _retry,
                  );
                }

                final cars = _filterCars(snapshot.data ?? const []);
                if (cars.isEmpty) {
                  return DriverEmptyState(
                    title: driverTr(context, 'No vehicle types available'),
                    message: driverTr(
                      context,
                      'No vehicle types for your location yet. Try again after enabling GPS.',
                    ),
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
                    final title = car.localizedName(lang);
                    return DsCard(
                      onTap: () {
                        FFAppState().MNDOBTYPECARrev = car.reference;
                        FFAppState().textTypeCar = title;
                        Navigator.pop(context, car);
                      },
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
