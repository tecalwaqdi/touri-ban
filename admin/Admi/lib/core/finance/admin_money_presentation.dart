import '/backend/schema/order_record.dart';
import '/core/admin_currency.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/money_amount.dart';

/// Presentation-only money fields for Admin UI (no Firestore writes).
///
/// Backed exclusively by [FinancialAccountingEngine] — never treats
/// `total_mndob2` (gross) as driver net.
class AdminOrderMoneyDisplay {
  const AdminOrderMoneyDisplay({
    required this.currencyCode,
    required this.currencySymbol,
    required this.gross,
    required this.platformFee,
    required this.vat,
    required this.driverNet,
    required this.driverNetConfidence,
    required this.line,
  });

  final String currencyCode;
  final String currencySymbol;
  final MoneyAmount? gross;
  final MoneyAmount? platformFee;
  final MoneyAmount? vat;
  final MoneyAmount? driverNet;
  final FinancialConfidence driverNetConfidence;
  final FinancialOrderLine line;

  bool get hasDriverNet => driverNet != null;
  bool get driverNetIsDerived =>
      driverNet != null && driverNetConfidence == FinancialConfidence.derived;

  /// Prefer customer paid / gross base from the engine line.
  double get grossMajor =>
      gross?.majorUnits ??
      line.customerPaid?.majorUnits ??
      0;

  double get platformFeeMajor => platformFee?.majorUnits ?? 0;

  double get vatMajor => vat?.majorUnits ?? 0;

  /// Null when unprovable — callers must show "—", never 0-as-missing.
  double? get driverNetMajor => driverNet?.majorUnits;

  static AdminOrderMoneyDisplay fromOrder(OrderRecord order) {
    final line = FinancialOrderAdapter.analyzeOrder(order);
    final symbol = AdminCurrency.displaySymbolForOrder(order);
    return AdminOrderMoneyDisplay(
      currencyCode: line.currency,
      currencySymbol: symbol,
      gross: line.grossBase ?? line.customerPaid,
      platformFee: line.platformFee,
      vat: line.recordedVat,
      driverNet: line.driverNet,
      driverNetConfidence: line.confidence,
      line: line,
    );
  }

  /// Formats major money for Admin UI: `42.50 ر.س` (LTR-isolated).
  static String formatMajor(
    num? major, {
    required String symbol,
    int fractionDigits = 2,
  }) {
    if (major == null) return '—';
    final raw =
        '${major.toDouble().toStringAsFixed(fractionDigits)} $symbol';
    return '\u2066$raw\u2069';
  }

  static String formatMoneyAmount(MoneyAmount? m, {String? symbolOverride}) {
    if (m == null) return '—';
    final symbol = symbolOverride ??
        AdminCurrency.symbolByCode[m.code] ??
        m.code;
    return formatMajor(m.majorUnits, symbol: symbol);
  }
}
