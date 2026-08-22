'use strict';

/**
 * FINANCE_APPROVAL_POLICY — uses existing SuperAdmin / Finance roles only.
 * Default production: allowSelfApproval = false.
 */

const DEFAULT_POLICY = {
  allowSelfApproval: false,
  name: 'FINANCE_APPROVAL_POLICY',
  version: '7a',
};

async function loadFinancePolicy(db, tx) {
  const ref = db.doc('financial_config/runtime');
  const snap = tx ? await tx.get(ref) : await ref.get();
  const data = snap.exists ? snap.data() : {};
  return {
    ...DEFAULT_POLICY,
    allowSelfApproval: data.allowSelfApproval === true,
    loaded: snap.exists,
  };
}

function assertChecker({policy, makerUid, checkerUid, action}) {
  if (!makerUid || !checkerUid) return {selfApproved: false};
  if (makerUid !== checkerUid) return {selfApproved: false};
  if (policy.allowSelfApproval === true) {
    return {selfApproved: true};
  }
  const err = new Error('SELF_APPROVAL_FORBIDDEN');
  err.code = 'permission-denied';
  err.details = {action, makerUid};
  throw err;
}

/**
 * Existing roles only: SuperAdmin and Finance may write.
 * SuperAdmin is the only dedicated checker when no second Finance user exists.
 * Production default: allowSelfApproval=false (set financial_config/runtime).
 */
function describePolicy(policy) {
  return {
    name: 'FINANCE_APPROVAL_POLICY',
    version: policy.version || '7a',
    allowSelfApproval: policy.allowSelfApproval === true,
    makerRoles: ['super_admin', 'finance'],
    checkerRoles: ['super_admin', 'finance'],
    note:
      'No separate Accountant role. SuperAdmin is the temporary sole checker ' +
      'unless a second Finance user exists. Self-approval is off in production ' +
      'unless financial_config/runtime.allowSelfApproval=true; when used it is audited.',
  };
}

module.exports = {
  DEFAULT_POLICY,
  loadFinancePolicy,
  assertChecker,
  describePolicy,
};
