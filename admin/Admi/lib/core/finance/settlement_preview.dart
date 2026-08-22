import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Read-only settlement preview — never persisted.
class SettlementPreview {
  const SettlementPreview({
    required this.driverId,
    required this.currency,
    required this.from,
    required this.to,
    required this.countryPath,
    required this.includedCount,
    required this.excludedCount,
    required this.exclusionCounts,
    required this.cashHeld,
    required this.cashDriverEntitlement,
    required this.driverCashLiability,
    required this.onlineDriverEntitlement,
    required this.companyOnlineLiability,
    required this.netTripSettlement,
    required this.direction,
    required this.includedLines,
    required this.excludedLines,
  });

  final String driverId;
  final String currency;
  final DateTime? from;
  final DateTime? to;
  final String? countryPath;
  final int includedCount;
  final int excludedCount;
  final Map<String, int> exclusionCounts;
  final MoneyAmount cashHeld;
  final MoneyAmount cashDriverEntitlement;

  /// Cash held − cash entitlement (>0 driver pays company for cash side).
  final MoneyAmount driverCashLiability;
  final MoneyAmount onlineDriverEntitlement;

  /// Same as online entitlement (company owes driver).
  final MoneyAmount companyOnlineLiability;

  /// driverCashLiability − companyOnlineLiability
  final MoneyAmount netTripSettlement;

  /// driverPaysCompany | companyPaysDriver | balanced
  final String direction;

  final List<FinancialOrderLine> includedLines;
  final List<FinancialOrderLine> excludedLines;

  static SettlementPreview build({
    required String driverId,
    required String currency,
    required Iterable<FinancialOrderLine> lines,
    DateTime? from,
    DateTime? to,
    String? countryPath,
  }) {
    final code = CurrencyMoneyPolicy.normalizeCode(currency);
    final included = <FinancialOrderLine>[];
    final excluded = <FinancialOrderLine>[];
    final exclusionCounts = <String, int>{};

    var cashHeld = 0;
    var cashEnt = 0;
    var onlineEnt = 0;

    for (final line in lines) {
      if (line.currency != code) continue;
      if (line.settlementEligible) {
        included.add(line);
        if (line.channel == FinancialPaymentChannel.cash) {
          cashHeld += line.cashHeldByDriver?.minorUnits ?? 0;
          cashEnt += line.driverNet?.minorUnits ?? 0;
        } else if (line.channel == FinancialPaymentChannel.online) {
          onlineEnt += line.driverNet?.minorUnits ?? 0;
        }
      } else {
        excluded.add(line);
        final reason = line.exclusionReason ?? 'EXCLUDED';
        exclusionCounts[reason] = (exclusionCounts[reason] ?? 0) + 1;
      }
    }

    final liability = cashHeld - cashEnt;
    final companyOnline = onlineEnt;
    final net = liability - companyOnline;
    final direction = net > 0
        ? 'driverPaysCompany'
        : net < 0
            ? 'companyPaysDriver'
            : 'balanced';

    return SettlementPreview(
      driverId: driverId,
      currency: code,
      from: from,
      to: to,
      countryPath: countryPath,
      includedCount: included.length,
      excludedCount: excluded.length,
      exclusionCounts: exclusionCounts,
      cashHeld: MoneyAmount(currency: code, minorUnits: cashHeld),
      cashDriverEntitlement: MoneyAmount(currency: code, minorUnits: cashEnt),
      driverCashLiability: MoneyAmount(currency: code, minorUnits: liability),
      onlineDriverEntitlement:
          MoneyAmount(currency: code, minorUnits: onlineEnt),
      companyOnlineLiability:
          MoneyAmount(currency: code, minorUnits: companyOnline),
      netTripSettlement: MoneyAmount(currency: code, minorUnits: net),
      direction: direction,
      includedLines: included,
      excludedLines: excluded,
    );
  }
}
