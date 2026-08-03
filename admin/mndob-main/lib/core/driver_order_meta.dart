import '/backend/schema/order_record.dart';
import '/core/driver_trip_constants.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// حقول إضافية على مستند `order` (اختيارية — تُقرأ بأمان).
extension DriverOrderMeta on OrderRecord {
  String get cartext =>
      (snapshotData['cartext'] as String?)?.trim() ?? '';

  bool get driverGuide => snapshotData['DriverGuide'] == true;

  String get tripTypeRaw =>
      (snapshotData['trip_type'] as String?)?.trim() ?? '';

  String get luggageEstimate =>
      (snapshotData['luggage_estimate'] as String?)?.trim() ?? '';

  DateTime? get driverArrivedAt =>
      snapshotData['driverArrivedAt'] as DateTime?;

  DateTime? get waitingStartedAt =>
      snapshotData['waitingStartedAt'] as DateTime?;

  double get waitingCharges =>
      castToType<double>(snapshotData['waitingCharges']) ?? 0.0;

  int get etaSeconds =>
      castToType<int>(snapshotData['etaSeconds']) ?? 0;

  double get distanceRemainingMeters =>
      castToType<double>(snapshotData['distanceRemainingMeters']) ?? 0.0;

  DateTime? get destinationUpdatedAt =>
      snapshotData['destinationUpdatedAt'] as DateTime?;

  String tripTypeLabel() {
    final raw = tripTypeRaw.toLowerCase();
    if (raw.contains('round') || raw.contains('عودة')) {
      return 'ذهاب وعودة';
    }
    if (raw.contains('one') || raw.contains('ذهاب')) {
      return 'ذهاب فقط';
    }
    if (driverGuide) return 'جولة إرشادية';
    if (addCartNumer > 1) return 'متعدد الوجهات';
    return 'ذهاب فقط';
  }

  String luggageLabel() {
    final raw = luggageEstimate.toLowerCase();
    if (raw.isEmpty) return '—';
    if (raw.contains('none') || raw.contains('لا')) return 'بدون أمتعة';
    if (raw.contains('small') || raw.contains('صغير')) return 'أمتعة صغيرة';
    if (raw.contains('medium') || raw.contains('متوسط')) return 'أمتعة متوسطة';
    if (raw.contains('large') || raw.contains('كبير')) return 'أمتعة كبيرة';
    return luggageEstimate;
  }

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

  /// موقع العميل للالتقاط (ثابت عند إنشاء الطلب).
  LatLng? get customerPickup => lokeshn;

  /// موقع المندوب الحي (يُحدَّث أثناء التتبع في mapuser).
  LatLng? get driverLivePosition => mapuser;

  /// وجهة الرحلة من قائمة الأماكن أو الإحداثيات المحفوظة.
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

  /// نقاط المسار: مندوب → التقاط → كل المحطات بالترتيب → الوجهة الأخيرة.
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
