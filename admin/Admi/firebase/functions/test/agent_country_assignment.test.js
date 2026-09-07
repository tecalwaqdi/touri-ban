'use strict';

/**
 * F3-C3 one-active-agent-per-country unit + concurrency tests.
 */
const assert = require('assert');
const {describe, it} = require('node:test');
const active = require('../agent_active.js');
const assignment = require('../agent_country_assignment.js');

class FakeDocSnap {
  constructor(exists, data, ref) {
    this.exists = exists;
    this._data = data;
    this.ref = ref;
  }
  data() {
    return this._data;
  }
}

class FakeDb {
  constructor() {
    this.users = new Map();
    this.locks = new Map();
    this.audits = [];
    this._txQueue = Promise.resolve();
  }
  doc(path) {
    return {path, id: path.split('/').pop()};
  }
  collection(name) {
    const self = this;
    if (name === 'user') {
      return {
        doc(id) {
          return {
            id,
            path: `user/${id}`,
            async get() {
              const d = self.users.get(id);
              return new FakeDocSnap(!!d, d ? {...d} : null, {id, path: `user/${id}`});
            },
            set(data, opts) {
              const prev = self.users.get(id) || {};
              self.users.set(id, opts && opts.merge ? {...prev, ...data} : {...data});
              return Promise.resolve();
            },
          };
        },
        where() {
          const filters = [];
          const q = {
            where(f, op, v) {
              filters.push({f, op, v});
              return q;
            },
            async get() {
              const docs = [];
              for (const [id, data] of self.users.entries()) {
                let ok = true;
                for (const filt of filters) {
                  if (filt.f === 'Isagent' && data.Isagent !== filt.v) ok = false;
                  if (filt.f === 'Rev_dloh_agent') {
                    const want = filt.v.path || filt.v;
                    const got = data.Rev_dloh_agent && data.Rev_dloh_agent.path
                      ? data.Rev_dloh_agent.path
                      : data.Rev_dloh_agent;
                    if (want !== got) ok = false;
                  }
                }
                if (ok) docs.push({id, data: () => ({...data})});
              }
              return {docs, size: docs.length};
            },
          };
          return q.where(arguments[0], arguments[1], arguments[2]);
        },
      };
    }
    if (name === assignment.ASSIGNMENT_COLLECTION) {
      return {
        doc(id) {
          return {
            id,
            path: `${assignment.ASSIGNMENT_COLLECTION}/${id}`,
            async get() {
              const d = self.locks.get(id);
              return new FakeDocSnap(!!d, d ? {...d} : null, {
                id,
                path: `${assignment.ASSIGNMENT_COLLECTION}/${id}`,
              });
            },
            set(data, opts) {
              const prev = self.locks.get(id) || {};
              const next = opts && opts.merge ? {...prev, ...data} : {...data};
              // strip FieldValue sentinels for tests
              for (const k of Object.keys(next)) {
                if (next[k] && next[k]._methodName) next[k] = new Date().toISOString();
              }
              self.locks.set(id, next);
              return Promise.resolve();
            },
          };
        },
      };
    }
    if (name === 'admin_audit_log') {
      return {
        async add(row) {
          self.audits.push(row);
          return {id: `a${self.audits.length}`};
        },
      };
    }
    throw new Error('unknown collection ' + name);
  }
  runTransaction(fn) {
    // Serialize transactions to model contention + atomic rollback.
    const run = this._txQueue.then(async () => {
      const usersSnap = new Map(
        [...this.users.entries()].map(([k, v]) => [k, {...v}]),
      );
      const locksSnap = new Map(
        [...this.locks.entries()].map(([k, v]) => [k, {...v}]),
      );
      const stagingUsers = new Map(usersSnap);
      const stagingLocks = new Map(locksSnap);
      const tx = {
        get: (ref) => {
          if (ref.path.startsWith('user/')) {
            const d = stagingUsers.get(ref.id);
            return Promise.resolve(
              new FakeDocSnap(!!d, d ? {...d} : null, ref),
            );
          }
          if (ref.path.startsWith(assignment.ASSIGNMENT_COLLECTION)) {
            const d = stagingLocks.get(ref.id);
            return Promise.resolve(
              new FakeDocSnap(!!d, d ? {...d} : null, ref),
            );
          }
          return Promise.resolve(new FakeDocSnap(false, null, ref));
        },
        set: (ref, data, opts) => {
          if (ref.path.startsWith('user/')) {
            const prev = stagingUsers.get(ref.id) || {};
            const next = opts && opts.merge ? {...prev, ...data} : {...data};
            stagingUsers.set(ref.id, next);
          } else if (ref.path.startsWith(assignment.ASSIGNMENT_COLLECTION)) {
            const prev = stagingLocks.get(ref.id) || {};
            const next = opts && opts.merge ? {...prev, ...data} : {...data};
            for (const k of Object.keys(next)) {
              if (next[k] && next[k]._methodName) {
                next[k] = new Date().toISOString();
              }
            }
            stagingLocks.set(ref.id, next);
          }
        },
      };
      try {
        const result = await fn(tx);
        this.users = stagingUsers;
        this.locks = stagingLocks;
        return result;
      } catch (e) {
        // rollback — leave this.users / this.locks unchanged
        throw e;
      }
    });
    this._txQueue = run.catch(() => {});
    return run;
  }
}

