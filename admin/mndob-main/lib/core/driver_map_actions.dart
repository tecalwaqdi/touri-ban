import 'package:flutter/material.dart';

import '/core/driver_navigation_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// إجراءات الخريطة داخل التطبيق + فتح Google Maps للتوجيه.
abstract final class DriverMapActions {
  DriverMapActions._();

  static void showEmbeddedMapHint(
    BuildContext context, {
    String label = 'الموقع معروض على الخريطة في أعلى الشاشة',
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          label,
          style: const TextStyle(fontFamily: 'cairo'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<void> navigateWithGoogleMaps({
    required LatLng destination,
    LatLng? origin,
    List<LatLng> waypoints = const [],
  }) =>
      DriverNavigationService.openGoogleMapsNavigation(
        destination: destination,
        origin: origin,
        waypoints: waypoints,
      );

  static Future<void> focusLocationHint(
    BuildContext context,
    LatLng? location, {
    String? title,
    bool openExternal = false,
  }) async {
    if (location == null) {
      showEmbeddedMapHint(
        context,
        label: 'لا يتوفر موقع لهذه النقطة',
      );
      return;
    }
    if (openExternal) {
      await DriverNavigationService.openGoogleMapsMarker(
        location,
        title: title,
      );
      return;
    }
    showEmbeddedMapHint(
      context,
      label: title ?? 'تم تحديد الموقع على الخريطة أعلاه',
    );
  }
}
