import '/backend/backend.dart';
import '/core/finance/financial_accounting_engine.dart';

/// Maps Firestore [OrderRecord] → historical financial snapshot (no rates).
abstract final class FinancialOrderAdapter {
  FinancialOrderAdapter._();

  static num? _num(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static bool _has(Map<String, dynamic> data, String key) =>
      data.containsKey(key) && data[key] != null;

  static FinancialOrderSnapshot fromOrder(OrderRecord order) {
    final data = Map<String, dynamic>.from(order.snapshotData);
    final currency = (data['currency'] ?? data['currency_code'] ?? '')
        .toString()
        .trim();
    final method = order.hasPaymentMethod()
        ? order.paymentMethod!.name
        : (data['PaymentMethod'] ?? '').toString();

    return FinancialOrderSnapshot(
      orderId: order.reference.id,
      currency: currency.isEmpty ? 'SAR' : currency,
      paymentMethodRaw: method,
      statusCode: (data['status_code'] ?? '').toString(),
      paymentStatus: (data['payment_status'] ?? '').toString(),
      halhOrder: order.halhOrder?.name ?? (data['halh_order'] ?? '').toString(),
      halh: order.halh,
      allnow: order.allnow,
      total: _num(data, 'total'),
      totalApp: _num(data, 'total_app'),
      totalVat: _num(data, 'total_vat'),
      totalMndob: _num(data, 'total_mndob'),
      totalMndob2: _num(data, 'total_mndob2'),
      ksm: _num(data, 'ksm'),
      hasTotal: _has(data, 'total'),
      hasTotalApp: _has(data, 'total_app'),
      hasTotalVat: _has(data, 'total_vat'),
      hasTotalMndob: _has(data, 'total_mndob'),
      hasTotalMndob2: _has(data, 'total_mndob2'),
      hasKsm: _has(data, 'ksm'),
      driverId: order.mndobUser?.id,
      countryPath: order.revDolh?.path,
      orderedAt: order.dataOrder,
    );
  }

  static FinancialOrderLine analyzeOrder(OrderRecord order) =>
      FinancialAccountingEngine.analyze(fromOrder(order));
}
