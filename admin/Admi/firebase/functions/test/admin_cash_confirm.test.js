'use strict';

const assert = require('assert');
const {FakeFirestore} = require('./fake_firestore');
const cash = require('../cash_collection_realization');

function adminShim(db) {
  return {
    firestore: {
      FieldValue: db.FieldValue,
    },
  };
}

function pendingCashOrder(overrides = {}) {
  return {
    PaymentMethod: 'Cash',
    status_code: 'completed',
    payment_status: 'pending_cash',
    cash_collection_status: 'pending',
    currency: 'SAR',
    total: 50,
    total_app: 7.5,
    total_vat: 0,
    ksm: 0,
    mndob_user: {path: 'user/drv1'},
    Rev_dolh: {path: 'countries/saudi_arabia'},
    data_order: new Date('2026-09-01T10:00:00.000Z'),
    ...overrides,
  };
}

async function enableFlag(db) {
  await db.doc('financial_config/runtime').set({
    FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
  });
}

async function runTests() {
  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await db.collection('order').doc('oa1').set(pendingCashOrder());
    let err;
    try {
      await cash.adminConfirmCashCollectionV2({
        db,
        auth: {uid: 'drv1', token: {}},
        data: {orderId: 'oa1', reason: 'stuck trip'},
        admin: adminShim(db),
      });
    } catch (e) {
      err = e;
    }
    assert.ok(err);
    assert.strictEqual(err.message, 'ADMIN_OR_FINANCE_REQUIRED');
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await db.collection('order').doc('oa2').set(pendingCashOrder());
    const r = await cash.adminConfirmCashCollectionV2({
      db,
      auth: {uid: 'fin1', token: {finance: true}},
      data: {orderId: 'oa2', reason: 'customer paid, driver offline'},
      admin: adminShim(db),
    });
    assert.strictEqual(r.code, 'COLLECTED');
    assert.strictEqual(r.realizedByRole, 'admin');
    const after = await db.collection('order').doc('oa2').get();
    assert.strictEqual(after.data().payment_status, 'cash_collected');
    assert.strictEqual(after.data().cash_realized_by_admin, true);
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await db.collection('order').doc('oa3').set(pendingCashOrder());
    const a = await cash.adminConfirmCashCollectionV2({
      db,
      auth: {uid: 'sa', token: {super_admin: true}},
      data: {orderId: 'oa3', reason: 'manual close', operationId: 'op-admin-1'},
      admin: adminShim(db),
    });
    const b = await cash.adminConfirmCashCollectionV2({
      db,
      auth: {uid: 'sa', token: {super_admin: true}},
      data: {orderId: 'oa3', reason: 'manual close', operationId: 'op-admin-1'},
      admin: adminShim(db),
    });
    assert.strictEqual(a.code, 'COLLECTED');
    assert.strictEqual(b.idempotent, true);
  }

  console.log('admin_cash_confirm tests OK');
}

runTests().catch((e) => {
  console.error(e);
  process.exit(1);
});
