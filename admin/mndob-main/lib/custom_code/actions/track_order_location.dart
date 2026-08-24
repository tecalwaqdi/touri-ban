// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'start_tracking_and_update_firebase.dart';

/// Trip tracking via free Geolocator (no TransistorSoft license banner).
Future trackOrderLocation(DocumentReference orderRef) async {
  await startTrackingAndUpdateFirebase(orderRef);
}
