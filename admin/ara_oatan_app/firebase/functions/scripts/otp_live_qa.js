'use strict';

/**
 * Live OTP QA harness — no OTP printed; codes only via env.
 *
 * Env (optional):
 *   CP_OTP_CUSTOMER_EMAIL / CP_OTP_DRIVER_EMAIL
 *   CP_OTP_CUSTOMER_CODE / CP_OTP_DRIVER_CODE  (never logged)
 *   ADMIN_QA_EMAIL used as plus-address base if CP_* unset
 *   FIREBASE_WEB_API_KEY
 *
 *   GCLOUD_PROJECT=tutorial-multi-language-70gx4j node scripts/otp_live_qa.js
 */

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || 'tutorial-multi-language-70gx4j';
process.env.GOOGLE_CLOUD_PROJECT = process.env.GCLOUD_PROJECT;

const admin = require('firebase-admin');
const crypto = require('crypto');

const PROJECT = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const REGION = 'us-central1';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT});
}

const report = {
  PROJECT,
  UNAUTH_DENIED: 'PASS', // proven separately
  CUSTOMER: {},
  DRIVER: {},
  SECURITY: {},
};

function baseMailbox() {
  return (
    process.env.CP_OTP_CUSTOMER_EMAIL ||
    process.env.OTP_QA_EMAIL ||
    process.env.ADMIN_QA_EMAIL ||
    ''
  );
}

function plusAddress(kind) {
  const explicit =
    kind === 'customer'
      ? process.env.CP_OTP_CUSTOMER_EMAIL
      : process.env.CP_OTP_DRIVER_EMAIL;
  if (explicit) return explicit.trim().toLowerCase();
  const base = baseMailbox().trim().toLowerCase();
  if (!base || !base.includes('@')) {
    throw new Error('NO_QA_MAILBOX');
  }
  const [local, domain] = base.split('@');
  const stamp = Date.now().toString(36);
  // Prefer plus-address so Owner receives in same inbox when supported.
  return `${local}+otp.${kind}.${stamp}@${domain}`;
}

async function identitySignUp(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    },
  );
  const body = await res.json();
  return {ok: res.ok, body};
}

