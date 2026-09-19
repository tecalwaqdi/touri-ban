import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Canvas-drawn map markers — no image assets, no extra package.
///
/// The car is painted pointing **north** so `Marker.rotation` can be fed the
/// raw compass bearing directly.
abstract final class TouryMapMarkers {
  static const double _canvasSize = 108;

  static final Map<String, gmaps.BitmapDescriptor> _cache =
      <String, gmaps.BitmapDescriptor>{};

  /// Clears the descriptor cache (theme change / tests).
  @visibleForTesting
  static void debugClearCache() => _cache.clear();

  @visibleForTesting
  static int get debugCacheSize => _cache.length;

  /// Small stylized car seen from above, ready to be rotated by heading.
  static Future<gmaps.BitmapDescriptor> car({
    required Color body,
    required Color glass,
    double pixelRatio = 3.0,
  }) {
    final key = 'car_${body.toARGB32()}_${glass.toARGB32()}_'
        '${pixelRatio.toStringAsFixed(2)}';
    return _cached(key, () => _paint(pixelRatio, (canvas) {
          _drawCar(canvas, body: body, glass: glass);
        }));
  }

  /// Filled circular pin with a glyph — used for pickup / stop / destination.
  static Future<gmaps.BitmapDescriptor> dot({
    required Color color,
    required IconData icon,
    double pixelRatio = 3.0,
  }) {
    final key = 'dot_${color.toARGB32()}_${icon.codePoint}_'
        '${pixelRatio.toStringAsFixed(2)}';
    return _cached(key, () => _paint(pixelRatio, (canvas) {
          _drawDot(canvas, color: color, icon: icon);
        }));
  }

