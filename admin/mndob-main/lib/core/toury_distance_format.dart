import 'package:intl/intl.dart';

/// OSRM (and similar) route APIs return distance in meters.
double touryMetersToKm(num meters) {
  final m = meters.toDouble();
  if (!m.isFinite || m <= 0) return 0;
  return m / 1000.0;
}

/// Normalize a distance that may already be km, or accidentally left in meters.
///
/// Values at or above [metersThreshold] are treated as meters (e.g. 21564 → 21.564 km).
/// Typical tourist trips stay under this threshold when correctly stored as km.
double touryAsDistanceKm(
  num value, {
  bool fromMeters = false,
  double metersThreshold = 3000,
}) {
  final v = value.toDouble();
  if (!v.isFinite || v <= 0) return 0;
  if (fromMeters || v >= metersThreshold) return v / 1000.0;
  return v;
}

/// Formats a trip distance for UI display as kilometers (e.g. `21.6 km`).
String touryFormatDistanceKm(
  num value, {
  String? locale,
  bool fromMeters = false,
  int fractionDigits = 1,
}) {
  final km = touryAsDistanceKm(value, fromMeters: fromMeters);
  if (km <= 0) return '';
  final format = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = fractionDigits;
  return '${format.format(km)} km';
}
