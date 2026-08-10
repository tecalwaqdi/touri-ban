import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Canonical booking / trip status codes (stored in DB; never show raw to users).
/// Aligns with driver/admin [TourySystemStatusCodes] write vocabulary.
abstract final class TouryBookingStatusCodes {
  static const pendingDriver = 'pending_driver';
  static const driverAssigned = 'driver_assigned';
  static const driverArrived = 'driver_arrived';
  static const tripInProgress = 'trip_in_progress';
  /// Canonical completed write (driver/admin). Prefer this for new writes.
  static const completed = 'completed';
  /// Legacy completed alias still present on older docs.
  static const tripCompleted = 'trip_completed';
  /// Canonical customer cancel write.
  static const cancelledByCustomer = 'cancelled_by_customer';
  static const cancelledByDriver = 'cancelled_by_driver';
  static const cancelledByAdmin = 'cancelled_by_admin';
  /// Legacy cancel alias.
  static const cancelled = 'cancelled';
  static const active = 'active';
  /// Online booking awaiting card payment (not dispatchable).
  static const paymentPending = 'payment_pending';
}

/// Maps legacy Arabic `halh_text` + machine `status_code` → localized labels.
abstract final class BookingStatusLocalizer {
  static const Map<String, String> _legacyHalhToCode = {
    'بإنتظار قبول المندوب': TouryBookingStatusCodes.pendingDriver,
    'بانتظار قبول المندوب': TouryBookingStatusCodes.pendingDriver,
    'بانتظار قبول السائق': TouryBookingStatusCodes.pendingDriver,
    'مقبول': TouryBookingStatusCodes.driverAssigned,
    'وصل المندوب': TouryBookingStatusCodes.driverArrived,
    'وصل السائق': TouryBookingStatusCodes.driverArrived,
    'تم البدء في الرحلة': TouryBookingStatusCodes.tripInProgress,
    'بدأت الرحلة': TouryBookingStatusCodes.tripInProgress,
    'مكتمل': TouryBookingStatusCodes.completed,
    'ملغي': TouryBookingStatusCodes.cancelledByCustomer,
    'ملغى': TouryBookingStatusCodes.cancelledByCustomer,
    'Pending': TouryBookingStatusCodes.pendingDriver,
  };

  static const Map<String, String> _statusCodeAlias = {
    'driver_assigned': TouryBookingStatusCodes.driverAssigned,
    'driver_arriving': TouryBookingStatusCodes.driverAssigned,
    'driver_arrived': TouryBookingStatusCodes.driverArrived,
    'trip_started': TouryBookingStatusCodes.tripInProgress,
    'trip_in_progress': TouryBookingStatusCodes.tripInProgress,
    'trip_completed': TouryBookingStatusCodes.completed,
    'completed': TouryBookingStatusCodes.completed,
    'cancelled': TouryBookingStatusCodes.cancelledByCustomer,
    'canceled': TouryBookingStatusCodes.cancelledByCustomer,
    'cancelled_by_customer': TouryBookingStatusCodes.cancelledByCustomer,
    'cancelled_by_driver': TouryBookingStatusCodes.cancelledByDriver,
    'cancelled_by_admin': TouryBookingStatusCodes.cancelledByAdmin,
    'pending': TouryBookingStatusCodes.pendingDriver,
    'pending_driver': TouryBookingStatusCodes.pendingDriver,
    'awaiting_driver': TouryBookingStatusCodes.pendingDriver,
    // Keep payment_pending distinct — unpaid online bookings must not look
    // like driver-pool pending.
    'payment_pending': TouryBookingStatusCodes.paymentPending,
    'pending_payment': TouryBookingStatusCodes.paymentPending,
  };

  static bool _isCancelledCode(String code) =>
      code == TouryBookingStatusCodes.cancelled ||
      code == TouryBookingStatusCodes.cancelledByCustomer ||
      code == TouryBookingStatusCodes.cancelledByDriver ||
      code == TouryBookingStatusCodes.cancelledByAdmin;

  static bool _isCompletedCode(String code) =>
      code == TouryBookingStatusCodes.completed ||
      code == TouryBookingStatusCodes.tripCompleted;

