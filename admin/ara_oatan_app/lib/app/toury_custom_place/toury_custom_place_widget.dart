import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

import '/core/toury_custom_place_cart.dart';
import '/core/toury_location_service.dart';
import '/core/toury_maps_config.dart';
import '/core/toury_navigation.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'toury_custom_place_model.dart';

export 'toury_custom_place_model.dart';

/// اختيار موقع مخصص غير موجود في قائمة المعالم — يُحسب ضمن السلة بنفس آلية المعالم.
class TouryCustomPlaceWidget extends StatefulWidget {
  const TouryCustomPlaceWidget({super.key});

  static String routeName = 'TouryCustomPlace';
  static String routePath = '/touryCustomPlace';

  @override
  State<TouryCustomPlaceWidget> createState() => _TouryCustomPlaceWidgetState();
}

class _TouryCustomPlaceWidgetState extends State<TouryCustomPlaceWidget> {
  late TouryCustomPlaceModel _model;
  bool _locating = false;

  static const _defaultCenter = TouryMapsConfig.mapShellCenter;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TouryCustomPlaceModel());
    _model.googleMapsCenter = _initialMapCenter();
  }

  LatLng _initialMapCenter() {
    final app = FFAppState();
    return app.latlngvill ??
        app.mkanuserorder ??
        app.akrLoceshn ??
        _defaultCenter;
  }

  String get _resolvedAddress {
    final place = _model.placePickerValue;
    if (place.address.isNotEmpty) return place.address;
    if (place.name.isNotEmpty) return place.name;
    final center = _model.googleMapsCenter;
    if (center == null) return '';
    return '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}';
  }

  Future<void> _moveMapTo(LatLng target, {double zoom = 14}) async {
    _model.googleMapsCenter = target;
    safeSetState(() {});
    try {
      final controller = await _model.googleMapsController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(target.toGoogleMaps(), zoom),
      );
    } catch (_) {}
  }

  Future<void> _onPlaceSelected(FFPlace place) async {
    _model.placePickerValue = place;
    if (place.name.isNotEmpty) {
      _model.nameController.text = place.name;
    }
    if (place.latLng.latitude != 0 || place.latLng.longitude != 0) {
      await _moveMapTo(place.latLng);
    }
    safeSetState(() {});
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await TouryLocationService.getHighAccuracyPosition();
      if (position == null || !mounted) return;
      await _moveMapTo(position, zoom: 15);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirmAdd() {
    final center = _model.googleMapsCenter;
    if (center == null) {
      DsSnackBar.show(
        context,
        message: 'custom_place_move_map_hint'.tr(),
        tone: DsSnackTone.warning,
      );
      return;
    }

    final name = _model.nameController.text.trim().isNotEmpty
        ? _model.nameController.text.trim()
        : (_model.placePickerValue.name.isNotEmpty
            ? _model.placePickerValue.name
            : 'custom_place_title'.tr());

    final added = touryAddCustomPlaceToCart(
      context: context,
      name: name,
      location: center,
      address: _resolvedAddress,
    );
    if (added && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;
          final cartCount = FFAppState().addcart;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: 'custom_place_title'.tr(),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
                actions: [
                  if (cartCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: DsSpacing.xs),
                      child: Center(
                        child: DsButton.text(
                          label: 'my_trip_count'
                              .tr(namedArgs: {'count': '$cartCount'}),
                          size: DsButtonSize.sm,
                          onPressed: () => touryOpenCheckout(context),
                        ),
                      ),
                    ),
                ],
              ),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterFlowGoogleMap(
                      controller: _model.googleMapsController,
                      onCameraIdle: (latLng) =>
                          safeSetState(() => _model.googleMapsCenter = latLng),
                      initialLocation:
                          _model.googleMapsCenter ??= _initialMapCenter(),
                      markerColor: GoogleMarkerColor.red,
                      mapType: MapType.normal,
                      style: GoogleMapStyle.standard,
                      initialZoom: 12,
                      allowInteraction: true,
                      allowZoom: true,
                      showZoomControls: false,
                      showLocation: true,
                      showCompass: false,
                      showMapToolbar: false,
                      showTraffic: false,
                      centerMapOnMarkerTap: false,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: DsSpacing.xxxl),
                      child: Icon(
                        Icons.location_on,
                        color: colors.error,
                        size: DsConstants.iconXl + DsSpacing.xxs,
                      ),
                    ),
                  ),
                  Positioned(
                    top: DsSpacing.sm,
                    left: DsSpacing.sm,
                    right: DsSpacing.sm,
                    child: PointerInterceptor(
                      intercepting: isWeb,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: DsRadius.medium,
                          boxShadow: DsShadows.floating(
                            dark: context.dsIsDark,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: DsSpacing.xs,
                          vertical: DsSpacing.xxs,
                        ),
                        child: FlutterFlowPlacePicker(
                          iOSGoogleMapsApiKey:
                              TouryMapsConfig.googleMapsApiKey,
                          androidGoogleMapsApiKey:
                              TouryMapsConfig.googleMapsApiKey,
                          webGoogleMapsApiKey:
                              TouryMapsConfig.googleMapsApiKey,
                          onSelect: _onPlaceSelected,
                          defaultText: 'custom_place_search_hint'.tr(),
                          icon: Icon(
                            DsIcons.search,
                            color: colors.primary,
                            size: DsIcons.sm,
                          ),
                          buttonOptions: FFButtonOptions(
                            width: double.infinity,
                            height: DsConstants.buttonHeightMd,
                            color: colors.surface,
                            textStyle: typography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                            elevation: 0,
                            borderRadius: DsRadius.medium,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: DsSpacing.sm,
                    bottom: DsConstants.heroHeightLg,
                    child: FloatingActionButton.small(
                      heroTag: 'custom_place_gps',
                      backgroundColor: colors.surface,
                      foregroundColor: colors.primary,
                      onPressed: _locating ? null : _goToMyLocation,
                      child: _locating
                          ? const SizedBox(
                              width: DsIcons.sm,
                              height: DsIcons.sm,
                              child: DsLoading(size: DsIcons.sm),
                            )
                          : Icon(Icons.my_location, color: colors.primary),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: PointerInterceptor(
                      intercepting: isWeb,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: DsRadius.xlRadius,
                          ),
                          boxShadow: DsShadows.bottomSheet(
                            dark: context.dsIsDark,
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          DsSpacing.md,
                          DsSpacing.md,
                          DsSpacing.md,
                          DsSpacing.md + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DsCard(
                              color: colors.infoContainer,
                              bordered: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: DsSpacing.sm,
                                vertical: DsSpacing.xs,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: DsIcons.sm,
                                    color: colors.info,
                                  ),
                                  const SizedBox(width: DsSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'custom_place_map_hint'.tr(),
                                      style: typography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsTextField(
                              controller: _model.nameController,
                              focusNode: _model.nameFocusNode,
                              label: 'custom_place_name_label'.tr(),
                              hint: 'custom_place_name_hint'.tr(),
                              prefixIcon: Icon(
                                Icons.bookmark_border_rounded,
                                size: DsIcons.sm,
                                color: colors.iconMuted,
                              ),
                            ),
                            if (_resolvedAddress.isNotEmpty) ...[
                              const SizedBox(height: DsSpacing.xs),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    DsIcons.location,
                                    size: DsIcons.xs,
                                    color: colors.iconMuted,
                                  ),
                                  const SizedBox(width: DsSpacing.xxs),
                                  Expanded(
                                    child: Text(
                                      _resolvedAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: DsSpacing.md),
                            DsButton.primary(
                              label: 'custom_place_add_to_trip'.tr(),
                              icon: Icons.add_location_alt_rounded,
                              size: DsButtonSize.md,
                              expanded: true,
                              onPressed: _confirmAdd,
                            ),
                          ],
                        ),
                      ),
                    ),
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
