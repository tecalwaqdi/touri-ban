import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/core/toury_system_status_codes.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// تحديث موقع المندوب الحي في مستند المستخدم والطلب النشط.
abstract final class DriverLiveLocationService {
  DriverLiveLocationService._();

  static Timer? _idleTimer;
  static StreamSubscription<Position>? _idleStream;
  static const double maxAccuracyMeters = 500.0;

  static bool isUsableCoordinate(LatLng? p) {
    if (p == null) return false;
    if (p.latitude.abs() < 0.0001 && p.longitude.abs() < 0.0001) {
      return false;
    }
    if (p.latitude.abs() > 90 || p.longitude.abs() > 180) return false;
    return true;
  }

  static Future<LatLng?> currentPosition({bool requestPermission = true}) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!isUsableCoordinate(latLng)) return null;
      if (pos.accuracy > maxAccuracyMeters) {
        debugPrint(
          'DriverLiveLocationService: weak accuracy ${pos.accuracy}m '
          '(threshold $maxAccuracyMeters) — accepting usable fix',
        );
      }
      return latLng;
    } catch (e) {
      debugPrint('DriverLiveLocationService.currentPosition: $e');
      return null;
    }
  }

  /// يكتب `loceshnMndobNow` ويحدّث الطلب النشط إن وُجد.
  static Future<void> syncNow({LatLng? position}) async {
    if (!loggedIn || currentUserReference == null) return;

    final resolved = position ?? await currentPosition();
    if (!isUsableCoordinate(resolved)) return;
    final loc = resolved!;

    try {
      await currentUserReference!.update({
        'loceshnMndobNow': GeoPoint(loc.latitude, loc.longitude),
        'last_seen_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Online/offline rules may only allow location with ngl — retry soft.
      debugPrint('DriverLiveLocationService.syncNow: $e');
      try {
        await currentUserReference!.update({
          'loceshnMndobNow': GeoPoint(loc.latitude, loc.longitude),
        });
      } catch (e2) {
        debugPrint('DriverLiveLocationService.syncNow retry: $e2');
        return;
      }
    }

    final activeRef = FFAppState().revOrder;
    if (activeRef != null) {
      try {
        final order = await OrderRecord.getDocumentOnce(activeRef);
        if (!DriverTripService.isActiveTripForCurrentDriver(order)) {
          FFAppState().revOrder = null;
          return;
        }
        LatLng? target = order.customerPickup;
        final code =
            (order.snapshotData['status_code'] ?? '').toString().trim();
        if (code == TourySystemStatusCodes.tripInProgress ||
            code == TourySystemStatusCodes.tripStarted ||
            order.halhText == DriverTripHalh.inProgress) {
          target = order.tripDestination ?? target;
        }
        await DriverTripService.updateTrackingMetrics(
          orderRef: activeRef,
          driverPosition: loc,
          target: target,
        );
        try {
          await DriverTripService.maybeAutoMarkArrived(
            order: order,
            driverPosition: loc,
          );
        } catch (_) {}
      } catch (e) {
        debugPrint('DriverLiveLocationService.syncNow active trip: $e');
      }
    }
  }

  /// تتبع خفيف عندما يكون المندوب متصلاً بدون رحلة نشطة.
  static void startIdleSync({bool isOnline = true}) {
    stopIdleSync();
    final hasTrip = FFAppState().revOrder != null;
    if ((!isOnline && !hasTrip) || !loggedIn) return;

    unawaited(syncNow());

    final interval = hasTrip
        ? const Duration(seconds: 8)
        : const Duration(seconds: 20);
    _idleTimer = Timer.periodic(interval, (_) {
      unawaited(syncNow());
    });
  }

  static void stopIdleSync({bool force = false}) {
    if (!force && FFAppState().revOrder != null) {
      // Keep light sync while an active trip is restored.
      return;
    }
    _idleTimer?.cancel();
    _idleTimer = null;
    unawaited(_idleStream?.cancel());
    _idleStream = null;
  }
}
