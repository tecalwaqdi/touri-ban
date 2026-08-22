import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/core/finance/debit_credit.dart';

void main() {
  test('debit increases receivable; credit is payable', () {
    final rows = buildRunningBalance([
      const FinanceLedgerLine(
        id: 'open',
        at: '2026-01-01T00:00:00.000Z',
        type: 'opening_balance',
        reference: 'OB',
        debitMinor: 100,
        creditMinor: 0,
      ),
      const FinanceLedgerLine(
        id: 'pay',
        at: '2026-01-02T00:00:00.000Z',
        type: 'settlement_payment',
        reference: 'PAY',
        debitMinor: 0,
        creditMinor: 40,
      ),
    ]);
    expect(rows.last.runningBalanceMinor, 60);
    expect(rows.last.runningLabel, 'DEBIT_RECEIVABLE');
  });

  test('same timestamp uses type rank then id', () {
    final rows = buildRunningBalance([
      const FinanceLedgerLine(
        id: 'b',
        at: '2026-08-01T00:00:00.000Z',
        type: 'adjustment',
        reference: 'adj',
        debitMinor: 10,
        creditMinor: 0,
      ),
      const FinanceLedgerLine(
        id: 'a',
        at: '2026-08-01T00:00:00.000Z',
        type: 'cash_trip',
        reference: 'trip',
        debitMinor: 100,
        creditMinor: 0,
      ),
    ]);
    expect(rows.first.id, 'a');
    expect(rows.last.runningBalanceMinor, 110);
  });

  test('mixed currencies stay isolated', () {
    final sar = buildRunningBalance([
      const FinanceLedgerLine(
        id: 's',
        at: '2026-08-01T00:00:00.000Z',
        type: 'cash_trip',
        reference: 's',
        debitMinor: 80400,
        creditMinor: 0,
      ),
    ]);
    final eur = buildRunningBalance([
      const FinanceLedgerLine(
        id: 'e',
        at: '2026-08-01T00:00:00.000Z',
        type: 'online_trip',
        reference: 'e',
        debitMinor: 0,
        creditMinor: 210000,
      ),
    ]);
    expect(sar.single.runningLabel, 'DEBIT_RECEIVABLE');
    expect(eur.single.runningLabel, 'CREDIT_PAYABLE');
  });
}
