'use strict';

/**
 * Phase 8B — Emulator/static security: direct writes denied, role escalation locked,
 * wallet isolation. No production writes.
 */

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {describe, it} = require('node:test');

const {FakeFirestore} = require('./fake_firestore');
const ledger = require('../settlement_ledger');
const rulesPath = path.join(__dirname, '..', '..', 'firestore.rules');
const indexPath = path.join(__dirname, '..', 'index.js');
const ledgerPath = path.join(__dirname, '..', 'settlement_ledger.js');
const paymentsPath = path.join(__dirname, '..', 'settlement_payments.js');

describe('phase_8b_security_gates', () => {
  it('rules deny client writes on all financial collections', () => {
    const rules = fs.readFileSync(rulesPath, 'utf8');
    const collections = [
      'financial_settlements',
      'financial_settlement_claims',
      'financial_settlement_payments',
      'financial_payment_allocations',
      'financial_periods',
      'financial_adjustments',
      'financial_config',
      'financial_audit_events',
      'financial_aggregation_metrics',
      'financial_wallet_adjust_idempotency',
    ];
    for (const c of collections) {
      assert.ok(rules.includes(`match /${c}/`), `missing ${c}`);
    }
    const section = rules.slice(rules.indexOf('match /financial_settlements'));
    assert.ok(/allow create,\s*update,\s*delete:\s*if false/.test(section));
    assert.ok(rules.includes('privilegedUserFieldsUnchanged'));
    assert.ok(rules.includes("d.get('finance'"));
    assert.ok(rules.includes("d.get('super_admin'"));
  });

  it('wallet tool is SuperAdmin-only, flag-gated, not used by settlement V2', () => {
    const index = fs.readFileSync(indexPath, 'utf8');
    assert.ok(index.includes('LEGACY_WALLET_TOOL'));
    const start = index.indexOf('exports.adminAdjustDriverWallet');
    const fn = index.slice(start - 200, start + 2000);
    assert.ok(fn.includes('!token.super_admin'));
    assert.ok(fn.includes('WALLET_SETTLEMENT_ENABLED'));
    assert.ok(!fs.readFileSync(ledgerPath, 'utf8').includes('adminAdjustDriverWallet'));
    assert.ok(!fs.readFileSync(paymentsPath, 'utf8').includes('adminAdjustDriverWallet'));
  });

  it('FakeFirestore: finance write flags default OFF reject settlement create', async () => {
    const db = new FakeFirestore();
    await db.doc('financial_config/runtime').set({
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: false,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED: false,
      WALLET_SETTLEMENT_ENABLED: false,
      AUTOMATIC_PAYOUT_ENABLED: false,
      allowSelfApproval: false,
    });
    let msg = '';
    try {
      await ledger.createSettlementDraft({
        db,
        auth: {uid: 'fin1', token: {finance: true}},
        data: {
          driverId: 'd1',
          currency: 'SAR',
          countryId: 'countries/sa',
          periodStart: new Date('2026-01-01').toISOString(),
          periodEnd: new Date('2026-01-31').toISOString(),
        },
        now: new Date(),
      });
    } catch (e) {
      msg = String(e.message || e);
    }
    assert.ok(msg.includes('FEATURE_FLAG_DISABLED'), msg);
  });
});
