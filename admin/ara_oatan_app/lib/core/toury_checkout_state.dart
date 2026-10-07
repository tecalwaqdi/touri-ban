import 'package:collection/collection.dart';

import '/app_state.dart';
import '/core/toury_billable_hours.dart';
import '/core/toury_landmark_filter.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_labels.dart';
import '/core/toury_pricing.dart';
import '/core/toury_route_metrics.dart';
import '/flutter_flow/lat_lng.dart';

/// Result of applying the canonical billable-hours rule to checkout state.
class TouryBillableHoursApplyResult {
  const TouryBillableHoursApplyResult({
    required this.billableHours,
    required this.userSelectedHours,
    required this.vehicleMinimumHours,
    required this.estimatedRouteDurationMinutes,
    required this.routeForcedIncrease,
    required this.changed,
  });

  final int billableHours;
  final int userSelectedHours;
  final int vehicleMinimumHours;
  final int estimatedRouteDurationMinutes;
  final bool routeForcedIncrease;
  final bool changed;
}

/// Apply [TouryBillableHours.compute] to [FFAppState.totalsaat] / addhors.
///
/// Semantics:
/// - [FFAppState.userRequestedExtraHours] = Customer-chosen extras (never
///   overwritten by route/auto).
/// - AUTO_REQUIRED = max(vehicleMin, ceil(serviceMinutes/60), landmark floor)
/// - FINAL = max(AUTO_REQUIRED, vehicleMin + userRequestedExtraHours)
///
/// [FFAppState.addhors] mirrors FINAL − vehicleMin for price/booking display.
TouryBillableHoursApplyResult touryApplyBillableHours([FFAppState? state]) {
  final app = state ?? FFAppState();
  final vehicleMin = app.saatcar.clamp(0, 24 * 30).toInt();
  final userExtra = app.userRequestedExtraHours.clamp(0, 24 * 30).toInt();
  final userRequested = (vehicleMin + userExtra).clamp(0, 24 * 30).toInt();
  // Financial billable hours require Google Routes duration only.
  final travelMinutes = app.billingRouteIsGoogle
      ? app.routeDurationMinutes.round()
      : 0;
  final landmarkCount = app.cartmkss.length;
  // Return travel is already inside travelMinutes when returnToPickup is on.
  final serviceMins = TouryBillableHours.serviceMinutes(
    outboundTravelMinutes: travelMinutes,
    landmarkCount: landmarkCount,
    returnTravelMinutes: 0,
  );
  var autoRequired = TouryBillableHours.compute(
    userSelectedHours: vehicleMin,
    vehicleMinimumHours: vehicleMin,
    estimatedRouteDurationMinutes: serviceMins,
  );
  final landmarkMin = app.Minimumhours;
  if (!app.DriverGuideState && landmarkMin >= 2 && autoRequired < landmarkMin) {
    autoRequired = landmarkMin;
  }
  final billable =
      userRequested > autoRequired ? userRequested : autoRequired;
  final routeForced = TouryBillableHours.routeForcedIncrease(
    userSelectedHours: userRequested,
    vehicleMinimumHours: vehicleMin,
    estimatedRouteDurationMinutes: serviceMins,
    billableHours: billable,
  );
  final displayExtra = (billable - vehicleMin).clamp(0, 24 * 30).toInt();
  final changed =
      app.totalsaat != billable || app.addhors != displayExtra;
  if (changed) {
    app.update(() {
      app.totalsaat = billable;
      app.addhors = displayExtra;
      // userRequestedExtraHours intentionally untouched.
    });
  }
  return TouryBillableHoursApplyResult(
    billableHours: billable,
    userSelectedHours: userRequested,
    vehicleMinimumHours: vehicleMin,
    estimatedRouteDurationMinutes: serviceMins,
    routeForcedIncrease: routeForced,
    changed: changed,
  );
}

/// Localized explanation when route ETA raised billable hours.
String touryBillableHoursRouteExplanation({
  required int estimatedRouteDurationMinutes,
  required int billableHours,
  required String Function(String key, {Map<String, String>? namedArgs}) tr,
}) {
  final (h, m) = TouryBillableHours.splitDurationMinutes(
    estimatedRouteDurationMinutes,
  );
  return tr(
    'checkout_route_hours_adjusted',
    namedArgs: {
      'eta_hours': '$h',
      'eta_minutes': '$m',
      'billable_hours': '$billableHours',
    },
  );
}

