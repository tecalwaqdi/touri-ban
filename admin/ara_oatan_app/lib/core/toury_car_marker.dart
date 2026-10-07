import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Canvas-drawn map markers — no image assets, no extra package.
///
/// The car is a top-down sedan silhouette pointing **north** so
/// `Marker.rotation` can be fed the raw compass bearing directly.
abstract final class TouryMapMarkers {
  static const double _canvasSize = 108;

  static final Map<String, gmaps.BitmapDescriptor> _cache =
      <String, gmaps.BitmapDescriptor>{};

  /// Clears the descriptor cache (theme change / tests).
  @visibleForTesting
  static void debugClearCache() => _cache.clear();

  @visibleForTesting
  static int get debugCacheSize => _cache.length;

  /// Top-down sedan for live tracking — rotated by compass heading.
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
  static const Color trackingAccent = Color(0xFF4285F4);

  static void _drawCar(
    Canvas canvas, {
    required Color body,
    required Color glass,
  }) {
    const center = Offset(_canvasSize / 2, _canvasSize / 2);
    // Top-down sedan proportions (north = hood) — readable like Maps tracking.
    const carWidth = 40.0;
    const carHeight = 78.0;
    final bodyColor = Color.lerp(body, const Color(0xFFF8FAFC), 0.55) ?? body;
    final darkBody = Color.lerp(bodyColor, Colors.black, 0.22) ?? bodyColor;
    final lightBody = Color.lerp(bodyColor, Colors.white, 0.35) ?? bodyColor;

    // Soft ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(1.5, 6),
        width: carWidth + 16,
        height: carHeight + 8,
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Subtle live halo (does not obscure the car shape).
    canvas.drawCircle(
      center,
      carWidth * 0.95,
      Paint()..color = trackingAccent.withValues(alpha: 0.12),
    );

    // --- Tire wells (outside body edges) ---
    final tirePaint = Paint()..color = const Color(0xFF0B1220);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);
    for (final dy in const [-0.30, 0.32]) {
      for (final dx in const [-1.0, 1.0]) {
        final tireCenter =
            center.translate(dx * (carWidth * 0.54), carHeight * dy);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: tireCenter, width: 8.5, height: 16),
            const Radius.circular(2.5),
          ),
          tirePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: tireCenter, width: 3.2, height: 8),
            const Radius.circular(1.2),
          ),
          rimPaint,
        );
      }
    }

    // --- Side mirrors ---
    final mirrorPaint = Paint()..color = darkBody;
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(dx * (carWidth * 0.58), -carHeight * 0.08),
            width: 7.5,
            height: 12,
          ),
          const Radius.circular(2.5),
        ),
        mirrorPaint,
      );
    }

    // --- Body path: tapered hood, wider cabin, rounded trunk (north-up) ---
    final bodyPath = Path()
      ..moveTo(center.dx - carWidth * 0.28, center.dy - carHeight * 0.48) // hood L
      ..quadraticBezierTo(
        center.dx,
        center.dy - carHeight * 0.52,
        center.dx + carWidth * 0.28,
        center.dy - carHeight * 0.48,
      )
      ..lineTo(center.dx + carWidth * 0.46, center.dy - carHeight * 0.22)
      ..lineTo(center.dx + carWidth * 0.48, center.dy + carHeight * 0.18)
      ..quadraticBezierTo(
        center.dx + carWidth * 0.46,
        center.dy + carHeight * 0.48,
        center.dx,
        center.dy + carHeight * 0.49,
      )
      ..quadraticBezierTo(
        center.dx - carWidth * 0.46,
        center.dy + carHeight * 0.48,
        center.dx - carWidth * 0.48,
        center.dy + carHeight * 0.18,
      )
      ..lineTo(center.dx - carWidth * 0.46, center.dy - carHeight * 0.22)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = ui.Gradient.linear(
          center.translate(-carWidth * 0.35, -carHeight * 0.2),
          center.translate(carWidth * 0.4, carHeight * 0.25),
          [lightBody, bodyColor, darkBody],
          const [0.0, 0.45, 1.0],
        ),
    );

    // Soft slate outline — Google Maps–like edge on light tiles.
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF64748B).withValues(alpha: 0.65),
    );

    // Hood panel crease.
    canvas.drawLine(
      center.translate(0, -carHeight * 0.46),
      center.translate(0, -carHeight * 0.28),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Windshield (trapezoid, front / north).
    final windshield = Path()
      ..moveTo(center.dx - carWidth * 0.28, center.dy - carHeight * 0.10)
      ..lineTo(center.dx + carWidth * 0.28, center.dy - carHeight * 0.10)
      ..lineTo(center.dx + carWidth * 0.34, center.dy - carHeight * 0.26)
      ..lineTo(center.dx - carWidth * 0.34, center.dy - carHeight * 0.26)
      ..close();
    canvas.drawPath(
      windshield,
      Paint()
        ..shader = ui.Gradient.linear(
          center.translate(0, -carHeight * 0.28),
          center.translate(0, -carHeight * 0.08),
          [
            const Color(0xFF93C5FD).withValues(alpha: 0.95),
            Color.lerp(glass, const Color(0xFF1E3A8A), 0.35) ?? glass,
          ],
        ),
    );
    canvas.drawPath(
      windshield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Roof.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, carHeight * 0.06),
          width: carWidth * 0.62,
          height: carHeight * 0.18,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = Color.lerp(bodyColor, Colors.white, 0.18) ?? bodyColor,
    );

    // Rear window.
    final rearGlass = Path()
      ..moveTo(center.dx - carWidth * 0.30, center.dy + carHeight * 0.18)
      ..lineTo(center.dx + carWidth * 0.30, center.dy + carHeight * 0.18)
      ..lineTo(center.dx + carWidth * 0.26, center.dy + carHeight * 0.32)
      ..lineTo(center.dx - carWidth * 0.26, center.dy + carHeight * 0.32)
      ..close();
    canvas.drawPath(
      rearGlass,
      Paint()..color = glass.withValues(alpha: 0.82),
    );

    // Door seam lines (subtle realism).
    final seam = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1.1;
    canvas.drawLine(
      center.translate(-carWidth * 0.42, -carHeight * 0.02),
      center.translate(-carWidth * 0.42, carHeight * 0.16),
      seam,
    );
    canvas.drawLine(
      center.translate(carWidth * 0.42, -carHeight * 0.02),
      center.translate(carWidth * 0.42, carHeight * 0.16),
      seam,
    );

    // Headlights (warm white).
    final headlight = Paint()..color = const Color(0xFFFFFBEB);
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(
              dx * (carWidth * 0.24),
              -carHeight * 0.455,
            ),
            width: 10,
            height: 5.5,
          ),
          const Radius.circular(2.5),
        ),
        headlight,
      );
    }

    // Taillights (red).
    final taillight = Paint()..color = const Color(0xFFEF4444);
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(
              dx * (carWidth * 0.24),
              carHeight * 0.455,
            ),
            width: 9,
            height: 4.5,
          ),
          const Radius.circular(2),
        ),
        taillight,
      );
    }

    // Front grille hint.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, -carHeight * 0.485),
          width: carWidth * 0.22,
          height: 3.2,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF334155),
    );
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