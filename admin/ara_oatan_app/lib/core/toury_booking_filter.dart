import '/backend/schema/order_record.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_order_meta.dart';

/// Segments a customer booking into exactly one list tab.
enum TouryBookingBucket {
  /// Driver pending / assigned / arrived / trip running.
  active,

  /// Online booking created but card payment not captured yet.
  awaitingPayment,

  completed,

  cancelled,
}

/// Pure resolver — takes raw Firestore-ish primitives so it stays unit testable.
///
/// Order of precedence matters: a cancelled booking is cancelled even when it
/// carries a stale `payment_status`, and an unpaid booking must never be shown
/// as "active" (it is not dispatchable yet).
TouryBookingBucket touryResolveBookingBucket({
  String? statusCode,
  String? halhText,
  String? halhOrderName,
  String? driverOrderStatus,
  String? paymentStatus,
}) {
  final code = BookingStatusLocalizer.resolveCode(
    statusCode: statusCode,
    halhText: halhText,
  );

  if (code == TouryBookingStatusCodes.cancelled ||
      code == TouryBookingStatusCodes.cancelledByCustomer ||
      code == TouryBookingStatusCodes.cancelledByDriver ||
      code == TouryBookingStatusCodes.cancelledByAdmin ||
      (halhOrderName ?? '').toLowerCase() == 'canceled') {
    return TouryBookingBucket.cancelled;
  }

  if (BookingStatusLocalizer.isTripCompleted(
    statusCode: statusCode,
    halhText: halhText,
    driverOrderStatus: driverOrderStatus,
  )) {
    return TouryBookingBucket.completed;
  }

  if (BookingStatusLocalizer.isPaymentPending(
    statusCode: statusCode,
    paymentStatus: paymentStatus,
  )) {
    return TouryBookingBucket.awaitingPayment;
  }

  return TouryBookingBucket.active;
}

extension TouryOrderBucket on OrderRecord {
  TouryBookingBucket get bookingBucket => touryResolveBookingBucket(
        statusCode: rawStatusCode.isNotEmpty ? rawStatusCode : statusCode,
        halhText: halhText,
        halhOrderName: halhOrder?.name,
        driverOrderStatus: halhOrderMndob?.name,
        paymentStatus: (snapshotData['payment_status'] ?? '').toString(),
      );
}

/// Counts per bucket for tab badges (single pass).
Map<TouryBookingBucket, int> touryCountBuckets(Iterable<OrderRecord> orders) {
  final counts = <TouryBookingBucket, int>{
    for (final b in TouryBookingBucket.values) b: 0,
  };
  for (final order in orders) {
    counts[order.bookingBucket] = (counts[order.bookingBucket] ?? 0) + 1;
  }
  return counts;
}

List<OrderRecord> touryFilterBookings(
  List<OrderRecord> orders,
  TouryBookingBucket bucket,
) =>
    orders.where((o) => o.bookingBucket == bucket).toList(growable: false);
