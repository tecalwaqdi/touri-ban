// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:geolocator/geolocator.dart';

Future<double> get(
  LatLng place1,
  LatLng place2,
) async {
  double distanceInMeters = Geolocator.distanceBetween(
    place1.latitude,
    place1.longitude,
    place2.latitude,
    place2.longitude,
  );
  return distanceInMeters / 1000;
}
