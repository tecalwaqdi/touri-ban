'use strict';

/**
 * Production feature flags for financial writes.
 * Defaults are OFF — first production money movement requires explicit enable.
 * Stored on financial_config/runtime (Admin SDK only).
 */

const DEFAULT_FLAGS = {
  FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
  FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
  WALLET_SETTLEMENT_ENABLED: false,
  AUTOMATIC_PAYOUT_ENABLED: false,
};

async function loadFinanceFeatureFlags(db, tx) {
  const ref = db.doc('financial_config/runtime');
  const snap = tx ? await tx.get(ref) : await ref.get();
  const data = snap.exists ? snap.data() : {};
  return {
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: data.FINANCIAL_SETTLEMENT_WRITES_ENABLED === true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: data.FINANCIAL_PAYMENT_CONFIRM_ENABLED === true,
    WALLET_SETTLEMENT_ENABLED: data.WALLET_SETTLEMENT_ENABLED === true,
    AUTOMATIC_PAYOUT_ENABLED: data.AUTOMATIC_PAYOUT_ENABLED === true,
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
