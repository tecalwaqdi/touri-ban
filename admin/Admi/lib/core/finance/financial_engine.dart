import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_record.dart';
import '/core/toury_system_status_codes.dart';

/// Unified order payment / lifecycle status for finance dashboards.
enum OrderPaymentStatus { paid, pending, canceled, unknown }

/// Single source of truth for order status interpretation (no Mojibake).
abstract final class OrderStatusHelper {
  OrderStatusHelper._();

  static bool _matchesAny(String value, Set<String> candidates) {
    final normalized = value.trim().toLowerCase();
    return candidates.any((candidate) => normalized == candidate.toLowerCase());
  }

  static String _statusCode(OrderRecord order) {
    final raw = order.snapshotData['status_code'];
    return (raw ?? '').toString().trim().toLowerCase();
  }

  static String _paymentStatus(OrderRecord order) {
    final raw = order.snapshotData['payment_status'];
    final pay = (raw ?? '').toString().trim().toLowerCase();
    if (pay == 'cash_pending' || pay == 'cash_due') {
      return TourySystemStatusCodes.pendingCash;
    }
    return pay;
  }

  static bool isCanceled(OrderRecord order) {
    if (order.halhOrder == Halh.Canceled) return true;
    final code = _statusCode(order);
    if (code == TourySystemStatusCodes.cancelledByAdmin ||
        code == TourySystemStatusCodes.legacyCancelled ||
        code == TourySystemStatusCodes.legacyCanceled ||
        code.startsWith('cancelled') ||
        code.startsWith('canceled')) {
      return true;
    }
    if (order.halh.toLowerCase() == 'canceled' ||
        order.halh.toLowerCase() == 'cancelled') {
      return true;
    }
    return _matchesAny(order.halhText, {
      'ملغي',
      'ملغى',
    });
  }

  static bool isPaid(OrderRecord order) {
    if (isCanceled(order)) return false;
    final pay = _paymentStatus(order);
    if (pay == TourySystemStatusCodes.paid ||
        pay == TourySystemStatusCodes.cashCollected ||
        pay == 'captured') {
      return true;
    }
    final code = _statusCode(order);
    if (code == TourySystemStatusCodes.completed ||
        code == TourySystemStatusCodes.legacyTripCompleted) {
      // Completed trips count as revenue once payment is cash collected or online paid.
      if (order.halhOrder == Halh.Paid ||
          order.halh.toLowerCase() == 'paid' ||
          pay == TourySystemStatusCodes.pendingCash) {
        // pending_cash completed => still pending settlement; not paid revenue yet
        return order.halhOrder == Halh.Paid ||
            order.halh.toLowerCase() == 'paid' ||
            pay == TourySystemStatusCodes.cashCollected;
      }
    }
    if (order.halhOrder == Halh.Paid) return true;
    if (order.halh.toLowerCase() == 'paid') return true;
    return _matchesAny(order.halhText, {
      'مكتمل',
      'مكتملة',
    });
  }

  static bool isPending(OrderRecord order) {
    if (isCanceled(order) || isPaid(order)) return false;
    if (order.halhOrder == Halh.Pending) return true;
    if (order.halh.toLowerCase() == 'pending') return true;
    final pay = _paymentStatus(order);
    if (pay == TourySystemStatusCodes.pendingCash ||
        pay == TourySystemStatusCodes.unpaid ||
        pay == TourySystemStatusCodes.processing) {
      return true;
    }
    return !isCanceled(order) && !isPaid(order);
  }

  static OrderPaymentStatus statusOf(OrderRecord order) {
    if (isCanceled(order)) return OrderPaymentStatus.canceled;
    if (isPaid(order)) return OrderPaymentStatus.paid;
    if (isPending(order)) return OrderPaymentStatus.pending;
    return OrderPaymentStatus.unknown;
  }

  static bool countsTowardRevenue(OrderRecord order) => isPaid(order);

  /// Canonical Arabic payment chip label (localize at display with [uiTr]).
  static String paymentStatusArabicLabel(OrderRecord order) {
    switch (statusOf(order)) {
      case OrderPaymentStatus.paid:
        return 'مدفوع';
      case OrderPaymentStatus.pending:
        return 'قيد الانتظار';
      case OrderPaymentStatus.canceled:
        return 'ملغي';
      case OrderPaymentStatus.unknown:
        return 'غير معروف';
    }
  }
}