  /// True when the booking is waiting for a driver (not completed/cancelled).
  static bool isAwaitingDriver({
    String? statusCode,
    String? halhText,
    String? halhOrderName,
  }) {
    final code = resolveCode(statusCode: statusCode, halhText: halhText);
    if (code == TouryBookingStatusCodes.paymentPending) return false;
    if (code == TouryBookingStatusCodes.pendingDriver) return true;
    final order = (halhOrderName ?? '').toLowerCase();
    if (order == 'pending') return true;
    return false;
  }

  static bool isPaymentPending({
    String? statusCode,
    String? paymentStatus,
  }) {
    final code = resolveCode(statusCode: statusCode, halhText: null);
    if (code == TouryBookingStatusCodes.paymentPending) return true;
    final ps = (paymentStatus ?? '').trim().toLowerCase();
    return ps == 'unpaid' &&
        (statusCode ?? '').trim().toLowerCase() == 'payment_pending';
  }

  /// True when the trip itself is completed (not merely payment captured).
  static bool isTripCompleted({
    String? statusCode,
    String? halhText,
    String? driverOrderStatus,
  }) {
    final code = resolveCode(statusCode: statusCode, halhText: halhText);
    if (_isCompletedCode(code)) return true;
    final driver = (driverOrderStatus ?? '').toLowerCase();
    return driver == 'completed';
  }

  static String resolveCode({
    String? statusCode,
    String? halhText,
  }) {
    final code = (statusCode ?? '').trim();
    if (code.isNotEmpty) {
      return _statusCodeAlias[code] ??
          _statusCodeAlias[code.toLowerCase()] ??
          code;
    }
    final halh = (halhText ?? '').trim();
    if (halh.isEmpty) return TouryBookingStatusCodes.pendingDriver;
    return _legacyHalhToCode[halh] ??
        _statusCodeAlias[halh.toLowerCase()] ??
        TouryBookingStatusCodes.pendingDriver;
  }

  static String label(
    BuildContext? context, {
    String? statusCode,
    String? halhText,
  }) {
    final code = resolveCode(statusCode: statusCode, halhText: halhText);
    switch (code) {
      case TouryBookingStatusCodes.paymentPending:
        return 'status_awaiting_payment'.tr();
      case TouryBookingStatusCodes.pendingDriver:
        return 'status_pending_driver'.tr();
      case TouryBookingStatusCodes.driverAssigned:
        return 'status_driver_assigned'.tr();
      case TouryBookingStatusCodes.driverArrived:
        return 'status_driver_arrived'.tr();
      case TouryBookingStatusCodes.tripInProgress:
        return 'status_trip_started'.tr();
      case TouryBookingStatusCodes.completed:
      case TouryBookingStatusCodes.tripCompleted:
        return 'status_trip_completed'.tr();
      case TouryBookingStatusCodes.cancelled:
      case TouryBookingStatusCodes.cancelledByCustomer:
      case TouryBookingStatusCodes.cancelledByDriver:
      case TouryBookingStatusCodes.cancelledByAdmin:
        return 'status_cancelled'.tr();
      case TouryBookingStatusCodes.active:
        return 'booking_status_active'.tr();
      default:
        // Never pretend an unknown machine code is "pending driver".
        if (_isCancelledCode(code)) return 'status_cancelled'.tr();
        if (_isCompletedCode(code)) return 'status_trip_completed'.tr();
        return 'booking_status_active'.tr();
    }
  }
}

abstract final class PaymentStatusLocalizer {
  static String label(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'paid':
      case 'success':
      case 'captured':
        return 'status_paid'.tr();
      case 'failed':
      case 'failure':
      case 'error':
        return 'status_payment_failed'.tr();
      case 'pending':
      case 'awaiting':
      case 'unpaid':
        return 'status_payment_pending'.tr();
      case 'refunded':
        return 'wallet_status_cancelled'.tr();
      case 'cancelled':
      case 'canceled':
        return 'status_cancelled'.tr();
      default:
        return 'status_payment_pending'.tr();
    }
  }
}

abstract final class TripStatusLocalizer {
  static String label({
    String? statusCode,
    String? halhText,
  }) =>
      BookingStatusLocalizer.label(
        null,
        statusCode: statusCode,
        halhText: halhText,
      );
}
