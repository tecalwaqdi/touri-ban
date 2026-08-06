import '/core/toury_geo_display.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_payment_flow.dart';
import '/core/app_design_system.dart';
import '/core/app_ux_widgets.dart';
import '/core/toury_brand_widgets.dart';
import '/core/toury_location_service.dart';
import '/core/toury_booking_agents.dart';
import '/core/toury_booking_service.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_payment_labels.dart';
import '/core/toury_landmark_filter.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_phone_util.dart';
import '/core/toury_ngenius.dart';
import '/core/toury_navigation.dart';
import '/core/toury_polyline.dart';
import '/core/toury_route_metrics.dart';
import '/core/toury_distance_format.dart';
import '/core/toury_pricing.dart';
import '/core/toury_error_localizer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/mmaapp_widget.dart';
import '/components/payment_methods2_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_count_controller.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'checkout66_model.dart';
export 'checkout66_model.dart';

Future<Map<String, double>?> calculateMinDistanceAndTime() async {
  final currentLocation = await TouryLocationService.getUserPositionOrNull();
  final validation = touryValidateRoutePoints(
    origin: currentLocation,
    destinations: FFAppState().cartmkss.map((e) => e.loceshn),
    selectedAreaCenter: FFAppState().latlngvill,
  );
  if (!validation.canRoute) return null;
  final estimate = touryEstimateRoute(validation.points);

  return {
    'distance': estimate.distanceKm,
    'time': estimate.durationHours,
    'rejected': validation.rejectedCount.toDouble(),
  };
}

/// ملاحظة: لايمكن إتمام طلبك حتى يتم إضافة رقم الجوال ( إضافة رقم الجوال)
class Checkout66Widget extends StatefulWidget {
  const Checkout66Widget({super.key});

  static String routeName = 'Checkout66';
  static String routePath = '/checkout66';

  @override
  State<Checkout66Widget> createState() => _Checkout66WidgetState();
}

class _Checkout66WidgetState extends State<Checkout66Widget>
    with TickerProviderStateMixin {
  late Checkout66Model _model;
  double? previewDistance;
  double? previewTime;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  final animationsMap = <String, AnimationInfo>{};
  double osrmTime = 0;
  double osrmDistance = 0;
  bool isCalculating = false;
  bool _isPaying = false;
  int _rejectedRoutePoints = 0;

  double? get _tripDistanceKm {
    final raw = osrmDistance > 0 ? osrmDistance : previewDistance;
    if (raw == null || raw <= 0) return null;
    return touryAsDistanceKm(raw);
  }

  double? get _tripTimeHours {
    if (osrmTime > 0) return osrmTime / 60.0;
    if (previewTime != null) return previewTime;
    return null;
  }

  String _formatTripDistance() {
    final raw = _tripDistanceKm;
    if (raw == null || raw <= 0) return 'ux_not_available'.tr();
    final formatted = touryFormatDistanceKm(
      raw,
      locale: context.locale.toString(),
    );
    return formatted.isEmpty ? 'ux_not_available'.tr() : formatted;
  }

  String _formatTripTime() {
    final hours = _tripTimeHours;
    if (hours == null) return 'ux_not_available'.tr();
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return 'minutes_count'.tr(namedArgs: {'count': '$minutes'});
    }
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    if (minutes <= 0) {
      return 'ux_hours_count'.tr(namedArgs: {'count': '$wholeHours'});
    }
    return 'duration_hours_minutes'.tr(namedArgs: {
      'hours': '$wholeHours',
      'minutes': '$minutes',
    });
  }

  String _formatMoney(num value) {
    final amount = value.toDouble();
    final digits = amount == amount.roundToDouble() ? 0 : 2;
    try {
      return NumberFormat.currency(
        locale: context.locale.toString(),
        symbol: FFAppState().RMZCurrency,
        decimalDigits: digits,
      ).format(amount);
    } catch (_) {
      return '${amount.toStringAsFixed(digits)} ${FFAppState().RMZCurrency}';
    }
  }

