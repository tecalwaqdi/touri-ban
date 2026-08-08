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
      return 'booking_cancel_not_allowed';
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
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(order.reference);
        if (!snap.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'order missing',
          );
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
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'not booking owner',
          );
        }

        final liveStatus = (data['status_code'] ?? '').toString();
        final liveHalh = (data['halh_text'] ?? '').toString();
        if (TouryCustomerCancelPolicy.isAlreadyCancelled(
          statusCode: liveStatus,
          halhText: liveHalh,
        )) {
          return;
        }

        if (!TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: liveStatus,
          halhText: liveHalh,
          halhOrderName: (data['halh_order'] ?? '').toString(),
          driverOrderStatus: (data['halhOrderMndob'] ?? '').toString(),
        )) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'booking_cancel_race',
          );
        }

        tx.update(
          order.reference,
          customerCancelUpdatePayload(authUid: uid),
        );
      });
    } on FirebaseException catch (e) {
      debugPrint('cancelOrder FirebaseException: ${e.code} ${e.message}');
      return _mapFirebaseCancelError(e, order.reference);
    } catch (e) {
      debugPrint('cancelOrder error: $e');
      return 'booking_unknown_error';
    }

    // Cash / unpaid online — never invoke card refund.
    if (!isOnline || gatewayId.isEmpty) {
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

  /// null = treat as success (e.g. already cancelled).
  static Future<String?> _mapFirebaseCancelError(
    FirebaseException e,
    DocumentReference orderRef,
  ) async {
    if (e.code == 'failed-precondition' &&
        (e.message ?? '').contains('booking_cancel_race')) {
      return 'booking_cancel_race';
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
          final halh = (data['halh_text'] ?? '').toString();
          if (TouryCustomerCancelPolicy.isAlreadyCancelled(
            statusCode: status,
            halhText: halh,
          )) {
            return null;
          }
          if (!TouryCustomerCancelPolicy.canCustomerCancelBooking(
            statusCode: status,
            halhText: halh,
            halhOrderName: (data['halh_order'] ?? '').toString(),
            driverOrderStatus: (data['halhOrderMndob'] ?? '').toString(),
          )) {
            return 'booking_cancel_race';
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
