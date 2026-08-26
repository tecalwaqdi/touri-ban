'use strict';

/**
 * Delivery-only check — no verify, never prints OTP / secrets.
 *
 * Uses exact ADMIN_QA_EMAIL for Customer (no plus-alias).
 * Driver uses CP_OTP_DRIVER_EMAIL if set, else ADMIN_QA_EMAIL with a
 * distinct Auth user is impossible on same email — falls back to documenting
 * plus-alias risk OR a second env mailbox.
 */

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || 'tutorial-multi-language-70gx4j';
process.env.GOOGLE_CLOUD_PROJECT = process.env.GCLOUD_PROJECT;

const admin = require('firebase-admin');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PROJECT = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const REGION = 'us-central1';
const OUT_DIR = path.resolve(
  __dirname,
  '../../../../../qa_master_audit/email_otp_deploy',
);

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT});
}

function mask(email) {
  const e = String(email || '').toLowerCase();
  const at = e.indexOf('@');
  if (at < 1) return '***';
  return `${e.slice(0, 2)}***@${e.slice(at + 1)}`;
}

async function signIn(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    },
  );
  const body = await res.json();
  if (!res.ok) throw new Error(`signin:${JSON.stringify(body).slice(0, 100)}`);
  return body.idToken;
}

async function ensurePassword(uid) {
  const password = `DelivQa!${crypto.randomBytes(8).toString('hex')}Aa1`;
  await admin.auth().updateUser(uid, {password});
  return password;
}

async function callRequest(idToken) {
  const res = await fetch(
    `https://${REGION}-${PROJECT}.cloudfunctions.net/requestEmailVerificationOtp`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({data: {locale: 'en'}}),
    },
  );
  const body = await res.json().catch(() => ({}));
  return {http: res.status, body};
}

function extractError(body) {
  return (body && body.error && body.error.message) || null;
}

function extractResult(body) {
  return (body && (body.result || body.data)) || {};
}

async function prepareCustomer() {
  const email = String(process.env.ADMIN_QA_EMAIL || '').trim().toLowerCase();
  if (!email || !email.includes('@')) throw new Error('ADMIN_QA_EMAIL_MISSING');
  if (/\.invalid$/i.test(email)) throw new Error('INVALID_TLD');
  const user = await admin.auth().getUserByEmail(email);
  const password = await ensurePassword(user.uid);
  await admin.firestore().doc(`user/${user.uid}`).set(
    {
      email,
      functional_test: true,
      qa_purpose: 'EMAIL_OTP_DELIVERY_CHECK',
      actev_user: true,
    },
    {merge: true},
  );
  return {
    role: 'customer',
    uid: user.uid,
    email,
    password,
    emailVerified: user.emailVerified === true,
  };
}

async function prepareDriver() {
  const explicit = String(process.env.CP_OTP_DRIVER_EMAIL || '').trim().toLowerCase();
  const base = String(process.env.ADMIN_QA_EMAIL || '').trim().toLowerCase();
  // Prefer distinct Owner mailbox; otherwise create plus-alias (delivery risk flagged).
  let email = explicit;
  let usedPlusAlias = false;
  if (!email) {
    if (!base) throw new Error('NO_DRIVER_MAILBOX');
    const [local, domain] = base.split('@');
    email = `${local}+otp.driver.delivery@${domain}`;
    usedPlusAlias = true;
  }
  if (/\.invalid$/i.test(email)) throw new Error('INVALID_TLD');

  let uid;
  let password;
  try {
    const existing = await admin.auth().getUserByEmail(email);
    uid = existing.uid;
    password = await ensurePassword(uid);
    var emailVerified = existing.emailVerified === true;
  } catch (_) {
    password = `DelivQa!${crypto.randomBytes(8).toString('hex')}Aa1`;
    const created = await admin.auth().createUser({
      email,
      password,
      emailVerified: false,
    });
    uid = created.uid;
    emailVerified = false;
  }
  await admin.firestore().doc(`user/${uid}`).set(
    {
      email,
      functional_test: true,
      qa_purpose: 'EMAIL_OTP_DELIVERY_CHECK',
      ismndob: true,
      actev_mndob: false,
      registration_flow_version: 2,
    },
    {merge: true},
  );
  return {
    role: 'driver',
    uid,
    email,
    password,
    emailVerified,
    usedPlusAlias,
  };
}

