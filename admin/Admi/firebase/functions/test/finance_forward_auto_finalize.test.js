'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const fwd = require('../finance_forward_auto_finalize');

describe('finance_forward_auto_finalize eligibility', () => {
  it('requires completed + cash_collected', () => {
    assert.equal(
      fwd.isFinanceEligible({
        status_code: 'completed',
        payment_status: 'cash_collected',
      }),
      true,
    );
  });

  it('blocks pending_cash even when completed', () => {
    assert.equal(
      fwd.isFinanceEligible({
        status_code: 'completed',
        payment_status: 'pending_cash',
      }),
      false,
    );
  });

  it('blocks cash_collected when not completed', () => {
    assert.equal(
      fwd.isFinanceEligible({
        status_code: 'in_progress',
        payment_status: 'cash_collected',
      }),
      false,
    );
  });

  it('becameFinanceEligible only on transition', () => {
    const before = {status_code: 'completed', payment_status: 'pending_cash'};
    const after = {status_code: 'completed', payment_status: 'cash_collected'};
    assert.equal(fwd.becameFinanceEligible(before, after), true);
    assert.equal(fwd.becameFinanceEligible(after, after), false);
  });

  it('invoke swallows errors and writes audit', async () => {
    const audits = [];
    const db = {
      collection: () => ({
        doc: () => {
          const id = 'audit_1';
          return {
            id,
            set: async (data) => {
              audits.push(data);
            },
          };
        },
      }),
    };
    const admin = {
      firestore: {FieldValue: {serverTimestamp: () => 'ts'}},
    };
    const result = await fwd.invokeAdminNextAutoFinalize({
      db,
      admin,
      orderId: 'demo_fin_forward_wire_1',
      source: 'test',
      swallowErrors: true,
      fetchIdToken: async () => {
        throw new Error('no_metadata');
      },
      httpFetch: async () => {
        throw new Error('should_not_fetch');
      },
    });
    assert.equal(result.swallowed, true);
    assert.equal(audits.length, 1);
    assert.equal(audits[0].eventType, 'FINANCE_FORWARD_AUTO_FINALIZE_FAILED');
  });
});
