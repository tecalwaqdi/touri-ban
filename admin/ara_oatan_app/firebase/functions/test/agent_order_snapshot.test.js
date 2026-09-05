'use strict';

/**
 * F3-C2 agent snapshot unit tests (Customer booking write path).
 */
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const agentSnap = require('../agent_order_snapshot.js');

class FakeFirestore {
  constructor() {
    this.users = [];
  }
  doc(fullPath) {
    return {path: fullPath};
  }
  collection(name) {
    if (name === 'user') return new FakeQuery(this.users);
    return {
      doc: (id) => ({path: `${name}/${id}`, id}),
    };
  }
}

class FakeQuery {
  constructor(rows) {
    this.rows = rows;
    this.filters = [];
  }
  where(field, op, val) {
    this.filters.push({field, op, val});
    return this;
  }
  async get() {
    const docs = this.rows
      .filter((row) => {
        for (const f of this.filters) {
          if (f.field === 'Isagent' && f.op === '==') {
            if (row.data.Isagent !== f.val) return false;
          }
          if (f.field === 'Rev_dloh_agent' && f.op === '==') {
            const want = f.val.path || f.val;
            const got = row.data.Rev_dloh_agent?.path || row.data.Rev_dloh_agent;
            if (want !== got) return false;
          }
        }
        return true;
      })
      .map((row) => ({id: row.id, data: () => row.data}));
    return {docs, size: docs.length};
  }
}

const NOW = '2026-09-06T00:00:00.000Z';