async function runRole(prep) {
  if (prep.emailVerified) {
    return {
      role: prep.role,
      emailMasked: mask(prep.email),
      authExists: true,
      emailVerified: true,
      usedPlusAlias: !!prep.usedPlusAlias,
      request: 'SKIPPED_ALREADY_VERIFIED',
      note: 'Would not send OTP',
    };
  }
  const idToken = await signIn(prep.email, prep.password);
  const {http, body} = await callRequest(idToken);
  const err = extractError(body);
  const result = extractResult(body);
  const otpReturned =
    JSON.stringify(result).includes('"otp"') ||
    JSON.stringify(result).includes('"code"');

  // Challenge meta
  let challengeMeta = null;
  if (result.challengeId) {
    const snap = await admin
      .firestore()
      .collection('email_verification_challenges')
      .doc(result.challengeId)
      .get();
    const d = snap.data() || {};
    challengeMeta = {
      exists: snap.exists,
      hasHash: typeof d.otpHash === 'string' && d.otpHash.length === 64,
      hasPlainOtp: Object.prototype.hasOwnProperty.call(d, 'otp'),
    };
  }

  return {
    role: prep.role,
    emailMasked: mask(prep.email),
    domain: prep.email.split('@')[1],
    authExists: true,
    emailVerified: false,
    usedPlusAlias: !!prep.usedPlusAlias,
    http,
    functionError: err ? String(err).slice(0, 80) : null,
    requestOk: !err && result.ok === true,
    challengeIdPresent: typeof result.challengeId === 'string',
    challengeIdPrefix: result.challengeId
      ? String(result.challengeId).slice(0, 8)
      : null,
    cooldownSeconds: result.resendCooldownSec ?? null,
    expiresInSec: result.expiresInSec ?? null,
    otpReturnedToClient: otpReturned,
    alreadyVerified: result.alreadyVerified === true,
    challengeMeta,
    // private fields written separately
    _uid: prep.uid,
    _email: prep.email,
    _password: prep.password,
    _challengeId: result.challengeId || null,
  };
}

async function main() {
  fs.mkdirSync(OUT_DIR, {recursive: true});
  const customerPrep = await prepareCustomer();
  const driverPrep = await prepareDriver();
  const customer = await runRole(customerPrep);
  // Driver may hit Brevo rate / need slight delay
  await new Promise((r) => setTimeout(r, 1500));
  const driver = await runRole(driverPrep);

  const pub = {
    CUSTOMER: Object.fromEntries(
      Object.entries(customer).filter(([k]) => !k.startsWith('_')),
    ),
    DRIVER: Object.fromEntries(
      Object.entries(driver).filter(([k]) => !k.startsWith('_')),
    ),
  };
  fs.writeFileSync(
    path.join(OUT_DIR, 'delivery_check_request.json'),
    JSON.stringify(pub, null, 2),
  );
  fs.writeFileSync(
    path.join(OUT_DIR, 'delivery_check_private.json'),
    JSON.stringify(
      {
        customer: {
          uid: customer._uid,
          email: customer._email,
          password: customer._password,
          challengeId: customer._challengeId,
        },
        driver: {
          uid: driver._uid,
          email: driver._email,
          password: driver._password,
          challengeId: driver._challengeId,
        },
      },
      null,
      2,
    ),
  );
  console.log(JSON.stringify(pub, null, 2));
}

main().catch((e) => {
  console.error('FATAL', String(e.message || e));
  process.exit(1);
});
