import 'dart:math' as math;

import 'package:collection/collection.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_country_service.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Resolves the driver's **current work city/village** from fresh GPS.
///
/// Registration village/city is an explicit fallback only when GPS is
/// unavailable or stale — it must never override a fresh fix.
abstract final class DriverWorkAreaResolver {
  DriverWorkAreaResolver._();

  /// Do not treat fixes older than this as current work area.
  static const gpsMaxAge = Duration(minutes: 5);

  /// Ephemeral work refs (AppState) — not registration profile fields.
  static DocumentReference? workCityRef() => FFAppState().mdenh;
  static DocumentReference? workVillageRef() =>
      FFAppState().workVillageNow ?? currentUserDocument?.mndobVill;

  static String workAreaSource() =>
      (FFAppState().workAreaSource).trim().isEmpty
          ? 'registration_fallback'
          : FFAppState().workAreaSource;

  static LatLng? _latOfVillage(VillagesRecord v) {
    final raw = v.snapshotData['lat_ling'];
    if (raw is LatLng && TouryMapsConfig.isUsableCoordinate(raw)) return raw;
    if (raw is GeoPoint) {
      final p = LatLng(raw.latitude, raw.longitude);
      if (TouryMapsConfig.isUsableCoordinate(p)) return p;
    }
    return null;
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final la1 = _rad(a.latitude);
    final la2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
  }

  static double _rad(double d) => d * math.pi / 180.0;

  static bool _gpsFresh(DateTime? updatedAt, DateTime now) {
    if (updatedAt == null) return false;
    return now.difference(updatedAt) <= gpsMaxAge;
  }

  /// Apply registration city/village as explicit fallback (tagged).
  static Future<void> applyRegistrationFallback() async {
    FFAppState().workAreaSource = 'registration_fallback';
    final vill = currentUserDocument?.mndobVill;
    if (vill != null) {
      FFAppState().workVillageNow = vill;
      try {
        final snap = await vill.get();
        final data = snap.data();
        if (data is Map) {
          final cities = data['cities'];
          if (cities is DocumentReference) {
            FFAppState().mdenh = cities;
          }
          final dolh = data['dolh'];
          if (dolh is DocumentReference) {
            FFAppState().dolh = dolh;
          }
        }
      } catch (_) {}
    }
  }

