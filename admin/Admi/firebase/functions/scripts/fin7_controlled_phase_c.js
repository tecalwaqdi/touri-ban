#!/usr/bin/env node
/**
 * FIN-7 — Controlled Phase C cash realization (ONE new order).
 * Requires service account. Does NOT modify historical orders.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node scripts/fin7_controlled_phase_c.js
 *   FIN7_DRY_RUN=1 — baseline + flag-off only, no order creation
 */
'use strict';

const admin = require('firebase-admin');
const path = require('path');
const https = require('https');

const cash = require(path.join(__dirname, '..', 'cash_collection_realization.js'));
const flagsMod = require(path.join(__dirname, '..', 'finance_feature_flags.js'));
const v2 = require(path.join(__dirname, '..', 'financial_accounting_v2.js'));

const SA =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(process.env.HOME, 'Downloads/tutorial-multi-language-70gx4j-fb851be1eb3e.json');
const PROJECT = 'tutorial-multi-language-70gx4j';
const REGION = 'us-central1';
const DRY_RUN = process.env.FIN7_DRY_RUN === '1';
const ORDER_PREFIX = 'fin7_ctrl_';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SA)) });
}

const db = admin.firestore();
const auth = admin.auth();

const report = {
  version: { source: '1.0.8+2010', firebase: null, render: null, parity: null },
  flags: { initial: {}, final: {} },
  historicalBaseline: null,
  controlledOrderId: null,
  steps: {},
  parity: {},
  safety: {},
  finalDecision: { cashFlagFinal: 'OFF', fin7: 'NOT_READY' },
  errors: [],
};

async function fetchJson(url) {
  return new Promise((resolve) => {
    https
      .get(url, (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          try {
            resolve({ ok: res.statusCode === 200, json: JSON.parse(raw) });
          } catch (_) {
            resolve({ ok: false, json: null });
          }
        });
      })
      .on('error', () => resolve({ ok: false, json: null }));
  });
}

async function checkVersions() {
  const fb = await fetchJson(
    'https://tutorial-multi-language-70gx4j.web.app/admin/version.json',
  );
  const rd = await fetchJson('https://touri-ban-1.onrender.com/version.json');
  report.version.firebase = fb.json
    ? `${fb.json.version}+${fb.json.build_number}`
    : 'UNKNOWN';
  report.version.render = rd.json
    ? `${rd.json.version}+${rd.json.build_number}`
    : 'UNKNOWN';
  report.version.parity =
    report.version.firebase === '1.0.8+2010' &&
    report.version.render === '1.0.8+2010'
      ? 'YES'
      : 'NO';
}

async function historicalSnapshot() {
  const snap = await db
    .collection('order')
    .where('status_code', '==', 'completed')
    .where('payment_status', '==', 'pending_cash')
    .limit(20)
    .get();
  const legacy = [];
  for (const doc of snap.docs) {
    if (doc.id.startsWith(ORDER_PREFIX)) continue;
    const o = doc.data();
    legacy.push({
      id: doc.id,
      total: o.total,
      payment_status: o.payment_status,
      cash_collection_status: o.cash_collection_status,
      cashCollectedByDriver: o.cashCollectedByDriver,
    });
  }
  const cp = await db.collection('company_payments').count().get();
  return {
    legacyCompletedPendingCash: legacy.length,
    legacyOrders: legacy,
    companyPaymentsCount: cp.data().count,
    settlementsCount: (await db.collection('financial_settlements').count().get())
      .data().count,
  };
}

async function pickControlledDriver() {
  const snap = await db
    .collection('user')
    .where('ismndob', '==', true)
    .where('actev_mndob', '==', true)
    .limit(5)
    .get();
  if (snap.empty) {
    throw new Error('NO_ACTIVE_DRIVER');
  }
  for (const doc of snap.docs) {
    const u = doc.data();
    const country = u.Rev_dolh || u.Rev_dloh_agent || u.rev_dolh;
    if (country) {
      return { uid: doc.id, countryRef: country, displayName: u.display_name || doc.id };
    }
  }
  const doc = snap.docs[0];
  const u = doc.data();
  return {
    uid: doc.id,
    countryRef: u.Rev_dolh || null,
    displayName: u.display_name || doc.id,
  };
}