// Function to calculate OSRM directly
  Future<void> _calculateOsrm() async {
    setState(() => isCalculating = true);

    try {
      final currentLocation =
          await TouryLocationService.getUserPositionOrNull();
      if (currentLocation == null) {
        setState(() => isCalculating = false);
        return;
      }

      final validation = touryValidateRoutePoints(
        origin: currentLocation,
        destinations: FFAppState().cartmkss.map((e) => e.loceshn),
        selectedAreaCenter: FFAppState().latlngvill,
      );
      if (!validation.canRoute) {
        setState(() {
          isCalculating = false;
          _rejectedRoutePoints = validation.rejectedCount;
        });
        return;
      }
      final destinations = validation.points.skip(1).toList();
      if (destinations.isEmpty) {
        setState(() => isCalculating = false);
        return;
      }

      // Build coordinates string
      final coordinates = [
        '${currentLocation.longitude},${currentLocation.latitude}',
        ...destinations.map((point) => '${point.longitude},${point.latitude}')
      ].join(';');

      final url =
          'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline&steps=false';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          final durationSeconds = TouryPolyline.asDouble(route['duration']);
          // OSRM distance is meters; store kilometers consistently in app state.
          final distanceKm =
              touryMetersToKm(TouryPolyline.asDouble(route['distance']));

          if (!touryRoadMetricsArePlausible(
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            points: validation.points,
          )) {
            setState(() {
              isCalculating = false;
              _rejectedRoutePoints = validation.rejectedCount + 1;
            });
            return;
          }
          setState(() {
            osrmTime = durationSeconds / 60;
            osrmDistance = distanceKm;
            _rejectedRoutePoints = validation.rejectedCount;
            isCalculating = false;
          });
          FFAppState().update(() {
            FFAppState().osrmTotalTime = osrmTime;
            FFAppState().osrmTotalDistance = distanceKm;
            FFAppState().osrmCalculationTime = DateTime.now();
          });
        } else if (mounted) {
          setState(() => isCalculating = false);
        }
      } else if (mounted) {
        setState(() => isCalculating = false);
      }
    } catch (e) {
      print('OSRM error: $e');
      setState(() => isCalculating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Checkout66Model());

    _model.textController ??= TextEditingController(
        text: FFAppState().saatcar.toString());
    _model.textFieldFocusNode ??= FocusNode();
    // Extra hours must start at 0 — never reuse last booking's addhors/totalsaat.
    FFAppState().addhors = 0;
    if (FFAppState().saatcar > 0) {
      FFAppState().totalsaat = FFAppState().saatcar;
    }
    _model.countControllerValue = 0;

    touryPurgeBannedCartItems();
    touryPrepareCheckoutState(resetExtraHours: true);
    // Refresh geo labels + country VAT (Admin vat_percent), then totals.
    unawaited(() async {
      await TouryLocationService.refreshStoredGeoLabels();
      if (!mounted) return;
      touryRecalculateCheckoutPrice();
      safeSetState(() {});
    }());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOsrm();
      calculateMinDistanceAndTime().then((result) {
        if (!mounted) return;
        setState(() {
          if (result != null) {
            previewDistance = result['distance'];
            previewTime = result['time'];
            _rejectedRoutePoints = result['rejected']?.round() ?? 0;
          }
        });
      });
    });

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().DriverGuideState == false) {
        FFAppState().aiRow = false;
        FFAppState().Minimumhours = touryMinimumBookingHours(
          landmarkCount: FFAppState().cartmkss.length,
          driverGuide: false,
        );
        safeSetState(() {});
      } else {
        FFAppState().Minimumhours = 0;
        safeSetState(() {});
      }
    });

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.linear,
            delay: 0.0.ms,
            duration: 460.0.ms,
            begin: const Offset(0.0, 1.0),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.select<FFAppState, int>(
      (s) => Object.hash(
        s.naimdolh,
        s.naimvillatext,
        s.naimmdenh,
        s.addcart,
        s.tebycar,
        s.typeHgz,
        s.IsLnstantAddress,
        s.cartmkss.length,
        s.saatcar,
        s.addhors,
      ),
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: TouryBrand.surfaceFor(context),
        drawer: Drawer(
          elevation: 16.0,
          child: WebViewAware(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  height: TouryLayout.drawerHeaderHeight(context),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22.0),
                      bottomRight: Radius.circular(22.0),
                      topLeft: Radius.circular(0.0),
                      topRight: Radius.circular(0.0),
                    ),
                    shape: BoxShape.rectangle,
                  ),
                  child: Align(
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: const AlignmentDirectional(0.0, 0.0),
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'mq4294hr' /* YOU ARE BROWSING NOW */,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      color:
                                          FlutterFlowTheme.of(context).tertiary,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                              ),
                            ),
                            Text(
                              FFAppState().naimdolh,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .labelSmallFamily,
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    fontSize: 20.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w100,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .labelSmallIsCustom,
                                  ),
                            ),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 11.0, 0.0, 0.0),
                                  child: InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                          LISTCountriesWidget.routeName);
                                    },
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        'vuz463hm' /* Change country */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            fontSize: 11.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .bodyMediumIsCustom,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]
                              .divide(const SizedBox(height: 4.0))
                              .around(const SizedBox(height: 4.0)),
                        ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: FlutterFlowIconButton(
                            borderColor: FlutterFlowTheme.of(context).primary,
                            borderRadius: 20.0,
                            borderWidth: 1.0,
                            buttonSize: 40.0,
                            fillColor: FlutterFlowTheme.of(context).primary,
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                              size: 18.0,
                            ),
                            onPressed: () async {
                              context.pushNamed(LISTCountriesWidget.routeName);
                            },
                          ),
                        ),
                      ]
                          .divide(const SizedBox(width: 16.0))
                          .around(const SizedBox(width: 16.0)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      children: [
                        Align(
                          alignment: const AlignmentDirectional(-1.0, -1.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 10.0, 0.0, 0.0),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                title: Text(
                                  FFLocalizations.of(context).getText(
                                    'yy1tb3mw' /* You are currently browsing. */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelLargeFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelLargeIsCustom,
                                      ),
                                ),
                                subtitle: Text(
                                  FFAppState().naimvillatext,
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelMediumIsCustom,
                                      ),
                                ),
                                tileColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                dense: false,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(-1.0, -1.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 10.0, 0.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(ListWidget.routeName);
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.map,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 25.0,
                                  ),
                                  title: Text(
                                    FFAppState().naimmdenh,
                                    textAlign: TextAlign.start,
                                    style: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelLargeFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelLargeIsCustom,
                                        ),
                                  ),
                                  subtitle: Text(
                                    FFLocalizations.of(context).getText(
                                      'n46e0sg0' /* Go now. */,
                                    ),
                                    textAlign: TextAlign.start,
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 12.0,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 20.0,
                                  ),
                                  tileColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  dense: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(-1.0, -1.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 11.0, 0.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(Checkout66Widget.routeName);
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.playlist_add,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 25.0,
                                  ),
                                  title: Text(
                                    FFAppState().addcart.toString(),
                                    style: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .titleLargeFamily,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 20.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .titleLargeIsCustom,
                                        ),
                                  ),
                                  subtitle: Text(
                                    FFLocalizations.of(context).getText(
                                      'oqt82ju4' /* Added destinations */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_sharp,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 20.0,
                                  ),
                                  tileColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  dense: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(1.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 11.0, 0.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(
                                    List22TaskOverviewResponsiveWidget
                                        .routeName);
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.mail_sharp,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 25.0,
                                  ),
                                  title: Text(
                                    FFLocalizations.of(context).getText(
                                      'v6yf1odi' /* My bookings */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelLargeFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelLargeIsCustom,
                                        ),
                                  ),
                                  subtitle: Text(
                                    FFLocalizations.of(context).getText(
                                      'kx4lgrt5' /* Booking list. */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 20.0,
                                  ),
                                  tileColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  dense: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(1.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 11.0, 0.0, 0.0),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: Icon(
                                  Icons.mail_sharp,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 25.0,
                                ),
                                title: Text(
                                  FFLocalizations.of(context).getText(
                                    'r4vmp44e' /* 0 */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .titleLargeFamily,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .titleLargeIsCustom,
                                      ),
                                ),
                                subtitle: Text(
                                  FFLocalizations.of(context).getText(
                                    'g3vg9g5t' /* رسائل جديدة */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelMediumIsCustom,
                                      ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                                tileColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                dense: false,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(-1.0, -1.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 11.0, 0.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(Profile05Widget.routeName);
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.settings_outlined,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 25.0,
                                  ),
                                  title: Text(
                                    FFLocalizations.of(context).getText(
                                      'y62g7p0k' /* Settings */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelLargeFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelLargeIsCustom,
                                        ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 20.0,
                                  ),
                                  tileColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  dense: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.3,
                  child: Divider(
                    height: 1.0,
                    thickness: 0.75,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: TouryBrand.tealDark,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 48.0,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22.0,
            ),
            onPressed: () async {
              if (FFAppState().typeHgz == 1) {
                context.pushNamed(
                  ListViWidget.routeName,
                  queryParameters: {
                    'cite': serializeParam(
                      FFAppState().villa,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                );
              } else {
                context.pushNamed(DemoDWidget.routeName);
              }
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'q0xxfq1y' /* My trip list */,
            ),
            style: const TextStyle(
              fontFamily: 'cairo',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: const [],
          centerTitle: true,
          elevation: 0,
        ),
        body: TouryAdaptiveScope(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: TouryLayout.bottomNavSafe(context) + 16,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!TouryPhoneUtil.hasUsablePhone(
                          phoneNumber: currentUserDocument?.phoneNumber,
                          phoneN: currentUserDocument?.phoneN,
                          authPhone: currentUser?.phoneNumber,
                        ))
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16.0, 16.0, 16.0, 16.0),
                        child: AuthUserStreamWidget(
                          builder: (context) => Container(
                            constraints: const BoxConstraints(minHeight: 80),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).error,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        size: 18.0,
                                      ),
                                      Flexible(
                                        child: Text(
                                          FFLocalizations.of(context)
                                              .getText('2n28fqm2'),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .secondaryBackground,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
                                                fontSize: 9.0,
                                              ),
                                        ),
                                      ),
                                    ].divide(const SizedBox(width: 4.0)),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FFButtonWidget(
                                      onPressed: () async {
                                        context.pushNamed(
                                            UpdateProfWidget.routeName);
                                      },
                                      text: FFLocalizations.of(context).getText(
                                        'vlo7yf10' /* Add your phone number */,
                                      ),
                                      icon: const Icon(
                                        Icons.add_outlined,
                                        size: 15.0,
                                      ),
                                      options: FFButtonOptions(
                                        height: 32.5,
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(16.0, 0.0, 16.0, 0.0),
                                        iconPadding: const EdgeInsetsDirectional
                                            .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                        color: FlutterFlowTheme.of(context)
                                            .warning,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmallFamily,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .titleSmallIsCustom,
                                            ),
                                        elevation: 0.0,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 8.0, 0.0, 0.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🔹 Distance & Time + Button
                          Row(
                            children: [
                              /// 📏 Distance & Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ui_text_12ee72ca4f'.tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.route, size: 8),
                                        Flexible(
                                          child: Text(
                                            _formatTripDistance(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 18),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _formatTripTime(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              /// 🗺️ Map Button — Flexible prevents Kyrgyz overflow
                              if (FFAppState().addcart >= 1)
                                Flexible(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FFButtonWidget(
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      context: context,
                                      builder: (context) {
                                        return GestureDetector(
                                          onTap: () =>
                                              FocusScope.of(context).unfocus(),
                                          child: Padding(
                                            padding: MediaQuery.viewInsetsOf(
                                                context),
                                            child: const MmaappWidget(),
                                          ),
                                        );
                                      },
                                    ).then((value) => safeSetState(() {}));
                                  },
                                  text: 'booking_view_route'.tr(),
                                  icon:
                                      const Icon(Icons.map_outlined, size: 18),
                                  options: FFButtonOptions(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    elevation: 0,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// ℹ️ Info Message
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'ui_text_d93bf2eb9f'.tr(),
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                if (touryBookingOptionsVisible())
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 9.0, 0.0, 9.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.pushNamed(ListCarWidget.routeName);
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            Icons.directions_car,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                          title: Text(
                            valueOrDefault<String>(
                              FFAppState().tebycar,
                              'ux_no_car_selected'.tr(),
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelLarge
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelLargeFamily,
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelLargeIsCustom,
                                ),
                          ),
                          subtitle: Text(
                            valueOrDefault<String>(
                              FFAppState().notcar,
                              'ux_preferred_car'.tr(),
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelMediumIsCustom,
                                ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 20.0,
                          ),
                          tileColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          dense: false,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11.0),
                              bottomRight: Radius.circular(11.0),
                              topLeft: Radius.circular(11.0),
                              topRight: Radius.circular(11.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (touryBookingOptionsVisible() &&
                    (FFAppState().IsLnstantAddress == false))
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 9.0, 0.0, 9.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.pushNamed(ListAdressSelectWidget.routeName);
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            Icons.location_pin,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                          title: Text(
                            valueOrDefault<String>(
                              FFAppState().villtextnow,
                              'ux_meeting_point'.tr(),
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelLarge
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelLargeFamily,
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelLargeIsCustom,
                                ),
                          ),
                          subtitle: Text(
                            valueOrDefault<String>(
                              FFAppState().adressNaim,
                              'ux_pick_meeting_point'.tr(),
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelMediumIsCustom,
                                ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 20.0,
                          ),
                          tileColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          dense: false,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11.0),
                              bottomRight: Radius.circular(11.0),
                              topLeft: Radius.circular(11.0),
                              topRight: Radius.circular(11.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (touryBookingOptionsVisible() &&
                    (FFAppState().IsLnstantAddress == true))
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 9.0, 0.0, 9.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        final loc =
                            await TouryLocationService.getUserPositionOrNull();
                        if (loc == null) {
                          await TouryDialogs.showLocationError(context);
                          return;
                        }
                        currentUserLocationValue = loc;
                        final confirmDialogResponse =
                            await TouryDialogs.confirmUpdateLocation(context);
                        if (!mounted) return;
                        if (confirmDialogResponse) {
                          final resolved =
                              await TouryLocationService.resolveFromCoordinates(
                            loc,
                          );
                          if (resolved.success && resolved.position != null) {
                            FFAppState().LOceshtoaddAdress =
                                resolved.coordinatesString;
                            safeSetState(() {});
                            FFAppState().IsLnstantAddress = true;
                            safeSetState(() {});
                            FFAppState().mkanuserorder = resolved.position;
                            FFAppState().fullAdress =
                                resolved.fullAddress ?? '';
                            FFAppState().adressNaim = resolved.villageName;
                            safeSetState(() {});
                            if (resolved.village != null) {
                              FFAppState().villa = resolved.village!.reference;
                              FFAppState().villnow =
                                  resolved.village!.reference;
                              FFAppState().villtextnow =
                                  touryLocalizedVillageLabel(resolved.village!);
                            }
                            safeSetState(() {});
                          } else {
                            await TouryDialogs.showLocationError(context);
                          }
                        }

                        safeSetState(() {});
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            Icons.location_pin,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                          title: Text(
                            valueOrDefault<String>(
                              FFAppState().villtextnow,
                              'ux_meeting_point'.tr(),
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelLarge
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelLargeFamily,
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelLargeIsCustom,
                                ),
                          ),
                          subtitle: Text(
                            FFAppState().fullAdress,
                            style: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelMediumIsCustom,
                                ),
                          ),
                          trailing: Icon(
                            Icons.settings_backup_restore,
                            color: FlutterFlowTheme.of(context).error,
                            size: 20.0,
                          ),
                          tileColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          dense: false,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11.0),
                              bottomRight: Radius.circular(11.0),
                              topLeft: Radius.circular(11.0),
                              topRight: Radius.circular(11.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (touryBookingOptionsVisible())
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 9.0, 0.0, 9.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        final datePickedDate = await showDatePicker(
                          context: context,
                          initialDate: getCurrentTimestamp,
                          firstDate: getCurrentTimestamp,
                          lastDate: DateTime(2050),
                          builder: (context, child) {
                            return wrapInMaterialDatePickerTheme(
                              context,
                              child!,
                              headerBackgroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              headerForegroundColor:
                                  FlutterFlowTheme.of(context).info,
                              headerTextStyle: FlutterFlowTheme.of(context)
                                  .headlineLarge
                                  .override(
                                    fontFamily: 'cairo',
                                    fontSize: 32.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                              pickerBackgroundColor:
                                  FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                              pickerForegroundColor:
                                  FlutterFlowTheme.of(context).primaryText,
                              selectedDateTimeBackgroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              selectedDateTimeForegroundColor:
                                  FlutterFlowTheme.of(context).info,
                              actionButtonForegroundColor:
                                  FlutterFlowTheme.of(context).error,
                              iconSize: 24.0,
                            );
                          },
                        );

                        TimeOfDay? datePickedTime;
                        if (datePickedDate != null) {
                          datePickedTime = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(getCurrentTimestamp),
                            builder: (context, child) {
                              // Wrap with MediaQuery to force 24-hour format
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  alwaysUse24HourFormat:
                                      true, // This is the key change
                                ),
                                child: wrapInMaterialTimePickerTheme(
                                  context,
                                  child!,
                                  headerBackgroundColor:
                                      FlutterFlowTheme.of(context).primary,
                                  headerForegroundColor:
                                      FlutterFlowTheme.of(context).info,
                                  headerTextStyle: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .override(
                                        fontFamily: 'cairo',
                                        fontSize: 32.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                  pickerBackgroundColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                  pickerForegroundColor:
                                      FlutterFlowTheme.of(context).primaryText,
                                  selectedDateTimeBackgroundColor:
                                      FlutterFlowTheme.of(context).primary,
                                  selectedDateTimeForegroundColor:
                                      FlutterFlowTheme.of(context).info,
                                  actionButtonForegroundColor:
                                      FlutterFlowTheme.of(context).error,
                                  iconSize: 24.0,
                                ),
                              );
                            },
                          );
                        }

                        if (datePickedDate != null && datePickedTime != null) {
                          safeSetState(() {
                            _model.datePicked = DateTime(
                              datePickedDate.year,
                              datePickedDate.month,
                              datePickedDate.day,
                              datePickedTime!.hour,
                              datePickedTime.minute,
                            );
                          });
                        } else if (_model.datePicked != null) {
                          safeSetState(() {
                            _model.datePicked = getCurrentTimestamp;
                          });
                        }
                        if (_model.datePicked != null) {
                          FFAppState().dataSchedule = _model.datePicked;
                          FFAppState().fulltextSchedule =
                              _model.datePicked!.toString();
                          safeSetState(() {});
                        }
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            Icons.schedule_rounded,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                          title: Text(
                            FFLocalizations.of(context).getText(
                              '04e2w4m3' /* Trip scheduling */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelLarge
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelLargeFamily,
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelLargeIsCustom,
                                ),
                          ),
                          subtitle: Text(
                            valueOrDefault<String>(
                              FFAppState().fulltextSchedule,
                              'ux_schedule_optional'.tr(),
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .labelMediumFamily,
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .labelMediumIsCustom,
                                ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 20.0,
                          ),
                          tileColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          dense: false,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11.0),
                              bottomRight: Radius.circular(11.0),
                              topLeft: Radius.circular(11.0),
                              topRight: Radius.circular(11.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (touryBookingOptionsVisible())
                  TouryCheckoutOptionTile(
                    icon: Icons.payment_rounded,
                    title: FFLocalizations.of(context).getText(
                      '97gi9omv' /* Payment method. */,
                    ),
                    subtitle: touryPaymentDisplayLabel(
                      valueOrDefault<String>(
                        FFAppState().payth,
                        TouryPaymentKeys.unset,
                      ),
                    ),
                    selected: !touryIsUnsetPaymentValue(FFAppState().payth),
                    onTap: () async {
                      await showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
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
                                child: Container(
                                  height: TouryLayout.sheetMaxHeight(context),
                                  decoration: BoxDecoration(
                                    color: TouryBrand.cardFor(context),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  child: const PaymentMethods2Widget(),
                                ),
                              ),
                            ),
                          );
                        },
                      ).then((value) => safeSetState(() {}));
                    },
                  ),
                if (_rejectedRoutePoints > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(7, 8, 7, 0),
                    child: TouryHelpBanner(
                      message: 'map_invalid_destinations'.tr(
                        namedArgs: {'count': '$_rejectedRoutePoints'},
                      ),
                      icon: Icons.wrong_location_outlined,
                      tone: TouryBannerTone.warning,
                    ),
                  ),
                if ((FFAppState().villnow != null) &&
                    (FFAppState().typecarRev != null))
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        7.0, 8.0, 7.0, 8.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            12.0, 12.0, 12.0, 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need extra hours?'.tr(),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            Text(
                              'Planning for a longer trip? Add more hours and enjoy the ride!'
                                  .tr(),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyMediumFamily,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyMediumIsCustom,
                                  ),
                            ),
                            // Drive time shorter than tour booking is normal —
                            // show informational ETA, not a red blocker warning.
                            if (_tripTimeHours != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.35),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.route_outlined,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'checkout_estimated_drive_info'.tr(
                                            namedArgs: {
                                              'time': _formatTripTime(),
                                            },
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'checkout_base_booking_duration'.tr(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmallFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 11.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .bodySmallIsCustom,
                                          ),
                                    ),
                                    Text(
                                      NumberFormat.decimalPattern(
                                        context.locale.toString(),
                                      ).format(FFAppState().saatcar),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLargeFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 11.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .bodyLargeIsCustom,
                                          ),
                                    ),
                                  ],
                                ),
                                ),
                                Flexible(
                                  child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              8.0, 0.0, 8.0, 0.0),
                                      child: Text(
                                        'checkout_extra_booking_duration'.tr(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmallFamily,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 11.0,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .bodySmallIsCustom,
                                            ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 120.0,
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            shape: BoxShape.rectangle,
                                          ),
                                          child: FlutterFlowCountController(
                                            decrementIconBuilder: (enabled) =>
                                                Icon(
                                              Icons.remove_rounded,
                                              color: enabled
                                                  ? FlutterFlowTheme.of(context)
                                                      .secondaryText
                                                  : FlutterFlowTheme.of(context)
                                                      .alternate,
                                              size: 18.0,
                                            ),
                                            incrementIconBuilder: (enabled) =>
                                                Icon(
                                              Icons.add_rounded,
                                              color: enabled
                                                  ? FlutterFlowTheme.of(context)
                                                      .primary
                                                  : FlutterFlowTheme.of(context)
                                                      .alternate,
                                              size: 18.0,
                                            ),
                                            countBuilder: (count) => Text(
                                              count.toString(),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleLarge
                                                  .override(
                                                    fontFamily:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleLargeFamily,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    fontSize: 18.0,
                                                    letterSpacing: 0.0,
                                                    shadows: [
                                                      Shadow(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .alternate,
                                                        offset: const Offset(
                                                            2.0, 2.0),
                                                        blurRadius: 2.0,
                                                      )
                                                    ],
                                                    useGoogleFonts:
                                                        !FlutterFlowTheme.of(
                                                                context)
                                                            .titleLargeIsCustom,
                                                  ),
                                            ),
                                            count: _model
                                                .countControllerValue ??= 0,
                                            updateCount: (count) async {
                                              final extra = count.clamp(0, 300);
                                              safeSetState(() =>
                                                  _model.countControllerValue = extra);
                                              // MUST set hours BEFORE recalculate — previous
                                              // code called touryRecalculateCheckoutPrice with
                                              // stale addhors then returned early when consistent.
                                              FFAppState().update(() {
                                                FFAppState().addhors = extra;
                                                FFAppState().totalsaat =
                                                    FFAppState().saatcar + extra;
                                              });
                                              touryRecalculateCheckoutPrice();
                                              safeSetState(() {});
                                            },
stepSize: 1,
                                            minimum: 0,
                                            maximum: 300,
                                            contentPadding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                    12.0, 0.0, 12.0, 0.0),
                                          ),
                                        ),
                                      ].divide(const SizedBox(width: 8.0)),
                                    ),
                                  ],
                                ),
                                ),
                              ].divide(const SizedBox(width: 12.0)),
                            ),
                            if (FFAppState().NsbhKsm >= 1.0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              4.0, 0.0, 4.0, 0.0),
                                      child: Icon(
                                        Icons.local_offer,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 10.0,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: Text(
                                      FFLocalizations.of(context)
                                          .getVariableText(
                                        enText: 'You get a  ${formatNumber(
                                          FFAppState().NsbhKsm,
                                          formatType: FormatType.percent,
                                        )}  discount for each additional hour you add, up to a maximum of  ${FFAppState().UbKsm.toString()}${FFAppState().RMZCurrency}',
                                        arText: 'checkout_extra_hour_discount'
                                            .tr(namedArgs: {
                                          'percent':
                                              FFAppState().NsbhKsm.toString(),
                                          'max': FFAppState().UbKsm.toString(),
                                          'currency': FFAppState().RMZCurrency,
                                        }),
                                        zh_HansText: 'You get a  ${formatNumber(
                                          FFAppState().NsbhKsm,
                                          formatType: FormatType.percent,
                                        )}  discount for each additional hour you add, up to a maximum of  ${FFAppState().UbKsm.toString()}${FFAppState().RMZCurrency}',
                                        trText: 'You get a  ${formatNumber(
                                          FFAppState().NsbhKsm,
                                          formatType: FormatType.percent,
                                        )}  discount for each additional hour you add, up to a maximum of  ${FFAppState().UbKsm.toString()}${FFAppState().RMZCurrency}',
                                        urText: 'You get a  ${formatNumber(
                                          FFAppState().NsbhKsm,
                                          formatType: FormatType.percent,
                                        )}  discount for each additional hour you add, up to a maximum of  ${FFAppState().UbKsm.toString()}${FFAppState().RMZCurrency}',
                                        ruText: 'You get a  ${formatNumber(
                                          FFAppState().NsbhKsm,
                                          formatType: FormatType.percent,
                                        )}  discount for each additional hour you add, up to a maximum of  ${FFAppState().UbKsm.toString()}${FFAppState().RMZCurrency}',
                                        azText: 'You get a  ${formatNumber(
                                          FFAppState().NsbhKsm,
                                          formatType: FormatType.percent,
                                        )}  discount for each additional hour you add, up to a maximum of  ${FFAppState().UbKsm.toString()}${FFAppState().RMZCurrency}',
                                        kaText: 'You get a  ${formatNumber(
                                          FFAppState().NsbhKsm,
                                          formatType: FormatType.percent,
                                        )}  discount for each additional hour you add, up to a maximum of  ${FFAppState().UbKsm.toString()}${FFAppState().RMZCurrency}',
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 10.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .bodyMediumIsCustom,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            Divider(
                              thickness: 1.0,
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ].divide(const SizedBox(height: 12.0)),
                        ),
                      ),
                    ).animateOnPageLoad(
                        animationsMap['containerOnPageLoadAnimation1']!),
                  ),
                if (FFAppState().addcart >= 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        16.0, 10.0, 0.0, 0.0),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        '3im46sag' /* List of added locations. */,
                      ),
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            fontFamily:
                                FlutterFlowTheme.of(context).labelMediumFamily,
                            letterSpacing: 0.0,
                            useGoogleFonts: !FlutterFlowTheme.of(context)
                                .labelMediumIsCustom,
                          ),
                    ),
                  ),
                if ((FFAppState().addcart <= 0) && (FFAppState().typeHgz != 2))
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        16.0, 16.0, 16.0, 0.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sentiment_dissatisfied,
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            size: 28.0,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'vbjndb7s' /* No tours have been added! */,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyMediumFamily,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    useGoogleFonts: !FlutterFlowTheme.of(context)
                                        .bodyMediumIsCustom,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (FFAppState().typeHgz == 2)
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 64),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(44.0),
                              topRight: Radius.circular(44.0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 12),
                              Icon(
                                  Icons.drive_eta_sharp,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  size: 22.0,
                                ),
                              const SizedBox(width: 8),
                              if (FFAppState().addcart <= 0)
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 18.0, 0.0),
                                    child: Text(
                                      FFLocalizations.of(context)
                                          .getText('un9qx6mz'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .bodyMediumIsCustom,
                                          ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (FFAppState().addcart >= 1 && FFAppState().typeHgz != 2)
                  Builder(
                    builder: (context) {
                      final mkss = FFAppState().cartmkss.toList();

                      return SingleChildScrollView(
                        child: Column(
                          children: List.generate(mkss.length, (mkssIndex) {
                            final mkssItem = mkss[mkssIndex];
                            return ListView(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      12.0, 8.0, 8.0, 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      0.0, 0.0, 0.0, 8.0),
                                              child: Text(
                                                mkssItem.naim,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLargeFamily,
                                                          fontSize: 15.0,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelLargeIsCustom,
                                                        ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      0.0, 0.0, 0.0, 8.0),
                                              child: Text(
                                                mkssItem.textivill,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLargeFamily,
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelLargeIsCustom,
                                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ),
                                      FlutterFlowIconButton(
                                        borderColor: Colors.transparent,
                                        borderRadius: 30.0,
                                        borderWidth: 1.0,
                                        buttonSize: 40.0,
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          size: 20.0,
                                        ),
                                        onPressed: () async {
                                          FFAppState()
                                              .removeFromCartmkss(mkssItem);
                                          FFAppState().addcart =
                                              FFAppState().addcart + -1;
                                          FFAppState().Minimumhours =
                                              (FFAppState().addcart / 2)
                                                  .toInt();
                                          final mkanRef = mkssItem.revmkan;
                                          if (mkanRef != null) {
                                            FFAppState()
                                                .removeFromMkan(mkanRef);
                                          }
                                          FFAppState().update(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      );
                    },
                  ),
                if (FFAppState().addcart >= 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (kDebugMode &&
                          (valueOrDefault<bool>(
                                  currentUserDocument?.actevMndob, false) ==
                              true) &&
                          (currentUserUid == '00900'))
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 19.0, 0.0, 11.0),
                          child: AuthUserStreamWidget(
                            builder: (context) => SizedBox(
                              width: 200.0,
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                autofocus: false,
                                readOnly: true,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText:
                                      FFLocalizations.of(context).getText(
                                    'njvlci0g' /* عدد الساعات المطلوبة */,
                                  ),
                                  labelStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelMediumIsCustom,
                                      ),
                                  hintText: FFLocalizations.of(context).getText(
                                    'lxw2tgd1' /* TextField */,
                                  ),
                                  hintStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelMediumIsCustom,
                                      ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0x00000000),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                keyboardType: TextInputType.number,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primaryText,
                                validator: _model.textControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((FFAppState().villnow != null) &&
                        (FFAppState().typecarRev != null))
                      TouryPriceSummaryCard(
                        title: ' Price Summary'.tr(),
                        children: [
                          TouryPriceSummaryRow(
                            label: 'checkout_total_booking_duration'.tr(),
                            value: valueOrDefault<String>(
                              NumberFormat.decimalPattern(
                                context.locale.toString(),
                              ).format(FFAppState().totalsaat),
                              '0',
                            ),
                          ),
                          TouryPriceSummaryRow(
                            label: 'Driver Fee:'.tr(),
                            value: _formatMoney(FFAppState().totalmndob3),
                          ),
                          TouryPriceSummaryRow(
                            label: 'checkout_app_fee'.tr(),
                            value: _formatMoney(FFAppState().totalapp2),
                          ),
                          if (FFAppState().isVat == true)
                            TouryPriceSummaryRow(
                              label: 'checkout_vat_rate'.tr(
                                namedArgs: {
                                  'rate': FFAppState().VatDolh.toString(),
                                },
                              ),
                              value: _formatMoney(FFAppState().vat2),
                            ),
                          if ((FFAppState().addhors >= 1) &&
                              (FFAppState().NsbhKsm >= 1.0))
                            TouryPriceSummaryRow(
                              label: FFLocalizations.of(context).getText(
                                'fy9yp6wj' /* Total Deductions: */,
                              ),
                              value: _formatMoney(FFAppState().totalKsm2),
                              isDeduction: true,
                            ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: TouryBrand.border,
                            ),
                          ),
                          TouryPriceSummaryRow(
                            label: FFLocalizations.of(context).getText(
                              'jdq5i83p' /* Total Amount: */,
                            ),
                            value: _formatMoney(FFAppState().totalAllnow3),
                            isTotal: true,
                          ),
                          if (!touryIsCashPaymentValue(FFAppState().payth) &&
                              FFAppState().payth.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TouryGradientButton(
                                label: _isPaying
                                    ? 'checkout_paying'.tr()
                                    : FFLocalizations.of(context).getText(
                                        'hgw4quay' /* Pay Now */,
                                      ),
                                icon: _isPaying
                                    ? Icons.hourglass_top_rounded
                                    : Icons.payment_rounded,
                                height: 52,
                                onPressed: _isPaying
                                    ? null
                                    : () async {
                                        if ((FFAppState().Minimumhours >= 2) &&
                                            (FFAppState().totalsaat <
                                                FFAppState().Minimumhours)) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'checkout_min_hours_hint'
                                                    .tr(namedArgs: {
                                                  'hours': FFAppState()
                                                      .Minimumhours
                                                      .toString(),
                                                }),
                                                style: TextStyle(
                                                  fontFamily: 'cairo',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                ),
                                              ),
                                              duration: const Duration(
                                                  milliseconds: 4000),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                            ),
                                          );
                                        } else {
                                          if (!touryHasElectronicPaymentSelected()) {
                                            TouryDialogs.showSnackBar(
                                              context,
                                              'ux_choose_payment_method'.tr(),
                                              type: TouryMessageType.error,
                                            );
                                            return;
                                          }

                                          setState(() => _isPaying = true);
                                          try {
                                            final carRef =
                                                FFAppState().typecarRev;
                                            final countryRef =
                                                FFAppState().dolh;
                                            if (carRef == null ||
                                                countryRef == null) {
                                              TouryDialogs.showSnackBar(
                                                context,
                                                'checkout_location_required'
                                                    .tr(),
                                                type: TouryMessageType.error,
                                              );
                                              return;
                                            }
                                            final quote =
                                                touryRecalculateCheckoutPrice();
                                            final payResult =
                                                await touryExecuteCardPayment(
                                              description:
                                                  '$currentUserDisplayName / ${'ux_new_booking'.tr()} — ${'ux_hours_count'.tr(namedArgs: {
                                                    'count': FFAppState()
                                                        .totalsaat
                                                        .toString(),
                                                  })} - ${FFAppState().naimvillatext}',
                                              amountHalalas:
                                                  quote.customerTotalHalalas,
                                              carPath: carRef.path,
                                              countryPath: countryRef.path,
                                              bookingHours: quote.bookingHours,
                                              additionalHours:
                                                  FFAppState().addhors,
                                            );

                                            _model.apiResultr5n =
                                                payResult.response;

                                            if (!payResult.success) {
                                              TouryDialogs.showSnackBar(
                                                context,
                                                payResult.errorMessage ??
                                                    'checkout_payment_card_error'
                                                        .tr(),
                                                type: TouryMessageType.error,
                                              );
                                            } else {
                                              await touryNavigateAfterCardPayment(
                                                context,
                                                result: payResult,
                                                paymentFlowType: TypeHgz.Rhlh,
                                                onPaidWithoutWebView: () {
                                                  context.pushNamed(
                                                    PaymentConfirmWidget
                                                        .routeName,
                                                    queryParameters: {
                                                      'fromWebView':
                                                          serializeParam(
                                                        false,
                                                        ParamType.bool,
                                                      ),
                                                    }.withoutNulls,
                                                  );
                                                },
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isPaying = false);
                                            }
                                          }
                                        }

                                        safeSetState(() {});
                                      },
                              ),
                            ),
                        ],
                      ),
                    if ((valueOrDefault(currentUserDocument?.phoneN, 0)
                                .toString() !=
                            '') &&
                        touryIsCashBookNowPayment(FFAppState().payth) &&
                        (FFAppState().DriverGuideState == true))
                      AuthUserStreamWidget(
                        builder: (context) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 64.1,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                              ),
                              child: Visibility(
                                visible: (valueOrDefault(
                                                currentUserDocument?.phoneN, 0)
                                            .toString() !=
                                        '') &&
                                    touryIsCashBookNowPayment(
                                        FFAppState().payth),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    touryEnsureCashPaymentIfUnset();
                                    touryPrepareCheckoutState();
                                    if (!touryCheckoutReadyForBooking()) {
                                      await TouryDialogs.showSelectAllOptions(
                                          context);
                                      return;
                                    }
                                    await Future.wait([
                                      Future(() async {
                                        if (touryCheckoutReadyForBooking()) {
                                          _model.conOrder =
                                              await queryOrderRecordCount();
                                          _model.ngl = await TouryFirestoreCache
                                              .settingsRecordOnce(
                                            queryBuilder: (settingsRecord) =>
                                                settingsRecord.where(
                                              'id',
                                              isEqualTo: 1,
                                            ),
                                            singleRecord: true,
                                          );
                                          try {
                                            final cashBooking =
                                                await touryCreateCashBookingFromCurrentState();
                                            if (!cashBooking.success) {
                                              throw StateError(
                                                    cashBooking.error ??
                                                    'booking_save_failed',
                                              );
                                            }
                                            FFAppState().paymentIdempotencyKey =
                                                '';
                                          } catch (e) {
                                            debugPrint('Order save failed: $e');
                                            if (context.mounted) {
                                              TouryDialogs.showSnackBar(
                                                context,
                                                e is StateError
                                                    ? ErrorLocalizer.fromCode(
                                                        e.message,
                                                      )
                                                    : ErrorLocalizer.fromObject(
                                                        e,
                                                      ),
                                                type: TouryMessageType.error,
                                              );
                                            }
                                            return;
                                          }

                                          final notifyHours =
                                              FFAppState().totalsaat;
                                          final notifyPay =
                                              FFAppState().totalmndob3;
                                          final notifyCurrency =
                                              FFAppState().RMZCurrency;
                                          final notifyVill =
                                              FFAppState().villnow;
                                          final notifyCar =
                                              FFAppState().typecarRev;
                                          final notifyNgl = true; // online drivers only
                                          // مسح الخصومات
                                          FFAppState().typeHgz = 0;
                                          FFAppState().AllowBooking = false;
                                          FFAppState().DriverGuideState = false;
                                          FFAppState().NsbhKsm = 0.0;
                                          FFAppState().totalKsm = 0;
                                          FFAppState().UbKsm = 0;
                                          FFAppState().totalKsm2 = 0.0;
                                          FFAppState().totalAllnow3 = 0.0;
                                          safeSetState(() {});

                                          await touryOnBookingSuccess(context);

                                          FFAppState().typecarRev = null;
                                          FFAppState().addcart = 0;
                                          FFAppState().cartItems = [];
                                          FFAppState().cartmkss = [];
                                          FFAppState().cartPriceSummary = [];
                                          FFAppState().saatcar = 0;
                                          FFAppState().totalsaatandcar = 0;
                                          FFAppState().srtypecar = 0;
                                          FFAppState().tebycar = '';
                                          FFAppState().notcar = '';
                                          FFAppState().adressNaim = '';
                                          FFAppState().adressSelection = null;
                                          FFAppState().fulltextSchedule = '';
                                          FFAppState().taimSchedule = '';
                                          FFAppState().TOTALmndob2 = 0;
                                          FFAppState().totalapp2 = 0;
                                          FFAppState().vat2 = 0;
                                          FFAppState().totalAllNow2 = 0;
                                          safeSetState(() {});

                                          unawaited(
                                            touryNotifyAgentsForNewOrder(
                                              villnow: notifyVill,
                                              typecarRev: notifyCar,
                                              nglValue: notifyNgl,
                                              totalsaat: notifyHours,
                                              totalmndob3: notifyPay,
                                              currency: notifyCurrency,
                                              countryRef: FFAppState().dolh,
                                              cityRef: FFAppState().mdenh,
                                            ),
                                          );
                                          FFAppState().totalmndob3 = 0.0;
                                          safeSetState(() {});
                                        } else {
                                          await TouryDialogs
                                              .showSelectAllOptions(context);
                                        }
                                      }),
                                      Future(() async {}),
                                    ]);

                                    safeSetState(() {});
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    '4pp7yghj' /* Book now */,
                                  ),
                                  icon: const Icon(
                                    Icons.send,
                                    size: 22.0,
                                  ),
                                  options: FFButtonOptions(
                                    height: 44.0,
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            24.0, 0.0, 24.0, 0.0),
                                    iconPadding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmallFamily,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 22.0,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .titleSmallIsCustom,
                                        ),
                                    elevation: 3.0,
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if ((valueOrDefault(currentUserDocument?.phoneN, 0)
                                .toString() !=
                            '') &&
                        touryIsCashBookNowPayment(FFAppState().payth) &&
                        (FFAppState().DriverGuideState == false))
                      AuthUserStreamWidget(
                        builder: (context) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 64.1,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                              ),
                              child: Visibility(
                                visible: (valueOrDefault(
                                                currentUserDocument?.phoneN, 0)
                                            .toString() !=
                                        '') &&
                                    touryIsCashBookNowPayment(
                                        FFAppState().payth),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    touryEnsureCashPaymentIfUnset();
                                    touryPrepareCheckoutState();

                                    final missingHours =
                                        touryMissingBookingHours(
                                      bookingHours:
                                          FFAppState().totalsaat.toDouble(),
                                      previewTimeHours: _tripTimeHours,
                                      osrmTimeMinutes: osrmTime,
                                      landmarkCount:
                                          FFAppState().cartmkss.length,
                                    );
                                    if (missingHours != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            FFLocalizations.of(context)
                                                .getVariableText(
                                              enText:
                                                  'Please add at least $missingHours more hour(s) to continue.',
                                              arText:
                                                  'checkout_add_hours_prompt'
                                                      .tr(namedArgs: {
                                                'hours': '$missingHours',
                                              }),
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'cairo',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                          ),
                                          duration: const Duration(
                                              milliseconds: 4000),
                                          backgroundColor:
                                              FlutterFlowTheme.of(context)
                                                  .error,
                                        ),
                                      );
                                      return;
                                    }

                                    if (!touryCheckoutReadyForBooking()) {
                                      await TouryDialogs.showSelectAllOptions(
                                          context);
                                      return;
                                    }

                                    await Future.wait([
                                      Future(() async {
                                        if (touryCheckoutReadyForBooking()) {
                                          _model.conOrder2 =
                                              await queryOrderRecordCount();
                                          _model.ngl2 =
                                              await querySettingsRecordOnce(
                                            queryBuilder: (settingsRecord) =>
                                                settingsRecord.where(
                                              'id',
                                              isEqualTo: 1,
                                            ),
                                            singleRecord: true,
                                          ).then((s) => s.firstOrNull);
                                          try {
                                            final cashBooking =
                                                await touryCreateCashBookingFromCurrentState();
                                            if (!cashBooking.success) {
                                              throw StateError(
                                                    cashBooking.error ??
                                                    'booking_save_failed',
                                              );
                                            }
                                            FFAppState().paymentIdempotencyKey =
                                                '';
                                          } catch (e) {
                                            debugPrint('Order save failed: $e');
                                            if (context.mounted) {
                                              TouryDialogs.showSnackBar(
                                                context,
                                                e is StateError
                                                    ? ErrorLocalizer.fromCode(
                                                        e.message,
                                                      )
                                                    : ErrorLocalizer.fromObject(
                                                        e,
                                                      ),
                                                type: TouryMessageType.error,
                                              );
                                            }
                                            return;
                                          }

                                          final notifyHours =
                                              FFAppState().totalsaat;
                                          final notifyPay =
                                              FFAppState().totalmndob3;
                                          final notifyCurrency =
                                              FFAppState().RMZCurrency;
                                          final notifyVill =
                                              FFAppState().villnow;
                                          final notifyCar =
                                              FFAppState().typecarRev;
                                          final notifyNgl = true; // online drivers only
                                          // مسح الخصومات
                                          FFAppState().typeHgz = 0;
                                          FFAppState().AllowBooking = false;
                                          FFAppState().DriverGuideState = false;
                                          FFAppState().NsbhKsm = 0.0;
                                          FFAppState().totalKsm = 0;
                                          FFAppState().UbKsm = 0;
                                          FFAppState().totalKsm2 = 0.0;
                                          FFAppState().totalAllnow3 = 0.0;
                                          safeSetState(() {});

                                          await touryOnBookingSuccess(context);

                                          FFAppState().typecarRev = null;
                                          FFAppState().addcart = 0;
                                          FFAppState().cartItems = [];
                                          FFAppState().cartmkss = [];
                                          FFAppState().cartPriceSummary = [];
                                          FFAppState().saatcar = 0;
                                          FFAppState().totalsaatandcar = 0;
                                          FFAppState().srtypecar = 0;
                                          FFAppState().tebycar = '';
                                          FFAppState().notcar = '';
                                          FFAppState().adressNaim = '';
                                          FFAppState().adressSelection = null;
                                          FFAppState().fulltextSchedule = '';
                                          FFAppState().taimSchedule = '';
                                          FFAppState().TOTALmndob2 = 0;
                                          FFAppState().totalapp2 = 0;
                                          FFAppState().vat2 = 0;
                                          FFAppState().totalAllNow2 = 0;
                                          safeSetState(() {});

                                          unawaited(
                                            touryNotifyAgentsForNewOrder(
                                              villnow: notifyVill,
                                              typecarRev: notifyCar,
                                              nglValue: notifyNgl,
                                              totalsaat: notifyHours,
                                              totalmndob3: notifyPay,
                                              currency: notifyCurrency,
                                              countryRef: FFAppState().dolh,
                                              cityRef: FFAppState().mdenh,
                                            ),
                                          );
                                          FFAppState().totalmndob3 = 0.0;
                                          safeSetState(() {});
                                          // ====== PREVIEW TIME SAFE CHECK ======
                                          // ===== SAFE HOURS VALUES =====
                                        } else {
                                          await TouryDialogs
                                              .showSelectAllOptions(context);
                                        }
                                      }),
                                      Future(() async {}),
                                    ]);

                                    safeSetState(() {});
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    '6o9re56s' /* Book now */,
                                  ),
                                  icon: const Icon(
                                    Icons.send,
                                    size: 22.0,
                                  ),
                                  options: FFButtonOptions(
                                    height: 44.0,
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            24.0, 0.0, 24.0, 0.0),
                                    iconPadding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmallFamily,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 22.0,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .titleSmallIsCustom,
                                        ),
                                    elevation: 3.0,
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
