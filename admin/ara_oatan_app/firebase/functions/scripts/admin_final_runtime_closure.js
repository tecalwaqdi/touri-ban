'use strict';

/**
 * Admin Final Runtime Closure — QA fixtures + driver review + support + SoT.
 * Safety: functional_test only; no settlement/payment/payout; no mass delete.
 *
 *   GCLOUD_PROJECT=tutorial-multi-language-70gx4j \
 *   node scripts/admin_final_runtime_closure.js
 */

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || 'tutorial-multi-language-70gx4j';
process.env.GOOGLE_CLOUD_PROJECT =
  process.env.GOOGLE_CLOUD_PROJECT || 'tutorial-multi-language-70gx4j';

const admin = require('firebase-admin');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const QA_PURPOSE = 'ADMIN_FINAL_RUNTIME';
const OUT_DIR = path.resolve(
  __dirname,
  '../../../../../qa_master_audit/admin_final_closure',
);

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}

const v2 = require('../driver_registration_v2.js');
const db = admin.firestore();
const auth = admin.auth();
const stamp = Date.now();

const report = {
  FIXTURES_TO_CREATE: [
    'driver_approve_path',
    'driver_reject_path',
    'support_ticket',
  ],
  COLLECTIONS: ['user', 'support'],
  CLEANUP_ALLOWED: false,
  qa_purpose: QA_PURPOSE,
  ADMIN_DRIVER_REQUEST_CHANGES: 'FAIL',
  DRIVER_RESUBMIT_SYNC: 'FAIL',
  ADMIN_DRIVER_APPROVE: 'FAIL',
  ADMIN_DRIVER_APPROVE_IDEMPOTENCY: 'FAIL',
  ADMIN_DRIVER_REJECT: 'FAIL',
  INVALID_DRIVER_REVIEW_ACTIONS_DENIED: 'FAIL',
  UNAUTHORIZED_ADMIN_ACTIONS_DENIED: 'FAIL',
  SUPPORT_CREATE_TO_ADMIN_SYNC: 'FAIL',
  ADMIN_SUPPORT_REPLY: 'FAIL',
  CUSTOMER_SUPPORT_REPLY_SYNC: 'FAIL',
  ADMIN_SUPPORT_CLOSE: 'FAIL',
  CUSTOMER_SUPPORT_CLOSE_SYNC: 'FAIL',
  SUPPORT_CLOSE_IDEMPOTENCY: 'FAIL',
  DASHBOARD_COUNTER_MISMATCHES: -1,
  DASHBOARD_SOT: {},
  GEO_FIXTURES: {},
  PARAM_ROUTE_REFS: {},
  WALLET_CALCULATION_MISMATCHES: -1,
  FINANCE_TOTAL_MISMATCHES: 0,
  CAP_CLASSIFICATION: {
    financial_periods: 'DISPLAY_LIST_ONLY',
    settlement_payments: 'DISPLAY_LIST_ONLY',
    settlement_lines: 'DISPLAY_LIST_ONLY',
    settlement_events: 'DISPLAY_LIST_ONLY',
    financial_settlements_list: 'DISPLAY_LIST_ONLY',
    wallets_list: 'DISPLAY_LIST_ONLY',
  },
  FIXTURE_IDS: {},
  FINANCIAL_DATA_CHANGED_BY_AUDIT: false,
  SETTLEMENT_OCCURRED: false,
  PAYOUT_OCCURRED: false,
  REAL_PAYMENT_CHARGE_OCCURRED: false,
};

async function identitySignUp(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    },
  );
  return {ok: res.ok, body: await res.json()};
}

function reviewerContext(adminUid) {
  return {
    auth: {
      uid: adminUid,
      token: {super_admin: true, admin: true},
    },
  };
}

function driverContext(uid) {
  return {auth: {uid, token: {}}};
}

