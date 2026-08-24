// Automatic FlutterFlow imports
import '/backend/backend.dart';
// Imports other custom actions
// Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!


import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';

StreamSubscription<Position>? _positionStream;
DocumentReference? _trackedOrderRef;
bool _starting = false;

/// Notifies trip UI when background tracking starts/stops.
final ValueNotifier<bool> tripBackgroundTrackingActive =
    ValueNotifier<bool>(false);

/// Latest user-facing reason tracking could not start (permission, etc.).
final ValueNotifier<String?> tripTrackingUserMessage =
    ValueNotifier<String?>(null);

/// True while an active-trip Geolocator stream is running.
bool get isTripBackgroundTrackingActive =>
    _positionStream != null && _trackedOrderRef != null;

DocumentReference? get trackedTripOrderRef => _trackedOrderRef;

void _setTrackingActive(bool active) {
  if (tripBackgroundTrackingActive.value != active) {
    tripBackgroundTrackingActive.value = active;
  }
}

DocumentReference _resolveOrderRef(dynamic orderIdOrRef) {
  if (orderIdOrRef is DocumentReference) {
    return orderIdOrRef;
  }
  return FirebaseFirestore.instance
      .collection('order')
      .doc(orderIdOrRef.toString());
}

LocationSettings _tripLocationSettings() {
  if (Platform.isIOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      activityType: ActivityType.automotiveNavigation,
      distanceFilter: 10,
      pauseLocationUpdatesAutomatically: false,
      allowBackgroundLocationUpdates: true,
      showBackgroundLocationIndicator: true,
    );
  }
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
      intervalDuration: const Duration(seconds: 5),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Touri Trip — live tracking',
        notificationText:
            'Sharing your location with the customer during this active trip',
        enableWakeLock: true,
      ),
    );
  }
  return const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 10,
  );
}

Future<LocationPermission> _ensureTripLocationPermission() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return permission;
  }

  // Soft-upgrade to Always only when starting an active-trip stream.
  // Background delivery on iOS requires Always (or Always & When In Use).
  if (permission == LocationPermission.whileInUse) {
    try {
      permission = await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('Trip tracking Always upgrade: $e');
    }
  }
  return permission;
}

/// Start live trip tracking after accept / restore.
/// Idempotent: restarting for the same or another order replaces the stream.
/// Returns true when the background trip stream is running for [orderIdOrRef].
Future<bool> startTrackingAndUpdateFirebase(dynamic orderIdOrRef) async {
  if (_starting) {
    // Another start is in flight; if same order already tracked, treat as OK.
    final pendingRef = _resolveOrderRef(orderIdOrRef);
    return _trackedOrderRef?.path == pendingRef.path &&
        _positionStream != null;
  }
  _starting = true;
  try {
    final orderRef = _resolveOrderRef(orderIdOrRef);

    // Guard: only track real active trips for this driver.
    try {
      final order = await OrderRecord.getDocumentOnce(orderRef);
      if (!DriverTripService.isActiveTripForCurrentDriver(order)) {
        debugPrint(
          'Trip tracking skipped — order ${orderRef.id} is not an active trip',
        );
        await stopGeolocatorOrderStream();
        return false;
      }
    } catch (e) {
      debugPrint('Trip tracking order check failed: $e');
      return false;
    }

    final permission = await _ensureTripLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Trip tracking blocked — location permission $permission');
      tripTrackingUserMessage.value =
          'Location permission is required to share your position with the customer during an active trip. Enable Always location for background updates.';
      _setTrackingActive(false);
      return false;
    }
    tripTrackingUserMessage.value = null;

    // Already tracking this order — keep the existing stream.
    if (_positionStream != null &&
        _trackedOrderRef?.path == orderRef.path) {
      _setTrackingActive(true);
      return true;
    }

    await _positionStream?.cancel();
    _positionStream = null;
    _trackedOrderRef = orderRef;

    _positionStream =
        Geolocator.getPositionStream(locationSettings: _tripLocationSettings())
            .listen((Position position) async {
      final activeRef = _trackedOrderRef;
      if (activeRef == null) return;
      try {
        final driverPos = LatLng(position.latitude, position.longitude);
        if (driverPos.latitude == 0 && driverPos.longitude == 0) return;

        final order = await OrderRecord.getDocumentOnce(activeRef);
        if (!DriverTripService.isActiveTripForCurrentDriver(order)) {
          debugPrint(
            'Trip tracking auto-stop — order ${activeRef.id} no longer active',
          );
          await stopGeolocatorOrderStream();
          return;
        }

        LatLng? target = order.customerPickup;
        if (order.halhText == DriverTripHalh.inProgress) {
          target = order.tripDestination ?? target;
        }

        await DriverTripService.updateTrackingMetrics(
          orderRef: activeRef,
          driverPosition: driverPos,
          target: target,
          heading: position.heading.isFinite ? position.heading : null,
          speed: position.speed.isFinite ? position.speed : null,
        );
        await DriverTripService.maybeAutoMarkArrived(
          order: order,
          driverPosition: driverPos,
        );
      } catch (e) {
        debugPrint('Trip tracking Firestore update error: $e');
      }
    }, onError: (Object e) {
      debugPrint('Trip tracking stream error: $e');
    });

    _setTrackingActive(true);
    if (permission == LocationPermission.whileInUse) {
      tripTrackingUserMessage.value =
          'Background location needs Always permission so the customer can follow you when the app is minimized.';
    }
    debugPrint(
      'Trip background tracking started for order ${orderRef.id} '
      '(permission=$permission)',
    );
    return true;
  } finally {
    _starting = false;
  }
}

/// Stop background trip stream. Safe to call multiple times.
Future stopGeolocatorOrderStream() async {
  final hadStream = _positionStream != null;
  await _positionStream?.cancel();
  _positionStream = null;
  _trackedOrderRef = null;
  _setTrackingActive(false);
  if (hadStream) {
    debugPrint('Trip background tracking stopped');
  }
}
