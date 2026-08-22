'use strict';

/**
 * Aggregation metrics — no PII. Logged + returned for diagnostics.
 */

function callerRole(token) {
  if (!token) return 'anonymous';
  if (token.super_admin) return 'super_admin';
  if (token.finance) return 'finance';
  if (token.country_admin) return 'country_admin';
  if (token.agent) return 'agent';
  return 'other';
}

function buildAggregationMetrics({
  startedAtMs,
  ordersScanned,
  filters,
  resultCurrencyCount,
  cacheHit,
  token,
  op,
}) {
  return {
    op: op || 'aggregate',
    ordersScanned: Number(ordersScanned || 0),
    durationMs: Math.max(0, Date.now() - (startedAtMs || Date.now())),
    filters: filters || {},
    resultCurrencyCount: Number(resultCurrencyCount || 0),
    cacheHit: cacheHit === true,
    callerRole: callerRole(token),
    at: new Date().toISOString(),
  };
}

async function writeAggregationMetric(db, metrics) {
  try {
    await db.collection('financial_aggregation_metrics').doc().set({
      ...metrics,
    });
  } catch (_) {
    // Metrics must never break the main callable.
  }
}

module.exports = {
  callerRole,
  buildAggregationMetrics,
  writeAggregationMetric,
};