describe('agent_active semantics', () => {
  it('matches C2 active window', () => {
    assert.equal(
      active.isAgentActiveAt({Isagent: true, actev_user: true}),
      true,
    );
    assert.equal(
      active.isAgentActiveAt({Isagent: true, actev_user: false}),
      false,
    );
    assert.equal(
      active.isAgentActiveAt({
        Isagent: true,
        actev_user: true,
        agent_date_end: '2000-01-01T00:00:00.000Z',
      }),
      false,
    );
    assert.equal(active.countryDocId('countries/saudi_arabia'), 'saudi_arabia');
  });

  it('detects date window overlap', () => {
    const a = active.agentEffectiveWindow({
      agent_date_reg: '2026-01-01',
      agent_date_end: '2026-10-31',
    });
    const b = active.agentEffectiveWindow({
      agent_date_reg: '2026-10-15',
      agent_date_end: '2026-12-31',
    });
    assert.equal(active.windowsOverlap(a, b), true);
  });

  it('adjacent calendar days do not overlap; same instant does', () => {
    const a = active.agentEffectiveWindow({
      agent_date_end: '2026-09-10T00:00:00.000Z',
    });
    const b = active.agentEffectiveWindow({
      agent_date_reg: '2026-09-11T00:00:00.000Z',
    });
    assert.equal(active.windowsOverlap(a, b), false);

    const sameA = active.agentEffectiveWindow({
      agent_date_end: '2026-09-10T23:59:00.000Z',
    });
    const sameB = active.agentEffectiveWindow({
      agent_date_reg: '2026-09-10T23:59:00.000Z',
    });
    assert.equal(active.windowsOverlap(sameA, sameB), true);
  });
});

