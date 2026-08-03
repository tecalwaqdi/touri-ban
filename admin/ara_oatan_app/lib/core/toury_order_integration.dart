import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/toury_order_country.dart';
import '/app_state.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/lat_lng.dart';

/// حقول تكامل الطلب بين تطبيق العميل والمندوب والإدارة.
abstract final class TouryOrderIntegration {
  TouryOrderIntegration._();

  /// نص ثابت لـ halh_text — المندوب يبحث عنه أيضاً عبر halh_order.
  static const pendingStatusText = 'بإنتظار قبول المندوب';

  static String resolveTripType(FFAppState app) {
    if (app.DriverGuideState) return 'guide';
    if (app.addcart > 1) return 'multi_stop';
    if (app.typeHgz == 1) return 'round_trip';
    return 'one_way';
  }

  static List<Map<String, double>> _plannedWaypoints(FFAppState app) {
    final points = <LatLng>[
      if (app.mkanuserorder != null) app.mkanuserorder!,
      ...app.cartmkss.map((e) => e.loceshn).whereType<LatLng>(),
    ];
    final unique = <LatLng>[];
    for (final point in points) {
      if (unique.isEmpty || unique.last != point) unique.add(point);
    }
    return unique
        .map((p) => {
              'lat': p.latitude,
              'lng': p.longitude,
            })
        .toList(growable: false);
  }

  /// JSON-safe booking details accepted by server-side booking functions.
  static Map<String, dynamic> cloudBookingPayload() {
    final app = FFAppState();
    final pickup = app.mkanuserorder;
    return <String, dynamic>{
      if (pickup != null) ...{
        'pickupLat': pickup.latitude,
        'pickupLng': pickup.longitude,
      },
      'cityPath': app.mdenh?.path,
      'villagePath': app.villnow?.path,
      'cityName': app.villtextnow,
      'carName': app.tebycar,
      'schedule': app.dataSchedule?.toIso8601String(),
      'scheduleLabel': app.fulltextSchedule,
      'driverGuide': app.DriverGuideState,
      'tripType': resolveTripType(app),
      'luggageEstimate': app.luggageEstimate,
      'routeProvider': app.osrmTotalDistance > 0 ? 'osrm' : 'waypoints',
      'plannedDistanceMeters': app.osrmTotalDistance * 1000,
      'plannedDurationSeconds': (app.osrmTotalTime * 60).round(),
      'plannedWaypoints': _plannedWaypoints(app),
      'stops': app.cartmkss
          .map((stop) => {
                'name': stop.naim,
                'address': stop.address,
                'city': stop.textivill,
                if (stop.loceshn != null) ...{
                  'lat': stop.loceshn!.latitude,
                  'lng': stop.loceshn!.longitude,
                },
                if (stop.revmkan != null) 'placePath': stop.revmkan!.path,
              })
          .toList(growable: false),
    }..removeWhere((_, value) => value == null);
  }

  static Map<String, dynamic> firestoreExtras() {
    final app = FFAppState();
    final pickup = app.mkanuserorder;
    LatLng? destination;
    if (app.cartmkss.isNotEmpty) {
      destination = app.cartmkss.last.loceshn;
    }
    final planned = _plannedWaypoints(app);

    return {
      'trip_type': resolveTripType(app),
      'luggage_estimate': app.luggageEstimate,
      if (pickup != null) ...{
        'originLatitude': pickup.latitude,
        'originLongitude': pickup.longitude,
      },
      if (destination != null) ...{
        'destinationLatitude': destination.latitude,
        'destinationLongitude': destination.longitude,
      },
      if (planned.length >= 2) ...{
        'plannedWaypoints': planned,
        'routeProvider': app.osrmTotalDistance > 0 ? 'osrm' : 'waypoints',
        'routeVersion': 1,
          'routeCalculatedAt': FieldValue.serverTimestamp(),
        if (app.osrmTotalDistance > 0)
          'plannedDistanceMeters': app.osrmTotalDistance * 1000,
        if (app.osrmTotalTime > 0)
          'plannedDurationSeconds': (app.osrmTotalTime * 60).round(),
      },
      ...touryOrderCountryExtras(),
    }.withoutNulls;
  }
}
