'use strict';

/**
 * Secure 6-digit Email OTP verification.
 *
 * SoT after success: Firebase Auth emailVerified=true (Admin SDK only).
 * Never stores plaintext OTP. Never returns OTP to clients.
 *
 * Secrets (server-only, never commit):
 *   EMAIL_OTP_HMAC_SECRET
 *   BREVO_API_KEY
 * Optional:
 *   BREVO_SENDER_EMAIL (default info@touri-taxi.com)
 *   BREVO_SENDER_NAME (default Touri)
 *   EMAIL_VERIFICATION_MODE (email_otp | email_link) — presentation/request path only
 */

const crypto = require('crypto');
const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

const OTP_LENGTH = 6;
const OTP_EXPIRY_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_VERIFY_ATTEMPTS = 5;
const HOURLY_REQUEST_CAP = 8;
const PURPOSE = 'email_verification';
const COLLECTION = 'email_verification_challenges';
const RATE_COLLECTION = 'email_otp_rate_limits';

function httpsError(code, message, details) {
  return new functions.https.HttpsError(code, message, details);
}

function normalizeEmail(email) {
  return String(email || '')
    .trim()
    .toLowerCase();
}

function maskEmail(email) {
  const e = normalizeEmail(email);
  const at = e.indexOf('@');
  if (at < 1) return '***';
  const local = e.slice(0, at);
  const domain = e.slice(at + 1);
  const shown = local.slice(0, Math.min(2, local.length));
  return `${shown}***@${domain}`;
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

function getEmailVerificationMode() {
  const mode = String(process.env.EMAIL_VERIFICATION_MODE || 'email_otp')
    .trim()
    .toLowerCase();
  return mode === 'email_link' ? 'email_link' : 'email_otp';
}

function generateOtp() {
  // Cryptographically secure 6-digit numeric OTP (000000–999999).
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

async function sendBrevoOtpEmail({toEmail, otp, locale}) {
  const apiKey = process.env.BREVO_API_KEY || '';
  if (!apiKey) {
    throw httpsError(
      'failed-precondition',
      'EMAIL_OTP_NOT_CONFIGURED',
      {reason: 'BREVO_API_KEY'},
    );
  }
  const senderEmail =
    process.env.BREVO_SENDER_EMAIL || 'info@touri-taxi.com';
  const senderName = process.env.BREVO_SENDER_NAME || 'Touri';
  const isAr = String(locale || '').toLowerCase().startsWith('ar');
  const subject = isAr
    ? 'رمز التحقق من بريدك الإلكتروني - Touri'
    : 'Your email verification code - Touri';
  const bodyText = isAr
    ? `رمز التحقق الخاص بك:\n${otp}\n\nتنتهي صلاحية الرمز خلال 10 دقائق.\n\nإذا لم تطلب هذا الرمز، تجاهل هذه الرسالة.`
    : `Your verification code:\n${otp}\n\nThis code expires in 10 minutes.\n\nIf you did not request this code, you can ignore this email.`;
  const bodyHtml = isAr
    ? `<p>رمز التحقق الخاص بك:</p><p style="font-size:28px;letter-spacing:6px;font-weight:700">${otp}</p><p>تنتهي صلاحية الرمز خلال 10 دقائق.</p>`
    : `<p>Your verification code:</p><p style="font-size:28px;letter-spacing:6px;font-weight:700">${otp}</p><p>This code expires in 10 minutes.</p>`;

  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
      'api-key': apiKey,
    },
    body: JSON.stringify({
      sender: {name: senderName, email: senderEmail},
      to: [{email: toEmail}],
      subject,
      textContent: bodyText,
      htmlContent: bodyHtml,
      tags: ['email_verification_otp'],
    }),
  });
  const rawText = await res.text().catch(() => '');
  let parsed = {};
  try {
    parsed = rawText ? JSON.parse(rawText) : {};
  } catch (_) {
    parsed = {};
  }
  const messageId =
    parsed.messageId ||
    (Array.isArray(parsed.messageIds) && parsed.messageIds[0]) ||
    null;

  if (!res.ok) {
    // Never log API key or OTP body. Truncate Brevo payload for ops only.
    console.error('brevo_otp_send_failed', res.status, rawText.slice(0, 200));
    const lower = rawText.toLowerCase();
    if (
      res.status === 401 &&
      (lower.includes('unrecognised ip') ||
        lower.includes('unrecognized ip') ||
        lower.includes('authorised ip') ||
        lower.includes('authorized ip'))
    ) {
      throw httpsError(
        'failed-precondition',
        'BREVO_IP_NOT_AUTHORIZED',
        {reason: 'brevo_ip_allowlist'},
      );
    }
    throw httpsError('internal', 'OTP_SEND_FAILED');
  }

  // Safe ops log only — no OTP / no API key.
  console.info(
    'brevo_otp_send_ok',
    JSON.stringify({
      httpStatus: res.status,
      messageId: messageId ? String(messageId).slice(0, 120) : null,
      sender: senderEmail,
      toMasked: maskEmail(toEmail),
    }),
  );

  // Best-effort immediate event probe (same request path; no secrets logged).
  try {
    const evRes = await fetch(
      `https://api.brevo.com/v3/smtp/statistics/events?limit=10&sort=desc&email=${encodeURIComponent(toEmail)}`,
      {
        method: 'GET',
        headers: {
          accept: 'application/json',
          'api-key': apiKey,
        },
      },
    );
    const evText = await evRes.text().catch(() => '');
    let evJson = {};
    try {
      evJson = evText ? JSON.parse(evText) : {};
    } catch (_) {
      evJson = {};
    }
    const events = Array.isArray(evJson.events) ? evJson.events : [];
    const latest = events[0] || null;
    console.info(
      'brevo_otp_events_probe',
      JSON.stringify({
        httpStatus: evRes.status,
        latestEvent: latest && latest.event ? String(latest.event) : null,
        latestMessageId:
          latest && latest.messageId
            ? String(latest.messageId).slice(0, 120)
            : null,
        eventCount: events.length,
        toMasked: maskEmail(toEmail),
      }),
    );
  } catch (probeErr) {
    console.warn(
      'brevo_otp_events_probe_failed',
      String((probeErr && probeErr.message) || probeErr).slice(0, 120),
    );
  }

  return {ok: true, messageId: messageId ? String(messageId) : null};
}

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw httpsError('unauthenticated', 'AUTHENTICATION_REQUIRED');
  }
  return context.auth.uid;
}

