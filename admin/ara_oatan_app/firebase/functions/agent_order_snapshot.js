'use strict';

/**
 * F3-C2 / FIN-9 — Immutable agent attribution snapshot for NEW bookings.
 *
 * Canonical field contract (Admin agent_order_snapshot.js / F1 adapter):
 *   agent_id, agent_scope, agent_rate, agent_rate_type,
 *   agent_amount_minor, agent_amount, agent_currency,
 *   agent_snapshot_at, agent_snapshot_version, agent_attribution_status
 *   (+ agent_ambiguous_agent_ids when ambiguous)
 *
 * Statuses:
 *   attributed | none | ambiguous | rate_missing | platform_missing
 *
 * Equation (percent_of_platform_fee):
 *   agent_amount_minor = round(platformFeeMinor * Agent_total / 100)
 *
 * Does NOT change customer total, driver net, VAT, or platform fee.
 * Does NOT invent a commission when config is invalid — explicit status only.
 */

const SNAPSHOT_VERSION = 'FIN-9';
const RATE_TYPE = 'percent_of_platform_fee';

function str(v) {
  return v == null ? '' : String(v).trim();
}

/**
 * Canonical agent share from platform fee minors + Agent_total percent.
 * Matches Admin FIN-9 / financial_accounting_v2 money rounding.
 */
function computeAgentAmountMinor(platformFeeMinor, ratePercent) {
  if (platformFeeMinor == null || ratePercent == null) return null;
  const platform = Number(platformFeeMinor);
  const rate = Number(ratePercent);
  if (!Number.isFinite(platform) || platform < 0) return null;
  if (!Number.isFinite(rate) || rate <= 0) return null;
  return Math.round((platform * rate) / 100);
}

function isActiveAgent(data) {
  if (!data || (data.Isagent !== true && data.isagent !== true)) return false;
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
  const path = str(countryPath);
  if (!path) return [];
  const countryRef = db.doc(path);
  const snap = await db
    .collection('user')
    .where('Isagent', '==', true)
    .where('Rev_dloh_agent', '==', countryRef)
    .get();
  return snap.docs.filter((d) => isActiveAgent(d.data()));
}

/**
 * Build immutable agent snapshot fields for a booking create.
 *
 * @param {object} args
 * @param {*} args.db Firestore
 * @param {string} args.countryPath e.g. countries/saudi_arabia
 * @param {number} args.platformFeeHalalas integer minors from verified quote (appFeeHalalas)
 * @param {string} [args.currency]
 * @param {string} [args.nowIso] optional fixed clock for tests
 */
async function buildBookingAgentSnapshot({
  db,
  countryPath,
  platformFeeHalalas,
  currency,
  nowIso,
}) {
  const stampedAt = nowIso || new Date().toISOString();
  const platformMinor = Number(platformFeeHalalas);
  const cur = str(currency) || 'SAR';

  if (!Number.isFinite(platformMinor) || platformMinor < 0) {
    return {
      agent_attribution_status: 'platform_missing',
      agent_snapshot_at: stampedAt,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  const path = str(countryPath);
  if (!path) {
    return {
      agent_attribution_status: 'platform_missing',
      agent_snapshot_at: stampedAt,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  const agents = await resolveActiveAgents(db, path);

  if (agents.length === 0) {
    // Explicit NO_AGENT_AT_BOOKING (canonical status: none)
    return {
      agent_attribution_status: 'none',
      agent_snapshot_at: stampedAt,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  if (agents.length > 1) {
    // Never pick arbitrarily
    return {
      agent_attribution_status: 'ambiguous',
      agent_ambiguous_agent_ids: agents.map((d) => d.id).sort(),
      agent_snapshot_at: stampedAt,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  const agentDoc = agents[0];
  const agent = agentDoc.data() || {};
  // Do not coerce missing rate to a successful 0 attribution.
  const hasRateField =
    agent.Agent_total != null || agent.agent_total != null;
  const rate = Number(
    agent.Agent_total != null ? agent.Agent_total : agent.agent_total,
  );

  if (!hasRateField || !Number.isFinite(rate) || rate <= 0) {
    return {
      agent_attribution_status: 'rate_missing',
      agent_id: agentDoc.id,
      agent_scope: 'country_exclusive',
      agent_snapshot_at: stampedAt,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  const amountMinor = computeAgentAmountMinor(platformMinor, rate);
  if (amountMinor == null) {
    return {
      agent_attribution_status: 'rate_missing',
      agent_id: agentDoc.id,
      agent_scope: 'country_exclusive',
      agent_snapshot_at: stampedAt,
      agent_snapshot_version: SNAPSHOT_VERSION,
    };
  }

  return {
    agent_id: agentDoc.id,
    agent_scope: 'country_exclusive',
    agent_rate: rate,
    agent_rate_type: RATE_TYPE,
    agent_amount_minor: amountMinor,
    agent_amount: amountMinor / 100,
    agent_currency: cur,
    agent_snapshot_at: stampedAt,
    agent_snapshot_version: SNAPSHOT_VERSION,
    agent_attribution_status: 'attributed',
  };
}

module.exports = {
  SNAPSHOT_VERSION,
  RATE_TYPE,
  computeAgentAmountMinor,
  isActiveAgent,
  resolveActiveAgents,
  buildBookingAgentSnapshot,
};
