import 'dart:math' as math;

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_country_service.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_maps_config.dart';
import '/core/toury_system_status_codes.dart';

/// Builds and ranks new-order queries for the driver app (GPS-first).
abstract final class DriverOrderMatch {
  DriverOrderMatch._();

  /// Max distance (km) from driver GPS to order pickup.
  static const maxOrderRadiusKm = 80.0;

  @Deprecated('Use maxOrderRadiusKm')
  static const maxCrossCityKm = maxOrderRadiusKm;

  static DocumentReference? driverCountryRef() => FFAppState().dolh;

  static DocumentReference? driverVillageRef() =>
      currentUserDocument?.mndobVill;

  /// City/region selected at registration (`FFAppState.mdenh` / village.cities).
  static DocumentReference? driverCityRef() => FFAppState().mdenh;

  static DocumentReference? driverTypeCarRef() =>
      currentUserDocument?.mndobTypeCar;

  /// Load city from village.cities when AppState city is empty.
  static Future<DocumentReference?> ensureDriverCity() async {
    final existing = driverCityRef();
    if (existing != null) return existing;
    final vill = driverVillageRef();
    if (vill == null) return null;
    try {
      final snap = await vill.get();
      final data = snap.data();
      if (data is Map) {
        final cities = data['cities'];
        if (cities is DocumentReference) {
          FFAppState().mdenh = cities;
          return cities;
        }
      }
    } catch (_) {}
    return null;
  }

  static LatLng? driverLivePosition() {
    final live = currentUserDocument?.loceshnMndobNow;
    if (TouryMapsConfig.isUsableCoordinate(live)) return live;
    return null;
  }

  /// Resolve country from village, then from live GPS coordinates.
  static Future<DocumentReference?> ensureDriverCountry() async {
    final existing = FFAppState().dolh;
    if (existing != null) return existing;

    final vill = currentUserDocument?.mndobVill;
    if (vill != null) {
      try {
        final snap = await vill.get();
        final data = snap.data();
        if (data is Map) {
          final dolh = data['dolh'];
          if (dolh is DocumentReference) {
            FFAppState().dolh = dolh;
            return dolh;
          }
        }
      } catch (_) {}
    }

    final pos = driverLivePosition();
    if (pos == null) return null;
    final iso = TouryCountryRegistry.isoFromCoordinates(pos);
    if (iso == null) return null;

    final countries = await DriverCountryService.listActiveCountries();
    final match = countries
        .where((c) => DriverCountryService.isoOfCountry(c) == iso)
        .firstOrNull;
    if (match == null) return null;
    await DriverCountryService.applyCountry(FFAppState(), match);
    return FFAppState().dolh;
  }

  /// Firestore query: open pool only (status + ALLNOW).
  /// Car/country filtered in [rankForDriver] to avoid composite-index failures.
  static Query Function(Query) queryBuilder({
    DocumentReference? countryRef,
    DocumentReference? typeCarRef,
  }) {
    return (q) => q
        .where(
          'status_code',
          isEqualTo: TourySystemStatusCodes.pendingDriver,
        )
        .where('ALLNOW', isEqualTo: true)
        .orderBy('data_order', descending: true);
  }

  /// Assigned to this driver — filter active/completed/cancelled client-side.
  static Query Function(Query) assignedToMeQuery() {
    final me = currentUserReference;
    return (q) {
      var query = q;
      if (me != null) {
        query = query.where('mndob_user', isEqualTo: me);
      }
      return query.orderBy('data_order', descending: true);
    };
  }

