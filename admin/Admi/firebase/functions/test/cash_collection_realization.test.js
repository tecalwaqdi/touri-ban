'use strict';

const assert = require('assert');
const {FakeFirestore} = require('./fake_firestore');
const v2 = require('../financial_accounting_v2');
const cash = require('../cash_collection_realization');

function driverAuth(uid = 'drv1') {
  return {uid, token: {}};
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

function adminShim(db) {
  return {
    firestore: {
      FieldValue: db.FieldValue,
    },
  };
}

async function enableFlag(db) {
  await db.doc('financial_config/runtime').set({
    FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
  });
}

async function seedOrder(db, id, data) {
  await db.collection('order').doc(id).set(data);
}

async function expectError(fn, message) {
  let err;
  try {
    await fn();
  } catch (e) {
    err = e;
  }
  assert.ok(err, `expected ${message}`);
  assert.strictEqual(err.message, message);
}

async function runTests() {
  {
    const line = v2.analyzeOrder('dry', {
      ...pendingCashOrder(),
      payment_status: 'cash_collected',
      cash_collection_status: 'collected',
    });
    assert.strictEqual(line.customerPaidMinor, 5000);
    assert.strictEqual(line.platformFeeMinor, 750);
    assert.strictEqual(line.driverNetMinor, 4250);
    assert.strictEqual(line.signedCashMinor, 750);
    assert.strictEqual(line.eligible, true);
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await seedOrder(db, 'o50', pendingCashOrder());

    const r1 = await cash.confirmCashCollectionV2({
      db,
      auth: driverAuth(),
      data: {orderId: 'o50', operationId: 'op-1'},
      admin: adminShim(db),
    });
    assert.strictEqual(r1.code, 'COLLECTED');
    assert.strictEqual(r1.companyDueMinor, 750);
    assert.strictEqual(r1.driverNetMinor, 4250);
    assert.strictEqual(r1.settlementEligible, true);

    const after = await db.collection('order').doc('o50').get();
    assert.strictEqual(after.data().payment_status, 'cash_collected');
    assert.strictEqual(after.data().cash_collection_status, 'collected');
    assert.strictEqual(after.data().financial_realization_version, 1);
    assert.ok(after.data().financial_realized_at);
    assert.ok(after.data().cashCollectedAt);

    const r2 = await cash.confirmCashCollectionV2({
      db,
      auth: driverAuth(),
      data: {orderId: 'o50', operationId: 'op-1'},
      admin: adminShim(db),
    });
    assert.strictEqual(r2.code, 'COLLECTED');
    assert.strictEqual(r2.idempotent, true);
    assert.strictEqual(r2.companyDueMinor, 750);
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await seedOrder(db, 'o50b', pendingCashOrder());

    await cash.confirmCashCollectionV2({
      db,
      auth: driverAuth(),
      data: {orderId: 'o50b', operationId: 'op-a'},
      admin: adminShim(db),
    });
    const rDup = await cash.confirmCashCollectionV2({
      db,
      auth: driverAuth(),
      data: {orderId: 'o50b', operationId: 'op-b'},
      admin: adminShim(db),
    });
    assert.strictEqual(rDup.code, 'ALREADY_REALIZED');
    assert.strictEqual(rDup.companyDueMinor, 750);
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await seedOrder(
      db,
      'oOnline',
      pendingCashOrder({
        PaymentMethod: 'OnlinePayment',
        payment_status: 'paid',
      }),
    );

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth(),
          data: {orderId: 'oOnline', operationId: 'op-on'},
          admin: adminShim(db),
        }),
      'NOT_CASH',
    );
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await seedOrder(
      db,
      'oCancel',
      pendingCashOrder({
        status_code: 'cancelled_by_driver',
      }),
    );

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth(),
          data: {orderId: 'oCancel', operationId: 'op-c'},
          admin: adminShim(db),
        }),
      'INVALID_STATE',
    );
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await seedOrder(
      db,
      'oWrong',
      pendingCashOrder({
        mndob_user: {path: 'user/other'},
      }),
    );

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth(),
          data: {orderId: 'oWrong', operationId: 'op-w'},
          admin: adminShim(db),
        }),
      'NOT_ASSIGNED_DRIVER',
    );
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await db.collection('order').doc('oLegacy').set({
      PaymentMethod: 'Cash',
      status_code: 'completed',
      payment_status: 'pending_cash',
      mndob_user: {path: 'user/drv1'},
      currency: 'SAR',
    });

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth(),
          data: {orderId: 'oLegacy', operationId: 'op-l'},
          admin: adminShim(db),
        }),
      'FINANCE_DATA_INCOMPLETE',
    );
  }

  {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: false,
    });
    await seedOrder(db, 'oFlag', pendingCashOrder());

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth(),
          data: {orderId: 'oFlag', operationId: 'op-f'},
          admin: adminShim(db),
        }),
      'FEATURE_FLAG_DISABLED',
    );
  }

  {
    // LIVE cutover shape: read_only + cash flag true must allow Driver cash V2.
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
      LEGACY_ADMIN_WRITE_MODE: 'read_only',
      LEGACY_ADMIN_CUTOVER_RESTRICTED: true,
    });
    await seedOrder(db, 'oRo', pendingCashOrder());

    const r1 = await cash.confirmCashCollectionV2({
      db,
      auth: driverAuth(),
      data: {orderId: 'oRo', operationId: 'op-ro-1'},
      admin: adminShim(db),
    });
    assert.strictEqual(r1.code, 'COLLECTED');
    assert.strictEqual(r1.financialRealized, true);

    const r2 = await cash.confirmCashCollectionV2({
      db,
      auth: driverAuth(),
      data: {orderId: 'oRo', operationId: 'op-ro-1'},
      admin: adminShim(db),
    });
    assert.strictEqual(r2.idempotent, true);
    assert.strictEqual(r2.code, 'COLLECTED');

    const after = await db.collection('order').doc('oRo').get();
    assert.strictEqual(after.data().payment_status, 'cash_collected');
    assert.strictEqual(after.data().total, 50);
  }

  {
    // Cash flag false under read_only remains denied (domain flag, not LEGACY_ADMIN_READ_ONLY).
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: false,
      LEGACY_ADMIN_WRITE_MODE: 'read_only',
      LEGACY_ADMIN_CUTOVER_RESTRICTED: true,
    });
    await seedOrder(db, 'oRoOff', pendingCashOrder());

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth(),
          data: {orderId: 'oRoOff', operationId: 'op-ro-off'},
          admin: adminShim(db),
        }),
      'FEATURE_FLAG_DISABLED',
    );
  }

  {
    // Unauthorized driver (not assigned) denied under read_only + cash flag true.
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
      LEGACY_ADMIN_WRITE_MODE: 'read_only',
      LEGACY_ADMIN_CUTOVER_RESTRICTED: true,
    });
    await seedOrder(db, 'oAuth', pendingCashOrder());

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth('other_drv'),
          data: {orderId: 'oAuth', operationId: 'op-auth'},
          admin: adminShim(db),
        }),
      'NOT_ASSIGNED_DRIVER',
    );
  }

  {
    // Admin path also allowed under read_only when cash flag true.
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
      LEGACY_ADMIN_WRITE_MODE: 'read_only',
      LEGACY_ADMIN_CUTOVER_RESTRICTED: true,
    });
    await seedOrder(db, 'oAdminRo', pendingCashOrder());

    const r = await cash.adminConfirmCashCollectionV2({
      db,
      auth: {uid: 'fin1', token: {finance: true}},
      data: {
        orderId: 'oAdminRo',
        operationId: 'op-admin-ro',
        reason: 'Stage1 QA cash CF gate fix',
      },
      admin: adminShim(db),
    });
    assert.strictEqual(r.code, 'COLLECTED');
  }

  {
    // Non-finance/non-super admin path denied.
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
      LEGACY_ADMIN_WRITE_MODE: 'read_only',
    });
    await seedOrder(db, 'oAdminDeny', pendingCashOrder());

    await expectError(
      () =>
        cash.adminConfirmCashCollectionV2({
          db,
          auth: {uid: 'agent1', token: {country_admin: true}},
          data: {
            orderId: 'oAdminDeny',
            operationId: 'op-admin-deny',
            reason: 'should fail role gate',
          },
          admin: adminShim(db),
        }),
      'ADMIN_OR_FINANCE_REQUIRED',
    );
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await seedOrder(
      db,
      'oStarted',
      pendingCashOrder({
        status_code: 'trip_in_progress',
      }),
    );

    await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: driverAuth(),
          data: {orderId: 'oStarted', operationId: 'op-s'},
          admin: adminShim(db),
        }),
      'INVALID_STATE',
    );
  }

  {
    const db = new FakeFirestore();
    await enableFlag(db);
    await seedOrder(db, 'oConc', pendingCashOrder());

    const [a, b] = await Promise.all([
      cash.confirmCashCollectionV2({
        db,
        auth: driverAuth(),
        data: {orderId: 'oConc', operationId: 'op-c1'},
        admin: adminShim(db),
      }),
      cash.confirmCashCollectionV2({
        db,
        auth: driverAuth(),
        data: {orderId: 'oConc', operationId: 'op-c2'},
        admin: adminShim(db),
      }),
    ]);
    const codes = [a.code, b.code].sort();
    assert.ok(codes.includes('COLLECTED'));
    assert.ok(codes.includes('ALREADY_REALIZED'));
    assert.strictEqual(a.companyDueMinor || b.companyDueMinor, 750);

    const after = await db.collection('order').doc('oConc').get();
    assert.strictEqual(after.data().payment_status, 'cash_collected');
  }

  {
    const pending = v2.analyzeOrder('p', pendingCashOrder());
    assert.strictEqual(pending.eligible, false);
    assert.strictEqual(pending.exclusionReason, 'NOT_COLLECTED');

    const collected = v2.analyzeOrder('c', {
      ...pendingCashOrder(),
      payment_status: 'cash_collected',
      cash_collection_status: 'collected',
    });
    assert.strictEqual(collected.eligible, true);
    assert.strictEqual(collected.signedCashMinor, 750);
  }

  console.log('cash_collection_realization.test.js: all assertions passed');
}

runTests().catch((e) => {
  console.error(e);
  process.exit(1);
});