class OrderFinancials {
  const OrderFinancials({
    required this.totalSales,
    required this.appProfit,
    required this.vat,
    required this.repCommission,
    required this.deliveryFees,
    required this.isPaid,
    required this.isPending,
    required this.isCanceled,
  });

  final double totalSales;
  final double appProfit;
  final double vat;
  final double repCommission;
  final double deliveryFees;
  final bool isPaid;
  final bool isPending;
  final bool isCanceled;

  double get platformFees => appProfit + vat;

  double get partnerPayouts => repCommission + deliveryFees;
}

class FinancialTotals {
  const FinancialTotals({
    this.totalSales = 0,
    this.appProfit = 0,
    this.vat = 0,
    this.repCommission = 0,
    this.deliveryFees = 0,
    this.paidCount = 0,
    this.pendingCount = 0,
    this.canceledCount = 0,
    this.totalBookings = 0,
  });

  final double totalSales;
  final double appProfit;
  final double vat;
  final double repCommission;
  final double deliveryFees;
  final int paidCount;
  final int pendingCount;
  final int canceledCount;
  final int totalBookings;

  int get activeOrderCount => paidCount + pendingCount;

  double get platformFees => appProfit + vat;

  double get partnerPayouts => repCommission + deliveryFees;

  FinancialTotals merge(OrderFinancials f) {
    return FinancialTotals(
      totalSales: totalSales + f.totalSales,
      appProfit: appProfit + f.appProfit,
      vat: vat + f.vat,
      repCommission: repCommission + f.repCommission,
      deliveryFees: deliveryFees + f.deliveryFees,
      paidCount: paidCount + (f.isPaid ? 1 : 0),
      pendingCount: pendingCount + (f.isPending ? 1 : 0),
      canceledCount: canceledCount + (f.isCanceled ? 1 : 0),
      totalBookings: totalBookings + 1,
    );
  }
}

/// Unified financial calculations for admin dashboards and reports.
abstract final class FinancialEngine {
  FinancialEngine._();

  static OrderFinancials orderFinancials(OrderRecord order) {
    final paid = OrderStatusHelper.isPaid(order);
    final pending = OrderStatusHelper.isPending(order);
    final canceled = OrderStatusHelper.isCanceled(order);

    return OrderFinancials(
      totalSales: paid ? order.total.toDouble() : 0,
      appProfit: paid ? order.totalApp.toDouble() : 0,
      vat: paid ? order.totalVat.toDouble() : 0,
      repCommission: paid ? order.totalMndob.toDouble() : 0,
      deliveryFees: paid ? order.totalMndob2.toDouble() : 0,
      isPaid: paid,
      isPending: pending,
      isCanceled: canceled,
    );
  }

  /// Revenue from paid orders only.
  static double calculateRevenue(Iterable<OrderRecord> orders) {
    var total = 0.0;
    for (final order in orders) {
      total += orderFinancials(order).totalSales;
    }
    return total;
  }

  static double calculateProfit(Iterable<OrderRecord> orders) {
    var total = 0.0;
    for (final order in orders) {
      total += orderFinancials(order).appProfit;
    }
    return total;
  }

  static double calculateVAT(Iterable<OrderRecord> orders) {
    var total = 0.0;
    for (final order in orders) {
      total += orderFinancials(order).vat;
    }
    return total;
  }

  static double calculateCommission(Iterable<OrderRecord> orders) {
    var total = 0.0;
    for (final order in orders) {
      total += orderFinancials(order).repCommission;
    }
    return total;
  }

  static double calculateDeliveryFees(Iterable<OrderRecord> orders) {
    var total = 0.0;
    for (final order in orders) {
      total += orderFinancials(order).deliveryFees;
    }
    return total;
  }

  static FinancialTotals aggregate(Iterable<OrderRecord> orders) {
    var totals = const FinancialTotals();
    for (final order in orders) {
      totals = totals.merge(orderFinancials(order));
    }
    return totals;
  }

  static int countPaid(Iterable<OrderRecord> orders) =>
      orders.where(OrderStatusHelper.isPaid).length;

  static int countPending(Iterable<OrderRecord> orders) =>
      orders.where(OrderStatusHelper.isPending).length;

  static int countCanceled(Iterable<OrderRecord> orders) =>
      orders.where(OrderStatusHelper.isCanceled).length;
}
