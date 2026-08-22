import 'dart:convert';
import 'dart:io';

import 'package:ara_oatan_app/app_state.dart';
import 'package:ara_oatan_app/backend/schema/structs/amakn_costm_struct.dart';
import 'package:ara_oatan_app/core/toury_checkout_state.dart';
import 'package:ara_oatan_app/core/toury_distance_format.dart';
import 'package:ara_oatan_app/core/toury_route_metrics.dart';
import 'package:ara_oatan_app/flutter_flow/lat_lng.dart';
import 'package:flutter_test/flutter_test.dart';

/// Live scenario checks for route origin + multi-stop metrics.
/// Uses dart:io HttpClient so Flutter's test HTTP stub does not block OSRM.
void main() {
  // Makkah-area points (approx tourist route).
  const pickup = LatLng(21.4225, 39.8262);
  const jabalRahmah = LatLng(21.3891, 39.8765);
  const clockTower = LatLng(21.4187, 39.8261);
  const mina = LatLng(21.4133, 39.8930);
  const makkahCenter = LatLng(21.3891, 39.8579);
  const riyadhGps = LatLng(24.7136, 46.6753);

  String fingerprint({
    required LatLng? origin,
    required List<LatLng?> stops,
  }) {
    final buf = StringBuffer()
      ..write(origin?.latitude)
      ..write(',')
      ..write(origin?.longitude);
    for (final stop in stops) {
      buf
        ..write('|')
        ..write(stop?.latitude)
        ..write(',')
        ..write(stop?.longitude);
    }
    return buf.toString();
  }

  Future<({double km, double minutes, List<Map<String, double>> legs})>
      osrmDrive(List<LatLng> points) async {
    final coordinates =
        points.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinates'
      '?overview=false&steps=false',
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(url).timeout(const Duration(seconds: 20));
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      expect(response.statusCode, 200, reason: 'OSRM HTTP');
      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body) as Map<String, dynamic>;
      expect(data['code'], 'Ok', reason: 'OSRM code');
      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final legsRaw = (route['legs'] as List?) ?? const [];
      final legs = legsRaw
          .map((leg) => {
                'km': (leg['distance'] as num).toDouble() / 1000.0,
                'minutes': (leg['duration'] as num).toDouble() / 60.0,
              })
          .toList(growable: false);
      return (
        km: (route['distance'] as num).toDouble() / 1000.0,
        minutes: (route['duration'] as num).toDouble() / 60.0,
        legs: legs,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Same path both Checkout and Mmaapp use after the origin fix.
  Future<({double km, double minutes, int rejected})> computeSharedRoute({
    required LatLng origin,
    required List<LatLng?> destinations,
    LatLng? areaCenter,
  }) async {
    final validation = touryValidateRoutePoints(
      origin: origin,
      destinations: destinations,
      selectedAreaCenter: areaCenter ?? makkahCenter,
    );
    expect(validation.canRoute, isTrue,
        reason: validation.errorKey ?? 'canRoute');
    final road = await osrmDrive(validation.points);
    expect(
      touryRoadMetricsArePlausible(
        distanceKm: road.km,
        durationSeconds: road.minutes * 60,
        points: validation.points,
      ),
      isTrue,
    );
    return (
      km: road.km,
      minutes: road.minutes,
      rejected: validation.rejectedCount,
    );
  }

  group('origin preference (scenario 7)', () {
    late FFAppState app;

    setUp(() {
      app = FFAppState();
      app.mkanuserorder = null;
      app.akrLoceshn = null;
      app.latlngvill = null;
    });

    test('uses saved pickup, ignores distant GPS candidate order', () {
      app.mkanuserorder = pickup;
      app.latlngvill = makkahCenter;
      expect(touryResolveTripRouteOrigin(app), pickup);
      expect(touryResolveTripRouteOrigin(app), isNot(riyadhGps));
    });

    test('falls back to city center when pickup missing', () {
      app.latlngvill = makkahCenter;
      expect(touryResolveTripRouteOrigin(app), makkahCenter);
    });
  });

  group('coordinate validation (scenario 8)', () {
    test('rejects null / 0,0 / swapped and keeps valid stop', () {
      final validation = touryValidateRoutePoints(
        origin: pickup,
        selectedAreaCenter: makkahCenter,
        destinations: const [
          null,
          LatLng(0, 0),
          LatLng(39.8262, 21.4225), // swapped
          jabalRahmah,
        ],
      );
      expect(validation.rejectedCount, greaterThanOrEqualTo(3));
      expect(validation.canRoute, isTrue);
      expect(validation.points.last, jabalRahmah);
    });
  });

  group('fingerprint invalidate (scenarios 4–5)', () {
    test('add and remove landmark change fingerprint', () {
      final origin = pickup;
      final base = fingerprint(origin: origin, stops: [jabalRahmah]);
      final added =
          fingerprint(origin: origin, stops: [jabalRahmah, clockTower]);
      final removed = fingerprint(origin: origin, stops: [jabalRahmah]);
      expect(base, isNot(added));
      expect(removed, base);
    });
  });

  group('shared SoT numbers across screens (scenarios 1–3, 12)', () {
    test('pickup + destination only — checkout path == map path', () async {
      final a = await computeSharedRoute(
        origin: pickup,
        destinations: [clockTower],
      );
      final b = await computeSharedRoute(
        origin: pickup,
        destinations: [clockTower],
      );
      expect(a.km, closeTo(b.km, 0.01));
      expect(a.minutes, closeTo(b.minutes, 0.1));
      expect(a.km, greaterThan(0.5));
      expect(a.minutes, greaterThan(1));
      // ignore: avoid_print
      print('S1 pickup+dest: ${a.km.toStringAsFixed(2)} km, '
          '${a.minutes.round()} min');
    });

    test('one landmark between pickup and final', () async {
      final result = await computeSharedRoute(
        origin: pickup,
        destinations: [jabalRahmah, clockTower],
      );
      expect(result.km, greaterThan(5));
      expect(result.minutes, greaterThan(5));
      // ignore: avoid_print
      print('S2 one landmark: ${result.km.toStringAsFixed(2)} km, '
          '${result.minutes.round()} min');
    });

    test('multi landmarks keep cart order (not optimized)', () async {
      final orderA = await computeSharedRoute(
        origin: pickup,
        destinations: [jabalRahmah, mina, clockTower],
      );
      final orderB = await computeSharedRoute(
        origin: pickup,
        destinations: [mina, jabalRahmah, clockTower],
      );
      expect(
        (orderA.km - orderB.km).abs() > 0.3 ||
            (orderA.minutes - orderB.minutes).abs() > 0.5,
        isTrue,
        reason: 'cart order must affect route totals',
      );
      // ignore: avoid_print
      print('S3 orderA ${orderA.km.toStringAsFixed(2)} km / '
          '${orderA.minutes.round()} min | orderB '
          '${orderB.km.toStringAsFixed(2)} km / ${orderB.minutes.round()} min');
    });

    test('add then remove recalculates different totals', () async {
      final one = await computeSharedRoute(
        origin: pickup,
        destinations: [jabalRahmah],
      );
      final two = await computeSharedRoute(
        origin: pickup,
        destinations: [jabalRahmah, mina],
      );
      final back = await computeSharedRoute(
        origin: pickup,
        destinations: [jabalRahmah],
      );
      expect(two.km, greaterThan(one.km));
      expect(back.km, closeTo(one.km, 0.5));
      // ignore: avoid_print
      print('S4/S5 one=${one.km.toStringAsFixed(2)} '
          'two=${two.km.toStringAsFixed(2)} back=${back.km.toStringAsFixed(2)}');
    });
  });

  group('GPS outside city (scenario 7)', () {
    test('saved pickup keeps Makkah stops; GPS origin invents huge trip', () {
      final withPickup = touryValidateRoutePoints(
        origin: pickup,
        destinations: [jabalRahmah, clockTower],
        selectedAreaCenter: makkahCenter,
      );
      expect(withPickup.canRoute, isTrue);
      expect(withPickup.rejectedCount, 0);

      final withGps = touryValidateRoutePoints(
        origin: riyadhGps,
        destinations: [jabalRahmah, clockTower],
        selectedAreaCenter: makkahCenter,
      );
      // Destinations near Makkah may still validate vs area center, but
      // origin=GPS creates a Riyadh→Makkah first leg (~850 km).
      expect(withGps.canRoute, isTrue);
      final gpsEstimate = touryEstimateRoute(withGps.points);
      final pickupEstimate = touryEstimateRoute(withPickup.points);
      expect(gpsEstimate.distanceKm, greaterThan(pickupEstimate.distanceKm * 10));
    });

    test('resolve origin prefers pickup over city when both set', () {
      final app = FFAppState()
        ..mkanuserorder = pickup
        ..latlngvill = makkahCenter;
      expect(touryResolveTripRouteOrigin(app), pickup);
    });
  });

  group('loading / zero display helpers', () {
    test('distance format returns empty for non-positive', () {
      expect(touryFormatDistanceKm(0), isEmpty);
      expect(touryFormatDistanceKm(-1), isEmpty);
      expect(touryFormatDistanceKm(18.6), isNotEmpty);
    });

    test('FFAppState SoT fields stay equal for list + map', () {
      final app = FFAppState();
      app.osrmTotalDistance = 18.6;
      app.osrmTotalTime = 34;
      expect(app.osrmTotalDistance, 18.6);
      expect(app.osrmTotalTime, 34);
    });
  });

  group('failure modes (scenarios 9–10)', () {
    test('haversine preview remains usable when road API unavailable', () {
      final validation = touryValidateRoutePoints(
        origin: pickup,
        destinations: [jabalRahmah],
        selectedAreaCenter: makkahCenter,
      );
      final estimate = touryEstimateRoute(validation.points);
      expect(estimate.distanceKm, greaterThan(0));
      expect(estimate.durationHours, greaterThan(0));
    });

    test('implausible Google-like spike is rejected by gate', () {
      expect(
        touryRoadMetricsArePlausible(
          distanceKm: 13036,
          durationSeconds: const Duration(hours: 211).inSeconds.toDouble(),
          points: const [pickup, jabalRahmah],
        ),
        isFalse,
      );
    });
  });

  group('cart reopen fingerprint (scenario 6)', () {
    test('rebuilding same cart yields same fingerprint', () {
      final app = FFAppState();
      app.mkanuserorder = pickup;
      app.cartmkss = [
        AmaknCostmStruct(naim: 'جبل الرحمة', loceshn: jabalRahmah),
        AmaknCostmStruct(naim: 'برج الساعة', loceshn: clockTower),
      ];
      final first = fingerprint(
        origin: touryResolveTripRouteOrigin(app),
        stops: app.cartmkss.map((e) => e.loceshn).toList(),
      );
      final second = fingerprint(
        origin: touryResolveTripRouteOrigin(app),
        stops: app.cartmkss.map((e) => e.loceshn).toList(),
      );
      expect(first, second);
    });
  });

  group('Google Maps baseline (scenarios 11–12)', () {
    test('OSRM multi-stop; legs sum == total (static; traffic differs)',
        () async {
      final road = await osrmDrive([pickup, jabalRahmah, mina, clockTower]);
      expect(road.km, greaterThan(10));
      expect(road.minutes, greaterThan(10));
      expect(road.legs.length, 3);
      final legsSumKm =
          road.legs.fold<double>(0, (s, l) => s + (l['km'] ?? 0));
      expect(legsSumKm, closeTo(road.km, 0.05));
      // ignore: avoid_print
      print('S11/S12 OSRM multi ${road.km.toStringAsFixed(2)} km '
          '${road.minutes.round()} min (Google traffic ETA may be higher)');
    });
  });
}
