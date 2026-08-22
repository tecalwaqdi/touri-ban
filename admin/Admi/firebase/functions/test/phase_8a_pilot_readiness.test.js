'use strict';

/**
 * Phase 8A pilot readiness — FakeFirestore only.
 * Does NOT enable production flags or touch production data.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {FakeFirestore} = require('./fake_firestore');
const ledger = require('../settlement_ledger');
const payments = require('../settlement_payments');
const {
  DEFAULT_FLAGS,
  loadFinanceFeatureFlags,
} = require('../finance_feature_flags');
const {DEFAULT_POLICY, describePolicy} = require('../finance_policy');

function superAuth(uid = 'super1') {
  return {uid, token: {super_admin: true}};
}
function financeAuth(uid = 'fin1') {
  return {uid, token: {finance: true}};
}
function countryAdminAuth(uid = 'ca1', countryId = 'countries/sa') {
  return {uid, token: {country_admin: true, country_id: countryId}};
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

async function seedOrders(db, n, driver = 'drv1') {
  for (let i = 1; i <= n; i++) {
    await db.collection('order').doc(`o${i}`).set({
      mndob_user: db.doc(`user/${driver}`),
      Rev_dolh: db.doc('countries/sa'),
      ...cashOrder(),
    });
  }
}

async function enableSettlementFlags(db, extra = {}) {
  await db.doc('financial_config/runtime').set({
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
    WALLET_SETTLEMENT_ENABLED: false,
    allowSelfApproval: false,
    ...extra,
  });
}

const period = {
  periodStart: '2026-03-01T00:00:00.000Z',
  periodEnd: '2026-05-01T00:00:00.000Z',
};

async function catchMsg(fn) {
  try {
    await fn();
    return null;
  } catch (e) {
    return e.message;
  }
}

/**
 * LEGACY_WALLET_TOOL gate + FakeFirestore adjust — mirrors index.js security
 * (super_admin only, WALLET_SETTLEMENT_ENABLED, optional idempotency).
 * Settlement modules must never call this path.
 */
