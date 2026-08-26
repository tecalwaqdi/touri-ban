import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/core/toury_active_booking.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_dialogs.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/order/tfasel_order/tfasel_order_widget.dart';

class TouryActiveBookingGateResult {
  const TouryActiveBookingGateResult({
    required this.blocked,
    this.active,
    this.sameOrderResume = false,
  });

  final bool blocked;
  final TouryActiveBookingInfo? active;
  final bool sameOrderResume;
}

/// Pure same-order check — active lock is the current payment/booking flow.
@visibleForTesting
bool touryIsSameActiveBookingFlow({
  required String activeOrderId,
  String? currentOrderId,
  String pendingPaymentOrderId = '',
  String paymentOrderId = '',
}) {
  final id = activeOrderId.trim();
  if (id.isEmpty) return false;
  final allowIds = <String>{
    if ((currentOrderId ?? '').trim().isNotEmpty) currentOrderId!.trim(),
    if (pendingPaymentOrderId.trim().isNotEmpty) pendingPaymentOrderId.trim(),
    if (paymentOrderId.trim().isNotEmpty) paymentOrderId.trim(),
  };
  return allowIds.contains(id);
}

/// Resolves whether a new booking/payment start should be blocked.
///
/// Same-order rules:
/// - If [currentOrderId] matches the active lock → resume (not blocked).
/// - If pending payment matches [FFAppState.pendingPaymentOrderId] → resume.
/// - Otherwise a different active booking blocks.
Future<TouryActiveBookingGateResult> touryEvaluateActiveBookingGate({
  String? currentOrderId,
}) async {
  final active = await touryFindActiveBookingForCurrentUser();
  if (active == null) {
    return const TouryActiveBookingGateResult(blocked: false);
  }

  final pending = FFAppState().pendingPaymentOrderId.trim();
  final paymentOrder = FFAppState().paymentOrderId.trim();

  if (touryIsSameActiveBookingFlow(
    activeOrderId: active.orderId,
    currentOrderId: currentOrderId,
    pendingPaymentOrderId: pending,
    paymentOrderId: paymentOrder,
  )) {
    return TouryActiveBookingGateResult(
      blocked: false,
      active: active,
      sameOrderResume: true,
    );
  }

  return TouryActiveBookingGateResult(blocked: true, active: active);
}

/// Shows snack + optional deep-link to a *different* existing order.
/// Returns true if blocked.
///
/// Pass [currentOrderId] when retrying/resuming payment for a known order so
/// the same booking is never treated as a foreign active booking.
Future<bool> touryBlockIfActiveBooking(
  BuildContext context, {
  String? currentOrderId,
}) async {
  final gate = await touryEvaluateActiveBookingGate(
    currentOrderId: currentOrderId,
  );
  if (!gate.blocked) return false;
  if (!context.mounted) return true;

  final active = gate.active;
  final code = (active?.statusCode ?? '').trim().toLowerCase();
  final isPaymentPending = code == TouryBookingStatusCodes.paymentPending ||
      code == 'pending_payment' ||
      code == 'awaiting_payment';

  TouryDialogs.showSnackBar(
    context,
    isPaymentPending
        ? 'booking_payment_in_progress_other'.tr()
        : 'booking_active_exists'.tr(),
    type: TouryMessageType.warning,
  );

  final order = active?.order;
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