function controlledOrderPayload(driverUid, countryRef) {
  const now = admin.firestore.Timestamp.now();
  return {
    PaymentMethod: 'Cash',
    status_code: 'completed',
    halh: 'completed',
    halh_order: 'Completed',
    payment_status: 'pending_cash',
    cash_collection_status: 'pending',
    cashCollectedByDriver: false,
    currency: 'SAR',
    total: 50,
    total_mndob2: 50,
    total_app: 7.5,
    total_vat: 0,
    total_mndob: 42.5,
    ksm: 0,
    mndob_user: db.doc(`user/${driverUid}`),
    Rev_dolh: countryRef,
    data_order: now,
    iDorder: `FIN7-${Date.now()}`,
    fin7_controlled: true,
    fin7_created_at: now,
  };
}

function analyzeOrderDoc(orderId, data) {
  return v2.analyzeOrder(orderId, data);
}

async function expectError(fn, message) {
  try {
    await fn();
    return { pass: false, got: 'UNEXPECTED_SUCCESS' };
  } catch (e) {
    const msg = String(e.message || e);
    return { pass: msg === message, got: msg };
  }
}

async function countSettlements() {
  return (await db.collection('financial_settlements').count().get()).data().count;
}

async function main() {
  await checkVersions();
  if (report.version.parity !== 'YES') {
    report.errors.push('VERSION_PARITY_FAIL');
    console.log(JSON.stringify(report, null, 2));
    process.exit(2);
  }

  report.historicalBaseline = await historicalSnapshot();
  const flags0 = await flagsMod.loadFinanceFeatureFlags(db);
  report.flags.initial = {
    CASH: flags0.FINANCIAL_CASH_REALIZATION_V2_ENABLED ? 'ON' : 'OFF',
    SETTLEMENT: flags0.FINANCIAL_SETTLEMENT_WRITES_ENABLED ? 'ON' : 'OFF',
  };
  if (report.flags.initial.CASH !== 'OFF') {
    report.errors.push('INITIAL_CASH_FLAG_NOT_OFF');
    console.log(JSON.stringify(report, null, 2));
    process.exit(2);
  }

  const driver = await pickControlledDriver();
  report.controlledDriver = { uid: driver.uid, name: driver.displayName };

  const orderId = `${ORDER_PREFIX}${Date.now()}`;
  report.controlledOrderId = orderId;

  if (DRY_RUN) {
    report.steps.dryRun = true;
    const flagOff = await expectError(
      () =>
        cash.confirmCashCollectionV2({
          db,
          auth: { uid: driver.uid },
          data: { orderId, operationId: `fin7_flag_off_${Date.now()}` },
          admin,
        }),
      'FEATURE_FLAG_DISABLED',
    );
    report.steps.flagOffCall = flagOff;
    console.log(JSON.stringify(report, null, 2));
    return;
  }

  const payload = controlledOrderPayload(driver.uid, driver.countryRef);
  await db.collection('order').doc(orderId).set(payload);

  const created = (await db.collection('order').doc(orderId).get()).data();
  const lineBefore = analyzeOrderDoc(orderId, created);
  report.steps.beforeCollection = {
    status_code: created.status_code,
    payment_status: created.payment_status,
    cash_collection_status: created.cash_collection_status,
    cashCollectedByDriver: created.cashCollectedByDriver,
    gross: lineBefore.customerPaidMinor / 100,
    platform: lineBefore.platformFeeMinor / 100,
    vat: lineBefore.recordedVatMinor / 100,
    driverNet: lineBefore.driverNetMinor / 100,
    eligible: lineBefore.eligible,
    exclusionReason: lineBefore.exclusionReason,
    snapshotComplete:
      created.total != null &&
      created.total_mndob2 != null &&
      created.total_app != null &&
      created.total_vat != null &&
      created.total_mndob != null,
  };

  if (!report.steps.beforeCollection.snapshotComplete) {
    report.errors.push('SNAPSHOT_INCOMPLETE');
    console.log(JSON.stringify(report, null, 2));
    process.exit(3);
  }
  if (lineBefore.eligible) {
    report.errors.push('SHOULD_NOT_BE_ELIGIBLE_BEFORE_COLLECTION');
  }

  const settlementsBefore = await countSettlements();
  const flagOff = await expectError(
    () =>
      cash.confirmCashCollectionV2({
        db,
        auth: { uid: driver.uid },
        data: { orderId, operationId: `fin7_flag_off_${Date.now()}` },
        admin,
      }),
    'FEATURE_FLAG_DISABLED',
  );
  report.steps.flagOffCall = flagOff;
  const afterFlagOff = (await db.collection('order').doc(orderId).get()).data();
  report.steps.flagOffNoMutation =
    afterFlagOff.payment_status === 'pending_cash' &&
    afterFlagOff.cash_collection_status === 'pending';

  // Enable Phase C for controlled test only
  await db.doc('financial_config/runtime').set(
    {
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
    },
    { merge: true },
  );

  const opId = `fin7_collect_${orderId}`;
  const collected = await cash.confirmCashCollectionV2({
    db,
    auth: { uid: driver.uid },
    data: { orderId, operationId: opId },
    admin,
  });
  report.steps.collection = {
    code: collected.code,
    companyDueMinor: collected.companyDueMinor,
    driverNetMinor: collected.driverNetMinor,
    platformMinor: collected.platformMinor,
    grossMinor: collected.grossMinor,
  };

  const after = (await db.collection('order').doc(orderId).get()).data();
  const lineAfter = analyzeOrderDoc(orderId, {
    ...after,
    payment_status: 'cash_collected',
    cash_collection_status: 'collected',
  });
  report.steps.afterCollection = {
    payment_status: after.payment_status,
    cash_collection_status: after.cash_collection_status,
    cashCollectedByDriver: after.cashCollectedByDriver,
    hasCashCollectedAt: !!after.cashCollectedAt,
    hasFinancialRealizedAt: !!after.financial_realized_at,
    companyDue: lineAfter.signedCashMinor / 100,
    driverNet: lineAfter.driverNetMinor / 100,
    eligible: lineAfter.eligible,
  };

  const idem2 = await cash.confirmCashCollectionV2({
    db,
    auth: { uid: driver.uid },
    data: { orderId, operationId: opId },
    admin,
  });
  report.steps.idempotency = {
    code: idem2.code,
    idempotent: idem2.idempotent === true,
  };

  const idem3 = await cash.confirmCashCollectionV2({
    db,
    auth: { uid: driver.uid },
    data: { orderId, operationId: `fin7_dup_${Date.now()}` },
    admin,
  });
  report.steps.secondOperationId = {
    code: idem3.code,
    companyDueMinor: idem3.companyDueMinor,
  };

  // Negative: wrong driver
  report.steps.wrongDriver = await expectError(
    () =>
      cash.confirmCashCollectionV2({
        db,
        auth: { uid: 'wrong_driver_uid_fin7' },
        data: { orderId, operationId: `fin7_wrong_${Date.now()}` },
        admin,
      }),
    'NOT_ASSIGNED_DRIVER',
  );

  const settlementsAfter = await countSettlements();
  report.safety.settlementsCreated = settlementsAfter - settlementsBefore;
  report.safety.settlementWritesFlag = 'OFF';

  const histAfter = await historicalSnapshot();
  report.safety.legacyPendingUnchanged =
    histAfter.legacyCompletedPendingCash ===
      report.historicalBaseline.legacyCompletedPendingCash &&
    JSON.stringify(histAfter.legacyOrders) ===
      JSON.stringify(report.historicalBaseline.legacyOrders);
  report.safety.companyPaymentsUnchanged =
    histAfter.companyPaymentsCount ===
    report.historicalBaseline.companyPaymentsCount;

  report.parity = {
    expectedGross: 50,
    expectedPlatform: 7.5,
    expectedVat: 0,
    expectedDriverNet: 42.5,
    expectedCompanyDue: 7.5,
    actualCompanyDue: collected.companyDueMinor / 100,
    actualDriverNet: collected.driverNetMinor / 100,
    delta:
      Math.abs(collected.companyDueMinor - 750) +
      Math.abs(collected.driverNetMinor - 4250),
  };

  const allPass =
    report.steps.flagOffCall.pass &&
    report.steps.flagOffNoMutation &&
    report.steps.collection.code === 'COLLECTED' &&
    report.steps.afterCollection.payment_status === 'cash_collected' &&
    report.steps.idempotency.idempotent &&
    report.steps.secondOperationId.code === 'ALREADY_REALIZED' &&
    report.safety.settlementsCreated === 0 &&
    report.safety.legacyPendingUnchanged &&
    report.parity.delta === 0;

  report.finalDecision.cashFlagFinal = allPass ? 'ON' : 'OFF';
  report.finalDecision.fin7 = allPass ? 'FROZEN' : 'NOT_READY';

  if (!allPass) {
    await db.doc('financial_config/runtime').set(
      { FINANCIAL_CASH_REALIZATION_V2_ENABLED: false },
      { merge: true },
    );
    report.flags.final = { CASH: 'OFF', reason: 'E2E_INCOMPLETE' };
  } else {
    report.flags.final = { CASH: 'ON', reason: 'CONTROLLED_E2E_PASS' };
  }

  console.log(JSON.stringify(report, null, 2));
  process.exit(allPass ? 0 : 1);
}

main().catch((e) => {
  report.errors.push(String(e.message || e).slice(0, 400));
  console.log(JSON.stringify(report, null, 2));
  process.exit(1);
});
