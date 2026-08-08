import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_record.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_customer_cancel_policy.dart';
import '/core/toury_order_integration.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_localization/easy_localization.dart';

/// حقول تتبع إضافية على مستند `order`.
extension TouryOrderMeta on OrderRecord {
  int get etaSeconds => castToType<int>(snapshotData['etaSeconds']) ?? 0;

  double get distanceRemainingMeters =>
      castToType<double>(snapshotData['distanceRemainingMeters']) ?? 0.0;

  int get etaMinutes => etaSeconds <= 0 ? 0 : (etaSeconds / 60).ceil();

  LatLng? get driverLivePosition => mapuser;

  String get statusCode =>
      castToType<String>(snapshotData['status_code']) ?? '';

  LatLng? get customerPickup => lokeshn;

  LatLng? get tripDestination {
    if (listAmakn.isNotEmpty) {
      final last = listAmakn.last;
      if (last.hasLoceshn()) return last.loceshn;
    }
    final lat = castToType<double>(snapshotData['destinationLatitude']);
    final lng = castToType<double>(snapshotData['destinationLongitude']);
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      return LatLng(lat, lng);
    }
    return null;
  }

  bool get isDriverEnRoute {
    if (const {
      'driver_assigned',
      'driver_arrived',
      'trip_in_progress',
    }.contains(statusCode)) {
      return true;
    }
    final status = halhText;
    return status == 'مقبول' ||
        status == 'وصل المندوب' ||
        status == 'تم البدء في الرحلة';
  }

  /// نقاط المسار المخططة المحفوظة عند إنشاء الطلب.
  List<LatLng> plannedWaypoints() {
    final raw = snapshotData['plannedWaypoints'];
    if (raw is! List) return const [];
    final points = <LatLng>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final lat = castToType<double>(item['lat']);
      final lng = castToType<double>(item['lng']);
      if (lat == null || lng == null) continue;
      if (lat == 0 && lng == 0) continue;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  List<LatLng> intermediateStops() {
    if (listAmakn.length <= 1) return const [];
    return listAmakn
        .take(listAmakn.length - 1)
        .map((e) => e.loceshn)
        .whereType<LatLng>()
        .toList(growable: false);
  }

  List<LatLng> trackingRouteWaypoints() {
    final driver = driverLivePosition;
    final pickup = customerPickup;
    final dest = tripDestination;
    final planned = plannedWaypoints();
    final stops = intermediateStops();

    // أثناء التتبع الحي: المندوب → الالتقاط → المحطات → الوجهة.
    if (driver != null) {
      final live = <LatLng>[
        driver,
        if (pickup != null && pickup != driver) pickup,
        ...stops.where((p) => p != pickup && p != dest && p != driver),
        if (dest != null && dest != pickup && dest != driver) dest,
      ];
      if (live.length >= 2) return live;
    }

    // للطلبات السابقة أو قبل قبول المندوب: استخدم snapshot المخطط.
    if (planned.length >= 2) return planned;

    return [
      if (pickup != null) pickup,
      ...stops.where((p) => p != pickup && p != dest),
      if (dest != null && dest != pickup) dest,
    ];
  }

  String etaLabel() {
    if (etaMinutes <= 0) return '';
    return 'map_eta_minutes'.tr(
      namedArgs: {'minutes': etaMinutes.toString()},
    );
  }

  bool get isPending {
    if (BookingStatusLocalizer.isAwaitingDriver(
      statusCode: statusCode,
      halhText: halhText,
      halhOrderName: halhOrder?.name,
    )) {
      return true;
    }
    return halhText == TouryOrderIntegration.pendingStatusText ||
        halhOrder == Halh.Pending;
  }

  /// Raw Firestore status (do not collapse aliases).
  String get rawStatusCode =>
      (snapshotData['status_code'] ?? '').toString().trim();

  /// Customer may cancel only if no driver accepted yet, or accepted but
  /// has not started moving toward the customer (`driver_arriving`+).
  bool get canCancelByCustomer =>
      TouryCustomerCancelPolicy.canCustomerCancelBooking(
        statusCode: rawStatusCode,
        halhText: halhText,
        halhOrderName: halhOrder?.name,
        driverOrderStatus: halhOrderMndob?.name,
      );
}
