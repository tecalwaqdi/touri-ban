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

Future trakdemo(DocumentReference orderRef) async {
  // 1️⃣ مستمع الموقع لتحديث Firebase
  bg.BackgroundGeolocation.onLocation((bg.Location location) async {
    try {
      await orderRef.update({
        'mapuser':
            GeoPoint(location.coords.latitude, location.coords.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'speed': location.coords.speed,
      });
      print('✅ [Tracking] تم تحديث الموقع بنجاح');
    } catch (e) {
      print('❌ [Tracking] فشل تحديث الموقع: $e');
    }
  });

  // 2️⃣ مستمع الحركة لتسجيل الحركة/التوقف
  bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
    print(
        '🚗 [Motion] الحالة تغيرت إلى: ${location.isMoving ? "تحرك" : "توقف"}');
  });

  // 3️⃣ تهيئة BackgroundGeolocation بدون إعدادات غير مدعومة
  await bg.BackgroundGeolocation.ready(bg.Config(
    desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
    distanceFilter: 10.0, // تحديث كل 10 أمتار
    stopOnTerminate: false,
    startOnBoot: true,
    enableHeadless: true,
    preventSuspend: true,
    heartbeatInterval: 60,
    showsBackgroundLocationIndicator: true,
    pausesLocationUpdatesAutomatically: false,
    activityType: bg.Config.ACTIVITY_TYPE_AUTOMOTIVE_NAVIGATION,
    locationAuthorizationRequest: 'Always',
    debug: true,
    logLevel: bg.Config.LOG_LEVEL_VERBOSE,

    // stopTimeout مدعوم على Android فقط، يبقي الحركة متوقعة
    stopTimeout: 1,
  ));

  // 4️⃣ تشغيل الخدمة إذا لم تكن مفعلة
  bg.State state = await bg.BackgroundGeolocation.state;
  if (!state.enabled) {
    await bg.BackgroundGeolocation.start();
  }
}
