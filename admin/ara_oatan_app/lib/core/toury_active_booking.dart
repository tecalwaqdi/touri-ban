import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_order_meta.dart';

/// Customer-active booking statuses (single active booking lock).
const Set<String> kTouryCustomerActiveStatusCodes = {
  TouryBookingStatusCodes.paymentPending,
  TouryBookingStatusCodes.pendingDriver,
  TouryBookingStatusCodes.driverAssigned,
  TouryBookingStatusCodes.driverArrived,
  TouryBookingStatusCodes.tripInProgress,
  TouryBookingStatusCodes.active,
  'driver_arriving',
  'trip_started',
  'awaiting_driver',
  'pending',
  'pending_payment',
};

const Set<String> kTouryCustomerTerminalStatusCodes = {
  TouryBookingStatusCodes.completed,
  TouryBookingStatusCodes.tripCompleted,
  TouryBookingStatusCodes.cancelled,
  TouryBookingStatusCodes.cancelledByCustomer,
  TouryBookingStatusCodes.cancelledByDriver,
  TouryBookingStatusCodes.cancelledByAdmin,
  'canceled',
  'expired',
};

bool touryIsCustomerActiveStatusCode(String? code) {
  final c = (code ?? '').trim().toLowerCase();
  if (c.isEmpty) return false;
  // Fail closed: anything not terminal counts as active.
  return !kTouryCustomerTerminalStatusCodes.contains(c);
}

class TouryActiveBookingInfo {
  const TouryActiveBookingInfo({
    required this.orderId,
    this.order,
    this.statusCode,
  });

  final String orderId;
  final OrderRecord? order;
  final String? statusCode;
}

/// Reads `user.active_order_id`, then falls back to scanning recent orders
/// so a missing/stale lock cannot allow a second booking.
Future<TouryActiveBookingInfo?> touryFindActiveBookingForCurrentUser() async {
  final uid = currentUserUid;
  final userRef = currentUserReference;
  if (uid.isEmpty || userRef == null) return null;

  final userSnap = await userRef.get();
  final data = userSnap.data() as Map<String, dynamic>?;
  final activeId = (data?['active_order_id'] ?? '').toString().trim();

  if (activeId.isNotEmpty) {
    final orderRef = OrderRecord.collection.doc(activeId);
    final orderSnap = await orderRef.get();
    if (orderSnap.exists) {
      final order = OrderRecord.fromSnapshot(orderSnap);
      final code =
          (order.snapshotData['status_code'] ?? order.rawStatusCode ?? '')
              .toString();
      if (touryIsCustomerActiveStatusCode(code)) {
        return TouryActiveBookingInfo(
          orderId: activeId,
          order: order,
          statusCode: code,
        );
      }
    }
    await _bestEffortClearStaleActiveLock(userRef);
  }

  final scanned = await _findActiveOrderByUserQuery(userRef);
  if (scanned != null) {
    await _bestEffortHealActiveLock(userRef, scanned.orderId);
    return scanned;
  }
  return null;
}

Future<TouryActiveBookingInfo?> _findActiveOrderByUserQuery(
  DocumentReference userRef,
) async {
  try {
    final snap = await OrderRecord.collection
        .where('USER', isEqualTo: userRef)
        .orderBy('data_order', descending: true)
        .limit(12)
        .get();
    for (final doc in snap.docs) {
      final order = OrderRecord.fromSnapshot(doc);
      final code =
          (order.snapshotData['status_code'] ?? order.rawStatusCode ?? '')
              .toString();
      if (touryIsCustomerActiveStatusCode(code)) {
        return TouryActiveBookingInfo(
          orderId: doc.id,
          order: order,
          statusCode: code,
        );
      }
      // Legacy rows without status_code: treat open cash/pending as active.
      if (code.isEmpty) {
        final halh = order.halhText.trim();
        final pay = (order.snapshotData['payment_status'] ?? '').toString();
        final cancelled = order.activeOrder == false &&
            (halh.contains('ملغ') ||
                pay == 'cancelled' ||
                pay == 'canceled');
        if (!cancelled &&
            (halh.contains('بإنتظار') ||
                halh.contains('انتظار') ||
                pay == 'payment_pending' ||
                pay == 'pending_cash' ||
                pay == 'cash_pending')) {
          return TouryActiveBookingInfo(
            orderId: doc.id,
            order: order,
            statusCode: code.isEmpty ? 'pending_driver' : code,
          );
        }
      }
    }
  } catch (_) {
    // Missing composite index or rules — fall through.
  }
  return null;
}

Future<void> _bestEffortClearStaleActiveLock(DocumentReference userRef) async {
  try {
    await userRef.set(
      {
        'active_order_id': FieldValue.delete(),
        'active_order_updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  } catch (_) {}
}

Future<void> _bestEffortHealActiveLock(
  DocumentReference userRef,
  String orderId,
) async {
  try {
    await userRef.set(
      {
        'active_order_id': orderId,
        'active_order_updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  } catch (_) {}
}

/// Claim `user.active_order_id` inside an open transaction (after other reads).
Future<String?> touryClaimActiveOrderInTransaction({
  required Transaction tx,
  required DocumentReference userRef,
  required String orderId,
}) async {
  final userSnap = await tx.get(userRef);
  final data = userSnap.data() as Map<String, dynamic>? ?? {};
  final currentId = (data['active_order_id'] ?? '').toString().trim();

  if (currentId.isNotEmpty && currentId != orderId) {
    final otherRef = OrderRecord.collection.doc(currentId);
    final otherSnap = await tx.get(otherRef);
    if (otherSnap.exists) {
      final other = otherSnap.data() as Map<String, dynamic>? ?? {};
      final code = (other['status_code'] ?? '').toString();
      if (touryIsCustomerActiveStatusCode(code)) {
        return currentId;
      }
    }
  }

  tx.set(
    userRef,
    {
      'active_order_id': orderId,
      'active_order_updated_at': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
  return null;
}

/// Committed claim (phase 1) — required before client cash order create.
Future<String?> touryClaimActiveOrderCommitted({
  required DocumentReference userRef,
  required String orderId,
}) async {
  return FirebaseFirestore.instance.runTransaction((tx) async {
    return touryClaimActiveOrderInTransaction(
      tx: tx,
      userRef: userRef,
      orderId: orderId,
    );
  });
}

Future<void> touryReleaseActiveOrderInTransaction({
  required Transaction tx,
  required DocumentReference userRef,
  required String orderId,
}) async {
  final userSnap = await tx.get(userRef);
  if (!userSnap.exists) return;
  final data = userSnap.data() as Map<String, dynamic>? ?? {};
  final currentId = (data['active_order_id'] ?? '').toString().trim();
  if (currentId.isEmpty || currentId != orderId) return;
  tx.set(
    userRef,
    {
      'active_order_id': FieldValue.delete(),
      'active_order_updated_at': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}
