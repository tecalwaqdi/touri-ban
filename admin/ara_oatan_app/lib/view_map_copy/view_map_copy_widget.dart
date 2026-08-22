import 'package:easy_localization/easy_localization.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/structs/index.dart';
import '/core/toury_custom_place_cart.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'view_map_copy_model.dart';
export 'view_map_copy_model.dart';

class ViewMapCopyWidget extends StatefulWidget {
  const ViewMapCopyWidget({
    super.key,
    this.map,
  });

  final LatLng? map;

  static String routeName = 'view_mapCopy';
  static String routePath = '/viewMapCopy';

  @override
  State<ViewMapCopyWidget> createState() => _ViewMapCopyWidgetState();
}

class _ViewMapCopyWidgetState extends State<ViewMapCopyWidget> {
  late ViewMapCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ViewMapCopyModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Business logic — unchanged behaviour, DS-styled surfaces only.
  // ---------------------------------------------------------------------------

  /// A place can only join the trip when it belongs to the browsed city.
  Future<void> _addSelectedPlaceToTrip() async {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    if (_model.placePickerValue.city == FFAppState().naimvillatext) {
      final place = _model.placePickerValue;
      touryAddCustomPlaceToCart(
        context: context,
        name: place.name,
        location: place.latLng,
        address: place.address,
      );
      safeSetState(() {});
      return;
    }

    await showDialog(
      context: context,
      builder: (alertDialogContext) {
        return WebViewAware(
          child: AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: DsRadius.extraLarge),
            content: Text(
              'place_city_only'.tr(namedArgs: {
                'city': FFAppState().naimvillatext,
              }),
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            actions: [
              DsButton.text(
                label: 'ui_text_b0a98216a3'.tr(),
                onPressed: () => Navigator.pop(alertDialogContext),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenScaffold(
      scaffoldKey: scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: DsAppBar(
        automaticallyImplyLeading: false,
        title: FFLocalizations.of(context).getText(
          'usn2swjj' /* Specify the location on the ma... */,
        ),
        leading: DsIconButton(
          icon: DsIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () async {
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        top: true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DsSpacing.md,
                DsSpacing.xs,
                DsSpacing.md,
                DsSpacing.xs,
              ),
              child: _buildPlacePicker(context),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: DsRadius.lgRadius,
                ),
                child: FlutterFlowGoogleMap(
                  controller: _model.googleMapsController,
                  onCameraIdle: (latLng) =>
                      safeSetState(() => _model.googleMapsCenter = latLng),
                  initialLocation: _model.googleMapsCenter ??= widget.map!,
                  markerColor: GoogleMarkerColor.green,
                  mapType: MapType.hybrid,
                  style: GoogleMapStyle.standard,
                  initialZoom: 9.0,
                  allowInteraction: true,
                  allowZoom: true,
                  showZoomControls: true,
                  showLocation: true,
                  showCompass: true,
                  showMapToolbar: true,
                  showTraffic: true,
                  centerMapOnMarkerTap: true,
                ),
              ),
            ),
            _buildSelectionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacePicker(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return FlutterFlowPlacePicker(
      iOSGoogleMapsApiKey: TouryMapsConfig.googleMapsApiKey,
      androidGoogleMapsApiKey: TouryMapsConfig.googleMapsApiKey,
      webGoogleMapsApiKey: TouryMapsConfig.googleMapsApiKey,
      onSelect: (place) async {
        safeSetState(() => _model.placePickerValue = place);
      },
      defaultText: FFLocalizations.of(context).getText(
        '5951u60p' /* Select Location */,
      ),
      icon: Icon(
        DsIcons.location,
        color: colors.onPrimary,
        size: DsIcons.xs,
      ),
      buttonOptions: FFButtonOptions(
        width: double.infinity,
        height: DsConstants.buttonHeightMd,
        color: colors.primary,
        textStyle: typography.labelLarge.copyWith(color: colors.onPrimary),
        elevation: 0.0,
        borderSide: const BorderSide(
          color: Colors.transparent,
          width: 1.0,
        ),
        borderRadius: DsRadius.medium,
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final placeName = _model.placePickerValue.name;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.md,
        DsSpacing.md,
        DsSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: DsRadius.xlRadius),
        boxShadow: DsShadows.bottomSheet(dark: context.dsIsDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                DsIcons.location,
                size: DsIcons.sm,
                color: colors.primary,
              ),
              const SizedBox(width: DsSpacing.xs),
              Flexible(
                child: Text(
                  valueOrDefault<String>(placeName, 'حدد مكان'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.primary(
            expanded: true,
            size: DsButtonSize.lg,
            icon: DsIcons.add,
            label: valueOrDefault<String>(
              'إضافة $placeName  إلى رحلتي',
              'إضافة إلى رحلتي',
            ),
            onPressed: _addSelectedPlaceToTrip,
          ),
        ],
      ),
    );
  }
}
