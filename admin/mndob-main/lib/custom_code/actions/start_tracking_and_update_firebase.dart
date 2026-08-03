// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '/backend/backend.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_trip_service.dart';
import '/flutter_flow/lat_lng.dart';

StreamSubscription<Position>? _positionStream;
DocumentReference? _trackedOrderRef;

DocumentReference _resolveOrderRef(dynamic orderIdOrRef) {
  if (orderIdOrRef is DocumentReference) {
    return orderIdOrRef;
  }
  return FirebaseFirestore.instance
      .collection('order')
      .doc(orderIdOrRef.toString());
}

/// بدء التتبع عند قبول الطلب — يقبل معرّف المستند أو DocumentReference.
Future startTrackingAndUpdateFirebase(dynamic orderIdOrRef) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permission denied');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Location permission permanently denied');
    return;
  }

  await _positionStream?.cancel();
  _positionStream = null;

  final orderRef = _resolveOrderRef(orderIdOrRef);
  _trackedOrderRef = orderRef;

  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 5,
  );

  _positionStream =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) async {
    if (_trackedOrderRef == null) return;
    try {
      final driverPos = LatLng(position.latitude, position.longitude);
      if (driverPos.latitude == 0 && driverPos.longitude == 0) return;

      final order = await OrderRecord.getDocumentOnce(_trackedOrderRef!);
      LatLng? target = order.customerPickup;
      if (order.halhText == 'تم البدء في الرحلة') {
        target = order.tripDestination ?? target;
      }

      await DriverTripService.updateTrackingMetrics(
        orderRef: _trackedOrderRef!,
        driverPosition: driverPos,
        target: target,
      );
      await DriverTripService.maybeAutoMarkArrived(
        order: order,
        driverPosition: driverPos,
      );

      print(
          'Location updated for order ${_trackedOrderRef!.id}: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Firestore update error: $e');
    }
  });

  print('Tracking started for order ${orderRef.id}');
}

Future stopGeolocatorOrderStream() async {
  await _positionStream?.cancel();
  _positionStream = null;
  _trackedOrderRef = null;
}
