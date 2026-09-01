import 'package:cloud_firestore/cloud_firestore.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/backend/schema/order_record.dart';
import '/core/admin_booking_status_label.dart';
import '/core/admin_booking_geography.dart';
import '/core/finance/financial_engine.dart';
import '/core/toury_system_status_codes.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Admin-only details view — read-only over [AdminBookingRow] + order snapshot.
class AdminBookingDetailsView {
  const AdminBookingDetailsView({
    required this.row,
    required this.statusCode,
    required this.paymentStatusLabel,
    required this.cancellationByLabel,
    required this.cancellationReason,
    required this.customerRef,
    required this.driverRef,
    required this.pickupCity,
    required this.destinationCity,
    required this.pickupCoords,
    required this.destinationCoords,
    required this.hasDriver,
    required this.timeline,
    required this.showVat,
    required this.showDiscount,
    required this.discountAmount,
    required this.tripTypeLabel,
    required this.geography,
  });

  final AdminBookingRow row;
  final String statusCode;
  final String paymentStatusLabel;
  final String cancellationByLabel;
  final String cancellationReason;
  final DocumentReference? customerRef;
  final DocumentReference? driverRef;
  final String pickupCity;
  final String destinationCity;
  final String pickupCoords;
  final String destinationCoords;
  final bool hasDriver;
  final List<AdminBookingTimelineEvent> timeline;
  final bool showVat;
  final bool showDiscount;
  final double discountAmount;
  final String tripTypeLabel;
  final AdminBookingGeography geography;

  factory AdminBookingDetailsView.fromOrder(OrderRecord order) {
    final row = AdminBookingRow.fromOrder(order);
    final data = order.snapshotData;

    return AdminBookingDetailsView(
      row: row,
      statusCode: AdminBookingStatusLabel.codeOf(order),
      paymentStatusLabel: OrderStatusHelper.paymentStatusArabicLabel(order),
      cancellationByLabel: _cancellationBy(data, row),
      cancellationReason: _str(data, [
        'cancel_reason',
        'cancellation_reason',
        'cancelled_reason',
        'reason',
      ]),
      customerRef: order.user,
      driverRef: order.mndobUser,
      pickupCity: _landmarkCity(order, 0),
      destinationCity: _landmarkCity(order, 1),
      pickupCoords: _coordsLabel(_pickupLatLng(order)),
      destinationCoords: _coordsLabel(_destinationLatLng(order, data)),
      hasDriver: order.hasMndobUser() || order.naimMndobText.trim().isNotEmpty,
      timeline: AdminBookingTimelineEvent.build(row),
      showVat: order.totalVat > 0,
      showDiscount: _discount(data) > 0,
      discountAmount: _discount(data),
      tripTypeLabel: _tripType(data, order),
      geography: AdminBookingGeography.fromOrder(order),
    );
  }

  bool get isCancelled =>
      row.statusTone == AdminBookingStatusTone.canceled ||
      row.statusTone == AdminBookingStatusTone.expired;

  bool get isTerminal => row.isTerminal;

