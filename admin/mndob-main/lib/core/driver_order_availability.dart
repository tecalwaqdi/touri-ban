import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/order_record.dart';
import '/core/toury_system_status_codes.dart';

/// Acceptance window for open pool orders (server timestamps only).
///
/// Deadline resolution order (never invents create-time from the device clock):
/// 1. `acceptanceDeadline` (Timestamp / DateTime)
/// 2. `acceptance_deadline_ms` (int epoch ms)
/// 3. `data_order` + 1 hour
/// 4. `createdAt` + 1 hour
///
/// [now] is only used to compare against those document fields.
abstract final class DriverOrderAvailability {
  DriverOrderAvailability._();

  static const acceptanceWindow = Duration(hours: 1);

  /// Absolute acceptance deadline from Firestore fields, or null if unknown.
  static DateTime? acceptanceDeadlineAt(Map<String, dynamic> data) {
    final direct = _asDateTime(data['acceptanceDeadline']);
    if (direct != null) return direct;

    final ms = data['acceptance_deadline_ms'];
    if (ms is num) {
      return DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true)
          .toLocal();
    }

    final created = createdAtFromDocument(data);
    if (created != null) return created.add(acceptanceWindow);
    return null;
  }

  /// Trusted create time from document fields (Firestore), never device "now".
  static DateTime? createdAtFromDocument(Map<String, dynamic> data) {
    return _asDateTime(data['data_order']) ??
        _asDateTime(data['createdAt']) ??
        _asDateTime(data['created_at']);
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is num) {
      final n = value.toInt();
      // Heuristic: seconds vs millis.
      final ms = n < 100000000000 ? n * 1000 : n;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// True when the offer window has clearly passed.
  /// If deadline fields are missing, returns false (cannot prove expiry from doc).
  static bool isAcceptanceExpired(
    Map<String, dynamic> data, {
    DateTime? now,
  }) {
    final deadline = acceptanceDeadlineAt(data);
    if (deadline == null) return false;
    return (now ?? DateTime.now()).isAfter(deadline);
  }

  static bool isAcceptanceExpiredOrder(
    OrderRecord order, {
    DateTime? now,
  }) =>
      isAcceptanceExpired(
        Map<String, dynamic>.from(order.snapshotData),
        now: now,
      );

  /// Still in the open offer pool for drivers.
  static bool isOpenOffer(OrderRecord order, {DateTime? now}) {
    final data = Map<String, dynamic>.from(order.snapshotData);
    if (order.mndobUser != null) return false;
    if (data['ALLNOW'] == false) return false;

    final status = (data['status_code'] ?? '').toString().trim().toLowerCase();
    if (status.isNotEmpty &&
        status != TourySystemStatusCodes.pendingDriver &&
        status != TourySystemStatusCodes.legacyAwaitingDriver &&
        status != 'pending') {
      return false;
    }
    if (TourySystemStatusCodes.isTerminalBooking(status)) return false;
    if (isAcceptanceExpired(data, now: now)) return false;
    return true;
  }

  /// Deduplicate by document id (first wins).
  static List<OrderRecord> uniqueById(Iterable<OrderRecord> orders) {
    final seen = <String>{};
    final out = <OrderRecord>[];
    for (final order in orders) {
      final id = order.reference.id;
      if (!seen.add(id)) continue;
      out.add(order);
    }
    return out;
  }
}
