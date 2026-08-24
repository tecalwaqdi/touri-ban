// Automatic FlutterFlow imports
import 'index.dart'; // Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'start_tracking_and_update_firebase.dart';

Future stopTracking() async {
  await stopGeolocatorOrderStream();
}