  static String formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '—';
    if (digits.length == 12 && digits.startsWith('966')) {
      return '+966 ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
    }
    if (digits.length == 10 && digits.startsWith('0')) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    return raw.trim().isNotEmpty ? raw.trim() : digits;
  }

  static String money(double v, String symbol) {
    if (v == 0) return '—';
    return formatNumber(
      v,
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
      currency: symbol.isNotEmpty ? '$symbol ' : '',
    );
  }

  static String _str(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static double _discount(Map<String, dynamic> data) {
    final v = data['discount'] ?? data['discount_amount'];
    if (v is num) return v.toDouble();
    return 0;
  }

  static String _tripType(Map<String, dynamic> data, OrderRecord order) {
    final schedule = order.fullSchedule.trim();
    if (schedule.isNotEmpty) return schedule;
    final t = _str(data, ['trip_type', 'booking_type', 'type']);
    if (t.isNotEmpty) return t;
    if (order.totalTaim > 0) return 'بالساعة';
    return '';
  }

  static String _coordsLabel(LatLng? ll) {
    if (ll == null) return '';
    return '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
  }

  static String _landmarkCity(OrderRecord order, int index) {
    final landmarks = order.listAmakn;
    if (landmarks.length <= index) return '';
    return landmarks[index].textivill.trim();
  }

  static LatLng? _pickupLatLng(OrderRecord order) {
    if (order.hasLokeshn()) return order.lokeshn;
    final landmarks = order.listAmakn;
    if (landmarks.isNotEmpty && landmarks.first.hasLoceshn()) {
      return landmarks.first.loceshn;
    }
    return null;
  }

  static LatLng? _destinationLatLng(
    OrderRecord order,
    Map<String, dynamic> data,
  ) {
    final landmarks = order.listAmakn;
    if (landmarks.length >= 2 && landmarks.last.hasLoceshn()) {
      return landmarks.last.loceshn;
    }
    final dest = data['destination'] ?? data['dropoff'];
    if (dest is GeoPoint) {
      return LatLng(dest.latitude, dest.longitude);
    }
    return null;
  }

  static String _cancellationBy(
    Map<String, dynamic> data,
    AdminBookingRow row,
  ) {
    if (row.statusTone != AdminBookingStatusTone.canceled) return '';
    var code = _str(data, ['cancelled_by_code', 'cancelled_by', 'canceled_by']);
    if (code.isEmpty) code = AdminBookingStatusLabel.codeOf(row.order);
    return switch (code) {
      TourySystemStatusCodes.cancelledByCustomer => 'العميل',
      TourySystemStatusCodes.cancelledByDriver => 'المندوب',
      TourySystemStatusCodes.cancelledByAdmin => 'الإدارة',
      TourySystemStatusCodes.expired => 'النظام',
      'system' => 'النظام',
      _ when code.startsWith('cancelled') || code.startsWith('canceled') =>
        'غير محدد',
      _ => '',
    };
  }

  /// Raw legacy fields for the technical debug panel only.
  Map<String, String> technicalFields() {
    final data = row.order.snapshotData;
    final entries = <String, String>{
      'status_code': statusCode,
      'halh_text': row.order.halhText,
      'halh': row.order.halh,
      'ALLNOW': '${row.order.allnow}',
      'ActiveOrder': '${data['ActiveOrder']}',
      'doc_id': row.order.reference.id,
    };
    entries.removeWhere((_, v) => v.trim().isEmpty);
    return entries;
  }
}

class AdminBookingTimelineEvent {
  const AdminBookingTimelineEvent({
    required this.label,
    required this.at,
  });

  final String label;
  final DateTime at;

  static List<AdminBookingTimelineEvent> build(AdminBookingRow row) {
    final events = <AdminBookingTimelineEvent>[
      if (row.createdAt != null)
        AdminBookingTimelineEvent(
          label: 'تم إنشاء الطلب',
          at: row.createdAt!,
        ),
      if (row.acceptedAt != null)
        AdminBookingTimelineEvent(
          label: 'قبول المندوب',
          at: row.acceptedAt!,
        ),
      if (row.arrivedAt != null)
        AdminBookingTimelineEvent(
          label: 'وصل المندوب',
          at: row.arrivedAt!,
        ),
      if (row.startedAt != null)
        AdminBookingTimelineEvent(
          label: 'بدأت الرحلة',
          at: row.startedAt!,
        ),
      if (row.completedAt != null)
        AdminBookingTimelineEvent(
          label: 'اكتملت الرحلة',
          at: row.completedAt!,
        ),
      if (row.cancelledAt != null)
        AdminBookingTimelineEvent(
          label: 'تم الإلغاء',
          at: row.cancelledAt!,
        ),
      if (row.expiresAt != null)
        AdminBookingTimelineEvent(
          label: 'انتهت الصلاحية',
          at: row.expiresAt!,
        ),
    ];
    events.sort((a, b) => a.at.compareTo(b.at));
    return events;
  }
}
