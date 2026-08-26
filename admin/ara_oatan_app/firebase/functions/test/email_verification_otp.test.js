'use strict';

/**
 * Email OTP unit tests (no network, no secrets in assertions of values).
 * Run: npx mocha test/email_verification_otp.test.js
 */

const assert = require('assert');
const crypto = require('crypto');
const otp = require('../email_verification_otp.js');

class FakeTimestamp {
  constructor(ms) {
    this._ms = ms;
  }
  toMillis() {
    return this._ms;
  }
  static fromMillis(ms) {
    return new FakeTimestamp(ms);
  }
  static serverTimestamp() {
    return {__server: true};
  }
}

class FakeDoc {
  constructor(id, data) {
    this.id = id;
    this._data = data ? {...data} : null;
    this.ref = this;
  }
  get exists() {
    return this._data != null;
  }
  data() {
    return this._data ? {...this._data} : undefined;
  }
  async get() {
    return this;
  }
  async set(data, opts) {
    if (opts && opts.merge && this._data) {
      this._data = {...this._data, ...data};
    } else {
      this._data = {...data};
    }
  }
  async update(data) {
    this._data = {...(this._data || {}), ...data};
  }
}

class FakeDb {
  constructor() {
    this.cols = new Map();
  }
  collection(name) {
    if (!this.cols.has(name)) this.cols.set(name, new Map());
    const col = this.cols.get(name);
    const api = {
      doc: (id) => {
        const docId = id || crypto.randomBytes(8).toString('hex');
        if (!col.has(docId)) col.set(docId, new FakeDoc(docId, null));
        return col.get(docId);
      },
      where: () => api,
      orderBy: () => api,
      limit: () => api,
      get: async () => ({empty: true, docs: []}),
    };
    return api;
  }
  async runTransaction(fn) {
    return fn({
      get: async (ref) => ref,
      set: (ref, data, opts) => ref.set(data, opts),
      update: (ref, data) => ref.update(data),
    });
  }
  batch() {
    const ops = [];
    return {
      update: (ref, data) => ops.push(() => ref.update(data)),
      commit: async () => {
        for (const op of ops) await op();
      },
    };
  }
}

// Patch FieldValue/Timestamp for module under test via admin mock is heavy —
// instead pass deps and use FakeTimestamp in challenge docs manually.

describe('email_verification_otp crypto helpers', () => {
  it('generateOtp is 6 digits', () => {
    for (let i = 0; i < 20; i++) {
      const code = otp.generateOtp();
      assert.match(code, /^\d{6}$/);
    }
  });

  it('hashOtp is keyed HMAC and does not equal raw sha256(otp)', () => {
    const secret = 'unit-test-hmac-secret-key-32b';
    const h = otp.hashOtp({
      challengeId: 'c1',
      uid: 'u1',
      emailNormalized: 'a@b.com',
      otp: '123456',
      secret,
    });
    assert.strictEqual(h.length, 64);
    const plain = crypto.createHash('sha256').update('123456').digest('hex');
    assert.notStrictEqual(h, plain);
  });

  it('timingSafeEqualHex works', () => {
    assert.strictEqual(otp.timingSafeEqualHex('abc', 'abc'), true);
    assert.strictEqual(otp.timingSafeEqualHex('abc', 'abd'), false);
  });
});

