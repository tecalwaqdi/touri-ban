'use strict';

/**
 * F3-B1 — Live READ-ONLY reconciliation census.
 * Project: tutorial-multi-language-70gx4j
 *
 * NO WRITES. Mirrors B1 exclusion + axis classification for reporting.
 * Usage: node scripts/f3b1_live_reconciliation_readonly.js
 */

const admin = require('firebase-admin');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FIREBASE_CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
const FIXTURE_ID = /^(fin7_ctrl_|fin9_ctrl_|fin_rt_cash_|fin_rt_cash_ui_|fin_rt_)/;

async function initDb() {
  try {
    admin.initializeApp({projectId: PROJECT_ID});
    await admin.firestore().collection('order').limit(1).get();
    return admin.firestore();
  } catch (_) {
    try {
      admin.app().delete();
    } catch (e2) {
      /* ignore */
    }
  }
  const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(cfgPath)) throw new Error('No ADC / firebase-tools login');
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  const refreshToken = cfg.tokens && cfg.tokens.refresh_token;
  if (!refreshToken) throw new Error('No refresh token');
  const {GoogleAuth} = require('google-auth-library');
  const auth = new GoogleAuth({
    credentials: {
      type: 'authorized_user',
      client_id: FIREBASE_CLI_CLIENT_ID,
      client_secret: FIREBASE_CLI_CLIENT_SECRET,
      refresh_token: refreshToken,
    },
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    projectId: PROJECT_ID,
  });
  const authClient = await auth.getClient();
  const {Firestore} = require('@google-cloud/firestore');
  return new Firestore({projectId: PROJECT_ID, authClient});
}

function isQa(data, id) {
  if (data.is_test_fixture === true || data.qa_fixture === true || data.test_fixture === true) {
    return true;
  }
  if (data.functional_test === true) return true;
  if (String(data.golden_cycle || '').trim() === 'TOURi_GOLDEN_1') return true;
  if (FIXTURE_ID.test(String(id || ''))) return true;
  return false;
}

function isCompleted(data) {
  const sc = String(data.status_code || '').trim().toLowerCase();
  if (sc === 'completed' || sc === 'trip_completed') return true;
  if (!sc) {
    const h = String(data.halh || data.Halh || '').trim();
    // Frozen Arabic complete fallback only when status_code empty — minimal probe.
    if (h.includes('مكتمل') || h.toLowerCase() === 'completed') return true;
  }
  return false;
}

function has(data, key) {
  return Object.prototype.hasOwnProperty.call(data, key) && data[key] != null;
}

function financialStatus(data) {
  if (has(data, 'total_mndob2') && has(data, 'total_app') && has(data, 'total_vat') && has(data, 'total_mndob')) {
    return 'COMPLETE';
  }
  const any =
    has(data, 'total_mndob2') ||
    has(data, 'total_app') ||
    has(data, 'total_mndob') ||
    has(data, 'total');
  return any ? 'PARTIAL' : 'UNRESOLVED';
}

function paymentMethod(data) {
  const raw = String(data.PaymentMethod || data.paymentMethod || '').toLowerCase();
  if (raw.includes('cash')) return 'CASH';
  if (raw.includes('online')) return 'ONLINE';
  return 'UNKNOWN';
}

function collectionStatus(data, method) {
  if (method === 'ONLINE') return 'NOT_APPLICABLE';
  const pay = String(data.payment_status || '').toLowerCase();
  const cash = String(data.cash_collection_status || '').toLowerCase();
  if (pay === 'cash_collected' || cash === 'collected') return 'COLLECTED';
  if (method === 'CASH') return 'UNCOLLECTED';
  return 'UNKNOWN';
}

function agentStatus(data) {
  const st = String(data.agent_attribution_status || '').trim().toLowerCase();
  const id = String(data.agent_id || '').trim();
  const amt = data.agent_amount_minor;
  if (st === 'none') return 'NONE';
  if (st === 'ambiguous') return 'AMBIGUOUS';
  if (st === 'rate_missing' || st === 'platform_missing') return 'UNRESOLVED';
  if (st === 'attributed' || st === 'snapshot') {
    return id && amt != null ? 'COMPLETE' : 'UNRESOLVED';
  }
  if (!st && !id && amt == null && data.agent_rate == null) return 'MISSING';
  if (id && amt != null) return 'COMPLETE';
  if (id || amt != null || data.agent_rate != null) return 'UNRESOLVED';
  return 'MISSING';
}

function reconStatus(op, fin, agent, collection, method, linkedSettlement) {
  if (!op) return 'BLOCKED_BY_MISSING_DATA';
  if (fin === 'PARTIAL' || fin === 'UNRESOLVED' || agent === 'MISSING' || agent === 'UNRESOLVED') {
    return 'BLOCKED_BY_MISSING_DATA';
  }
  if (agent === 'AMBIGUOUS') return 'NEEDS_REVIEW';
  if (method === 'CASH' && collection === 'UNCOLLECTED') return 'NEEDS_REVIEW';
  if (!linkedSettlement) return 'NEEDS_REVIEW';
  return 'RECONCILED';
}

