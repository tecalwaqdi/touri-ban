'use strict';

/**
 * Secure 6-digit Email OTP verification (Driver Registration V2).
 *
 * SoT after success: Firebase Auth emailVerified=true (Admin SDK only).
 * Never stores plaintext OTP. Never returns OTP to clients.
 *
 * Secrets (server-only, never commit):
 *   RESEND_API_KEY
 *   EMAIL_OTP_HMAC_SECRET
 * Optional env (non-secret):
 *   RESEND_FROM_EMAIL
 *   RESEND_FROM_NAME
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
const PURPOSE = 'email_verification';
const COLLECTION = 'email_verification_challenges';
const RATE_COLLECTION = 'email_otp_rate_limits';
const CHALLENGE_VERSION = 1;

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
    .update(`${challengeId}|${uid}|${emailNormalized}|${otp}`)
    .digest('hex');
}

function timingSafeEqualHex(a, b) {
  const aa = Buffer.from(String(a || ''), 'utf8');
  const bb = Buffer.from(String(b || ''), 'utf8');
  if (aa.length !== bb.length) return false;
  return crypto.timingSafeEqual(aa, bb);
}

async function sendResendOtpEmail({toEmail, otp, locale}) {
  try {
    return await resendEmail.sendVerificationOtpEmail({toEmail, otp, locale});
  } catch (err) {
    if (err && err.code === 'RESEND_PROVIDER_ERROR') {
      throw httpsError('internal', 'RESEND_PROVIDER_ERROR');
    }
    throw httpsError('internal', 'OTP_SEND_FAILED');
  }
}

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw httpsError('unauthenticated', 'AUTHENTICATION_REQUIRED');
  }
  return context.auth.uid;
}

async function enforceHourlyRateLimit(db, {uid, emailNormalized}) {
  const hourBucket = new Date().toISOString().slice(0, 13);
  const refs = [
    db.collection(RATE_COLLECTION).doc(`uid_${uid}_${hourBucket}`),
    db.collection(RATE_COLLECTION).doc(`email_${emailNormalized}_${hourBucket}`),
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
  let docs = snap && !snap.empty ? snap.docs : [];
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

async function requestEmailVerificationOtp(data, context, deps = {}) {
  const uid = requireAuth(context);
  const db = deps.db || admin.firestore();
  const auth = deps.auth || admin.auth();
  const sendEmail = deps.sendEmail || sendResendOtpEmail;
  const secret = deps.hmacSecret || getHmacSecret();
  const now = deps.now || Date.now();
  const locale = typeof data?.locale === 'string' ? data.locale : 'en';

  const userRecord = await auth.getUser(uid);
  const email = normalizeEmail(userRecord.email);
  if (!email) {
    throw httpsError('failed-precondition', 'EMAIL_MISSING');
  }
  if (userRecord.emailVerified === true) {
    return {
      alreadyVerified: true,
      verified: true,
      emailMasked: resendEmail.maskEmail(email),
    };
  }

  const cooldownRef = db.collection('email_otp_cooldown').doc(uid);
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

async function verifyEmailVerificationOtp(data, context, deps = {}) {
  const uid = requireAuth(context);
  const db = deps.db || admin.firestore();
  const auth = deps.auth || admin.auth();
  const secret = deps.hmacSecret || getHmacSecret();
  const now = deps.now || Date.now();

  const challengeId = String(data?.challengeId || '').trim();
  const code = String(data?.code || '').trim();
  if (!challengeId || !/^\d{6}$/.test(code)) {
    throw httpsError('invalid-argument', 'OTP_INVALID');
  }

  const userRecord = await auth.getUser(uid);
  if (userRecord.emailVerified === true) {
    return {verified: true, alreadyVerified: true};
  }
  const currentEmail = normalizeEmail(userRecord.email);
  if (!currentEmail) {
    throw httpsError('failed-precondition', 'EMAIL_MISSING');
  }

  const challengeRef = db.collection(COLLECTION).doc(challengeId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(challengeRef);
    if (!snap.exists) {
      return {fail: 'OTP_INVALID', http: 'not-found'};
    }
    const ch = snap.data() || {};

    if (ch.uid !== uid) {
      return {fail: 'CROSS_USER_DENIED', http: 'permission-denied'};
    }
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
    if (normalizeEmail(ch.emailNormalized) !== currentEmail) {
      return {fail: 'EMAIL_CHANGED', http: 'failed-precondition'};
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
      emailNormalized: currentEmail,
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
    return {ok: true};
  });

  if (result && result.fail) {
    throw httpsError(result.http || 'invalid-argument', result.fail);
  }
  if (!result || !result.ok) {
    throw httpsError('internal', 'VERIFY_FAILED');
  }

  await auth.updateUser(uid, {emailVerified: true});

  try {
    await db.doc(`user/${uid}`).set(
      {
        email_verified_mirror: true,
        emailVerifiedMirrorAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  } catch (_) {}

  return {verified: true};
}

module.exports = {
  OTP_LENGTH,
  OTP_EXPIRY_MS,
  RESEND_COOLDOWN_MS,
  MAX_VERIFY_ATTEMPTS,
  PURPOSE,
  COLLECTION,
  CHALLENGE_VERSION,
  normalizeEmail,
  generateOtp,
  hashOtp,
  timingSafeEqualHex,
  requestEmailVerificationOtp,
  verifyEmailVerificationOtp,
};
