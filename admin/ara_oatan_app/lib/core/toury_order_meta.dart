import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_record.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_customer_cancel_policy.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_tracking_phase.dart';
import '/core/toury_trip_progress.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_localization/easy_localization.dart';

/// حقول تتبع إضافية على مستند `order`.
extension TouryOrderMeta on OrderRecord {
  /// Optional booking flag: after landmarks, return to original pickup.
  bool get returnToPickup => snapshotData['returnToPickup'] == true;

  String get trackingPhaseRaw =>
      (snapshotData['tracking_phase'] ?? '').toString().trim();

  String get trackingPhase => TouryTrackingPhase.resolve(
        statusCode: statusCode,
        returnToPickup: returnToPickup,
        trackingPhase: trackingPhaseRaw,
        halhText: halhText,
      );

  /// Fixed pickup snapshot from booking (`LOKESHN` / origin*).
  LatLng? get originalPickupSnapshot => TouryTrackingPhase.originalPickup(
        lokeshn: lokeshn,
        originLatitude:
            castToType<double>(snapshotData['originLatitude']),
        originLongitude:
            castToType<double>(snapshotData['originLongitude']),
      );

  int get etaSeconds => castToType<int>(snapshotData['etaSeconds']) ?? 0;

  double get distanceRemainingMeters =>
      castToType<double>(snapshotData['distanceRemainingMeters']) ?? 0.0;

  int get etaMinutes => etaSeconds <= 0 ? 0 : (etaSeconds / 60).ceil();

  bool get etaApproximate => snapshotData['etaApproximate'] == true;

  double? get driverHeading {
    final v = snapshotData['driverHeading'];
    if (v is num) return v.toDouble();
    return null;
  }

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
    final pickup = originalPickupSnapshot ?? customerPickup;
    final dest = tripDestination;
    final planned = plannedWaypoints();
    final stops = intermediateStops();
    final phase = trackingPhase;
    final stage = touryResolveTripStage(
      statusCode: statusCode,
      halhText: halhText,
    );

    List<LatLng> dedupe(List<LatLng> live) {
      final out = <LatLng>[];
      for (final p in live) {
        if (out.isEmpty || out.last != p) out.add(p);
      }
      return out;
    }

    // At customer pickup: clear the approach polyline until Start.
    if (stage == TouryTripStage.arrived &&
        phase != TouryTrackingPhase.toDestination &&
        phase != TouryTrackingPhase.atDestination &&
        phase != TouryTrackingPhase.returningToPickup &&
        phase != TouryTrackingPhase.returnedToPickup) {
      return const [];
    }

    // Phase 1: Driver → original pickup only.
    if (phase == TouryTrackingPhase.toPickup ||
        stage == TouryTripStage.enRoute) {
      if (driver != null && pickup != null && driver != pickup) {
        return [driver, pickup];
      }
      if (pickup != null && dest != null && pickup != dest) {
        return [pickup, dest];
      }
      return const [];
    }

    // Visit waiting: no active navigation polyline (stay at destination).
    if (phase == TouryTrackingPhase.atDestination ||
        phase == TouryTrackingPhase.returnedToPickup) {
      return const [];
    }

    // Return leg: driver/landmark → original pickup snapshot.
    if (phase == TouryTrackingPhase.returningToPickup && returnToPickup) {
      final origin = driver ?? dest;
      if (origin != null && pickup != null && origin != pickup) {
        return [origin, pickup];
      }
      return const [];
    }

    // Phase 2: Driver → stops → destination (pickup leg cleared).
    if (phase == TouryTrackingPhase.toDestination ||
        stage == TouryTripStage.arrived ||
        stage == TouryTripStage.started) {
      final live = <LatLng>[
        if (driver != null) driver,
        ...stops.where((p) => p != pickup && p != dest && p != driver),
        if (dest != null && dest != driver && dest != pickup) dest,
      ];
      final points = dedupe(live);
      if (points.length >= 2) return points;
    }

    if (phase == TouryTrackingPhase.completed) {
      return const [];
    }

    if (planned.length >= 2) return planned;

    return [
      if (pickup != null) pickup,
      ...stops.where((p) => p != pickup && p != dest),
      if (dest != null && dest != pickup) dest,
    ];
  }

  String etaLabel() {
    if (etaMinutes <= 0) return '';
    final base = 'map_eta_minutes'.tr(
      namedArgs: {'minutes': etaMinutes.toString()},
    );
    final suffix = etaApproximate
        ? ' (${'map_eta_estimated'.tr()})'
        : ' (${'map_eta_traffic'.tr()})';
    return '$base$suffix';
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

  /// Trusted create time from Firestore `data_order` (UTC).
  DateTime? get createdAtUtc => TouryCustomerCancelPolicy.createdAtFromField(
        snapshotData['data_order'] ?? dataOrder,
      );

  /// Customer may cancel anytime before driver accept (no cancel timer).
  bool get canCancelByCustomer =>
      TouryCustomerCancelPolicy.canCustomerCancelBooking(
        statusCode: rawStatusCode,
        halhText: halhText,
        halhOrderName: halhOrder?.name,
        driverOrderStatus: halhOrderMndob?.name,
        mndobUser: mndobUser ?? snapshotData['mndob_user'],
        createdAt: createdAtUtc,
        paymentStatus: (snapshotData['payment_status'] ?? '').toString(),
      );

  bool get isAwaitingPayment => BookingStatusLocalizer.isPaymentPending(
        statusCode: rawStatusCode,
        paymentStatus: (snapshotData['payment_status'] ?? '').toString(),
      );
}
