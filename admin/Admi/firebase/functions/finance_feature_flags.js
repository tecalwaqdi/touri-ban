'use strict';

/**
 * Production feature flags for financial writes.
 * Defaults are OFF — first production money movement requires explicit enable.
 * Stored on financial_config/runtime (Admin SDK only).
 */

const DEFAULT_FLAGS = {
  FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
  FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
  FINANCIAL_CASH_REALIZATION_V2_ENABLED: false,
  WALLET_SETTLEMENT_ENABLED: false,
  AUTOMATIC_PAYOUT_ENABLED: false,
  /// Recognition engine: v2 (production) | v3 (snapshot-prefer when present).
  FINANCIAL_ENGINE_VERSION: 'v2',
};

async function loadFinanceFeatureFlags(db, tx) {
  const ref = db.doc('financial_config/runtime');
  const snap = tx ? await tx.get(ref) : await ref.get();
  const data = snap.exists ? snap.data() : {};
  return {
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: data.FINANCIAL_SETTLEMENT_WRITES_ENABLED === true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: data.FINANCIAL_PAYMENT_CONFIRM_ENABLED === true,
    FINANCIAL_CASH_REALIZATION_V2_ENABLED: data.FINANCIAL_CASH_REALIZATION_V2_ENABLED === true,
    WALLET_SETTLEMENT_ENABLED: data.WALLET_SETTLEMENT_ENABLED === true,
    AUTOMATIC_PAYOUT_ENABLED: data.AUTOMATIC_PAYOUT_ENABLED === true,
    FINANCIAL_ENGINE_VERSION:
      typeof data.FINANCIAL_ENGINE_VERSION === 'string' && data.FINANCIAL_ENGINE_VERSION
        ? String(data.FINANCIAL_ENGINE_VERSION)
        : DEFAULT_FLAGS.FINANCIAL_ENGINE_VERSION,
    independentApproverUids: Array.isArray(data.independentApproverUids)
      ? data.independentApproverUids.map(String)
      : [],
    hasIndependentApprover: data.hasIndependentApprover === true,
    allowSelfApproval: data.allowSelfApproval === true,
    loaded: snap.exists,
  };
}

function assertFlag(flags, key, fail) {
  if (flags[key] === true) return;
  fail('failed-precondition', 'FEATURE_FLAG_DISABLED', {flag: key});
}

module.exports = {
  DEFAULT_FLAGS,
  loadFinanceFeatureFlags,
  assertFlag,
};
