'use strict';

/**
 * Finance V3 — trip financial snapshot schema (prospective).
 * NO Firestore writes. Validation only for future CF / dry-run tools.
 */

const REQUIRED = [
  'schema_version',
  'generated_at',
  'order_id',
  'currency',
  'customer_total_minor',
  'platform_commission_minor',
  'vat_minor',
  'driver_net_minor',
  'confidence',
  'source',
];

function validateTripFinancialSnapshot(raw) {
  const errors = [];
  if (!raw || typeof raw !== 'object') {
    return {ok: false, errors: ['NOT_AN_OBJECT']};
  }
  for (const k of REQUIRED) {
    if (raw[k] === undefined || raw[k] === null || raw[k] === '') {
      errors.push(`MISSING_${k}`);
    }
  }
  const currency = String(raw.currency || '').trim().toUpperCase();
  if (!currency) errors.push('CURRENCY_EMPTY');
  const minors = [
    'customer_total_minor',
    'platform_commission_minor',
    'vat_minor',
    'driver_net_minor',
  ];
  for (const k of minors) {
    const n = Number(raw[k]);
    if (!Number.isFinite(n) || !Number.isInteger(n)) errors.push(`NOT_INT_${k}`);
  }
  const conf = String(raw.confidence || '');
  if (!['high', 'derived', 'incomplete'].includes(conf)) {
    errors.push('CONFIDENCE_INVALID');
  }
  return {ok: errors.length === 0, errors, currency};
}

function classifyAgentAttribution({agentId, agentsInCountryCount, hasRate}) {
  if (agentId && hasRate) return 'attributed';
  if (!hasRate && agentId) return 'missing_rate';
  if (agentsInCountryCount > 1) return 'ambiguous';
  if (agentsInCountryCount === 1 && hasRate) return 'attributed';
  if (agentsInCountryCount === 0) return 'unattributed';
  return 'legacy_unprovable';
}

module.exports = {
  validateTripFinancialSnapshot,
  classifyAgentAttribution,
  REQUIRED,
};
