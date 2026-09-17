'use strict';

/**
 * Unit tests — Legacy Admin cutover write gate (fail closed).
 * No Production network; pure evaluateLegacyAdminWriteGate.
 */

const assert = require('assert');
const {
  evaluateLegacyAdminWriteGate,
  normalizeWriteMode,
  assertFlag,
} = require('../finance_feature_flags');

function fail(code, message, details) {
  const err = new Error(message);
  err.code = code;
  err.details = details;
  throw err;
}

{
  assert.strictEqual(normalizeWriteMode('read_only', false), 'read_only');
  assert.strictEqual(
    normalizeWriteMode('super_admin_emergency_only', false),
    'super_admin_emergency_only',
  );
  assert.strictEqual(normalizeWriteMode('nope', true), 'read_only');
  assert.strictEqual(normalizeWriteMode('', false), 'unrestricted');
}

{
  const blocked = evaluateLegacyAdminWriteGate({
    mode: 'read_only',
    flagEnabled: true,
    isSuperAdmin: true,
  });
  assert.strictEqual(blocked.allowed, false);
  assert.strictEqual(blocked.code, 'LEGACY_ADMIN_READ_ONLY');
}

{
  const denied = evaluateLegacyAdminWriteGate({
    mode: 'super_admin_emergency_only',
    flagEnabled: false,
    isSuperAdmin: false,
  });
  assert.strictEqual(denied.allowed, false);
  assert.strictEqual(denied.code, 'LEGACY_ADMIN_SUPER_ADMIN_EMERGENCY_ONLY');
}

{
  const allowed = evaluateLegacyAdminWriteGate({
    mode: 'super_admin_emergency_only',
    flagEnabled: false,
    isSuperAdmin: true,
  });
  assert.strictEqual(allowed.allowed, true);
}

{
  const flagOff = evaluateLegacyAdminWriteGate({
    mode: 'unrestricted',
    flagEnabled: false,
    isSuperAdmin: true,
  });
  assert.strictEqual(flagOff.allowed, false);
  assert.strictEqual(flagOff.code, 'FEATURE_FLAG_DISABLED');
}

{
  let threw = null;
  try {
    assertFlag(
      {
        LEGACY_ADMIN_WRITE_MODE: 'read_only',
        FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
      },
      'FINANCIAL_SETTLEMENT_WRITES_ENABLED',
      fail,
      {auth: {token: {super_admin: true}}},
    );
  } catch (e) {
    threw = e;
  }
  assert.ok(threw);
  assert.strictEqual(threw.message, 'LEGACY_ADMIN_READ_ONLY');
}

{
  // Super Admin emergency bypasses domain flag
  assertFlag(
    {
      LEGACY_ADMIN_WRITE_MODE: 'super_admin_emergency_only',
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
    },
    'FINANCIAL_SETTLEMENT_WRITES_ENABLED',
    fail,
    {auth: {token: {super_admin: true}}},
  );
}

{
  let threw = null;
  try {
    assertFlag(
      {
        LEGACY_ADMIN_WRITE_MODE: 'super_admin_emergency_only',
        FINANCIAL_SETTLEMENT_WRITES_ENABLED: true,
      },
      'FINANCIAL_SETTLEMENT_WRITES_ENABLED',
      fail,
      {auth: {token: {finance: true}}},
    );
  } catch (e) {
    threw = e;
  }
  assert.ok(threw);
  assert.strictEqual(threw.message, 'LEGACY_ADMIN_SUPER_ADMIN_EMERGENCY_ONLY');
}

console.log('legacy_admin_write_gate.test.js: PASS');
