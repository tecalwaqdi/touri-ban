import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_record.dart';
import '/core/admin_booking_status_label.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/financial_engine.dart';

/// Admin-only view model over [OrderRecord] — does not mutate Firestore contracts.
class AdminBookingRow {
  const AdminBookingRow({
    required this.order,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.driverName,
    required this.driverPhone,
    required this.statusLabel,
    required this.statusTone,
    required this.city,
    required this.pickupLabel,
    required this.destinationLabel,
    required this.landmarksLabel,
    required this.vehicleLabel,
    required this.plateLabel,
    required this.amount,
    required this.commission,
    required this.driverNet,
    required this.driverNetIsDerived,
    required this.currencySymbol,
    required this.paymentLabel,
    required this.paymentStatusLabel,
    required this.routeLabel,
    required this.createdAt,
    required this.acceptedAt,
    required this.arrivedAt,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.expiresAt,
    this.paymentAt,
    required this.durationMinutes,
    required this.isTerminal,
    required this.isActivePool,
    this.isQaFixture = false,
    this.qaBadgeLabel,
  });

  final OrderRecord order;
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String driverName;
  final String driverPhone;
  final String statusLabel;
  final AdminBookingStatusTone statusTone;
  final String city;
  final String pickupLabel;
  final String destinationLabel;
  final String landmarksLabel;
  final String vehicleLabel;
  final String plateLabel;
  final double amount;

  /// Platform fee (`total_app`). Null when unprovable — never coerce missing → 0.
  final double? commission;

  /// Driver net from canonical V2 engine. Null when unprovable — never gross.
  final double? driverNet;
  final bool driverNetIsDerived;
  final String currencySymbol;
  final String paymentLabel;
  final String paymentStatusLabel;
  final String routeLabel;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;
  final DateTime? paymentAt;
  final int durationMinutes;
  final bool isTerminal;
  final bool isActivePool;
  final bool isQaFixture;
  final String? qaBadgeLabel;

  factory AdminBookingRow.fromOrder(OrderRecord order) {
    final data = order.snapshotData;
    final landmarks = _landmarkNames(order);
    final pickup = _pickupLabel(order, landmarks);
    final destination = _destinationLabel(order, landmarks);
    final money = AdminOrderMoneyDisplay.fromOrder(order);
    final qa = AdminQaFixture.isFixtureOrder(order);

    return AdminBookingRow(
      order: order,
      orderId: order.iDorder.trim().isNotEmpty
          ? order.iDorder.trim()
          : order.reference.id,
      customerName: order.naimUserText.trim(),
      customerPhone: _phoneString(order.phoneNumper, data['phone_numper']),
      driverName: order.naimMndobText.trim().isNotEmpty
          ? order.naimMndobText.trim()
          : (qa && order.mndobUser == null
              ? '—'
              : order.naimMndobText.trim()),
      driverPhone: _phoneString(order.phoneNuMndob, data['phone_nu_mndob']),
      statusLabel: AdminBookingStatusLabel.of(order),
      statusTone: AdminBookingStatusLabel.toneOf(order),
      city: order.villText.trim().isNotEmpty
          ? order.villText.trim()
          : _str(data['city_text']),
      pickupLabel: pickup,
      destinationLabel: destination,
      landmarksLabel: landmarks.join(' ← '),
      vehicleLabel: order.cartext.trim(),
      plateLabel: _firstNonEmpty([
        _str(data['number_lohh_car']),
        _str(data['plate']),
        _str(data['normalized_plate']),
        _str(data['car_plate']),
      ]),
      // Presentation: prefer engine gross/customer paid; else stored total.
      amount: money.gross?.majorUnits ?? order.total,
      // Missing platform fee stays null (never ?? 0).
      commission: money.platformFee?.majorUnits,
      // Never fallback total_mndob2 (gross) → driver net.
      driverNet: money.driverNetMajor,
      driverNetIsDerived: money.driverNetIsDerived,
      currencySymbol: money.currencySymbol,
      paymentLabel: _paymentLabel(order),
      paymentStatusLabel: OrderStatusHelper.paymentStatusArabicLabel(order),
      routeLabel: _routeLabel(pickup, destination),
      createdAt: order.dataOrder ?? _asDate(data['createdAt']),
      acceptedAt: _asDate(data['acceptedAt']),
      arrivedAt: _asDate(data['arrivedAt']),
      startedAt: _asDate(data['startedAt'] ?? data['tripStartedAt']),
      completedAt: _asDate(data['completedAt']),
      cancelledAt: _asDate(data['cancelledAt']),
      expiresAt: _asDate(data['expiresAt']),
      paymentAt: _asDate(
        data['cash_collected_at'] ??
            data['paid_at'] ??
            data['payment_verified_at'] ??
            data['paymentCollectedAt'],
      ),
      durationMinutes: order.totalTaim,
      isTerminal: AdminBookingStatusLabel.isTerminal(order),
      isActivePool: order.allnow ||
          data['ActiveOrder'] == true ||
          data['ALLNOW'] == true,
      isQaFixture: qa,
      qaBadgeLabel: qa ? AdminQaFixture.badgeAr(order) : null,
    );
  }

