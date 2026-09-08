'use strict';

/**
 * F03 + F07 Agent handoff security gate — static + unit matrix.
 * Emulator-style assertions without production writes.
 */

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {describe, it} = require('node:test');

const rulesPath = path.join(__dirname, '..', '..', 'firestore.rules');
const assignment = require('../agent_country_assignment.js');
const summary = require('../driver_financial_summary_v2.js');

describe('F03 Agent_total commission rate', () => {
  it('rules lock Agent_total / vat / app_commission via agentCommercialRatesUnchanged', () => {
    const rules = fs.readFileSync(rulesPath, 'utf8');
    assert.ok(rules.includes('function agentCommercialRatesUnchanged'));
    assert.ok(rules.includes("'Agent_total'"));
    assert.ok(rules.includes("'vat_percent'"));
    assert.ok(rules.includes("'app_commission_percent'"));
    assert.ok(rules.includes('notSettingAgentRates'));
    assert.ok(rules.includes('agentCommercialRatesUnchanged()'));
  });

  it('rules lock historical agent snapshot fields on orders', () => {
    const rules = fs.readFileSync(rulesPath, 'utf8');
    const fn = rules.slice(rules.indexOf('function financialOrderFieldsUnchanged'));
    assert.ok(fn.includes("'agent_rate'"));
    assert.ok(fn.includes("'agent_amount'"));
    assert.ok(fn.includes("'agent_snapshot_at'"));
  });

  it('validateCommissionRatePercent accepts 0..100', () => {
    assert.equal(assignment.validateCommissionRatePercent(0, 'Agent_total'), 0);
    assert.equal(assignment.validateCommissionRatePercent(5, 'Agent_total'), 5);
    assert.equal(assignment.validateCommissionRatePercent(100, 'Agent_total'), 100);
    assert.equal(assignment.validateCommissionRatePercent('7.5', 'Agent_total'), 7.5);
  });

  it('DENY Agent_total 150 / negative / NaN / Infinity', () => {
    for (const bad of [150, -1, NaN, Infinity, -Infinity, 'abc']) {
      assert.throws(
        () => assignment.validateCommissionRatePercent(bad, 'Agent_total'),
        (err) =>
          err &&
          (err.message === assignment.ERR_INVALID_RATE ||
            (err.details && err.details.code === assignment.ERR_INVALID_RATE)),
      );
    }
  });
});

describe('F07 country isolation', () => {
  it('settlement child reads use canReadSettlementChild (parent scope)', () => {
    const rules = fs.readFileSync(rulesPath, 'utf8');
    assert.ok(rules.includes('function canReadSettlementChild'));
    const lines = rules.slice(rules.indexOf('match /lines/{lineId}'));
    assert.ok(lines.includes('canReadSettlementChild(id)'));
    assert.ok(!/^[\s\S]*allow read: if signedIn\(\) && \(\s*isSuperAdmin\(\) \|\| isFinance\(\) \|\| isCountryAdmin\(\)\s*\);/m.test(
      rules.slice(
        rules.indexOf('match /lines/{lineId}'),
        rules.indexOf('match /events/{eventId}') + 200,
      ).replace(/canReadSettlementChild\(id\)/g, 'SCOPED'),
    ));
    // Explicit: bare isCountryAdmin() alone must not authorize child reads.
    const childBlock = rules.slice(
      rules.indexOf('match /lines/{lineId}'),
      rules.indexOf('match /financial_settlement_claims'),
    );
    assert.ok(childBlock.includes('canReadSettlementChild(id)'));
    assert.equal(
      (childBlock.match(/isCountryAdmin\(\)/g) || []).length,
      0,
      'child match must not call isCountryAdmin() directly',
    );
  });

  it('type_car is GLOBAL catalog — Super Admin write only', () => {
    const rules = fs.readFileSync(rulesPath, 'utf8');
    const start = rules.indexOf('// Public GLOBAL vehicle catalog');
    assert.ok(start >= 0, 'GLOBAL policy comment missing');
    const block = rules.slice(start, start + 450);
    assert.ok(block.includes('GLOBAL CAR CATALOG'));
    assert.ok(block.includes('allow create, update, delete: if isSuperAdmin()'));
    assert.ok(!block.includes('isCountryAdmin()'));
  });

  it('India country_admin DENY Spain driver financial summary', () => {
    const auth = {
      uid: 'agent-in',
      token: {
        country_admin: true,
        country_id: 'countries/india',
      },
    };
    assert.throws(
      () => summary.assertDriverSummaryCountryScope(auth, 'countries/spain'),
      (err) => err && err.code === 'permission-denied',
    );
  });

  it('Spain country_admin DENY India driver financial summary', () => {
    const auth = {
      uid: 'agent-es',
      token: {country_admin: true, country_id: 'countries/spain'},
    };
    assert.throws(
      () => summary.assertDriverSummaryCountryScope(auth, 'countries/india'),
      (err) => err && err.code === 'permission-denied',
    );
  });

  it('India country_admin ALLOW India driver financial summary', () => {
    const auth = {
      uid: 'agent-in',
      token: {country_admin: true, country_id: 'countries/india'},
    };
    assert.doesNotThrow(() =>
      summary.assertDriverSummaryCountryScope(auth, 'countries/india'),
    );
  });

  it('Super Admin ALLOW any country driver summary', () => {
    const auth = {uid: 'sa', token: {super_admin: true}};
    assert.doesNotThrow(() =>
      summary.assertDriverSummaryCountryScope(auth, 'countries/spain'),
    );
  });

  it('global finance Accountant ALLOW any country', () => {
    const auth = {uid: 'acc', token: {finance: true}};
    assert.doesNotThrow(() =>
      summary.assertDriverSummaryCountryScope(auth, 'countries/spain'),
    );
  });
});