/// Origin for drive distance / ETA / polyline.
/// Prefer booking pickup, then city center — not live GPS (GPS caused
/// «غير متاح» / rejected Makkah stops when the device was elsewhere).
LatLng? touryResolveTripRouteOrigin([FFAppState? state]) {
  final app = state ?? FFAppState();
  for (final candidate in <LatLng?>[
    app.mkanuserorder,
    app.akrLoceshn,
    app.latlngvill,
  ]) {
    if (touryIsValidCoordinate(candidate)) return candidate;
  }
  return null;
}

/// هل توجد بيانات موقع/دولة كافية لإكمال الحجز؟
bool touryHasPersistedLocation([FFAppState? state]) {
  final app = state ?? FFAppState();
  final hasCountry = app.dolh != null || app.naimdolh.trim().isNotEmpty;
  final hasVillage = app.villnow != null ||
      app.villa != null ||
      app.naimvillatext.trim().isNotEmpty;
  return hasCountry && hasVillage;
}

/// ساعات مقترحة للرحلة (معلومة فقط — ليست مدة الحجز).
double tourySuggestedTripHours({
  double? previewTimeHours,
  double? osrmTimeMinutes,
  int landmarkCount = 0,
}) {
  var hours = previewTimeHours ?? 0.0;
  if (hours <= 0 && (osrmTimeMinutes ?? 0) > 0) {
    hours = osrmTimeMinutes! / 60.0;
  }
  if (hours <= 0) {
    hours = landmarkCount > 0 ? 1.0 : 0.5;
  }
  return hours.clamp(0.5, 4.0);
}

/// Booking hours vs route ETA: tour packages may exceed drive time — OK.
bool touryBookingHoursSufficient({
  required double bookingHours,
  required double suggestedHours,
}) {
  if (bookingHours < 1) return false;
  // Keep [suggestedHours] for call-site compatibility / informational UI only.
  return true;
}

/// Central booking rule: roughly two landmarks per booked hour, with a
/// practical ceiling so corrupted carts can never demand hundreds of hours.
int touryMinimumBookingHours({
  required int landmarkCount,
  required bool driverGuide,
}) {
  if (driverGuide || landmarkCount < 3) return 0;
  return ((landmarkCount + 1) ~/ 2).clamp(2, 8);
}

/// ساعات ناقصة للمتابعة (null = كافٍ).
/// Only enforces landmark-based minimum — not route ETA vs booking duration.
double? touryMissingBookingHours({
  required double bookingHours,
  double? previewTimeHours,
  double? osrmTimeMinutes,
  int landmarkCount = 0,
  bool driverGuide = false,
}) {
  if (bookingHours < 1) {
    return 1;
  }
  final minimum = touryMinimumBookingHours(
    landmarkCount: landmarkCount,
    driverGuide: driverGuide,
  );
  if (minimum >= 2 && bookingHours < minimum) {
    return (minimum - bookingHours).ceilToDouble().clamp(1.0, 8.0);
  }
  // Intentionally ignore preview/OSRM vs booking — tour duration ≠ drive time.
  return null;
}

/// هل بيانات الحجز جاهزة لزر «احجز الآن»؟
bool touryCheckoutReadyForBooking([FFAppState? state]) {
  final app = state ?? FFAppState();
  // الاستعانة بالسائق: المندوب يختار المحطات — لا تشترط سلة معالم.
  if (app.DriverGuideState) {
    if (app.mkanuserorder == null && app.latlngvill == null && app.akrLoceshn == null) {
      return false;
    }
    if (app.tebycar.trim().isEmpty && app.typecarRev == null) return false;
    if (app.totalsaat < 1) return false;
    return true;
  }
  if (app.cartmkss.isEmpty && app.addcart <= 0) return false;
  if (app.mkanuserorder == null) return false;
  if (app.tebycar.trim().isEmpty && app.typecarRev == null) return false;
  if (app.totalsaat < 1) return false;
  if (!app.DriverGuideState &&
      app.Minimumhours >= 2 &&
      app.totalsaat < app.Minimumhours) {
    return false;
  }
  return true;
}