// 1–8: one valid active agent + FIN-9 5% of 7.50 → 0.38
{
  const db = new FakeFirestore();
  db.users.push({
    id: 'agent_sa_1',
    data: {
      Isagent: true,
      actev_user: true,
      Agent_total: 5,
      Rev_dloh_agent: {path: 'countries/saudi_arabia'},
    },
  });
  agentSnap
    .buildBookingAgentSnapshot({
      db,
      countryPath: 'countries/saudi_arabia',
      platformFeeHalalas: 750,
      currency: 'SAR',
      nowIso: NOW,
    })
    .then((patch) => {
      assert.strictEqual(patch.agent_id, 'agent_sa_1');
      assert.strictEqual(patch.agent_scope, 'country_exclusive');
      assert.strictEqual(patch.agent_rate, 5);
      assert.strictEqual(patch.agent_rate_type, 'percent_of_platform_fee');
      assert.strictEqual(patch.agent_amount_minor, 38);
      assert.strictEqual(patch.agent_amount, 0.38);
      assert.strictEqual(patch.agent_currency, 'SAR');
      assert.strictEqual(patch.agent_snapshot_at, NOW);
      assert.strictEqual(patch.agent_snapshot_version, 'FIN-9');
      assert.strictEqual(patch.agent_attribution_status, 'attributed');
      console.log('PASS attributed 5% of 7.50 → 0.38');
    })
    .then(async () => {
      // Pure formula helper
      assert.strictEqual(agentSnap.computeAgentAmountMinor(750, 5), 38);
      assert.strictEqual(agentSnap.computeAgentAmountMinor(750, 10), 75);
      assert.strictEqual(agentSnap.computeAgentAmountMinor(750, 0), null);
      assert.strictEqual(agentSnap.computeAgentAmountMinor(null, 5), null);

      // 9–10: agent amount does not alter money majors (semantic assert)
      const money = {
        total: 50,
        total_app: 7.5,
        total_vat: 0,
        total_mndob: 42.5,
        total_mndob2: 50,
      };
      const agent = await agentSnap.buildBookingAgentSnapshot({
        db,
        countryPath: 'countries/saudi_arabia',
        platformFeeHalalas: 750,
        currency: 'SAR',
        nowIso: NOW,
      });
      const merged = {...money, ...agent};
      assert.strictEqual(merged.total, 50);
      assert.strictEqual(merged.total_mndob, 42.5);
      assert.strictEqual(merged.total_app, 7.5);
      assert.ok(merged.agent_amount === 0.38);
      console.log('PASS customer total / driver net unchanged');

      // 12: no active agent
      const empty = new FakeFirestore();
      const none = await agentSnap.buildBookingAgentSnapshot({
        db: empty,
        countryPath: 'countries/empty',
        platformFeeHalalas: 750,
        nowIso: NOW,
      });
      assert.strictEqual(none.agent_attribution_status, 'none');
      assert.ok(!none.agent_id);
      assert.ok(!none.agent_amount_minor);
      assert.strictEqual(none.agent_snapshot_at, NOW);
      console.log('PASS no agent → none');

      // 13: multiple active agents
      const multi = new FakeFirestore();
      multi.users.push(
        {
          id: 'a1',
          data: {
            Isagent: true,
            actev_user: true,
            Agent_total: 5,
            Rev_dloh_agent: {path: 'countries/x'},
          },
        },
        {
          id: 'a2',
          data: {
            Isagent: true,
            actev_user: true,
            Agent_total: 8,
            Rev_dloh_agent: {path: 'countries/x'},
          },
        },
      );
      const amb = await agentSnap.buildBookingAgentSnapshot({
        db: multi,
        countryPath: 'countries/x',
        platformFeeHalalas: 750,
        nowIso: NOW,
      });
      assert.strictEqual(amb.agent_attribution_status, 'ambiguous');
      assert.deepStrictEqual(amb.agent_ambiguous_agent_ids, ['a1', 'a2']);
      assert.ok(!amb.agent_amount_minor);
      assert.ok(!amb.agent_id);
      console.log('PASS ambiguous never picks agent');

      // 14: invalid / missing rate never silent zero attributed
      const badRate = new FakeFirestore();
      badRate.users.push({
        id: 'agent_bad',
        data: {
          Isagent: true,
          actev_user: true,
          Rev_dloh_agent: {path: 'countries/saudi_arabia'},
        },
      });
      const missing = await agentSnap.buildBookingAgentSnapshot({
        db: badRate,
        countryPath: 'countries/saudi_arabia',
        platformFeeHalalas: 750,
        nowIso: NOW,
      });
      assert.strictEqual(missing.agent_attribution_status, 'rate_missing');
      assert.strictEqual(missing.agent_id, 'agent_bad');
      assert.ok(missing.agent_amount_minor == null);
      console.log('PASS rate_missing (no silent zero)');

      // Zero rate field present
      const zeroRate = new FakeFirestore();
      zeroRate.users.push({
        id: 'agent_zero',
        data: {
          Isagent: true,
          actev_user: true,
          Agent_total: 0,
          Rev_dloh_agent: {path: 'countries/saudi_arabia'},
        },
      });
      const z = await agentSnap.buildBookingAgentSnapshot({
        db: zeroRate,
        countryPath: 'countries/saudi_arabia',
        platformFeeHalalas: 750,
        nowIso: NOW,
      });
      assert.strictEqual(z.agent_attribution_status, 'rate_missing');
      console.log('PASS Agent_total=0 → rate_missing');

      // 15–16: snapshot is a plain object — mutating agent later does not rewrite it
      const frozen = await agentSnap.buildBookingAgentSnapshot({
        db,
        countryPath: 'countries/saudi_arabia',
        platformFeeHalalas: 750,
        nowIso: NOW,
      });
      db.users[0].data.Agent_total = 99;
      db.users[0].id = 'different_agent';
      assert.strictEqual(frozen.agent_rate, 5);
      assert.strictEqual(frozen.agent_id, 'agent_sa_1');
      console.log('PASS snapshot immutable vs later agent mutation');

      // platform fee missing
      const pf = await agentSnap.buildBookingAgentSnapshot({
        db,
        countryPath: 'countries/saudi_arabia',
        platformFeeHalalas: NaN,
        nowIso: NOW,
      });
      assert.strictEqual(pf.agent_attribution_status, 'platform_missing');
      console.log('PASS platform_missing');

      // 11: cash + online source both spread agentFields
      const src = fs.readFileSync(
        path.join(__dirname, '..', 'ngenius_payments.js'),
        'utf8',
      );
      assert.ok(src.includes('buildBookingAgentSnapshot'));
      assert.ok((src.match(/\.\.\.agentFields/g) || []).length >= 2);
      assert.ok(src.includes('createCashBooking'));
      assert.ok(src.includes('finalizeNGeniusBooking'));
      console.log('PASS cash + online both write agentFields');

      // Inactive agent filtered out
      const inactive = new FakeFirestore();
      inactive.users.push({
        id: 'dead',
        data: {
          Isagent: true,
          actev_user: false,
          Agent_total: 5,
          Rev_dloh_agent: {path: 'countries/saudi_arabia'},
        },
      });
      const noActive = await agentSnap.buildBookingAgentSnapshot({
        db: inactive,
        countryPath: 'countries/saudi_arabia',
        platformFeeHalalas: 750,
        nowIso: NOW,
      });
      assert.strictEqual(noActive.agent_attribution_status, 'none');
      console.log('PASS inactive agent → none');

      console.log('agent_order_snapshot (Customer F3-C2) tests OK');
    })
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
