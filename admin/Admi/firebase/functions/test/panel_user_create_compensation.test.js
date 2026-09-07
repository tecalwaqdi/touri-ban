'use strict';

const assert = require('node:assert/strict');
const {describe, it} = require('node:test');
const {
  compensateFailedPanelUserCreate,
} = require('../panel_user_create_compensation.js');

describe('createPanelUser compensation', () => {
  it('deletes Auth + user doc after assignment failure', async () => {
    const authUsers = new Set(['uid1']);
    const docs = new Map([['uid1', {Isagent: true}]]);
    const audits = [];
    const auth = {
      async deleteUser(uid) {
        if (!authUsers.has(uid)) throw new Error('missing');
        authUsers.delete(uid);
      },
    };
    const firestore = {
      doc(path) {
        const id = path.split('/')[1];
        return {
          async delete() {
            docs.delete(id);
          },
        };
      },
    };
    const r = await compensateFailedPanelUserCreate({
      auth,
      firestore,
      uid: 'uid1',
      actorUid: 'admin',
      reason: 'AGENT_COUNTRY_ALREADY_HAS_ACTIVE_AGENT',
      auditWriter: async (row) => audits.push(row),
    });
    assert.equal(r.ok, true);
    assert.equal(r.authOrphan, false);
    assert.equal(r.userDocOrphan, false);
    assert.equal(authUsers.size, 0);
    assert.equal(docs.size, 0);
    assert.equal(audits.length, 1);
    assert.equal(audits[0].action, 'create_panel_user_compensation');
  });

  it('reports recoverable Auth orphan when Auth delete fails', async () => {
    const docs = new Map([['uid2', {Isagent: true}]]);
    const auth = {
      async deleteUser() {
        throw new Error('auth delete denied');
      },
    };
    const firestore = {
      doc(path) {
        const id = path.split('/')[1];
        return {
          async delete() {
            docs.delete(id);
          },
        };
      },
    };
    const r = await compensateFailedPanelUserCreate({
      auth,
      firestore,
      uid: 'uid2',
      actorUid: 'admin',
      reason: 'claim_failed',
    });
    assert.equal(r.ok, false);
    assert.equal(r.authOrphan, true);
    assert.equal(r.userDocOrphan, false);
    assert.equal(docs.size, 0);
    assert.match(r.authDeleteError, /auth delete denied/);
  });
});
