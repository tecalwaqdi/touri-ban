'use strict';

/**
 * In-memory Firestore subset for settlement ledger tests.
 * Supports get/set/update/delete, simple where, and transactional OCC.
 */
class FakeTimestamp {
  constructor(date) {
    this._date = date instanceof Date ? date : new Date(date);
  }
  toDate() {
    return this._date;
  }
  toMillis() {
    return this._date.getTime();
  }
}

class FakeDocumentSnapshot {
  constructor(ref, data, exists) {
    this.ref = ref;
    this._data = data ? JSON.parse(JSON.stringify(data)) : null;
    this.exists = exists;
    this.id = ref.id;
  }
  data() {
    return this._data ? JSON.parse(JSON.stringify(this._data)) : undefined;
  }
}

class FakeDocumentReference {
  constructor(db, path) {
    this._db = db;
    this.path = path;
    const parts = path.split('/');
    this.id = parts[parts.length - 1];
  }
  collection(name) {
    return new FakeCollectionReference(this._db, `${this.path}/${name}`);
  }
  async get() {
    const rec = this._db._get(this.path);
    return new FakeDocumentSnapshot(this, rec ? rec.data : null, !!rec);
  }
  async set(data, opts = {}) {
    this._db._set(this.path, data, opts.merge === true);
  }
  async update(data) {
    this._db._update(this.path, data);
  }
  async delete() {
    this._db._delete(this.path);
  }
}

class FakeQuery {
  constructor(db, collPath, filters = []) {
    this._db = db;
    this._collPath = collPath;
    this._filters = filters;
  }
  where(field, op, value) {
    return new FakeQuery(this._db, this._collPath, [
      ...this._filters,
      {field, op, value},
    ]);
  }
  orderBy() {
    return this;
  }
  limit() {
    return this;
  }
  async get() {
    const docs = this._db._query(this._collPath, this._filters);
    return {
      empty: docs.length === 0,
      size: docs.length,
      docs,
      forEach(fn) {
        docs.forEach(fn);
      },
    };
  }
}

class FakeCollectionReference extends FakeQuery {
  constructor(db, collPath) {
    super(db, collPath, []);
    this.path = collPath;
  }
  doc(id) {
    const docId = id || this._db._autoId();
    return new FakeDocumentReference(this._db, `${this._collPath}/${docId}`);
  }
}

class FakeTransaction {
  constructor(db) {
    this._db = db;
    this._readVersions = new Map();
    this._writes = [];
  }
  async get(ref) {
    const rec = this._db._get(ref.path);
    this._readVersions.set(ref.path, rec ? rec.version : 0);
    return new FakeDocumentSnapshot(ref, rec ? rec.data : null, !!rec);
  }
  set(ref, data, opts = {}) {
    this._writes.push({op: 'set', path: ref.path, data, merge: opts.merge === true});
  }
  update(ref, data) {
    this._writes.push({op: 'update', path: ref.path, data});
  }
  delete(ref) {
    this._writes.push({op: 'delete', path: ref.path});
  }
  _commit() {
    for (const [path, ver] of this._readVersions.entries()) {
      const rec = this._db._get(path);
      const current = rec ? rec.version : 0;
      if (current !== ver) {
        const err = new Error('ABORTED');
        err.code = 'aborted';
        throw err;
      }
    }
    for (const w of this._writes) {
      if (w.op === 'set') this._db._set(w.path, w.data, w.merge);
      else if (w.op === 'update') this._db._update(w.path, w.data);
      else if (w.op === 'delete') this._db._delete(w.path);
    }
  }
}

class FakeFirestore {
  constructor() {
    this._docs = new Map();
    this._id = 0;
    this.FieldValue = {
      serverTimestamp: () => ({_sv: true}),
      increment: (n) => ({_inc: n}),
    };
  }
  _autoId() {
    this._id += 1;
    return `auto_${this._id}`;
  }
  _get(path) {
    return this._docs.get(path) || null;
  }
  _clone(data) {
    return JSON.parse(JSON.stringify(data));
  }
  _applySpecials(target, patch) {
    const out = {...target};
    for (const [k, v] of Object.entries(patch)) {
      if (v && typeof v === 'object' && v._sv) {
        out[k] = new Date().toISOString();
      } else if (v && typeof v === 'object' && typeof v._inc === 'number') {
        out[k] = (typeof out[k] === 'number' ? out[k] : 0) + v._inc;
      } else {
        out[k] = v;
      }
    }
    return out;
  }
  _set(path, data, merge) {
    const prev = this._get(path);
    const next = merge && prev ? this._applySpecials(prev.data, data) : this._applySpecials({}, data);
    this._docs.set(path, {data: this._clone(next), version: (prev ? prev.version : 0) + 1});
  }
  _update(path, data) {
    const prev = this._get(path);
    if (!prev) {
      const err = new Error('NOT_FOUND');
      err.code = 'not-found';
      throw err;
    }
    this._docs.set(path, {
      data: this._clone(this._applySpecials(prev.data, data)),
      version: prev.version + 1,
    });
  }
  _delete(path) {
    this._docs.delete(path);
  }
  _query(collPath, filters) {
    const prefix = `${collPath}/`;
    const out = [];
    for (const [path, rec] of this._docs.entries()) {
      if (!path.startsWith(prefix)) continue;
      const rest = path.slice(prefix.length);
      if (rest.includes('/')) continue;
      let ok = true;
      for (const f of filters) {
        const left = rec.data[f.field];
        const right = f.value;
        if (f.op === '==') {
          const lv = left && left.path ? left.path : left;
          const rv = right && right.path ? right.path : right;
          if (lv !== rv) ok = false;
        }
      }
      if (ok) {
        const ref = new FakeDocumentReference(this, path);
        out.push(new FakeDocumentSnapshot(ref, rec.data, true));
      }
    }
    return out;
  }
  collection(name) {
    return new FakeCollectionReference(this, name);
  }
  doc(path) {
    return new FakeDocumentReference(this, path);
  }
  async runTransaction(fn) {
    let last;
    for (let i = 0; i < 8; i++) {
      const tx = new FakeTransaction(this);
      try {
        const result = await fn(tx);
        tx._commit();
        return result;
      } catch (e) {
        last = e;
        if (e && e.code === 'aborted') continue;
        throw e;
      }
    }
    throw last;
  }
}

module.exports = {FakeFirestore, FakeTimestamp};
