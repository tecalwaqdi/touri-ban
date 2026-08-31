import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/admin/adminuser/admin_customers_adapter.dart';
import '/backend/backend.dart';
import '/core/admin_booking_status_label.dart';

/// Resolves whether a customer's `active_order_id` points to a live trip.
///
/// Uses the same terminal detection as Admin Bookings ([AdminBookingStatusLabel])
/// without mutating the frozen bookings page.
class AdminCustomerActiveOrderTruth {
  const AdminCustomerActiveOrderTruth({
    required this.orderId,
    required this.hasLiveTrip,
    required this.isStaleLock,
    required this.orderMissing,
    this.order,
    this.row,
    this.statusLabel = '',
  });

  final String orderId;
  final bool hasLiveTrip;
  final bool isStaleLock;
  final bool orderMissing;
  final OrderRecord? order;
  final AdminBookingRow? row;
  final String statusLabel;

  static AdminCustomerActiveOrderTruth none() =>
      const AdminCustomerActiveOrderTruth(
        orderId: '',
        hasLiveTrip: false,
        isStaleLock: false,
        orderMissing: false,
      );

  /// Pure check from an already-loaded order document.
  static AdminCustomerActiveOrderTruth fromOrder({
    required String orderId,
    required OrderRecord? order,
  }) {
    final id = orderId.trim();
    if (id.isEmpty) return none();
    if (order == null) {
      return AdminCustomerActiveOrderTruth(
        orderId: id,
        hasLiveTrip: false,
        isStaleLock: true,
        orderMissing: true,
      );
    }
    final terminal = AdminBookingStatusLabel.isTerminal(order);
    final row = AdminBookingRow.fromOrder(order);
    return AdminCustomerActiveOrderTruth(
      orderId: id,
      hasLiveTrip: !terminal,
      isStaleLock: terminal,
      orderMissing: false,
      order: order,
      row: row,
      statusLabel: row.statusLabel,
    );
  }

  static Future<AdminCustomerActiveOrderTruth> resolveForUser(
    UserRecord user,
  ) async {
    final id = AdminCustomerRow.activeOrderIdOf(user);
    if (id.isEmpty) return none();
    try {
      final snap = await OrderRecord.collection.doc(id).get();
      if (!snap.exists) {
        return AdminCustomerActiveOrderTruth(
          orderId: id,
          hasLiveTrip: false,
          isStaleLock: true,
          orderMissing: true,
        );
      }
      return fromOrder(
        orderId: id,
        order: OrderRecord.fromSnapshot(snap),
      );
    } catch (_) {
      return AdminCustomerActiveOrderTruth(
        orderId: id,
        hasLiveTrip: false,
        isStaleLock: true,
        orderMissing: true,
      );
    }
  }

  /// Batch-resolve locks present on a page (avoids N+1 when most have no lock).
  static Future<Map<String, AdminCustomerActiveOrderTruth>> resolvePage(
    Iterable<UserRecord> users,
  ) async {
    final out = <String, AdminCustomerActiveOrderTruth>{};
    final withLock = <UserRecord>[];
    for (final u in users) {
      final id = AdminCustomerRow.activeOrderIdOf(u);
      if (id.isEmpty) {
        out[u.reference.id] = none();
      } else {
        withLock.add(u);
      }
    }
    await Future.wait(withLock.map((u) async {
      out[u.reference.id] = await resolveForUser(u);
    }));
    return out;
  }

  AdminCustomerTripHint get tripHint {
    if (orderId.isEmpty) return AdminCustomerTripHint.none;
    if (hasLiveTrip) return AdminCustomerTripHint.confirmedActive;
    if (isStaleLock || orderMissing) return AdminCustomerTripHint.staleLock;
    return AdminCustomerTripHint.lockPresent;
  }
}
