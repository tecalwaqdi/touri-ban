/// Canonical booking / payment codes shared conceptually across Customer,
/// Driver, and Admin. Display strings stay localized; comparisons use these.
abstract final class TourySystemStatusCodes {
  TourySystemStatusCodes._();

  // Booking lifecycle (Firestore `status_code`)
  static const pendingDriver = 'pending_driver';
  static const driverAssigned = 'driver_assigned';
  static const driverArriving = 'driver_arriving';
  static const driverArrived = 'driver_arrived';
  static const tripStarted = 'trip_started';
  static const tripInProgress = 'trip_in_progress';
  static const completed = 'completed';
  static const cancelledByCustomer = 'cancelled_by_customer';
  static const cancelledByDriver = 'cancelled_by_driver';
  static const cancelledByAdmin = 'cancelled_by_admin';
  static const expired = 'expired';

  /// Legacy aliases still present in older documents.
  static const legacyAwaitingDriver = 'awaiting_driver';
  static const legacyTripCompleted = 'trip_completed';
  static const legacyCancelled = 'cancelled';
  static const legacyCanceled = 'canceled';

  // Payment (Firestore `payment_status`)
  static const unpaid = 'unpaid';
  static const pendingCash = 'pending_cash';
  static const cashCollected = 'cash_collected';
  static const processing = 'processing';
  static const paid = 'paid';
  static const failed = 'failed';
  static const refunded = 'refunded';

  static bool isTerminalBooking(String? code) {
    final c = (code ?? '').trim().toLowerCase();
    return c == completed ||
        c == legacyTripCompleted ||
        c == cancelledByCustomer ||
        c == cancelledByDriver ||
        c == cancelledByAdmin ||
        c == legacyCancelled ||
        c == legacyCanceled ||
        c == expired;
  }

  static bool isAssignable(String? code, String? halhText, String? halhOrder) {
    final c = (code ?? '').trim().toLowerCase();
    if (c == pendingDriver || c == legacyAwaitingDriver || c == 'pending') {
      return true;
    }
    if (c.isNotEmpty && isTerminalBooking(c)) return false;
    if (c == driverAssigned ||
        c == driverArrived ||
        c == tripStarted ||
        c == tripInProgress ||
        c == driverArriving) {
      return false;
    }
    // Legacy Arabic / English waiting labels.
    final h = (halhText ?? '').trim();
    if (h == 'بإنتظار قبول المندوب' ||
        h == 'بانتظار قبول المندوب' ||
        h == 'Pending') {
      return true;
    }
    final o = (halhOrder ?? '').trim();
    return o == 'Pending' || o.isEmpty && c.isEmpty;
  }

  /// Map legacy Arabic `halh_text` → canonical `status_code`.
  static String? fromHalhText(String? halhText) {
    switch ((halhText ?? '').trim()) {
      case 'بإنتظار قبول المندوب':
      case 'بانتظار قبول المندوب':
      case 'Pending':
        return pendingDriver;
      case 'مقبول':
        return driverAssigned;
      case 'وصل المندوب':
        return driverArrived;
      case 'تم البدء في الرحلة':
        return tripInProgress;
      case 'مكتمل':
      case 'مكتملة':
        return completed;
      case 'ملغي':
        return cancelledByDriver;
      default:
        return null;
    }
  }

  /// English phrase key for UI localization (DB dual-write still uses Arabic constants).
  static String displayHalhKeyForCode(String? code) {
    switch ((code ?? '').trim().toLowerCase()) {
      case pendingDriver:
      case legacyAwaitingDriver:
      case 'pending':
        return 'Waiting for driver';
      case driverAssigned:
      case driverArriving:
        return 'Accepted';
      case driverArrived:
        return 'Driver arrived';
      case tripStarted:
      case tripInProgress:
        return 'Trip started';
      case completed:
      case legacyTripCompleted:
        return 'Completed';
      case cancelledByCustomer:
      case cancelledByDriver:
      case cancelledByAdmin:
      case legacyCancelled:
      case legacyCanceled:
      case expired:
        return 'Cancelled';
      default:
        return '';
    }
  }

  /// Legacy dual-write Arabic label for Firestore `halh_text` only — not for UI.
  static String displayHalhForCode(String? code) {
    switch ((code ?? '').trim().toLowerCase()) {
      case pendingDriver:
      case legacyAwaitingDriver:
      case 'pending':
        return 'بإنتظار قبول المندوب';
      case driverAssigned:
      case driverArriving:
        return 'مقبول';
      case driverArrived:
        return 'وصل المندوب';
      case tripStarted:
      case tripInProgress:
        return 'تم البدء في الرحلة';
      case completed:
      case legacyTripCompleted:
        return 'مكتمل';
      case cancelledByCustomer:
      case cancelledByDriver:
      case cancelledByAdmin:
      case legacyCancelled:
      case legacyCanceled:
      case expired:
        return 'ملغي';
      default:
        return '';
    }
  }

  static bool isActiveTripCode(String? code) {
    final c = (code ?? '').trim().toLowerCase();
    return c == driverAssigned ||
        c == driverArriving ||
        c == driverArrived ||
        c == tripStarted ||
        c == tripInProgress;
  }
}