  /// Display string for driver net (`42.50 ر.س` or `—`).
  String get driverNetLabel {
    if (driverNet == null) return '—';
    return AdminOrderMoneyDisplay.formatMajor(
      driverNet,
      symbol: currencySymbol,
    );
  }

  /// Display string for platform commission (`—` when missing).
  String get commissionLabel {
    if (commission == null) return '—';
    return AdminOrderMoneyDisplay.formatMajor(
      commission,
      symbol: currencySymbol,
    );
  }

  static String _phoneString(int typed, dynamic raw) {
    if (typed > 0) return typed.toString();
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty || s == '0') return '';
    return s;
  }

  static String _str(dynamic v) => (v ?? '').toString().trim();

  static String _firstNonEmpty(List<String> values) {
    for (final v in values) {
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static List<String> _landmarkNames(OrderRecord order) {
    final names = <String>[];
    for (final item in order.listAmakn) {
      final n = item.naim.trim();
      if (n.isNotEmpty) names.add(n);
    }
    if (names.isEmpty && order.hasListamakn()) {
      final n = order.listamakn.naim.trim();
      if (n.isNotEmpty) names.add(n);
    }
    return names;
  }

  static String _pickupLabel(OrderRecord order, List<String> landmarks) {
    if (landmarks.isNotEmpty) return landmarks.first;
    final coords = order.lokeshn;
    if (coords != null) {
      return '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';
    }
    return '';
  }

  static String _destinationLabel(OrderRecord order, List<String> landmarks) {
    if (landmarks.length >= 2) return landmarks.last;
    if (landmarks.length == 1) return landmarks.first;
    return '';
  }

  static String _paymentLabel(OrderRecord order) {
    switch (order.paymentMethod) {
      case PaymentMethod.Cash:
        return 'نقداً';
      case PaymentMethod.OnlinePayment:
        return 'إلكتروني';
      default:
        return order.paymentGatewayOrderId.isNotEmpty ? 'إلكتروني' : '';
    }
  }

  static String _routeLabel(String pickup, String destination) {
    if (pickup.isEmpty && destination.isEmpty) return '';
    if (pickup.isEmpty) return destination;
    if (destination.isEmpty) return pickup;
    if (pickup == destination) return pickup;
    return '$pickup → $destination';
  }
}

/// Sort keys for the bookings table (server or client on current page).
enum AdminBookingsSortKey {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  status,
  orderId,
}

abstract final class AdminBookingsSorter {
  AdminBookingsSorter._();

  static List<OrderRecord> sort(
    List<OrderRecord> input,
    AdminBookingsSortKey key,
  ) {
    final list = List<OrderRecord>.from(input);
    int cmpDate(OrderRecord a, OrderRecord b) {
      final da = a.dataOrder?.millisecondsSinceEpoch ?? 0;
      final db = b.dataOrder?.millisecondsSinceEpoch ?? 0;
      return da.compareTo(db);
    }

    switch (key) {
      case AdminBookingsSortKey.dateDesc:
        list.sort((a, b) => cmpDate(b, a));
      case AdminBookingsSortKey.dateAsc:
        list.sort(cmpDate);
      case AdminBookingsSortKey.amountDesc:
        list.sort((a, b) => b.total.compareTo(a.total));
      case AdminBookingsSortKey.amountAsc:
        list.sort((a, b) => a.total.compareTo(b.total));
      case AdminBookingsSortKey.status:
        list.sort(
          (a, b) => AdminBookingStatusLabel.of(a)
              .compareTo(AdminBookingStatusLabel.of(b)),
        );
      case AdminBookingsSortKey.orderId:
        list.sort((a, b) => a.iDorder.compareTo(b.iDorder));
    }
    return list;
  }
}
