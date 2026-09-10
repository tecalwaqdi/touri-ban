#!/usr/bin/env node
/**
 * Provision a handover Accountant (isAdminRule=5 → finance claim only).
 *
 * Does NOT enable finance write flags. Credentials are printed once — do not
 * commit them to git.
 *
 * Usage:
 *   cd admin/Admi/firebase/functions
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/sa.json \
 *   ACCOUNTANT_EMAIL=accountant@example.com \
 *   ACCOUNTANT_PASSWORD='StrongTempPass!' \
 *   ACCOUNTANT_NAME='محاسب التسليم' \
 *     node ../scripts/provision_handover_accountant.js [--dry-run]
 */
'use strict';

const path = require('path');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
const {deriveClaimsFromUserData} = require('../functions/auth_claims_derive.js');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const DRY_RUN = process.argv.includes('--dry-run');
const EMAIL = (process.env.ACCOUNTANT_EMAIL || '').trim().toLowerCase();
const PASSWORD = process.env.ACCOUNTANT_PASSWORD || '';
const DISPLAY_NAME = process.env.ACCOUNTANT_NAME || 'Accountant';
const PHONE = process.env.ACCOUNTANT_PHONE || '';

function initAdmin() {
  if (admin.apps.length) return;
  const sa =
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    path.join(process.env.HOME, 'Downloads/tutorial-multi-language-70gx4j-fb851be1eb3e.json');
  admin.initializeApp({
    credential: admin.credential.cert(require(sa)),
    projectId: PROJECT_ID,
  });
}

async function getUserByEmail(auth, email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === 'auth/user-not-found') return null;
    throw e;
  }
}

async function main() {
  if (!EMAIL || !EMAIL.includes('@')) {
    console.error('Set ACCOUNTANT_EMAIL');
    process.exit(2);
  }
  if (PASSWORD.length < 8) {
    console.error('Set ACCOUNTANT_PASSWORD (min 8 chars)');
    process.exit(2);
  }

  initAdmin();
  const auth = admin.auth();
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const userDoc = {
    email: EMAIL,
    display_name: DISPLAY_NAME,
    phone_number: PHONE,
    actev_user: true,
    IsAdmin: false,
    isAdmin: false,
    isAdminRule: 5,
    panel_role: 'accountant',
    created_time: now,
    updated_at: now,
  };

  const claims = deriveClaimsFromUserData(userDoc);
  if (claims.finance !== true || claims.super_admin) {
    console.error('Claim derivation failed for accountant', claims);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log(JSON.stringify({dryRun: true, email: EMAIL, claims, userDoc}, null, 2));
    return;
  }

  let uid;
  const existing = await getUserByEmail(auth, EMAIL);
  if (existing) {
    uid = existing.uid;
    await auth.updateUser(uid, {
      password: PASSWORD,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      disabled: false,
    });
  } else {
    const created = await auth.createUser({
      email: EMAIL,
      password: PASSWORD,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      disabled: false,
    });
    uid = created.uid;
  }

  userDoc.uid = uid;
  await db.collection('user').doc(uid).set(userDoc, {merge: true});
  await auth.setCustomUserClaims(uid, claims);

  console.log(
    JSON.stringify(
      {
        ok: true,
        uid,
        email: EMAIL,
        displayName: DISPLAY_NAME,
        claims,
        homeRoute: 'AdminFinanceHub',
        note: 'Deliver password out-of-band. Finance write flags remain OFF.',
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