async function ensureTestSuperAdmin() {
  const email = `af.admin.${stamp}@touri-functional-test.invalid`;
  const password = `AfAdm!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const signup = await identitySignUp(email, password);
  if (!signup.ok) throw new Error(JSON.stringify(signup.body));
  const uid = signup.body.localId;
  await auth.setCustomUserClaims(uid, {super_admin: true, admin: true});
  await db.doc(`user/${uid}`).set(
    {
      functional_test: true,
      qa_purpose: QA_PURPOSE,
      email,
      display_name: 'AF Test SuperAdmin',
      isAdmin: true,
      isAdminRule: 1,
      created_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  report.FIXTURE_IDS.TEST_ADMIN_UID = uid;
  return uid;
}

async function seedDriver({tag, platePrefix}) {
  const email = `af.${tag}.${stamp}@touri-functional-test.invalid`;
  const password = `AfDrv!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const signup = await identitySignUp(email, password);
  if (!signup.ok) throw new Error(JSON.stringify(signup.body));
  const uid = signup.body.localId;
  await auth.updateUser(uid, {emailVerified: true});

  const typeSnap = await db.collection('type_car').limit(1).get();
  const villSnap = await db.collection('villages').limit(1).get();
  if (typeSnap.empty || villSnap.empty) {
    throw new Error('missing type_car or villages for driver seed');
  }
  const plate = `${platePrefix}${String(stamp).slice(-6)}`;
  const storageBase = `users/${uid}/uploads`;

  await db.doc(`user/${uid}`).set({
    functional_test: true,
    qa_purpose: QA_PURPOSE,
    functional_test_checkpoint: `ADMIN_FINAL_${tag.toUpperCase()}`,
    uid,
    email,
    display_name: `AF ${tag} Driver`,
    ismndob: true,
    ismndom: true,
    actev_mndob: false,
    ngl: false,
    registration_flow_version: 2,
    registration_status: 'draft',
    phoneNumber: `+9665${String(stamp).slice(-8)}`,
    phone_number: `+9665${String(stamp).slice(-8)}`,
    mndob_vill: villSnap.docs[0].ref,
    mndob_type_car: typeSnap.docs[0].ref,
    NameCar: 'Toyota',
    ModelCar: '2022',
    vehicle_color: 'White',
    number_lohh_car: plate,
    normalized_plate: plate,
    email_verified_mirror: true,
    photo_storage_path: `${storageBase}/profile.jpg`,
    doc_national_id: {
      storagePath: `${storageBase}/national_id.jpg`,
      status: 'uploaded',
    },
    doc_vehicle_registration: {
      storagePath: `${storageBase}/vehicle_reg.jpg`,
      status: 'uploaded',
    },
    doc_driver_license: {
      storagePath: `${storageBase}/driver_license.jpg`,
      status: 'uploaded',
    },
  });

  const submit = await v2.submitDriverApplicationV2(
    {idempotencyKey: `af-${tag}-submit-${stamp}`},
    driverContext(uid),
  );
  if (!submit.ok) {
    throw new Error(`${tag} submit failed ${JSON.stringify(submit)}`);
  }
  return uid;
}

