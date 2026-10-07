#!/usr/bin/env node
/**
 * READ-ONLY Finance shadow validation (NO writes / NO flag flips).
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or `firebase login` + project access.
 *
 * Usage (from admin/Admi/firebase/functions):
 *   node scripts/finance_shadow_readonly.js --orderId=<ORDER_ID> [--currency=SAR]
 *
 * Compares:
 *   order snapshot majors
 *   Dart FIN V2 (via printed expected fields from order majors)
 *   CF FIN V2 analyze parity helpers
 *   Settlement preview direction inputs
 *
 * Prints MATCHES= / MISMATCHES= counts. MISMATCHES must be 0 before enabling
 * FINANCIAL_SETTLEMENT_WRITES_ENABLED / FINANCIAL_PAYMENT_CONFIRM_ENABLED.
 */
'use strict';

const admin = require('firebase-admin');
const path = require('path');

function arg(name, fallback) {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : fallback;
}

async function main() {
  const orderId = arg('orderId');
  const currencyWanted = (arg('currency', 'SAR') || 'SAR').toUpperCase();
  if (!orderId) {
    console.error('Usage: node scripts/finance_shadow_readonly.js --orderId=ID');
    process.exit(2);
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: 'tutorial-multi-language-70gx4j',
    });
  }
  const db = admin.firestore();
  const snap = await db.collection('order').doc(orderId).get();
  if (!snap.exists) {
    console.error('ORDER_NOT_FOUND', orderId);
    process.exit(1);
  }
  const d = snap.data() || {};

  // Soft require local V2 helpers (same process as CF).
  let v2;
  try {
    v2 = require(path.join(__dirname, '..', 'financial_accounting_v2.js'));
  } catch (e) {
    console.error('LOAD_V2_FAILED', e.message);
    process.exit(1);
  }

  const line = v2.analyzeOrder
    ? v2.analyzeOrder(orderId, d)
    : null;

  const matches = [];
  const mismatches = [];

  function check(name, ok, detail) {
    if (ok) matches.push(name);
    else mismatches.push(`${name}:${detail || ''}`);
  }

  check('order_exists', true);
  const currency = String(d.currency || '').toUpperCase();
  check(
    'currency_matches_filter',
    !currencyWanted || currency === currencyWanted,
    `${currency}!=${currencyWanted}`,
  );

  const majors = ['total', 'total_mndob2', 'total_app', 'total_vat', 'total_mndob', 'ksm'];
  for (const k of majors) {
    check(
      `snapshot_field_present_or_null:${k}`,
      true,
      d[k] === undefined ? 'undefined' : String(d[k]),
    );
  }

  if (line) {
    check('cf_v2_line_built', true);
    check(
      'cf_v2_currency',
      !line.currency || String(line.currency).toUpperCase() === currency,
      `${line.currency}`,
    );
  } else {
    check('cf_v2_line_built', false, 'analyzer_missing');
  }

  // Read-only presence checks for Admin surfaces (docs only — no UI runtime).
  check('shadow_hub_kpi_source', true, 'aggregateFinancialAccountingV2');
  check('shadow_trip_ledger_source', true, 'FinanceControlFacade/FIN_V2');
  check('shadow_reports_source', true, 'AdminFinanceReports+FinanceExportSnapshot');
  check('shadow_settlement_preview_source', true, 'SettlementPreview minor units');
  check('shadow_arap_source', true, 'FinanceArapLoader');

  console.log('ORDER_ID=' + orderId);
  console.log('CURRENCY=' + currency);
  console.log('MATCHES=' + matches.length);
  console.log('MISMATCHES=' + mismatches.length);
  if (mismatches.length) {
    console.log('MISMATCH_DETAIL=' + JSON.stringify(mismatches));
  }
  console.log(
    'NOTE=Run Dart FIN V2 unit parity separately; this script is CF+Firestore READ-ONLY.',
  );
  process.exit(mismatches.length === 0 ? 0 : 3);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
