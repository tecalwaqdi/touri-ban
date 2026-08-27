import '/core/toury_geo_display.dart';
import '/design_system/design_system.dart';
import '/core/toury_order_integration.dart';
import '/core/payments/touri_payment_experience_service.dart';
import '/core/toury_payment_flow.dart';
import '/core/app_design_system.dart';
import '/core/app_ux_widgets.dart';
import '/core/toury_brand_widgets.dart';
import '/core/toury_location_service.dart';
import '/core/toury_booking_agents.dart';
import '/core/toury_booking_service.dart';
import '/core/payments/touri_payment_lock.dart';
import '/core/toury_active_booking_guard.dart';
import '/components/touri_checkout_payment_section.dart';
import '/core/toury_async_action_guard.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_payment_labels.dart';
import '/core/toury_landmark_filter.dart';
import '/core/toury_landmark_cart.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_profile_completeness.dart';
import '/core/toury_ngenius.dart';
import '/core/toury_navigation.dart';
import '/core/toury_polyline.dart';
import '/core/toury_route_metrics.dart';
import '/core/toury_distance_format.dart';
import '/core/toury_directions_service.dart';
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
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_count_controller.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'checkout66_model.dart';
export 'checkout66_model.dart';

Future<Map<String, double>?> calculateMinDistanceAndTime() async {
  // Booking pickup / city center first; GPS only as last resort.
  LatLng? origin = touryResolveTripRouteOrigin();
  origin ??= await TouryLocationService.getUserPositionOrNull();
  final validation = touryValidateRoutePoints(
    origin: origin,
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
  bool _isBookingCash = false;
  static const _payActionKey = 'payment:checkout_card';
  static const _cashActionKey = 'booking:create:cash';

  Future<void> _onPayNowPressed() async {
    // Synchronous lock BEFORE any await — same frame visual feedback.
    if (_isPaying || !TouryAsyncActionGuard.tryStart(_payActionKey)) {
      return;
    }
    setState(() => _isPaying = true);

    try {
      if ((FFAppState().Minimumhours >= 2) &&
          (FFAppState().totalsaat < FFAppState().Minimumhours)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'checkout_min_hours_hint'.tr(namedArgs: {
                'hours': FFAppState().Minimumhours.toString(),
              }),
              style: TextStyle(
                fontFamily: 'cairo',
                color: FlutterFlowTheme.of(context).secondaryBackground,
              ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
        return;
      }

      if (!touryHasElectronicPaymentSelected()) {
        if (!mounted) return;
        TouryDialogs.showSnackBar(
          context,
          'ux_choose_payment_method'.tr(),
          type: TouryMessageType.error,
        );
        return;
      }

      // Same unpaid draft must RESUME — never "payment in progress for another booking".
      final gate = await touryEvaluateActiveBookingGate(
        currentOrderId: FFAppState().pendingPaymentOrderId.isNotEmpty
            ? FFAppState().pendingPaymentOrderId
            : (FFAppState().paymentOrderId.isNotEmpty
                ? FFAppState().paymentOrderId
                : null),
      );
      if (gate.blocked) {
        if (mounted) {
          await touryShowPaymentLockDialog(
            context,
            gate: gate,
            otherPayment: gate.decision.kind ==
                TouriPaymentLockKind.conflictOtherPayment,
          );
        }
        return;
      }
      if (gate.decision.kind == TouriPaymentLockKind.paidBlock) {
        if (mounted) {
          TouryDialogs.showSnackBar(
            context,
            'checkout_payment_paid'.tr(),
            type: TouryMessageType.success,
          );
        }
        return;
      }

      final resumeId = gate.resumeOrderId;
      if (resumeId.isNotEmpty) {
        FFAppState().pendingPaymentOrderId = resumeId;
        FFAppState().paymentIdempotencyKey =
            touriStableOrderIdempotencyKey(resumeId);
      }

      final carRef = FFAppState().typecarRev;
      final countryRef = FFAppState().dolh;
      if (carRef == null || countryRef == null) {
        if (!mounted) return;
        TouryDialogs.showSnackBar(
          context,
          'checkout_location_required'.tr(),
          type: TouryMessageType.error,
        );
        return;
      }

      final quote = touryRecalculateCheckoutPrice();
      final payResult = await TouryPaymentExperienceService().startCardCheckout(
        context: context,
        description:
            '$currentUserDisplayName / ${'ux_new_booking'.tr()} — ${'ux_hours_count'.tr(namedArgs: {
              'count': FFAppState().totalsaat.toString(),
            })} - ${FFAppState().naimvillatext}',
        amountHalalas: quote.customerTotalHalalas,
        carPath: carRef.path,
        countryPath: countryRef.path,
        bookingHours: quote.bookingHours,
        additionalHours: FFAppState().addhors,
        orderPath: resumeId.isNotEmpty ? 'order/$resumeId' : null,
      );

      if (!mounted) return;

      _model.apiResultr5n = payResult.response;

      if (!payResult.success) {
        final cancelled =
            (payResult.status ?? '').toLowerCase() == 'cancelled';
        TouryDialogs.showSnackBar(
          context,
          payResult.errorMessage ??
              'checkout_payment_temporarily_unavailable'.tr(),
          type: cancelled
              ? TouryMessageType.warning
              : TouryMessageType.error,
        );
      } else {
        await touryNavigateAfterCardPayment(
          context,
          result: payResult,
          paymentFlowType: TypeHgz.Rhlh,
          onPaidWithoutWebView: () {
            if (!context.mounted) return;
            context.pushNamed(
              PaymentConfirmWidget.routeName,
              queryParameters: {
                'fromWebView': serializeParam(false, ParamType.bool),
              }.withoutNulls,
            );
          },
        );
      }
    } finally {
      TouryAsyncActionGuard.finish(_payActionKey);
      if (mounted) {
        setState(() => _isPaying = false);
      } else {
        _isPaying = false;
      }
    }
  }

  Future<void> _onPrimaryCheckoutPressed() async {
    if (touryIsCashBookNowPayment(FFAppState().payth)) {
      await _onConfirmCashPressed();
      return;
    }
    if (touryHasElectronicPaymentSelected()) {
      await _onPayNowPressed();
      return;
    }
    if (!mounted) return;
    TouryDialogs.showSnackBar(
      context,
      'ux_choose_payment_method'.tr(),
      type: TouryMessageType.error,
    );
  }

  Future<void> _onConfirmCashPressed() async {
    if (_isBookingCash || !TouryAsyncActionGuard.tryStart(_cashActionKey)) {
      return;
    }
    setState(() => _isBookingCash = true);
    try {
      if (!TouryProfileCompleteness.hasUsablePhone()) {
        if (mounted) {
          TouryDialogs.showSnackBar(
            context,
            'profile_phone_required'.tr(),
            type: TouryMessageType.error,
          );
        }
        return;
      }
      touryEnsureCashPaymentIfUnset();
      touryPrepareCheckoutState();
      if (!touryCheckoutReadyForBooking()) {
        await TouryDialogs.showSelectAllOptions(context);
        return;
      }

      final gate = await touryEvaluateActiveBookingGate();
      if (gate.blocked &&
          gate.decision.kind != TouriPaymentLockKind.resumeUnpaidCheckout &&
          gate.decision.kind != TouriPaymentLockKind.resumeSame) {
        if (mounted) {
          await touryShowPaymentLockDialog(
            context,
            gate: gate,
            otherPayment: gate.decision.kind ==
                TouriPaymentLockKind.conflictOtherPayment,
          );
        }
        return;
      }

      final cashBooking = await touryCreateCashBookingFromCurrentState();
      if (!cashBooking.success) {
        if (!mounted) return;
        TouryDialogs.showSnackBar(
          context,
          ErrorLocalizer.fromCode(cashBooking.error ?? 'booking_save_failed'),
          type: TouryMessageType.error,
        );
        return;
      }
      FFAppState().paymentIdempotencyKey = '';

      final notifyHours = FFAppState().totalsaat;
      final notifyPay = FFAppState().totalmndob3;
      final notifyCurrency = FFAppState().RMZCurrency;
      final notifyVill = FFAppState().villnow;
      final notifyCar = FFAppState().typecarRev;
      final notifyDriverGuide =
          FFAppState().DriverGuideState == true || FFAppState().typeHgz == 2;
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
          nglValue: true,
          totalsaat: notifyHours,
          totalmndob3: notifyPay,
          currency: notifyCurrency,
          countryRef: FFAppState().dolh,
          cityRef: FFAppState().mdenh,
          driverGuideOnly: notifyDriverGuide,
        ),
      );
      FFAppState().totalmndob3 = 0.0;
      safeSetState(() {});
    } finally {
      TouryAsyncActionGuard.finish(_cashActionKey);
      if (mounted) {
        setState(() => _isBookingCash = false);
      } else {
        _isBookingCash = false;
      }
    }
  }

  int _rejectedRoutePoints = 0;
  /// Set in [dispose] so in-flight OSRM / preview callbacks skip setState.
  bool _routeCalcCancelled = false;

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
    if (isCalculating && (_tripDistanceKm == null || _tripDistanceKm! <= 0)) {
      return '…';
    }
    final raw = _tripDistanceKm;
    if (raw == null || raw <= 0) return 'ux_not_available'.tr();
    final formatted = touryFormatDistanceKm(
      raw,
      locale: context.locale.toString(),
    );
    return formatted.isEmpty ? 'ux_not_available'.tr() : formatted;
  }

  String _formatTripTime() {
    if (isCalculating && _tripTimeHours == null) {
      return '…';
    }
    final hours = _tripTimeHours;
    if (hours == null || hours <= 0) return 'ux_not_available'.tr();
    if (hours < 1) {
      final minutes = (hours * 60).round();
      final shown = minutes < 1 ? 1 : minutes;
      return 'minutes_count'.tr(namedArgs: {'count': '$shown'});
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

  String _routeFingerprint() {
    final app = FFAppState();
    final origin = touryResolveTripRouteOrigin(app);
    final buf = StringBuffer()
      ..write(origin?.latitude)
      ..write(',')
      ..write(origin?.longitude);
    for (final stop in app.cartmkss) {
      buf
        ..write('|')
        ..write(stop.loceshn?.latitude)
        ..write(',')
        ..write(stop.loceshn?.longitude);
    }
    return buf.toString();
  }

  String? _lastRouteFingerprint;

  void _invalidateRouteMetrics() {
    osrmDistance = 0;
    osrmTime = 0;
    previewDistance = null;
    previewTime = null;
    FFAppState().update(() {
      FFAppState().osrmTotalDistance = 0;
      FFAppState().osrmTotalTime = 0;
    });
  }

  Future<void> _refreshRouteMetrics() async {
    if (!mounted || _routeCalcCancelled) return;
    _invalidateRouteMetrics();
    if (mounted) setState(() => isCalculating = true);
    await Future.wait<void>([
      _calculateOsrm(),
      calculateMinDistanceAndTime().then((result) {
        if (!mounted || _routeCalcCancelled) return;
        setState(() {
          if (result != null) {
            previewDistance = result['distance'];
            previewTime = result['time'];
            _rejectedRoutePoints = result['rejected']?.round() ?? 0;
          }
        });
      }),
    ]);
  }

  void _maybeRecalcRouteAfterCartChange() {
    final next = _routeFingerprint();
    if (_lastRouteFingerprint == next) return;
    _lastRouteFingerprint = next;
    unawaited(_refreshRouteMetrics());
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
    if (!mounted || _routeCalcCancelled) return;
    setState(() => isCalculating = true);

    try {
      LatLng? origin = touryResolveTripRouteOrigin();
      origin ??= await TouryLocationService.getUserPositionOrNull();
      if (!mounted || _routeCalcCancelled) return;
      if (origin == null) {
        setState(() => isCalculating = false);
        return;
      }

      final validation = touryValidateRoutePoints(
        origin: origin,
        destinations: FFAppState().cartmkss.map((e) => e.loceshn),
        selectedAreaCenter: FFAppState().latlngvill,
      );
      if (!mounted || _routeCalcCancelled) return;
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

      // Prefer Google Routes (traffic-aware) when authenticated; OSRM as fallback.
      if (loggedIn) {
        final googleRoute = await TouryDirectionsService.fetchRoadRouteResult(
          validation.points,
          language: context.locale.toString(),
          region: 'sa',
          optimal: true,
        );
        if (!mounted || _routeCalcCancelled) return;
        if (googleRoute != null &&
            googleRoute.distanceMeters > 0 &&
            googleRoute.durationSeconds > 0) {
          final distanceKm = touryMetersToKm(googleRoute.distanceMeters.toDouble());
          if (touryRoadMetricsArePlausible(
            distanceKm: distanceKm,
            durationSeconds: googleRoute.durationSeconds.toDouble(),
            points: validation.points,
          )) {
            setState(() {
              osrmTime = googleRoute.durationSeconds / 60;
              osrmDistance = distanceKm;
              _rejectedRoutePoints = validation.rejectedCount;
              isCalculating = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _routeCalcCancelled) return;
              FFAppState().update(() {
                FFAppState().osrmTotalTime = osrmTime;
                FFAppState().osrmTotalDistance = distanceKm;
                FFAppState().osrmCalculationTime = DateTime.now();
              });
            });
            return;
          }
        }
      }

      // Build coordinates from validated points (pickup → stops in cart order).
      final coordinates = validation.points
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final url =
          'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline&steps=false';

      final response = await http.get(Uri.parse(url));
      if (!mounted || _routeCalcCancelled) return;

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
            if (!mounted || _routeCalcCancelled) return;
            final estimate = touryEstimateRoute(validation.points);
            setState(() {
              previewDistance = estimate.distanceKm;
              previewTime = estimate.durationHours;
              isCalculating = false;
              _rejectedRoutePoints = validation.rejectedCount;
            });
            return;
          }
          if (!mounted || _routeCalcCancelled) return;
          setState(() {
            osrmTime = durationSeconds / 60;
            osrmDistance = distanceKm;
            _rejectedRoutePoints = validation.rejectedCount;
            isCalculating = false;
          });
          // Defer app-state notify so it never runs synchronously during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _routeCalcCancelled) return;
            FFAppState().update(() {
              FFAppState().osrmTotalTime = osrmTime;
              FFAppState().osrmTotalDistance = distanceKm;
              FFAppState().osrmCalculationTime = DateTime.now();
            });
          });
        } else {
          setState(() => isCalculating = false);
        }
      } else {
        setState(() => isCalculating = false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OSRM error: $e');
      }
      if (!mounted || _routeCalcCancelled) return;
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
    _model.countControllerValue = 0;

    // Defer FFAppState mutations / geo refresh off the build path.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _routeCalcCancelled) return;
      FFAppState().addhors = 0;
      if (FFAppState().saatcar > 0) {
        FFAppState().totalsaat = FFAppState().saatcar;
      }
      touryPurgeBannedCartItems();
      touryPrepareCheckoutState(resetExtraHours: true);
      unawaited(() async {
        await TouryLocationService.refreshStoredGeoLabels();
        if (!mounted || _routeCalcCancelled) return;
        touryRecalculateCheckoutPrice();
        safeSetState(() {});
      }());
      _lastRouteFingerprint = _routeFingerprint();
      unawaited(_calculateOsrm());
      unawaited(calculateMinDistanceAndTime().then((result) {
        if (!mounted || _routeCalcCancelled) return;
        setState(() {
          if (result != null) {
            previewDistance = result['distance'];
            previewTime = result['time'];
            _rejectedRoutePoints = result['rejected']?.round() ?? 0;
          }
        });
      }));
      if (FFAppState().DriverGuideState == false) {
        FFAppState().aiRow = false;
        FFAppState().Minimumhours = touryMinimumBookingHours(
          landmarkCount: FFAppState().cartmkss.length,
          driverGuide: false,
        );
      } else {
        FFAppState().Minimumhours = 0;
      }
      safeSetState(() {});
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
  }

  Widget _extraHoursMetricTile({
    required String label,
    required Widget value,
  }) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DsSpacing.sm + 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: DsRadius.medium,
        border: Border.all(color: colors.border.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.labelSmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DsSpacing.xs),
          value,
        ],
      ),
    );
  }

  Widget _extraHoursStepper() {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: DsRadius.medium,
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: FlutterFlowCountController(
        decrementIconBuilder: (enabled) => Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled
                ? colors.primarySoft
                : colors.border.withValues(alpha: 0.35),
            borderRadius: DsRadius.small,
          ),
          child: Icon(
            Icons.remove_rounded,
            color: enabled ? colors.primary : colors.textSecondary,
            size: 18,
          ),
        ),
        incrementIconBuilder: (enabled) => Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled ? colors.primary : colors.border.withValues(alpha: 0.35),
            borderRadius: DsRadius.small,
          ),
          child: Icon(
            Icons.add_rounded,
            color: enabled ? colors.onPrimary : colors.textSecondary,
            size: 18,
          ),
        ),
        countBuilder: (count) => Text(
          NumberFormat.decimalPattern(context.locale.toString()).format(count),
          style: typography.titleMedium.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        count: _model.countControllerValue ??= 0,
        updateCount: (count) async {
          final extra = count.clamp(0, 300);
          safeSetState(() => _model.countControllerValue = extra);
          FFAppState().update(() {
            FFAppState().addhors = extra;
            FFAppState().totalsaat = FFAppState().saatcar + extra;
          });
          touryRecalculateCheckoutPrice();
          safeSetState(() {});
        },
        stepSize: 1,
        minimum: 0,
        maximum: 300,
        contentPadding:
            const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
      ),
    );
  }

  @override
  void dispose() {
    _routeCalcCancelled = true;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _routeCalcCancelled) return;
      _maybeRecalcRouteAfterCartChange();
    });

    return DsScreenShell(
      child: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: context.dsColors.scaffold,
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
                                // Already on checkout — close drawer instead of stacking.
                                if (scaffoldKey.currentState?.isDrawerOpen ??
                                    false) {
                                  scaffoldKey.currentState!.closeDrawer();
                                }
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
        appBar: DsAppBar(
          automaticallyImplyLeading: false,
          title: FFLocalizations.of(context).getText(
            'q0xxfq1y' /* My trip list */,
          ),
          leading: DsIconButton(
            icon: DsIcons.back,
            onPressed: () async {
              if (FFAppState().typeHgz == 1) {
                context.safePopOrBookingHome(
                  fallbackRouteName: ListViWidget.routeName,
                  fallbackQueryParameters: {
                    'cite': serializeParam(
                      FFAppState().villa,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                );
              } else {
                context.safePopOrBookingHome(
                  fallbackRouteName: DemoDWidget.routeName,
                );
              }
            },
          ),
        ),
        body: TouryAdaptiveScope(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: TouryLayout.bottomNavSafe(context) + DsSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Phone gate MUST live inside AuthUserStreamWidget so a
                // successful profile write clears the banner without restart.
                AuthUserStreamWidget(
                  builder: (context) {
                    if (TouryProfileCompleteness.hasUsablePhone()) {
                      return const SizedBox.shrink();
                    }
                    final colors = context.dsColors;
                    final typography = context.dsTypography;
                    return Padding(
                      padding: const EdgeInsets.all(DsSpacing.md),
                      child: DsCard(
                        color: colors.errorContainer,
                        bordered: false,
                        elevated: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: colors.error,
                                  size: DsIcons.sm,
                                ),
                                const SizedBox(width: DsSpacing.xs),
                                Expanded(
                                  child: Text(
                                    FFLocalizations.of(context)
                                        .getText('2n28fqm2'),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            DsButton.primary(
                              label: FFLocalizations.of(context).getText(
                                'vlo7yf10' /* Add your phone number */,
                              ),
                              icon: Icons.add_outlined,
                              size: DsButtonSize.sm,
                              expanded: true,
                              onPressed: () async {
                                context.pushNamed(UpdateProfWidget.routeName);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpacing.md,
                      DsSpacing.xs,
                      DsSpacing.md,
                      0,
                    ),
                    child: DsCard(
                      elevated: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Distance & Time + Button
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ui_text_12ee72ca4f'.tr(),
                                      style: context.dsTypography.titleMedium
                                          .copyWith(
                                        color: context.dsColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: DsSpacing.xs),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.route_rounded,
                                          size: DsIcons.xs,
                                          color: context.dsColors.primary,
                                        ),
                                        const SizedBox(width: DsSpacing.xxs),
                                        Flexible(
                                          child: Text(
                                            _formatTripDistance(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context
                                                .dsTypography.headlineSmall
                                                .copyWith(
                                              color: context
                                                  .dsColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: DsSpacing.xs),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: DsIcons.sm,
                                          color: context.dsColors.primary,
                                        ),
                                        const SizedBox(width: DsSpacing.xs),
                                        Flexible(
                                          child: Text(
                                            _formatTripTime(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context
                                                .dsTypography.headlineSmall
                                                .copyWith(
                                              color: context
                                                  .dsColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (osrmTime > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'map_eta_traffic'.tr(),
                                        style: context.dsTypography.labelSmall
                                            .copyWith(
                                          color: context.dsColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (FFAppState().cartmkss.isNotEmpty) ...[
                                      const SizedBox(height: DsSpacing.xs),
                                      Text(
                                        '${'map_stops_count'.tr()}: ${FFAppState().cartmkss.length}',
                                        style: context.dsTypography.labelMedium
                                            .copyWith(
                                          color: context.dsColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (FFAppState().addcart >= 1)
                                Flexible(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: DsButton.primary(
                                      label: 'booking_view_route'.tr(),
                                      icon: Icons.map_outlined,
                                      size: DsButtonSize.sm,
                                      onPressed: () async {
                                        await showModalBottomSheet(
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          context: context,
                                          builder: (context) {
                                            return GestureDetector(
                                              onTap: () => FocusScope.of(
                                                      context)
                                                  .unfocus(),
                                              child: Padding(
                                                padding:
                                                    MediaQuery.viewInsetsOf(
                                                        context),
                                                child: const MmaappWidget(),
                                              ),
                                            );
                                          },
                                        ).then(
                                            (value) => safeSetState(() {}));
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: DsSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: DsIcons.xs,
                                color: context.dsColors.iconMuted,
                              ),
                              const SizedBox(width: DsSpacing.xs),
                              Expanded(
                                child: Text(
                                  'ui_text_d93bf2eb9f'.tr(),
                                  style: context.dsTypography.bodySmall
                                      .copyWith(
                                    color: context.dsColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      DsSpacing.sm, DsSpacing.sm, DsSpacing.sm, 0,
                    ),
                    child: TouriCheckoutPaymentMethodPicker(
                      remoteOkCash: true,
                      onChanged: () => safeSetState(() {}),
                    ),
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
                        DsSpacing.sm, DsSpacing.sm, DsSpacing.sm, DsSpacing.sm),
                    child: DsCard(
                      elevated: true,
                      padding: const EdgeInsets.all(DsSpacing.md),
                      child: Builder(
                        builder: (context) {
                          final colors = DsColors.of(context);
                          final typography = DsTypography.of(context);
                          final baseHours = NumberFormat.decimalPattern(
                            context.locale.toString(),
                          ).format(FFAppState().saatcar);
                          final totalHours = NumberFormat.decimalPattern(
                            context.locale.toString(),
                          ).format(FFAppState().totalsaat > 0
                              ? FFAppState().totalsaat
                              : FFAppState().saatcar +
                                  (_model.countControllerValue ?? 0));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: colors.primarySoft,
                                      borderRadius: DsRadius.medium,
                                    ),
                                    child: Icon(
                                      Icons.schedule_rounded,
                                      color: colors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: DsSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Need extra hours?'.tr(),
                                          style: typography.titleMedium
                                              .copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'planning_for_a_longer_trip_Add_more_hours_and_enjoy_the_ride'
                                              .tr(),
                                          style: typography.bodySmall.copyWith(
                                            color: colors.textSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_tripTimeHours != null) ...[
                                const SizedBox(height: DsSpacing.sm),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(DsSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: colors.primarySoft,
                                    borderRadius: DsRadius.medium,
                                    border: Border.all(
                                      color: colors.primary
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.route_outlined,
                                        color: colors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: DsSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'checkout_estimated_drive_info'.tr(
                                            namedArgs: {
                                              'time': _formatTripTime(),
                                            },
                                          ),
                                          style: typography.bodySmall.copyWith(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: DsSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _extraHoursMetricTile(
                                      label: 'checkout_base_booking_duration'
                                          .tr(),
                                      value: Text(
                                        baseHours,
                                        style: typography.headlineSmall
                                            .copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: DsSpacing.sm),
                                  Expanded(
                                    child: _extraHoursMetricTile(
                                      label: 'checkout_extra_booking_duration'
                                          .tr(),
                                      value: _extraHoursStepper(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DsSpacing.md,
                                  vertical: DsSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: DsRadius.medium,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timelapse_rounded,
                                      size: 18,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: DsSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Total number of hours: '.tr(),
                                        style: typography.labelMedium.copyWith(
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      totalHours,
                                      style: typography.titleMedium.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (FFAppState().NsbhKsm >= 1.0) ...[
                                const SizedBox(height: DsSpacing.sm),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(DsSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: colors.primarySoft,
                                    borderRadius: DsRadius.medium,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.local_offer_rounded,
                                        color: colors.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: DsSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          'checkout_extra_hour_discount'.tr(
                                            namedArgs: {
                                              'percent': FFAppState()
                                                  .NsbhKsm
                                                  .toString(),
                                              'max':
                                                  FFAppState().UbKsm.toString(),
                                              'currency':
                                                  FFAppState().RMZCurrency,
                                            },
                                          ),
                                          style: typography.bodySmall.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ).animateOnPageLoad(
                        animationsMap['containerOnPageLoadAnimation1']!),
                  ),
                if (FFAppState().addcart >= 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        DsSpacing.md, DsSpacing.md, DsSpacing.md, DsSpacing.xs),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: DsColors.of(context).primarySoft,
                            borderRadius: DsRadius.medium,
                          ),
                          child: Icon(
                            Icons.route_rounded,
                            color: DsColors.of(context).primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: DsSpacing.sm),
                        Expanded(
                          child: Text(
                            FFLocalizations.of(context).getText(
                              '3im46sag' /* List of added locations. */,
                            ),
                            style: DsTypography.of(context).titleSmall.copyWith(
                                  color: DsColors.of(context).textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: DsColors.of(context).primarySoft,
                            borderRadius: DsRadius.pill,
                          ),
                          child: Text(
                            '${FFAppState().cartmkss.length}',
                            style: DsTypography.of(context).labelMedium.copyWith(
                                  color: DsColors.of(context).primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Empty itinerary — always visible (including typeHgz==2).
                // Previously typeHgz==2 only showed a tiny 12px bar that looked blank.
                if (FFAppState().addcart <= 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpacing.md,
                      DsSpacing.lg,
                      DsSpacing.md,
                      DsSpacing.md,
                    ),
                    child: DsEmptyState(
                      icon: FFAppState().typeHgz == 2
                          ? Icons.route_outlined
                          : Icons.luggage_outlined,
                      title: FFLocalizations.of(context).getText(
                        'vbjndb7s' /* No tours have been added! */,
                      ),
                      message: FFAppState().typeHgz == 2
                          ? 'ux_select_destination_hint'.tr()
                          : 'ux_add_places_hint'.tr(),
                    ),
                  ),
                if (FFAppState().typeHgz == 2 && FFAppState().addcart >= 1)
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
                              ),
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
                      final colors = DsColors.of(context);
                      final typography = DsTypography.of(context);

                      return Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            DsSpacing.md, DsSpacing.xs, DsSpacing.md, 0),
                        child: Column(
                          children: List.generate(mkss.length, (mkssIndex) {
                            final mkssItem = mkss[mkssIndex];
                            final subtitle = mkssItem.textivill.trim();
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: mkssIndex == mkss.length - 1
                                    ? 0
                                    : DsSpacing.sm,
                              ),
                              child: DsCard(
                                elevated: true,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  DsSpacing.md,
                                  DsSpacing.sm + 2,
                                  DsSpacing.sm,
                                  DsSpacing.sm + 2,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors.primarySoft,
                                        borderRadius: DsRadius.medium,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${mkssIndex + 1}',
                                        style: typography.titleSmall.copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: DsSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mkssItem.naim,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                typography.titleSmall.copyWith(
                                              color: colors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.place_outlined,
                                                  size: 14,
                                                  color: colors.textSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    subtitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: typography.bodySmall
                                                        .copyWith(
                                                      color:
                                                          colors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: DsSpacing.xs),
                                    Material(
                                      color: colors.error
                                          .withValues(alpha: 0.10),
                                      borderRadius: DsRadius.medium,
                                      child: InkWell(
                                        borderRadius: DsRadius.medium,
                                        onTap: () async {
                                          touryRemoveLandmarkFromCart(
                                            context: context,
                                            item: mkssItem,
                                            onChanged: () {
                                              safeSetState(() {});
                                              _maybeRecalcRouteAfterCartChange();
                                            },
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                color: colors.error,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'landmark_remove'.tr(),
                                                style: typography.labelMedium
                                                    .copyWith(
                                                  color: colors.error,
                                                  fontWeight: FontWeight.w700,
                                                ),
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
                          Padding(
                            padding: const EdgeInsets.only(top: DsSpacing.md),
                            child: Builder(
                              builder: (context) {
                                final cash = touryIsCashBookNowPayment(
                                  FFAppState().payth,
                                );
                                final card = touryHasElectronicPaymentSelected();
                                final kind = touriCheckoutCtaKind(
                                  cashSelected: cash,
                                  cardSelected: card,
                                  paid: false,
                                  hasPendingSameBookingAttempt: FFAppState()
                                      .pendingPaymentOrderId
                                      .isNotEmpty,
                                  lastAttemptFailed: false,
                                );
                                final busy = _isPaying || _isBookingCash;
                                return DsButton.primary(
                                  label: busy
                                      ? (cash
                                          ? 'checkout_booking'.tr()
                                          : 'checkout_preparing_payment'.tr())
                                      : touriCheckoutCtaLabel(
                                          kind: kind,
                                          amountLabel: _formatMoney(
                                            FFAppState().totalAllnow3,
                                          ),
                                        ),
                                  icon: cash
                                      ? Icons.send_rounded
                                      : Icons.payment_rounded,
                                  size: DsButtonSize.lg,
                                  expanded: true,
                                  loading: busy,
                                  enabled: !busy &&
                                      kind != TouriCheckoutCtaKind.chooseMethod,
                                  onPressed: busy
                                      ? null
                                      : _onPrimaryCheckoutPressed,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
