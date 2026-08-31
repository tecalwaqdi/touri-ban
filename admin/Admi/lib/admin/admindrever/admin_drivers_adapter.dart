import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/backend/backend.dart';
import '/components/admin_status_badge.dart';
import '/core/admin_driver_profile_view.dart';
import '/core/admin_driver_status_truth.dart';
import '/flutter_flow/flutter_flow_util.dart';

export '/core/admin_driver_status_truth.dart'
    show AdminDriverConnectionStatus, AdminDriverAvailabilityStatus;

/// Compact row view-model for the Drivers admin list.
class AdminDriverRow {
  const AdminDriverRow({
    required this.user,
    required this.displayName,
    required this.secondaryLine,
    required this.phone,
    required this.city,
    required this.operatingCity,
    required this.photoUrl,
    required this.vehicle,
    required this.review,
    required this.accountActive,
    required this.connection,
    required this.availability,
    required this.onActiveTrip,
    required this.tripsLabel,
    required this.earningsLabel,
    required this.normalizedPlate,
    required this.rawPlate,
    required this.statusTruth,
  });

  final UserRecord user;
  final String displayName;
  final String secondaryLine;
  final String phone;
  final String city;
  final String operatingCity;
  final String photoUrl;
  final AdminDriverVehicleSummary vehicle;
  final AdminDriverReviewBucket review;
  final bool accountActive;
  final AdminDriverConnectionStatus connection;
  final AdminDriverAvailabilityStatus availability;
  final bool onActiveTrip;
  final String tripsLabel;
  final String earningsLabel;
  final String normalizedPlate;
  final String rawPlate;
  final AdminDriverStatusTruth statusTruth;

  static AdminDriverRow fromUser(UserRecord user) {
    final data = user.snapshotData;
    final name = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : (user.driverid.trim().isNotEmpty ? user.driverid.trim() : '—');
    final email = user.email.trim();
    final uid = user.reference.id;
    final secondary = email.isNotEmpty
        ? email
        : (uid.length > 10 ? '${uid.substring(0, 10)}…' : uid);

    final vehicle = AdminDriverProfileView.vehicle(user);
    final plateRaw = _str(data, 'number_lohh_car');
    final plateNorm = _str(data, 'normalized_plate');

    final truth = AdminDriverStatusTruth.fromMap(data);

    final registrationCity = user.mndobVillText.trim().isNotEmpty
        ? user.mndobVillText.trim()
        : _str(data, 'city_display');
    final operating = _str(data, 'city_display').isNotEmpty
        ? _str(data, 'city_display')
        : registrationCity;

    // Prefer bare storage path for SDK resolve (avoids token URL churn).
    final photoPath = _str(data, 'photo_storage_path');
    final photoUrl = photoPath.isNotEmpty
        ? photoPath
        : user.photoUrl.trim();

    final trips = data['Bookings_Agent'] ??
        data['bookings_count'] ??
        data['total_trips'] ??
        data['trips_count'];
    final tripsLabel = trips == null ? '—' : '$trips';

    // SoT denormalized counter used by Admin financial surfaces (not recomputed).
    final earnings = user.hasTotalApp()
        ? user.totalApp.toStringAsFixed(0)
        : (_num(data, 'total_app')?.toStringAsFixed(0) ?? '—');

    return AdminDriverRow(
      user: user,
      displayName: name,
      secondaryLine: secondary,
      phone: formatPhoneDisplay(
        user.phoneNumber.trim().isNotEmpty ? user.phoneNumber.trim() : '—',
      ),
      city: registrationCity.isNotEmpty ? registrationCity : '—',
      operatingCity: operating.isNotEmpty ? operating : '—',
      photoUrl: photoUrl,
      vehicle: vehicle,
      review: truth.registration,
      accountActive: truth.accountActive,
      connection: truth.connection,
      availability: truth.availability,
      onActiveTrip: truth.onActiveTrip,
      tripsLabel: tripsLabel,
      earningsLabel: earnings,
      normalizedPlate: plateNorm,
      rawPlate: plateRaw.isNotEmpty ? plateRaw : vehicle.plate,
      statusTruth: truth,
    );
  }

