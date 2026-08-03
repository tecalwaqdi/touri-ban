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
import 'start_tracking_and_update_firebase.dart';

Future stopTracking() async {
  await stopGeolocatorOrderStream();
  await bg.BackgroundGeolocation.stop();
  await bg.BackgroundGeolocation.removeListeners();
}
