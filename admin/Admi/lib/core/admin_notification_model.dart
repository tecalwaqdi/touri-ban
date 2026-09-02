import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories for [admin_panel_notifications] rows.
enum AdminNotificationCategory {
  drivers,
  operations,
  support,
  finance,
  system,
}

/// Parsed admin panel notification (Firestore `admin_panel_notifications`).
class AdminPanelNotification {
  AdminPanelNotification({
    required this.id,
    required this.reference,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.unread,
    required this.createdAt,
    this.driverId = '',
    this.bookingId = '',
    this.supportId = '',
    this.dedupKey = '',
  });

  final String id;
  final DocumentReference<Map<String, dynamic>> reference;
  final String type;
  final String title;
  final String subtitle;
  final AdminNotificationCategory category;
  final bool unread;
  final DateTime? createdAt;
  final String driverId;
  final String bookingId;
  final String supportId;
  final String dedupKey;

  factory AdminPanelNotification.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String Function(String key) tr,
  }) {
    final d = doc.data();
    final type = (d['type'] ?? '').toString();
    final driverId = (d['driverId'] ?? d['driver_id'] ?? '').toString();
    final bookingId = (d['bookingId'] ?? d['orderId'] ?? '').toString();
    final supportId = (d['supportId'] ?? d['ticketId'] ?? '').toString();
    final dedupKey = (d['dedupKey'] ?? d['dedup_key'] ?? doc.id).toString();

    final category = _categoryForType(type);
    final title = _titleFor(type, tr);
    final subtitle = _subtitleFor(d, driverId, bookingId, supportId);

    DateTime? created;
    final raw = d['createdAt'] ?? d['created_at'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is DateTime) {
      created = raw;
    }

    return AdminPanelNotification(
      id: doc.id,
      reference: doc.reference,
      type: type,
      title: title,
      subtitle: subtitle,
      category: category,
      unread: d['unread'] == true || d['read'] != true,
      createdAt: created,
      driverId: driverId,
      bookingId: bookingId,
      supportId: supportId,
      dedupKey: dedupKey,
    );
  }

  static AdminNotificationCategory _categoryForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('driver') ||
        t.contains('registration') ||
        t.contains('document') ||
        t.contains('resubmit')) {
      return AdminNotificationCategory.drivers;
    }
    if (t.contains('support') || t.contains('ticket')) {
      return AdminNotificationCategory.support;
    }
    if (t.contains('finance') ||
        t.contains('cash') ||
        t.contains('settlement') ||
        t.contains('reconcil')) {
      return AdminNotificationCategory.finance;
    }
    if (t.contains('booking') || t.contains('order') || t.contains('trip')) {
      return AdminNotificationCategory.operations;
    }
    return AdminNotificationCategory.system;
  }

  static String _titleFor(String type, String Function(String key) tr) {
    final t = type.toLowerCase();
    if (t.contains('resubmit')) {
      return tr('أعاد المندوب إرسال طلبه للمراجعة');
    }
    if (t.contains('driver') || t.contains('registration')) {
      return tr('طلب مندوب جديد بانتظار المراجعة');
    }
    if (t.contains('document') && t.contains('expir')) {
      return tr('وثيقة مندوب قاربت على الانتهاء');
    }
    if (t.contains('support') || t.contains('ticket')) {
      return tr('تذكرة دعم جديدة');
    }
    if (t.contains('booking') || t.contains('order')) {
      return tr('حجز جديد');
    }
    if (type.trim().isEmpty) return tr('إشعار إداري');
    return type;
  }

  static String _subtitleFor(
    Map<String, dynamic> d,
    String driverId,
    String bookingId,
    String supportId,
  ) {
    final parts = <String>[];
    if (driverId.isNotEmpty) parts.add('Driver: $driverId');
    if (bookingId.isNotEmpty) parts.add('Booking: $bookingId');
    if (supportId.isNotEmpty) parts.add('Ticket: $supportId');
    if (d['reviewAttemptCount'] != null) {
      parts.add('attempt: ${d['reviewAttemptCount']}');
    }
    return parts.join(' · ');
  }

  /// Dedup by key while preserving order (latest first).
  static List<AdminPanelNotification> dedupe(
      List<AdminPanelNotification> items) {
    final seen = <String>{};
    final out = <AdminPanelNotification>[];
    for (final n in items) {
      final key = n.dedupKey.isNotEmpty ? n.dedupKey : n.id;
      if (seen.add(key)) out.add(n);
    }
    return out;
  }
}

/// Masks secrets in audit/metadata strings for display.
String adminMaskSensitiveText(String raw) {
  if (raw.isEmpty) return raw;
  var s = raw;
  final patterns = [
    RegExp(
        r'(password|passwd|otp|token|api[_-]?key|secret|authorization)\s*[:=]\s*\S+',
        caseSensitive: false),
    RegExp(r'Bearer\s+\S+', caseSensitive: false),
  ];
  for (final p in patterns) {
    s = s.replaceAll(p, '[مخفي]');
  }
  return s;
}
