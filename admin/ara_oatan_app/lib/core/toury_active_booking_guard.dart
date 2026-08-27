import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/core/payments/touri_payment_lock.dart';
import '/core/toury_active_booking.dart';
import '/core/toury_dialogs.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/order/tfasel_order/tfasel_order_widget.dart';

class TouryActiveBookingGateResult {
  const TouryActiveBookingGateResult({
    required this.blocked,
    this.active,
    this.sameOrderResume = false,
    this.decision = const TouriPaymentLockDecision(
      kind: TouriPaymentLockKind.none,
    ),
  });

  final bool blocked;
  final TouryActiveBookingInfo? active;
  final bool sameOrderResume;
  final TouriPaymentLockDecision decision;

  String get resumeOrderId => decision.resumeOrderId;
}

/// Pure same-order check — active lock is the current payment/booking flow.
@visibleForTesting
bool touryIsSameActiveBookingFlow({
  required String activeOrderId,
  String? currentOrderId,
  String pendingPaymentOrderId = '',
  String paymentOrderId = '',
}) {
  return touriIsSamePaymentBooking(
    activeOrderId: activeOrderId,
    currentOrderId: currentOrderId,
    pendingPaymentOrderId: pendingPaymentOrderId,
    paymentOrderId: paymentOrderId,
    paymentSessionId: paymentOrderId,
  );
}

Future<TouryActiveBookingGateResult> touryEvaluateActiveBookingGate({
  String? currentOrderId,
}) async {
  final active = await touryFindActiveBookingForCurrentUser();
  if (active == null) {
    return const TouryActiveBookingGateResult(blocked: false);
  }

  final pending = FFAppState().pendingPaymentOrderId.trim();
  final paymentOrder = FFAppState().paymentOrderId.trim();
  final payStatus =
      (active.order?.snapshotData['payment_status'] ?? '').toString();

  final decision = touriDecidePaymentLock(
    currentOrderId: currentOrderId,
    pendingPaymentOrderId: pending,
    paymentOrderId: paymentOrder,
    paymentSessionId: paymentOrder,
    activeOrderId: active.orderId,
    activeStatusCode: active.statusCode ?? '',
    activePaymentStatus: payStatus,
  );

  if (decision.shouldResume) {
    final id = decision.resumeOrderId;
    if (id.isNotEmpty) {
      FFAppState().pendingPaymentOrderId = id;
    }
    return TouryActiveBookingGateResult(
      blocked: false,
      active: active,
      sameOrderResume: true,
      decision: decision,
    );
  }

  if (decision.kind == TouriPaymentLockKind.none) {
    return TouryActiveBookingGateResult(
      blocked: false,
      active: active,
      decision: decision,
    );
  }

  return TouryActiveBookingGateResult(
    blocked: true,
    active: active,
    decision: decision,
  );
}

/// Shows a recoverable conflict — never a dead-end snack for same unpaid draft.
/// Returns true if blocked.
Future<bool> touryBlockIfActiveBooking(
  BuildContext context, {
  String? currentOrderId,
}) async {
  final gate = await touryEvaluateActiveBookingGate(
    currentOrderId: currentOrderId,
  );
  if (!gate.blocked) return false;
  if (!context.mounted) return true;

  final otherPayment =
      gate.decision.kind == TouriPaymentLockKind.conflictOtherPayment;

  await touryShowPaymentLockDialog(
    context,
    gate: gate,
    otherPayment: otherPayment,
  );
  return true;
}

Future<void> touryShowPaymentLockDialog(
  BuildContext context, {
  required TouryActiveBookingGateResult gate,
  required bool otherPayment,
}) async {
  final active = gate.active;
  final orderId = active?.orderId ?? '';
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        otherPayment
            ? 'payment_other_booking_conflict_title'.tr()
            : 'booking_active_exists'.tr(),
      ),
      content: Text(
        otherPayment
            ? 'payment_other_booking_conflict_body'.tr(
                namedArgs: {
                  'booking': orderId.length > 8
                      ? orderId.substring(0, 8)
                      : orderId,
                },
              )
            : 'booking_active_exists'.tr(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'view'),
          child: Text('booking_view_details'.tr()),
        ),
        if (otherPayment)
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'pay'),
            child: Text('checkout_resume_payment'.tr()),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'dismiss'),
          child: Text('order_cancel_confirm_back'.tr()),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (choice == 'view' || choice == 'pay') {
    final order = active?.order;
    if (order != null) {
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
  }
}

/// @deprecated Use lock dialog. Kept for tests that still call the snack helper.
void touryShowLegacyOtherBookingSnack(BuildContext context) {
  TouryDialogs.showSnackBar(
    context,
    'booking_payment_in_progress_other'.tr(),
    type: TouryMessageType.warning,
  );
}
