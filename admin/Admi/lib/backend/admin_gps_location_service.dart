import 'package:geolocator/geolocator.dart';

import '/flutter_flow/lat_lng.dart';

/// قراءة موقع الجهاز الحالي (GPS) مع طلب الصلاحيات عند الحاجة.
abstract final class AdminGpsLocationService {
  AdminGpsLocationService._();

  static Future<LatLng?> currentPosition({bool requestPermission = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

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
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (latLng.latitude == 0 && latLng.longitude == 0) {
        return null;
      }
      return latLng;
    } catch (_) {
      return null;
    }
  }
}
