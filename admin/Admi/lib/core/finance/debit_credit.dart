/// Company-books debit/credit convention (per driver + currency).
///
/// runningBalance > 0 → Debit / Receivable (driver owes company)
/// runningBalance < 0 → Credit / Payable (company owes driver)
///
/// running = cumulative (debitMinor - creditMinor). Never mix currencies.
library;

const kFinanceTypeRank = <String, int>{
  'opening_balance': 10,
  'cash_trip': 20,
  'online_trip': 21,
  'settlement_lock': 30,
  'adjustment': 40,
  'settlement_payment': 50,
  'reversal': 60,
};

int financeTypeRank(String type) => kFinanceTypeRank[type] ?? 99;

int compareFinanceLedgerKeys({
  required String at,
  required String type,
  required String id,
  required String otherAt,
  required String otherType,
  required String otherId,
}) {
  final ta = DateTime.tryParse(at)?.millisecondsSinceEpoch ?? 0;
  final tb = DateTime.tryParse(otherAt)?.millisecondsSinceEpoch ?? 0;
  if (ta != tb) return ta - tb;
  final ra = financeTypeRank(type) - financeTypeRank(otherType);
  if (ra != 0) return ra;
  return id.compareTo(otherId);
}

class FinanceLedgerLine {
  const FinanceLedgerLine({
    required this.id,
    required this.at,
    required this.type,
    required this.reference,
    required this.debitMinor,
    required this.creditMinor,
    this.runningBalanceMinor = 0,
  });

  final String id;
  final String at;
  final String type;
  final String reference;
  final int debitMinor;
  final int creditMinor;
  final int runningBalanceMinor;

  int get signedDelta => debitMinor - creditMinor;

  String get runningLabel {
    if (runningBalanceMinor > 0) return 'DEBIT_RECEIVABLE';
    if (runningBalanceMinor < 0) return 'CREDIT_PAYABLE';
    return 'BALANCED';
  }
}

List<FinanceLedgerLine> buildRunningBalance(List<FinanceLedgerLine> entries) {
  final sorted = [...entries]
    ..sort(
      (a, b) => compareFinanceLedgerKeys(
        at: a.at,
        type: a.type,
        id: a.id,
        otherAt: b.at,
        otherType: b.type,
        otherId: b.id,
      ),
    );
  var running = 0;
  return [
    for (final e in sorted)
      FinanceLedgerLine(
        id: e.id,
        at: e.at,
        type: e.type,
        reference: e.reference,
        debitMinor: e.debitMinor,
        creditMinor: e.creditMinor,
        runningBalanceMinor: running += e.signedDelta,
      ),
  ];
}
