/// Canonical booking / payment codes (Admin mirror of driver/customer contract).
abstract final class TourySystemStatusCodes {
  TourySystemStatusCodes._();

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
  static const legacyAwaitingDriver = 'awaiting_driver';
  static const legacyTripCompleted = 'trip_completed';
  static const legacyCancelled = 'cancelled';
  static const legacyCanceled = 'canceled';

  static const unpaid = 'unpaid';
  static const pendingCash = 'pending_cash';
  static const cashCollected = 'cash_collected';
  static const processing = 'processing';
  static const paid = 'paid';
  static const failed = 'failed';
  static const refunded = 'refunded';
}
