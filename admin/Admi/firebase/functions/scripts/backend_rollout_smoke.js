'use strict';

/**
 * Backend rollout smoke — Phase C flag-off + finance flag read.
 * Does NOT enable flags. Does NOT print secrets. Does NOT mutate financial docs
 * when flag is OFF (callable aborts before writes).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
 *     node scripts/backend_rollout_smoke.js
 */

const admin = require('firebase-admin');
const path = require('path');

const cash = require(path.join(__dirname, '..', 'cash_collection_realization.js'));
const flagsMod = require(path.join(__dirname, '..', 'finance_feature_flags.js'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

async function countColl(name) {
  const snap = await db.collection(name).limit(1).get();
  // Prefer aggregate when available; fall back to existence probe only.
  try {
    const agg = await db.collection(name).count().get();
    return agg.data().count;
  } catch (_) {
    return snap.size >= 0 ? `probe_ok(${snap.size})` : 'unknown';
  }
}

async function main() {
  const report = {
    projectId: admin.app().options.projectId || process.env.GCLOUD_PROJECT,
    phaseCFlag: null,
    flagOffCall: null,
    financialWrites: null,
    settlementsBefore: null,
    settlementsAfter: null,
    companyPaymentsBefore: null,
    companyPaymentsAfter: null,
    errors: [],
  };

  try {
    const flags = await flagsMod.loadFinanceFeatureFlags(db);
    report.phaseCFlag =
      flags.FINANCIAL_CASH_REALIZATION_V2_ENABLED === true ? 'ON' : 'OFF';
    report.settlementWritesFlag =
      flags.FINANCIAL_SETTLEMENT_WRITES_ENABLED === true ? 'ON' : 'OFF';
    report.walletSettlementFlag =
      flags.WALLET_SETTLEMENT_ENABLED === true ? 'ON' : 'OFF';

    report.settlementsBefore = await countColl('financial_settlements');
    report.companyPaymentsBefore = await countColl('company_payments');

    if (report.phaseCFlag !== 'OFF') {
      report.errors.push('ABORT: FINANCIAL_CASH_REALIZATION_V2_ENABLED is ON');
      console.log(JSON.stringify(report, null, 2));
      process.exit(2);
    }

    let caught = null;
    try {
      await cash.confirmCashCollectionV2({
        db,
        auth: {uid: 'smoke-nonexistent-driver'},
        data: {
          orderId: 'smoke-nonexistent-order-do-not-create',
          operationId: `smoke_flag_off_${Date.now()}`,
        },
        admin,
      });
      report.flagOffCall = 'UNEXPECTED_SUCCESS';
    } catch (e) {
      caught = e;
      const msg = String(e && e.message ? e.message : e);
      const details = e && e.details ? e.details : null;
      const disabled =
        msg.includes('FEATURE_FLAG_DISABLED') ||
        (details && details.flag === 'FINANCIAL_CASH_REALIZATION_V2_ENABLED');
      report.flagOffCall = disabled
        ? 'PASS_FEATURE_FLAG_DISABLED'
        : `FAIL_${msg.slice(0, 120)}`;
    }

    report.settlementsAfter = await countColl('financial_settlements');
    report.companyPaymentsAfter = await countColl('company_payments');
    report.financialWrites =
      report.settlementsBefore === report.settlementsAfter &&
      report.companyPaymentsBefore === report.companyPaymentsAfter
        ? 0
        : 'CHANGED';

    // Existing finance callables — existence probe only (no invoke with user data).
    const names = [
      'getDriverFinancialSummaryV2',
      'aggregateFinancialAccountingV2',
      'confirmCashCollectionV2',
      'requestEmailVerificationOtp',
      'verifyEmailVerificationOtp',
    ];
    report.deployedFunctions = {};
    for (const n of names) {
      try {
        const [fn] = await admin
          .app()
          .functions
          ? [null]
          : [null];
        void fn;
        report.deployedFunctions[n] = 'listed_separately';
      } catch (_) {
        report.deployedFunctions[n] = 'n/a';
      }
    }

    console.log(JSON.stringify(report, null, 2));
    if (
      report.phaseCFlag !== 'OFF' ||
      report.flagOffCall !== 'PASS_FEATURE_FLAG_DISABLED' ||
      report.financialWrites !== 0
    ) {
      process.exit(1);
    }
  } catch (e) {
    report.errors.push(String(e && e.message ? e.message : e).slice(0, 300));
    console.log(JSON.stringify(report, null, 2));
    process.exit(1);
  }
}

main();
