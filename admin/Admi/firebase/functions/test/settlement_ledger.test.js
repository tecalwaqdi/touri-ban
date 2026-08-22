'use strict';

const assert = require('assert');
const {FakeFirestore} = require('./fake_firestore');
const ledger = require('../settlement_ledger');

function financeAuth(uid = 'admin1') {
  return {uid, token: {super_admin: true}};
}

function agentAuth() {
  return {uid: 'agent1', token: {country_admin: true, country_id: 'countries/sa'}};
}

function cashOrder(id, overrides = {}) {
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

function seedOrder(db, id, data) {
  return db.collection('order').doc(id).set({
    mndob_user: db.doc('user/drv1'),
    Rev_dolh: db.doc('countries/sa'),
    ...data,
  });
}

async function seedFiveCash(db) {
  for (let i = 1; i <= 5; i++) {
    await seedOrder(db, `o${i}`, cashOrder(`o${i}`));
  }
}

const period = {
  periodStart: '2026-03-01T00:00:00.000Z',
  periodEnd: '2026-05-01T00:00:00.000Z',
};

async function draft(db, extra = {}) {
  await db.doc('financial_config/runtime').set({
    allowSelfApproval: true,
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
  });
  return ledger.createSettlementDraft({
    db,
    auth: extra.auth || financeAuth(),
    data: {
      driverId: 'drv1',
      countryId: 'countries/sa',
      currency: extra.currency || 'SAR',
      ...period,
      idempotencyKey: extra.idempotencyKey || 'draft-1',
      ...extra.data,
    },
  });
}

(async () => {
  // create draft
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const r = await draft(db);
    assert.strictEqual(r.status, 'draft');
    assert.strictEqual(r.eligibleTripCount, 5);
    assert.ok(r.settlementCode.startsWith('STL-'));
    const snap = await db.collection('financial_settlements').doc(r.settlementId).get();
    assert.strictEqual(snap.data().status, 'draft');
    const claims = await db.collection('financial_settlement_claims').get();
    assert.strictEqual(claims.size, 0, 'draft must not claim');
  }

  // duplicate draft idempotency
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const a = await draft(db, {idempotencyKey: 'same'});
    const b = await draft(db, {idempotencyKey: 'same'});
    assert.strictEqual(a.settlementId, b.settlementId);
    const all = await db.collection('financial_settlements').get();
    assert.strictEqual(all.size, 1);
  }

  // lock
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    const locked = await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'lock-1'},
    });
    assert.strictEqual(locked.status, 'locked');
    assert.strictEqual(locked.eligibleTripCount, 5);
    const claims = await db.collection('financial_settlement_claims').get();
    assert.strictEqual(claims.size, 5);
    const lines = await db
      .collection('financial_settlements')
      .doc(d.settlementId)
      .collection('lines')
      .get();
    assert.strictEqual(lines.size, 5);
  }

  // duplicate lock
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    const a = await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'lock-dup'},
    });
    const b = await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'lock-dup'},
    });
    assert.strictEqual(a.settlementId, b.settlementId);
    const claims = await db.collection('financial_settlement_claims').get();
    assert.strictEqual(claims.size, 5);
  }

  // double-order claim — two drafts, second lock fails
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d1 = await draft(db, {idempotencyKey: 'a'});
    const d2 = await draft(db, {idempotencyKey: 'b'});
    await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d1.settlementId, idempotencyKey: 'l1'},
    });
    let failed = false;
    try {
      await ledger.lockSettlement({
        db,
        auth: financeAuth(),
        data: {settlementId: d2.settlementId, idempotencyKey: 'l2'},
      });
    } catch (e) {
      failed = true;
      assert.strictEqual(e.code, 'already-exists');
    }
    assert.ok(failed);
    const s2 = await db.collection('financial_settlements').doc(d2.settlementId).get();
    assert.strictEqual(s2.data().status, 'draft', 'failed lock must not partial-lock');
  }

  // stale preview
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    await db.collection('order').doc('o1').set(
      {payment_status: 'pending_cash'},
      {merge: true},
    );
    let code;
    try {
      await ledger.lockSettlement({
        db,
        auth: financeAuth(),
        data: {settlementId: d.settlementId, idempotencyKey: 'stale'},
      });
    } catch (e) {
      code = e.message;
    }
    assert.strictEqual(code, 'SETTLEMENT_PREVIEW_STALE');
  }

  // cancelled order excluded / lock fails
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    await db.collection('order').doc('o2').set(
      {status_code: 'cancelled_by_customer'},
      {merge: true},
    );
    let code;
    try {
      await ledger.lockSettlement({
        db,
        auth: financeAuth(),
        data: {settlementId: d.settlementId, idempotencyKey: 'can'},
      });
    } catch (e) {
      code = e.message;
    }
    assert.strictEqual(code, 'SETTLEMENT_PREVIEW_STALE');
  }

  // pending cash excluded from draft
  {
    const db = new FakeFirestore();
    await seedOrder(db, 'p1', cashOrder('p1', {payment_status: 'pending_cash'}));
    const d = await draft(db);
    assert.strictEqual(d.eligibleTripCount, 0);
  }

  // INCOMPLETE excluded
  {
    const db = new FakeFirestore();
    await seedOrder(
      db,
      'inc1',
      cashOrder('inc1', {total: 70, ksm: 10, total_app: 15, total_vat: 15}),
    );
    const d = await draft(db);
    assert.strictEqual(d.eligibleTripCount, 0);
    assert.ok(d.excludedTripCount >= 1);
  }

  // DERIVED allowed
  {
    const db = new FakeFirestore();
    await seedOrder(db, 'der1', cashOrder('der1')); // no total_mndob → derived
    const d = await draft(db);
    assert.strictEqual(d.eligibleTripCount, 1);
    assert.ok(d.derivedCount >= 1);
  }

  // multi currency rejected from SAR settlement
  {
    const db = new FakeFirestore();
    await seedOrder(db, 'sar1', cashOrder('sar1'));
    await seedOrder(db, 'eur1', cashOrder('eur1', {currency: 'EUR'}));
    const d = await draft(db, {currency: 'SAR'});
    assert.strictEqual(d.eligibleTripCount, 1);
    assert.strictEqual(d.currency, 'SAR');
  }

  // wrong driver rejected
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    await db.collection('order').doc('o1').set(
      {mndob_user: db.doc('user/other')},
      {merge: true},
    );
    let code;
    try {
      await ledger.lockSettlement({
        db,
        auth: financeAuth(),
        data: {settlementId: d.settlementId, idempotencyKey: 'wd'},
      });
    } catch (e) {
      code = e.message;
    }
    assert.strictEqual(code, 'SETTLEMENT_PREVIEW_STALE');
  }

  // agent write denied
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    let denied = false;
    try {
      await draft(db, {auth: agentAuth()});
    } catch (e) {
      denied = e.code === 'permission-denied';
    }
    assert.ok(denied);
  }

  // superadmin allowed — already covered by draft

  // mark settled requires evidence / amount mismatch
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    const locked = await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'l'},
    });
    let missing = false;
    try {
      await ledger.markSettlementSettled({
        db,
        auth: financeAuth(),
        data: {
          settlementId: d.settlementId,
          idempotencyKey: 's1',
          settlementMethod: 'cash',
        },
      });
    } catch (e) {
      missing = e.code === 'invalid-argument';
    }
    assert.ok(missing);

    let mismatch = false;
    try {
      await ledger.markSettlementSettled({
        db,
        auth: financeAuth(),
        data: {
          settlementId: d.settlementId,
          idempotencyKey: 's2',
          settlementMethod: 'bank_transfer',
          paymentReference: 'TX-1',
          amountMinor: 1,
        },
      });
    } catch (e) {
      mismatch = e.message === 'AMOUNT_MISMATCH';
    }
    assert.ok(mismatch);

    const settled = await ledger.markSettlementSettled({
      db,
      auth: financeAuth(),
      data: {
        settlementId: d.settlementId,
        idempotencyKey: 's3',
        settlementMethod: 'bank_transfer',
        paymentReference: 'TX-OK',
        amountMinor: locked.absoluteSettlementAmountMinor,
      },
    });
    assert.strictEqual(settled.status, 'settled');
  }

  // void locked releases claims
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'lv'},
    });
    const v = await ledger.voidSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, reason: 'test void', idempotencyKey: 'v1'},
    });
    assert.strictEqual(v.status, 'voided');
    const claims = await db.collection('financial_settlement_claims').get();
    assert.strictEqual(claims.size, 0);
    const lines = await db
      .collection('financial_settlements')
      .doc(d.settlementId)
      .collection('lines')
      .get();
    assert.strictEqual(lines.size, 5, 'lines retained');
  }

  // void settled rejected
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    const locked = await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'ls'},
    });
    await ledger.markSettlementSettled({
      db,
      auth: financeAuth(),
      data: {
        settlementId: d.settlementId,
        idempotencyKey: 'ms',
        settlementMethod: 'cash',
        paymentReference: 'R',
        amountMinor: locked.absoluteSettlementAmountMinor,
      },
    });
    let forbidden = false;
    try {
      await ledger.voidSettlement({
        db,
        auth: financeAuth(),
        data: {settlementId: d.settlementId, reason: 'nope', idempotencyKey: 'vs'},
      });
    } catch (e) {
      forbidden = e.message === 'VOID_SETTLED_FORBIDDEN';
    }
    assert.ok(forbidden);
  }

  // allocation duplicate rejected
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    const locked = await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'alloc-lock'},
    });
    await db.collection('company_payments').doc('cp1').set({
      driverId: 'drv1',
      currency: 'SAR',
      status: 'completed',
      amount: -50,
    });
    const amt = Math.min(5000, locked.absoluteSettlementAmountMinor);
    await ledger.allocateLegacyPayment({
      db,
      auth: financeAuth(),
      data: {
        settlementId: d.settlementId,
        sourceId: 'cp1',
        amountMinor: amt,
        idempotencyKey: 'al1',
      },
    });
    let dup = false;
    try {
      await ledger.allocateLegacyPayment({
        db,
        auth: financeAuth(),
        data: {
          settlementId: d.settlementId,
          sourceId: 'cp1',
          amountMinor: amt,
          idempotencyKey: 'al2',
        },
      });
    } catch (e) {
      dup = e.message === 'ALLOCATION_DUPLICATE';
    }
    assert.ok(dup);
    const pay = await db.collection('company_payments').doc('cp1').get();
    assert.strictEqual(pay.data().status, 'completed', 'legacy payment not mutated');
  }

  // two concurrent admins
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d1 = await draft(db, {idempotencyKey: 'c1'});
    const d2 = await draft(db, {idempotencyKey: 'c2'});
    const results = await Promise.allSettled([
      ledger.lockSettlement({
        db,
        auth: financeAuth('adminA'),
        data: {settlementId: d1.settlementId, idempotencyKey: 'ca'},
      }),
      ledger.lockSettlement({
        db,
        auth: financeAuth('adminB'),
        data: {settlementId: d2.settlementId, idempotencyKey: 'cb'},
      }),
    ]);
    const ok = results.filter((r) => r.status === 'fulfilled');
    const bad = results.filter((r) => r.status === 'rejected');
    assert.strictEqual(ok.length, 1);
    assert.strictEqual(bad.length, 1);
    const claims = await db.collection('financial_settlement_claims').get();
    assert.strictEqual(claims.size, 5);
  }

  // audit event created
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const d = await draft(db);
    const events = await db
      .collection('financial_settlements')
      .doc(d.settlementId)
      .collection('events')
      .get();
    assert.ok(events.size >= 1);
    const types = events.docs.map((x) => x.data().type);
    assert.ok(types.includes('CREATED_DRAFT'));
  }

  // no order/wallet mutation on lock
  {
    const db = new FakeFirestore();
    await seedFiveCash(db);
    const before = (await db.collection('order').doc('o1').get()).data();
    const d = await draft(db);
    await ledger.lockSettlement({
      db,
      auth: financeAuth(),
      data: {settlementId: d.settlementId, idempotencyKey: 'nm'},
    });
    const after = (await db.collection('order').doc('o1').get()).data();
    assert.strictEqual(after.total, before.total);
    assert.strictEqual(after.payment_status, before.payment_status);
    const wallets = await db.collection('wallets').get();
    assert.strictEqual(wallets.size, 0);
    const tx = await db.collection('transactions').get();
    assert.strictEqual(tx.size, 0);
  }

  console.log('settlement_ledger tests OK');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
