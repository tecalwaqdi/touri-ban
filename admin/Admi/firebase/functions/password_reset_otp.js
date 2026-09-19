'use strict';

/**
 * Password reset via 6-digit email OTP (Resend) — unauthenticated login recovery.
 * Same delivery path as driver email verification OTP.
 */

const crypto = require('crypto');
const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const resendEmail = require('./resend_email_service.js');

const OTP_LENGTH = 6;
const OTP_EXPIRY_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_VERIFY_ATTEMPTS = 5;
const HOURLY_REQUEST_CAP = 8;
const PURPOSE = 'password_reset';
const COLLECTION = 'email_verification_challenges';
const RATE_COLLECTION = 'email_otp_rate_limits';
const CHALLENGE_VERSION = 1;
const MIN_PASSWORD_LEN = 6;

function httpsError(code, message, details) {
  return new functions.https.HttpsError(code, message, details);
}

function normalizeEmail(email) {
  return String(email || '')
    .trim()
    .toLowerCase();
}

function getHmacSecret() {
  const secret = process.env.EMAIL_OTP_HMAC_SECRET || '';
  if (!secret || secret.length < 16) {
    throw httpsError(
      'failed-precondition',
      'EMAIL_OTP_NOT_CONFIGURED',
      {reason: 'EMAIL_OTP_HMAC_SECRET'},
    );
  }
  return secret;
}

function generateOtp() {
  const n = crypto.randomInt(0, 1000000);
  return String(n).padStart(OTP_LENGTH, '0');
}

function hashOtp({challengeId, uid, emailNormalized, otp, secret}) {
  return crypto
    .createHmac('sha256', secret)
    .update(`${PURPOSE}|${challengeId}|${uid}|${emailNormalized}|${otp}`)
    .digest('hex');
}

function timingSafeEqualHex(a, b) {
  const aa = Buffer.from(String(a || ''), 'utf8');
  const bb = Buffer.from(String(b || ''), 'utf8');
  if (aa.length !== bb.length) return false;
  return crypto.timingSafeEqual(aa, bb);
}

async function sendResetOtpEmail({toEmail, otp, locale}) {
  try {
    return await resendEmail.sendPasswordResetOtpEmail({toEmail, otp, locale});
  } catch (err) {
    if (err && err.code === 'RESEND_PROVIDER_ERROR') {
      throw httpsError('internal', 'RESEND_PROVIDER_ERROR');
    }
    throw httpsError('internal', 'OTP_SEND_FAILED');
  }
}

async function enforceHourlyRateLimit(db, {uid, emailNormalized}) {
  const hourBucket = new Date().toISOString().slice(0, 13);
  const refs = [
    db.collection(RATE_COLLECTION).doc(`pwd_uid_${uid}_${hourBucket}`),
    db.collection(RATE_COLLECTION).doc(`pwd_email_${emailNormalized}_${hourBucket}`),
  ];
  for (const ref of refs) {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const count = snap.exists ? Number(snap.data().count || 0) : 0;
      if (count >= HOURLY_REQUEST_CAP) {
        throw httpsError('resource-exhausted', 'SEND_RATE_LIMITED');
      }
      tx.set(
        ref,
        {
          count: count + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    });
  }
}