describe('requestEmailVerificationOtp', () => {
  const secret = 'unit-test-hmac-secret-key-32b';
  let sent;

  function deps(overrides = {}) {
    sent = null;
    const db = new FakeDb();
    // Provide FieldValue/Timestamp shims used by module via admin —
    // monkeypatch admin firestore helpers used at runtime:
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      try {
        admin.initializeApp({projectId: 'demo-email-otp'});
      } catch (_) {}
    }
    admin.firestore.FieldValue = {
      serverTimestamp: () => ({__server: true}),
    };
    admin.firestore.Timestamp = FakeTimestamp;

    return {
      db,
      auth: {
        getUser: async (uid) => ({
          email: 'user@example.com',
          emailVerified: false,
          uid,
        }),
      },
      hmacSecret: secret,
      now: 1_700_000_000_000,
      generateOtp: () => '483921',
      sendEmail: async ({toEmail, otp: code}) => {
        sent = {toEmail, otp: code};
      },
      ...overrides,
    };
  }

  it('unauthenticated denied', async () => {
    await assert.rejects(
      () => otp.requestEmailVerificationOtp({}, {}),
      (e) => e.code === 'unauthenticated',
    );
  });

  it('verified user handled without sending', async () => {
    const d = deps({
      auth: {
        getUser: async () => ({
          email: 'user@example.com',
          emailVerified: true,
        }),
      },
    });
    const res = await otp.requestEmailVerificationOtp(
      {},
      {auth: {uid: 'u1'}},
      d,
    );
    assert.strictEqual(res.alreadyVerified, true);
    assert.strictEqual(sent, null);
  });

  it('email missing handled', async () => {
    const d = deps({
      auth: {getUser: async () => ({email: '', emailVerified: false})},
    });
    await assert.rejects(
      () => otp.requestEmailVerificationOtp({}, {auth: {uid: 'u1'}}, d),
      (e) => e.message === 'EMAIL_MISSING',
    );
  });

  it('OTP generated, never returned, hash stored, expiry stored', async () => {
    const d = deps();
    process.env.EMAIL_OTP_HMAC_SECRET = secret;
    const res = await otp.requestEmailVerificationOtp(
      {locale: 'en'},
      {auth: {uid: 'u1'}},
      d,
    );
    assert.strictEqual(res.ok, true);
    assert.ok(res.challengeId);
    assert.strictEqual(res.otp, undefined);
    assert.strictEqual(JSON.stringify(res).includes('483921'), false);
    assert.strictEqual(sent.otp, '483921');

    const challenge = d.db.cols.get(otp.COLLECTION).get(res.challengeId);
    assert.ok(challenge.exists);
    const data = challenge.data();
    assert.ok(data.otpHash);
    assert.strictEqual(data.otp, undefined);
    assert.ok(data.expiresAt);
    assert.strictEqual(data.otpHash.includes('483921'), false);
  });

  it('cooldown enforced', async () => {
    const d = deps();
    process.env.EMAIL_OTP_HMAC_SECRET = secret;
    await otp.requestEmailVerificationOtp({}, {auth: {uid: 'u1'}}, d);
    await assert.rejects(
      () => otp.requestEmailVerificationOtp({}, {auth: {uid: 'u1'}}, d),
      (e) => e.message === 'RESEND_COOLDOWN',
    );
  });
});

