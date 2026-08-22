import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/core/toury_customer_cancel_policy.dart';
import '/core/toury_order_meta.dart';
import '/core/toury_payment_flags.dart';

/// Customer-facing cancel + navigation helpers for order details.
abstract final class TouryCustomerOrderActions {
  TouryCustomerOrderActions._();

  /// Single update matching `consumerCanCancelOrder` Firestore rules.
  static Future<void> writeCancelled(
    DocumentReference ref, {
    String reason = 'customer_cancelled',
  }) async {
    final uid = currentUserUid;
    await ref.update(
      customerCancelUpdatePayload(authUid: uid, reason: reason),
    );
  }

  /// Returns null on full success, or a **translation key** (not raw Firebase text).
  /// When cancel succeeds but refund is pending, returns a soft warning key.
  static Future<String?> cancelOrder(OrderRecord order) async {
    final uid = currentUserUid;
    if (uid.isEmpty || currentUserReference == null) {
      return 'booking_auth_required';
    }

    final ownerField = order.snapshotData['USER'] ?? order.user;
    if (!TouryCustomerCancelPolicy.isBookingOwner(
      userField: ownerField,
      authUid: uid,
      currentUserRef: currentUserReference,
    )) {
      return 'booking_permission_denied';
    }

    if (TouryCustomerCancelPolicy.isAlreadyCancelled(
      statusCode: order.rawStatusCode,
      halhText: order.halhText,
    )) {
      return null;
    }

    if (!order.canCancelByCustomer) {
      return TouryCustomerCancelPolicy.denyReasonKey(
        statusCode: order.rawStatusCode,
        halhText: order.halhText,
        halhOrderName: order.halhOrder?.name,
        driverOrderStatus: order.halhOrderMndob?.name,
        mndobUser: order.mndobUser ?? order.snapshotData['mndob_user'],
        createdAt: order.createdAtUtc,
        paymentStatus: (order.snapshotData['payment_status'] ?? '').toString(),
      );
    }

    final isOnline = order.paymentMethod == PaymentMethod.OnlinePayment &&
        !TouryPaymentFlags.cashOnlyMode;
    final gatewayId = order.paymentGatewayOrderId.trim();
    final paymentStatus =
        (order.snapshotData['payment_status'] ?? '').toString();

    if (TouryCustomerCancelPolicy.requiresPaidCancelGuard(
      isOnlinePayment: isOnline,
      paymentStatus: paymentStatus,
      gatewayOrderId: gatewayId,
    )) {
      return 'booking_cancel_not_allowed';
    }

    try {
      // Read-validate-write with server rules as the race authority against
      // driver accept. Avoid brittle same-txn lock clears.
      final snap = await order.reference.get();
      if (!snap.exists) {
        return 'booking_unknown_error';
      }
      final raw = snap.data();
      final data = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final liveUser = data['USER'];
      if (!TouryCustomerCancelPolicy.isBookingOwner(
        userField: liveUser,
        authUid: uid,
        currentUserRef: currentUserReference,
      )) {
        return 'booking_permission_denied';
      }

      final liveStatus = (data['status_code'] ?? '').toString();
      final liveHalh = (data['halh_text'] ?? '').toString();
      if (TouryCustomerCancelPolicy.isAlreadyCancelled(
        statusCode: liveStatus,
        halhText: liveHalh,
      )) {
        await _bestEffortClearActiveOrderLock(order.reference.id);
        return null;
      }

      if (!TouryCustomerCancelPolicy.canCustomerCancelBooking(
        statusCode: liveStatus,
        halhText: liveHalh,
        halhOrderName: (data['halh_order'] ?? '').toString(),
        driverOrderStatus: (data['halhOrderMndob'] ?? '').toString(),
        mndobUser: data['mndob_user'],
        paymentStatus: (data['payment_status'] ?? '').toString(),
      )) {
        return TouryCustomerCancelPolicy.denyReasonKey(
          statusCode: liveStatus,
          halhText: liveHalh,
          halhOrderName: (data['halh_order'] ?? '').toString(),
          driverOrderStatus: (data['halhOrderMndob'] ?? '').toString(),
          mndobUser: data['mndob_user'],
          paymentStatus: (data['payment_status'] ?? '').toString(),
        );
      }

      await order.reference.update(customerCancelUpdatePayload(authUid: uid));
    } on FirebaseException catch (e) {
      debugPrint('cancelOrder FirebaseException: ${e.code} ${e.message}');
      return _mapFirebaseCancelError(e, order.reference);
    } catch (e) {
      debugPrint('cancelOrder error: $e');
      return 'booking_unknown_error';
    }

    await _bestEffortClearActiveOrderLock(order.reference.id);

    // Cash / unpaid online — never invoke card refund.
    final unpaidPending = TouryCustomerCancelPolicy.isUnpaidPaymentPending(
      statusCode: order.rawStatusCode,
      paymentStatus: paymentStatus,
    );
    if (!isOnline || gatewayId.isEmpty || unpaidPending) {
      return null;
    }

    try {
      final refund = await NGeniusPaymentRefundCall.call(id: gatewayId);
      if (!refund.succeeded) {
        return 'booking_cancelled_refund_pending';
      }
    } catch (_) {
      return 'booking_cancelled_refund_pending';
    }

    return null;
  }

