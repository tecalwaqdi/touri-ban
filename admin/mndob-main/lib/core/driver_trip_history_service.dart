import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/toury_system_status_codes.dart';

enum DriverHistoryFilter {
  all,
  today,
  week,
  month,
  completed,
  cancelled,
  cash,
  electronic,
  scheduled,
}

class DriverTripSummary {
  const DriverTripSummary({
    required this.order,
    required this.orderId,
    required this.statusCode,
    required this.paymentLabel,
    required this.paymentStatusKey,
    required this.finance,
    required this.pickup,
    required this.destination,
    required this.when,
  });

  final OrderRecord order;
  final String orderId;
  final String statusCode;
  final String paymentLabel;
  final String paymentStatusKey;
  final DriverTripFinance finance;
  final String pickup;
  final String destination;
  final DateTime? when;

  factory DriverTripSummary.fromOrder(OrderRecord order) {
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    final finance = DriverTripFinance.fromOrder(order);
    final when = order.dataOrder ??
        order.dateend ??
        order.start ??
        _asDate(order.snapshotData['completedAt']);
    return DriverTripSummary(
      order: order,
      orderId: order.reference.id,
      statusCode: code,
      paymentLabel: DriverPaymentLabels.label(order.paymentMethod),
      paymentStatusKey:
          DriverPaymentStatusMapper.displayKey(
            DriverPaymentStatusMapper.normalizeStatus(order),
          ),
      finance: finance,
      pickup: order.pickupLabel(),
      destination: order.destinationLabel(),
      when: when,
    );
  }

  static DateTime? _asDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

class DriverHistoryPage {
  const DriverHistoryPage({
    required this.items,
    required this.hasMore,
    this.lastDoc,
  });

  final List<DriverTripSummary> items;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
}

/// Paginated driver-owned trip history (never loads other drivers).
abstract final class DriverTripHistoryService {
  DriverTripHistoryService._();

  static const defaultLimit = 20;

  static Future<DriverHistoryPage> load({
    DriverHistoryFilter filter = DriverHistoryFilter.completed,
    int limit = defaultLimit,
    DocumentSnapshot? startAfter,
  }) async {
    final driverRef = currentUserReference;
    if (driverRef == null) {
      return const DriverHistoryPage(items: [], hasMore: false);
    }

    Query q = OrderRecord.collection
        .where('mndob_user', isEqualTo: driverRef)
        .orderBy('data_order', descending: true)
        .limit(limit);

    // Server-side filter when possible; rest applied client-side after ownership.
    switch (filter) {
      case DriverHistoryFilter.completed:
        q = OrderRecord.collection
            .where('mndob_user', isEqualTo: driverRef)
            .where('status_code', isEqualTo: TourySystemStatusCodes.completed)
            .orderBy('data_order', descending: true)
            .limit(limit);
        break;
      case DriverHistoryFilter.cancelled:
        // Multiple cancel codes — fetch by driver then filter.
        break;
      default:
        break;
    }

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    var items = snap.docs
        .map(OrderRecord.fromSnapshot)
        .where((o) => o.mndobUser?.path == driverRef.path)
        .map(DriverTripSummary.fromOrder)
        .toList();

    items = _applyClientFilter(items, filter);

    return DriverHistoryPage(
      items: items,
      hasMore: snap.docs.length >= limit,
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
    );
  }

  static List<DriverTripSummary> _applyClientFilter(
    List<DriverTripSummary> items,
    DriverHistoryFilter filter,
  ) {
    final now = DateTime.now();
    bool inRange(DateTime? d, Duration window) {
      if (d == null) return false;
      return now.difference(d) <= window;
    }

    switch (filter) {
      case DriverHistoryFilter.all:
      case DriverHistoryFilter.completed:
        return items;
      case DriverHistoryFilter.today:
        return items
            .where((e) => inRange(e.when, const Duration(hours: 24)))
            .toList();
      case DriverHistoryFilter.week:
        return items
            .where((e) => inRange(e.when, const Duration(days: 7)))
            .toList();
      case DriverHistoryFilter.month:
        return items
            .where((e) => inRange(e.when, const Duration(days: 31)))
            .toList();
      case DriverHistoryFilter.cancelled:
        return items
            .where((e) =>
                e.statusCode.startsWith('cancelled') ||
                e.statusCode == TourySystemStatusCodes.expired)
            .toList();
      case DriverHistoryFilter.cash:
        return items
            .where((e) => DriverPaymentLabels.isCash(e.order.paymentMethod))
            .toList();
      case DriverHistoryFilter.electronic:
        return items
            .where((e) => !DriverPaymentLabels.isCash(e.order.paymentMethod))
            .toList();
      case DriverHistoryFilter.scheduled:
        return items.where((e) {
          final sched = e.order.snapshotData['is_scheduled'] == true ||
              e.order.snapshotData['scheduled'] == true;
          return sched;
        }).toList();
    }
  }
}
