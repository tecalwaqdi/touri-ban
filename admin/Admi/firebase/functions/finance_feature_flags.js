'use strict';

/**
 * Production feature flags for financial writes.
 * Defaults are OFF — first production money movement requires explicit enable.
 * Stored on financial_config/runtime (Admin SDK only).
 *
 * Cutover parallel-write control:
 *   LEGACY_ADMIN_WRITE_MODE =
 *     - unrestricted (legacy default when unset historically)
 *     - read_only (all CF financial writes blocked; fail closed)
 *     - super_admin_emergency_only (only Auth claim super_admin may pass flag gates)
 *
 * Missing / unknown mode during cutover restriction → fail closed to read_only
 * when LEGACY_ADMIN_CUTOVER_RESTRICTED=true on the doc.
 */

const DEFAULT_FLAGS = {
  FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
  FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
  FINANCIAL_CASH_REALIZATION_V2_ENABLED: false,
  WALLET_SETTLEMENT_ENABLED: false,
  AUTOMATIC_PAYOUT_ENABLED: false,
  /// Recognition engine: v2 (production) | v3 (snapshot-prefer when present).
  FINANCIAL_ENGINE_VERSION: 'v2',
  LEGACY_ADMIN_WRITE_MODE: 'unrestricted',
  LEGACY_ADMIN_CUTOVER_RESTRICTED: false,
};

const WRITE_MODES = new Set([
  'unrestricted',
  'read_only',
  'super_admin_emergency_only',
]);

function normalizeWriteMode(raw, cutoverRestricted) {
  const mode = typeof raw === 'string' ? raw.trim().toLowerCase() : '';
  if (WRITE_MODES.has(mode)) return mode;
  // Fail closed when cutover restriction armed but mode missing/unknown.
  if (cutoverRestricted === true) return 'read_only';
  return DEFAULT_FLAGS.LEGACY_ADMIN_WRITE_MODE;
}

async function loadFinanceFeatureFlags(db, tx) {
  const ref = db.doc('financial_config/runtime');
  const snap = tx ? await tx.get(ref) : await ref.get();
  const data = snap.exists ? snap.data() : {};
  const cutoverRestricted = data.LEGACY_ADMIN_CUTOVER_RESTRICTED === true;
  const writeMode = normalizeWriteMode(
    data.LEGACY_ADMIN_WRITE_MODE,
    cutoverRestricted,
  );
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
    LEGACY_ADMIN_WRITE_MODE: writeMode,
    LEGACY_ADMIN_CUTOVER_RESTRICTED: cutoverRestricted,
    independentApproverUids: Array.isArray(data.independentApproverUids)
      ? data.independentApproverUids.map(String)
      : [],
    hasIndependentApprover: data.hasIndependentApprover === true,
    allowSelfApproval: data.allowSelfApproval === true,
    loaded: snap.exists,
  };
}

function isSuperAdminAuth(auth) {
  if (!auth || typeof auth !== 'object') return false;
  const token = auth.token || auth;
  return token.super_admin === true || token.admin === true;
}

/**
 * Fail-closed write gate for Legacy Admin financial CF mutations.
 * No browser override — server-side only.
 *
 * @param {object} flags from loadFinanceFeatureFlags
 * @param {string} key flag name
 * @param {function} fail (code, message, details) => never
 * @param {{auth?: object}} [opts]
 */
function assertFlag(flags, key, fail, opts = {}) {
  const mode = flags.LEGACY_ADMIN_WRITE_MODE || 'unrestricted';

  if (mode === 'read_only') {
    fail('failed-precondition', 'LEGACY_ADMIN_READ_ONLY', {
      flag: key,
      mode,
      reason: 'Legacy Admin financial writes disabled for Admin Next cutover',
    });
  }

  if (mode === 'super_admin_emergency_only') {
    if (!isSuperAdminAuth(opts.auth)) {
      fail('failed-precondition', 'LEGACY_ADMIN_SUPER_ADMIN_EMERGENCY_ONLY', {
        flag: key,
        mode,
        reason: 'Only Super Admin emergency writes allowed during cutover',
      });
    }
    // Super Admin emergency: allow even if domain flag is false (explicit cutover escape hatch).
    return;
  }

  if (flags[key] === true) return;
  fail('failed-precondition', 'FEATURE_FLAG_DISABLED', {flag: key});
}

/**
 * Pure helper for unit tests — decides whether a write is blocked.
 */
function evaluateLegacyAdminWriteGate({mode, flagEnabled, isSuperAdmin}) {
  const normalized = normalizeWriteMode(mode, mode == null);
  if (normalized === 'read_only') {
    return {allowed: false, code: 'LEGACY_ADMIN_READ_ONLY'};
  }
  if (normalized === 'super_admin_emergency_only') {
    if (!isSuperAdmin) {
      return {allowed: false, code: 'LEGACY_ADMIN_SUPER_ADMIN_EMERGENCY_ONLY'};
    }
    return {allowed: true, code: null};
  }
  if (flagEnabled === true) return {allowed: true, code: null};
  return {allowed: false, code: 'FEATURE_FLAG_DISABLED'};
}

module.exports = {
  DEFAULT_FLAGS,
  loadFinanceFeatureFlags,
  assertFlag,
  evaluateLegacyAdminWriteGate,
  normalizeWriteMode,
  isSuperAdminAuth,
};