  /// Resolve lat/lng → authorized country → nearest canonical village → city.
  ///
  /// Writes ephemeral AppState + optional `work_*_now` user fields (not
  /// registration `mndob_vill` / profile edit).
  static Future<DriverWorkAreaResult> refreshFromGps({
    LatLng? position,
    DateTime? gpsUpdatedAt,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final pos = position ?? currentUserDocument?.loceshnMndobNow;
    if (!TouryMapsConfig.isUsableCoordinate(pos)) {
      await applyRegistrationFallback();
      return DriverWorkAreaResult.fallback(
        reason: 'gps_unavailable',
        city: FFAppState().mdenh,
        village: FFAppState().workVillageNow,
      );
    }

    DateTime? lastSeen;
    final rawSeen = currentUserDocument?.snapshotData['last_seen_at'] ??
        currentUserDocument?.snapshotData['work_area_updated_at'];
    if (rawSeen is DateTime) {
      lastSeen = rawSeen;
    } else if (rawSeen is Timestamp) {
      lastSeen = rawSeen.toDate();
    }
    final updated =
        gpsUpdatedAt ?? FFAppState().workAreaUpdatedAt ?? lastSeen;
    // A live [position] argument always counts as fresh.
    final fresh =
        position != null || gpsUpdatedAt != null || _gpsFresh(updated, clock);
    if (!fresh) {
      await applyRegistrationFallback();
      return DriverWorkAreaResult.fallback(
        reason: 'gps_stale',
        city: FFAppState().mdenh,
        village: FFAppState().workVillageNow,
      );
    }

    final iso = TouryCountryRegistry.isoFromCoordinates(pos!);
    if (iso == null) {
      await applyRegistrationFallback();
      return DriverWorkAreaResult.fallback(
        reason: 'outside_known_bounds',
        city: FFAppState().mdenh,
        village: FFAppState().workVillageNow,
      );
    }

    // Authorized country check (runtime must stay in same authorized country).
    DocumentReference? countryRef = FFAppState().dolh;
    if (countryRef == null) {
      final countries = await DriverCountryService.listActiveCountries();
      final match = countries
          .where((c) => DriverCountryService.isoOfCountry(c) == iso)
          .firstOrNull;
      if (match != null) {
        await DriverCountryService.applyCountry(FFAppState(), match);
        countryRef = FFAppState().dolh;
      }
    } else {
      final authorizedIso =
          TouryCountryRegistry.normalizeIso(countryRef.id);
      if (authorizedIso != null && authorizedIso != iso) {
        // Physically left authorized country — keep registration fallback.
        await applyRegistrationFallback();
        return DriverWorkAreaResult.fallback(
          reason: 'outside_authorized_country',
          city: FFAppState().mdenh,
          village: FFAppState().workVillageNow,
        );
      }
    }

    if (countryRef == null) {
      await applyRegistrationFallback();
      return DriverWorkAreaResult.fallback(
        reason: 'country_unresolved',
        city: FFAppState().mdenh,
        village: FFAppState().workVillageNow,
      );
    }

    List<VillagesRecord> villages;
    try {
      villages = await queryVillagesRecordOnce(
        queryBuilder: (q) => q
            .where('dolh', isEqualTo: countryRef)
            .where('acctev', isEqualTo: true)
            .limit(300),
      );
    } catch (_) {
      villages = await queryVillagesRecordOnce(
        queryBuilder: (q) => q.where('dolh', isEqualTo: countryRef).limit(300),
      );
    }

    VillagesRecord? nearest;
    var bestKm = double.infinity;
    for (final v in villages) {
      final loc = _latOfVillage(v);
      if (loc == null) continue;
      final km = _haversineKm(pos, loc);
      if (km < bestKm) {
        bestKm = km;
        nearest = v;
      }
    }

    if (nearest == null || !bestKm.isFinite) {
      await applyRegistrationFallback();
      return DriverWorkAreaResult.fallback(
        reason: 'no_village_lat_ling',
        city: FFAppState().mdenh,
        village: FFAppState().workVillageNow,
      );
    }

    final city = nearest.cities;
    final villageRef = nearest.reference;
    FFAppState().update(() {
      FFAppState().workVillageNow = villageRef;
      FFAppState().workAreaSource = 'gps';
      FFAppState().workAreaUpdatedAt = clock;
      if (city != null) FFAppState().mdenh = city;
      FFAppState().dolh = countryRef;
    });

    // Persist work area for server offer waves (not registration profile).
    final userRef = currentUserReference;
    if (userRef != null) {
      try {
        await userRef.update({
          if (city != null) 'work_city_now': city,
          'work_village_now': villageRef,
          'work_country_now': countryRef,
          'work_area_source': 'gps',
          'work_area_updated_at': FieldValue.serverTimestamp(),
          'loceshnMndobNow': GeoPoint(pos.latitude, pos.longitude),
        });
      } catch (_) {}
    }

    return DriverWorkAreaResult(
      source: 'gps',
      city: city ?? FFAppState().mdenh,
      village: villageRef,
      distanceKm: bestKm,
    );
  }
}

class DriverWorkAreaResult {
  const DriverWorkAreaResult({
    required this.source,
    this.city,
    this.village,
    this.distanceKm,
    this.reason,
  });

  factory DriverWorkAreaResult.fallback({
    required String reason,
    DocumentReference? city,
    DocumentReference? village,
  }) =>
      DriverWorkAreaResult(
        source: 'registration_fallback',
        city: city,
        village: village,
        reason: reason,
      );

  final String source;
  final DocumentReference? city;
  final DocumentReference? village;
  final double? distanceKm;
  final String? reason;
}
