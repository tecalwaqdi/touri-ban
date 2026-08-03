import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '/app_state.dart';
import '/backend/schema/structs/index.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_navigation.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// مسافة بالأمتار تُعتبر نفس الموقع المخصص.
const touryCustomPlaceDuplicateMeters = 80.0;

/// هل الإحداثيات قريبة جداً من وجهة موجودة في السلة؟
bool touryCustomPlaceAlreadyInCart(LatLng location, [FFAppState? state]) {
  final app = state ?? FFAppState();
  for (final item in app.cartmkss) {
    final existing = item.loceshn;
    if (existing == null) continue;
    final meters = Geolocator.distanceBetween(
      existing.latitude,
      existing.longitude,
      location.latitude,
      location.longitude,
    );
    if (meters < touryCustomPlaceDuplicateMeters) {
      return true;
    }
  }
  return false;
}

/// يضيف موقعاً مخصصاً للسلة بنفس آلية المعالم (addcart + cartmkss + الحد الأدنى للساعات).
bool touryAddCustomPlaceToCart({
  required BuildContext context,
  required String name,
  required LatLng location,
  String? address,
  bool openCheckoutSnack = true,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    TouryDialogs.showSnackBar(
      context,
      'custom_place_name_required'.tr(),
      type: TouryMessageType.warning,
    );
    return false;
  }

  if (touryCustomPlaceAlreadyInCart(location)) {
    TouryDialogs.showSnackBar(
      context,
      'custom_place_duplicate'.tr(),
      type: TouryMessageType.warning,
    );
    return false;
  }

  final app = FFAppState();
  app.addcart = app.addcart + 1;
  app.addToCartmkss(
    AmaknCostmStruct(
      naim: trimmedName,
      address: address?.trim() ?? '',
      textivill: '${app.naimdolh}- ${app.naimvillatext}',
      loceshn: location,
      dolh: app.dolh,
    ),
  );
  app.dataSchedule = getCurrentTimestamp;
  app.fulltextSchedule = 'instant_booking'.tr();
  if (app.naimvillatext.trim().isNotEmpty) {
    app.textallAlmdn = '${app.textallAlmdn} ${app.naimvillatext}'.trim();
  }
  app.Minimumhours = touryMinimumBookingHours(
    landmarkCount: app.cartmkss.length,
    driverGuide: app.DriverGuideState,
  );
  tourySyncBookingFlags();
  app.update(() {});

  if (!openCheckoutSnack || !context.mounted) {
    return true;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('custom_place_added'.tr(namedArgs: {'name': trimmedName})),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'view_my_trip'.tr(),
        onPressed: () => touryOpenCheckout(context),
      ),
    ),
  );
  return true;
}
