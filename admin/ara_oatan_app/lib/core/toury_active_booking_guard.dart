import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/core/toury_active_booking.dart';
import '/core/toury_dialogs.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/order/tfasel_order/tfasel_order_widget.dart';

/// Shows snack + optional deep-link to the existing order. Returns true if blocked.
Future<bool> touryBlockIfActiveBooking(BuildContext context) async {
  final active = await touryFindActiveBookingForCurrentUser();
  if (active == null) return false;
  if (!context.mounted) return true;
  TouryDialogs.showSnackBar(
    context,
    'booking_active_exists'.tr(),
    type: TouryMessageType.warning,
  );
  final order = active.order;
  if (order != null && context.mounted) {
    context.pushNamed(
      TfaselOrderWidget.routeName,
      queryParameters: {
        'idorder': serializeParam(order, ParamType.Document),
      }.withoutNulls,
      extra: <String, dynamic>{
        'idorder': order,
      },
    );
  }
  return true;
}
