'use strict';

/**
 * STAGE 1A smoke — test accounts only.
 * Creates ephemeral Auth+Firestore users with clear test prefix, invokes callables,
 * verifies financial freeze, then cleans leftovers.
 *
 * Usage:
 *   cd admin/Admi/firebase/functions && node scripts/account_deletion_stage1a_smoke.js
 */

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'tutorial-multi-language-70gx4j',
    storageBucket: 'tutorial-multi-language-70gx4j.firebasestorage.app',
  });
}

const db = admin.firestore();
const auth = admin.auth();
const PROJECT = 'tutorial-multi-language-70gx4j';
const REGION = 'us-central1';
const RUN_ID = `stg1a_${Date.now()}`;

function deepClone(v) {
  return JSON.parse(JSON.stringify(v));
}

function assertEqual(label, a, b) {
  const sa = JSON.stringify(a);
  const sb = JSON.stringify(b);
  if (sa !== sb) {
    throw new Error(`${label} CHANGED\n before=${sa}\n after=${sb}`);
  }
}

/** Fields account-deletion must never touch (ignore unrelated order triggers). */
function financialOrderSlice(data) {
  if (!data) return data;
  return {
    total: data.total,
    total_app: data.total_app,
    total_mndob: data.total_mndob,
    ActiveOrder: data.ActiveOrder,
    naim_user_text: data.naim_user_text,
    phone_numper: data.phone_numper,
    naim_mndob_text: data.naim_mndob_text,
    phone_nu_mndob: data.phone_nu_mndob,
    _test_marker: data._test_marker,
  };
}

function assertFinancialFreeze(label, before, after) {
  assertEqual(`${label}.order`, financialOrderSlice(before.order), financialOrderSlice(after.order));
  assertEqual(`${label}.wallet`, before.wallet, after.wallet);
  if ('tx' in before) assertEqual(`${label}.tx`, before.tx, after.tx);
  if ('pay' in before) assertEqual(`${label}.pay`, before.pay, after.pay);
  if ('settlement' in before) {
    assertEqual(`${label}.settlement`, before.settlement, after.settlement);
  }
}

function loadWebApiKey() {
  if (process.env.FIREBASE_WEB_API_KEY) return process.env.FIREBASE_WEB_API_KEY;
  const fs = require('fs');
  const path = require('path');
  const gs = JSON.parse(
    fs.readFileSync(
      path.resolve(
        __dirname,
        '../../../../ara_oatan_app/android/app/google-services.json',
      ),
      'utf8',
    ),
  );
  const key = gs.client?.[0]?.api_key?.[0]?.current_key;
  if (!key) throw new Error('FIREBASE_WEB_API_KEY missing');
  return key;
}

/** Email/password sign-in — avoids createCustomToken (ADC quota-project issues). */
async function getIdTokenForEmailPassword(email, password) {
  const apiKey = loadWebApiKey();
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    },
  );
  const json = await res.json();
  if (!res.ok || !json.idToken) {
    throw new Error(`idToken exchange failed: ${JSON.stringify(json)}`);
  }
  return json.idToken;
}

async function callCallable(name, data, idToken) {
  const url = `https://${REGION}-${PROJECT}.cloudfunctions.net/${name}`;
  const headers = {'Content-Type': 'application/json'};
  if (idToken) headers.Authorization = `Bearer ${idToken}`;
  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({data: data || {}}),
  });
  const json = await res.json().catch(() => ({}));
  return {status: res.status, json};
}

