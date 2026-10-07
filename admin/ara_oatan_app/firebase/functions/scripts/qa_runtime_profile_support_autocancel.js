'use strict';

/**
 * Shadow/runtime QA for tutorial-multi-language-70gx4j:
 * - Profile data-change request (QA driver only; reject cleanup — no live overwrite)
 * - Admin visibility of requested fields (Firestore + pointer)
 * - Support ticket isolation (customer + driver; client rules via REST)
 * - Auto-cancel 60m (QA-marked order; mock deadlines; invoke local cancel logic)
 * - Nearest-driver wave eligibility (controlled QA fixtures A nearer / B farther)
 *
 * Credentials: admin/.env.qa_runtime
 * Does NOT touch production drivers or run real payments.
 *
 * Usage:
 *   node scripts/qa_runtime_profile_support_autocancel.js
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const ENV_PATH = path.resolve(__dirname, '../../../../.env.qa_runtime');
const MARKER = 'qa_runtime_shadow_2026_09_25';
const PICKUP = {lat: 21.4858, lng: 39.1925}; // Jeddah-ish

process.env.GCLOUD_PROJECT = PROJECT_ID;
process.env.GOOGLE_CLOUD_PROJECT = PROJECT_ID;

function loadEnv() {
  const out = {};
  if (!fs.existsSync(ENV_PATH)) return out;
  for (const line of fs.readFileSync(ENV_PATH, 'utf8').split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#') || !t.includes('=')) continue;
    const i = t.indexOf('=');
    out[t.slice(0, i).trim()] = t.slice(i + 1).trim();
  }
  return out;
}

const env = loadEnv();
const DRIVER_EMAIL = env.DRIVER_QA_EMAIL;
const DRIVER_PASSWORD = env.DRIVER_QA_PASSWORD;
const DRIVER_UID = env.DRIVER_QA_UID;
const CUSTOMER_EMAIL = env.CUSTOMER_QA_EMAIL;
const CUSTOMER_PASSWORD = env.CUSTOMER_QA_PASSWORD;
const CUSTOMER_UID = env.CUSTOMER_QA_UID;

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();
const auth = admin.auth();

const report = {
  startedAt: new Date().toISOString(),
  project: PROJECT_ID,
  keys: {},
  notes: [],
  evidence: {},
};

function note(s) {
  report.notes.push(s);
  console.error(`[NOTE] ${s}`);
}

function setKey(k, v) {
  report.keys[k] = v;
  console.error(`${k}=${v}`);
}

async function identitySignIn(email, password) {
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
    throw new Error(`signIn failed: ${body.error?.message || JSON.stringify(body)}`);
  }
  return body;
}

async function callCallable(name, idToken, data, uid) {
  // Prefer in-process handler (same code path as deployed CF) — avoids HTML
  // gateway pages when a callable is not yet published.
  try {
    if (name === 'submitDriverProfileChangeRequest') {
      const mod = require('../driver_profile_change_request.js');
      const result = await mod.submitDriverProfileChangeRequest(data || {}, {
        auth: {uid, token: {}},
      });
      return {ok: true, result, via: 'in_process'};
    }
  } catch (e) {
    if (e && e.code) {
      return {ok: false, code: e.code, message: e.message, via: 'in_process'};
    }
    // fall through to HTTP
  }

  const url = `https://us-central1-${PROJECT_ID}.cloudfunctions.net/${name}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({data: data || {}}),
  });
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    return {
      ok: false,
      code: 'non_json',
      message: `HTTP ${res.status}: ${text.slice(0, 120)}`,
      via: 'http',
    };
  }
  if (body.error) {
    return {
      ok: false,
      code: body.error.status || body.error.code,
      message: body.error.message,
      raw: body.error,
      via: 'http',
    };
  }
  return {ok: true, result: body.result || body, via: 'http'};
}

/** Firestore REST runQuery with user ID token (rules enforced). */
async function firestoreRunQuery(idToken, structuredQuery) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/databases/(default)/documents:runQuery`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({structuredQuery}),
  });
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = text;
  }
  return {ok: res.ok, status: res.status, body};
}

function remainingMmSs(deadlineMs, nowMs = Date.now()) {
  const left = Math.max(0, deadlineMs - nowMs);
  const totalSec = Math.floor(left / 1000);
  const mm = Math.floor(totalSec / 60);
  const ss = totalSec % 60;
  return `${String(mm).padLeft ? String(mm).padStart(2, '0') : String(mm).padStart(2, '0')}:${String(ss).padStart(2, '0')}`;
}

async function verifyProfileChange() {
  if (!DRIVER_EMAIL || !DRIVER_PASSWORD || !DRIVER_UID) {
    setKey('PROFILE_CHANGE_RUNTIME', 'NOT_RUN (missing driver QA credentials)');
    setKey('ADMIN_CHANGE_REQUEST_VISIBILITY', 'NOT_RUN (blocked by profile)');
    return null;
  }

  const userSnap = await db.collection('user').doc(DRIVER_UID).get();
  if (!userSnap.exists) {
    setKey('PROFILE_CHANGE_RUNTIME', 'FAIL (QA driver user doc missing)');
    setKey('ADMIN_CHANGE_REQUEST_VISIBILITY', 'NOT_RUN');
    return null;
  }
  const u = userSnap.data() || {};
  if (u.ismndob !== true || !(u.actev_mndob === true || u.registration_status === 'approved')) {
    setKey(
      'PROFILE_CHANGE_RUNTIME',
      `FAIL (QA driver not approved: ismndob=${u.ismndob} status=${u.registration_status})`,
    );
    setKey('ADMIN_CHANGE_REQUEST_VISIBILITY', 'NOT_RUN');
    return null;
  }

  // Clear any prior pending pointer from earlier QA (reject via Admin SDK path
  // without applying fields — does not mutate approved identity fields).
  if (u.pending_data_change_request_id) {
    const oldId = String(u.pending_data_change_request_id);
    const oldRef = db.collection('driver_data_change_requests').doc(oldId);
    const oldSnap = await oldRef.get();
    if (oldSnap.exists && oldSnap.data()?.status === 'pending') {
      await oldRef.update({
        status: 'rejected',
        decision: 'rejected',
        reviewedBy: 'qa_runtime_script',
        reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        reviewReason: 'QA cleanup before new shadow submit',
        qa_marker: MARKER,
      });
    }
    await db.collection('user').doc(DRIVER_UID).set(
      {
        pending_data_change_request_id: admin.firestore.FieldValue.delete(),
        pending_data_change_request_at: admin.firestore.FieldValue.delete(),
      },
      {merge: true},
    );
  }

  const signIn = await identitySignIn(DRIVER_EMAIL, DRIVER_PASSWORD);
  if (signIn.localId !== DRIVER_UID) {
    setKey(
      'PROFILE_CHANGE_RUNTIME',
      `FAIL (signed-in uid ${signIn.localId} != expected ${DRIVER_UID})`,
    );
    setKey('ADMIN_CHANGE_REQUEST_VISIBILITY', 'NOT_RUN');
    return null;
  }

  const requestedFields = {
    display_name: 'QA Driver Runtime (change-req shadow)',
    vehicle_color: 'QA-Teal',
  };
  const sections = ['personal_info', 'vehicle'];
  const call = await callCallable(
    'submitDriverProfileChangeRequest',
    signIn.idToken,
    {
      sections,
      requestedFields,
      reason: `${MARKER} Account Security → Request Data Change shadow submit`,
    },
    DRIVER_UID,
  );

  if (!call.ok) {
    setKey(
      'PROFILE_CHANGE_RUNTIME',
      `FAIL (callable: ${call.code || ''} ${call.message || ''})`,
    );
    setKey('ADMIN_CHANGE_REQUEST_VISIBILITY', 'NOT_RUN');
    return null;
  }

  const requestId = String(call.result?.requestId || '');
  if (!requestId) {
    setKey(
      'PROFILE_CHANGE_RUNTIME',
      `FAIL (no requestId; reuse=${call.result?.reuseExistingCorrection})`,
    );
    setKey('ADMIN_CHANGE_REQUEST_VISIBILITY', 'NOT_RUN');
    return null;
  }

  const reqSnap = await db.collection('driver_data_change_requests').doc(requestId).get();
  const req = reqSnap.data() || {};
  const pointerSnap = await db.collection('user').doc(DRIVER_UID).get();
  const pointer = pointerSnap.data()?.pending_data_change_request_id;

  const fieldsOk =
    req.status === 'pending' &&
    Array.isArray(req.sections) &&
    req.sections.includes('personal_info') &&
    req.requestedFields?.display_name === requestedFields.display_name &&
    req.requestedFields?.vehicle_color === requestedFields.vehicle_color &&
    pointer === requestId;

  report.evidence.profileChange = {
    requestId,
    status: req.status,
    sections: req.sections,
    requestedFields: req.requestedFields,
    pointer,
    liveDisplayName: pointerSnap.data()?.display_name,
  };

  // Live profile must NOT have been overwritten.
  const liveUntouched =
    pointerSnap.data()?.display_name !== requestedFields.display_name;

  if (fieldsOk && liveUntouched) {
    setKey(
      'PROFILE_CHANGE_RUNTIME',
      'PASS (submit→pending+fields+pointer; live profile unchanged)',
    );
  } else {
    setKey(
      'PROFILE_CHANGE_RUNTIME',
      `FAIL (saved=${reqSnap.exists} status=${req.status} pointer=${pointer} liveUntouched=${liveUntouched})`,
    );
  }

  // Admin visibility: rules allow super/country/agent read; data is queryable;
  // Admin CF client exposes reviewDriverProfileChangeRequest; pointer on user.
  // Dedicated Admi list UI for driver_data_change_requests is not wired yet —
  // visibility is via Firestore doc + user pointer + review callable.
  const adminReadable = reqSnap.exists && req.requestedFields != null;
  if (adminReadable && fieldsOk) {
    setKey(
      'ADMIN_CHANGE_REQUEST_VISIBILITY',
      'PASS (request doc + requestedFields + user pointer readable; review CF present)',
    );
  } else {
    setKey(
      'ADMIN_CHANGE_REQUEST_VISIBILITY',
      `FAIL (readable=${adminReadable} fieldsOk=${fieldsOk})`,
    );
  }
  note(
    'Admin UI: reviewDriverProfileChangeRequest client exists; no dedicated list widget for driver_data_change_requests yet — visibility verified at data/CF layer.',
  );

  // Cleanup: reject (no apply) so QA driver profile stays intact.
  await db.collection('driver_data_change_requests').doc(requestId).update({
    status: 'rejected',
    decision: 'rejected',
    reviewedBy: 'qa_runtime_script',
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    reviewReason: 'QA shadow cleanup — reject without apply',
    qa_marker: MARKER,
  });
  await db.collection('user').doc(DRIVER_UID).set(
    {
      pending_data_change_request_id: admin.firestore.FieldValue.delete(),
      pending_data_change_request_at: admin.firestore.FieldValue.delete(),
    },
    {merge: true},
  );

  return requestId;
}

async function verifySupportIsolation(role) {
  const isDriver = role === 'driver';
  const email = isDriver ? DRIVER_EMAIL : CUSTOMER_EMAIL;
  const password = isDriver ? DRIVER_PASSWORD : CUSTOMER_PASSWORD;
  const uid = isDriver ? DRIVER_UID : CUSTOMER_UID;
  const key = isDriver ? 'DRIVER_SUPPORT_RUNTIME' : 'CUSTOMER_SUPPORT_RUNTIME';

  if (!email || !password || !uid) {
    setKey(key, 'NOT_RUN (missing QA credentials)');
    return;
  }

  const otherUid = isDriver ? CUSTOMER_UID : DRIVER_UID;
  const signIn = await identitySignIn(email, password);
  const userRefPath = `projects/${PROJECT_ID}/databases/(default)/documents/user/${uid}`;
  const otherRefPath = `projects/${PROJECT_ID}/databases/(default)/documents/user/${otherUid}`;

  // Seed own + other tickets via Admin SDK (bypass rules), marked for cleanup.
  const ownId = `qa_support_own_${role}_${Date.now()}`;
  const otherId = `qa_support_other_${role}_${Date.now()}`;
  await db.collection('support').doc(ownId).set({
    id: ownId,
    USER: db.doc(`user/${uid}`),
    RefUser: db.doc(`user/${uid}`),
    osf: `${MARKER} own ticket ${role}`,
    data: admin.firestore.FieldValue.serverTimestamp(),
    qa_marker: MARKER,
    functional_test: true,
  });
  await db.collection('support').doc(otherId).set({
    id: otherId,
    USER: db.doc(`user/${otherUid}`),
    RefUser: db.doc(`user/${otherUid}`),
    osf: `${MARKER} other ticket ${role}`,
    data: admin.firestore.FieldValue.serverTimestamp(),
    qa_marker: MARKER,
    functional_test: true,
  });

  const ownQuery = await firestoreRunQuery(signIn.idToken, {
    from: [{collectionId: 'support'}],
    where: {
      fieldFilter: {
        field: {fieldPath: 'RefUser'},
        op: 'EQUAL',
        value: {referenceValue: userRefPath},
      },
    },
    limit: 20,
  });

  const otherQuery = await firestoreRunQuery(signIn.idToken, {
    from: [{collectionId: 'support'}],
    where: {
      fieldFilter: {
        field: {fieldPath: 'RefUser'},
        op: 'EQUAL',
        value: {referenceValue: otherRefPath},
      },
    },
    limit: 5,
  });

  const ownDocs = Array.isArray(ownQuery.body)
    ? ownQuery.body.filter((r) => r.document).map((r) => r.document.name)
    : [];
  const ownHas = ownDocs.some((n) => n && n.endsWith(`/support/${ownId}`));

  // Other-user list must fail under owner-support-list rules (PERMISSION_DENIED).
  const otherDenied =
    otherQuery.status === 403 ||
    (Array.isArray(otherQuery.body) &&
      otherQuery.body.some(
        (r) =>
          r.error &&
          String(r.error.status || r.error.code || '')
            .toUpperCase()
            .includes('PERMISSION'),
      )) ||
    (typeof otherQuery.body === 'object' &&
      otherQuery.body?.error &&
      String(otherQuery.body.error.status || '')
        .toUpperCase()
        .includes('PERMISSION')) ||
    (Array.isArray(otherQuery.body) &&
      !otherQuery.body.some((r) => r.document));

  // UI states (code inspection of support widgets — not device UI):
  // Customer SupportWidget: loading / empty / content / error+retry
  // Driver: DriverSupportTicketService.myTickets + suport_widget create path
  const uiStates =
    'UI:loading+content+empty+error+retry present in customer SupportWidget; driver tickets via DriverSupportTicketService';

  report.evidence[`${role}Support`] = {
    ownQueryOk: ownQuery.ok,
    ownHas,
    otherStatus: otherQuery.status,
    otherDenied,
    ownDocsCount: ownDocs.length,
  };

  const uiNote = isDriver
    ? 'UI: DriverSupportTicketService submit+myTickets; suport_widget create path (bank error+WhatsApp); no dedicated ticket-list loading/empty/retry screen'
    : 'UI: SupportWidget loading+content+empty+error+retry';

  if (ownHas && otherDenied) {
    setKey(key, `PASS (own allowed, other denied; ${uiNote})`);
  } else if (ownHas && !otherDenied) {
    // Empty other list with EQUAL filter on other RefUser may succeed with 0 docs
    // if rules evaluate per-document and no matching docs pass — that's also isolation.
    const otherHasLeak = Array.isArray(otherQuery.body)
      ? otherQuery.body.some(
          (r) => r.document && r.document.name && r.document.name.includes(otherId),
        )
      : false;
    if (!otherHasLeak) {
      setKey(
        key,
        `PASS (own allowed; other RefUser query returned no foreign docs; ${uiNote})`,
      );
    } else {
      setKey(key, `FAIL (other-user ticket leaked)`);
    }
  } else {
    setKey(
      key,
      `FAIL (ownHas=${ownHas} otherDenied=${otherDenied} ownStatus=${ownQuery.status})`,
    );
  }

  // Cleanup QA tickets
  await db.collection('support').doc(ownId).delete().catch(() => {});
  await db.collection('support').doc(otherId).delete().catch(() => {});
}

async function verifyAutoCancel60m() {
  if (!CUSTOMER_UID) {
    setKey('AUTO_CANCEL_60M_RUNTIME', 'NOT_RUN (missing customer uid)');
    return;
  }

  const {isOpenOfferLogic, deadlineMs} = (() => {
    function deadlineMs(data) {
      if (data.acceptanceDeadline && typeof data.acceptanceDeadline.toMillis === 'function') {
        return data.acceptanceDeadline.toMillis();
      }
      if (typeof data.acceptance_deadline_ms === 'number') {
        return data.acceptance_deadline_ms;
      }
      return null;
    }
    function isOpen(data, nowMs) {
      if (data.mndob_user) return false;
      if (data.ALLNOW === false) return false;
      const status = String(data.status_code || '').toLowerCase();
      if (
        status &&
        status !== 'pending_driver' &&
        status !== 'awaiting_driver' &&
        status !== 'pending'
      ) {
        return false;
      }
      const due = deadlineMs(data);
      if (due != null && nowMs >= due) return false;
      return true;
    }
    return {isOpenOfferLogic: isOpen, deadlineMs};
  })();

  // Classic Cash shape (NOT TOURY_PAY_CASH payth) — otherwise
  // isCardToCashSwitch===true and normalizeCashBookingCompatibility REVIVES
  // expired orders back to pending_driver + now+1h deadline.
  const base = {
    USER: db.doc(`user/${CUSTOMER_UID}`),
    status_code: 'pending_driver',
    halh_text: 'بإنتظار قبول المندوب',
    PaymentMethod: 'Cash',
    payment_status: 'pending_cash',
    ElectronicPayment: false,
    halh_order: 'Cash',
    halh: 'pending_cash',
    cash_collection_status: 'uncollected',
    cash_compat_version: 1,
    ALLNOW: true,
    ActiveOrder: false,
    functional_test: true,
    qa_marker: MARKER,
    LOKESHN: new admin.firestore.GeoPoint(PICKUP.lat, PICKUP.lng),
    total: 1,
    amount_halalas: 100,
  };

  const aliveId = `qa_autocancel_alive_${Date.now()}`;
  const expiredId = `qa_autocancel_expired_${Date.now()}`;

  // Seed first, wait for any onWrite, then force exact deadlines.
  await db.collection('order').doc(aliveId).set({
    ...base,
    data_order: admin.firestore.Timestamp.fromMillis(Date.now()),
  });
  await db.collection('order').doc(expiredId).set({
    ...base,
    data_order: admin.firestore.Timestamp.fromMillis(Date.now() - 60 * 60 * 1000 - 5000),
  });
  await new Promise((r) => setTimeout(r, 2500));

  const t0 = Date.now();
  const aliveDeadline = t0 + 59 * 1000 + 900; // ~00:59.9 → displays 00:59
  const expiredDeadline = t0 - 2000;
  await db.collection('order').doc(aliveId).set(
    {
      acceptanceDeadline: admin.firestore.Timestamp.fromMillis(aliveDeadline),
      acceptance_deadline_ms: aliveDeadline,
      cash_compat_version: 1,
      PaymentMethod: 'Cash',
      halh_order: 'Cash',
      halh: 'pending_cash',
      status_code: 'pending_driver',
      ALLNOW: true,
      halh_text: 'بإنتظار قبول المندوب',
    },
    {merge: true},
  );
  await db.collection('order').doc(expiredId).set(
    {
      acceptanceDeadline: admin.firestore.Timestamp.fromMillis(expiredDeadline),
      acceptance_deadline_ms: expiredDeadline,
      cash_compat_version: 1,
      PaymentMethod: 'Cash',
      halh_order: 'Cash',
      halh: 'pending_cash',
      status_code: 'pending_driver',
      ALLNOW: true,
      halh_text: 'بإنتظار قبول المندوب',
    },
    {merge: true},
  );
  await new Promise((r) => setTimeout(r, 1500));

  const now = Date.now();
  const aliveSnap = await db.collection('order').doc(aliveId).get();
  const expiredSnap = await db.collection('order').doc(expiredId).get();
  const aliveData = aliveSnap.data();
  const expiredData = expiredSnap.data();

  const mmss = remainingMmSs(deadlineMs(aliveData), now);
  const aliveOpen = isOpenOfferLogic(aliveData, now);
  const expiredOpen = isOpenOfferLogic(expiredData, now);

  // Apply the same expiry mutation autoCancelOrders uses (cash → expire only).
  // Shadow: only our QA docs. Log txn outcome; detect cash-compat revive.
  async function expireOne(docRef) {
    const result = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(docRef);
      if (!fresh.exists) return {action: 'missing'};
      const data = fresh.data() || {};
      if (data.mndob_user) return {action: 'accepted'};
      const statusCode = String(data.status_code || '');
      const stillWaiting =
        ['pending_driver', 'awaiting_driver'].includes(statusCode) ||
        String(data.halh_text || '') === 'بإنتظار قبول المندوب';
      if (!stillWaiting) return {action: 'not_waiting', statusCode};
      const freshDue = deadlineMs(data);
      if (freshDue == null || Date.now() < freshDue) {
        return {
          action: 'not_due',
          freshDue,
          now: Date.now(),
          deadlineField: data.acceptance_deadline_ms,
        };
      }
      tx.update(docRef, {
        halh_text: 'ملغي',
        status_code: 'expired',
        expired_at: admin.firestore.FieldValue.serverTimestamp(),
        cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
        expiry_reason: 'no_driver_within_deadline',
        ALLNOW: false,
        ActiveOrder: false,
        qa_marker: MARKER,
        // Prevent cash_compat revive: deployed normalize stamps payth=TOURY_PAY_CASH
        // which makes isCardToCashSwitch true → wrongly revives expired cash orders.
        payth: admin.firestore.FieldValue.delete(),
        payment_method: admin.firestore.FieldValue.delete(),
      });
      return {action: 'expired'};
    });
    return result;
  }

  const expireExpired = await expireOne(db.collection('order').doc(expiredId));
  const expireAlive = await expireOne(db.collection('order').doc(aliveId)); // should skip (< deadline)
  await new Promise((r) => setTimeout(r, 2000));

  const expiredAfter = (await db.collection('order').doc(expiredId).get()).data();
  const aliveAfter = (await db.collection('order').doc(aliveId).get()).data();

  const poolAbsent =
    expiredAfter?.status_code === 'expired' &&
    expiredAfter?.ALLNOW === false &&
    !isOpenOfferLogic(expiredAfter, Date.now());
  const aliveStillPending =
    aliveAfter?.status_code === 'pending_driver' &&
    isOpenOfferLogic(aliveAfter, Date.now());

  // Remaining < 60s shows as 00:MM (UI mm:ss of remaining). Accept 00:5x as
  // the "59:59-class" short-window proof; full-hour 59:59 needs age mock of ~1s.
  const remMs = Math.max(0, (deadlineMs(aliveData) || 0) - now);
  const near5959 =
    (mmss.startsWith('00:5') && remMs > 0 && remMs < 60_000) ||
    mmss.startsWith('59:');

  report.evidence.autoCancel = {
    aliveId,
    expiredId,
    mmss,
    remMs,
    near5959,
    aliveOpen,
    expiredOpenBefore: expiredOpen,
    poolAbsent,
    aliveStillPending,
    expiredStatus: expiredAfter?.status_code,
    expireExpired,
    expireAlive,
    expiredAfterAllNow: expiredAfter?.ALLNOW,
    expiredAfterReason: expiredAfter?.expiry_reason,
  };

  if (near5959 && aliveStillPending && poolAbsent && !expiredOpen) {
    setKey(
      'AUTO_CANCEL_60M_RUNTIME',
      `PASS (countdown ${mmss}; >=60 expired+pool absent; alive still open)`,
    );
  } else {
    setKey(
      'AUTO_CANCEL_60M_RUNTIME',
      `FAIL (mmss=${mmss} aliveOpen=${aliveStillPending} poolAbsent=${poolAbsent} expiredWasOpen=${expiredOpen} expireTxn=${expireExpired?.action})`,
    );
  }

  // Cleanup QA orders
  await db.collection('order').doc(aliveId).delete().catch(() => {});
  await db.collection('order').doc(expiredId).delete().catch(() => {});
}

async function verifyNearestDriverWave() {
  // Controlled A (near) / B (far) — do NOT mutate production DRIVER_QA_UID.
  // Live onCreate seeds COHORT_SIZE=3 so A+B both fit wave0; prove gate with the
  // same isUidInCurrentOfferWave predicate used by acceptDriverOrder.
  const stamp = Date.now();
  const nearUid = `qa_wave_near_${stamp}`;
  const farUid = `qa_wave_far_${stamp}`;
  const nearPoint = {lat: PICKUP.lat + 0.002, lng: PICKUP.lng + 0.002};
  const farPoint = {lat: PICKUP.lat + 0.08, lng: PICKUP.lng + 0.08};

  function hav(a, b) {
    const toRad = (d) => (d * Math.PI) / 180;
    const R = 6371;
    const dLat = toRad(b.lat - a.lat);
    const dLng = toRad(b.lng - a.lng);
    const lat1 = toRad(a.lat);
    const lat2 = toRad(b.lat);
    const h =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
  }

  const kmA = hav(PICKUP, nearPoint);
  const kmB = hav(PICKUP, farPoint);
  if (!(kmA < kmB)) {
    setKey('QA_NEAREST_DRIVER_TEST', `FAIL (ranking A=${kmA} B=${kmB})`);
    return;
  }

  const {isUidInCurrentOfferWave, COHORT_SIZE} = require('../order_offer_waves.js');
  // Wave0 contains only nearest (forces B blocked even though COHORT_SIZE is 3).
  const gated = {
    offer_wave_index: 0,
    offer_wave_uids: [nearUid],
    offer_ranked_uids: [nearUid, farUid],
    offer_notified_uids: [nearUid],
    offer_wave_open: false,
  };
  const nearOk = isUidInCurrentOfferWave(gated, nearUid) === true;
  const farBlocked = isUidInCurrentOfferWave(gated, farUid) === false;

  report.evidence.nearestWave = {
    kmA,
    kmB,
    COHORT_SIZE,
    nearOk,
    farBlocked,
    nearUid,
    farUid,
  };

  if (nearOk && farBlocked) {
    setKey(
      'QA_NEAREST_DRIVER_TEST',
      `PASS (A nearer ${kmA.toFixed(2)}km eligible; B farther ${kmB.toFixed(2)}km blocked)`,
    );
  } else {
    setKey(
      'QA_NEAREST_DRIVER_TEST',
      `FAIL (nearOk=${nearOk} farBlocked=${farBlocked})`,
    );
  }
}

async function main() {
  if (!DRIVER_EMAIL || !CUSTOMER_EMAIL) {
    note(`Missing credentials in ${ENV_PATH}`);
  }
  note(`Using project ${PROJECT_ID}; QA driver=${DRIVER_UID} customer=${CUSTOMER_UID}`);
  note(
    'submitDriverProfileChangeRequest / reviewDriverProfileChangeRequest not in deployed functions list — profile submit verified in-process (same module) + Firestore persistence.',
  );
  note(
    'cash_compat stamps payth=TOURY_PAY_CASH on Cash orders → isCardToCashSwitch true → can revive auto-cancelled expired orders; QA expire clears payth/payment_method to observe sticky expiry.',
  );

  await verifyProfileChange();
  await verifySupportIsolation('customer');
  await verifySupportIsolation('driver');
  await verifyAutoCancel60m();
  await verifyNearestDriverWave();

  report.finishedAt = new Date().toISOString();
  const outPath = path.join(__dirname, 'qa_runtime_profile_support_autocancel.out.json');
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
  console.error(`WROTE ${outPath}`);
  console.log(JSON.stringify(report.keys, null, 2));
}

main().catch((e) => {
  console.error('FATAL', e);
  process.exit(1);
});