  static Future<gmaps.BitmapDescriptor> _cached(
    String key,
    Future<gmaps.BitmapDescriptor> Function() build,
  ) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    final built = await build();
    _cache[key] = built;
    return built;
  }

  static Future<gmaps.BitmapDescriptor> _paint(
    double pixelRatio,
    void Function(Canvas canvas) draw,
  ) async {
    final scale = pixelRatio.clamp(1.0, 4.0);
    final side = (_canvasSize * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    draw(canvas);

    final image = await recorder.endRecording().toImage(side, side);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        return gmaps.BitmapDescriptor.defaultMarker;
      }
      return gmaps.BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
        width: _canvasSize,
        height: _canvasSize,
      );
    } finally {
      image.dispose();
    }
  }

  /// Live-tracking accent (blue) — independent of brand teal/green.
  static const Color trackingAccent = Color(0xFF2563EB);

  static void _drawCar(
    Canvas canvas, {
    required Color body,
    required Color glass,
  }) {
    const center = Offset(_canvasSize / 2, _canvasSize / 2);
    // Slightly taller sedan silhouette — readable at mid zoom, not oversized.
    const carWidth = 36.0;
    const carHeight = 72.0;

    final rect = Rect.fromCenter(
      center: center,
      width: carWidth,
      height: carHeight,
    );

    // Soft ground shadow for satellite / dark tiles.
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 5),
        width: carWidth + 18,
        height: carHeight + 10,
      ),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Blue live halo (not brand green).
    canvas.drawCircle(
      center,
      carWidth * 1.05,
      Paint()..color = trackingAccent.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      carWidth * 0.78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = trackingAccent.withValues(alpha: 0.35),
    );

    // Side mirrors (before body so outline covers joints).
    final mirrorPaint = Paint()..color = Color.lerp(body, Colors.black, 0.15)!;
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(dx * (carWidth * 0.58), -carHeight * 0.12),
            width: 7,
            height: 11,
          ),
          const Radius.circular(3),
        ),
        mirrorPaint,
      );
    }

    // Wheel arches (top-down dark tires).
    final tire = Paint()..color = const Color(0xFF0F172A);
    for (final dy in const [-0.28, 0.30]) {
      for (final dx in const [-1.0, 1.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(dx * (carWidth * 0.52), carHeight * dy),
              width: 7,
              height: 14,
            ),
            const Radius.circular(3),
          ),
          tire,
        );
      }
    }

    final bodyRRect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(11),
      bottomRight: const Radius.circular(11),
    );

    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            Color.lerp(body, Colors.white, 0.28) ?? body,
            body,
            Color.lerp(body, Colors.black, 0.12) ?? body,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // White outline for contrast on any basemap.
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..color = Colors.white,
    );

    // Thin blue accent edge (modern tracking look).
    canvas.drawRRect(
      bodyRRect.deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = trackingAccent.withValues(alpha: 0.55),
    );

    // Windshield (front / north) + rear window.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, -carHeight * 0.24),
          width: carWidth - 10,
          height: carHeight * 0.22,
        ),
        const Radius.circular(7),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          center.translate(0, -carHeight * 0.34),
          center.translate(0, -carHeight * 0.12),
          [
            glass.withValues(alpha: 0.95),
            Color.lerp(glass, trackingAccent, 0.25) ?? glass,
          ],
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, carHeight * 0.26),
          width: carWidth - 12,
          height: carHeight * 0.16,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = glass.withValues(alpha: 0.8),
    );

    // Roof panel between windows.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, carHeight * 0.02),
          width: carWidth - 14,
          height: carHeight * 0.16,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = Color.lerp(body, Colors.white, 0.22) ?? body,
    );

    // Direction chevron on roof (north) — clarifies heading at a glance.
    final chevron = Path()
      ..moveTo(center.dx, center.dy - carHeight * 0.02)
      ..lineTo(center.dx - 6, center.dy + 8)
      ..lineTo(center.dx + 6, center.dy + 8)
      ..close();
    canvas.drawPath(
      chevron,
      Paint()..color = trackingAccent.withValues(alpha: 0.85),
    );

    // Headlights.
    final headlight = Paint()..color = const Color(0xFFFFF8E7);
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(
              dx * (carWidth * 0.26),
              -carHeight * 0.46,
            ),
            width: 9,
            height: 5,
          ),
          const Radius.circular(2.5),
        ),
        headlight,
      );
    }

    // Taillights.
    final taillight = Paint()..color = const Color(0xFFF87171);
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(
              dx * (carWidth * 0.26),
              carHeight * 0.46,
            ),
            width: 8,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        taillight,
      );
    }
  }

  static void _drawDot(
    Canvas canvas, {
    required Color color,
    required IconData icon,
  }) {
    const center = Offset(_canvasSize / 2, _canvasSize / 2);
    const radius = 26.0;

    canvas.drawCircle(
      center.translate(0, 3),
      radius,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius - 4, Paint()..color = color);

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 26),
    )
      ..pushStyle(
        ui.TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontFamily: icon.fontPackage == null
              ? icon.fontFamily
              : 'packages/${icon.fontPackage}/${icon.fontFamily}',
        ),
      )
      ..addText(String.fromCharCode(icon.codePoint));

    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: _canvasSize));
    canvas.drawParagraph(
      paragraph,
      Offset(0, center.dy - paragraph.height / 2),
    );
  }
}

/// Shortest-arc interpolation between two compass bearings (degrees).
///
/// Prevents the car spinning 350° backwards when heading wraps 359° → 1°.
double touryLerpHeading(double from, double to, double t) {
  final normalizedFrom = touryNormalizeHeading(from);
  final normalizedTo = touryNormalizeHeading(to);
  var delta = normalizedTo - normalizedFrom;
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return touryNormalizeHeading(normalizedFrom + delta * t);
}

double touryNormalizeHeading(double degrees) {
  if (!degrees.isFinite) return 0;
  final wrapped = degrees % 360;
  return wrapped < 0 ? wrapped + 360 : wrapped;
}

/// Initial bearing from [fromLat]/[fromLng] to [toLat]/[toLng] in degrees.
double touryBearingDegrees(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng,
) {
  final lat1 = fromLat * math.pi / 180;
  final lat2 = toLat * math.pi / 180;
  final dLng = (toLng - fromLng) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return touryNormalizeHeading(math.atan2(y, x) * 180 / math.pi);
}