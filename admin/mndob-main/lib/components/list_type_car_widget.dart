import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
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
  String? _loadedCountryId;

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

  /// Country-scoped catalog only — never fetch the global type_car collection.
  Future<List<TypeCarRecord>> _loadCars() async {
    final countryRef = FFAppState().dolh;
    final countryId = countryRef?.id.trim() ?? '';
    _loadedCountryId = countryId.isEmpty ? null : countryId;
    if (countryRef == null || countryId.isEmpty) {
      return const <TypeCarRecord>[];
    }
    // Scope by canonical countryId. Do NOT orderBy sort_order — missing
    // sort_order silently drops docs from Firestore ordered queries.
    return queryTypeCarRecordOnce(
      limit: 120,
      queryBuilder: (q) => q.where('countryId', isEqualTo: countryId),
    );
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

    // Fail closed when driver country is unknown — never show unscoped catalog.
    if (countryRef == null) {
      return const <TypeCarRecord>[];
    }

    var list = raw.where((item) {
      if (!item.isAvailableForListing) return false;
      if (item.naim.trim() == 'سيارة صغيره' && !allowSmallCar) return false;
      return item.matchesCountry(
        countryRef: countryRef,
        iso2: iso,
        allowLegacySaudiFallback: false,
      );
    }).toList();

    list.sort((a, b) {
      final bySr = a.sr.compareTo(b.sr);
      if (bySr != 0) return bySr;
      return a.reference.id.compareTo(b.reference.id);
    });
    return list;
  }

  bool _acceptSelection(TypeCarRecord car) {
    final driverCountry = FFAppState().dolh;
    final iso = TouryCountryRegistry.normalizeIso(driverCountry?.id);
    if (driverCountry == null) return false;
    return car.matchesCountry(
      countryRef: driverCountry,
      iso2: iso,
      allowLegacySaudiFallback: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final lang = FFLocalizations.of(context).locale.languageCode;
    final countryRef = FFAppState().dolh;
    final countryId = countryRef?.id.trim() ?? '';

    // Reload when driver country changes while the sheet is open.
    if (countryId != (_loadedCountryId ?? '') &&
        _carsFuture != null &&
        countryId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (countryId == (_loadedCountryId ?? '')) return;
        setState(() {
          _carsFuture = _loadCars();
        });
      });
    }

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
            child: countryRef == null
                ? DriverEmptyState(
                    title: driverTr(context, 'Driver country unavailable'),
                    message: driverTr(
                      context,
                      'Could not determine the driver account country',
                    ),
                    icon: Icons.public_off_outlined,
                  )
                : FutureBuilder<List<TypeCarRecord>>(
                    key: ValueKey('typecar:$countryId'),
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
                          title: driverTr(
                            context,
                            'No vehicle types available',
                          ),
                          message: driverTr(
                            context,
                            'No vehicle types are currently available for your country',
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
                              if (!_acceptSelection(car)) {
                                return;
                              }
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          style:
                                              typography.bodySmall.copyWith(
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