async function runLegacyAdminWalletAdjust({db, auth, data, FieldValue}) {
  if (!auth || !auth.uid) {
    const err = new Error('Sign in required.');
    err.code = 'unauthenticated';
    throw err;
  }
  const token = auth.token || {};
  if (!token.super_admin) {
    const err = new Error('PERMISSION_DENIED');
    err.code = 'permission-denied';
    throw err;
  }
  const flags = await loadFinanceFeatureFlags(db);
  if (!flags.WALLET_SETTLEMENT_ENABLED) {
    const err = new Error('FEATURE_FLAG_DISABLED');
    err.code = 'failed-precondition';
    err.details = {flag: 'WALLET_SETTLEMENT_ENABLED'};
    throw err;
  }

  const driverId = String((data && data.driverId) || '').trim();
  const amount = Number(data && data.amount);
  const note = String((data && data.note) || '').trim().slice(0, 500);
  const currency = String((data && data.currency) || 'SAR').trim().toUpperCase() || 'SAR';
  const idempotencyKey = String((data && data.idempotencyKey) || '').trim();
  const sv = FieldValue || {serverTimestamp: () => ({_sv: true})};

  if (!driverId) throw new Error('driverId required.');
  if (!Number.isFinite(amount) || amount === 0 || Math.abs(amount) > 50000) {
    throw new Error('amount must be a non-zero number within ±50000.');
  }

  if (idempotencyKey) {
    const prior = await db
      .collection('financial_wallet_adjust_idempotency')
      .doc(idempotencyKey)
      .get();
    if (prior.exists && prior.data() && prior.data().result) {
      return prior.data().result;
    }
  }

  const userRef = db.collection('user').doc(driverId);
  const wallets = await db
    .collection('wallets')
    .where('userRef', '==', userRef)
    .limit(1)
    .get();
  const walletRef = wallets.empty
    ? db.collection('wallets').doc(driverId)
    : wallets.docs[0].ref;

  const ledgerId = `admin_adj_${driverId.slice(0, 8)}_${Date.now()}`;
  const ledgerRef = db.collection('transactions').doc(ledgerId);
  const idempRef = idempotencyKey
    ? db.collection('financial_wallet_adjust_idempotency').doc(idempotencyKey)
    : null;

  let result = null;
  await db.runTransaction(async (tx) => {
    if (idempRef) {
      const prior = await tx.get(idempRef);
      if (prior.exists && prior.data() && prior.data().result) {
        result = prior.data().result;
        return;
      }
    }
    const wallet = await tx.get(walletRef);
    const balanceBefore = wallet.exists ? Number(wallet.data().currentBalance || 0) : 0;
    const balanceAfter = balanceBefore + amount;
    if (balanceAfter < 0) throw new Error('INSUFFICIENT_BALANCE');

    tx.set(
      walletRef,
      {
        userRef,
        currentBalance: balanceAfter,
        walletBalance: balanceAfter,
        currency,
        isActive: true,
        walletUpdatedAt: sv.serverTimestamp(),
        lastUpdated: sv.serverTimestamp(),
        updatedAt: sv.serverTimestamp(),
        ...(wallet.exists ? {} : {createdAt: sv.serverTimestamp()}),
      },
      {merge: true},
    );
    tx.set(ledgerRef, {
      driverId,
      userRef,
      walletRef,
      type: 'admin_adjustment',
      amount,
      currency,
      status: 'completed',
      description_code: amount > 0 ? 'admin_credit' : 'admin_debit',
      notes: note || `Admin adjustment by ${auth.uid}`,
      balanceBefore,
      balanceAfter,
      actorUid: auth.uid,
      createdAt: sv.serverTimestamp(),
      ...(idempotencyKey ? {idempotencyKey} : {}),
    });
    result = {
      ok: true,
      driverId,
      walletId: walletRef.id,
      amount,
      balanceBefore,
      balanceAfter,
      ledgerId,
      ...(idempotencyKey ? {idempotencyKey} : {}),
    };
    if (idempRef) {
      tx.set(idempRef, {
        result,
        actorUid: auth.uid,
        driverId,
        amount,
        createdAt: sv.serverTimestamp(),
      });
    }
  });

  const auditId = `audit_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  await db.collection('admin_audit_log').doc(auditId).set({
    actor_uid: auth.uid,
    action: 'wallet_adjust',
    target: `wallets/${result.walletId}`,
    details: JSON.stringify({
      driverId,
      amount,
      balanceBefore: result.balanceBefore,
      balanceAfter: result.balanceAfter,
      note,
      ledgerId: result.ledgerId,
      idempotencyKey: idempotencyKey || null,
      legacyTool: 'LEGACY_WALLET_TOOL',
    }),
    created_at: new Date().toISOString(),
  });

  return result;
}

(async () => {
  // ── 1) Feature flags OFF by default ─────────────────────────────────────
  {
    assert.strictEqual(DEFAULT_FLAGS.FINANCIAL_SETTLEMENT_WRITES_ENABLED, false);
    assert.strictEqual(DEFAULT_FLAGS.FINANCIAL_PAYMENT_CONFIRM_ENABLED, false);
    assert.strictEqual(DEFAULT_FLAGS.WALLET_SETTLEMENT_ENABLED, false);
    assert.strictEqual(DEFAULT_POLICY.allowSelfApproval, false);

    const db = new FakeFirestore();
    await seedOrders(db, 1);
    const flags = await loadFinanceFeatureFlags(db);
    assert.strictEqual(flags.FINANCIAL_SETTLEMENT_WRITES_ENABLED, false);
    assert.strictEqual(flags.FINANCIAL_PAYMENT_CONFIRM_ENABLED, false);
    assert.strictEqual(flags.WALLET_SETTLEMENT_ENABLED, false);

    const draftMsg = await catchMsg(() =>
      ledger.createSettlementDraft({
        db,
        auth: financeAuth('maker'),
        data: {
          driverId: 'drv1',
          countryId: 'countries/sa',
          currency: 'SAR',
          ...period,
          idempotencyKey: '8a-flag-draft',
        },
      }),
    );
    assert.strictEqual(draftMsg, 'FEATURE_FLAG_DISABLED');

    // Seed a draft under a temporary flag, then turn flags off for lock/confirm.
    await enableSettlementFlags(db);
    const d = await ledger.createSettlementDraft({
      db,
      auth: financeAuth('maker'),
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-pre-lock',
      },
    });
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
      WALLET_SETTLEMENT_ENABLED: false,
    });

    const lockMsg = await catchMsg(() =>
      ledger.lockSettlement({
        db,
        auth: superAuth('checker'),
        data: {settlementId: d.settlementId, idempotencyKey: '8a-flag-lock'},
      }),
    );
    assert.strictEqual(lockMsg, 'FEATURE_FLAG_DISABLED');

    // Confirm payment gated when PAYMENT_CONFIRM flag is off.
    await enableSettlementFlags(db);
    const d2 = await ledger.createSettlementDraft({
      db,
      auth: financeAuth('maker'),
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-pre-pay',
      },
    });
    const locked2 = await ledger.lockSettlement({
      db,
      auth: superAuth('checker'),
      data: {settlementId: d2.settlementId, idempotencyKey: '8a-lock-for-pay'},
    });
    const pay = await payments.createSettlementPayment({
      db,
      auth: financeAuth('maker'),
      data: {
        settlementId: locked2.settlementId,
        amountMinor: 1000,
        method: 'bank_transfer',
        externalReference: 'PRE',
        idempotencyKey: '8a-pay-pending',
      },
    });
    await db.doc('financial_config/runtime').set(
      {FINANCIAL_PAYMENT_CONFIRM_ENABLED: false},
      {merge: true},
    );
    const confirmMsg = await catchMsg(() =>
      payments.confirmSettlementPayment({
        db,
        auth: superAuth('checker'),
        data: {paymentId: pay.paymentId, idempotencyKey: '8a-flag-confirm'},
      }),
    );
    assert.strictEqual(confirmMsg, 'FEATURE_FLAG_DISABLED');
    const walletMsg = await catchMsg(() =>
      runLegacyAdminWalletAdjust({
        db,
        auth: superAuth(),
        data: {driverId: 'drv1', amount: 10, note: 'pilot'},
      }),
    );
    assert.strictEqual(walletMsg, 'FEATURE_FLAG_DISABLED');
  }

  // ── 2) Full settlement E2E (FakeFirestore flags ON only) ───────────────────
  {
    const db = new FakeFirestore();
    await enableSettlementFlags(db);
    await seedOrders(db, 5);
    const maker = financeAuth('maker');
    const checker = superAuth('checker');

    // preview → draft
    const draft = await ledger.createSettlementDraft({
      db,
      auth: maker,
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-e2e-draft',
      },
    });
    assert.strictEqual(draft.status, 'draft');
    assert.strictEqual(draft.eligibleTripCount, 5);
    assert.ok(draft.previewHash || draft.settlementId);

    // lock (maker ≠ checker)
    const locked = await ledger.lockSettlement({
      db,
      auth: checker,
      data: {settlementId: draft.settlementId, idempotencyKey: '8a-e2e-lock'},
    });
    assert.strictEqual(locked.status, 'locked');
    const due = locked.absoluteSettlementAmountMinor;
    assert.ok(due > 0);

    // partial confirm
    const half = Math.floor(due / 2);
    const p1 = await payments.createSettlementPayment({
      db,
      auth: maker,
      data: {
        settlementId: locked.settlementId,
        amountMinor: half,
        method: 'bank_transfer',
        externalReference: 'E2E-HALF',
        idempotencyKey: '8a-e2e-p1',
      },
    });
    const c1 = await payments.confirmSettlementPayment({
      db,
      auth: checker,
      data: {paymentId: p1.paymentId, idempotencyKey: '8a-e2e-c1'},
    });
    assert.strictEqual(c1.settlementStatus, 'partially_paid');
    assert.strictEqual(c1.outstandingMinor, due - half);

    // final confirm → settled
    const p2 = await payments.createSettlementPayment({
      db,
      auth: maker,
      data: {
        settlementId: locked.settlementId,
        amountMinor: due - half,
        method: 'bank_transfer',
        externalReference: 'E2E-REST',
        idempotencyKey: '8a-e2e-p2',
      },
    });
    const c2 = await payments.confirmSettlementPayment({
      db,
      auth: checker,
      data: {paymentId: p2.paymentId, idempotencyKey: '8a-e2e-c2'},
    });
    assert.strictEqual(c2.settlementStatus, 'settled');
    assert.strictEqual(c2.outstandingMinor, 0);

    // Finance least privilege: settlement path never mutated wallets
    const wallets = await db.collection('wallets').get();
    assert.strictEqual(wallets.size, 0, 'settlement E2E must not touch wallets');
  }

  // void path separate (locked, no confirmed payments)
  {
    const db = new FakeFirestore();
    await enableSettlementFlags(db);
    await seedOrders(db, 3);
    const maker = financeAuth('maker');
    const checker = superAuth('checker');
    const draft = await ledger.createSettlementDraft({
      db,
      auth: maker,
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-void-draft',
      },
    });
    await ledger.lockSettlement({
      db,
      auth: checker,
      data: {settlementId: draft.settlementId, idempotencyKey: '8a-void-lock'},
    });
    const voided = await ledger.voidSettlement({
      db,
      auth: checker,
      data: {
        settlementId: draft.settlementId,
        reason: 'pilot void path',
        idempotencyKey: '8a-void',
      },
    });
    assert.strictEqual(voided.status, 'voided');
    const claims = await db.collection('financial_settlement_claims').get();
    assert.strictEqual(claims.size, 0);
  }

  // reverse payment scenario
  {
    const db = new FakeFirestore();
    await enableSettlementFlags(db);
    await seedOrders(db, 5);
    const maker = financeAuth('maker');
    const checker = superAuth('checker');
    const draft = await ledger.createSettlementDraft({
      db,
      auth: maker,
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-rev-draft',
      },
    });
    const locked = await ledger.lockSettlement({
      db,
      auth: checker,
      data: {settlementId: draft.settlementId, idempotencyKey: '8a-rev-lock'},
    });
    const p = await payments.createSettlementPayment({
      db,
      auth: maker,
      data: {
        settlementId: locked.settlementId,
        amountMinor: 4000,
        method: 'bank_transfer',
        externalReference: 'REV',
        idempotencyKey: '8a-rev-p',
      },
    });
    await payments.confirmSettlementPayment({
      db,
      auth: checker,
      data: {paymentId: p.paymentId, idempotencyKey: '8a-rev-c'},
    });
    const rev = await payments.reverseSettlementPayment({
      db,
      auth: checker,
      data: {
        paymentId: p.paymentId,
        reason: 'pilot reverse',
        reversalAmountMinor: 1500,
        idempotencyKey: '8a-rev-r',
      },
    });
    assert.strictEqual(rev.outstandingMinor, locked.absoluteSettlementAmountMinor - 2500);
    const orig = (await db.collection('financial_settlement_payments').doc(p.paymentId).get()).data();
    assert.strictEqual(orig.status, 'confirmed');
    assert.strictEqual(orig.amountMinor, 4000);
  }

  // ── 3) Maker/checker ────────────────────────────────────────────────────
  {
    const db = new FakeFirestore();
    await enableSettlementFlags(db); // allowSelfApproval=false
    await seedOrders(db, 2);
    const maker = financeAuth('same-uid');
    const draft = await ledger.createSettlementDraft({
      db,
      auth: maker,
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-self',
      },
    });
    const selfMsg = await catchMsg(() =>
      ledger.lockSettlement({
        db,
        auth: maker,
        data: {settlementId: draft.settlementId, idempotencyKey: '8a-self-lock'},
      }),
    );
    assert.strictEqual(selfMsg, 'SELF_APPROVAL_FORBIDDEN');

    const ok = await ledger.lockSettlement({
      db,
      auth: superAuth('other-uid'),
      data: {settlementId: draft.settlementId, idempotencyKey: '8a-ok-lock'},
    });
    assert.strictEqual(ok.status, 'locked');
    assert.notStrictEqual(maker.uid, 'other-uid');
  }

  // ── 4) Country scope ────────────────────────────────────────────────────
  {
    const db = new FakeFirestore();
    await enableSettlementFlags(db);
    await seedOrders(db, 1);
    // country_admin cannot write settlements (least privilege vs finance/super_admin)
    assert.strictEqual(
      ledger.canWriteSettlements(countryAdminAuth().token),
      false,
      'country_admin must not write settlements',
    );
    assert.strictEqual(
      ledger.canReadSettlements(countryAdminAuth().token),
      true,
      'country_admin may read in-scope',
    );

    const denied = await catchMsg(() =>
      ledger.createSettlementDraft({
        db,
        auth: countryAdminAuth('ca-ae', 'countries/ae'),
        data: {
          driverId: 'drv1',
          countryId: 'countries/sa',
          currency: 'SAR',
          ...period,
          idempotencyKey: '8a-cross-country',
        },
      }),
    );
    assert.ok(
      denied === 'Settlement writes require SuperAdmin or Finance.' ||
        String(denied).includes('SuperAdmin or Finance'),
    );

    // Exposure aggregate: AE country_admin must not see SA settlements
    const maker = financeAuth('maker');
    const checker = superAuth('checker');
    const draft = await ledger.createSettlementDraft({
      db,
      auth: maker,
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-scope-draft',
      },
    });
    await ledger.lockSettlement({
      db,
      auth: checker,
      data: {settlementId: draft.settlementId, idempotencyKey: '8a-scope-lock'},
    });
    const aeView = await payments.aggregateSettlementExposure({
      db,
      auth: countryAdminAuth('ca-ae', 'countries/ae'),
    });
    assert.strictEqual(aeView.settlementCount, 0);
    const saView = await payments.aggregateSettlementExposure({
      db,
      auth: countryAdminAuth('ca-sa', 'countries/sa'),
    });
    assert.strictEqual(saView.settlementCount, 1);
  }

  // ── 5) Wallet isolation + LEGACY_WALLET_TOOL contract ───────────────────
  {
    const ledgerSrc = fs.readFileSync(
      path.join(__dirname, '../settlement_ledger.js'),
      'utf8',
    );
    const paySrc = fs.readFileSync(
      path.join(__dirname, '../settlement_payments.js'),
      'utf8',
    );
    const indexSrc = fs.readFileSync(path.join(__dirname, '../index.js'), 'utf8');

    assert.ok(
      !ledgerSrc.includes('adminAdjustDriverWallet'),
      'settlement_ledger must never call adminAdjustDriverWallet',
    );
    assert.ok(
      !paySrc.includes('adminAdjustDriverWallet'),
      'settlement_payments must never call adminAdjustDriverWallet',
    );
    assert.ok(
      ledgerSrc.includes('NEVER writes: order, wallets, transactions'),
      'ledger documents wallet isolation',
    );
    assert.ok(indexSrc.includes('LEGACY_WALLET_TOOL'));
    assert.ok(indexSrc.includes('financial_wallet_adjust_idempotency'));
    assert.ok(indexSrc.includes('WALLET_SETTLEMENT_ENABLED'));
    const walletFn = indexSrc.slice(
      indexSrc.indexOf('exports.adminAdjustDriverWallet'),
      indexSrc.indexOf('// ── Settlement Ledger V2'),
    );
    assert.ok(walletFn.length > 200, 'adminAdjustDriverWallet block found');
    // Finance removed from allowed callers — super_admin only
    assert.ok(
      /if\s*\(\s*!token\.super_admin\s*\)/.test(walletFn),
      'wallet adjust must require super_admin only',
    );
    assert.ok(
      !/!token\.super_admin\s*&&\s*!token\.finance/.test(walletFn),
      'finance must not remain an allowed wallet-adjust caller',
    );

    // Unit-test wallet isolation on lock path
    const db = new FakeFirestore();
    await enableSettlementFlags(db);
    await seedOrders(db, 2);
    const draft = await ledger.createSettlementDraft({
      db,
      auth: financeAuth('maker'),
      data: {
        driverId: 'drv1',
        countryId: 'countries/sa',
        currency: 'SAR',
        ...period,
        idempotencyKey: '8a-iso-draft',
      },
    });
    await ledger.lockSettlement({
      db,
      auth: superAuth('checker'),
      data: {settlementId: draft.settlementId, idempotencyKey: '8a-iso-lock'},
    });
    assert.strictEqual((await db.collection('wallets').get()).size, 0);
    assert.strictEqual((await db.collection('transactions').get()).size, 0);

    // Finance cannot use legacy wallet tool; super_admin + flag + idempotency OK
    const financeDenied = await catchMsg(() =>
      runLegacyAdminWalletAdjust({
        db,
        auth: financeAuth('fin-bypass'),
        data: {driverId: 'drv1', amount: 5, note: 'nope'},
      }),
    );
    assert.strictEqual(financeDenied, 'PERMISSION_DENIED');

    await db.doc('financial_config/runtime').set(
      {WALLET_SETTLEMENT_ENABLED: true},
      {merge: true},
    );
    const a = await runLegacyAdminWalletAdjust({
      db,
      auth: superAuth('super-wallet'),
      data: {
        driverId: 'drv1',
        amount: 25,
        note: 'pilot',
        idempotencyKey: '8a-wallet-idem',
      },
      FieldValue: db.FieldValue,
    });
    assert.strictEqual(a.ok, true);
    assert.strictEqual(a.balanceAfter, 25);
    const b = await runLegacyAdminWalletAdjust({
      db,
      auth: superAuth('super-wallet'),
      data: {
        driverId: 'drv1',
        amount: 25,
        note: 'pilot',
        idempotencyKey: '8a-wallet-idem',
      },
      FieldValue: db.FieldValue,
    });
    assert.strictEqual(b.ledgerId, a.ledgerId);
    assert.strictEqual(b.balanceAfter, 25);
    const wallet = (await db.collection('wallets').doc('drv1').get()).data();
    assert.strictEqual(wallet.currentBalance, 25, 'idempotent replay must not double-credit');
    const audits = await db.collection('admin_audit_log').get();
    assert.ok(audits.size >= 1);
  }

  // ── 6) Finance role least privilege notes ───────────────────────────────
  {
    const policy = describePolicy(DEFAULT_POLICY);
    assert.deepStrictEqual(policy.makerRoles, ['super_admin', 'finance']);
    assert.deepStrictEqual(policy.checkerRoles, ['super_admin', 'finance']);
    assert.strictEqual(policy.allowSelfApproval, false);

    assert.strictEqual(ledger.canWriteSettlements(financeAuth().token), true);
    assert.strictEqual(ledger.canWriteSettlements(superAuth().token), true);
    assert.strictEqual(ledger.canWriteSettlements(countryAdminAuth().token), false);
    // Finance + country_admin hybrid must not write (agent-like)
    assert.strictEqual(
      ledger.canWriteSettlements({finance: true, country_admin: true}),
      false,
      'finance+country_admin must not get write (least privilege)',
    );
  }

  console.log('phase_8a_pilot_readiness tests OK');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
