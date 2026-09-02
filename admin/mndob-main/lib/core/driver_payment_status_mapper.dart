import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_record.dart';
import '/core/driver_payment_labels.dart';
import '/core/toury_system_status_codes.dart';

/// Canonical payment status mapping — Backend is source of truth.
abstract final class DriverPaymentStatusMapper {
  DriverPaymentStatusMapper._();

  static const supportedCurrencies = {'SAR', 'KGS', 'RUB', 'UZS'};

  static String normalizeStatus(OrderRecord order) {
    final raw = (order.snapshotData['payment_status'] ?? '').toString().trim();
    if (raw.isNotEmpty) {
      final lower = raw.toLowerCase();
      if (lower == 'cash_pending' || lower == 'cash_due') {
        return TourySystemStatusCodes.pendingCash;
      }
      return lower;
    }
    final cashStatus =
        (order.snapshotData['cash_collection_status'] ?? '').toString().trim();
    if (cashStatus == 'collected') {
      return TourySystemStatusCodes.cashCollected;
    }

    final halh = (order.snapshotData['halh_order'] ?? order.halh ?? '')
        .toString()
        .toLowerCase();
    if (halh.contains('paid') || halh == 'مدفوع') {
      return TourySystemStatusCodes.paid;
    }
    if (halh.contains('fail')) return TourySystemStatusCodes.failed;
    if (halh.contains('refund')) return TourySystemStatusCodes.refunded;

    if (DriverPaymentLabels.isCash(order.paymentMethod)) {
      return TourySystemStatusCodes.pendingCash;
    }
    return TourySystemStatusCodes.unpaid;
  }

  /// Cash-method only — online `paid` must not count as cash collected.
  static bool isCashCollected(OrderRecord order) {
    if (!DriverPaymentLabels.isCash(
      order.paymentMethod,
      fallbackRaw: order.snapshotData['PaymentMethod']?.toString(),
    )) {
      return false;
    }
    if (order.snapshotData['cashCollectedByDriver'] == true) return true;
    final cashStatus =
        (order.snapshotData['cash_collection_status'] ?? '').toString().trim();
    if (cashStatus == 'collected') return true;
    return normalizeStatus(order) == TourySystemStatusCodes.cashCollected;
  }

  static bool isCashCollectionPending(OrderRecord order) {
    if (!DriverPaymentLabels.isCash(
      order.paymentMethod,
      fallbackRaw: order.snapshotData['PaymentMethod']?.toString(),
    )) {
      return false;
    }
    return !isCashCollected(order) &&
        normalizeStatus(order) == TourySystemStatusCodes.pendingCash;
  }

  static bool isElectronic(PaymentMethod? method) =>
      !DriverPaymentLabels.isCash(method);

  /// Driver app must never mutate electronic payment_status.
  static bool driverMayWritePaymentStatus(PaymentMethod? method) =>
      DriverPaymentLabels.isCash(method);

  static String displayKey(String status) {
    switch (status.toLowerCase()) {
      case TourySystemStatusCodes.pendingCash:
      case 'cash_pending':
      case 'cash_due':
      case 'pending':
        return 'Payment pending';
      case TourySystemStatusCodes.cashCollected:
        return 'Cash collected';
      case 'authorized':
        return 'Authorized';
      case 'captured':
        return 'Captured';
      case TourySystemStatusCodes.paid:
        return 'Paid';
      case TourySystemStatusCodes.failed:
        return 'Payment failed';
      case TourySystemStatusCodes.refunded:
        return 'Refunded';
      case 'disputed':
        return 'Disputed';
      case TourySystemStatusCodes.processing:
        return 'Processing';
      default:
        return 'Unpaid';
    }
  }
}

/// Financial breakdown read from order (Backend fields only).
class DriverTripFinance {
  const DriverTripFinance({
    required this.gross,
    required this.commission,
    required this.tax,
    required this.net,
    required this.currency,
  });

  final double gross;
  final double commission;
  final double tax;
  final double net;
  final String currency;

  static DriverTripFinance fromOrder(OrderRecord order) {
    final data = order.snapshotData;
    double numOf(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    final currency = (data['currency'] ?? data['Rev_dolh'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    final safeCurrency = DriverPaymentStatusMapper.supportedCurrencies
            .contains(currency)
        ? currency
        : currency.isEmpty
            ? 'SAR'
            : currency;

    final gross = numOf(data['total'] ?? order.total);
    final commission = numOf(data['total_app'] ?? data['ksm']);
    final tax = numOf(data['total_vat'] ?? data['vat']);
    final net = numOf(data['total_mndob'] ?? data['total_mndob2']);
    final computedNet = net > 0 ? net : (gross - commission - tax);

    return DriverTripFinance(
      gross: gross,
      commission: commission,
      tax: tax,
      net: computedNet < 0 ? 0 : computedNet,
      currency: safeCurrency,
    );
  }
}
