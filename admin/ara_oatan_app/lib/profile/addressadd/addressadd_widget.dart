import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'addressadd_model.dart';

export 'addressadd_model.dart';

class AddressaddWidget extends StatefulWidget {
  const AddressaddWidget({super.key});

  static String routeName = 'addressadd';
  static String routePath = '/addressadd';

  @override
  State<AddressaddWidget> createState() => _AddressaddWidgetState();
}

class _AddressaddWidgetState extends State<AddressaddWidget> {
  late AddressaddModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  Future<void> _applyResolvedLocation(TouryResolvedLocation resolved) async {
    if (!resolved.success || resolved.position == null) {
      return;
    }
    currentUserLocationValue = resolved.position;
    _model.loceshn = resolved.position;
    FFAppState().LOceshtoaddAdress = resolved.coordinatesString;
    _model.villCobe = resolved.village;
    final json = resolved.geocodeResponse;
    if (json != null) {
      FFAppState().AdressTelet =
          '${PENmdenhCall.name(json)}- ${PENmdenhCall.add(json)}- ${PENmdenhCall.address(json)}';
      FFAppState().adressVillTEXT =
          resolved.village?.naim ?? PENmdenhCall.name(json) ?? '';
      _model.fullAdress = PENmdenhCall.fullAdress(json);
    } else {
      FFAppState().adressVillTEXT = resolved.villageName;
      FFAppState().AdressTelet = resolved.fullAddress ?? '';
      _model.fullAdress = resolved.fullAddress;
    }
    FFAppState().adressVillRev = resolved.village?.reference;
    safeSetState(() {});
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddressaddModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final resolved = await TouryLocationService.resolveCurrentLocation();
      if (!mounted) return;
      if (resolved.success) {
        await _applyResolvedLocation(resolved);
      } else {
        await TouryDialogs.showLocationError(context);
      }
    });

    _model.tiletTextController ??=
        TextEditingController(text: _model.fullAdress);
    _model.tiletFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    final resolved = await TouryLocationService.resolveCurrentLocation();
    if (!mounted) return;
    if (!resolved.success) {
      await TouryDialogs.showLocationError(context);
      return;
    }
    await _applyResolvedLocation(resolved);
    _model.villCobe2 = resolved.village;
    _model.idvill = resolved.village?.reference;
    await _model.googleMapsController.future.then(
      (c) => c.animateCamera(
        CameraUpdate.newLatLng(_model.loceshn!.toGoogleMaps()),
      ),
    );
    safeSetState(() {});
  }

  Future<void> _saveAddress() async {
    final resolved = await TouryLocationService.resolveCurrentLocation();
    if (!mounted) return;
    if (!resolved.success) {
      await TouryDialogs.showLocationError(context);
      return;
    }
    await _applyResolvedLocation(resolved);
    _model.villasend = resolved.village;
    await _model.googleMapsController.future.then(
      (c) => c.animateCamera(
        CameraUpdate.newLatLng(_model.loceshn!.toGoogleMaps()),
      ),
    );
    if ((_model.tiletTextController.text != '') &&
        (FFAppState().adressVillRev != null) &&
        (resolved.villageName == FFAppState().adressVillTEXT)) {
      var adressuserRecordReference = AdressuserRecord.collection.doc();
      await adressuserRecordReference.set({
        ...createAdressuserRecordData(
          user: currentUserReference,
          tilet: _model.tiletTextController.text,
          map: _model.googleMapsCenter,
          naimVill: FFAppState().adressVillTEXT,
          vill: _model.idvill,
          acctev: true,
          textfullAdress: FFAppState().AdressTelet,
        ),
        ...mapToFirestore(
          {
            'data_add': FieldValue.serverTimestamp(),
          },
        ),
      });
      _model.adressnow = AdressuserRecord.getDocumentFromData({
        ...createAdressuserRecordData(
          user: currentUserReference,
          tilet: _model.tiletTextController.text,
          map: _model.googleMapsCenter,
          naimVill: FFAppState().adressVillTEXT,
          vill: _model.idvill,
          acctev: true,
          textfullAdress: FFAppState().AdressTelet,
        ),
        ...mapToFirestore(
          {
            'data_add': DateTime.now(),
          },
        ),
      }, adressuserRecordReference);

      context.pushNamed(ListAdressSelectWidget.routeName);
    } else {
      await showDialog(
        context: context,
        builder: (alertDialogContext) {
          return WebViewAware(
            child: AlertDialog(
              title: Text('ui_text_b6f51cadc4'.tr()),
              content: Text('ui_text_5eac766a7c'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(alertDialogContext),
                  child: Text('ui_text_b0a98216a3'.tr()),
                ),
              ],
            ),
          );
        },
      );
    }

    safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              resizeToAvoidBottomInset: false,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                title: FFLocalizations.of(context).getText(
                  'zznzeuxy' /* Add Your Address */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.pop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.xxxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsFadeSlide(
                        child: DsCard(
                          elevated: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  '1epfep3m' /* Address Details */,
                                ),
                                style: typography.titleLarge.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xxs),
                              Text(
                                FFLocalizations.of(context).getText(
                                  'd7eiiez0' /* Note: This is the address wher... */,
                                ),
                                style: typography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.md),
                              _DetailRow(
                                icon: Icons.holiday_village_outlined,
                                value: FFAppState().naimvillatext,
                              ),
                              const SizedBox(height: DsSpacing.xs),
                              _DetailRow(
                                icon: DsIcons.location,
                                value: valueOrDefault<String>(
                                  _model.fullAdress,
                                  'يرجى تحديد الموقع الحالي',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 60),
                        child: DsCard(
                          elevated: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Form(
                                key: _model.formKey,
                                autovalidateMode: AutovalidateMode.always,
                                child: TextFormField(
                                  controller: _model.tiletTextController,
                                  focusNode: _model.tiletFocusNode,
                                  autofocus: false,
                                  obscureText: false,
                                  style: typography.bodyLarge.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                  cursorColor: colors.primary,
                                  decoration: InputDecoration(
                                    labelText:
                                        FFLocalizations.of(context).getText(
                                      '8ssn09j0' /* Address Name (e.g. Home, Work) */,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.bookmark_border_rounded,
                                      size: DsIcons.sm,
                                      color: colors.iconMuted,
                                    ),
                                  ),
                                  validator: _model.tiletTextControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: DsButton.outlined(
                                  label: FFLocalizations.of(context).getText(
                                    'pe6cesry' /* My current location */,
                                  ),
                                  icon: Icons.my_location_rounded,
                                  size: DsButtonSize.sm,
                                  onPressed: _useCurrentLocation,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              ClipRRect(
                                borderRadius: DsRadius.medium,
                                child: SizedBox(
                                  height: DsConstants.heroHeightLg + 120,
                                  child: Stack(
                                    children: [
                                      if (_model.loceshn == null)
                                        Container(
                                          color: colors.surfaceElevated,
                                          alignment: Alignment.center,
                                          child: const DsLoading(),
                                        )
                                      else
                                        FlutterFlowGoogleMap(
                                          controller:
                                              _model.googleMapsController,
                                          onCameraIdle: (latLng) =>
                                              safeSetState(() => _model
                                                  .googleMapsCenter = latLng),
                                          initialLocation:
                                              _model.googleMapsCenter ??=
                                                  _model.loceshn!,
                                          markerColor: GoogleMarkerColor.green,
                                          mapType: MapType.hybrid,
                                          style: GoogleMapStyle.standard,
                                          initialZoom: 25.0,
                                          allowInteraction: true,
                                          allowZoom: true,
                                          showZoomControls: true,
                                          showLocation: false,
                                          showCompass: true,
                                          showMapToolbar: true,
                                          showTraffic: true,
                                          centerMapOnMarkerTap: true,
                                          mapTakesGesturePreference: true,
                                        ),
                                      Align(
                                        alignment:
                                            const AlignmentDirectional(0.0, 0.0),
                                        child: PointerInterceptor(
                                          intercepting: isWeb,
                                          child: Icon(
                                            Icons.location_pin,
                                            color: colors.error,
                                            size: DsIcons.xl,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xl),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 120),
                        child: DsButton.primary(
                          label: FFLocalizations.of(context).getText(
                            '77xoowgb' /* Save Address */,
                          ),
                          icon: Icons.add_home_outlined,
                          size: DsButtonSize.lg,
                          expanded: true,
                          onPressed: _saveAddress,
                        ),
                      ),
                    ],
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

/// Icon + text line used inside the address summary card.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: DsIcons.sm, color: colors.primary),
        const SizedBox(width: DsSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: typography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