describe('agent_country_assignment', () => {
  it('0 → activate first agent PASS', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'a1',
      actorUid: 'super',
      agentPatch: {
        Isagent: true,
        actev_user: true,
        Rev_dloh_agent: {path: 'countries/x'},
      },
    });
    assert.equal(r.activeAgentId, 'a1');
    assert.equal(db.locks.get('x').active_agent_id, 'a1');
    assert.equal(db.users.get('a1').actev_user, true);
  });

  it('1 active → activate second REJECT', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.users.set('a2', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'a1'});
    let rejected = false;
    try {
      await assignment.claimCountryAgent({
        firestore: db,
        countryPath: 'countries/x',
        agentId: 'a2',
        actorUid: 'super',
        agentPatch: {actev_user: true, Isagent: true},
      });
    } catch (e) {
      rejected = true;
      assert.equal(e.message, assignment.ERR_CONFLICT);
      assert.equal(e.details.currentActiveAgentId, 'a1');
    }
    assert.equal(rejected, true);
    assert.equal(db.locks.get('x').active_agent_id, 'a1');
  });

  it('concurrent claims → exactly one success', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/y'},
    });
    db.users.set('a2', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/y'},
    });
    const results = await Promise.allSettled([
      assignment.claimCountryAgent({
        firestore: db,
        countryPath: 'countries/y',
        agentId: 'a1',
        actorUid: 's',
        agentPatch: {actev_user: true, Isagent: true},
      }),
      assignment.claimCountryAgent({
        firestore: db,
        countryPath: 'countries/y',
        agentId: 'a2',
        actorUid: 's',
        agentPatch: {actev_user: true, Isagent: true},
      }),
    ]);
    const ok = results.filter((r) => r.status === 'fulfilled');
    const fail = results.filter((r) => r.status === 'rejected');
    assert.equal(ok.length, 1);
    assert.equal(fail.length, 1);
    assert.equal(fail[0].reason.message, assignment.ERR_CONFLICT);
  });

  it('retry same activation idempotent', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/z'},
    });
    db.locks.set('z', {country_path: 'countries/z', active_agent_id: 'a1'});
    const r1 = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/z',
      agentId: 'a1',
      actorUid: 's',
    });
    assert.equal(r1.idempotent, true);
  });

  it('inactive may exist beside active', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.users.set('a2', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    const others = await assignment.__test.findOtherActiveAgents(
      db,
      'countries/x',
      'a1',
      new Date(),
    );
    assert.equal(others.length, 0);
  });

  it('deactivation frees country; reactivation blocked if another active', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.users.set('a2', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'a1'});
    await assignment.releaseCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'a1',
      actorUid: 's',
      deactivateAgent: true,
    });
    assert.equal(db.locks.get('x').active_agent_id, null);
    assert.equal(db.users.get('a1').actev_user, false);

    await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'a2',
      actorUid: 's',
      agentPatch: {actev_user: true, Isagent: true},
    });
    assert.equal(db.locks.get('x').active_agent_id, 'a2');

    let blocked = false;
    try {
      await assignment.claimCountryAgent({
        firestore: db,
        countryPath: 'countries/x',
        agentId: 'a1',
        actorUid: 's',
        agentPatch: {actev_user: true},
      });
    } catch (e) {
      blocked = e.message === assignment.ERR_CONFLICT;
    }
    assert.equal(blocked, true);
  });

  it('explicit reassignment deactivates old atomically', async () => {
    const db = new FakeDb();
    db.users.set('old', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'old'});
    const r = await assignment.reassignCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      newAgentId: 'neu',
      actorUid: 's',
    });
    assert.equal(r.previousActiveAgentId, 'old');
    assert.equal(r.newActiveAgentId, 'neu');
    assert.equal(db.users.get('old').actev_user, false);
    assert.equal(db.users.get('neu').actev_user, true);
    assert.equal(db.locks.get('x').active_agent_id, 'neu');
  });

  it('active country move clears old lock and claims new in one txn', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/from'},
    });
    db.locks.set('from', {
      country_path: 'countries/from',
      active_agent_id: 'a1',
    });
    await assignment.moveActiveAgentCountry({
      firestore: db,
      agentId: 'a1',
      fromCountryPath: 'countries/from',
      toCountryPath: 'countries/to',
      actorUid: 's',
    });
    assert.equal(db.locks.get('from').active_agent_id, null);
    assert.equal(db.locks.get('to').active_agent_id, 'a1');
    assert.equal(db.users.get('a1').Rev_dloh_agent.path, 'countries/to');
    assert.equal(db.users.get('a1').actev_user, true);
  });

  it('active country move rejects occupied destination', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/from'},
    });
    db.users.set('a2', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/to'},
    });
    db.locks.set('from', {
      country_path: 'countries/from',
      active_agent_id: 'a1',
    });
    db.locks.set('to', {
      country_path: 'countries/to',
      active_agent_id: 'a2',
    });
    let blocked = false;
    try {
      await assignment.moveActiveAgentCountry({
        firestore: db,
        agentId: 'a1',
        fromCountryPath: 'countries/from',
        toCountryPath: 'countries/to',
        actorUid: 's',
      });
    } catch (e) {
      blocked = e.message === assignment.ERR_CONFLICT;
    }
    assert.equal(blocked, true);
    assert.equal(db.locks.get('from').active_agent_id, 'a1');
    assert.equal(db.locks.get('to').active_agent_id, 'a2');
  });

  it('claim may create missing user doc when agentPatch provided', async () => {
    const db = new FakeDb();
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/new',
      agentId: 'brand_new',
      actorUid: 's',
      agentPatch: {
        Isagent: true,
        actev_user: true,
        email: 'a@example.com',
        Rev_dloh_agent: {path: 'countries/new'},
      },
    });
    assert.equal(r.activeAgentId, 'brand_new');
    assert.equal(db.locks.get('new').active_agent_id, 'brand_new');
    assert.equal(db.users.get('brand_new').Isagent, true);
  });

  it('claim without patch rejects missing user doc', async () => {
    const db = new FakeDb();
    let rejected = false;
    try {
      await assignment.claimCountryAgent({
        firestore: db,
        countryPath: 'countries/new',
        agentId: 'ghost',
        actorUid: 's',
      });
    } catch (e) {
      rejected = e.message === 'Agent not found.';
    }
    assert.equal(rejected, true);
  });

  it('no cross-country false conflict', async () => {
    const db = new FakeDb();
    db.users.set('sa', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/saudi_arabia'},
    });
    db.locks.set('saudi_arabia', {
      country_path: 'countries/saudi_arabia',
      active_agent_id: 'sa',
    });
    db.users.set('ng', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/nigeria'},
    });
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/nigeria',
      agentId: 'ng',
      actorUid: 's',
      agentPatch: {actev_user: true, Isagent: true},
    });
    assert.equal(r.activeAgentId, 'ng');
  });

  it('stale lock: inactive holder is reclaimable', async () => {
    const db = new FakeDb();
    db.users.set('old', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'old'});
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'neu',
      actorUid: 's',
      agentPatch: {actev_user: true, Isagent: true},
    });
    assert.equal(r.activeAgentId, 'neu');
    assert.equal(db.locks.get('x').active_agent_id, 'neu');
  });

  it('stale lock: moved-country holder is reclaimable', async () => {
    const db = new FakeDb();
    db.users.set('old', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/other'},
    });
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'old'});
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'neu',
      actorUid: 's',
      agentPatch: {actev_user: true, Isagent: true},
    });
    assert.equal(r.activeAgentId, 'neu');
  });

  it('stale lock: missing/deleted holder is reclaimable', async () => {
    const db = new FakeDb();
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {
      country_path: 'countries/x',
      active_agent_id: 'deleted_uid',
    });
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'neu',
      actorUid: 's',
      agentPatch: {actev_user: true, Isagent: true},
    });
    assert.equal(r.activeAgentId, 'neu');
  });

  it('stale lock: expired end date is reclaimable', async () => {
    const db = new FakeDb();
    db.users.set('old', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
      agent_date_end: '2001-01-01T00:00:00.000Z',
    });
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'old'});
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'neu',
      actorUid: 's',
      agentPatch: {actev_user: true, Isagent: true},
    });
    assert.equal(r.activeAgentId, 'neu');
  });

  it('stale lock: future start window is reclaimable', async () => {
    const db = new FakeDb();
    db.users.set('old', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
      agent_date_reg: '2099-01-01T00:00:00.000Z',
    });
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'old'});
    const r = await assignment.claimCountryAgent({
      firestore: db,
      countryPath: 'countries/x',
      agentId: 'neu',
      actorUid: 's',
      agentPatch: {actev_user: true, Isagent: true},
    });
    assert.equal(r.activeAgentId, 'neu');
  });

  it('valid lock is never stolen', async () => {
    const db = new FakeDb();
    db.users.set('old', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'old'});
    let code = null;
    try {
      await assignment.claimCountryAgent({
        firestore: db,
        countryPath: 'countries/x',
        agentId: 'neu',
        actorUid: 's',
        agentPatch: {actev_user: true, Isagent: true},
      });
    } catch (e) {
      code = e.message;
    }
    assert.equal(code, assignment.ERR_CONFLICT);
    assert.equal(db.locks.get('x').active_agent_id, 'old');
  });

  it('ambiguous lock (unparseable date) rejects without reclaim', async () => {
    const db = new FakeDb();
    db.users.set('old', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/x'},
      agent_date_end: 'not-a-real-date',
    });
    db.users.set('neu', {
      Isagent: true,
      actev_user: false,
      Rev_dloh_agent: {path: 'countries/x'},
    });
    db.locks.set('x', {country_path: 'countries/x', active_agent_id: 'old'});
    let code = null;
    try {
      await assignment.claimCountryAgent({
        firestore: db,
        countryPath: 'countries/x',
        agentId: 'neu',
        actorUid: 's',
        agentPatch: {actev_user: true, Isagent: true},
      });
    } catch (e) {
      code = e.message;
    }
    assert.equal(code, assignment.ERR_LOCK_AMBIGUOUS);
    assert.equal(db.locks.get('x').active_agent_id, 'old');
  });

  it('move rolls back when destination lock is valid', async () => {
    const db = new FakeDb();
    db.users.set('a1', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/from'},
    });
    db.users.set('a2', {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: {path: 'countries/to'},
    });
    db.locks.set('from', {
      country_path: 'countries/from',
      active_agent_id: 'a1',
    });
    db.locks.set('to', {
      country_path: 'countries/to',
      active_agent_id: 'a2',
    });
    let failed = false;
    try {
      await assignment.moveActiveAgentCountry({
        firestore: db,
        agentId: 'a1',
        fromCountryPath: 'countries/from',
        toCountryPath: 'countries/to',
        actorUid: 's',
      });
    } catch (e) {
      failed = e.message === assignment.ERR_CONFLICT;
    }
    assert.equal(failed, true);
    assert.equal(db.locks.get('from').active_agent_id, 'a1');
    assert.equal(db.locks.get('to').active_agent_id, 'a2');
    assert.equal(db.users.get('a1').Rev_dloh_agent.path, 'countries/from');
  });
});

console.log('F3-C3 agent country assignment tests OK');