async function enforceHourlyRateLimit(db, {uid, emailNormalized}) {
  const hourBucket = new Date().toISOString().slice(0, 13); // YYYY-MM-DDTHH
  const refs = [
    db.collection(RATE_COLLECTION).doc(`uid_${uid}_${hourBucket}`),
    db.collection(RATE_COLLECTION).doc(`email_${emailNormalized}_${hourBucket}`),
  ];
  for (const ref of refs) {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const count = snap.exists ? Number(snap.data().count || 0) : 0;
      if (count >= HOURLY_REQUEST_CAP) {
        throw httpsError('resource-exhausted', 'RATE_LIMITED');
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
    .where('purpose', '==', PURPOSE)
    .where('usedAt', '==', null)
    .limit(40)
    .get()
    .catch(() => null);
  // Fallback without composite index: scan recent by uid
  let docs = snap && !snap.empty ? snap.docs : [];
  if (!docs.length) {
    const alt = await db
      .collection(COLLECTION)
      .where('uid', '==', uid)
      .limit(40)
      .get();
    docs = alt.docs.filter((d) => {
      const data = d.data() || {};
      return (
        data.purpose === PURPOSE &&
        !data.usedAt &&
        !data.invalidatedAt
      );
    });
  }
  const batch = db.batch();
  let n = 0;
  for (const d of docs) {
    const data = d.data() || {};
    if (data.invalidatedAt || data.usedAt) continue;
    batch.update(d.ref, {
      invalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    n += 1;
  }
  if (n > 0) await batch.commit();
}

/**
 * @param {object} data
 * @param {object} context
 * @param {object} [deps] test injection
 */
async function requestEmailVerificationOtp(data, context, deps = {}) {
  const mode = getEmailVerificationMode();
  if (mode === 'email_link') {
    throw httpsError(
      'failed-precondition',
      'EMAIL_VERIFICATION_MODE_LINK',
      {mode},
    );
  }

  const uid = requireAuth(context);
  const db = deps.db || admin.firestore();
  const auth = deps.auth || admin.auth();
  const sendEmail = deps.sendEmail || sendBrevoOtpEmail;
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
      emailMasked: maskEmail(email),
    };
  }

  // Cooldown doc (no composite index required).
  const cooldownRef = db.collection('email_otp_cooldown').doc(uid);
  const cooldownSnap = await cooldownRef.get();
  if (cooldownSnap.exists) {
    const last = cooldownSnap.data() || {};
    const lastMs =
      (last.lastSentAt && last.lastSentAt.toMillis && last.lastSentAt.toMillis()) ||
      0;
    if (lastMs && now - lastMs < RESEND_COOLDOWN_MS) {
      const retryAfterSec = Math.ceil((RESEND_COOLDOWN_MS - (now - lastMs)) / 1000);
      throw httpsError('resource-exhausted', 'RESEND_COOLDOWN', {
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
    otpHash,
    createdAt: tsNow,
    expiresAt: admin.firestore.Timestamp.fromMillis(expiresAtMs),
    attemptCount: 0,
    maxAttempts: MAX_VERIFY_ATTEMPTS,
    usedAt: null,
    invalidatedAt: null,
    lastSentAt: tsNow,
    purpose: PURPOSE,
  });

  await cooldownRef.set({lastSentAt: tsNow}, {merge: true});

  await sendEmail({toEmail: email, otp, locale});

  return {
    ok: true,
    challengeId,
    emailMasked: maskEmail(email),
    expiresInSec: Math.floor(OTP_EXPIRY_MS / 1000),
    resendCooldownSec: Math.floor(RESEND_COOLDOWN_MS / 1000),
    // Intentionally never return otp / otpHash
  };
}

/**
 * @param {{challengeId:string, code:string}} data
 * @param {object} context
 * @param {object} [deps]
 */
async function verifyEmailVerificationOtp(data, context, deps = {}) {
  const uid = requireAuth(context);
  const db = deps.db || admin.firestore();
  const auth = deps.auth || admin.auth();
  const secret = deps.hmacSecret || getHmacSecret();
  const now = deps.now || Date.now();

  const challengeId = String(data?.challengeId || '').trim();
  const code = String(data?.code || '').trim();
  if (!challengeId || !/^\d{6}$/.test(code)) {
    throw httpsError('invalid-argument', 'INVALID_CODE');
  }

  const userRecord = await auth.getUser(uid);
  if (userRecord.emailVerified === true) {
    return {verified: true, alreadyVerified: true};
  }
  const currentEmail = normalizeEmail(userRecord.email);

  const challengeRef = db.collection(COLLECTION).doc(challengeId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(challengeRef);
    if (!snap.exists) {
      return {fail: 'INVALID_CODE', http: 'not-found'};
    }
    const ch = snap.data() || {};

    if (ch.uid !== uid) {
      return {fail: 'CROSS_USER_DENIED', http: 'permission-denied'};
    }
    if (ch.purpose !== PURPOSE) {
      return {fail: 'INVALID_CODE', http: 'failed-precondition'};
    }
    if (ch.usedAt) {
      return {fail: 'OTP_ALREADY_USED', http: 'failed-precondition'};
    }
    if (ch.invalidatedAt) {
      return {fail: 'OTP_INVALIDATED', http: 'failed-precondition'};
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
      return {fail: 'TOO_MANY_ATTEMPTS', http: 'resource-exhausted'};
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
        return {fail: 'TOO_MANY_ATTEMPTS', http: 'resource-exhausted'};
      }
      // Commit attempt increment — do not throw inside the transaction
      // (throws abort and roll back the write).
      tx.update(challengeRef, update);
      return {fail: 'INVALID_CODE', http: 'invalid-argument'};
    }

    // Consume atomically before Auth update (prevents reuse).
    tx.update(challengeRef, {
      usedAt: admin.firestore.FieldValue.serverTimestamp(),
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

  // Idempotent Auth update
  await auth.updateUser(uid, {emailVerified: true});

  // Best-effort mirror for driver flows (Auth remains SoT).
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

async function getEmailVerificationOtpStatus(data, context, deps = {}) {
  const uid = requireAuth(context);
  const auth = deps.auth || admin.auth();
  const userRecord = await auth.getUser(uid);
  return {
    emailVerified: userRecord.emailVerified === true,
    emailMasked: maskEmail(userRecord.email),
    mode: getEmailVerificationMode(),
  };
}

/**
 * Delivery diagnosis only — never returns OTP. Uses Brevo events API.
 * Bound to BREVO_API_KEY via Functions secrets.
 */
async function probeBrevoOtpDeliveryEvents(data, context, deps = {}) {
  const uid = requireAuth(context);
  const auth = deps.auth || admin.auth();
  const userRecord = await auth.getUser(uid);
  const email = normalizeEmail(userRecord.email);
  if (!email) {
    throw httpsError('failed-precondition', 'EMAIL_MISSING');
  }
  const apiKey = process.env.BREVO_API_KEY || '';
  if (!apiKey) {
    throw httpsError('failed-precondition', 'EMAIL_OTP_NOT_CONFIGURED', {
      reason: 'BREVO_API_KEY',
    });
  }

  const limit = Math.min(Number(data?.limit) || 15, 50);
  const evRes = await fetch(
    `https://api.brevo.com/v3/smtp/statistics/events?limit=${limit}&sort=desc&email=${encodeURIComponent(email)}`,
    {
      method: 'GET',
      headers: {
        accept: 'application/json',
        'api-key': apiKey,
      },
    },
  );
  const evText = await evRes.text().catch(() => '');
  let evJson = {};
  try {
    evJson = evText ? JSON.parse(evText) : {};
  } catch (_) {
    evJson = {};
  }
  if (!evRes.ok) {
    console.error(
      'brevo_otp_events_probe_http',
      evRes.status,
      evText.slice(0, 200),
    );
    return {
      ok: false,
      httpStatus: evRes.status,
      emailMasked: maskEmail(email),
      events: [],
      classification: 'API_ERROR',
    };
  }

  const events = Array.isArray(evJson.events) ? evJson.events : [];
  const sanitized = events.map((e) => ({
    event: e && e.event ? String(e.event) : null,
    date: e && e.date ? String(e.date) : null,
    messageId:
      e && e.messageId ? String(e.messageId).slice(0, 120) : null,
    reason: e && e.reason ? String(e.reason).slice(0, 160) : null,
    tag: e && e.tag ? String(e.tag) : null,
  }));

  const names = sanitized.map((e) => String(e.event || '').toLowerCase());
  let classification = 'NOT_FOUND';
  if (names.some((n) => n.includes('delivered') || n === 'delivery')) {
    classification = 'DELIVERED';
  } else if (names.some((n) => n.includes('bounce') || n === 'hard_bounce' || n === 'soft_bounce')) {
    classification = 'BOUNCED';
  } else if (names.some((n) => n.includes('blocked') || n === 'blocked')) {
    classification = 'BLOCKED';
  } else if (names.some((n) => n.includes('spam') || n === 'spam')) {
    classification = 'SPAM';
  } else if (names.some((n) => n.includes('deferred') || n === 'deferred')) {
    classification = 'DEFERRED';
  } else if (names.some((n) => n.includes('invalid') || n === 'invalid')) {
    classification = 'INVALID';
  } else if (names.some((n) => n.includes('request') || n === 'requests')) {
    classification = 'REQUEST';
  } else if (names.some((n) => n.includes('sent') || n === 'sent')) {
    classification = 'SENT';
  } else if (sanitized.length > 0) {
    classification = String(sanitized[0].event || 'UNKNOWN').toUpperCase();
  }

  console.info(
    'brevo_otp_delivery_probe',
    JSON.stringify({
      emailMasked: maskEmail(email),
      classification,
      eventCount: sanitized.length,
      latestEvent: sanitized[0] ? sanitized[0].event : null,
    }),
  );

  return {
    ok: true,
    httpStatus: evRes.status,
    emailMasked: maskEmail(email),
    classification,
    events: sanitized.slice(0, 10),
  };
}

module.exports = {
  OTP_LENGTH,
  OTP_EXPIRY_MS,
  RESEND_COOLDOWN_MS,
  MAX_VERIFY_ATTEMPTS,
  PURPOSE,
  COLLECTION,
  normalizeEmail,
  maskEmail,
  generateOtp,
  hashOtp,
  timingSafeEqualHex,
  requestEmailVerificationOtp,
  verifyEmailVerificationOtp,
  getEmailVerificationOtpStatus,
  probeBrevoOtpDeliveryEvents,
  getEmailVerificationMode,
};
