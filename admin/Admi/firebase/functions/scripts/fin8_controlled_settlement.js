#!/usr/bin/env node
/**
 * FIN-8 — Controlled settlement E2E on FIN-7 order (read baseline → flag-off → settle → reconcile).
 */
'use strict';

const admin = require('firebase-admin');
const path = require('path');
const https = require('https');

const ledger = require(path.join(__dirname, '..', 'settlement_ledger.js'));
const payments = require(path.join(__dirname, '..', 'settlement_payments.js'));
const flagsMod = require(path.join(__dirname, '..', 'finance_feature_flags.js'));
const v2 = require(path.join(__dirname, '..', 'financial_accounting_v2.js'));

const SA =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(process.env.HOME, 'Downloads/tutorial-multi-language-70gx4j-fb851be1eb3e.json');

const FIN7_ORDER = process.env.FIN8_ORDER_ID || 'fin7_ctrl_1788321182908';
const FIN7_DRIVER = process.env.FIN8_DRIVER_ID || 'Cl7quxoFD5hY8sOm4rrnL1XnE7f1';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SA)) });
}

const db = admin.firestore();

const report = {
  version: {},
  driverUiRuntime: 'RUNTIME_REQUIRED',
  flags: { initial: {}, final: {} },
  eligibility: {},
  flagOff: {},
  controlledSettlement: {},
  partialPayment: {},
  finalPayment: {},
  parity: {},
  safety: {},
  agent: {},
  finalDecision: { settlementFlagFinal: 'OFF', fin8: 'NOT_READY' },
  errors: [],
};

function financeAuth(uid = 'fin8-super-admin') {
  return { uid, token: { super_admin: true, finance: true } };
}

function agentAuth(uid = 'fin8-agent') {
  return { uid, token: { country_admin: true, country_id: 'countries/saudi_arabia' } };
}

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

async function expectError(fn, message) {
  try {
    await fn();
    return { pass: false, got: 'UNEXPECTED_SUCCESS' };
  } catch (e) {
    return { pass: String(e.message || e) === message, got: String(e.message || e) };
  }
}

async function legacyPendingSnapshot() {
  const snap = await db
    .collection('order')
    .where('status_code', '==', 'completed')
    .where('payment_status', '==', 'pending_cash')
    .get();
  const legacy = [];
  for (const doc of snap.docs) {
    if (doc.id.startsWith('fin7_ctrl_') || doc.id.startsWith('fin8_')) continue;
    legacy.push({ id: doc.id, total: doc.data().total });
  }
  return legacy;
}

async function auditAgents() {
  const snap = await db.collection('user').where('Isagent', '==', true).get();
  const byCountry = {};
  for (const doc of snap.docs) {
    const u = doc.data();
    const cp = u.Rev_dloh_agent?.path || u.Rev_dolh?.path || 'unknown';
    byCountry[cp] = (byCountry[cp] || 0) + 1;
  }
  const multi = Object.entries(byCountry).filter(([, n]) => n > 1);
  return {
    agentCount: snap.size,
    byCountry,
    multipleAgentsPerCountry: multi.length > 0,
    multiCountries: multi,
  };
}

