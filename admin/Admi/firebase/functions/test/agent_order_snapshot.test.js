'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const agentSnap = require('../agent_order_snapshot.js');

class FakeFirestore {
  constructor() {
    this.users = [];
    this.orders = {};
  }
  doc(fullPath) {
    return {path: fullPath};
  }
  collection(name) {
    if (name === 'user') return new FakeQuery(this.users);
    if (name === 'order') {
      return {
        doc: (id) => ({
          set: async (data, opts) => {
            this.orders[id] = {...(this.orders[id] || {}), ...data};
          },
          get: async () => ({exists: !!this.orders[id], data: () => this.orders[id]}),
        }),
      };
    }
    return {
      doc: (id) => ({
        path: `${name}/${id}`,
        id: id.split('/').pop(),
      }),
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
      .map((row) => ({
        id: row.id,
        data: () => row.data,
      }));
    return {docs, size: docs.length};
  }
}

describe('agent_order_snapshot', () => {
  it('attributes one active country agent using platform fee', async () => {
    const db = new FakeFirestore();
    db.users.push({
      id: 'agent1',
      data: {
        Isagent: true,
        actev_user: true,
        Agent_total: 10,
        Rev_dloh_agent: {path: 'countries/saudi_arabia'},
      },
    });
    const patch = await agentSnap.buildAgentSnapshotPatch(db, 'o1', {
      Rev_dolh: {path: 'countries/saudi_arabia'},
      total: 50,
      total_app: 7.5,
      total_vat: 0,
      total_mndob: 42.5,
      total_mndob2: 50,
      status_code: 'completed',
      payment_status: 'pending_cash',
      payment_method: 'cash',
    });
    assert.equal(patch.agent_id, 'agent1');
    assert.equal(patch.agent_rate, 10);
    assert.equal(patch.agent_rate_type, 'percent_of_platform_fee');
    assert.equal(patch.agent_amount_minor, 75);
    assert.equal(patch.agent_currency, 'SAR');
    assert.equal(patch.agent_attribution_status, 'attributed');
  });

  it('marks ambiguous when multiple active agents', async () => {
    const db = new FakeFirestore();
    db.users.push(
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
    const patch = await agentSnap.buildAgentSnapshotPatch(db, 'o2', {
      Rev_dolh: {path: 'countries/x'},
      total_app: 10,
      total: 100,
    });
    assert.equal(patch.agent_attribution_status, 'ambiguous');
    assert.ok(!patch.agent_amount_minor);
  });

  it('does not overwrite existing snapshot', async () => {
    const db = new FakeFirestore();
    const patch = await agentSnap.buildAgentSnapshotPatch(db, 'o3', {
      agent_id: 'existing',
      agent_snapshot_at: '2026-01-01T00:00:00.000Z',
      Rev_dolh: {path: 'countries/saudi_arabia'},
      total_app: 7.5,
    });
    assert.equal(patch, null);
  });

  it('zero agents → none', async () => {
    const db = new FakeFirestore();
    const patch = await agentSnap.buildAgentSnapshotPatch(db, 'o4', {
      Rev_dolh: {path: 'countries/empty'},
      total_app: 5,
    });
    assert.equal(patch.agent_attribution_status, 'none');
  });
});

console.log('agent_order_snapshot tests OK');
