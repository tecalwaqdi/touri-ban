'use strict';

const assert = require('node:assert/strict');
const {describe, it} = require('node:test');
const {
  AccountDeletionError,
  assertDriverDeletionAllowed,
  requestAccountDeletion,
  runAccountDeletionCleanup,
  createAccountDeletionRequest,
  OPEN_SETTLEMENT_STATUSES,
} = require('../account_deletion.js');

function memoryDb(seed = {}) {
  const store = new Map();
  for (const [path, data] of Object.entries(seed)) {
    store.set(path, {...data});
  }

  function doc(path) {
    return {
      id: path.split('/').pop(),
      path,
      async get() {
        const data = store.get(path);
        return {
          exists: data != null,
          id: path.split('/').pop(),
          ref: doc(path),
          data: () => (data != null ? {...data} : undefined),
        };
      },
      async set(data, opts) {
        const prev = store.get(path) || {};
        store.set(path, opts && opts.merge ? {...prev, ...deepMerge(prev, data)} : {...data});
      },
      async update(data) {
        const prev = store.get(path) || {};
        store.set(path, deepMerge(prev, data));
      },
      async delete() {
        store.delete(path);
      },
      collection(name) {
        return collection(`${path}/${name}`);
      },
    };
  }

  function deepMerge(a, b) {
    const out = {...a};
    for (const [k, v] of Object.entries(b || {})) {
      if (v && typeof v === 'object' && !Array.isArray(v) && typeof v.isEqual !== 'function') {
        if (v._methodName === 'FieldValue.delete' || v.methodName === 'FieldValue.delete') {
          delete out[k];
        } else if (k === 'accountDeletion' || typeof out[k] === 'object') {
          out[k] = {...(out[k] || {}), ...v};
        } else {
          out[k] = v;
        }
      } else {
        out[k] = v;
      }
    }
    return out;
  }

  function collection(name) {
    return {
      firestore: {batch: () => makeBatch()},
      doc(id) {
        return doc(`${name}/${id}`);
      },
      async add(data) {
        const id = `auto_${store.size + 1}`;
        const path = `${name}/${id}`;
        store.set(path, {...data});
        return doc(path);
      },
      limit() {
        return this.where('__all__', '==', true);
      },
      async get() {
        return this.where('__all__', '==', true).get();
      },
      where(field, op, value) {
        const filters = field === '__all__' ? [] : [{field, op, value}];
        const api = {
          where(f, o, v) {
            filters.push({field: f, op: o, value: v});
            return api;
          },
          limit() {
            return api;
          },
          async get() {
            const docs = [];
            for (const [path, data] of store.entries()) {
              if (!path.startsWith(`${name}/`)) continue;
              const rest = path.slice(name.length + 1);
              if (rest.includes('/')) continue;
              let ok = true;
              for (const f of filters) {
                let left = data[f.field];
                let right = f.value;
                if (left && left.path) left = left.path;
                if (right && right.path) right = right.path;
                if (f.op === '==' && left !== right) ok = false;
              }
              if (ok) {
                docs.push({
                  id: rest,
                  ref: doc(path),
                  data: () => ({...data}),
                });
              }
            }
            return {empty: docs.length === 0, size: docs.length, docs};
          },
        };
        return api;
      },
    };
  }

  function makeBatch() {
    const ops = [];
    return {
      delete(ref) {
        ops.push(() => store.delete(ref.path));
      },
      update(ref, data) {
        ops.push(() => {
          const prev = store.get(ref.path) || {};
          store.set(ref.path, deepMerge(prev, data));
        });
      },
      set(ref, data, opts) {
        ops.push(() => {
          const prev = store.get(ref.path) || {};
          store.set(
            ref.path,
            opts && opts.merge ? deepMerge(prev, data) : {...data},
          );
        });
      },
      async commit() {
        ops.forEach((fn) => fn());
      },
    };
  }

  return {
    store,
    doc,
    collection,
    batch: makeBatch,
  };
}

const FieldValue = {
  delete: () => ({_methodName: 'FieldValue.delete'}),
  serverTimestamp: () => new Date().toISOString(),
};

