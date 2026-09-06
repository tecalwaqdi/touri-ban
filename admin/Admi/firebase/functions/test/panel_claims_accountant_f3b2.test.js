'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const {
  deriveClaimsFromUserData,
  ACCOUNTANT_ADMIN_RULE,
} = require('../panel_claims.js');
const {canWriteSettlements, canReadSettlements} = require('../settlement_ledger.js');

describe('F3-B2 panel claims + settlement write gate', () => {
  it('isAdminRule=5 → finance claim only (accountant)', () => {
    const claims = deriveClaimsFromUserData({
      isAdminRule: ACCOUNTANT_ADMIN_RULE,
      email: 'accountant.demo@touri-taxi.com',
    });
    assert.equal(claims.finance, true);
    assert.equal(claims.super_admin, undefined);
    assert.equal(claims.country_admin, undefined);
    assert.equal(claims.agent, undefined);
  });

  it('country-scoped accountant keeps country_id', () => {
    const claims = deriveClaimsFromUserData({
      isAdminRule: 5,
      Rev_dloh_agent: {path: 'countries/saudi_arabia'},
    });
    assert.equal(claims.finance, true);
    assert.equal(claims.country_id, 'countries/saudi_arabia');
    assert.equal(claims.country_admin, undefined);
  });

  it('accountant finance claim cannot write settlements', () => {
    assert.equal(canWriteSettlements({finance: true}), false);
    assert.equal(canReadSettlements({finance: true}), true);
    assert.equal(canWriteSettlements({super_admin: true}), true);
  });

  it('does not trigger agent uniqueness fields', () => {
    const claims = deriveClaimsFromUserData({
      isAdminRule: 5,
      Isagent: false,
      isagent: false,
    });
    assert.equal(claims.agent, undefined);
  });
});
