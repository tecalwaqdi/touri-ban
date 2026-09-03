#!/usr/bin/env node
'use strict';

/**
 * Finance V3 historical scan — DRY RUN ONLY.
 *
 * Usage:
 *   DRY_RUN=true node scripts/finance_v3_historical_scan_dry_run.js
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or Firebase admin default in CI.
 * Does NOT write. Does NOT invent agent rates for history.
 *
 * If credentials missing: exits 0 with SKIPPED (safe for local without SA).
 */

const path = require('path');
const snap = require('../financial_snapshot_v3');
const v2 = require('../financial_accounting_v2');

async function main() {
  const dry = String(process.env.DRY_RUN || 'true').toLowerCase() !== 'false';
  if (!dry) {
    console.error('REFUSING: DRY_RUN=false is not supported by this script.');
    console.error('Apply path requires explicit future tool + backup + approval.');
    process.exit(2);
  }

  let admin;
  try {
    admin = require('firebase-admin');
  } catch (e) {
    console.log(JSON.stringify({status: 'SKIPPED', reason: 'firebase-admin_not_installed'}));
    return;
  }

  if (!admin.apps.length) {
    try {
      admin.initializeApp();
    } catch (e) {
      console.log(JSON.stringify({status: 'SKIPPED', reason: 'admin_init_failed', message: String(e.message || e)}));
      return;
    }
  }

  const db = admin.firestore();
  let ordersSnap;
  try {
    ordersSnap = await db.collection('order').limit(5000).get();
  } catch (e) {
    console.log(JSON.stringify({
      status: 'SKIPPED',
      reason: 'firestore_read_failed',
      message: String(e.message || e),
      hint: 'Provide valid ADC / GOOGLE_APPLICATION_CREDENTIALS for live dry-run',
    }));
    return;
  }
  const summary = {
    status: 'DRY_RUN_OK',
    scanned: 0,
    byLifecycle: {},
    byConfidence: {},
    byAgentStatus: {},
    missingCurrency: 0,
    completedMissingDriver: 0,
    hasFinancialSnapshot: 0,
    sampleUnprovable: [],
  };

  ordersSnap.forEach((doc) => {
    summary.scanned += 1;
    const data = {id: doc.id, ...doc.data()};
    const line = v2.analyzeOrder(doc.id, data);
    summary.byLifecycle[line.lifecycle] = (summary.byLifecycle[line.lifecycle] || 0) + 1;
    summary.byConfidence[line.confidence] = (summary.byConfidence[line.confidence] || 0) + 1;
    if (!line.currency) summary.missingCurrency += 1;
    if (line.lifecycle === 'completed' && !line.driverId) summary.completedMissingDriver += 1;
    if (data.financial_snapshot) summary.hasFinancialSnapshot += 1;

    const agentStatus = snap.classifyAgentAttribution({
      agentId: data.agent_id || null,
      agentsInCountryCount: 0, // country fan-out requires separate join; mark unprovable without inventing
      hasRate: data.agent_rate != null || data.Agent_total != null,
    });
    // Without country agent census, historical default is legacy_unprovable unless per-order agent_id exists.
    const status = data.agent_id
      ? agentStatus
      : (data.financial_snapshot && data.financial_snapshot.agent_attribution_status) ||
        'legacy_unprovable';
    summary.byAgentStatus[status] = (summary.byAgentStatus[status] || 0) + 1;
    if (status === 'legacy_unprovable' && summary.sampleUnprovable.length < 10) {
      summary.sampleUnprovable.push(doc.id);
    }
  });

  console.log(JSON.stringify(summary, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
