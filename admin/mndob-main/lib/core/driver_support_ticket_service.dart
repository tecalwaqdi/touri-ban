import 'dart:math' as math;


import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_offline_queue.dart';
import '/flutter_flow/flutter_flow_util.dart';

enum DriverSupportCategory {
  payment,
  trip,
  complaint,
  emergency,
  accountDeletion,
  commissionTransfer,
  other,
}

class DriverSupportTicketDraft {
  const DriverSupportTicketDraft({
    required this.category,
    required this.subject,
    required this.message,
    this.orderRef,
    this.attachmentUrl,
    this.idempotencyKey,
  });

  final DriverSupportCategory category;
  final String subject;
  final String message;
  final DocumentReference? orderRef;
  final String? attachmentUrl;
  final String? idempotencyKey;
}

/// Central support ticket writer — uses existing `support` collection.
abstract final class DriverSupportTicketService {
  DriverSupportTicketService._();

  static final _rand = math.Random();
  static final Set<String> _recentKeys = {};

  static String categoryLabel(DriverSupportCategory c) {
    switch (c) {
      case DriverSupportCategory.payment:
        return 'Payment issue';
      case DriverSupportCategory.trip:
        return 'Trip issue';
      case DriverSupportCategory.complaint:
        return 'Complaint';
      case DriverSupportCategory.emergency:
        return 'Emergency';
      case DriverSupportCategory.accountDeletion:
        return 'Delete account';
      case DriverSupportCategory.commissionTransfer:
        return 'Commission transfer';
      case DriverSupportCategory.other:
        return 'Other';
    }
  }

  static String? validate(DriverSupportTicketDraft draft) {
    if (draft.subject.trim().isEmpty) return 'Subject is required';
    if (draft.message.trim().length < 5) {
      return 'Please describe the issue';
    }
    return null;
  }

  static Future<DriverSupportSubmitResult> submit(
    DriverSupportTicketDraft draft,
  ) async {
    final err = validate(draft);
    if (err != null) {
      return DriverSupportSubmitResult(ok: false, message: err);
    }

    final key = (draft.idempotencyKey != null &&
            draft.idempotencyKey!.trim().isNotEmpty)
        ? draft.idempotencyKey!.trim()
        : 'tkt_${DateTime.now().microsecondsSinceEpoch}_${_rand.nextInt(1 << 20)}';
    if (_recentKeys.contains(key)) {
      return const DriverSupportSubmitResult(
        ok: true,
        message: 'Ticket already submitted',
        duplicate: true,
      );
    }

    final online = await DriverConnectivityService.probe();
    if (!online) {
      return const DriverSupportSubmitResult(
        ok: false,
        message: 'Connection required to submit a support ticket.',
      );
    }

    final userRef = currentUserReference;
    if (userRef == null) {
      return const DriverSupportSubmitResult(
        ok: false,
        message: 'Please sign in first.',
      );
    }

    final doc = SupportRecord.collection.doc();
    await doc.set({
      ...createSupportRecordData(
        user: userRef,
        sub: '${categoryLabel(draft.category)}: ${draft.subject.trim()}',
        msg: draft.message.trim(),
        phonN: valueOrDefault(currentUserDocument?.phoneN, 0),
        email: currentUserEmail,
      ),
      'category': draft.category.name,
      'status': 'open',
      'idempotency_key': key,
      'created_at': FieldValue.serverTimestamp(),
      if (draft.orderRef != null) 'order_ref': draft.orderRef,
      if (draft.attachmentUrl != null && draft.attachmentUrl!.isNotEmpty)
        'attachment_url': draft.attachmentUrl,
    });

    _recentKeys.add(key);
    return DriverSupportSubmitResult(
      ok: true,
      ticketId: doc.id,
      message: 'Ticket submitted',
    );
  }

  static Stream<List<SupportRecord>> myTickets({int limit = 30}) {
    final userRef = currentUserReference;
    if (userRef == null) {
      return Stream.value(const []);
    }
    return SupportRecord.collection
        .where('user', isEqualTo: userRef)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(SupportRecord.fromSnapshot).toList());
  }
}

class DriverSupportSubmitResult {
  const DriverSupportSubmitResult({
    required this.ok,
    this.message,
    this.ticketId,
    this.duplicate = false,
  });

  final bool ok;
  final String? message;
  final String? ticketId;
  final bool duplicate;
}
