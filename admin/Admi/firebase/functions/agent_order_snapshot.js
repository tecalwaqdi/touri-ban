'use strict';

/**
 * FIN-9 — Prospective immutable Agent snapshot on NEW orders only.
 *
 * Business contract:
 * - Agent_total = percentage (0–100) of platform fee (total_app), matching legacy agent reports.
 * - One active agent per country → attributed snapshot.
 * - Zero agents → agent_attribution_status: none
 * - >1 active agents → ambiguous (no fabricated commission)
 *
 * Equation: agent_amount_minor = round(platformFeeMinor * Agent_total / 100)
 * Does NOT deduct from driver net / VAT / gross.
 */

const v2 = require('./financial_accounting_v2.js');

const SNAPSHOT_VERSION = 'FIN-9';
const RATE_TYPE = 'percent_of_platform_fee';

function str(v) {
  return v == null ? '' : String(v).trim();
}

function countryRefFromOrder(order) {
  const r = order.Rev_dolh || order.rev_dolh;
  if (!r) return null;
  if (typeof r === 'string') return r;
  if (r.path) return r.path;
  return null;
}

function isActiveAgent(data) {
  if (data.Isagent !== true && data.isagent !== true) return false;
  if (data.actev_user === false) return false;
  const now = Date.now();
  const end = data.agent_date_end;
  if (end && end.toDate) {
    if (end.toDate().getTime() < now) return false;
  } else if (end && typeof end === 'string') {
    const t = Date.parse(end);
    if (!Number.isNaN(t) && t < now) return false;
  }
  const start = data.agent_date_reg;
  if (start && start.toDate) {
    if (start.toDate().getTime() > now) return false;
  } else if (start && typeof start === 'string') {
    const t = Date.parse(start);
    if (!Number.isNaN(t) && t > now) return false;
  }
  return true;
}

async function resolveActiveAgents(db, countryPath) {
  const countryRef = db.doc(countryPath);
  const snap = await db
    .collection('user')
    .where('Isagent', '==', true)
    .where('Rev_dloh_agent', '==', countryRef)
    .get();
  return snap.docs.filter((d) => isActiveAgent(d.data()));
}

/**
 * Build merge patch for a new order. Returns null if snapshot should not be written.
 */
async function buildAgentSnapshotPatch(db, orderId, order) {
  if (str(order.agent_id) || str(order.agent_snapshot_at)) {
    return null;
  }
  const countryPath = countryRefFromOrder(order);
  if (!countryPath) return null;

  const line = v2.analyzeOrder(orderId, order);
  const platformMinor = line.platformFeeMinor;
  if (platformMinor == null || platformMinor < 0) {
    return {
      agent_attribution_status: 'platform_missing',
      agent_snapshot_at: new Date().toISOString(),
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  const agents = await resolveActiveAgents(db, countryPath);
  const nowIso = new Date().toISOString();

  if (agents.length === 0) {
    return {
      agent_attribution_status: 'none',
      agent_snapshot_at: nowIso,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  if (agents.length > 1) {
    return {
      agent_attribution_status: 'ambiguous',
      agent_ambiguous_agent_ids: agents.map((d) => d.id).sort(),
      agent_snapshot_at: nowIso,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  const agentDoc = agents[0];
  const agent = agentDoc.data();
  const rate = Number(agent.Agent_total || 0);
  if (!Number.isFinite(rate) || rate <= 0) {
    return {
      agent_attribution_status: 'rate_missing',
      agent_id: agentDoc.id,
      agent_scope: 'country_exclusive',
      agent_snapshot_at: nowIso,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  const amountMinor = Math.round((platformMinor * rate) / 100);
  const currency = line.currency || str(agent.agent_currency_code) || 'SAR';

  return {
    agent_id: agentDoc.id,
    agent_scope: 'country_exclusive',
    agent_rate: rate,
    agent_rate_type: RATE_TYPE,
    agent_amount_minor: amountMinor,
    agent_amount: amountMinor / 100,
    agent_currency: currency,
    agent_snapshot_at: nowIso,
    agent_snapshot_version: SNAPSHOT_VERSION,
    agent_attribution_status: 'attributed',
  };
}

async function applyAgentSnapshotOnCreate({db, orderId, order}) {
  const patch = await buildAgentSnapshotPatch(db, orderId, order);
  if (!patch) return {applied: false, reason: 'skipped'};
  await db.collection('order').doc(orderId).set(patch, {merge: true});
  return {applied: true, patch};
}

module.exports = {
  SNAPSHOT_VERSION,
  RATE_TYPE,
  buildAgentSnapshotPatch,
  applyAgentSnapshotOnCreate,
  resolveActiveAgents,
  isActiveAgent,
};