  static Future<void> _bestEffortClearActiveOrderLock(String orderId) async {
    final uref = currentUserReference;
    if (uref == null || orderId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userSnap = await tx.get(uref);
        if (!userSnap.exists) return;
        final udata = userSnap.data();
        final map = udata is Map<String, dynamic>
            ? udata
            : (udata is Map
                ? Map<String, dynamic>.from(udata)
                : <String, dynamic>{});
        final currentId = (map['active_order_id'] ?? '').toString().trim();
        if (currentId.isEmpty || currentId == orderId) {
          tx.set(
            uref,
            {
              'active_order_id': FieldValue.delete(),
              'active_order_updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
    } catch (e) {
      debugPrint('clear active_order_id after cancel failed: $e');
    }
  }

  /// null = treat as success (e.g. already cancelled).
  static Future<String?> _mapFirebaseCancelError(
    FirebaseException e,
    DocumentReference orderRef,
  ) async {
    if (e.code == 'failed-precondition' &&
        (e.message ?? '').contains('booking_cancel_after_driver')) {
      return 'booking_cancel_after_driver';
    }

    if (e.code == 'failed-precondition' &&
        (e.message ?? '').contains('booking_cancel_window_expired')) {
      return 'booking_cancel_window_expired';
    }

    if (e.code == 'failed-precondition' &&
        (e.message ?? '').contains('booking_cancel_race')) {
      return 'booking_cancel_race';
    }

    if (e.code == 'failed-precondition' &&
        (e.message ?? '').contains('booking_cancel_not_allowed')) {
      return 'booking_cancel_not_allowed';
    }

    if (e.code == 'permission-denied') {
      try {
        final fresh = await orderRef.get();
        if (fresh.exists) {
          final raw = fresh.data();
          final data = raw is Map
              ? Map<String, dynamic>.from(raw)
              : <String, dynamic>{};
          final status = (data['status_code'] ?? '').toString();
          final liveHalh = (data['halh_text'] ?? '').toString();
          if (TouryCustomerCancelPolicy.isAlreadyCancelled(
            statusCode: status,
            halhText: liveHalh,
          )) {
            return null;
          }
          if (TouryCustomerCancelPolicy.hasDriverAccepted(
            statusCode: status,
            halhText: liveHalh,
            halhOrderName: (data['halh_order'] ?? '').toString(),
            driverOrderStatus: (data['halhOrderMndob'] ?? '').toString(),
            mndobUser: data['mndob_user'],
          )) {
            return 'booking_cancel_after_driver';
          }
        }
      } catch (_) {}
      return 'booking_permission_denied';
    }

    switch (e.code) {
      case 'unauthenticated':
        return 'booking_auth_required';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'booking_service_unavailable';
      case 'not-found':
        return 'booking_unknown_error';
      default:
        return 'booking_unknown_error';
    }
  }

  /// Localized user-facing message for a cancel/create error key.
  static String localizedError(String? keyOrMessage) {
    if (keyOrMessage == null || keyOrMessage.isEmpty) return '';
    if (keyOrMessage.contains(' ') || keyOrMessage.contains(':')) {
      return 'booking_unknown_error'.tr();
    }
    final translated = keyOrMessage.tr();
    if (translated == keyOrMessage) {
      return 'booking_unknown_error'.tr();
    }
    return translated;
  }
}