async function callCallable(name, idToken, data) {
  const res = await fetch(
    `https://${REGION}-${PROJECT}.cloudfunctions.net/${name}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({data: data || {}}),
    },
  );
  const body = await res.json().catch(() => ({}));
  return {http: res.status, body};
}

function extractError(body) {
  return (
    (body && body.error && (body.error.message || body.error.status)) ||
    (body && body.result && body.result.error) ||
    null
  );
}

function extractResult(body) {
  if (body && body.result) return body.result;
  if (body && body.data) return body.data;
  return body;
}

async function authEmailVerified(uid) {
  const u = await admin.auth().getUser(uid);
  return u.emailVerified === true;
}

async function challengeExists(challengeId) {
  if (!challengeId) return false;
  const snap = await admin
    .firestore()
    .collection('email_verification_challenges')
    .doc(challengeId)
    .get();
  if (!snap.exists) return false;
  const d = snap.data() || {};
  return {
    exists: true,
    hasHash: typeof d.otpHash === 'string' && d.otpHash.length === 64,
    hasPlainOtp: Object.prototype.hasOwnProperty.call(d, 'otp'),
    purpose: d.purpose,
    attemptCount: d.attemptCount || 0,
  };
}

async function runRole(kind) {
  const out = {};
  const email = plusAddress(kind);
  const password = `OtpQa!${crypto.randomBytes(8).toString('hex')}Aa1`;
  out.emailDomain = email.split('@')[1];
  out.emailLocalPrefix = email.split('@')[0].slice(0, 12);

  const signup = await identitySignUp(email, password);
  if (!signup.ok) {
    out.signup = 'FAIL';
    out.signupError = JSON.stringify(signup.body).slice(0, 160);
    return out;
  }
  const uid = signup.body.localId;
  const idToken = signup.body.idToken;
  out.uidPrefix = String(uid).slice(0, 8);
  out.signup = 'PASS';

  await admin.firestore().doc(`user/${uid}`).set(
    {
      email,
      functional_test: true,
      qa_purpose: 'EMAIL_OTP_LIVE_QA',
      display_name: `OTP QA ${kind}`,
      created_time: admin.firestore.FieldValue.serverTimestamp(),
      ...(kind === 'customer'
        ? {actev_user: true}
        : {ismndob: true, actev_mndob: false, registration_flow_version: 2}),
    },
    {merge: true},
  );

  out.preVerifyAuth = await authEmailVerified(uid);

  const req = await callCallable('requestEmailVerificationOtp', idToken, {
    locale: 'en',
  });
  const reqErr = extractError(req.body);
  const reqRes = extractResult(req.body) || {};
  out.requestHttp = req.http;
  out.requestOk = !reqErr && reqRes.ok === true;
  out.challengeIdPresent = typeof reqRes.challengeId === 'string';
  out.otpReturnedToClient = JSON.stringify(reqRes).includes('"otp"');
  out.requestError = reqErr ? String(reqErr).slice(0, 80) : null;
  out.challengeId = reqRes.challengeId || null;

  if (out.challengeId) {
    out.challengeMeta = await challengeExists(out.challengeId);
    out.plainOtpStored = out.challengeMeta.hasPlainOtp === true;
  }

  // Wrong OTP
  const wrong = await callCallable('verifyEmailVerificationOtp', idToken, {
    challengeId: out.challengeId,
    code: '000000',
  });
  const wrongErr = extractError(wrong.body);
  out.wrongDenied =
    !!wrongErr && /INVALID_CODE/i.test(String(wrongErr));
  out.afterWrongAuth = await authEmailVerified(uid);
  if (out.challengeId) {
    const meta2 = await challengeExists(out.challengeId);
    out.attemptAfterWrong = meta2.attemptCount;
  }

  const codeEnv =
    kind === 'customer'
      ? process.env.CP_OTP_CUSTOMER_CODE
      : process.env.CP_OTP_DRIVER_CODE;
  if (codeEnv && /^\d{6}$/.test(String(codeEnv).trim())) {
    const ok = await callCallable('verifyEmailVerificationOtp', idToken, {
      challengeId: out.challengeId,
      code: String(codeEnv).trim(),
    });
    const okErr = extractError(ok.body);
    const okRes = extractResult(ok.body) || {};
    out.correctVerifyOk = !okErr && okRes.verified === true;
    out.correctVerifyError = okErr ? String(okErr).slice(0, 80) : null;
    out.postVerifyAuth = await authEmailVerified(uid);
    // clear env usage marker only
    out.correctCodeSource = 'ENV';
  } else {
    out.correctVerifyOk = null;
    out.postVerifyAuth = await authEmailVerified(uid);
    out.ownerAction = 'ENTER_6_DIGIT_OTP_VIA_ENV_AND_RERUN';
  }

  out.uid = uid; // needed for resume — keep in private evidence file only
  out.email = email;
  out.password = password;
  out.idToken = idToken;
  out.challengeId = out.challengeId;
  return out;
}

async function main() {
  try {
    report.CUSTOMER = await runRole('customer');
  } catch (e) {
    report.CUSTOMER = {fatal: String(e.message || e)};
  }
  try {
    report.DRIVER = await runRole('driver');
  } catch (e) {
    report.DRIVER = {fatal: String(e.message || e)};
  }

  // Public summary without emails/tokens/codes
  const pub = {
    CUSTOMER: {
      signup: report.CUSTOMER.signup,
      preVerifyAuth: report.CUSTOMER.preVerifyAuth,
      requestOk: report.CUSTOMER.requestOk,
      challengeIdPresent: report.CUSTOMER.challengeIdPresent,
      otpReturnedToClient: report.CUSTOMER.otpReturnedToClient,
      plainOtpStored: report.CUSTOMER.plainOtpStored,
      challengeHasHash: report.CUSTOMER.challengeMeta && report.CUSTOMER.challengeMeta.hasHash,
      wrongDenied: report.CUSTOMER.wrongDenied,
      afterWrongAuth: report.CUSTOMER.afterWrongAuth,
      attemptAfterWrong: report.CUSTOMER.attemptAfterWrong,
      correctVerifyOk: report.CUSTOMER.correctVerifyOk,
      postVerifyAuth: report.CUSTOMER.postVerifyAuth,
      ownerAction: report.CUSTOMER.ownerAction,
      requestError: report.CUSTOMER.requestError,
      emailDomain: report.CUSTOMER.emailDomain,
    },
    DRIVER: {
      signup: report.DRIVER.signup,
      preVerifyAuth: report.DRIVER.preVerifyAuth,
      requestOk: report.DRIVER.requestOk,
      challengeIdPresent: report.DRIVER.challengeIdPresent,
      otpReturnedToClient: report.DRIVER.otpReturnedToClient,
      plainOtpStored: report.DRIVER.plainOtpStored,
      challengeHasHash: report.DRIVER.challengeMeta && report.DRIVER.challengeMeta.hasHash,
      wrongDenied: report.DRIVER.wrongDenied,
      afterWrongAuth: report.DRIVER.afterWrongAuth,
      correctVerifyOk: report.DRIVER.correctVerifyOk,
      postVerifyAuth: report.DRIVER.postVerifyAuth,
      ownerAction: report.DRIVER.ownerAction,
      requestError: report.DRIVER.requestError,
      emailDomain: report.DRIVER.emailDomain,
    },
  };

  const fs = require('fs');
  const path = require('path');
  const outDir = path.resolve(
    __dirname,
    '../../../../../qa_master_audit/email_otp_deploy',
  );
  fs.mkdirSync(outDir, {recursive: true});
  // Private resume file (gitignored ideally) — still avoid writing OTP codes
  // Local-only resume ids (qa_master_audit/ is gitignored). Includes
  // ephemeral password for Identity Toolkit sign-in — never commit.
  const privateSafe = {
    customer: {
      uid: report.CUSTOMER.uid,
      email: report.CUSTOMER.email,
      challengeId: report.CUSTOMER.challengeId,
      password: report.CUSTOMER.password || null,
    },
    driver: {
      uid: report.DRIVER.uid,
      email: report.DRIVER.email,
      challengeId: report.DRIVER.challengeId,
      password: report.DRIVER.password || null,
    },
  };
  fs.writeFileSync(
    path.join(outDir, 'live_qa_public.json'),
    JSON.stringify(pub, null, 2),
  );
  fs.writeFileSync(
    path.join(outDir, 'live_qa_private_ids.json'),
    JSON.stringify(privateSafe, null, 2),
  );
  console.log(JSON.stringify(pub, null, 2));
  console.log('WROTE', path.join(outDir, 'live_qa_public.json'));
}

main().catch((e) => {
  console.error('FATAL', String(e && e.message ? e.message : e));
  process.exit(1);
});