describe('verifyEmailVerificationOtp', () => {
  const secret = 'unit-test-hmac-secret-key-32b';
  let authState;

  function setupChallenge({otpCode = '483921', overrides = {}} = {}) {
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      try {
        admin.initializeApp({projectId: 'demo-email-otp'});
      } catch (_) {}
    }
    admin.firestore.FieldValue = {
      serverTimestamp: () => ({__server: true}),
    };
    admin.firestore.Timestamp = FakeTimestamp;

    const db = new FakeDb();
    const challengeId = 'chal1';
    const uid = 'u1';
    const email = 'user@example.com';
    const otpHash = otp.hashOtp({
      challengeId,
      uid,
      emailNormalized: email,
      otp: otpCode,
      secret,
    });
    const doc = db.collection(otp.COLLECTION).doc(challengeId);
    doc._data = {
      uid,
      emailNormalized: email,
      otpHash,
      createdAt: FakeTimestamp.fromMillis(1_700_000_000_000),
      expiresAt: FakeTimestamp.fromMillis(1_700_000_000_000 + otp.OTP_EXPIRY_MS),
      attemptCount: 0,
      maxAttempts: 5,
      usedAt: null,
      invalidatedAt: null,
      purpose: otp.PURPOSE,
      ...overrides,
    };
    authState = {email, emailVerified: false, uid};
    const auth = {
      getUser: async () => ({...authState}),
      updateUser: async (id, patch) => {
        assert.strictEqual(id, uid);
        Object.assign(authState, patch);
      },
    };
    return {
      db,
      auth,
      hmacSecret: secret,
      now: 1_700_000_000_000 + 1000,
      challengeId,
      otpCode,
    };
  }

  it('correct OTP succeeds and sets Auth emailVerified', async () => {
    const d = setupChallenge();
    const res = await otp.verifyEmailVerificationOtp(
      {challengeId: d.challengeId, code: d.otpCode},
      {auth: {uid: 'u1'}},
      d,
    );
    assert.strictEqual(res.verified, true);
    assert.strictEqual(authState.emailVerified, true);
    const ch = d.db.cols.get(otp.COLLECTION).get(d.challengeId).data();
    assert.ok(ch.usedAt);
  });

  it('wrong OTP fails and increments attempts', async () => {
    const d = setupChallenge();
    await assert.rejects(
      () =>
        otp.verifyEmailVerificationOtp(
          {challengeId: d.challengeId, code: '000000'},
          {auth: {uid: 'u1'}},
          d,
        ),
      (e) => e.message === 'INVALID_CODE',
    );
    const ch = d.db.cols.get(otp.COLLECTION).get(d.challengeId).data();
    assert.strictEqual(ch.attemptCount, 1);
    assert.strictEqual(authState.emailVerified, false);
  });

  it('5 wrong attempts locks', async () => {
    const d = setupChallenge();
    for (let i = 0; i < 4; i++) {
      await assert.rejects(() =>
        otp.verifyEmailVerificationOtp(
          {challengeId: d.challengeId, code: '000000'},
          {auth: {uid: 'u1'}},
          d,
        ),
      );
    }
    await assert.rejects(
      () =>
        otp.verifyEmailVerificationOtp(
          {challengeId: d.challengeId, code: '000000'},
          {auth: {uid: 'u1'}},
          d,
        ),
      (e) => e.message === 'TOO_MANY_ATTEMPTS',
    );
    const ch = d.db.cols.get(otp.COLLECTION).get(d.challengeId).data();
    assert.ok(ch.invalidatedAt);
  });

  it('expired OTP fails', async () => {
    const d = setupChallenge();
    d.now = 1_700_000_000_000 + otp.OTP_EXPIRY_MS + 5000;
    await assert.rejects(
      () =>
        otp.verifyEmailVerificationOtp(
          {challengeId: d.challengeId, code: d.otpCode},
          {auth: {uid: 'u1'}},
          d,
        ),
      (e) => e.message === 'OTP_EXPIRED',
    );
  });

  it('used OTP fails', async () => {
    const d = setupChallenge({
      overrides: {usedAt: FakeTimestamp.fromMillis(1)},
    });
    await assert.rejects(
      () =>
        otp.verifyEmailVerificationOtp(
          {challengeId: d.challengeId, code: d.otpCode},
          {auth: {uid: 'u1'}},
          d,
        ),
      (e) => e.message === 'OTP_ALREADY_USED',
    );
  });

  it('cross-user fails', async () => {
    const d = setupChallenge();
    await assert.rejects(
      () =>
        otp.verifyEmailVerificationOtp(
          {challengeId: d.challengeId, code: d.otpCode},
          {auth: {uid: 'other'}},
          {
            ...d,
            auth: {
              getUser: async () => ({
                email: 'other@example.com',
                emailVerified: false,
              }),
              updateUser: async () => {
                throw new Error('should not update');
              },
            },
          },
        ),
      (e) => e.message === 'CROSS_USER_DENIED' || e.code === 'permission-denied',
    );
  });

  it('email-changed challenge fails', async () => {
    const d = setupChallenge();
    authState.email = 'new@example.com';
    await assert.rejects(
      () =>
        otp.verifyEmailVerificationOtp(
          {challengeId: d.challengeId, code: d.otpCode},
          {auth: {uid: 'u1'}},
          d,
        ),
      (e) => e.message === 'EMAIL_CHANGED',
    );
  });

  it('FIREBASE_AUTH_EMAILVERIFIED_SOT: false → verify → true', async () => {
    const d = setupChallenge();
    assert.strictEqual(authState.emailVerified, false);
    await otp.verifyEmailVerificationOtp(
      {challengeId: d.challengeId, code: d.otpCode},
      {auth: {uid: 'u1'}},
      d,
    );
    assert.strictEqual(authState.emailVerified, true);
  });

  it('double correct submit: second is alreadyVerified (Auth SoT idempotent)', async () => {
    const d = setupChallenge();
    let updates = 0;
    d.auth.updateUser = async (id, patch) => {
      updates += 1;
      Object.assign(authState, patch);
    };
    const first = await otp.verifyEmailVerificationOtp(
      {challengeId: d.challengeId, code: d.otpCode},
      {auth: {uid: 'u1'}},
      d,
    );
    assert.strictEqual(first.verified, true);
    const second = await otp.verifyEmailVerificationOtp(
      {challengeId: d.challengeId, code: d.otpCode},
      {auth: {uid: 'u1'}},
      d,
    );
    assert.strictEqual(second.verified, true);
    assert.strictEqual(second.alreadyVerified, true);
    assert.strictEqual(updates, 1);
    const ch = d.db.cols.get(otp.COLLECTION).get(d.challengeId).data();
    assert.ok(ch.usedAt);
  });
});