async function invalidateActiveChallenges(db, uid) {
  const snap = await db
    .collection(COLLECTION)
    .where('uid', '==', uid)
    .limit(40)
    .get()
    .catch(() => null);
  const docs = snap && !snap.empty ? snap.docs : [];
  if (!docs.length) return;
  const batch = db.batch();
  let n = 0;
  for (const d of docs) {
    const data = d.data() || {};
    if (data.purpose !== PURPOSE || data.usedAt || data.invalidatedAt) continue;
    batch.update(d.ref, {
      invalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    n += 1;
  }
  if (n > 0) await batch.commit();
}

/**
 * @param {{email?:string, locale?:string}} data
 */
async function requestPasswordResetOtp(data, context, deps = {}) {
  const db = deps.db || admin.firestore();
  const auth = deps.auth || admin.auth();
  const sendEmail = deps.sendEmail || sendResetOtpEmail;
  const secret = deps.hmacSecret || getHmacSecret();
  const now = deps.now || Date.now();
  const locale = typeof data?.locale === 'string' ? data.locale : 'en';

  const email = normalizeEmail(data?.email);
  if (!email || !email.includes('@') || email.length > 254) {
    throw httpsError('invalid-argument', 'INVALID_EMAIL');
  }

  let uid;
  try {
    const userRecord = await auth.getUserByEmail(email);
    uid = userRecord.uid;
  } catch (e) {
    if (e && e.code === 'auth/user-not-found') {
      return {
        ok: true,
        requestAccepted: true,
        emailMasked: resendEmail.maskEmail(email),
        message: 'GENERIC_RESET_SENT',
      };
    }
    throw httpsError('internal', 'AUTH_LOOKUP_FAILED');
  }

  const cooldownRef = db.collection('email_otp_cooldown').doc(`pwd_${uid}`);
  const cooldownSnap = await cooldownRef.get();
  if (cooldownSnap.exists) {
    const last = cooldownSnap.data() || {};
    const lastMs =
      (last.lastSentAt && last.lastSentAt.toMillis && last.lastSentAt.toMillis()) ||
      0;
    if (lastMs && now - lastMs < RESEND_COOLDOWN_MS) {
      const retryAfterSec = Math.ceil((RESEND_COOLDOWN_MS - (now - lastMs)) / 1000);
      throw httpsError('resource-exhausted', 'SEND_RATE_LIMITED', {
        retryAfterSec,
      });
    }
  }

  await enforceHourlyRateLimit(db, {uid, emailNormalized: email});
  await invalidateActiveChallenges(db, uid);

  const challengeRef = db.collection(COLLECTION).doc();
  const challengeId = challengeRef.id;
  const otp = (deps.generateOtp || generateOtp)();
  const otpHash = hashOtp({
    challengeId,
    uid,
    emailNormalized: email,
    otp,
    secret,
  });
  const expiresAtMs = now + OTP_EXPIRY_MS;
  const tsNow = deps.now
    ? admin.firestore.Timestamp.fromMillis(now)
    : admin.firestore.FieldValue.serverTimestamp();

  await challengeRef.set({
    uid,
    emailNormalized: email,
    purpose: PURPOSE,
    otpHash,
    createdAt: tsNow,
    expiresAt: admin.firestore.Timestamp.fromMillis(expiresAtMs),
    attemptCount: 0,
    maxAttempts: MAX_VERIFY_ATTEMPTS,
    usedAt: null,
    consumedAt: null,
    invalidatedAt: null,
    lastSentAt: tsNow,
    version: CHALLENGE_VERSION,
  });

  await cooldownRef.set({lastSentAt: tsNow}, {merge: true});
  await sendEmail({toEmail: email, otp, locale});

  return {
    ok: true,
    challengeId,
    emailMasked: resendEmail.maskEmail(email),
    expiresInSec: Math.floor(OTP_EXPIRY_MS / 1000),
    resendCooldownSec: Math.floor(RESEND_COOLDOWN_MS / 1000),
  };
}

/**
 * @param {{challengeId?:string, code?:string, newPassword?:string}} data
 */
async function confirmPasswordResetOtp(data, context, deps = {}) {
  const db = deps.db || admin.firestore();
  const auth = deps.auth || admin.auth();
  const secret = deps.hmacSecret || getHmacSecret();
  const now = deps.now || Date.now();

  const challengeId = String(data?.challengeId || '').trim();
  const code = String(data?.code || '').trim();
  const newPassword = String(data?.newPassword || '');
  if (!challengeId || !/^\d{6}$/.test(code)) {
    throw httpsError('invalid-argument', 'OTP_INVALID');
  }
  if (newPassword.length < MIN_PASSWORD_LEN) {
    throw httpsError('invalid-argument', 'WEAK_PASSWORD');
  }

  const challengeRef = db.collection(COLLECTION).doc(challengeId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(challengeRef);
    if (!snap.exists) {
      return {fail: 'OTP_INVALID', http: 'not-found'};
    }
    const ch = snap.data() || {};

    if (ch.purpose !== PURPOSE) {
      return {fail: 'OTP_INVALID', http: 'failed-precondition'};
    }
    if (ch.usedAt || ch.consumedAt) {
      return {fail: 'OTP_CONSUMED', http: 'failed-precondition'};
    }
    if (ch.invalidatedAt) {
      return {fail: 'OTP_INVALID', http: 'failed-precondition'};
    }
    const expiresMs =
      (ch.expiresAt && ch.expiresAt.toMillis && ch.expiresAt.toMillis()) || 0;
    if (!expiresMs || now > expiresMs) {
      tx.update(challengeRef, {
        invalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {fail: 'OTP_EXPIRED', http: 'failed-precondition'};
    }

    const uid = String(ch.uid || '');
    const emailNormalized = normalizeEmail(ch.emailNormalized);
    if (!uid || !emailNormalized) {
      return {fail: 'OTP_INVALID', http: 'failed-precondition'};
    }

    const attempts = Number(ch.attemptCount || 0);
    const maxAttempts = Number(ch.maxAttempts || MAX_VERIFY_ATTEMPTS);
    if (attempts >= maxAttempts) {
      tx.update(challengeRef, {
        invalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {fail: 'OTP_TOO_MANY_ATTEMPTS', http: 'resource-exhausted'};
    }

    const expectedHash = hashOtp({
      challengeId,
      uid,
      emailNormalized,
      otp: code,
      secret,
    });
    const ok = timingSafeEqualHex(expectedHash, ch.otpHash);
    if (!ok) {
      const next = attempts + 1;
      const update = {attemptCount: next};
      if (next >= maxAttempts) {
        update.invalidatedAt = admin.firestore.FieldValue.serverTimestamp();
        tx.update(challengeRef, update);
        return {fail: 'OTP_TOO_MANY_ATTEMPTS', http: 'resource-exhausted'};
      }
      tx.update(challengeRef, update);
      return {fail: 'OTP_INVALID', http: 'invalid-argument'};
    }

    const consumedAt = admin.firestore.FieldValue.serverTimestamp();
    tx.update(challengeRef, {
      usedAt: consumedAt,
      consumedAt,
      attemptCount: attempts + 1,
    });
    return {ok: true, uid};
  });

  if (result && result.fail) {
    throw httpsError(result.http || 'invalid-argument', result.fail);
  }
  if (!result || !result.ok || !result.uid) {
    throw httpsError('internal', 'RESET_FAILED');
  }

  await auth.updateUser(result.uid, {password: newPassword});
  return {ok: true};
}

module.exports = {
  PURPOSE,
  requestPasswordResetOtp,
  confirmPasswordResetOtp,
  normalizeEmail,
  hashOtp,
  generateOtp,
};
