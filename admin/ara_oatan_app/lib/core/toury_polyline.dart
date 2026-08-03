import '/flutter_flow/lat_lng.dart';

/// فك ترميز Google/OSRM encoded polyline.
abstract final class TouryPolyline {
  TouryPolyline._();

  /// [precision] = 5 لـ Google/OSRM `polyline`، و6 لـ `polyline6`.
  static List<LatLng> decode(String encoded, {int precision = 5}) {
    final points = <LatLng>[];
    final factor = precision <= 5 ? 1E5 : 1E6;
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / factor, lng / factor));
    }

    return points;
  }

  static double asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
