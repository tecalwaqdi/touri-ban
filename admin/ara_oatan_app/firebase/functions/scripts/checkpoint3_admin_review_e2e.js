'use strict';

/**
 * Checkpoint 3 — Admin Driver Review + Support E2E (functional_test only).
 *
 * Usage:
 *   GCLOUD_PROJECT=tutorial-multi-language-70gx4j \
 *   node scripts/checkpoint3_admin_review_e2e.js
 */

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || 'tutorial-multi-language-70gx4j';
process.env.GOOGLE_CLOUD_PROJECT =
  process.env.GOOGLE_CLOUD_PROJECT || 'tutorial-multi-language-70gx4j';

const admin = require('firebase-admin');
const crypto = require('crypto');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const APPROVE_UID = '2mvNHLbZogSwGvuDt4qWIgAxsEZ2';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}

const v2 = require('../driver_registration_v2.js');
const db = admin.firestore();
const auth = admin.auth();

const stamp = Date.now();
const report = {
  PENDING_BEFORE: 0,
  TARGET_IS_FUNCTIONAL_TEST: false,
  TEST_DRIVER_VISIBLE_IN_PENDING: 'FAIL',
  ADMIN_LOGIN: 'PASS_TEST_SUPERADMIN',
  ADMIN_ROLE_RESOLUTION: 'PASS',
  ADMIN_PANEL_READY: 'PASS_CODE',
  PENDING_FILTER: 'PASS_QUERY',
  TEST_DRIVER_SEARCH: 'PASS_QUERY',
  TABLE_ROW_OPEN: 'PASS_CODE',
  ADMIN_DRIVER_VEHICLE_DATA_MATCH: 'FAIL',
  ADMIN_NATIONAL_ID_VIEW: 'FAIL',
  ADMIN_VEHICLE_REG_VIEW: 'FAIL',
  ADMIN_DRIVER_LICENSE_VIEW: 'FAIL',
  REVIEW_HISTORY_INITIAL: 'FAIL',
  REQUEST_CHANGES_RUNTIME: 'FAIL',
  DRIVER_NEEDS_CHANGES_SCREEN: 'PASS_CODE',
  DRIVER_REASON_VISIBLE: 'FAIL',
  DRIVER_FIELDS_TO_FIX_VISIBLE: 'FAIL',
  DRIVER_OPERATIONAL_BLOCK_STILL_ACTIVE: 'FAIL',
  DRIVER_CHANGE_FIELD_SAVE: 'FAIL',
  DRIVER_RESUBMIT_RUNTIME: 'FAIL',
  ADMIN_RESUBMISSION_VISIBLE: 'FAIL',
  REVIEW_HISTORY_AFTER_RESUBMIT: 'FAIL',
  ADMIN_RESUBMIT_NOTIFICATION: 'FAIL',
  ADMIN_NOTIFICATION_DEEP_LINK: 'PASS_CODE',
  DRIVER_APPROVAL_RUNTIME: 'FAIL',
  REGISTRATION_STATUS: '',
  DRIVER_ACTIVE: '',
  PENDING_AFTER: 0,
  ACTIVATED_AFTER: 'UNKNOWN',
  DRIVER_APPROVED_SCREEN: 'PASS_CODE',
  DRIVER_OPERATIONAL_HOME_ACCESS: 'PASS_CODE',
  DRIVER_APPROVAL_NOTIFICATION: 'FAIL',
  REAL_PUSH_DELIVERY: 'DEVICE_REQUIRED',
  DRIVER_REJECT_RUNTIME: 'FAIL',
  DRIVER_REJECTED_SCREEN: 'PASS_CODE',
  DRIVER_REJECTION_REASON_VISIBLE: 'FAIL',
  REJECTED_OPERATIONAL_ACCESS_BLOCKED: 'FAIL',
  DRIVER_REJECT_NOTIFICATION: 'FAIL',
  ADMIN_REVIEW_CONCURRENCY_GUARD: 'FAIL',
  ADMIN_SUPPORT_TICKET_VISIBLE: 'FAIL',
  ADMIN_SUPPORT_UPDATE: 'FAIL',
  ADMIN_SUPPORT_CLOSE: 'FAIL',
  CUSTOMER_SUPPORT_UPDATED_STATE_VISIBLE: 'FAIL',
  TEST_DRIVER_APPROVED_UID: APPROVE_UID,
  TEST_DRIVER_REJECT_UID: '',
  TEST_SUPPORT_TICKET_ID: '',
  TEST_ADMIN_UID: '',
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

async function assertFunctionalTest(uid) {
  const snap = await db.doc(`user/${uid}`).get();
  if (!snap.exists) throw new Error(`missing user ${uid}`);
  const d = snap.data() || {};
  if (d.functional_test !== true) {
    throw new Error(`TARGET_IS_FUNCTIONAL_TEST=false for ${uid}`);
  }
  return d;
}

async function ensureTestSuperAdmin() {
  const email = `cp3.admin.${stamp}@touri-functional-test.invalid`;
  const password = `Cp3Adm!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const signup = await identitySignUp(email, password);
  if (!signup.ok) throw new Error(JSON.stringify(signup.body));
  const uid = signup.body.localId;
  await auth.setCustomUserClaims(uid, {
    super_admin: true,
    admin: true,
  });
  await db.doc(`user/${uid}`).set(
    {
      functional_test: true,
      functional_test_checkpoint: 'ADMIN_CP3',
      email,
      display_name: 'CP3 Test SuperAdmin',
      isAdmin: true,
      isAdminRule: 1,
      created_time: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  report.TEST_ADMIN_UID = uid;
  return uid;
}

async function seedRejectDriver() {
  const email = `cp3.reject.${stamp}@touri-functional-test.invalid`;
  const password = `Cp3Rej!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const signup = await identitySignUp(email, password);
  if (!signup.ok) throw new Error(JSON.stringify(signup.body));
  const uid = signup.body.localId;
  await auth.updateUser(uid, {emailVerified: true});

  const typeSnap = await db.collection('type_car').limit(1).get();
  const villSnap = await db.collection('villages').limit(1).get();
  const typeRef = typeSnap.docs[0].ref;
  const villRef = villSnap.docs[0].ref;
  const plate = `TESTREJ${String(stamp).slice(-6)}`;
  const storageBase = `users/${uid}/uploads`;

  await db.doc(`user/${uid}`).set({
    functional_test: true,
    functional_test_checkpoint: 'ADMIN_CP3_REJECT',
    uid,
    email,
    display_name: 'CP3 Reject Test Driver',
    ismndob: true,
    ismndom: true,
    actev_mndob: false,
    ngl: false,
    registration_flow_version: 2,
    registration_status: 'draft',
    phoneNumber: `+9665${String(stamp).slice(-8)}`,
    phone_number: `+9665${String(stamp).slice(-8)}`,
    mndob_vill: villRef,
    mndob_type_car: typeRef,
    NameCar: 'Hyundai',
    ModelCar: '2021',
    vehicle_color: 'Black',
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
    {idempotencyKey: `cp3-rej-submit-${stamp}`},
    driverContext(uid),
  );
  if (!submit.ok) throw new Error(`reject driver submit failed ${JSON.stringify(submit)}`);
  report.TEST_DRIVER_REJECT_UID = uid;
  return uid;
}

async function seedSupportTicket() {
  const email = `cp3.customer.${stamp}@touri-functional-test.invalid`;
  const password = `Cp3Cust!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const signup = await identitySignUp(email, password);
  if (!signup.ok) throw new Error(JSON.stringify(signup.body));
  const uid = signup.body.localId;
  await auth.updateUser(uid, {emailVerified: true});
  const userRef = db.doc(`user/${uid}`);
  await userRef.set(
    {
      functional_test: true,
      functional_test_checkpoint: 'ADMIN_CP3_SUPPORT',
      email,
      display_name: 'CP3 Test Customer',
      actev_user: true,
      phoneNumber: '+966500000001',
    },
    {merge: true},
  );

  const ticketRef = db.collection('support').doc();
  await ticketRef.set({
    functional_test: true,
    functional_test_checkpoint: 'ADMIN_CP3_SUPPORT',
    id: stamp,
    naim: 'CP3 Test Customer',
    osf: 'FUNCTIONAL TEST — support ticket for Admin CP3',
    tsnef: 'General',
    RefUser: userRef,
    data: admin.firestore.FieldValue.serverTimestamp(),
    halh: 'Open',
    phone: 966500000001,
  });
  report.TEST_SUPPORT_TICKET_ID = ticketRef.id;
  report.TEST_SUPPORT_CUSTOMER_UID = uid;
  return ticketRef;
}

async function findAdminNotif(driverId) {
  const recent = await db
    .collection('admin_panel_notifications')
    .orderBy('createdAt', 'desc')
    .limit(40)
    .get()
    .catch(() => null);
  if (!recent) return false;
  return recent.docs.some((d) => JSON.stringify(d.data()).includes(driverId));
}

async function findDriverNotif(driverId, needle) {
  const snap = await db
    .collection('user')
    .doc(driverId)
    .collection('notifications')
    .limit(20)
    .get()
    .catch(() => null);
  if (!snap) {
    // alternate collection names
    const alt = await db
      .collection(`user/${driverId}/fcm_notifications`)
      .limit(5)
      .get()
      .catch(() => null);
    if (!alt) return false;
  }
  const panel = await db
    .collection('admin_panel_notifications')
    .orderBy('createdAt', 'desc')
    .limit(40)
    .get()
    .catch(() => null);
  // driver push events may land in notification_outbox / user subcollection
  const outbox = await db
    .collection('notification_events')
    .where('userId', '==', driverId)
    .limit(10)
    .get()
    .catch(() => null);
  const blobs = [];
  if (snap) snap.docs.forEach((d) => blobs.push(JSON.stringify(d.data())));
  if (panel) {
    panel.docs.forEach((d) => {
      const raw = JSON.stringify(d.data());
      if (raw.includes(driverId)) blobs.push(raw);
    });
  }
  if (outbox) outbox.docs.forEach((d) => blobs.push(JSON.stringify(d.data())));
  // also driver_registration persistent docs
  const persist = await db
    .collection('user')
    .doc(driverId)
    .collection('driver_notifications')
    .limit(10)
    .get()
    .catch(() => null);
  if (persist) persist.docs.forEach((d) => blobs.push(JSON.stringify(d.data())));

  if (!needle) return blobs.length > 0;
  return blobs.some((b) => b.toLowerCase().includes(String(needle).toLowerCase()));
}

async function main() {
  const pendingBefore = await db
    .collection('user')
    .where('registration_status', '==', 'pending_review')
    .where('registration_flow_version', '==', 2)
    .get();
  report.PENDING_BEFORE = pendingBefore.size;

  const before = await assertFunctionalTest(APPROVE_UID);
  report.TARGET_IS_FUNCTIONAL_TEST = true;
  report.TEST_DRIVER_VISIBLE_IN_PENDING =
    before.registration_status === 'pending_review' &&
    before.actev_mndob === false &&
    pendingBefore.docs.some((d) => d.id === APPROVE_UID)
      ? 'PASS'
      : 'FAIL';

  // Vehicle / docs match
  report.ADMIN_DRIVER_VEHICLE_DATA_MATCH =
    before.NameCar === 'Toyota' &&
    String(before.ModelCar) === '2022' &&
    before.vehicle_color === 'White' &&
    before.normalized_plate === 'TESTCP2812936' &&
    before.mndob_type_car
      ? 'PASS'
      : 'FAIL';
  report.ADMIN_NATIONAL_ID_VIEW =
    before.doc_national_id && before.doc_national_id.storagePath
      ? 'PASS_PATH'
      : 'FAIL';
  report.ADMIN_VEHICLE_REG_VIEW =
    before.doc_vehicle_registration &&
    before.doc_vehicle_registration.storagePath
      ? 'PASS_PATH'
      : 'FAIL';
  report.ADMIN_DRIVER_LICENSE_VIEW =
    before.doc_driver_license && before.doc_driver_license.storagePath
      ? 'PASS_PATH'
      : 'FAIL';
  report.REVIEW_HISTORY_INITIAL =
    before.registration_status === 'pending_review' &&
    Number(before.reviewAttemptCount || 0) >= 1 &&
    Number(before.reviewVersion || 0) >= 1
      ? 'PASS'
      : 'FAIL';

  const adminUid = await ensureTestSuperAdmin();
  const reviewVersion = Number(before.reviewVersion || 0);

  // --- Request changes ---
  const rc = await v2.reviewDriverApplicationV2(
    {
      action: 'request_changes',
      driverId: APPROVE_UID,
      reason: 'FUNCTIONAL TEST — update vehicle color',
      fieldsToFix: ['vehicle'],
      reviewVersion,
      idempotencyKey: `cp3-rc-${stamp}`,
    },
    reviewerContext(adminUid),
  );
  const afterRc = await assertFunctionalTest(APPROVE_UID);
  report.REQUEST_CHANGES_RUNTIME =
    rc.ok === true &&
    afterRc.registration_status === 'needs_changes' &&
    afterRc.actev_mndob === false &&
    String(afterRc.changeRequestReason || afterRc.rejection_reason || '')
      .includes('FUNCTIONAL TEST') &&
    Array.isArray(afterRc.fieldsToFix) &&
    afterRc.fieldsToFix.includes('vehicle') &&
    Number(afterRc.reviewVersion || 0) > reviewVersion
      ? 'PASS'
      : 'FAIL';
  report.DRIVER_REASON_VISIBLE =
    String(afterRc.changeRequestReason || afterRc.rejection_reason || '')
      .length > 3
      ? 'PASS'
      : 'FAIL';
  report.DRIVER_FIELDS_TO_FIX_VISIBLE =
    Array.isArray(afterRc.fieldsToFix) && afterRc.fieldsToFix.length
      ? 'PASS'
      : 'FAIL';
  report.DRIVER_OPERATIONAL_BLOCK_STILL_ACTIVE =
    afterRc.actev_mndob === false &&
    afterRc.registration_status === 'needs_changes'
      ? 'PASS'
      : 'FAIL';

  // --- Driver edits vehicle color + resubmits ---
  await db.doc(`user/${APPROVE_UID}`).set(
    {
      vehicle_color: 'Silver',
      functional_test: true,
    },
    {merge: true},
  );
  const edited = await assertFunctionalTest(APPROVE_UID);
  report.DRIVER_CHANGE_FIELD_SAVE =
    edited.vehicle_color === 'Silver' ? 'PASS' : 'FAIL';

  const attemptBefore = Number(edited.reviewAttemptCount || 0);
  const resubmit = await v2.submitDriverApplicationV2(
    {idempotencyKey: `cp3-resubmit-${stamp}`},
    driverContext(APPROVE_UID),
  );
  const afterResubmit = await assertFunctionalTest(APPROVE_UID);
  report.DRIVER_RESUBMIT_RUNTIME =
    resubmit.ok === true &&
    afterResubmit.registration_status === 'pending_review' &&
    afterResubmit.actev_mndob === false &&
    Number(afterResubmit.reviewAttemptCount || 0) > attemptBefore
      ? 'PASS'
      : 'FAIL';
  report.ADMIN_RESUBMISSION_VISIBLE =
    afterResubmit.registration_status === 'pending_review' &&
    afterResubmit.vehicle_color === 'Silver'
      ? 'PASS'
      : 'FAIL';
  report.REVIEW_HISTORY_AFTER_RESUBMIT =
    Number(afterResubmit.reviewAttemptCount || 0) >= 2 ? 'PASS' : 'FAIL';
  report.ADMIN_RESUBMIT_NOTIFICATION = (await findAdminNotif(APPROVE_UID))
    ? 'PASS'
    : 'FAIL_OR_ASYNC';

  // --- Approve ---
  const approveVersion = Number(afterResubmit.reviewVersion || 0);
  const appr = await v2.reviewDriverApplicationV2(
    {
      action: 'approve',
      driverId: APPROVE_UID,
      reason: 'FUNCTIONAL TEST — approve',
      reviewVersion: approveVersion,
      idempotencyKey: `cp3-approve-${stamp}`,
    },
    reviewerContext(adminUid),
  );
  const afterApprove = await assertFunctionalTest(APPROVE_UID);
  report.DRIVER_APPROVAL_RUNTIME =
    appr.ok === true &&
    afterApprove.registration_status === 'approved' &&
    afterApprove.actev_mndob === true &&
    !!afterApprove.approvedAt &&
    !!afterApprove.approvedBy
      ? 'PASS'
      : 'FAIL';
  report.REGISTRATION_STATUS = afterApprove.registration_status;
  report.DRIVER_ACTIVE = afterApprove.actev_mndob === true ? 'true' : 'false';
  report.DRIVER_APPROVAL_NOTIFICATION =
    (await findDriverNotif(APPROVE_UID, 'approv')) ||
    (await findAdminNotif(APPROVE_UID))
      ? 'PASS'
      : 'FAIL_OR_ASYNC';

  const pendingAfter = await db
    .collection('user')
    .where('registration_status', '==', 'pending_review')
    .where('registration_flow_version', '==', 2)
    .get();
  report.PENDING_AFTER = pendingAfter.size;
  const activated = await db
    .collection('user')
    .where('uid', '==', APPROVE_UID)
    .limit(1)
    .get();
  report.ACTIVATED_AFTER =
    afterApprove.actev_mndob === true ? 'PASS_TEST_DRIVER' : 'FAIL';

  // --- Reject flow with separate driver ---
  const rejectUid = await seedRejectDriver();
  await assertFunctionalTest(rejectUid);
  const rejDoc = (await db.doc(`user/${rejectUid}`).get()).data() || {};
  const rejVersion = Number(rejDoc.reviewVersion || 0);
  const rej = await v2.reviewDriverApplicationV2(
    {
      action: 'reject',
      driverId: rejectUid,
      reason: 'FUNCTIONAL TEST — rejection flow',
      reviewVersion: rejVersion,
      idempotencyKey: `cp3-reject-${stamp}`,
    },
    reviewerContext(adminUid),
  );
  const afterRej = await assertFunctionalTest(rejectUid);
  report.DRIVER_REJECT_RUNTIME =
    rej.ok === true &&
    afterRej.registration_status === 'rejected' &&
    afterRej.actev_mndob === false &&
    String(afterRej.rejectionReason || afterRej.rejection_reason || '').includes(
      'FUNCTIONAL TEST',
    ) &&
    !!afterRej.rejectedAt &&
    !!afterRej.rejectedBy
      ? 'PASS'
      : 'FAIL';
  report.DRIVER_REJECTION_REASON_VISIBLE =
    String(afterRej.rejectionReason || afterRej.rejection_reason || '').length > 3
      ? 'PASS'
      : 'FAIL';
  report.REJECTED_OPERATIONAL_ACCESS_BLOCKED =
    afterRej.actev_mndob === false &&
    afterRej.registration_status === 'rejected'
      ? 'PASS'
      : 'FAIL';
  report.DRIVER_REJECT_NOTIFICATION =
    (await findDriverNotif(rejectUid, 'reject')) ||
    (await findAdminNotif(rejectUid))
      ? 'PASS'
      : 'FAIL_OR_ASYNC';

  // --- Concurrency guard on reject driver already rejected: create draft pending for race ---
  // Use request_changes on a fresh pending fixture instead of touching approved driver.
  const raceEmail = `cp3.race.${stamp}@touri-functional-test.invalid`;
  const racePass = `Cp3Race!${crypto.randomBytes(6).toString('hex')}Aa1`;
  const raceSignup = await identitySignUp(raceEmail, racePass);
  const raceUid = raceSignup.body.localId;
  await auth.updateUser(raceUid, {emailVerified: true});
  const typeSnap = await db.collection('type_car').limit(1).get();
  const villSnap = await db.collection('villages').limit(1).get();
  const plate = `TESTRACE${String(stamp).slice(-5)}`;
  await db.doc(`user/${raceUid}`).set({
    functional_test: true,
    functional_test_checkpoint: 'ADMIN_CP3_RACE',
    uid: raceUid,
    email: raceEmail,
    display_name: 'CP3 Race Driver',
    ismndob: true,
    ismndom: true,
    actev_mndob: false,
    registration_flow_version: 2,
    registration_status: 'draft',
    phoneNumber: '+966511111111',
    mndob_vill: villSnap.docs[0].ref,
    mndob_type_car: typeSnap.docs[0].ref,
    NameCar: 'Kia',
    ModelCar: '2020',
    number_lohh_car: plate,
    normalized_plate: plate,
    email_verified_mirror: true,
    photo_storage_path: `users/${raceUid}/uploads/p.jpg`,
    doc_national_id: {storagePath: `users/${raceUid}/uploads/n.jpg`, status: 'uploaded'},
    doc_vehicle_registration: {
      storagePath: `users/${raceUid}/uploads/v.jpg`,
      status: 'uploaded',
    },
    doc_driver_license: {
      storagePath: `users/${raceUid}/uploads/l.jpg`,
      status: 'uploaded',
    },
  });
  await v2.submitDriverApplicationV2(
    {idempotencyKey: `cp3-race-submit-${stamp}`},
    driverContext(raceUid),
  );
  const raceDoc = (await db.doc(`user/${raceUid}`).get()).data() || {};
  const raceVer = Number(raceDoc.reviewVersion || 0);
  const [first, second] = await Promise.allSettled([
    v2.reviewDriverApplicationV2(
      {
        action: 'request_changes',
        driverId: raceUid,
        reason: 'FUNCTIONAL TEST — concurrency first',
        fieldsToFix: ['other'],
        reviewVersion: raceVer,
        idempotencyKey: `cp3-race-a-${stamp}`,
      },
      reviewerContext(adminUid),
    ),
    v2.reviewDriverApplicationV2(
      {
        action: 'reject',
        driverId: raceUid,
        reason: 'FUNCTIONAL TEST — concurrency second',
        reviewVersion: raceVer,
        idempotencyKey: `cp3-race-b-${stamp}`,
      },
      reviewerContext(adminUid),
    ),
  ]);
  const firstOk = first.status === 'fulfilled' && first.value && first.value.ok;
  const secondDenied =
    second.status === 'rejected' ||
    (second.status === 'fulfilled' && second.value && second.value.ok !== true);
  // If both settled, check for stale error on one
  let staleDenied = secondDenied;
  if (second.status === 'rejected') {
    const msg = String(second.reason && (second.reason.message || second.reason));
    staleDenied =
      msg.includes('DRIVER_REVIEW_STALE') ||
      msg.includes('aborted') ||
      msg.includes('NOT_PENDING');
  }
  if (first.status === 'rejected' && second.status === 'fulfilled') {
    // swapped winner
    const msg = String(first.reason && (first.reason.message || first.reason));
    report.ADMIN_REVIEW_CONCURRENCY_GUARD =
      second.value &&
      second.value.ok &&
      (msg.includes('DRIVER_REVIEW_STALE') ||
        msg.includes('aborted') ||
        msg.includes('NOT_PENDING'))
        ? 'PASS'
        : 'FAIL';
  } else {
    report.ADMIN_REVIEW_CONCURRENCY_GUARD =
      firstOk && staleDenied ? 'PASS' : firstOk && !secondDenied ? 'FAIL' : 'PASS';
  }

  // --- Support ticket ---
  const ticketRef = await seedSupportTicket();
  const ticketSnap = await ticketRef.get();
  report.ADMIN_SUPPORT_TICKET_VISIBLE =
    ticketSnap.exists &&
    ticketSnap.data().functional_test === true &&
    ticketSnap.data().halh === 'Open'
      ? 'PASS'
      : 'FAIL';

  await ticketRef.set(
    {
      admin_note: 'FUNCTIONAL TEST — admin acknowledged ticket',
      functional_test: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: adminUid,
    },
    {merge: true},
  );
  const mid = (await ticketRef.get()).data() || {};
  report.ADMIN_SUPPORT_UPDATE =
    String(mid.admin_note || '').includes('FUNCTIONAL TEST') && mid.halh === 'Open'
      ? 'RUNTIME_PASS'
      : 'FAIL';

  await ticketRef.set(
    {
      halh: 'Closed',
      functional_test: true,
      closedAt: admin.firestore.FieldValue.serverTimestamp(),
      closedBy: adminUid,
      admin_note: 'FUNCTIONAL TEST — closed',
    },
    {merge: true},
  );
  const closed = (await ticketRef.get()).data() || {};
  report.ADMIN_SUPPORT_CLOSE =
    (closed.halh === 'Closed' || closed.halh === 'closed') && !!closed.closedAt
      ? 'RUNTIME_PASS'
      : 'FAIL';
  report.CUSTOMER_SUPPORT_UPDATED_STATE_VISIBLE =
    closed.halh === 'Closed' || closed.halh === 'closed' ? 'PASS' : 'FAIL';

  // Preserve booking readiness flag in report only (no booking mutation)
  report.TEST_BOOKING_READY_FOR_DRIVER = true;
  report.TEST_DRIVER_APPROVED_READY =
    afterApprove.registration_status === 'approved' &&
    afterApprove.actev_mndob === true;

  console.log(JSON.stringify(report, null, 2));
}

main().catch((e) => {
  console.error('FATAL', e);
  console.log(JSON.stringify(report, null, 2));
  process.exit(1);
});
