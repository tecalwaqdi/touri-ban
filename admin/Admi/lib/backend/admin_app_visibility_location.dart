import 'dart:math' as math;

import '/flutter_flow/lat_lng.dart';

/// Helpers for Saudi city bboxes used by older customer-app GPS filters.
///
/// Landmark saves must keep the admin's real pin. Do **not** clamp coordinates
/// into these boxes — that made the app map show the wrong place while Admin
/// still looked correct. List visibility is driven by `id_vill` in current apps.
abstract final class AdminAppVisibilityLocation {
  AdminAppVisibilityLocation._();

  static const _cities = <_CityBox>[
    _CityBox(
      slug: 'taif',
      center: LatLng(21.2703, 40.4158),
      minLat: 21.15,
      maxLat: 21.45,
      minLng: 40.25,
      maxLng: 40.62,
    ),
    _CityBox(
      slug: 'makkah',
      center: LatLng(21.4225, 39.8262),
      minLat: 21.30,
      maxLat: 21.55,
      minLng: 39.72,
      maxLng: 40.02,
    ),
    _CityBox(
      slug: 'mecca',
      center: LatLng(21.4225, 39.8262),
      minLat: 21.30,
      maxLat: 21.55,
      minLng: 39.72,
      maxLng: 40.02,
    ),
    _CityBox(
      slug: 'jeddah',
      center: LatLng(21.5433, 39.1728),
      minLat: 21.45,
      maxLat: 21.78,
      minLng: 39.02,
      maxLng: 39.38,
    ),
    _CityBox(
      slug: 'madinah',
      center: LatLng(24.4686, 39.6142),
      minLat: 24.38,
      maxLat: 24.58,
      minLng: 39.48,
      maxLng: 39.72,
    ),
    _CityBox(
      slug: 'medina',
      center: LatLng(24.4686, 39.6142),
      minLat: 24.38,
      maxLat: 24.58,
      minLng: 39.48,
      maxLng: 39.72,
    ),
    _CityBox(
      slug: 'riyadh',
      center: LatLng(24.7136, 46.6753),
      minLat: 24.45,
      maxLat: 25.05,
      minLng: 46.35,
      maxLng: 47.05,
    ),
  ];

  static String? _slugFromVillageId(String? villageId) {
    if (villageId == null || villageId.isEmpty) return null;
    var id = villageId.trim().toLowerCase();
    if (id.startsWith('city_sa_')) {
      id = id.substring('city_sa_'.length);
    } else if (id.startsWith('city_')) {
      id = id.substring('city_'.length);
    }
    return id;
  }

  static _CityBox? _boxForVillageId(String? villageId) {
    final slug = _slugFromVillageId(villageId);
    if (slug == null) return null;
    for (final c in _cities) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  static bool pinPassesStoreFilter(LatLng pin, String? villageId) {
    final box = _boxForVillageId(villageId);
    if (box == null) {
      // Non-Saudi / unknown — store filter skips GPS check.
      return true;
    }
    if (box.contains(pin)) return true;
    // Soft edge used by the customer app (≤ 12 km from city center).
    return _distanceKm(pin, box.center) <= 12;
  }

  /// Returns the real pin for Firestore. Never moves coordinates.
  ///
  /// Previously clamped into city bboxes so old Play Store builds would list
  /// the landmark — that broke map accuracy. Prefer fixing the app filter
  /// (`id_vill`) over rewriting GPS.
  static LatLng ensureVisibleInStoreApp({
    required LatLng? pin,
    required String? villageId,
    LatLng? villageCenter,
  }) {
    if (pin != null && _isValid(pin)) return pin;
    if (villageCenter != null && _isValid(villageCenter)) return villageCenter;
    final box = _boxForVillageId(villageId);
    if (box != null) return box.center;
    return const LatLng(24.7136, 46.6753);
  }

  static bool _isValid(LatLng p) {
    if (p.latitude.isNaN || p.longitude.isNaN) return false;
    if (p.latitude.abs() < 0.0001 && p.longitude.abs() < 0.0001) return false;
    return p.latitude >= -90 &&
        p.latitude <= 90 &&
        p.longitude >= -180 &&
        p.longitude <= 180;
  }

  static double _distanceKm(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final lat1 = a.latitude * p;
    final lat2 = b.latitude * p;
    final dLat = (b.latitude - a.latitude) * p;
    final dLng = (b.longitude - a.longitude) * p;
    final h = (1 - math.cos(dLat)) / 4 +
        math.cos(lat1) * math.cos(lat2) * (1 - math.cos(dLng)) / 4;
    final s = h.clamp(0.0, 1.0);
    return 12742 * math.asin(math.sqrt(s));
  }
}

class _CityBox {
  const _CityBox({
    required this.slug,
    required this.center,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final String slug;
  final LatLng center;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  bool contains(LatLng p) =>
      p.latitude >= minLat &&
      p.latitude <= maxLat &&
      p.longitude >= minLng &&
      p.longitude <= maxLng;
}