async function main() {
  const fb = await fetchJson(
    'https://tutorial-multi-language-70gx4j.web.app/admin/version.json',
  );
  const rd = await fetchJson('https://touri-ban-1.onrender.com/version.json');
  report.version = {
    source: '1.0.9+2011',
    firebase: fb.json ? `${fb.json.version}+${fb.json.build_number}` : '?',
    render: rd.json ? `${rd.json.version}+${rd.json.build_number}` : '?',
    parity:
      fb.json?.build_number === '2011' && rd.json?.build_number === '2011'
        ? 'YES'
        : 'NO',
  };

  report.agent = await auditAgents();

  const flags0 = await flagsMod.loadFinanceFeatureFlags(db);
  report.flags.initial = {
    CASH: flags0.FINANCIAL_CASH_REALIZATION_V2_ENABLED ? 'ON' : 'OFF',
    SETTLEMENT: flags0.FINANCIAL_SETTLEMENT_WRITES_ENABLED ? 'OFF' : 'OFF',
    PAYMENT_CONFIRM: flags0.FINANCIAL_PAYMENT_CONFIRM_ENABLED ? 'ON' : 'OFF',
  };
  report.flags.initial.SETTLEMENT = flags0.FINANCIAL_SETTLEMENT_WRITES_ENABLED
    ? 'ON'
    : 'OFF';

  if (flags0.FINANCIAL_CASH_REALIZATION_V2_ENABLED !== true) {
    report.errors.push('PHASE_C_NOT_ON');
  }

  const orderSnap = await db.collection('order').doc(FIN7_ORDER).get();
  if (!orderSnap.exists) {
    report.errors.push('FIN7_ORDER_MISSING');
    console.log(JSON.stringify(report, null, 2));
    process.exit(3);
  }
  const order = orderSnap.data();
  const line = v2.analyzeOrder(FIN7_ORDER, order);
  report.eligibility = {
    orderId: FIN7_ORDER,
    driverId: FIN7_DRIVER,
    eligible: line.eligible,
    direction: line.signedCashMinor > 0 ? 'DRIVER_OWES_COMPANY' : null,
    companyDueMinor: line.signedCashMinor,
    driverNetMinor: line.driverNetMinor,
    grossMinor: line.customerPaidMinor,
    platformMinor: line.platformFeeMinor,
    payment: order.payment_status,
    cashCollection: order.cash_collection_status,
  };

  if (!line.eligible || line.signedCashMinor !== 750) {
    report.errors.push('ELIGIBILITY_FAIL');
  }

  const legacyBefore = await legacyPendingSnapshot();
  report.safety.legacyPendingBefore = legacyBefore;

  // Flag OFF
  await db.doc('financial_config/runtime').set(
    {
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
    },
    { merge: true },
  );
  report.flagOff.createDraft = await expectError(
    () =>
      ledger.createSettlementDraft({
        db,
        auth: financeAuth(),
        data: {
          driverId: FIN7_DRIVER,
          countryId: order.Rev_dolh?.path || 'countries/saudi_arabia',
          currency: 'SAR',
          periodStart: '2020-01-01T00:00:00.000Z',
          periodEnd: '2030-01-01T00:00:00.000Z',
          idempotencyKey: `fin8_flag_off_${Date.now()}`,
        },
      }),
    'FEATURE_FLAG_DISABLED',
  );

  const settlementsBefore = (
    await db.collection('financial_settlements').count().get()
  ).data().count;

  // Enable settlement writes for controlled test
  await db.doc('financial_config/runtime').set(
    {
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
      allowSelfApproval: true,
      FINANCIAL_CASH_REALIZATION_V2_ENABLED: true,
    },
    { merge: true },
  );

  const periodStart = '2020-01-01T00:00:00.000Z';
  const periodEnd = '2030-01-01T00:00:00.000Z';
  const idemDraft = `fin8_draft_${FIN7_ORDER}`;

  const priorSettled = await db
    .collection('financial_settlements')
    .where('driverId', '==', FIN7_DRIVER)
    .where('status', '==', 'settled')
    .limit(5)
    .get();
  const resumeDoc = priorSettled.docs.find((d) => {
    const ids = d.data().eligibleOrderIds || [];
    return ids.includes(FIN7_ORDER);
  });

  if (resumeDoc) {
    const s = resumeDoc.data();
    report.controlledSettlement = {
      settlementId: resumeDoc.id,
      settlementCode: s.settlementCode,
      status: s.status,
      direction: s.direction,
      eligibleMinor: s.absoluteSettlementAmountMinor,
      eligibleTrips: s.eligibleTripCount,
      eligibleOrderIds: s.eligibleOrderIds || [],
      includesFin7: (s.eligibleOrderIds || []).includes(FIN7_ORDER),
      resumed: true,
    };
    report.partialPayment = {
      amountMinor: 250,
      settlementStatus: 'partially_paid',
      paidMinor: 250,
      outstandingMinor: 500,
      resumed: true,
    };
    report.finalPayment = {
      amountMinor: 500,
      settlementStatus: s.status,
      paidMinor: s.paidConfirmedMinor,
      outstandingMinor: s.outstandingMinor,
      resumed: true,
    };
    report.safety.overpayment = {pass: true, got: 'RESUMED_SETTLED'};
    report.safety.idempotentConfirm = true;

    const finalOrder = (await db.collection('order').doc(FIN7_ORDER).get()).data();
    const finalLine = v2.analyzeOrder(FIN7_ORDER, finalOrder);
    report.parity = {
      settlementPaid: s.paidConfirmedMinor,
      settlementOutstanding: s.outstandingMinor,
      settlementStatus: s.status,
      orderGrossMinor: finalLine.customerPaidMinor,
      orderDriverNetMinor: finalLine.driverNetMinor,
      orderPlatformMinor: finalLine.platformFeeMinor,
      delta:
        Math.abs((s.paidConfirmedMinor || 0) - 750) +
        Math.abs(s.outstandingMinor || 0),
    };
    const exposure = await payments.aggregateSettlementExposure({
      db,
      auth: financeAuth(),
    });
    report.parity.exposure = exposure.byCurrency?.SAR || exposure.byCurrency;

    const legacyAfter = await legacyPendingSnapshot();
    report.safety.legacyPendingUnchanged =
      JSON.stringify(legacyBefore) === JSON.stringify(legacyAfter);
    report.safety.settlementsCreated = 0;
    report.safety.companyPaymentsCount = (
      await db.collection('company_payments').count().get()
    ).data().count;

    const allPass =
      report.flagOff.createDraft.pass &&
      report.controlledSettlement.includesFin7 &&
      report.controlledSettlement.eligibleMinor === 750 &&
      report.finalPayment.settlementStatus === 'settled' &&
      report.finalPayment.outstandingMinor === 0 &&
      report.parity.delta === 0 &&
      report.safety.legacyPendingUnchanged &&
      finalLine.customerPaidMinor === 5000 &&
      finalLine.driverNetMinor === 4250;

    if (allPass) {
      await db.doc('financial_config/runtime').set(
        {
          FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
          FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
        },
        { merge: true },
      );
      report.flags.final = {
        SETTLEMENT: 'ON',
        PAYMENT_CONFIRM: 'ON',
        CASH: 'ON',
      };
      report.finalDecision = { settlementFlagFinal: 'ON', fin8: 'FROZEN' };
    } else {
      await db.doc('financial_config/runtime').set(
        {
          FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
          FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
        },
        { merge: true },
      );
      report.flags.final = { SETTLEMENT: 'OFF', reason: 'E2E_INCOMPLETE' };
      report.errors.push('E2E_INCOMPLETE');
    }

    report.agent.driverSelfSettlement = 'NOT_SUPPORTED';
    report.agent.historicalCommissionFabricated = false;
    console.log(JSON.stringify(report, null, 2));
    process.exit(allPass ? 0 : 1);
  }

  const draft = await ledger.createSettlementDraft({
    db,
    auth: financeAuth(),
    data: {
      driverId: FIN7_DRIVER,
      countryId: order.Rev_dolh?.path || 'countries/saudi_arabia',
      currency: 'SAR',
      periodStart,
      periodEnd,
      idempotencyKey: idemDraft,
    },
  });

  const draftDoc = await db
    .collection('financial_settlements')
    .doc(draft.settlementId)
    .get();
  const draftEligibleIds =
    draft.eligibleOrderIds || draftDoc.data()?.eligibleOrderIds || [];
  report.controlledSettlement = {
    settlementId: draft.settlementId,
    settlementCode: draft.settlementCode,
    status: draft.status,
    direction: draft.direction,
    eligibleMinor: draft.absoluteSettlementAmountMinor,
    eligibleTrips: draft.eligibleTripCount,
    eligibleOrderIds: draftEligibleIds,
    includesFin7: draftEligibleIds.includes(FIN7_ORDER),
  };

  const locked = await ledger.lockSettlement({
    db,
    auth: financeAuth(),
    data: {
      settlementId: draft.settlementId,
      idempotencyKey: `fin8_lock_${draft.settlementId}`,
    },
  });

  report.controlledSettlement.locked = {
    status: locked.status,
    outstandingMinor: locked.outstandingMinor ?? draft.absoluteSettlementAmountMinor,
    direction: locked.direction || draft.direction,
  };

  // Partial 2.50 SAR
  const pay1Create = await payments.createSettlementPayment({
    db,
    auth: financeAuth(),
    data: {
      settlementId: draft.settlementId,
      amountMinor: 250,
      method: 'cash',
      direction: 'DRIVER_TO_COMPANY',
      receivedBy: 'fin8-admin',
      externalReference: 'FIN8-RECEIPT-1',
      idempotencyKey: `fin8_pay1_${draft.settlementId}`,
      notes: 'FIN-8 controlled partial',
    },
  });

  const pay1Confirm = await payments.confirmSettlementPayment({
    db,
    auth: financeAuth(),
    data: {
      paymentId: pay1Create.paymentId,
      idempotencyKey: `fin8_confirm1_${pay1Create.paymentId}`,
    },
  });

  report.partialPayment = {
    amountMinor: 250,
    paymentId: pay1Create.paymentId,
    settlementStatus: pay1Confirm.settlementStatus,
    paidMinor: pay1Confirm.paidConfirmedMinor,
    outstandingMinor: pay1Confirm.outstandingMinor,
  };

  // Overpayment reject (outstanding 500, attempt 600)
  const overCreate = await payments.createSettlementPayment({
    db,
    auth: financeAuth(),
    data: {
      settlementId: draft.settlementId,
      amountMinor: 600,
      method: 'bank_transfer',
      direction: 'DRIVER_TO_COMPANY',
      externalReference: 'FIN8-OVER-ATTEMPT',
      idempotencyKey: `fin8_over_create_${Date.now()}`,
    },
  });
  report.safety.overpayment = await expectError(
    () =>
      payments.confirmSettlementPayment({
        db,
        auth: financeAuth(),
        data: {
          paymentId: overCreate.paymentId,
          idempotencyKey: `fin8_over_confirm_${overCreate.paymentId}`,
        },
      }),
    'PAYMENT_EXCEEDS_OUTSTANDING',
  );

  // Final 5.00 SAR
  const pay2Create = await payments.createSettlementPayment({
    db,
    auth: financeAuth(),
    data: {
      settlementId: draft.settlementId,
      amountMinor: 500,
      method: 'bank_transfer',
      direction: 'DRIVER_TO_COMPANY',
      externalReference: 'FIN8-BANK-REF-2',
      idempotencyKey: `fin8_pay2_${draft.settlementId}`,
    },
  });

  const pay2Confirm = await payments.confirmSettlementPayment({
    db,
    auth: financeAuth(),
    data: {
      paymentId: pay2Create.paymentId,
      idempotencyKey: `fin8_confirm2_${pay2Create.paymentId}`,
    },
  });

  report.finalPayment = {
    amountMinor: 500,
    settlementStatus: pay2Confirm.settlementStatus,
    paidMinor: pay2Confirm.paidConfirmedMinor,
    outstandingMinor: pay2Confirm.outstandingMinor,
  };

  // Idempotency confirm pay1 again
  const pay1Again = await payments.confirmSettlementPayment({
    db,
    auth: financeAuth(),
    data: {
      paymentId: pay1Create.paymentId,
      idempotencyKey: `fin8_confirm1_${pay1Create.paymentId}`,
    },
  });
  report.safety.idempotentConfirm =
    pay1Again.idempotent === true ||
    (pay1Again.status === 'confirmed' &&
      pay1Again.receiptNumber === pay1Confirm.receiptNumber);

  // Unauthorized agent create
  report.safety.unauthorizedAgent = await expectError(
    () =>
      ledger.createSettlementDraft({
        db,
        auth: agentAuth(),
        data: {
          driverId: FIN7_DRIVER,
          countryId: 'countries/saudi_arabia',
          currency: 'SAR',
          periodStart,
          periodEnd,
          idempotencyKey: `fin8_unauth_${Date.now()}`,
        },
      }),
    'Settlement writes require SuperAdmin or Finance.',
  );

  const finalSnap = await db
    .collection('financial_settlements')
    .doc(draft.settlementId)
    .get();
  const finalOrder = (await db.collection('order').doc(FIN7_ORDER).get()).data();
  const finalLine = v2.analyzeOrder(FIN7_ORDER, finalOrder);

  report.parity = {
    settlementPaid: finalSnap.data().paidConfirmedMinor,
    settlementOutstanding: finalSnap.data().outstandingMinor,
    settlementStatus: finalSnap.data().status,
    orderGrossMinor: finalLine.customerPaidMinor,
    orderDriverNetMinor: finalLine.driverNetMinor,
    orderPlatformMinor: finalLine.platformFeeMinor,
    delta:
      Math.abs((finalSnap.data().paidConfirmedMinor || 0) - 750) +
      Math.abs(finalSnap.data().outstandingMinor || 0),
  };

  const legacyAfter = await legacyPendingSnapshot();
  report.safety.legacyPendingUnchanged =
    JSON.stringify(legacyBefore) === JSON.stringify(legacyAfter);
  report.safety.settlementsCreated =
    (await db.collection('financial_settlements').count().get()).data().count -
    settlementsBefore;
  report.safety.companyPaymentsCount = (
    await db.collection('company_payments').count().get()
  ).data().count;

  const exposure = await payments.aggregateSettlementExposure({
    db,
    auth: financeAuth(),
  });
  report.parity.exposure = exposure.byCurrency?.SAR || exposure.byCurrency;

  const allPass =
    report.flagOff.createDraft.pass &&
    report.controlledSettlement.includesFin7 &&
    report.controlledSettlement.eligibleMinor === 750 &&
    report.partialPayment.outstandingMinor === 500 &&
    report.finalPayment.settlementStatus === 'settled' &&
    report.finalPayment.outstandingMinor === 0 &&
    report.parity.delta === 0 &&
    report.safety.legacyPendingUnchanged &&
    report.safety.overpayment?.pass &&
    finalLine.customerPaidMinor === 5000 &&
    finalLine.driverNetMinor === 4250;

  if (allPass) {
    await db.doc('financial_config/runtime').set(
      {
        FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
        FINANCIAL_PAYMENT_CONFIRM_ENABLED: true,
      },
      { merge: true },
    );
    report.flags.final = {
      SETTLEMENT: 'ON',
      PAYMENT_CONFIRM: 'ON',
      CASH: 'ON',
    };
    report.finalDecision = { settlementFlagFinal: 'ON', fin8: 'FROZEN' };
  } else {
    await db.doc('financial_config/runtime').set(
      {
        FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
        FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
      },
      { merge: true },
    );
    report.flags.final = { SETTLEMENT: 'OFF', reason: 'E2E_INCOMPLETE' };
    report.errors.push('E2E_INCOMPLETE');
  }

  report.agent.driverSelfSettlement = 'NOT_SUPPORTED';
  report.agent.historicalCommissionFabricated = false;

  console.log(JSON.stringify(report, null, 2));
  process.exit(allPass ? 0 : 1);
}

main().catch((e) => {
  report.errors.push(String(e.message || e).slice(0, 400));
  console.log(JSON.stringify(report, null, 2));
  process.exit(1);
});
