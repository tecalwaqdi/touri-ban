'use strict';

const assert = require('assert');
const {FakeFirestore} = require('./fake_firestore');
const ledger = require('../settlement_ledger');
const payments = require('../settlement_payments');

function financeAuth(uid = 'admin1') {
  return {uid, token: {super_admin: true}};
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

async function lockedSettlement(db, extra = {}) {
  await db.doc('financial_config/runtime').set({
    allowSelfApproval: true,
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
  });
  const n = extra.trips || 5;
  for (let i = 1; i <= n; i++) {
    await db.collection('order').doc(`o${i}`).set({
      mndob_user: db.doc('user/drv1'),
      Rev_dolh: db.doc('countries/sa'),
      ...cashOrder(extra.order || {}),
    });
  }
  const d = await ledger.createSettlementDraft({
    db,
    auth: financeAuth(),
    data: {
      driverId: extra.driverId || 'drv1',
      countryId: 'countries/sa',
      currency: extra.currency || 'SAR',
      periodStart: '2026-03-01T00:00:00.000Z',
      periodEnd: '2026-05-01T00:00:00.000Z',
      idempotencyKey: extra.draftKey || 'draft-pay',
    },
  });
  const locked = await ledger.lockSettlement({
    db,
    auth: financeAuth(),
    data: {settlementId: d.settlementId, idempotencyKey: extra.lockKey || 'lock-pay'},
  });
  return locked;
}

async function createPay(db, settlementId, amountMinor, extra = {}) {
  return payments.createSettlementPayment({
    db,
    auth: extra.auth || financeAuth(),
    data: {
      settlementId,
      amountMinor,
      method: extra.method || 'bank_transfer',
      direction: extra.direction,
      externalReference: extra.ref || 'REF-1',
      receivedBy: extra.receivedBy,
      idempotencyKey: extra.idempotencyKey || `cp-${amountMinor}-${Math.random()}`,
      notes: extra.notes || '',
    },
  });
}

(async () => {
  const db0 = new FakeFirestore();
  const locked = await lockedSettlement(db0);
  const amount = locked.absoluteSettlementAmountMinor;
  assert.ok(amount > 0);

  // pending does not reduce outstanding
  {
    const p = await createPay(db0, locked.settlementId, 3000, {idempotencyKey: 'p0'});
    assert.strictEqual(p.status, 'pending');
    const s = (await db0.collection('financial_settlements').doc(locked.settlementId).get()).data();
    assert.strictEqual(s.outstandingMinor, amount);
    assert.strictEqual(s.status, 'locked');
  }

  // full payment
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'f', lockKey: 'fl'});
    const p = await createPay(db, L.settlementId, L.absoluteSettlementAmountMinor, {
      idempotencyKey: 'full',
    });
    const c = await payments.confirmSettlementPayment({
      db,
      auth: financeAuth(),
      data: {paymentId: p.paymentId, idempotencyKey: 'cf'},
    });
    assert.strictEqual(c.status, 'confirmed');
    assert.strictEqual(c.outstandingMinor, 0);
    assert.strictEqual(c.settlementStatus, 'settled');
    assert.ok(String(c.receiptNumber).startsWith('PAY-'));
  }

  // multiple partials
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'm', lockKey: 'ml'});
    const a = L.absoluteSettlementAmountMinor;
    const p1 = await createPay(db, L.settlementId, 3000, {idempotencyKey: 'm1'});
    await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p1.paymentId, idempotencyKey: 'cm1'},
    });
    let s = (await db.collection('financial_settlements').doc(L.settlementId).get()).data();
    assert.strictEqual(s.status, 'partially_paid');
    assert.strictEqual(s.outstandingMinor, a - 3000);
    const p2 = await createPay(db, L.settlementId, 2000, {idempotencyKey: 'm2'});
    await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p2.paymentId, idempotencyKey: 'cm2'},
    });
    s = (await db.collection('financial_settlements').doc(L.settlementId).get()).data();
    assert.strictEqual(s.outstandingMinor, a - 5000);
    const p3 = await createPay(db, L.settlementId, a - 5000, {idempotencyKey: 'm3'});
    const c3 = await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p3.paymentId, idempotencyKey: 'cm3'},
    });
    assert.strictEqual(c3.settlementStatus, 'settled');
    assert.strictEqual(c3.outstandingMinor, 0);
  }

  // overpayment rejected
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'o', lockKey: 'ol'});
    const p = await createPay(db, L.settlementId, L.absoluteSettlementAmountMinor + 1, {
      idempotencyKey: 'ov',
    });
    let msg;
    try {
      await payments.confirmSettlementPayment({
        db, auth: financeAuth(), data: {paymentId: p.paymentId, idempotencyKey: 'cov'},
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'PAYMENT_EXCEEDS_OUTSTANDING');
  }

  // wrong direction
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'wd', lockKey: 'wdl'});
    let msg;
    try {
      await createPay(db, L.settlementId, 1000, {
        direction: 'COMPANY_TO_DRIVER',
        idempotencyKey: 'wdir',
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'WRONG_PAYMENT_DIRECTION');
  }

  // duplicate create
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'dc', lockKey: 'dcl'});
    const a = await createPay(db, L.settlementId, 1000, {idempotencyKey: 'same-c'});
    const b = await createPay(db, L.settlementId, 1000, {idempotencyKey: 'same-c'});
    assert.strictEqual(a.paymentId, b.paymentId);
  }

  // duplicate confirm
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'df', lockKey: 'dfl'});
    const p = await createPay(db, L.settlementId, 1000, {idempotencyKey: 'pc'});
    const c1 = await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p.paymentId, idempotencyKey: 'same-conf'},
    });
    const c2 = await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p.paymentId, idempotencyKey: 'same-conf'},
    });
    assert.strictEqual(c1.receiptNumber, c2.receiptNumber);
  }

  // concurrent confirmation — only one full remaining slot
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'cc', lockKey: 'ccl'});
    const rest = L.absoluteSettlementAmountMinor;
    const p1 = await createPay(db, L.settlementId, rest, {idempotencyKey: 'cc1'});
    const p2 = await createPay(db, L.settlementId, rest, {idempotencyKey: 'cc2'});
    const results = await Promise.allSettled([
      payments.confirmSettlementPayment({
        db, auth: financeAuth('adminA'), data: {paymentId: p1.paymentId, idempotencyKey: 'ca'},
      }),
      payments.confirmSettlementPayment({
        db, auth: financeAuth('adminB'), data: {paymentId: p2.paymentId, idempotencyKey: 'cb'},
      }),
    ]);
    const ok = results.filter((r) => r.status === 'fulfilled');
    const bad = results.filter((r) => r.status === 'rejected');
    assert.strictEqual(ok.length, 1);
    assert.strictEqual(bad.length, 1);
    assert.ok(
      bad[0].reason.message === 'PAYMENT_EXCEEDS_OUTSTANDING' ||
        String(bad[0].reason.message).includes('status=settled'),
    );
  }

  // reversal restores outstanding
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'rv', lockKey: 'rvl'});
    const p = await createPay(db, L.settlementId, 4000, {idempotencyKey: 'rvp'});
    await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p.paymentId, idempotencyKey: 'rvc'},
    });
    const rev = await payments.reverseSettlementPayment({
      db, auth: financeAuth(),
      data: {paymentId: p.paymentId, reason: 'mistake', idempotencyKey: 'rvr'},
    });
    assert.strictEqual(rev.outstandingMinor, L.absoluteSettlementAmountMinor);
    const orig = (await db.collection('financial_settlement_payments').doc(p.paymentId).get()).data();
    assert.strictEqual(orig.status, 'confirmed');
    assert.strictEqual(orig.amountMinor, 4000);
  }

  // void with payments rejected
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'vp', lockKey: 'vpl'});
    const p = await createPay(db, L.settlementId, 2000, {idempotencyKey: 'vpp'});
    await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p.paymentId, idempotencyKey: 'vpc'},
    });
    let msg;
    try {
      await ledger.voidSettlement({
        db, auth: financeAuth(),
        data: {settlementId: L.settlementId, reason: 'nope', idempotencyKey: 'vpv'},
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'VOID_WITH_CONFIRMED_PAYMENTS_FORBIDDEN');
  }

  // legacy allocation + duplicate + wrong driver/currency
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'lg', lockKey: 'lgl'});
    await db.collection('company_payments').doc('cp1').set({
      driverId: 'drv1', currency: 'SAR', status: 'completed', amount: -50,
    });
    const alloc = await payments.allocateExistingPayment({
      db, auth: financeAuth(),
      data: {
        settlementId: L.settlementId,
        sourceId: 'cp1',
        amountMinor: 5000,
        idempotencyKey: 'lg1',
      },
    });
    assert.ok(alloc.receiptNumber);
    const s = (await db.collection('financial_settlements').doc(L.settlementId).get()).data();
    assert.strictEqual(s.paidConfirmedMinor, 5000);
    let dup = false;
    try {
      await payments.allocateExistingPayment({
        db, auth: financeAuth(),
        data: {settlementId: L.settlementId, sourceId: 'cp1', amountMinor: 1000, idempotencyKey: 'lg2'},
      });
    } catch (e) { dup = e.message === 'ALLOCATION_DUPLICATE'; }
    assert.ok(dup);

    await db.collection('company_payments').doc('cp2').set({
      driverId: 'other', currency: 'SAR', status: 'completed', amount: -10,
    });
    let drv = false;
    try {
      await payments.allocateExistingPayment({
        db, auth: financeAuth(),
        data: {settlementId: L.settlementId, sourceId: 'cp2', amountMinor: 1000, idempotencyKey: 'lg3'},
      });
    } catch (e) { drv = e.message === 'ALLOCATION_DRIVER_MISMATCH'; }
    assert.ok(drv);

    await db.collection('company_payments').doc('cp3').set({
      driverId: 'drv1', currency: 'EUR', status: 'completed', amount: -10,
    });
    let cur = false;
    try {
      await payments.allocateExistingPayment({
        db, auth: financeAuth(),
        data: {settlementId: L.settlementId, sourceId: 'cp3', amountMinor: 1000, idempotencyKey: 'lg4'},
      });
    } catch (e) { cur = e.message === 'ALLOCATION_CURRENCY_MISMATCH'; }
    assert.ok(cur);
  }

  // agent write denied
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'ag', lockKey: 'agl'});
    let denied = false;
    try {
      await createPay(db, L.settlementId, 1000, {auth: agentAuth(), idempotencyKey: 'agp'});
    } catch (e) { denied = e.code === 'permission-denied'; }
    assert.ok(denied);
  }

  // receipt codes unique
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'rc', lockKey: 'rcl'});
    const p1 = await createPay(db, L.settlementId, 1000, {idempotencyKey: 'rc1'});
    const p2 = await createPay(db, L.settlementId, 1000, {idempotencyKey: 'rc2'});
    const c1 = await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p1.paymentId, idempotencyKey: 'rcc1'},
    });
    const c2 = await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p2.paymentId, idempotencyKey: 'rcc2'},
    });
    assert.notStrictEqual(c1.receiptNumber, c2.receiptNumber);
  }

  // cash requires receivedBy
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'cs', lockKey: 'csl'});
    let bad = false;
    try {
      await createPay(db, L.settlementId, 1000, {method: 'cash', idempotencyKey: 'csh'});
    } catch (e) { bad = e.code === 'invalid-argument'; }
    assert.ok(bad);
    const p = await createPay(db, L.settlementId, 1000, {
      method: 'cash', receivedBy: 'cashier-1', ref: 'RCPT-1', idempotencyKey: 'csh2',
    });
    const c = await payments.confirmSettlementPayment({
      db, auth: financeAuth(), data: {paymentId: p.paymentId, idempotencyKey: 'cshc'},
    });
    assert.strictEqual(c.status, 'confirmed');
  }

  // wallet confirm disabled
  {
    const db = new FakeFirestore();
    const L = await lockedSettlement(db, {draftKey: 'w', lockKey: 'wl'});
    const p = await createPay(db, L.settlementId, 1000, {
      method: 'wallet', ref: 'W', idempotencyKey: 'w1',
    });
    let msg;
    try {
      await payments.confirmSettlementPayment({
        db, auth: financeAuth(), data: {paymentId: p.paymentId, idempotencyKey: 'wc'},
      });
    } catch (e) { msg = e.message; }
    assert.strictEqual(msg, 'WALLET_CONFIRM_DISABLED');
  }

  // aging + multi-currency never netted
  {
    const now = new Date('2026-08-22T00:00:00Z');
    const by = payments.aggregateExposure([
      {
        currency: 'SAR',
        direction: 'DRIVER_PAYS_COMPANY',
        status: 'partially_paid',
        outstandingMinor: 30400,
        paidConfirmedMinor: 50000,
        lockedAt: '2026-08-20T00:00:00Z',
      },
      {
        currency: 'EUR',
        direction: 'COMPANY_PAYS_DRIVER',
        status: 'locked',
        outstandingMinor: 210000,
        paidConfirmedMinor: 0,
        lockedAt: '2026-06-01T00:00:00Z',
      },
    ], now);
    assert.strictEqual(by.SAR.receivablesOutstandingMinor, 30400);
    assert.strictEqual(by.SAR.payablesOutstandingMinor, 0);
    assert.strictEqual(by.EUR.payablesOutstandingMinor, 210000);
    assert.strictEqual(by.EUR.receivablesOutstandingMinor, 0);
    assert.ok(by.SAR.receivablesAging['0-7'] > 0);
    assert.ok(by.EUR.payablesAging['61-90'] > 0 || by.EUR.payablesAging['>90'] > 0);
  }

  console.log('settlement_payments tests OK');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
