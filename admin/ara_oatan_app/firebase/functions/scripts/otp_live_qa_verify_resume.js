'use strict';

/**
 * Resume verify only — uses private ids + env OTP codes.
 * Never prints OTP codes or passwords.
 *
 *   CP_OTP_CUSTOMER_CODE=...... CP_OTP_DRIVER_CODE=...... \
 *   node scripts/otp_live_qa_verify_resume.js
 */

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || 'tutorial-multi-language-70gx4j';
process.env.GOOGLE_CLOUD_PROJECT = process.env.GCLOUD_PROJECT;

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const PROJECT = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const REGION = 'us-central1';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT});
}

const privatePath = path.resolve(
  __dirname,
  '../../../../../qa_master_audit/email_otp_deploy/live_qa_private_ids.json',
);

async function signInWithPassword(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    },
  );
  const body = await res.json();
  if (!res.ok) {
    throw new Error(`signIn_failed:${JSON.stringify(body).slice(0, 120)}`);
  }
  return body.idToken;
}

async function callVerify(idToken, challengeId, code) {
  const res = await fetch(
    `https://${REGION}-${PROJECT}.cloudfunctions.net/verifyEmailVerificationOtp`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({data: {challengeId, code}}),
    },
  );
  const body = await res.json().catch(() => ({}));
  return {http: res.status, body};
}

function extractError(body) {
  return (
    (body && body.error && (body.error.message || body.error.status)) || null
  );
}

function extractResult(body) {
  if (body && body.result) return body.result;
  if (body && body.data) return body.data;
  return body;
}

async function runRole(role, codeEnv) {
  const priv = JSON.parse(fs.readFileSync(privatePath, 'utf8'));
  const rec = priv[role];
  if (!rec || !rec.uid || !rec.challengeId || !rec.email || !rec.password) {
    return {fatal: 'MISSING_PRIVATE_IDS_OR_PASSWORD'};
  }
  const code = String(process.env[codeEnv] || '').trim();
  const pre = (await admin.auth().getUser(rec.uid)).emailVerified;
  if (!/^\d{6}$/.test(code)) {
    return {ownerAction: `SET_${codeEnv}_AND_RERUN`, preAuth: pre};
  }
  const idToken = await signInWithPassword(rec.email, rec.password);

  // Wrong code first if not yet attempted this resume
  if (process.env.CP_OTP_SKIP_WRONG !== '1') {
    const wrong = await callVerify(idToken, rec.challengeId, '000000');
    const wrongErr = extractError(wrong.body);
    const snap = await admin
      .firestore()
      .collection('email_verification_challenges')
      .doc(rec.challengeId)
      .get();
    const ch = snap.data() || {};
    var wrongMeta = {
      wrongDenied: !!wrongErr && /INVALID_CODE/i.test(String(wrongErr)),
      attemptAfterWrong: ch.attemptCount || 0,
      afterWrongAuth: (await admin.auth().getUser(rec.uid)).emailVerified,
    };
  }

  const ver = await callVerify(idToken, rec.challengeId, code);
  const err = extractError(ver.body);
  const result = extractResult(ver.body) || {};
  const post = (await admin.auth().getUser(rec.uid)).emailVerified;
  return {
    preAuth: pre,
    ...(wrongMeta || {}),
    http: ver.http,
    verifyOk: !err && result.verified === true,
    error: err ? String(err).slice(0, 80) : null,
    postAuth: post,
    alreadyVerified: result.alreadyVerified === true,
  };
}

async function main() {
  const out = {
    CUSTOMER: await runRole('customer', 'CP_OTP_CUSTOMER_CODE'),
    DRIVER: await runRole('driver', 'CP_OTP_DRIVER_CODE'),
  };
  const dir = path.dirname(privatePath);
  fs.writeFileSync(
    path.join(dir, 'live_qa_verify_public.json'),
    JSON.stringify(out, null, 2),
  );
  console.log(JSON.stringify(out, null, 2));
}

main().catch((e) => {
  console.error('FATAL', String(e.message || e));
  process.exit(1);
});
