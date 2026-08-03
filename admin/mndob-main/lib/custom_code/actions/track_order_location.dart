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

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/flutter_flow/lat_lng.dart';

Future trackOrderLocation(DocumentReference orderRef) async {
  OrderRecord? cachedOrder;

  Future<void> onPosition(double lat, double lon) async {
    try {
      cachedOrder ??= await OrderRecord.getDocumentOnce(orderRef);
      final order = cachedOrder!;
      final driverPos = LatLng(lat, lon);

      LatLng? target = order.customerPickup;
      if (order.halhText == DriverTripHalh.inProgress) {
        target = order.tripDestination ?? target;
      }

      await DriverTripService.updateTrackingMetrics(
        orderRef: orderRef,
        driverPosition: driverPos,
        target: target,
      );

      await DriverTripService.maybeAutoMarkArrived(
        order: order,
        driverPosition: driverPos,
      );

      cachedOrder = await OrderRecord.getDocumentOnce(orderRef);
    } catch (e) {
      print('❌ [Tracking] فشل تحديث الموقع: $e');
    }
  }

  // 1. إعداد مستمع الموقع (Location Listener)
  bg.BackgroundGeolocation.onLocation((bg.Location location) async {
    try {
      await orderRef.update({
        'mapuser':
            GeoPoint(location.coords.latitude, location.coords.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'speed': location.coords.speed,
      });
      await onPosition(location.coords.latitude, location.coords.longitude);
      print('✅ [Tracking] تم تحديث الموقع بنجاح');
    } catch (e) {
      print('❌ [Tracking] فشل تحديث الموقع: $e');
    }
  });

  // 2. مستمع حالة الحركة (اختياري: فقط للطباعة في الـ log، بدون إشعارات)
  bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
    // إذا أردت عدم طباعة أي شيء عند تغير الحركة، يمكن حذف هذا المستمع تماماً
    // حالياً فقط يطبع في الـ console، لا إشعارات
    print(
        '🚗 [Motion] الحالة تغيرت إلى: ${location.isMoving ? "تحرك" : "توقف"}');
  });

  // 3. تهيئة المكتبة بأفضل إعدادات ممكنة لـ FlutterFlow
  await bg.BackgroundGeolocation.ready(bg.Config(
    // الدقة والمسافة
    desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
    distanceFilter: 10.0, // تحديث كل 10 أمتار

    // إعدادات الخلفية (Background)
    stopOnTerminate: false,
    startOnBoot: true,
    enableHeadless: true,

    // إعدادات iOS
    preventSuspend: true,
    heartbeatInterval: 60,
    showsBackgroundLocationIndicator: false, // إيقاف العلامة الزرقاء
    pausesLocationUpdatesAutomatically: false,

    // هوية التطبيق
    activityType: bg.Config.ACTIVITY_TYPE_AUTOMOTIVE_NAVIGATION,
    locationAuthorizationRequest: 'Always',

    // إيقاف أي إشعارات Debug أو أصوات
    debug: false,
    logLevel: bg.Config.LOG_LEVEL_VERBOSE,
  ));

  // 4. تشغيل الخدمة
  bg.State state = await bg.BackgroundGeolocation.state;
  if (!state.enabled) {
    await bg.BackgroundGeolocation.start();
  }
}