/// مزامنة أعلام الحجز من البيانات المحفوظة (دولة، مدينة، سلة).
void tourySyncBookingFlags() {
  final app = FFAppState();
  var changed = false;

  void touch(void Function() mutate) {
    mutate();
    changed = true;
  }

  if (app.cartmkss.isEmpty && app.addcart > 0) {
    touch(() => app.addcart = 0);
  } else if (app.cartmkss.isNotEmpty && app.addcart != app.cartmkss.length) {
    touch(() => app.addcart = app.cartmkss.length);
  }

  if (app.mkanuserorder == null) {
    final firstLoc =
        app.cartmkss.map((e) => e.loceshn).whereType<LatLng>().firstOrNull;
    if (firstLoc != null) {
      touch(() => app.mkanuserorder = firstLoc);
    } else if (app.latlngvill != null) {
      touch(() => app.mkanuserorder = app.latlngvill);
    } else if (app.akrLoceshn != null) {
      touch(() => app.mkanuserorder = app.akrLoceshn);
    }
  }

  if (app.typeHgz == 0) {
    if (app.DriverGuideState) {
      touch(() => app.typeHgz = 2);
    } else if (app.cartmkss.isNotEmpty || app.addcart > 0) {
      touch(() => app.typeHgz = 1);
    }
  }

  final minimumHours = touryMinimumBookingHours(
    landmarkCount: app.cartmkss.length,
    driverGuide: app.DriverGuideState,
  );
  if (app.Minimumhours != minimumHours) {
    touch(() => app.Minimumhours = minimumHours);
  }

  if (!app.AllowBooking && touryHasPersistedLocation(app)) {
    touch(() {
      app.AllowBooking = true;
      app.villnow ??= app.villa;
      app.villa ??= app.villnow;
      if (app.villtextnow.trim().isEmpty &&
          app.naimvillatext.trim().isNotEmpty) {
        app.villtextnow = app.naimvillatext;
      }
    });
  }

  if (app.DriverGuideState) {
    // Driver-guided tours: ensure pickup + at least 1 hour so Book Now works.
    if (app.mkanuserorder == null) {
      if (app.latlngvill != null) {
        touch(() => app.mkanuserorder = app.latlngvill);
      } else if (app.akrLoceshn != null) {
        touch(() => app.mkanuserorder = app.akrLoceshn);
      }
    }
    if (app.totalsaat < 1) {
      touch(() => app.totalsaat = app.saatcar > 0 ? app.saatcar : 2);
    }
  }

  if (app.typeHgz == 2 && app.DriverGuideState && !app.AllowBooking) {
    touch(() => app.AllowBooking = true);
  }

  if (changed) {
    app.update(() {});
  }
}

/// Apply cash-only defaults without inventing payment when online is enabled.
void touryApplyCashOnlyPaymentDefaults([FFAppState? state]) {
  if (!TouryPaymentFlags.cashOnlyMode) return;
  final app = state ?? FFAppState();
  app.ElectronicPayment = false;
  if (!touryIsCashPaymentValue(app.payth)) {
    app.payth = TouryPaymentKeys.cash;
  }
  app.clearSensitivePaymentSession();
}

/// يهيّئ حالة الحجز قبل فتح صفحة الدفع أو عند تحميلها.
void touryPrepareCheckoutState({bool resetExtraHours = false}) {
  final app = FFAppState();
  if (resetExtraHours) {
    // Never carry last session's extra hours into a new checkout screen.
    app.addhors = 0;
    if (app.saatcar > 0) {
      app.totalsaat = app.saatcar;
    } else {
      // Avoid stale totalsaat from SharedPreferences when car hours cleared.
      app.totalsaat = 0;
    }
  }
  touryPurgeBannedCartItems(app);
  touryApplyCashOnlyPaymentDefaults(app);
  tourySyncBookingFlags();
  touryApplyBillableHours(app);
  touryRecalculateCheckoutPrice(app);
}

/// هل تُعرض خيارات الحجز (سيارة، عنوان، جدولة، دفع)؟
bool touryBookingOptionsVisible() {
  final app = FFAppState();
  return app.AllowBooking == true || app.typeHgz == 2;
}

/// هل زر «احجز الآن» النقدي يجب أن يظهر؟
bool touryIsCashBookNowPayment(String payth) {
  if (TouryPaymentFlags.cashOnlyMode) {
    return !touryIsOnlinePaymentValue(payth);
  }
  return touryIsCashPaymentValue(payth);
}

/// True when the user still must pick a payment method before booking.
bool touryRequiresPaymentMethodSelection(String payth) {
  if (TouryPaymentFlags.cashOnlyMode) return false;
  return touryIsUnsetPaymentValue(payth);
}

/// Cash-only mode uses [touryApplyCashOnlyPaymentDefaults].
void touryEnsureCashPaymentIfUnset() {
  touryApplyCashOnlyPaymentDefaults();
}
