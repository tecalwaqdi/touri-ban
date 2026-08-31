import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/admin/admindrever/admin_drivers_adapter.dart';
import '/backend/backend.dart';
import '/core/admin_booking_status_label.dart';

/// Resolves a driver's live trip from recent orders (lightweight, no full history).
class AdminDriverActiveTripTruth {
  const AdminDriverActiveTripTruth({
    required this.hasLiveTrip,
    this.order,
    this.row,
    this.statusLabel = '',
  });

  final bool hasLiveTrip;
  final OrderRecord? order;
  final AdminBookingRow? row;
  final String statusLabel;

  static const empty = AdminDriverActiveTripTruth(hasLiveTrip: false);

  static Future<AdminDriverActiveTripTruth> resolve(UserRecord driver) async {
    final truth = AdminDriverRow.fromUser(driver);
    if (!truth.onActiveTrip) return empty;

    try {
      final docs = await queryOrderRecordOnce(
        queryBuilder: (q) =>
            q.where('mndob_user', isEqualTo: driver.reference),
        limit: 12,
      );
      docs.sort((a, b) {
        final ad = a.dataOrder ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.dataOrder ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      for (final o in docs) {
        if (!AdminBookingStatusLabel.isTerminal(o)) {
          final row = AdminBookingRow.fromOrder(o);
          return AdminDriverActiveTripTruth(
            hasLiveTrip: true,
            order: o,
            row: row,
            statusLabel: row.statusLabel,
          );
        }
      }
      return empty;
    } catch (_) {
      return empty;
    }
  }
}
