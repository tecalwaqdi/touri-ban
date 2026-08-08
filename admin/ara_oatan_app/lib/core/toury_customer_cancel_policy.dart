import '/backend/schema/enums/enums.dart';
import '/core/toury_booking_status_localizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pure helpers for customer booking cancel authorization (UI + write path).
abstract final class TouryCustomerCancelPolicy {
  TouryCustomerCancelPolicy._();

  /// Ownership field on `order` documents is `USER`.
  /// Accepts DocumentReference, path string, or bare uid (legacy).
  static bool isBookingOwner({
    required dynamic userField,
    required String authUid,
    DocumentReference? currentUserRef,
  }) {
    if (authUid.isEmpty) return false;

    if (userField is DocumentReference) {
      if (userField.id == authUid) return true;
      final expected = currentUserRef;
      if (expected != null && userField.path == expected.path) return true;
      return userField.path == 'user/$authUid';
    }

    if (userField is String) {
      var path = userField.trim();
      while (path.startsWith('/')) {
        path = path.substring(1);
      }
      if (path.isEmpty) return false;
      if (path == authUid) return true;
      if (path == 'user/$authUid') return true;
      if (path.endsWith('/user/$authUid')) return true;
      return false;
    }

    return false;
  }

  /// Same cancellable matrix as customer UI + Firestore `consumerCanCancelOrder`.
  static bool canCustomerCancelBooking({
    required String statusCode,
    String? halhText,
    String? halhOrderName,
    String? driverOrderStatus,
  }) {
    final code = statusCode.trim();
    final halh = (halhText ?? '').trim();

    if (_isTerminalOrInProgress(
      code: code,
      halh: halh,
      driverOrderStatus: driverOrderStatus,
    )) {
      return false;
    }

    if (BookingStatusLocalizer.isAwaitingDriver(
      statusCode: code,
      halhText: halh,
      halhOrderName: halhOrderName,
    )) {
      return true;
    }

    // Empty/missing status_code: treat legacy pending Arabic as cancellable.
    if (code.isEmpty) {
      if (halh.isEmpty) return true;
      if (halh == 'بإنتظار قبول المندوب' ||
          halh == 'بانتظار قبول المندوب' ||
          halh == 'بانتظار قبول السائق' ||
          halh == 'مقبول') {
        return true;
      }
      return false;
    }

    // Accepted / assigned but driver has not started en-route.
    if (code == TouryBookingStatusCodes.driverAssigned ||
        code == 'driver_assigned' ||
        code == 'payment_pending' ||
        code == 'pending' ||
        code == 'awaiting_driver' ||
        code == TouryBookingStatusCodes.pendingDriver) {
      return true;
    }

    return false;
  }

  static bool _isTerminalOrInProgress({
    required String code,
    required String halh,
    String? driverOrderStatus,
  }) {
    if (code == TouryBookingStatusCodes.cancelled ||
        code == 'canceled' ||
        code == 'cancelled_by_driver' ||
        code == 'cancelled_by_customer' ||
        code == 'cancelled_by_admin' ||
        code == TouryBookingStatusCodes.tripCompleted ||
        code == 'completed' ||
        code == TouryBookingStatusCodes.tripInProgress ||
        code == 'trip_started' ||
        code == TouryBookingStatusCodes.driverArrived ||
        code == 'driver_arriving') {
      return true;
    }
    if (BookingStatusLocalizer.isTripCompleted(
      statusCode: code,
      halhText: halh,
      driverOrderStatus: driverOrderStatus,
    )) {
      return true;
    }
    if (halh == 'ملغي' ||
        halh == 'ملغى' ||
        halh == 'مكتمل' ||
        halh == 'وصل المندوب' ||
        halh == 'وصل السائق' ||
        halh == 'تم البدء في الرحلة' ||
        halh == 'بدأت الرحلة') {
      return true;
    }
    final driver = (driverOrderStatus ?? '').toLowerCase();
    if (driver == 'completed') return true;
    return false;
  }

  static bool isAlreadyCancelled({
    required String statusCode,
    String? halhText,
  }) {
    final code = statusCode.trim().toLowerCase();
    if (code == 'cancelled' ||
        code == 'canceled' ||
        code == 'cancelled_by_customer' ||
        code == 'cancelled_by_driver' ||
        code == 'cancelled_by_admin') {
      return true;
    }
    final halh = (halhText ?? '').trim();
    return halh == 'ملغي' || halh == 'ملغى';
  }

  /// Online bookings that are already paid need refund path; without a gateway
  /// id we refuse cancel rather than silently dropping a paid order.
  static bool requiresPaidCancelGuard({
    required bool isOnlinePayment,
    required String paymentStatus,
    required String gatewayOrderId,
  }) {
    if (!isOnlinePayment) return false;
    final ps = paymentStatus.trim().toLowerCase();
    final paid = ps == 'paid' ||
        ps == 'captured' ||
        ps == 'authorized' ||
        ps == 'success';
    if (!paid) return false;
    return gatewayOrderId.trim().isEmpty;
  }
}

/// Shared cancel payload — must stay aligned with Firestore `hasOnly` allow-list.
Map<String, Object?> customerCancelUpdatePayload({
  required String authUid,
  String reason = 'customer_cancelled',
}) {
  return {
    'status_code': TouryBookingStatusCodes.cancelled,
    'cancelled_by_code': 'cancelled_by_customer',
    'cancelledAt': FieldValue.serverTimestamp(),
    'cancelledBy': authUid.isNotEmpty ? authUid : 'customer',
    'cancelReason': reason,
    'cancellationReason': reason,
    'updatedAt': FieldValue.serverTimestamp(),
    'ActiveOrder': false,
    'ALLNOW': false,
    'halh_order': Halh.Canceled.serialize(),
    'halh': 'cancelled',
    'halh_text': 'ملغي',
    'NotSestem': 'customer_cancelled',
  };
}
