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

  /// True when a driver has accepted / been assigned (cancel must be blocked).
  static bool hasDriverAccepted({
    required String statusCode,
    String? halhText,
    String? halhOrderName,
    String? driverOrderStatus,
    dynamic mndobUser,
  }) {
    if (mndobUser != null) return true;

    final driver = (driverOrderStatus ?? '').trim().toLowerCase();
    if (driver == 'accepted' ||
        driver == HalhOrder.Accepted.name.toLowerCase()) {
      return true;
    }

    final code = BookingStatusLocalizer.resolveCode(
      statusCode: statusCode,
      halhText: halhText,
    );
    if (code == TouryBookingStatusCodes.driverAssigned ||
        code == TouryBookingStatusCodes.driverArrived ||
        code == TouryBookingStatusCodes.tripInProgress ||
        code == TouryBookingStatusCodes.completed ||
        code == TouryBookingStatusCodes.tripCompleted) {
      return true;
    }

    final halh = (halhText ?? '').trim();
    if (halh == 'مقبول' ||
        halh == 'وصل المندوب' ||
        halh == 'وصل السائق' ||
        halh == 'تم البدء في الرحلة' ||
        halh == 'بدأت الرحلة' ||
        halh == 'مكتمل') {
      return true;
    }

    final orderName = (halhOrderName ?? '').trim().toLowerCase();
    if (orderName == 'accepted') return true;

    return false;
  }

  /// Still waiting for any driver — no acceptance yet.
  static bool isAwaitingUnassignedDriver({
    required String statusCode,
    String? halhText,
    String? halhOrderName,
    String? driverOrderStatus,
    dynamic mndobUser,
  }) {
    if (hasDriverAccepted(
      statusCode: statusCode,
      halhText: halhText,
      halhOrderName: halhOrderName,
      driverOrderStatus: driverOrderStatus,
      mndobUser: mndobUser,
    )) {
      return false;
    }
    if (_isTerminalOrInProgress(
      code: statusCode.trim(),
      halh: (halhText ?? '').trim(),
      driverOrderStatus: driverOrderStatus,
    )) {
      return false;
    }
    return BookingStatusLocalizer.isAwaitingDriver(
          statusCode: statusCode,
          halhText: halhText,
          halhOrderName: halhOrderName,
        ) ||
        statusCode.trim().isEmpty ||
        statusCode.trim() == 'pending' ||
        statusCode.trim() == 'payment_pending' ||
        statusCode.trim() == 'awaiting_driver';
  }

  /// Parse Firestore `data_order` (Timestamp / DateTime / millis).
  static DateTime? createdAtFromField(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
    }
    if (raw is double) {
      return DateTime.fromMillisecondsSinceEpoch(raw.round(), isUtc: true);
    }
    return null;
  }

  /// Unpaid online booking awaiting card payment (no refund on cancel).
  static bool isUnpaidPaymentPending({
    required String statusCode,
    required String paymentStatus,
  }) {
    final code = statusCode.trim().toLowerCase();
    final ps = paymentStatus.trim().toLowerCase();
    if (code != 'payment_pending' && code != 'pending_payment') return false;
    return ps == 'unpaid' ||
        ps == 'pending' ||
        ps == 'failed' ||
        ps == 'cancelled' ||
        ps == 'canceled' ||
        ps == 'expired' ||
        ps.isEmpty;
  }

  /// Same cancellable matrix as customer UI + Firestore `consumerCanCancelOrder`.
  ///
  /// Allowed anytime before driver accept (no cancel timer / device clock).
  /// Blocked as soon as a driver is assigned or the booking is terminal.
  static bool canCustomerCancelBooking({
    required String statusCode,
    String? halhText,
    String? halhOrderName,
    String? driverOrderStatus,
    dynamic mndobUser,
    DateTime? createdAt,
    DateTime? now,
    String paymentStatus = '',
  }) {
    if (isAlreadyCancelled(statusCode: statusCode, halhText: halhText)) {
      return false;
    }

    if (hasDriverAccepted(
      statusCode: statusCode,
      halhText: halhText,
      halhOrderName: halhOrderName,
      driverOrderStatus: driverOrderStatus,
      mndobUser: mndobUser,
    )) {
      return false;
    }

    // Unpaid online draft: cancel immediately (no driver pool yet).
    if (isUnpaidPaymentPending(
      statusCode: statusCode,
      paymentStatus: paymentStatus,
    )) {
      return true;
    }

    return isAwaitingUnassignedDriver(
      statusCode: statusCode,
      halhText: halhText,
      halhOrderName: halhOrderName,
      driverOrderStatus: driverOrderStatus,
      mndobUser: mndobUser,
    );
  }

  static bool _isTerminalOrInProgress({
    required String code,
    required String halh,
    String? driverOrderStatus,
  }) {
    final normalized = code.trim().toLowerCase();
    if (normalized == TouryBookingStatusCodes.cancelled ||
        normalized == 'canceled' ||
        normalized == 'cancelled_by_driver' ||
        normalized == 'cancelled_by_customer' ||
        normalized == 'cancelled_by_admin' ||
        normalized == TouryBookingStatusCodes.tripCompleted ||
        normalized == 'completed' ||
        normalized == TouryBookingStatusCodes.tripInProgress ||
        normalized == 'trip_started' ||
        normalized == TouryBookingStatusCodes.driverArrived ||
        normalized == 'driver_arriving') {
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

  /// Best-effort deny reason key when [canCustomerCancelBooking] is false.
  static String denyReasonKey({
    required String statusCode,
    String? halhText,
    String? halhOrderName,
    String? driverOrderStatus,
    dynamic mndobUser,
    DateTime? createdAt,
    DateTime? now,
    String paymentStatus = '',
  }) {
    if (hasDriverAccepted(
      statusCode: statusCode,
      halhText: halhText,
      halhOrderName: halhOrderName,
      driverOrderStatus: driverOrderStatus,
      mndobUser: mndobUser,
    )) {
      return 'booking_cancel_after_driver';
    }
    return 'booking_cancel_not_allowed';
  }
}

/// Shared cancel payload — must stay aligned with Firestore `hasOnly` allow-list.
Map<String, Object?> customerCancelUpdatePayload({
  required String authUid,
  String reason = 'customer_cancelled',
}) {
  return {
    'status_code': TouryBookingStatusCodes.cancelledByCustomer,
    'cancelled_by_code': TouryBookingStatusCodes.cancelledByCustomer,
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
