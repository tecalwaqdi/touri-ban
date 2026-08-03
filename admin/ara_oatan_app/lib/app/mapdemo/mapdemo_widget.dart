import 'package:easy_localization/easy_localization.dart';

import '/backend/schema/structs/index.dart';
import '/components/listamak_widget.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'mapdemo_model.dart';
export 'mapdemo_model.dart';

class MapdemoWidget extends StatefulWidget {
  const MapdemoWidget({super.key});

  static String routeName = 'mapdemo';
  static String routePath = '/mapdemo';

  @override
  State<MapdemoWidget> createState() => _MapdemoWidgetState();
}

class _MapdemoWidgetState extends State<MapdemoWidget> {
  late MapdemoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapdemoModel());

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

  void _showAddedSnackBar(String message) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: typography.labelMedium.copyWith(color: colors.onPrimary),
        ),
        duration: const Duration(milliseconds: 4000),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
        action: SnackBarAction(
          label: 'view_my_trip'.tr(),
          textColor: colors.onPrimary,
          onPressed: () async {
            context.pushNamed(Checkout66Widget.routeName);
          },
        ),
      ),
    );
  }

  /// Drops the current map centre into the cart as a manually picked stop.
  Future<void> _addMapCentre() async {
    FFAppState().addcart = FFAppState().addcart + 1;
    FFAppState().addToCartmkss(AmaknCostmStruct(
      naim: 'محدد يدوي من الخريطة ',
      loceshn: _model.googleMapsCenter,
    ));
    safeSetState(() {});
    _showAddedSnackBar('ui_text_17db754851'.tr());
  }

  /// Adds the place returned by the search picker, keeping the city trail.
  Future<void> _addSearchedPlace() async {
    FFAppState().addcart = FFAppState().addcart + 1;
    FFAppState().addToCartmkss(AmaknCostmStruct(
      naim: _model.placePickerValue.name,
      address: _model.placePickerValue.address,
      textivill: _model.placePickerValue.city,
      loceshn: _model.placePickerValue.latLng,
      dolh: FFAppState().dolh,
    ));
    FFAppState().textallAlmdn = (String var1, String var2) {
      return "$var1 $var2";
    }(FFAppState().textallAlmdn, _model.placePickerValue.city);
    safeSetState(() {});
    _showAddedSnackBar(
      'landmark_added_success'.tr(namedArgs: {
        'name': _model.placePickerValue.name,
      }),
    );
  }

  Future<void> _openAddedTripsSheet() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: context.dsColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: DsRadius.xlRadius),
      ),
      context: context,
      builder: (context) {
        return WebViewAware(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Padding(
              padding: MediaQuery.viewInsetsOf(context),
              child: SizedBox(
                height: TouryLayout.sheetMaxHeight(context) * 0.5,
                child: const ListamakWidget(),
              ),
            ),
          ),
        );
      },
    ).then((value) => safeSetState(() {}));
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
        title: FFAppState().naimvillatext,
        leading: DsIconButton(
          icon: DsIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () async {
            context.pop();
          },
        ),
        actions: [
          DsIconButton(
            icon: DsIcons.close,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: DsSpacing.xxs),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMap(context)),
                  Align(
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: PointerInterceptor(
                      intercepting: isWeb,
                      child: Icon(
                        Icons.location_pin,
                        color: context.dsColors.error,
                        size: DsIcons.md,
                      ),
                    ),
                  ),
                  Align(
                    alignment: const AlignmentDirectional(0.0, -1.0),
                    child: _buildTopBar(context),
                  ),
                  Align(
                    alignment: const AlignmentDirectional(0.0, 1.0),
                    child: _buildBottomActions(context),
                  ),
                ],
              ),
            ),
            if (FFAppState().addcart.toString() != '0')
              Padding(
                padding: const EdgeInsets.only(top: DsSpacing.md),
                child: DsButton.text(
                  icon: Icons.list_alt_rounded,
                  label: FFLocalizations.of(context).getText(
                    'i1l2zo9t' /* Show the list of added trips. */,
                  ),
                  onPressed: _openAddedTripsSheet,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterFlowGoogleMap(
      controller: _model.googleMapsController,
      onCameraIdle: (latLng) =>
          safeSetState(() => _model.googleMapsCenter = latLng),
      initialLocation: _model.googleMapsCenter ??= FFAppState().latlngvill!,
      markerColor: GoogleMarkerColor.violet,
      mapType: MapType.hybrid,
      style: GoogleMapStyle.standard,
      initialZoom: 8.0,
      allowInteraction: true,
      allowZoom: true,
      showZoomControls: true,
      showLocation: true,
      showCompass: true,
      showMapToolbar: true,
      showTraffic: true,
      centerMapOnMarkerTap: true,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final hasSearchedPlace = _model.placePickerValue.name != '';

    return PointerInterceptor(
      intercepting: isWeb,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.sm,
          DsSpacing.xs,
          DsSpacing.sm,
          0,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 132,
              child: _buildPlacePicker(context),
            ),
            const Spacer(),
            if (hasSearchedPlace)
              Flexible(
                child: DsFadeSlide(
                  offset: const Offset(0, -0.6),
                  child: DsButton.secondary(
                    size: DsButtonSize.sm,
                    icon: DsIcons.add,
                    label: ' إضافة ${_model.placePickerValue.name}',
                    onPressed: _addSearchedPlace,
                  ),
                ),
              ),
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
        'krcgoqb2' /* Search */,
      ),
      icon: Icon(
        DsIcons.search,
        color: colors.onPrimary,
        size: DsIcons.xs,
      ),
      buttonOptions: FFButtonOptions(
        width: double.infinity,
        height: DsConstants.buttonHeightSm,
        color: colors.primary,
        textStyle: typography.labelMedium.copyWith(color: colors.onPrimary),
        elevation: 0.0,
        borderSide: const BorderSide(
          color: Colors.transparent,
          width: 1.0,
        ),
        borderRadius: DsRadius.medium,
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return PointerInterceptor(
      intercepting: isWeb,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.md,
          0,
          DsSpacing.md,
          DsSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsButton(
              variant: DsButtonVariant.secondary,
              expanded: true,
              icon: Icons.location_pin,
              label: FFLocalizations.of(context).getText(
                'mcm14opc' /* Add the specific location. */,
              ),
              onPressed: _addMapCentre,
            ),
            const SizedBox(height: DsSpacing.xs),
            Container(
              padding: DsSpacing.chipPadding,
              decoration: BoxDecoration(
                color: colors.scrim,
                borderRadius: DsRadius.pill,
              ),
              child: Text(
                FFLocalizations.of(context).getText(
                  'l2q2z1ln' /* Try to zoom the map to the las... */,
                ),
                textAlign: TextAlign.center,
                style: typography.labelSmall.copyWith(
                  color: DsColors.dark.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
