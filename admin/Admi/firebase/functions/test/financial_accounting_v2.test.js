/**
 * Unit tests for financial_accounting_v2 (no Firestore).
 */
'use strict';

const assert = require('assert');
const v2 = require('../financial_accounting_v2');

function cashCollected(overrides) {
  return {
    PaymentMethod: 'Cash',
    status_code: 'completed',
    payment_status: 'cash_collected',
    currency: 'SAR',
    total: 800,
    total_app: 120,
    total_vat: 120,
    ksm: 0,
    ...overrides,
  };
}

{
  const line = v2.analyzeOrder('a', cashCollected({}));
  assert.strictEqual(line.confidence, 'derived');
  assert.strictEqual(line.driverNetMinor, 56000);
  assert.strictEqual(line.signedCashMinor, 24000);
  assert.strictEqual(line.reconStatus, 'reconciled');
  assert.strictEqual(line.eligible, true);
}

{
  const line = v2.analyzeOrder(
    'b',
    cashCollected({
      total: 700,
      total_mndob: 560,
      total_mndob2: 800,
      ksm: 100,
    }),
  );
  assert.strictEqual(line.confidence, 'high');
  assert.strictEqual(line.signedCashMinor, 14000);
  assert.strictEqual(line.reconStatus, 'reconciled');
}

{
  const lines = [
    v2.analyzeOrder('c1', cashCollected({total: 400, total_app: 60, total_vat: 60})),
    v2.analyzeOrder('c2', cashCollected({total: 1600, total_app: 240, total_vat: 240})),
    v2.analyzeOrder('o1', {
      PaymentMethod: 'OnlinePayment',
      status_code: 'completed',
      payment_status: 'paid',
      currency: 'SAR',
      total: 3000,
      total_app: 450,
      total_vat: 450,
      total_mndob: 2100,
      total_mndob2: 3000,
      ksm: 0,
    }),
  ];
  // Simulate 5 cash / 6 online example scaled: cash liability 600, online owe 2100, net -1500
  const cashLines = [
    v2.analyzeOrder('x1', cashCollected({total: 400, total_app: 60, total_vat: 60})), // net 280, owe 120
    v2.analyzeOrder('x2', cashCollected({total: 400, total_app: 60, total_vat: 60})),
    v2.analyzeOrder('x3', cashCollected({total: 400, total_app: 60, total_vat: 60})),
    v2.analyzeOrder('x4', cashCollected({total: 400, total_app: 60, total_vat: 60})),
    v2.analyzeOrder('x5', cashCollected({total: 400, total_app: 60, total_vat: 60})),
  ];
  // 5*400=2000 held, 5*280=1400 ent, liability 600
  const onlineLines = [];
  for (let i = 0; i < 6; i++) {
    onlineLines.push(
      v2.analyzeOrder(`y${i}`, {
        PaymentMethod: 'OnlinePayment',
        status_code: 'completed',
        payment_status: 'paid',
        currency: 'SAR',
        total: 500,
        total_app: 75,
        total_vat: 75,
        total_mndob: 350,
        total_mndob2: 500,
        ksm: 0,
      }),
    );
  }
  // 6*350=2100 online entitlement
  const preview = v2.settlePreviewForDriver([...cashLines, ...onlineLines], 'SAR');
  assert.strictEqual(preview.cashHeldMinor, 200000);
  assert.strictEqual(preview.cashDriverEntitlementMinor, 140000);
  assert.strictEqual(preview.driverCashLiabilityMinor, 60000);
  assert.strictEqual(preview.companyOnlineLiabilityMinor, 210000);
  assert.strictEqual(preview.netTripSettlementMinor, -150000);
  assert.strictEqual(preview.direction, 'companyPaysDriver');
}

{
  const pending = v2.analyzeOrder('p', {
    PaymentMethod: 'Cash',
    status_code: 'completed',
    payment_status: 'pending_cash',
    currency: 'SAR',
    total: 800,
    total_app: 120,
    total_vat: 120,
    ksm: 0,
  });
  assert.strictEqual(pending.eligible, false);
  assert.strictEqual(pending.exclusionReason, 'NOT_COLLECTED');
}

{
  // Full dataset aggregation — simulate >500 by looping
  const by = {};
  for (let i = 0; i < 600; i++) {
    const line = v2.analyzeOrder(`z${i}`, cashCollected({
      total: 100,
      total_app: 15,
      total_vat: 15,
    }));
    v2.accumulate(by, line);
  }
  assert.strictEqual(by.SAR.cashCollectedTrips, 600);
  assert.strictEqual(by.SAR.cashCustomerCollectedMinor, 600 * 10000);
}

console.log('financial_accounting_v2 tests OK');
