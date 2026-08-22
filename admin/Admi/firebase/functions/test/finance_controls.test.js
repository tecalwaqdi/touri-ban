'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {FakeFirestore} = require('./fake_firestore');
const ledger = require('../settlement_ledger');
const payments = require('../settlement_payments');
const controls = require('../finance_controls');
const driverLedger = require('../driver_ledger');
const {buildRunningBalance, compareLedgerKeys} = require('../driver_ledger');

function superAuth(uid = 'super1') {
  return {uid, token: {super_admin: true}};
}
function financeAuth(uid = 'fin1') {
  return {uid, token: {finance: true}};
}
function agentAuth() {
  return {uid: 'agent1', token: {country_admin: true, country_id: 'countries/sa'}};
}

function cashOrder(overrides = {}) {
  return {
    PaymentMethod: 'Cash',
    status_code: 'completed',
    payment_status: 'cash_collected',
    currency: 'SAR',
    total: 100,
    total_app: 15,
    total_vat: 15,
    ksm: 0,
    data_order: new Date('2026-04-01T10:00:00Z'),
    ...overrides,
  };
}

function cash804(overrides = {}) {
  return cashOrder({
    total: 200,
    total_app: 80.4,
    total_vat: 80.4,
    total_mndob: 39.2,
    total_mndob2: 200,
    ...overrides,
  });
}

async function seedOrders(db, n, factory = cashOrder, driver = 'drv1') {
  for (let i = 1; i <= n; i++) {
    await db.collection('order').doc(`o${i}`).set({
      mndob_user: db.doc(`user/${driver}`),
      Rev_dolh: db.doc('countries/sa'),
      ...factory(),
    });
  }
}

async function twoPartyLocked(db, extra = {}) {
  await db.doc('financial_config/runtime').set({
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
  });
  const maker = extra.maker || financeAuth('maker');
  const checker = extra.checker || superAuth('checker');
  const factory = extra.factory || cashOrder;
  const n = extra.trips || 5;
  await seedOrders(db, n, factory, extra.driverId || 'drv1');
  const d = await ledger.createSettlementDraft({
    db,
    auth: maker,
    data: {
      driverId: extra.driverId || 'drv1',
      countryId: 'countries/sa',
      currency: extra.currency || 'SAR',
      periodStart: extra.periodStart || '2026-03-01T00:00:00.000Z',
      periodEnd: extra.periodEnd || '2026-05-01T00:00:00.000Z',
      idempotencyKey: extra.draftKey || 'd1',
    },
  });
  const locked = await ledger.lockSettlement({
    db,
    auth: checker,
    data: {settlementId: d.settlementId, idempotencyKey: extra.lockKey || 'l1'},
  });
  return {locked, maker, checker, draft: d};
}