describe('account_deletion', () => {
  it('rejects unauthenticated callable', async () => {
    await assert.rejects(
      () =>
        requestAccountDeletion(
          {confirm: true},
          {},
          {db: memoryDb(), auth: {}, storage: null, FieldValue},
        ),
      (e) => e instanceof AccountDeletionError && e.code === 'unauthenticated',
    );
  });

  it('rejects client-supplied other uid', async () => {
    await assert.rejects(
      () =>
        requestAccountDeletion(
          {confirm: true, uid: 'other'},
          {auth: {uid: 'me'}},
          {db: memoryDb({'user/me': {}}), auth: {}, storage: null, FieldValue},
        ),
      (e) => e instanceof AccountDeletionError && e.code === 'permission-denied',
    );
  });

  it('blocks driver with active trip', async () => {
    const db = memoryDb({
      'user/drv1': {ismndob: true},
      'order/o1': {
        mndob_user: {path: 'user/drv1'},
        ActiveOrder: true,
        halh_text: 'مقبول',
      },
    });
    // Fix ref equality for where clauses — use same object path via doc()
    db.store.set('order/o1', {
      mndob_user: db.doc('user/drv1'),
      ActiveOrder: true,
      halh_text: 'مقبول',
    });
    await assert.rejects(
      () => assertDriverDeletionAllowed({db, uid: 'drv1', FieldValue}),
      (e) =>
        e instanceof AccountDeletionError &&
        e.code === 'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP',
    );
  });

  it('blocks driver with open settlement', async () => {
    const db = memoryDb({
      'user/drv2': {ismndob: true},
      'financial_settlements/s1': {driverId: 'drv2', status: 'locked'},
    });
    assert.ok(OPEN_SETTLEMENT_STATUSES.has('locked'));
    await assert.rejects(
      () => assertDriverDeletionAllowed({db, uid: 'drv2', FieldValue}),
      (e) =>
        e instanceof AccountDeletionError &&
        e.code === 'ACCOUNT_DELETION_BLOCKED_PENDING_SETTLEMENT',
    );
  });

  it('deletes addresses and auth; leaves order financial/identity fields untouched', async () => {
    const deletedAuth = [];
    const db = memoryDb({
      'user/c1': {
        email: 'a@b.com',
        display_name: 'Ali',
        phone_number: '9665',
        ismndob: false,
      },
      'order/o1': {
        USER: null,
        naim_user_text: 'Ali',
        phone_numper: 9665,
        total: 120.5,
        total_app: 12,
        total_mndob: 108.5,
      },
      'wallets/w1': {
        userRef: null,
        currentBalance: 50,
        isActive: true,
      },
      'ADRESSUSER/a1': {USER: null, TILET: 'home'},
    });
    db.store.get('order/o1').USER = db.doc('user/c1');
    db.store.get('wallets/w1').userRef = db.doc('user/c1');
    db.store.get('ADRESSUSER/a1').USER = db.doc('user/c1');

    const auth = {
      async deleteUser(uid) {
        deletedAuth.push(uid);
      },
    };

    const result = await runAccountDeletionCleanup({
      db,
      auth,
      storage: null,
      uid: 'c1',
      FieldValue,
      deleteAuthUser: true,
      skipDriverGates: true,
    });

    assert.equal(result.ok, true);
    assert.deepEqual(deletedAuth, ['c1']);
    const order = db.store.get('order/o1');
    assert.equal(order.naim_user_text, 'Ali');
    assert.equal(order.phone_numper, 9665);
    assert.equal(order.total, 120.5);
    assert.equal(order.total_app, 12);
    assert.equal(order.total_mndob, 108.5);
    const wallet = db.store.get('wallets/w1');
    assert.equal(wallet.currentBalance, 50);
    assert.equal(wallet.isActive, true);
    assert.equal(wallet.account_deletion_anonymized, undefined);
    assert.equal(db.store.has('ADRESSUSER/a1'), false);
    assert.equal(db.store.has('user/c1'), false);
  });

  it('createAccountDeletionRequest does not delete auth', async () => {
    const db = memoryDb();
    const res = await createAccountDeletionRequest(
      {accountType: 'customer', contact: 'user@example.com', locale: 'ar'},
      {},
      {db, FieldValue},
    );
    assert.equal(res.ok, true);
    assert.equal(res.status, 'pending_verification');
    assert.ok(res.requestId);
  });
});