async function main() {
  const db = await initDb();
  const ordersSnap = await db.collection('order').limit(2000).get();
  const settlementsSnap = await db.collection('financial_settlements').limit(500).get();

  const orderIdsInSettlements = new Set();
  let realSettlements = 0;
  let qaSettlements = 0;
  for (const doc of settlementsSnap.docs) {
    const d = doc.data() || {};
    if (isQa(d, doc.id) || String(d.idempotencyKey || '').toLowerCase().startsWith('fin8_')) {
      qaSettlements++;
      continue;
    }
    realSettlements++;
    for (const key of ['eligibleOrderIds', 'orderIds', 'lineOrderIds']) {
      const list = d[key];
      if (!Array.isArray(list)) continue;
      for (const id of list) orderIdsInSettlements.add(String(id));
    }
  }

  let qaExcluded = 0;
  let completed = 0;
  let finComplete = 0;
  let finPartial = 0;
  let finUnresolved = 0;
  let cashCollected = 0;
  let cashUncollected = 0;
  let agentComplete = 0;
  let agentMissing = 0;
  let agentNone = 0;
  let agentAmbiguous = 0;
  let agentUnresolved = 0;
  let settled = 0;
  let unsettled = 0;
  let reconciled = 0;
  let needsReview = 0;
  let blocked = 0;

  // company_payments unallocated probe
  let unallocCount = 0;
  let unallocAmount = 0;
  try {
    const cp = await db.collection('company_payments').limit(500).get();
    for (const doc of cp.docs) {
      const d = doc.data() || {};
      if (isQa(d, doc.id)) continue;
      const allocated = d.settlementId || d.financial_settlement_id || d.allocatedSettlementId;
      if (allocated) continue;
      unallocCount++;
      const amt = Number(d.amountMinor ?? d.amount_minor ?? d.amount ?? 0);
      if (Number.isFinite(amt)) unallocAmount += amt;
    }
  } catch (e) {
    // collection may not exist / permission — report unknown
    unallocCount = -1;
  }

  for (const doc of ordersSnap.docs) {
    const d = doc.data() || {};
    if (isQa(d, doc.id)) {
      qaExcluded++;
      continue;
    }
    if (!isCompleted(d)) continue;
    completed++;
    const fin = financialStatus(d);
    if (fin === 'COMPLETE') finComplete++;
    else if (fin === 'PARTIAL') finPartial++;
    else finUnresolved++;

    const method = paymentMethod(d);
    const coll = collectionStatus(d, method);
    if (method === 'CASH' && coll === 'COLLECTED') cashCollected++;
    if (method === 'CASH' && coll === 'UNCOLLECTED') cashUncollected++;

    const agent = agentStatus(d);
    if (agent === 'COMPLETE') agentComplete++;
    else if (agent === 'MISSING') agentMissing++;
    else if (agent === 'NONE') agentNone++;
    else if (agent === 'AMBIGUOUS') agentAmbiguous++;
    else agentUnresolved++;

    const linked = orderIdsInSettlements.has(doc.id);
    if (linked) settled++;
    else unsettled++;

    const recon = reconStatus(true, fin, agent, coll, method, linked);
    if (recon === 'RECONCILED') reconciled++;
    else if (recon === 'NEEDS_REVIEW') needsReview++;
    else blocked++;
  }

  const out = {
    PROJECT_ID,
    MODE: 'READ_ONLY',
    ORDERS_SCANNED: ordersSnap.size,
    QA_EXCLUDED: qaExcluded,
    REAL_COMPLETED: completed,
    FINANCIAL_COMPLETE: finComplete,
    FINANCIAL_PARTIAL: finPartial,
    FINANCIAL_UNRESOLVED: finUnresolved,
    CASH_COLLECTED: cashCollected,
    CASH_UNCOLLECTED: cashUncollected,
    AGENT_COMPLETE: agentComplete,
    AGENT_MISSING: agentMissing,
    AGENT_NONE: agentNone,
    AGENT_AMBIGUOUS: agentAmbiguous,
    AGENT_UNRESOLVED: agentUnresolved,
    REAL_SETTLEMENTS: realSettlements,
    QA_SETTLEMENTS: qaSettlements,
    SETTLED_TRIPS_LINKED: settled,
    UNSETTLED_TRIPS: unsettled,
    RECONCILED: reconciled,
    NEEDS_REVIEW: needsReview,
    BLOCKED_BY_MISSING_DATA: blocked,
    UNALLOCATED_COMPANY_PAYMENTS_COUNT: unallocCount,
    UNALLOCATED_COMPANY_PAYMENTS_AMOUNT_RAW: unallocAmount,
    AUTO_MATCHED: 0,
    WRITES: 0,
  };
  console.log(JSON.stringify(out, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
