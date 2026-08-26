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

  static void _drawCar(
    Canvas canvas, {
    required Color body,
    required Color glass,
  }) {
    const center = Offset(_canvasSize / 2, _canvasSize / 2);
    const carWidth = 38.0;
    const carHeight = 66.0;

    final rect = Rect.fromCenter(
      center: center,
      width: carWidth,
      height: carHeight,
    );

    // Ground shadow keeps the car readable over satellite / dark tiles.
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 4),
        width: carWidth + 16,
        height: carHeight + 12,
      ),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Halo ring — signals "live" without animating the bitmap.
    canvas.drawCircle(
      center,
      carWidth * 0.92,
      Paint()..color = body.withValues(alpha: 0.16),
    );

    final bodyRRect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );

    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            Color.lerp(body, Colors.white, 0.22) ?? body,
            body,
          ],
        ),
    );

    // Crisp white outline so the car pops on any basemap.
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );

    // Windshield (front) + rear window.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, -carHeight * 0.22),
          width: carWidth - 11,
          height: carHeight * 0.24,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, carHeight * 0.24),
          width: carWidth - 13,
          height: carHeight * 0.17,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = glass.withValues(alpha: 0.75),
    );

    // Roof strip between the two windows.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, carHeight * 0.01),
          width: carWidth - 15,
          height: carHeight * 0.14,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Color.lerp(body, Colors.white, 0.30) ?? body,
    );

    // Headlights.
    final headlight = Paint()..color = const Color(0xFFFFF6D6);
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(dx * (carWidth * 0.28),
                -carHeight * 0.44),
            width: 8,
            height: 5,
          ),
          const Radius.circular(2.5),
        ),
        headlight,
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