  static LatLng? pickupOf(OrderRecord order) {
    if (order.lokeshn != null) return order.lokeshn;
    if (order.mapuser != null) return order.mapuser;
    final lat = order.originLatitude;
    final lng = order.originLongitude;
    if (lat != 0 || lng != 0) return LatLng(lat, lng);
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

  /// Distance in km from driver to order pickup, or null when unknown.
  static double? distanceKm(OrderRecord order, LatLng? driverPosition) {
    if (driverPosition == null) return null;
    final pickup = pickupOf(order);
    if (pickup == null) return null;
    final km = _haversineKm(driverPosition, pickup);
    return km.isFinite ? km : null;
  }

  /// Pure ranking decision for tests (no Firestore).
  /// Returns null when the order should be dropped; otherwise (boost, km).
  /// boost 0 = same village/city (preferred), 1 = out of area but nearby.
  static ({int boost, double km})? scoreForMatch({
    String? orderVillPath,
    String? orderCityPath,
    String? driverVillPath,
    String? driverCityPath,
    double? distanceKm,
    double maxRadiusKm = maxOrderRadiusKm,
  }) {
    final sameVillage =
        driverVillPath != null &&
        orderVillPath != null &&
        orderVillPath == driverVillPath;
    final sameCity =
        driverCityPath != null &&
        orderCityPath != null &&
        orderCityPath == driverCityPath;
    final hasArea = driverVillPath != null || driverCityPath != null;
    final km = distanceKm;
    final finite = km != null && km.isFinite;

    if (!hasArea) {
      if (finite && km > maxRadiusKm) return null;
      return (boost: 0, km: finite ? km : 99999);
    }

    final inArea = sameVillage || sameCity;
    if (!inArea && finite && km > maxRadiusKm) return null;
    if (!inArea && !finite) {
      return (boost: 1, km: 99999);
    }
    return (
      boost: inArea ? 0 : 1,
      km: finite ? km : 99999,
    );
  }

  /// Rank by nearest pickup to driver GPS. Optional village/city boost.
  /// Drops orders farther than [maxOrderRadiusKm] when GPS is known.
  static List<OrderRecord> rankForDriver(
    List<OrderRecord> orders, {
    DocumentReference? driverCityOrVillage,
    DocumentReference? driverCityRef,
    LatLng? driverPosition,
  }) {
    final village = driverCityOrVillage ?? driverVillageRef();
    final city = driverCityRef ?? DriverOrderMatch.driverCityRef();
    final position = driverPosition ?? driverLivePosition();
    final scored = <({OrderRecord order, int cityBoost, double km})>[];

    final car = driverTypeCarRef();
    final country = driverCountryRef();

    for (final order in orders) {
      // Pool UI: hide already-assigned rows (rules allow browse without
      // proving mndob_user==null on the list query).
      if (order.mndobUser != null) continue;
      if (car != null &&
          order.carRev != null &&
          order.carRev!.path != car.path) {
        continue;
      }
      final orderCountry = order.snapshotData['Rev_dolh'];
      if (country != null &&
          orderCountry is DocumentReference &&
          orderCountry.path != country.path) {
        continue;
      }

      final sameVillage = village != null &&
          order.vill != null &&
          order.vill!.path == village.path;
      // Compare city↔city only (never village path vs cities_user_now).
      final sameCity = order.citiesUserNow != null &&
          city != null &&
          order.citiesUserNow!.path == city.path;

      final pickup = pickupOf(order);
      var km = double.infinity;
      if (position != null && pickup != null) {
        km = _haversineKm(position, pickup);
      }

      // GPS-first: without a work village/city, keep only nearby orders.
      if (village == null && city == null) {
        if (position != null) {
          if (!km.isFinite || km > maxOrderRadiusKm) continue;
        }
        scored.add((
          order: order,
          cityBoost: 0,
          km: km.isFinite ? km : 99999,
        ));
        continue;
      }

      final inArea = sameVillage || sameCity;
      if (!inArea && km.isFinite && km > maxOrderRadiusKm) {
        continue;
      }
      if (!inArea && !km.isFinite) {
        km = 99999;
      }

      scored.add((
        order: order,
        cityBoost: inArea ? 0 : 1,
        km: km.isFinite ? km : 99999,
      ));
    }

    scored.sort((a, b) {
      final c = a.cityBoost.compareTo(b.cityBoost);
      if (c != 0) return c;
      return a.km.compareTo(b.km);
    });
    return scored.map((e) => e.order).toList();
  }
}
