/**
 * CP8A — Firebase Auth email delivery reproduce (no secrets in output).
 *
 * Env:
 *   CP8A_QA_EMAIL          required for Owner mailbox test
 *   CP8A_QA_EMAIL_B        optional second provider
 *   CP8A_QA_PASSWORD       optional (auto-generated if unset)
 *
 * Never prints full email addresses. Writes fingerprint-only evidence under
 * qa_master_audit/checkpoint_8a/
 */
'use strict';

process.env.GCLOUD_PROJECT = 'tutorial-multi-language-70gx4j';
process.env.GOOGLE_CLOUD_QUOTA_PROJECT = 'tutorial-multi-language-70gx4j';

const admin = require('firebase-admin');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PROJECT = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const OUT = path.join(
  '/Users/ventura/ara-ban/qa_master_audit/checkpoint_8a',
  'owner_mailbox_runs',
);

function fp(email) {
  return crypto
    .createHash('sha256')
    .update(String(email).toLowerCase())
    .digest('hex')
    .slice(0, 12);
}

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT});
}

async function signUp(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    },
  );
  return {ok: res.ok, status: res.status, body: await res.json(), ts: new Date().toISOString()};
}

async function sendVerify(idToken) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({requestType: 'VERIFY_EMAIL', idToken}),
    },
  );
  return {ok: res.ok, status: res.status, body: await res.json(), ts: new Date().toISOString()};
}

async function sendReset(email) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({requestType: 'PASSWORD_RESET', email}),
    },
  );
  return {ok: res.ok, status: res.status, body: await res.json(), ts: new Date().toISOString()};
}

async function runOne(label, email) {
  const password =
    process.env.CP8A_QA_PASSWORD || `Cp8a!${crypto.randomBytes(6).toString('hex')}`;
  const report = {label, email_fp: fp(email), timestamp: new Date().toISOString()};
  const signup = await signUp(email, password);
  report.SIGNUP = {
    SDK_RESULT: signup.ok ? 'success' : 'fail',
    status: signup.status,
    errorCode: signup.body?.error?.message || null,
    timestamp: signup.ts,
  };
  if (!signup.ok) return report;

  const uid = signup.body.localId;
  await admin.firestore().collection('user').doc(uid).set(
    {
      uid,
      email,
      display_name: 'CP8A Email QA',
      Clients: true,
      Drever: false,
      functional_test: true,
      qa_purpose: 'EMAIL_DELIVERY_CP8A',
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  const verify = await sendVerify(signup.body.idToken);
  report.VERIFICATION_SEND = {
    SDK_RESULT: verify.ok ? 'success' : 'fail',
    Firebase_errorCode: verify.body?.error?.message || null,
    timestamp: verify.ts,
  };

  const reset = await sendReset(email);
  report.PASSWORD_RESET_SEND = {
    PASSWORD_RESET_SDK_RESULT: reset.ok ? 'success' : 'fail',
    errorCode: reset.body?.error?.message || null,
    timestamp: reset.ts,
  };

  report.OWNER_INBOX_CHECK_REQUIRED = true;
  report.uid_prefix = String(uid).slice(0, 6);
  return report;
}

(async () => {
  fs.mkdirSync(OUT, {recursive: true});
  const a = String(process.env.CP8A_QA_EMAIL || '').trim();
  const b = String(process.env.CP8A_QA_EMAIL_B || '').trim();
  if (!a) {
    console.log(
      JSON.stringify(
        {
          RESULT: 'OWNER_ACTION_REQUIRED',
          NEED: 'CP8A_QA_EMAIL',
          OPTIONAL: 'CP8A_QA_EMAIL_B',
        },
        null,
        2,
      ),
    );
    process.exit(2);
  }
  const results = {PROVIDER_A: await runOne('PROVIDER_A', a)};
  if (b) results.PROVIDER_B = await runOne('PROVIDER_B', b);
  const file = path.join(OUT, `run_${Date.now()}.json`);
  fs.writeFileSync(file, JSON.stringify(results, null, 2));
  console.log(JSON.stringify({written: file, ...results}, null, 2));
})().catch((e) => {
  console.error(String(e.stack || e));
  process.exit(1);
});
