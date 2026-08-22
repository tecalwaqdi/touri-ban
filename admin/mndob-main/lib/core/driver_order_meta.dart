import '/backend/schema/order_record.dart';
import '/core/driver_trip_constants.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Optional extra fields on `order` documents (read safely).
extension DriverOrderMeta on OrderRecord {
  /// Firestore may store text fields as String or num (payment/API paths).
  static String _asTrimmedString(dynamic value) {
    final text = castToType<String>(value)?.trim() ?? '';
    return text;
  }

  String get cartext => _asTrimmedString(snapshotData['cartext']);

  bool get driverGuide => snapshotData['DriverGuide'] == true;

  String get tripTypeRaw => _asTrimmedString(snapshotData['trip_type']);

  /// Piece count (int) from payment-api / ngenius, or label string from app booking.
  String get luggageEstimate =>
      _asTrimmedString(snapshotData['luggage_estimate']);

  DateTime? get driverArrivedAt =>
      castToType<DateTime>(snapshotData['driverArrivedAt']);

  DateTime? get waitingStartedAt =>
      castToType<DateTime>(snapshotData['waitingStartedAt']);

  double get waitingCharges =>
      castToType<double>(snapshotData['waitingCharges']) ?? 0.0;

  int get etaSeconds =>
      castToType<int>(snapshotData['etaSeconds']) ?? 0;

  double get distanceRemainingMeters =>
      castToType<double>(snapshotData['distanceRemainingMeters']) ?? 0.0;

  /// Planned trip length from booking (meters), when available.
  double get plannedDistanceMeters =>
      castToType<double>(snapshotData['plannedDistanceMeters']) ?? 0.0;

  int get plannedDurationSeconds =>
      castToType<int>(snapshotData['plannedDurationSeconds']) ?? 0;

  DateTime? get destinationUpdatedAt =>
      castToType<DateTime>(snapshotData['destinationUpdatedAt']);

  /// English phrase key for EasyLocalization (never Arabic UI literal).
  String tripTypeLabelKey() {
    final raw = tripTypeRaw.toLowerCase();
    if (raw.contains('round') || raw.contains('عودة')) {
      return 'Round trip';
    }
    if (raw.contains('one') || raw.contains('ذهاب')) {
      return 'One way';
    }
    if (driverGuide) return 'Guided tour';
    if (addCartNumer > 1) return 'Multi-stop';
    return 'One way';
  }

  /// Prefer [tripTypeLabelKey] + driverTr in UI.
  String tripTypeLabel() => tripTypeLabelKey();

  String luggageLabelKey() {
    final raw = luggageEstimate.toLowerCase();
    if (raw.isEmpty) return '—';

    // Numeric piece counts from payment/API order builders.
    final pieces = int.tryParse(raw);
    if (pieces != null) {
      if (pieces <= 0) return 'No luggage';
      if (pieces == 1) return 'Small luggage';
      if (pieces == 2) return 'Medium luggage';
      return 'Large luggage';
    }

    if (raw.contains('none') || raw.contains('لا')) return 'No luggage';
    if (raw.contains('small') || raw.contains('صغير')) return 'Small luggage';
    if (raw.contains('medium') || raw.contains('متوسط')) {
      return 'Medium luggage';
    }
    if (raw.contains('large') || raw.contains('كبير')) return 'Large luggage';
    return luggageEstimate;
  }

  String luggageLabel() => luggageLabelKey();

  String pickupLabel() {
    if (loceshStreng.isNotEmpty) return loceshStreng;
    if (lokeshn != null) {
      return '${lokeshn!.latitude.toStringAsFixed(5)}, ${lokeshn!.longitude.toStringAsFixed(5)}';
    }
    return '—';
  }

  String destinationLabel() {
    if (listAmakn.isNotEmpty) {
      final last = listAmakn.last;
      if (last.address.isNotEmpty) return last.address;
      if (last.naim.isNotEmpty) return last.naim;
    }
    if (destinationLatitude != 0 || destinationLongitude != 0) {
      return '$destinationLatitude, $destinationLongitude';
    }
    return '—';
  }

  /// Customer pickup location (fixed at order creation).
  LatLng? get customerPickup => lokeshn;

  /// Live driver position (updated during tracking in mapuser).
  LatLng? get driverLivePosition => mapuser;

  /// Trip destination from places list or saved coordinates.
  LatLng? get tripDestination {
    if (listAmakn.isNotEmpty) {
      final last = listAmakn.last;
      if (last.hasLoceshn()) return last.loceshn;
    }
    if (destinationLatitude != 0 || destinationLongitude != 0) {
      return LatLng(destinationLatitude, destinationLongitude);
    }
    return null;
  }

  /// Route points: driver → pickup → stops → final destination.
  List<LatLng> routeWaypoints({LatLng? driverOverride}) {
    final driver = driverOverride ??
        (DriverTripHalh.isActiveTrip(halhText) ? driverLivePosition : null);
    final pickup = customerPickup;
    final stops = <LatLng>[];
    for (final stop in listAmakn) {
      final loc = stop.hasLoceshn() ? stop.loceshn : null;
      if (loc == null) continue;
      if (pickup != null &&
          (loc.latitude - pickup.latitude).abs() < 1e-6 &&
          (loc.longitude - pickup.longitude).abs() < 1e-6) {
        continue;
      }
      if (stops.any((s) =>
          (s.latitude - loc.latitude).abs() < 1e-6 &&
          (s.longitude - loc.longitude).abs() < 1e-6)) {
        continue;
      }
      stops.add(loc);
    }
    final dest = tripDestination;
    final points = <LatLng>[
      if (driver != null) driver,
      if (pickup != null && pickup != driver) pickup,
      ...stops.where((p) => p != pickup && p != driver),
      if (dest != null &&
          dest != pickup &&
          dest != driver &&
          !stops.any((s) =>
              (s.latitude - dest.latitude).abs() < 1e-6 &&
              (s.longitude - dest.longitude).abs() < 1e-6))
        dest,
    ];
    return points;
  }

  String destinationsFingerprint() {
    final parts = <String>[
      destinationLatitude.toString(),
      destinationLongitude.toString(),
      listAmakn.length.toString(),
      ...listAmakn.map((e) => '${e.naim}|${e.address}|${e.loceshn}'),
    ];
    return parts.join('::');
  }
}