async function createTestCustomer() {
  const email = `del.test.customer.${RUN_ID}@touri-taxi-test.local`;
  const password = `TestDel!${Date.now()}`;
  const user = await auth.createUser({
    email,
    password,
    displayName: 'STG1A Customer',
    emailVerified: true,
  });
  const uid = user.uid;
  const uref = db.doc(`user/${uid}`);
  await uref.set({
    email,
    display_name: 'STG1A Customer',
    phone_number: '966500000001',
    uid,
    ismndob: false,
    actev_user: true,
    created_time: admin.firestore.FieldValue.serverTimestamp(),
    fcm_token: 'test-fcm-token',
    _test_marker: RUN_ID,
  });
  await uref.collection('fcm_tokens').doc('t1').set({
    fcm_token: 'test-fcm-token',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection('ADRESSUSER').add({
    USER: uref,
    TILET: 'home',
    textfullAdress: 'test address',
    _test_marker: RUN_ID,
  });
  // Historical financial-like order — MUST remain unchanged
  const orderRef = await db.collection('order').add({
    USER: uref,
    naim_user_text: 'STG1A Customer',
    phone_numper: 966500000001,
    total: 99.25,
    total_app: 9.25,
    total_mndob: 90,
    ActiveOrder: false,
    halh_order: 'Completed',
    _test_marker: RUN_ID,
  });
  const walletRef = await db.collection('wallets').add({
    userRef: uref,
    currentBalance: 0,
    isActive: true,
    currency: 'SAR',
    _test_marker: RUN_ID,
  });
  const txRef = await db.collection('transactions').add({
    userRef: uref,
    amount: 10,
    status: 'completed',
    _test_marker: RUN_ID,
  });
  const payHistRef = await db.collection('Paymenthistory').add({
    userRev: uref,
    amount: 99.25,
    status: 'Paid',
    _test_marker: RUN_ID,
  });

  return {uid, email, password, uref, orderRef, walletRef, txRef, payHistRef};
}

async function createTestDriver({withActiveTrip = false, withSettlement = false, withBalance = false} = {}) {
  const email = `del.test.driver.${RUN_ID}.${Math.random().toString(36).slice(2, 7)}@touri-taxi-test.local`;
  const password = `TestDel!${Date.now()}`;
  const user = await auth.createUser({
    email,
    password,
    displayName: 'STG1A Driver',
    emailVerified: true,
  });
  const uid = user.uid;
  const uref = db.doc(`user/${uid}`);
  await uref.set({
    email,
    display_name: 'STG1A Driver',
    phone_number: '966500000002',
    uid,
    ismndob: true,
    actev_mndob: true,
    ngl: false,
    created_time: admin.firestore.FieldValue.serverTimestamp(),
    _test_marker: RUN_ID,
  });

  let orderRef = null;
  if (withActiveTrip) {
    orderRef = await db.collection('order').add({
      mndob_user: uref,
      naim_mndob_text: 'STG1A Driver',
      phone_nu_mndob: 966500000002,
      total: 55,
      ActiveOrder: true,
      halh_text: 'مقبول',
      _test_marker: RUN_ID,
    });
  } else {
    orderRef = await db.collection('order').add({
      mndob_user: uref,
      naim_mndob_text: 'STG1A Driver',
      phone_nu_mndob: 966500000002,
      total: 55,
      ActiveOrder: false,
      halh_text: 'مكتمل',
      _test_marker: RUN_ID,
    });
  }

  let settlementRef = null;
  if (withSettlement) {
    settlementRef = await db.collection('financial_settlements').add({
      driverId: uid,
      status: 'locked',
      _test_marker: RUN_ID,
    });
  }

  const walletRef = await db.collection('wallets').add({
    userRef: uref,
    currentBalance: withBalance ? 25.5 : 0,
    isActive: true,
    currency: 'SAR',
    _test_marker: RUN_ID,
  });

  return {uid, email, password, uref, orderRef, settlementRef, walletRef};
}

async function snapshotDocs(refs) {
  const out = {};
  for (const [k, ref] of Object.entries(refs)) {
    if (!ref) continue;
    const snap = await ref.get();
    out[k] = snap.exists ? snap.data() : null;
  }
  return deepClone(out);
}

async function cleanupMarker(marker) {
  const cols = [
    'order',
    'wallets',
    'transactions',
    'Paymenthistory',
    'financial_settlements',
    'ADRESSUSER',
    'account_deletion_requests',
  ];
  for (const col of cols) {
    const snap = await db.collection(col).where('_test_marker', '==', marker).get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    if (!snap.empty) await batch.commit();
  }
}

async function main() {
  const report = {ok: true, steps: []};
  const mark = (name, ok, detail) => {
    report.steps.push({name, ok, detail});
    console.log(`${ok ? 'PASS' : 'FAIL'} ${name}`, detail || '');
    if (!ok) report.ok = false;
  };

  // 1) Unauthenticated rejected
  {
    const r = await callCallable('requestAccountDeletion', {confirm: true}, null);
    const err = r.json.error || {};
    const rejected =
      r.status >= 400 ||
      err.status === 'UNAUTHENTICATED' ||
      (err.message || '').toLowerCase().includes('sign in') ||
      (err.message || '').toLowerCase().includes('unauth');
    mark('unauthenticated_rejected', rejected, {status: r.status, error: err});
  }

  // 2) Customer happy path + financial freeze
  let customer;
  try {
    customer = await createTestCustomer();
    const before = await snapshotDocs({
      order: customer.orderRef,
      wallet: customer.walletRef,
      tx: customer.txRef,
      pay: customer.payHistRef,
    });

    // spoof other uid should fail
    const idToken = await getIdTokenForEmailPassword(customer.email, customer.password);
    const spoof = await callCallable(
      'requestAccountDeletion',
      {confirm: true, uid: 'someone-else'},
      idToken,
    );
    const spoofErr = spoof.json.error || {};
    const spoofBlocked =
      spoof.status >= 400 ||
      (spoofErr.message || '').includes('another') ||
      spoofErr.status === 'PERMISSION_DENIED' ||
      (spoofErr.details && spoofErr.details.code === 'permission-denied');
    mark('uid_spoof_rejected', spoofBlocked, {status: spoof.status, error: spoofErr});

    const del = await callCallable(
      'requestAccountDeletion',
      {confirm: true},
      idToken,
    );
    const delOk = del.status === 200 && del.json.result && del.json.result.ok === true;
    mark('customer_delete_callable', delOk, {status: del.status, body: del.json});

    // Auth gone
    let authGone = false;
    try {
      await auth.getUser(customer.uid);
    } catch (e) {
      authGone = e.code === 'auth/user-not-found';
    }
    mark('customer_auth_deleted', authGone);

    // Profile gone or redacted (race with onUserDeleted may leave brief tombstone)
    const userSnap = await db.doc(`user/${customer.uid}`).get();
    const ud = userSnap.exists ? userSnap.data() || {} : {};
    const profileClean =
      !userSnap.exists ||
      ud.account_deleted === true ||
      ['completed', 'cleanup_complete'].includes(
        (ud.accountDeletion && ud.accountDeletion.status) || '',
      );
    mark('customer_profile_cleaned', profileClean, {
      exists: userSnap.exists,
      account_deleted: ud.account_deleted || null,
      accountDeletion: ud.accountDeletion || null,
    });
    // Brief wait + re-check: safety-net should not leave PII profile forever.
    if (userSnap.exists) {
      await new Promise((r) => setTimeout(r, 2500));
      const again = await db.doc(`user/${customer.uid}`).get();
      mark(
        'customer_profile_absent_or_tombstone',
        !again.exists ||
          (again.data() || {}).account_deleted === true ||
          !((again.data() || {}).email || (again.data() || {}).phone_number),
        {exists: again.exists, data: again.exists ? again.data() : null},
      );
    } else {
      mark('customer_profile_absent_or_tombstone', true);
    }

    // FCM subcollection empty
    const tokens = await db
      .collection('user')
      .doc(customer.uid)
      .collection('fcm_tokens')
      .get();
    mark('customer_fcm_cleaned', tokens.empty, {count: tokens.size});

    // Addresses cleaned
    const addrs = await db
      .collection('ADRESSUSER')
      .where('_test_marker', '==', RUN_ID)
      .get();
    mark('customer_addresses_cleaned', addrs.empty, {count: addrs.size});

    const after = await snapshotDocs({
      order: customer.orderRef,
      wallet: customer.walletRef,
      tx: customer.txRef,
      pay: customer.payHistRef,
    });
    try {
      assertFinancialFreeze('customer', before, after);
      mark('customer_financial_freeze', true);
    } catch (e) {
      mark('customer_financial_freeze', false, e.message);
    }
  } catch (e) {
    mark('customer_flow', false, e.message);
  }

  // 3) Driver blockers
  try {
    const active = await createTestDriver({withActiveTrip: true});
    const token = await getIdTokenForEmailPassword(active.email, active.password);
    const beforeOrder = (await active.orderRef.get()).data();
    const beforeWallet = (await active.walletRef.get()).data();
    const r = await callCallable('requestAccountDeletion', {confirm: true}, token);
    const err = r.json.error || {};
    const blocked =
      (err.message || '').includes('ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP') ||
      (err.details && err.details.code === 'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP');
    mark('driver_block_active_trip', blocked, {status: r.status, error: err});
    const afterOrder = (await active.orderRef.get()).data();
    const afterWallet = (await active.walletRef.get()).data();
    assertEqual(
      'driver_active_order',
      financialOrderSlice(beforeOrder),
      financialOrderSlice(afterOrder),
    );
    assertEqual('driver_active_wallet', beforeWallet, afterWallet);
    mark('driver_active_no_mutation', true);
    // cleanup auth user (deletion blocked so still exists)
    await auth.deleteUser(active.uid).catch(() => {});
    await db.doc(`user/${active.uid}`).delete().catch(() => {});
  } catch (e) {
    mark('driver_block_active_trip', false, e.message);
  }

  try {
    const pend = await createTestDriver({withSettlement: true});
    const token = await getIdTokenForEmailPassword(pend.email, pend.password);
    const beforeSettlement = (await pend.settlementRef.get()).data();
    const beforeOrder = (await pend.orderRef.get()).data();
    const beforeWallet = (await pend.walletRef.get()).data();
    const r = await callCallable('requestAccountDeletion', {confirm: true}, token);
    const err = r.json.error || {};
    const blocked =
      (err.message || '').includes('ACCOUNT_DELETION_BLOCKED_PENDING_SETTLEMENT') ||
      (err.details &&
        err.details.code === 'ACCOUNT_DELETION_BLOCKED_PENDING_SETTLEMENT');
    mark('driver_block_pending_settlement', blocked, {status: r.status, error: err});
    assertEqual('settlement', beforeSettlement, (await pend.settlementRef.get()).data());
    assertEqual(
      'order',
      financialOrderSlice(beforeOrder),
      financialOrderSlice((await pend.orderRef.get()).data()),
    );
    assertEqual('wallet', beforeWallet, (await pend.walletRef.get()).data());
    mark('driver_settlement_no_mutation', true);
    await auth.deleteUser(pend.uid).catch(() => {});
    await db.doc(`user/${pend.uid}`).delete().catch(() => {});
  } catch (e) {
    mark('driver_block_pending_settlement', false, e.message);
  }

  try {
    const bal = await createTestDriver({withBalance: true});
    const token = await getIdTokenForEmailPassword(bal.email, bal.password);
    const beforeWallet = (await bal.walletRef.get()).data();
    const beforeOrder = (await bal.orderRef.get()).data();
    const r = await callCallable('requestAccountDeletion', {confirm: true}, token);
    const err = r.json.error || {};
    const blocked =
      (err.message || '').includes('ACCOUNT_DELETION_BLOCKED_WALLET_BALANCE') ||
      (err.details && err.details.code === 'ACCOUNT_DELETION_BLOCKED_WALLET_BALANCE');
    mark('driver_block_wallet_balance', blocked, {status: r.status, error: err});
    assertEqual('wallet', beforeWallet, (await bal.walletRef.get()).data());
    assertEqual(
      'order',
      financialOrderSlice(beforeOrder),
      financialOrderSlice((await bal.orderRef.get()).data()),
    );
    mark('driver_balance_no_mutation', true);
    await auth.deleteUser(bal.uid).catch(() => {});
    await db.doc(`user/${bal.uid}`).delete().catch(() => {});
  } catch (e) {
    mark('driver_block_wallet_balance', false, e.message);
  }

  // 4) Clean driver deletion
  try {
    const clean = await createTestDriver({});
    const before = await snapshotDocs({order: clean.orderRef, wallet: clean.walletRef});
    const token = await getIdTokenForEmailPassword(clean.email, clean.password);
    const r = await callCallable('requestAccountDeletion', {confirm: true}, token);
    const ok = r.status === 200 && r.json.result && r.json.result.ok === true;
    mark('driver_clean_delete', ok, {status: r.status, body: r.json});
    const after = await snapshotDocs({order: clean.orderRef, wallet: clean.walletRef});
    assertFinancialFreeze('clean_driver', before, after);
    mark('driver_clean_financial_freeze', true);
    let authGone = false;
    try {
      await auth.getUser(clean.uid);
    } catch (e) {
      authGone = e.code === 'auth/user-not-found';
    }
    mark('driver_auth_deleted', authGone);
  } catch (e) {
    mark('driver_clean_delete', false, e.message);
  }

  // 5) Web request callable (no auth delete)
  {
    const r = await callCallable(
      'createAccountDeletionRequest',
      {
        accountType: 'customer',
        contact: `web.${RUN_ID}@touri-taxi-test.local`,
        locale: 'ar',
        note: 'stage1a',
      },
      null,
    );
    const ok = r.status === 200 && r.json.result && r.json.result.ok === true;
    mark('web_request_callable', ok, {status: r.status, body: r.json});
  }

  await cleanupMarker(RUN_ID).catch((e) => {
    mark('cleanup_marker', false, e.message);
  });

  console.log('\n=== STAGE1A SUMMARY ===');
  console.log(JSON.stringify(report, null, 2));
  if (!report.ok) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
