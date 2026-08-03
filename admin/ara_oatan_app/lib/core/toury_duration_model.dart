/// Booking vs driving duration helpers (minutes as source of truth for display).
///
/// Billable hours in FFAppState (`saatcar`, `totalsaat`, `addhors`) remain
/// integer **hours** for pricing / CF compatibility. Convert at the edges.
abstract final class TouryDurationModel {
  /// Base booking hours from car type (`agl_saat` → `saatcar`).
  static int baseBookingHours(int saatcar) => saatcar.clamp(0, 24 * 30);

  /// Extra hours added by the customer (`addhors`).
  static int extraBookingHours(int addhors) => addhors.clamp(0, 24 * 30);

  /// Total reserved booking hours.
  static int totalBookingHours({
    required int saatcar,
    required int addhors,
  }) =>
      (baseBookingHours(saatcar) + extraBookingHours(addhors)).clamp(0, 24 * 30);

  static int hoursToMinutes(int hours) => hours.clamp(0, 24 * 30) * 60;

  /// Format minutes for UI: "20 min", "1 h 30 min", "3 h".
  static String formatMinutes(int totalMinutes, {required String localeTag}) {
    final m = totalMinutes.clamp(0, 24 * 60 * 30);
    if (m < 60) {
      return '$m min';
    }
    final h = m ~/ 60;
    final rem = m % 60;
    if (rem == 0) return '$h h';
    return '$h h $rem min';
  }

  /// Driving ETA minutes from OSRM (preferred) or preview hours.
  static int? drivingMinutes({
    double? osrmTimeMinutes,
    double? previewTimeHours,
  }) {
    if (osrmTimeMinutes != null && osrmTimeMinutes > 0) {
      return osrmTimeMinutes.round().clamp(1, 24 * 60 * 7);
    }
    if (previewTimeHours != null && previewTimeHours > 0) {
      return (previewTimeHours * 60).round().clamp(1, 24 * 60 * 7);
    }
    return null;
  }

  /// Tour products: drive time shorter than reserved booking is normal — not a blocker.
  static bool isDriveShorterThanBookingNormal({
    required int bookingHours,
    required int? driveMinutes,
  }) {
    if (driveMinutes == null || bookingHours < 1) return false;
    return driveMinutes < hoursToMinutes(bookingHours);
  }
}
