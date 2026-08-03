import '/flutter_flow/lat_lng.dart';
import '/core/toury_country_registry.dart';

/// مفتاح Google Maps المستخدم في الخرائط وبحث الأماكن (Places).
abstract final class TouryMapsConfig {
  TouryMapsConfig._();

  static const String googleMapsApiKey =
      'AIzaSyD5G1uXTPM2DP-5ZkeLQA_7FsFjxNWOIzM';

  /// Neutral ocean shell — NEVER Makkah/Saudi as a global default.
  /// Used only when UI must paint a map before country/GPS is known.
  static const LatLng mapShellCenter = LatLng(20.0, 0.0);
  @Deprecated('Use mapShellCenter or country ISO center — never invent Makkah as GPS')
  static const LatLng defaultCenter = mapShellCenter;
  static const double defaultZoom = 3.0;

  static bool isUsableCoordinate(LatLng? value) {
    if (value == null) return false;
    final lat = value.latitude;
    final lng = value.longitude;
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
      return false;
    }
    // Reject only the null-island pair (0,0), not every zero component.
    if (lat == 0 && lng == 0) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Returns [preferred] when valid; otherwise null (caller must wait for GPS).
  static LatLng? resolveLocationOrNull(LatLng? preferred) {
    return isUsableCoordinate(preferred) ? preferred : null;
  }

  /// Prefer real coords, then country ISO center, then neutral shell.
  /// Never fall back to Makkah for non-Saudi countries.
  static LatLng resolveLocation(
    LatLng? preferred, {
    LatLng? shell,
    String? countryIso2,
  }) {
    final preferredOk = resolveLocationOrNull(preferred);
    if (preferredOk != null) return preferredOk;

    final isoCenter = TouryCountryRegistry.mapCenterForIso(countryIso2);
    if (isoCenter != null) return isoCenter;

    return shell ?? mapShellCenter;
  }

  static double resolveZoom({
    double? preferred,
    String? countryIso2,
  }) {
    if (preferred != null && preferred > 0) return preferred;
    return TouryCountryRegistry.mapZoomForIso(countryIso2);
  }
}