(async () => {
  // running balance convention + same timestamp tie-break
  {
    const rows = buildRunningBalance([
      {id: 'b', at: '2026-08-01T00:00:00.000Z', type: 'adjustment', debitMinor: 10, creditMinor: 0},
      {id: 'a', at: '2026-08-01T00:00:00.000Z', type: 'cash_trip', debitMinor: 100, creditMinor: 0},
      {id: 'c', at: '2026-08-01T00:00:00.000Z', type: 'cash_trip', debitMinor: 5, creditMinor: 0},
    ]);
    assert.strictEqual(rows[0].id, 'a');
    assert.strictEqual(rows[1].id, 'c');
    assert.strictEqual(rows[2].id, 'b');
    assert.strictEqual(rows[2].runningBalanceMinor, 115);
    assert.strictEqual(rows[2].runningLabel, 'DEBIT_RECEIVABLE');
    assert.ok(compareLedgerKeys(rows[0], rows[1]) < 0);
  }

  // mixed currency isolation
  {
    const sar = buildRunningBalance([
      {id: '1', at: '2026-08-01T00:00:00.000Z', type: 'cash_trip', debitMinor: 100, creditMinor: 0},
    ]);
    const eur = buildRunningBalance([
      {id: '2', at: '2026-08-01T00:00:00.000Z', type: 'online_trip', debitMinor: 0, creditMinor: 50},
    ]);
    assert.strictEqual(sar[0].runningBalanceMinor, 100);
    assert.strictEqual(eur[0].runningBalanceMinor, -50);
    assert.notStrictEqual(sar[0].runningBalanceMinor + eur[0].runningBalanceMinor, sar[0].runningBalanceMinor);
  }

  // maker cannot approve own item
  {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
    });
    await seedOrders(db, 2);
    const maker = financeAuth('maker');
    const d = await ledger.createSettlementDraft({
      db, auth: maker,
      data: {
        driverId: 'drv1', countryId: 'countries/sa', currency: 'SAR',
        periodStart: '2026-03-01T00:00:00.000Z',
        periodEnd: '2026-05-01T00:00:00.000Z',
        idempotencyKey: 'self-lock',
      },
    });
    let msg;
    try {
      await ledger.lockSettlement({
        db, auth: maker,
        data: {settlementId: d.settlementId, idempotencyKey: 'self-lock-2'},
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'SELF_APPROVAL_FORBIDDEN');
  }

  // approver can approve
  {
    const db = new FakeFirestore();
    const {locked} = await twoPartyLocked(db);
    assert.strictEqual(locked.status, 'locked');
  }

  // reversal math: due 804, confirm 500 → 304; reverse 200 → 504
  {
    const db = new FakeFirestore();
    const {locked, maker, checker} = await twoPartyLocked(db, {factory: cash804});
    assert.strictEqual(locked.absoluteSettlementAmountMinor, 80400);
    const p = await payments.createSettlementPayment({
      db, auth: maker,
      data: {
        settlementId: locked.settlementId,
        amountMinor: 50000,
        method: 'bank_transfer',
        externalReference: 'TR-500',
        idempotencyKey: 'p500',
      },
    });
    const c = await payments.confirmSettlementPayment({
      db, auth: checker,
      data: {paymentId: p.paymentId, idempotencyKey: 'c500'},
    });
    assert.strictEqual(c.outstandingMinor, 30400);
    const orig = (await db.collection('financial_settlement_payments').doc(p.paymentId).get()).data();
    assert.strictEqual(orig.status, 'confirmed');
    const rev = await payments.reverseSettlementPayment({
      db, auth: checker,
      data: {
        paymentId: p.paymentId,
        reason: 'partial reverse 200',
        reversalAmountMinor: 20000,
        idempotencyKey: 'r200',
      },
    });
    assert.strictEqual(rev.outstandingMinor, 50400);
    const still = (await db.collection('financial_settlement_payments').doc(p.paymentId).get()).data();
    assert.strictEqual(still.status, 'confirmed');
    assert.strictEqual(still.amountMinor, 50000);
  }

  // period close with blocker rejected
  {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    });
    await db.collection('order').doc('inc1').set({
      mndob_user: db.doc('user/drv1'),
      Rev_dolh: db.doc('countries/sa'),
      PaymentMethod: 'Cash',
      status_code: 'completed',
      payment_status: 'cash_collected',
      currency: 'SAR',
      data_order: new Date('2026-08-10T10:00:00Z'),
    });
    const p = await controls.createFinancialPeriod({
      db, auth: superAuth(),
      data: {
        name: 'August 2026',
        countryRef: 'countries/sa',
        currency: 'SAR',
        startAt: '2026-08-01T00:00:00.000Z',
        endAt: '2026-09-01T00:00:00.000Z',
      },
    });
    let msg;
    try {
      await controls.closeFinancialPeriod({
        db, auth: superAuth(),
        data: {periodId: p.periodId, reason: 'month end'},
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'PERIOD_CLOSE_BLOCKED');
  }

  // period close clean succeeds
  {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    });
    const p = await controls.createFinancialPeriod({
      db, auth: superAuth(),
      data: {
        name: 'September 2026',
        countryRef: 'all',
        currency: 'all',
        startAt: '2026-09-01T00:00:00.000Z',
        endAt: '2026-10-01T00:00:00.000Z',
      },
    });
    const r = await controls.closeFinancialPeriod({
      db, auth: superAuth(),
      data: {periodId: p.periodId, reason: 'clean close'},
    });
    assert.strictEqual(r.status, 'closed');
  }

  // closed period rejects backdated posting
  {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    });
    const p = await controls.createFinancialPeriod({
      db, auth: superAuth(),
      data: {
        name: 'April 2026',
        countryRef: 'countries/sa',
        currency: 'SAR',
        startAt: '2026-04-01T00:00:00.000Z',
        endAt: '2026-05-01T00:00:00.000Z',
      },
    });
    await controls.closeFinancialPeriod({
      db, auth: superAuth(),
      data: {periodId: p.periodId, reason: 'closed'},
    });
    await seedOrders(db, 1);
    let msg;
    try {
      await ledger.createSettlementDraft({
        db, auth: financeAuth('maker'),
        data: {
          driverId: 'drv1', countryId: 'countries/sa', currency: 'SAR',
          periodStart: '2026-04-01T00:00:00.000Z',
          periodEnd: '2026-05-01T00:00:00.000Z',
          idempotencyKey: 'closed-post',
        },
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'PERIOD_CLOSED');
  }

  // reopen with reason
  {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    });
    const p = await controls.createFinancialPeriod({
      db, auth: superAuth(),
      data: {
        name: 'May 2026',
        startAt: '2026-05-01T00:00:00.000Z',
        endAt: '2026-06-01T00:00:00.000Z',
      },
    });
    await controls.closeFinancialPeriod({
      db, auth: superAuth(),
      data: {periodId: p.periodId, reason: 'done'},
    });
    let denied;
    try {
      await controls.reopenFinancialPeriod({
        db, auth: financeAuth('fin'),
        data: {periodId: p.periodId, reason: 'fix'},
      });
    } catch (e) { denied = e.message; }
    assert.strictEqual(denied, 'SUPERADMIN_REQUIRED');
    const re = await controls.reopenFinancialPeriod({
      db, auth: superAuth(),
      data: {periodId: p.periodId, reason: 'need posting'},
    });
    assert.strictEqual(re.status, 'reopened');
    assert.strictEqual(re.eventType, 'PERIOD_REOPENED');
    const found = await controls.searchFinanceAudit({
      db, auth: superAuth(),
      data: {eventType: 'PERIOD_REOPENED'},
    });
    assert.ok(found.count >= 1);
  }

  // adjustment approved + reversal + opening balance
  {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    });
    const maker = financeAuth('maker');
    const checker = superAuth('checker');
    const adj = await controls.createAdjustmentDraft({
      db, auth: maker,
      data: {
        driverId: 'drv1',
        countryRef: 'countries/sa',
        currency: 'SAR',
        amountMinor: 2500,
        direction: 'DRIVER_TO_COMPANY',
        reasonCode: 'correction',
        notes: 'fix',
        effectiveDate: '2026-08-01T00:00:00.000Z',
      },
    });
    const before = await controls.loadDriverStatement({
      db, auth: checker, data: {driverId: 'drv1', currency: 'SAR'},
    });
    assert.strictEqual(before.outstandingMinor, 0);
    const ap = await controls.approveAdjustment({
      db, auth: checker, data: {adjustmentId: adj.adjustmentId},
    });
    assert.strictEqual(ap.status, 'approved');
    const after = await controls.loadDriverStatement({
      db, auth: checker, data: {driverId: 'drv1', currency: 'SAR'},
    });
    assert.strictEqual(after.approvedAdjustmentsMinor, 2500);
    assert.strictEqual(after.outstandingMinor, 2500);
    await controls.reverseAdjustment({
      db, auth: checker,
      data: {adjustmentId: adj.adjustmentId, reason: 'undo'},
    });
    const undone = await controls.loadDriverStatement({
      db, auth: checker, data: {driverId: 'drv1', currency: 'SAR'},
    });
    assert.strictEqual(undone.outstandingMinor, 0);

    const ob = await controls.createOpeningBalance({
      db, auth: maker,
      data: {
        driverId: 'drv1',
        countryRef: 'countries/sa',
        currency: 'SAR',
        amountMinor: 1000,
        direction: 'COMPANY_TO_DRIVER',
        effectiveDate: '2026-01-01T00:00:00.000Z',
        reference: 'OB-1',
      },
    });
    await controls.approveAdjustment({
      db, auth: checker, data: {adjustmentId: ob.adjustmentId},
    });
    const withOb = await controls.loadDriverStatement({
      db, auth: checker, data: {driverId: 'drv1', currency: 'SAR'},
    });
    assert.strictEqual(withOb.openingBalanceMinor, -1000);
    assert.strictEqual(withOb.outstandingLabel, 'CREDIT_PAYABLE');
  }

  // source changed after settlement lock
  {
    const db = new FakeFirestore();
    const {locked} = await twoPartyLocked(db, {trips: 2});
    const ok = await controls.verifySettlementAgainstSource({
      db, auth: superAuth(), data: {settlementId: locked.settlementId},
    });
    assert.strictEqual(ok.changed, false);
    await db.collection('order').doc('o1').update({total: 180});
    const bad = await controls.verifySettlementAgainstSource({
      db, auth: superAuth(), data: {settlementId: locked.settlementId},
    });
    assert.strictEqual(bad.flag, 'SOURCE_CHANGED_AFTER_LOCK');
    assert.strictEqual(bad.mutated, false);
    const still = (await db.collection('financial_settlements').doc(locked.settlementId).get()).data();
    assert.strictEqual(still.lockedHash, locked.lockedHash);
  }

  // orphan detection + audit search
  {
    const db = new FakeFirestore();
    await db.collection('financial_settlement_claims').doc('ghost').set({
      orderId: 'ghost',
      settlementId: 'missing',
    });
    const orphans = await controls.detectOrphans({db, auth: superAuth(), data: {}});
    assert.strictEqual(orphans.repair, false);
    assert.ok(orphans.items.some((i) => i.code === 'ORPHAN_CLAIM' && i.count >= 1));
  }

  // audit search by actor
  {
    const db = new FakeFirestore();
    await twoPartyLocked(db, {trips: 1});
    const r = await controls.searchFinanceAudit({
      db, auth: superAuth(), data: {actorUid: 'checker', eventType: 'LOCKED'},
    });
    assert.ok(r.count >= 1);
    assert.ok(r.events[0].settlementCode.startsWith('STL-'));
  }

  // period totals
  {
    const db = new FakeFirestore();
    await seedOrders(db, 3, () => cashOrder({data_order: new Date('2026-08-05T00:00:00Z')}));
    const p = await controls.createFinancialPeriod({
      db, auth: superAuth(),
      data: {
        name: 'August dash',
        startAt: '2026-08-01T00:00:00.000Z',
        endAt: '2026-09-01T00:00:00.000Z',
        currency: 'all',
      },
    });
    const dash = await controls.periodDashboard({
      db, auth: superAuth(), data: {periodId: p.periodId},
    });
    assert.strictEqual(dash.byCurrency.SAR.totalTrips, 3);
    assert.strictEqual(dash.byCurrency.SAR.eligible, 3);
  }

  // agent scope: cannot write
  {
    const db = new FakeFirestore();
    let msg;
    try {
      await controls.createAdjustmentDraft({
        db, auth: agentAuth(),
        data: {
          driverId: 'drv1', countryRef: 'countries/sa', currency: 'SAR',
          amountMinor: 1, direction: 'DRIVER_TO_COMPANY', reasonCode: 'other',
        },
      });
    } catch (e) { msg = e.message; }
    assert.ok(String(msg).includes('SuperAdmin or Finance') || msg === 'Settlement writes require SuperAdmin or Finance.');
  }

  // client direct write denied in rules
  {
    const rules = fs.readFileSync(
      path.join(__dirname, '../../firestore.rules'),
      'utf8',
    );
    for (const col of [
      'financial_periods',
      'financial_adjustments',
      'financial_config',
      'financial_audit_events',
      'financial_settlements',
      'financial_settlement_payments',
    ]) {
      assert.ok(rules.includes(`match /${col}/{id}`), col);
    }
    assert.ok(rules.includes('allow create, update, delete: if false;'));
  }

  // feature flags block settlement writes by default
  {
    const db = new FakeFirestore();
    await seedOrders(db, 1);
    let msg;
    try {
      await ledger.createSettlementDraft({
        db, auth: financeAuth('maker'),
        data: {
          driverId: 'drv1', countryId: 'countries/sa', currency: 'SAR',
          periodStart: '2026-03-01T00:00:00.000Z',
          periodEnd: '2026-05-01T00:00:00.000Z',
          idempotencyKey: 'flag-off',
        },
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'FEATURE_FLAG_DISABLED');
  }

  // accountant home + reconciliation + report csv
  {
    const db = new FakeFirestore();
    await seedOrders(db, 1);
    const home = await controls.accountantHome({db, auth: superAuth(), now: new Date('2026-04-01T12:00:00Z')});
    assert.ok(home.today);
    assert.ok(home.actionRequired);
    assert.ok(home.badges);
    assert.strictEqual(home.policy.allowSelfApproval, false);
    assert.strictEqual(home.featureFlags.FINANCIAL_SETTLEMENT_WRITES_ENABLED, false);
    assert.ok(home.warnings.some((w) => String(w).includes('No independent finance approver')));
    assert.strictEqual(home.independentApproverConfigured, false);
    const recon = await controls.scanFinancialExceptions({db, auth: superAuth(), data: {}});
    assert.ok(Array.isArray(recon.items));
    const inc = await controls.listIncompleteOrders({db, auth: superAuth(), data: {}});
    assert.ok(inc.orders);
    const csv = await controls.financialReport({
      db, auth: superAuth(),
      data: {type: 'reconciliation_exceptions'},
    });
    assert.ok(csv.csv.includes('not a tax invoice'));
    assert.strictEqual(csv.pdf, null);
  }

  // company position does not mix currencies
  {
    const db = new FakeFirestore();
    await db.collection('order').doc('sar').set({
      mndob_user: db.doc('user/drv1'),
      Rev_dolh: db.doc('countries/sa'),
      ...cashOrder(),
    });
    await db.collection('order').doc('eur').set({
      mndob_user: db.doc('user/drv1'),
      Rev_dolh: db.doc('countries/sa'),
      ...cashOrder({currency: 'EUR', data_order: new Date('2026-04-02T00:00:00Z')}),
    });
    const pos = await controls.aggregateCompanyPosition({db, auth: superAuth(), data: {}});
    assert.ok(pos.byCurrency.SAR);
    assert.ok(pos.byCurrency.EUR);
    assert.strictEqual(pos.mixedCurrencies, false);
  }

  // driver_ledger paymentEntry sanity
  {
    const e = driverLedger.paymentEntry({
      paymentId: 'p1',
      status: 'confirmed',
      amountMinor: 500,
      direction: 'DRIVER_TO_COMPANY',
      confirmedAt: '2026-08-01T00:00:00.000Z',
      receiptNumber: 'PAY-1',
    });
    assert.strictEqual(e.creditMinor, 500);
    assert.strictEqual(e.debitMinor, 0);
  }

  console.log('finance_controls tests OK');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
