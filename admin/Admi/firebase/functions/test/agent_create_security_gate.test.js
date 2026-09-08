'use strict';

/**
 * Agent create security gate — static contract for Rules + createPanelUser lock.
 * Does not write to production.
 */

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {describe, it} = require('node:test');
const {
  applyCountryAdminCreateLock,
} = require('../panel_user_country_lock.js');

class HttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

const rulesPath = path.join(__dirname, '..', '..', 'firestore.rules');
const indexPath = path.join(__dirname, '..', 'index.js');

describe('agent_create_security_gate', () => {
  const rules = fs.readFileSync(rulesPath, 'utf8');
  const index = fs.readFileSync(indexPath, 'utf8');

  it('createPanelUser applies country lock before Auth create', () => {
    assert.ok(index.includes('applyCountryAdminCreateLock'));
    assert.ok(index.includes('panel_user_country_lock.js'));
    const start = index.indexOf('exports.createPanelUser');
    const fn = index.slice(start, start + 3500);
    assert.ok(fn.indexOf('applyCountryAdminCreateLock') < fn.indexOf('createUser'));
  });

  it('rules: panelCanProvisionUser uses countryRefMatchesClaim', () => {
    assert.ok(rules.includes('function panelCanProvisionUser'));
    const fn = rules.slice(rules.indexOf('function panelCanProvisionUser'));
    assert.ok(fn.includes('countryRefMatchesClaim(d.get(\'Rev_dolh\''));
  });

  it('rules: mkan create validates geo hierarchy', () => {
    assert.ok(rules.includes('function mkanCreateInClaimCountry'));
    assert.ok(rules.includes('country-admin-mkan-geo-hierarchy-2026-09-08'));
    const mkan = rules.slice(rules.indexOf('match /mkan/{document}'));
    assert.ok(mkan.includes('mkanCreateInClaimCountry()'));
  });

  it('PASS: KY agent create KY user', () => {
    const userData = {display_name: 'KY', Rev_dolh: 'countries/kyrgyzstan'};
    applyCountryAdminCreateLock(
      userData,
      {country_admin: true, country_id: 'countries/kyrgyzstan'},
      {HttpsError},
    );
    assert.equal(userData.Rev_dolh, 'countries/kyrgyzstan');
  });

  it('DENY: KY agent create India user', () => {
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {Rev_dolh: 'countries/india'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (e) => e.code === 'permission-denied',
    );
  });

  it('DENY: KY agent create Spain user', () => {
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {Rev_dolh: 'countries/spain'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (e) => e.code === 'permission-denied',
    );
  });

  it('DENY: KY agent create privileged Super Admin / Country Admin / Accountant', () => {
    for (const patch of [
      {isAdmin: true},
      {Isagent: true},
      {isAdminRule: 5},
      {isAdminRule: 1},
      {isPartner: true},
    ]) {
      assert.throws(
        () =>
          applyCountryAdminCreateLock(
            {...patch, Rev_dolh: 'countries/kyrgyzstan'},
            {country_admin: true, country_id: 'countries/kyrgyzstan'},
            {HttpsError},
          ),
        (e) => e.code === 'permission-denied',
      );
    }
  });

  it('PASS: KY agent create KY driver (ismndob)', () => {
    const userData = {ismndob: true, Rev_dolh: 'countries/kyrgyzstan'};
    applyCountryAdminCreateLock(
      userData,
      {country_admin: true, country_id: 'countries/kyrgyzstan'},
      {HttpsError},
    );
    assert.equal(userData.Rev_dolh, 'countries/kyrgyzstan');
    assert.equal(userData.ismndob, true);
  });

  it('DENY: KY agent create foreign driver', () => {
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {ismndob: true, Rev_dolh: 'countries/india'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (e) => e.code === 'permission-denied',
    );
  });
});