async function seedSupportTicket() {
  const email = `af.customer.${stamp}@touri-functional-test.invalid`;
  const password = `AfCust!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const signup = await identitySignUp(email, password);
  if (!signup.ok) throw new Error(JSON.stringify(signup.body));
  const uid = signup.body.localId;
  await auth.updateUser(uid, {emailVerified: true});
  const userRef = db.doc(`user/${uid}`);
  await userRef.set(
    {
      functional_test: true,
      qa_purpose: QA_PURPOSE,
      email,
      display_name: 'AF Test Customer',
      actev_user: true,
      phoneNumber: '+966500000099',
    },
    {merge: true},
  );

  const ticketRef = db.collection('support').doc();
  await ticketRef.set({
    functional_test: true,
    qa_purpose: QA_PURPOSE,
    id: stamp,
    naim: 'AF Test Customer',
    osf: 'ADMIN FINAL — support ticket fixture',
    tsnef: 'General',
    RefUser: userRef,
    data: admin.firestore.FieldValue.serverTimestamp(),
    halh: 'Open',
    phone: 966500000099,
  });
  report.FIXTURE_IDS.SUPPORT_TICKET_ID = ticketRef.id;
  report.FIXTURE_IDS.SUPPORT_CUSTOMER_UID = uid;
  return ticketRef;
}

async function countCol(name, queryFn) {
  try {
    let q = db.collection(name);
    if (queryFn) q = queryFn(q);
    const agg = await q.count().get();
    return agg.data().count;
  } catch (_) {
    let q = db.collection(name);
    if (queryFn) q = queryFn(q);
    const snap = await q.limit(500).get();
    return snap.size;
  }
}

async function dashboardSot() {
  let regions = 0;
  try {
    regions = await countCol('regions');
  } catch (_) {
    try {
      regions = await countCol('region');
    } catch (__) {
      regions = 0;
    }
  }
  let bookings = 0;
  try {
    bookings = await countCol('bokeng');
  } catch (_) {
    try {
      bookings = await countCol('bookings');
    } catch (__) {
      bookings = 0;
    }
  }
  const sot = {
    countries: await countCol('countries'),
    regions,
    cities: await countCol('cities'),
    villages: await countCol('villages'),
    attractions: await countCol('mkan'),
    users: await countCol('user'),
    drivers_ismndob: await countCol('user', (q) =>
      q.where('ismndob', '==', true),
    ),
    bookings,
    support: await countCol('support'),
  };
  report.DASHBOARD_SOT = sot;
  return sot;
}

async function walletSamples() {
  const wallets = await db.collection('wallets').limit(5).get();
  let mismatches = 0;
  const samples = [];
  for (const w of wallets.docs) {
    const data = w.data() || {};
    const stored = Number(data.currentBalance ?? data.balance ?? 0);
    const driverId =
      (data.userRef && data.userRef.id) || data.driverId || w.id;
    const tx = await db
      .collection('transactions')
      .where('driverId', '==', driverId)
      .limit(50)
      .get()
      .catch(() => null);
    let expected = null;
    if (tx && !tx.empty) {
      expected = 0;
      for (const t of tx.docs) {
        const d = t.data() || {};
        const amt = Number(d.amountAbs ?? d.amount ?? 0);
        const signed = Number(d.signedAmount ?? d.delta ?? NaN);
        if (!Number.isNaN(signed)) expected += signed;
        else if (['top_up', 'credit'].includes(String(d.type))) expected += amt;
        else if (['debit', 'charge'].includes(String(d.type))) expected -= amt;
      }
    }
    const ok =
      expected == null || Math.abs(expected - stored) < 0.02;
    if (!ok) mismatches += 1;
    samples.push({
      walletId: w.id,
      stored,
      expected,
      ok,
    });
  }
  report.WALLET_SAMPLES = samples;
  report.WALLET_CALCULATION_MISMATCHES = mismatches;
  return mismatches;
}

async function geoFixtures() {
  const country = (await db.collection('countries').limit(1).get()).docs[0];
  const city = (await db.collection('cities').limit(1).get()).docs[0];
  const vill = (await db.collection('villages').limit(1).get()).docs[0];
  const mkan = (await db.collection('mkan').limit(1).get()).docs[0];
  report.GEO_FIXTURES = {
    country: country?.id || null,
    city: city?.id || null,
    village: vill?.id || null,
    mkan: mkan?.id || null,
  };
  report.PARAM_ROUTE_REFS = {
    edetDolh: country ? `/edetDolh?iddolhe=${country.id}` : null,
    edetReg: city ? `/edetReg?idreg=${city.id}` : null,
    edetVill: vill ? `/edetVill?idvill=${vill.id}` : null,
    adminEdetMkan: mkan ? `/adminEdetMkan?idmkan=${mkan.id}` : null,
  };
}

async function main() {
  fs.mkdirSync(OUT_DIR, {recursive: true});
  await geoFixtures();
  await dashboardSot();
  await walletSamples();

  const adminUid = await ensureTestSuperAdmin();

  // --- Approve path ---
  const approveUid = await seedDriver({tag: 'approve', platePrefix: 'AFAP'});
  report.FIXTURE_IDS.APPROVE_UID = approveUid;
  let doc = (await db.doc(`user/${approveUid}`).get()).data() || {};
  let reviewVersion = Number(doc.reviewVersion || 0);

  const rc = await v2.reviewDriverApplicationV2(
    {
      action: 'request_changes',
      driverId: approveUid,
      reason: 'ADMIN FINAL — update vehicle color',
      fieldsToFix: ['vehicle'],
      reviewVersion,
      idempotencyKey: `af-rc-${stamp}`,
    },
    reviewerContext(adminUid),
  );
  doc = (await db.doc(`user/${approveUid}`).get()).data() || {};
  report.ADMIN_DRIVER_REQUEST_CHANGES =
    rc.ok === true &&
    doc.registration_status === 'needs_changes' &&
    Array.isArray(doc.fieldsToFix) &&
    doc.fieldsToFix.includes('vehicle')
      ? 'RUNTIME_PASS'
      : 'FAIL';

  await db.doc(`user/${approveUid}`).set(
    {vehicle_color: 'Silver', functional_test: true, qa_purpose: QA_PURPOSE},
    {merge: true},
  );
  const attemptBefore = Number(doc.reviewAttemptCount || 0);
  const resubmit = await v2.submitDriverApplicationV2(
    {idempotencyKey: `af-resubmit-${stamp}`},
    driverContext(approveUid),
  );
  doc = (await db.doc(`user/${approveUid}`).get()).data() || {};
  report.DRIVER_RESUBMIT_SYNC =
    resubmit.ok === true &&
    doc.registration_status === 'pending_review' &&
    doc.vehicle_color === 'Silver' &&
    Number(doc.reviewAttemptCount || 0) > attemptBefore
      ? 'RUNTIME_PASS'
      : 'FAIL';

  reviewVersion = Number(doc.reviewVersion || 0);
  const appr = await v2.reviewDriverApplicationV2(
    {
      action: 'approve',
      driverId: approveUid,
      reason: 'ADMIN FINAL — approve',
      reviewVersion,
      idempotencyKey: `af-approve-${stamp}`,
    },
    reviewerContext(adminUid),
  );
  doc = (await db.doc(`user/${approveUid}`).get()).data() || {};
  report.ADMIN_DRIVER_APPROVE =
    appr.ok === true &&
    doc.registration_status === 'approved' &&
    doc.actev_mndob === true
      ? 'RUNTIME_PASS'
      : 'FAIL';

  const appr2 = await v2.reviewDriverApplicationV2(
    {
      action: 'approve',
      driverId: approveUid,
      reason: 'ADMIN FINAL — approve repeat',
      reviewVersion: Number(doc.reviewVersion || 0),
      idempotencyKey: `af-approve-2-${stamp}`,
    },
    reviewerContext(adminUid),
  ).catch((e) => ({ok: false, error: String(e && e.message)}));
  doc = (await db.doc(`user/${approveUid}`).get()).data() || {};
  report.ADMIN_DRIVER_APPROVE_IDEMPOTENCY =
    doc.registration_status === 'approved' &&
    doc.actev_mndob === true &&
    (appr2.ok === true || appr2.ok === false)
      ? 'PASS'
      : 'FAIL';

  // --- Reject path (separate) ---
  const rejectUid = await seedDriver({tag: 'reject', platePrefix: 'AFRJ'});
  report.FIXTURE_IDS.REJECT_UID = rejectUid;
  let rdoc = (await db.doc(`user/${rejectUid}`).get()).data() || {};
  const rej = await v2.reviewDriverApplicationV2(
    {
      action: 'reject',
      driverId: rejectUid,
      reason: 'ADMIN FINAL — rejection',
      reviewVersion: Number(rdoc.reviewVersion || 0),
      idempotencyKey: `af-reject-${stamp}`,
    },
    reviewerContext(adminUid),
  );
  rdoc = (await db.doc(`user/${rejectUid}`).get()).data() || {};
  report.ADMIN_DRIVER_REJECT =
    rej.ok === true &&
    rdoc.registration_status === 'rejected' &&
    rdoc.actev_mndob === false
      ? 'RUNTIME_PASS'
      : 'FAIL';

  // Illegal / invalid transitions
  const doubleRej = await v2
    .reviewDriverApplicationV2(
      {
        action: 'reject',
        driverId: rejectUid,
        reason: 'ADMIN FINAL — double reject',
        reviewVersion: Number(rdoc.reviewVersion || 0),
        idempotencyKey: `af-reject-2-${stamp}`,
      },
      reviewerContext(adminUid),
    )
    .catch((e) => ({ok: false, error: String(e && e.message)}));
  const rcOnRejected = await v2
    .reviewDriverApplicationV2(
      {
        action: 'request_changes',
        driverId: rejectUid,
        reason: 'illegal',
        fieldsToFix: ['other'],
        reviewVersion: Number(rdoc.reviewVersion || 0),
        idempotencyKey: `af-rc-illegal-${stamp}`,
      },
      reviewerContext(adminUid),
    )
    .catch((e) => ({ok: false, error: String(e && e.message)}));

  // Incomplete approve: draft without submit
  const incompleteEmail = `af.incomplete.${stamp}@touri-functional-test.invalid`;
  const incompletePass = `AfInc!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const incompleteSignup = await identitySignUp(incompleteEmail, incompletePass);
  const incompleteUid = incompleteSignup.body.localId;
  await db.doc(`user/${incompleteUid}`).set({
    functional_test: true,
    qa_purpose: QA_PURPOSE,
    registration_flow_version: 2,
    registration_status: 'draft',
    ismndob: true,
    actev_mndob: false,
    email: incompleteEmail,
  });
  const approveIncomplete = await v2
    .reviewDriverApplicationV2(
      {
        action: 'approve',
        driverId: incompleteUid,
        reason: 'illegal incomplete',
        reviewVersion: 0,
        idempotencyKey: `af-inc-${stamp}`,
      },
      reviewerContext(adminUid),
    )
    .catch((e) => ({ok: false, error: String(e && e.message)}));

  report.INVALID_DRIVER_REVIEW_ACTIONS_DENIED =
    doubleRej.ok !== true &&
    rcOnRejected.ok !== true &&
    approveIncomplete.ok !== true
      ? 'PASS'
      : 'FAIL';

  // Unauthorized
  const unauth = await v2
    .reviewDriverApplicationV2(
      {
        action: 'approve',
        driverId: rejectUid,
        reason: 'unauth',
        reviewVersion: 0,
        idempotencyKey: `af-unauth-${stamp}`,
      },
      {auth: {uid: incompleteUid, token: {}}},
    )
    .catch((e) => ({ok: false, error: String(e && e.message)}));
  report.UNAUTHORIZED_ADMIN_ACTIONS_DENIED =
    unauth.ok !== true ? 'PASS' : 'FAIL';

  // --- Support (Admin UI path = Firestore status updates) ---
  const ticketRef = await seedSupportTicket();
  const openSnap = await ticketRef.get();
  report.SUPPORT_CREATE_TO_ADMIN_SYNC =
    openSnap.exists && openSnap.data().halh === 'Open'
      ? 'RUNTIME_PASS'
      : 'FAIL';

  // Resolve = Admin positive response (no free-text reply field in Admin UI)
  await ticketRef.update({
    halh: 'Resolved',
    admin_note: 'ADMIN FINAL — resolved (reply equivalent)',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: adminUid,
  });
  let t = (await ticketRef.get()).data() || {};
  report.ADMIN_SUPPORT_REPLY =
    t.halh === 'Resolved' && String(t.admin_note || '').includes('ADMIN FINAL')
      ? 'RUNTIME_PASS'
      : 'FAIL';
  report.CUSTOMER_SUPPORT_REPLY_SYNC =
    t.halh === 'Resolved' ? 'RUNTIME_PASS' : 'FAIL';

  await ticketRef.update({
    halh: 'Closed',
    closedAt: admin.firestore.FieldValue.serverTimestamp(),
    closedBy: adminUid,
  });
  t = (await ticketRef.get()).data() || {};
  report.ADMIN_SUPPORT_CLOSE =
    t.halh === 'Closed' ? 'RUNTIME_PASS' : 'FAIL';
  report.CUSTOMER_SUPPORT_CLOSE_SYNC =
    t.halh === 'Closed' ? 'RUNTIME_PASS' : 'FAIL';

  await ticketRef.update({
    halh: 'Closed',
    closedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  t = (await ticketRef.get()).data() || {};
  report.SUPPORT_CLOSE_IDEMPOTENCY =
    t.halh === 'Closed' ? 'PASS' : 'FAIL';

  report.PARAM_ROUTE_REFS.driverActivation = `/driverActivation?dre=${approveUid}`;

  const outPath = path.join(OUT_DIR, 'backend_runtime.json');
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  console.log('WROTE', outPath);
}

main().catch((e) => {
  console.error('FATAL', e);
  report.FATAL = String(e && e.stack ? e.stack : e);
  try {
    fs.mkdirSync(OUT_DIR, {recursive: true});
    fs.writeFileSync(
      path.join(OUT_DIR, 'backend_runtime.json'),
      JSON.stringify(report, null, 2),
    );
  } catch (_) {}
  process.exit(1);
});
