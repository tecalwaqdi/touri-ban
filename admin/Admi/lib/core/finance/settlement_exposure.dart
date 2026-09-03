import '/core/finance/admin_money_presentation.dart';
import '/core/finance/money_amount.dart';

/// Client display of server settlement payment snapshots. Not a write SoT.
class SettlementExposureBucket {
  const SettlementExposureBucket({
    required this.currency,
    this.receivablesOutstandingMinor = 0,
    this.payablesOutstandingMinor = 0,
    this.collectedMinor = 0,
    this.partiallyPaidCount = 0,
    this.lockedCount = 0,
    this.settledCount = 0,
    this.receivablesAging = const {},
    this.payablesAging = const {},
  });

  final String currency;
  final int receivablesOutstandingMinor;
  final int payablesOutstandingMinor;
  final int collectedMinor;
  final int partiallyPaidCount;
  final int lockedCount;
  final int settledCount;
  final Map<String, int> receivablesAging;
  final Map<String, int> payablesAging;

  String money(int minor) {
    final m = MoneyAmount(currency: currency, minorUnits: minor);
    return AdminOrderMoneyDisplay.formatMoneyAmount(m);
  }

  static String agingBucket(DateTime? lockedAt, DateTime now) {
    if (lockedAt == null) return '>90';
    final days = now.difference(lockedAt).inDays;
    if (days <= 7) return '0-7';
    if (days <= 30) return '8-30';
    if (days <= 60) return '31-60';
    if (days <= 90) return '61-90';
    return '>90';
  }
}
