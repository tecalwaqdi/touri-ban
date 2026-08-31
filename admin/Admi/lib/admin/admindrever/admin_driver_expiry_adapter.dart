import 'package:flutter/widgets.dart';

import '/admin/admindrever/admin_drivers_adapter.dart';
import '/backend/backend.dart';
import '/core/admin_driver_profile_view.dart';
import '/flutter_flow/flutter_flow_util.dart';

enum AdminDriverExpiryDisplayStatus {
  expired,
  expiringSoon,
  valid,
  unknown,
}

/// Read-only view-model for document expiry queue rows (no invented dates).
class AdminDriverExpiryRow {
  const AdminDriverExpiryRow({
    required this.user,
    required this.driverRow,
    required this.bucket,
    required this.documentTypeRaw,
    required this.expiryDate,
    required this.daysField,
    required this.status,
    required this.documentSlot,
  });

  final UserRecord user;
  final AdminDriverRow driverRow;
  final String bucket;
  final String documentTypeRaw;
  final DateTime? expiryDate;
  final num? daysField;
  final AdminDriverExpiryDisplayStatus status;
  final AdminDriverDocumentSlot? documentSlot;

  static AdminDriverExpiryRow fromUser(UserRecord user, {required String bucket}) {
    final data = user.snapshotData;
    final docType = '${data['doc_expiry_document_type'] ?? ''}'.trim();
    final expiry = AdminDriverProfileView.parseDocExpiry(data['doc_expiry_date']);
    final daysRaw = data['doc_expiry_days'];
    num? daysField;
    if (daysRaw is num) {
      daysField = daysRaw;
    } else {
      daysField = num.tryParse('$daysRaw');
    }

    final slot = _slotForType(user, docType);
    final status = _status(
      bucket: bucket,
      expiry: expiry,
      daysField: daysField,
    );

    return AdminDriverExpiryRow(
      user: user,
      driverRow: AdminDriverRow.fromUser(user),
      bucket: bucket,
      documentTypeRaw: docType,
      expiryDate: expiry,
      daysField: daysField,
      status: status,
      documentSlot: slot,
    );
  }

  static AdminDriverDocumentSlot? _slotForType(UserRecord user, String raw) {
    if (raw.isEmpty) return null;
    final key = raw.trim().toLowerCase();
    AdminDriverDocKind? kind;
    switch (key) {
      case 'national_id':
        kind = AdminDriverDocKind.nationalId;
      case 'driver_license':
        kind = AdminDriverDocKind.driverLicense;
      case 'vehicle_registration':
        kind = AdminDriverDocKind.vehicleRegistration;
      case 'profile_photo':
        kind = AdminDriverDocKind.profilePhoto;
      default:
        return null;
    }
    for (final s in AdminDriverProfileView.documents(user)) {
      if (s.kind == kind) return s;
    }
    return null;
  }

  static AdminDriverExpiryDisplayStatus _status({
    required String bucket,
    required DateTime? expiry,
    required num? daysField,
  }) {
    if (expiry == null && daysField == null) {
      return AdminDriverExpiryDisplayStatus.unknown;
    }
    if (bucket == 'expired') {
      return AdminDriverExpiryDisplayStatus.expired;
    }
    if (expiry != null) {
      final now = DateTime.now().toUtc();
      final e = expiry.toUtc();
      if (e.isBefore(now)) return AdminDriverExpiryDisplayStatus.expired;
      if (e.difference(now).inDays <= 30) {
        return AdminDriverExpiryDisplayStatus.expiringSoon;
      }
      return AdminDriverExpiryDisplayStatus.valid;
    }
    if (bucket == 'expiring_soon') {
      return AdminDriverExpiryDisplayStatus.expiringSoon;
    }
    return AdminDriverExpiryDisplayStatus.valid;
  }

  static String documentTypeLabel(BuildContext context, String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'national_id':
        return uiTr(context, 'الهوية');
      case 'driver_license':
        return uiTr(context, 'رخصة القيادة');
      case 'vehicle_registration':
        return uiTr(context, 'استمارة المركبة');
      case 'profile_photo':
        return uiTr(context, 'الصورة الشخصية');
      default:
        if (raw.isEmpty) return '—';
        return raw;
    }
  }

  static String statusLabel(
    BuildContext context,
    AdminDriverExpiryDisplayStatus s,
  ) {
    switch (s) {
      case AdminDriverExpiryDisplayStatus.expired:
        return uiTr(context, 'منتهية');
      case AdminDriverExpiryDisplayStatus.expiringSoon:
        return uiTr(context, 'تنتهي قريبًا');
      case AdminDriverExpiryDisplayStatus.valid:
        return uiTr(context, 'سارية');
      case AdminDriverExpiryDisplayStatus.unknown:
        return uiTr(context, 'غير محدد');
    }
  }

  /// Display-only relative text; never written to Firestore.
  static String daysDisplay(BuildContext context, AdminDriverExpiryRow row) {
    final expiry = row.expiryDate;
    if (expiry == null) {
      if (row.daysField != null && row.bucket == 'expired') {
        final d = row.daysField!.abs().round();
        return uiTr(context, 'منتهية منذ $d يومًا');
      }
      if (row.daysField != null && row.bucket == 'expiring_soon') {
        final d = row.daysField!.round();
        return uiTr(context, 'متبقي $d يومًا');
      }
      return uiTr(context, 'غير محدد');
    }

    final now = DateTime.now();
    final diffDays = expiry.difference(now).inDays;
    if (diffDays < 0) {
      return uiTr(context, 'منتهية منذ ${-diffDays} يومًا');
    }
    if (diffDays == 0) {
      return uiTr(context, 'تنتهي اليوم');
    }
    if (diffDays <= 60) {
      return uiTr(context, 'متبقي $diffDays يومًا');
    }
    final months = (diffDays / 30).round();
    return uiTr(context, 'متبقي $months أشهر');
  }

  bool matchesSearch(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return true;
    return driverRow.matchesSearch(query) ||
        documentTypeRaw.toLowerCase().contains(query);
  }
}
