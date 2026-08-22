'use strict';

/**
 * Phase 8A — static security assertions for Firestore rules + wallet isolation.
 * Does not call Production.
 */

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {describe, it} = require('node:test');

const rulesPath = path.join(__dirname, '..', '..', 'firestore.rules');
const indexPath = path.join(__dirname, '..', 'index.js');
const ledgerPath = path.join(__dirname, '..', 'settlement_ledger.js');
const paymentsPath = path.join(__dirname, '..', 'settlement_payments.js');

describe('phase_8a_rules_and_isolation', () => {
  it('denies client writes on all financial_* collections', () => {
    const rules = fs.readFileSync(rulesPath, 'utf8');
    const collections = [
      'financial_settlements',
      'financial_settlement_claims',
      'financial_payment_allocations',
      'financial_payment_allocation_claims',
      'financial_settlement_payments',
      'financial_periods',
      'financial_adjustments',
      'financial_config',
      'financial_audit_events',
      'financial_aggregation_metrics',
      'financial_wallet_adjust_idempotency',
    ];
    for (const c of collections) {
      assert.ok(rules.includes(`match /${c}/`), `missing match for ${c}`);
    }
    const financialSection = rules.slice(rules.indexOf('match /financial_settlements'));
    assert.ok(
      /allow create,\s*update,\s*delete:\s*if false/.test(financialSection),
    );
    assert.ok(/allow read,\s*write:\s*if false/.test(financialSection));
    assert.ok(
      financialSection.includes('financial_wallet_adjust_idempotency'),
    );
  });

  it('locks privileged role fields on user docs', () => {
    const rules = fs.readFileSync(rulesPath, 'utf8');
    assert.ok(rules.includes('privilegedUserFieldsUnchanged'));
    assert.ok(rules.includes("d.get('finance'"));
    assert.ok(rules.includes("d.get('super_admin'"));
  });

  it('wallet adjust is LEGACY, super_admin only, flag gated', () => {
    const index = fs.readFileSync(indexPath, 'utf8');
    assert.ok(index.includes('LEGACY_WALLET_TOOL'));
    const start = index.indexOf('exports.adminAdjustDriverWallet');
    assert.ok(start > 0);
    const fn = index.slice(start - 400, start + 2500);
    assert.ok(fn.includes('LEGACY_WALLET_TOOL'));
    assert.ok(fn.includes('WALLET_SETTLEMENT_ENABLED'));
    assert.ok(fn.includes('!token.super_admin'));
    assert.ok(
      !fs.readFileSync(ledgerPath, 'utf8').includes('adminAdjustDriverWallet'),
    );
    assert.ok(
      !fs.readFileSync(paymentsPath, 'utf8').includes('adminAdjustDriverWallet'),
    );
  });
});