  bool matchesSearch(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'[\s\-]'), '');
    return displayName.toLowerCase().contains(q) ||
        phone.toLowerCase().contains(q) ||
        phone.replaceAll(RegExp(r'[\s\-]'), '').contains(digits) ||
        secondaryLine.toLowerCase().contains(q) ||
        user.email.toLowerCase().contains(q) ||
        user.reference.id.toLowerCase().contains(q) ||
        user.uid.toLowerCase().contains(q) ||
        user.driverid.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        vehicle.name.toLowerCase().contains(q) ||
        vehicle.classificationLabel.toLowerCase().contains(q) ||
        rawPlate.toLowerCase().contains(q) ||
        normalizedPlate.toLowerCase().contains(q) ||
        vehicle.plate.toLowerCase().contains(q);
  }

  static String _str(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return '';
    return v.toString().trim();
  }

  static double? _num(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static String formatPhoneDisplay(String raw) {
    if (raw.trim().isEmpty || raw == '—') return '—';
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 12 && digits.startsWith('966')) {
      return '+966 ${digits.substring(3, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 10 && digits.startsWith('05')) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    return raw.trim();
  }

  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2) : p;
    }
    return '${parts.first[0]}${parts.last[0]}';
  }
}

abstract final class AdminDriverStatusLabels {
  AdminDriverStatusLabels._();

  static String registration(BuildContext context, AdminDriverReviewBucket b) {
    switch (b) {
      case AdminDriverReviewBucket.pendingReview:
        return uiTr(context, 'بانتظار المراجعة');
      case AdminDriverReviewBucket.approved:
        return uiTr(context, 'معتمد');
      case AdminDriverReviewBucket.rejected:
        return uiTr(context, 'مرفوض');
      case AdminDriverReviewBucket.needsChanges:
        return uiTr(context, 'يحتاج تعديلات');
      case AdminDriverReviewBucket.suspended:
        return uiTr(context, 'موقوف');
      case AdminDriverReviewBucket.draft:
        return uiTr(context, 'مسودة');
      case AdminDriverReviewBucket.unknownLegacy:
        return uiTr(context, 'حالة غير محددة');
    }
  }

  static AdminStatusKind registrationKind(AdminDriverReviewBucket b) =>
      AdminDriverProfileView.reviewBadgeKind(b);

  static String account(BuildContext context, bool active) =>
      active ? uiTr(context, 'نشط') : uiTr(context, 'موقوف');

  static AdminStatusKind accountKind(bool active) =>
      active ? AdminStatusKind.active : AdminStatusKind.inactive;

  static String connection(
    BuildContext context,
    AdminDriverConnectionStatus s,
  ) {
    switch (s) {
      case AdminDriverConnectionStatus.online:
        return uiTr(context, 'متصل');
      case AdminDriverConnectionStatus.offline:
        return uiTr(context, 'غير متصل');
      case AdminDriverConnectionStatus.unknown:
        return uiTr(context, 'غير معروف');
    }
  }

  static AdminStatusKind connectionKind(AdminDriverConnectionStatus s) {
    switch (s) {
      case AdminDriverConnectionStatus.online:
        return AdminStatusKind.active;
      case AdminDriverConnectionStatus.offline:
        return AdminStatusKind.inactive;
      case AdminDriverConnectionStatus.unknown:
        return AdminStatusKind.unknown;
    }
  }

  static String availability(
    BuildContext context,
    AdminDriverAvailabilityStatus s,
  ) {
    switch (s) {
      case AdminDriverAvailabilityStatus.available:
        return uiTr(context, 'متاح');
      case AdminDriverAvailabilityStatus.busy:
        return uiTr(context, 'مشغول');
      case AdminDriverAvailabilityStatus.unavailable:
        return uiTr(context, 'غير متاح');
      case AdminDriverAvailabilityStatus.unknown:
        return uiTr(context, 'غير معروف');
    }
  }

  static AdminStatusKind availabilityKind(AdminDriverAvailabilityStatus s) {
    switch (s) {
      case AdminDriverAvailabilityStatus.available:
        return AdminStatusKind.active;
      case AdminDriverAvailabilityStatus.busy:
        return AdminStatusKind.medium;
      case AdminDriverAvailabilityStatus.unavailable:
        return AdminStatusKind.inactive;
      case AdminDriverAvailabilityStatus.unknown:
        return AdminStatusKind.unknown;
    }
  }

  /// Compact operational line: "متصل · متاح"
  static String operationalLine(BuildContext context, AdminDriverRow row) {
    if (row.connection == AdminDriverConnectionStatus.offline ||
        row.connection == AdminDriverConnectionStatus.unknown) {
      return connection(context, row.connection);
    }
    final a = connection(context, row.connection);
    final b = availability(context, row.availability);
    return '$a · $b';
  }
}

extension AdminDriverVehicleDisplay on AdminDriverVehicleSummary {
  String get titleLine {
    final car = [name, modelYear].where((e) => e.isNotEmpty).join(' ');
    return car;
  }

  String get classLine => classificationLabel;

  String plateLine(BuildContext context) {
    if (plate.isEmpty) return '';
    return '${uiTr(context, 'لوحة')}: $plate';
  }

  String missingLabel(BuildContext context) {
    if (kDebugMode) return 'Missing / Legacy';
    return uiTr(context, 'بيانات المركبة ناقصة');
  }
}
