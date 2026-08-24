import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/backend/schema/order_record.dart';
import '/core/driver_design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';

/// خلية في خريطة الحرارة — تجميع طلبات متاحة قريبة من بعضها.
class DriverHeatmapCell {
  const DriverHeatmapCell({
    required this.center,
    required this.count,
  });

  final LatLng center;
  final int count;
}

/// تجميع الطلبات المتاحة وتحويلها لدوائر حرارة على الخريطة.
abstract final class DriverOrderHeatmapService {
  DriverOrderHeatmapService._();

  static List<DriverHeatmapCell> cluster(
    List<OrderRecord> orders, {
    int precision = 2,
  }) {
    final buckets = <String, ({double latSum, double lngSum, int count})>{};

    for (final order in orders) {
      final point = order.hasMapuser()
          ? order.mapuser
          : order.hasLokeshn()
              ? order.lokeshn
              : null;
      if (point == null) continue;

      final key =
          '${point.latitude.toStringAsFixed(precision)},${point.longitude.toStringAsFixed(precision)}';
      final existing = buckets[key];
      if (existing == null) {
        buckets[key] = (
          latSum: point.latitude,
          lngSum: point.longitude,
          count: 1,
        );
      } else {
        buckets[key] = (
          latSum: existing.latSum + point.latitude,
          lngSum: existing.lngSum + point.longitude,
          count: existing.count + 1,
        );
      }
    }

    return buckets.entries.map((entry) {
      final bucket = entry.value;
      return DriverHeatmapCell(
        center: LatLng(
          bucket.latSum / bucket.count,
          bucket.lngSum / bucket.count,
        ),
        count: bucket.count,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  static Set<gmaps.Circle> toCircles(List<DriverHeatmapCell> cells) {
    return cells.map((cell) {
      final intensity = (0.12 + cell.count * 0.06).clamp(0.12, 0.45);
      return gmaps.Circle(
        circleId: gmaps.CircleId(
          'heat_${cell.center.latitude.toStringAsFixed(4)}_${cell.center.longitude.toStringAsFixed(4)}',
        ),
        center: cell.center.toGoogleMaps(),
        radius: 280 + cell.count * 120.0,
        fillColor: DriverBrand.teal.withValues(alpha: intensity),
        strokeColor: DriverBrand.tealDark.withValues(alpha: 0.55),
        strokeWidth: 1,
      );
    }).toSet();
  }
}
