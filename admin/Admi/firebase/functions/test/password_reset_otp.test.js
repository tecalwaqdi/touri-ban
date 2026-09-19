'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const passwordReset = require('../password_reset_otp.js');

describe('password_reset_otp', () => {
  it('hash includes purpose prefix', () => {
    const secret = 'test-secret-min-16-chars';
    const h = passwordReset.hashOtp({
      challengeId: 'c1',
      uid: 'u1',
      emailNormalized: 'a@b.com',
      otp: '123456',
      secret,
    });
    assert.equal(typeof h, 'string');
    assert.equal(h.length, 64);
  });

  it('confirm updates password after valid otp', async () => {
    const secret = 'test-secret-min-16-chars';
    const now = Date.now();
    const uid = 'test_uid_pwd';
    const email = 'driver@example.com';
    const otp = '654321';
    const challengeId = 'chal_pwd_1';

    const store = new Map();
    const challengeRef = {
      id: challengeId,
      path: `email_verification_challenges/${challengeId}`,
    };
    store.set(challengeRef.path, {
      uid,
      emailNormalized: email,
      purpose: passwordReset.PURPOSE,
      otpHash: passwordReset.hashOtp({
        challengeId,
        uid,
        emailNormalized: email,
        otp,
        secret,
      }),
      expiresAt: {toMillis: () => now + 600000},
      attemptCount: 0,
      maxAttempts: 5,
    });

    const db = {
      collection(name) {
        return {
          doc(id) {
            const path = `${name}/${id}`;
            return {
              id,
              path,
              get: async () => ({
                exists: store.has(path),
                data: () => store.get(path),
              }),
            };
          },
        };
      },
      runTransaction(fn) {
        const tx = {
          async get(ref) {
            return {
              exists: store.has(ref.path),
              data: () => store.get(ref.path),
            };
          },
          update(ref, patch) {
            const cur = store.get(ref.path) || {};
            store.set(ref.path, {...cur, ...patch});
          },
        };
        return fn(tx);
      },
    };

    let updatedPassword;
    const auth = {
      updateUser: async (id, patch) => {
        assert.equal(id, uid);
        updatedPassword = patch.password;
      },
    };

    const res = await passwordReset.confirmPasswordResetOtp(
      {challengeId, code: otp, newPassword: 'newpass9'},
      {},
      {db, auth, hmacSecret: secret, now},
    );
    assert.equal(res.ok, true);
    assert.equal(updatedPassword, 'newpass9');
  });
});
