/**
 * Driver Registration V2 — submit + review (server-side).
 * Legacy autoActivateDriver is blocked for registration_flow_version === 2.
 */
'use strict';

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const crypto = require('crypto');
const regNotif = require('./driver_registration_notifications.js');
const docStatus = require('./driver_registration_document_status.js');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const FLOW_VERSION = 2;
const ALLOWED_FIELDS_TO_FIX = new Set([
  'personal_info',
  'vehicle',
  'national_id',
  'vehicle_registration',
  'driver_license',
  'plate',
  'other',
]);

function fail(code, message) {
  throw new functions.https.HttpsError(code, message);
}

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) fail('unauthenticated', 'Sign in required.');
  return context.auth;
}

function requireReviewer(context) {
  const auth = requireAuth(context);
  const claims = auth.token || {};
  if (claims.super_admin !== true && claims.country_admin !== true) {
    fail('permission-denied', 'Reviewer role required.');
  }
  return claims;
}

function isHttps(url) {
  return typeof url === 'string' && /^https:\/\//i.test(url.trim());
}

function docStoragePath(driver, key) {
  const slot = driver[key];
  if (slot && typeof slot === 'object') {
    const p = String(slot.storagePath || '').trim();
    if (p.startsWith('users/') && !p.includes('..')) return p;
  }
  return '';
}

function docAssetPresent(driver, v2Key, legacyKey) {
  if (docStoragePath(driver, v2Key)) return true;
  const url = docUrl(driver, v2Key) || (legacyKey ? driver[legacyKey] : '') || '';
  return isHttps(String(url));
}

function docUrl(driver, key) {
  const slot = driver[key];
  if (slot && typeof slot === 'object' && typeof slot.url === 'string') return slot.url;
  return '';
}

function profilePhotoPresent(driver) {
  return docStatus.profilePhotoOk(driver);
}

/**
 * Phone: required presence on profile (E.164 / digits).
 * OTP / Auth phoneNumber / PhoneAuthCredential: NOT required.
 */
function phonePresent(driver) {
  return docStatus.phonePresent(driver);
}

function approvalBlockingReasonsV2(driver, authUser) {
  const blockers = [];
  if ((driver.registration_flow_version || 0) !== FLOW_VERSION) {
    blockers.push('NOT_REGISTRATION_V2');
  }
  const status = String(driver.registration_status || '');
  if (status === 'suspended' || status === 'blocked') blockers.push('account_suspended_or_blocked');
  if (status !== 'pending_review') blockers.push('NOT_PENDING_REVIEW');
  if (!authUser.emailVerified) blockers.push('EMAIL_NOT_VERIFIED');
  if (!phonePresent(driver)) blockers.push('PHONE_REQUIRED');
  if (!driver.mndob_vill) blockers.push('village_required');
  if (!driver.mndob_type_car && !driver.carRev_mndob && !driver.car_rev_mndob) {
    blockers.push('vehicle_type_required');
  }
  if (!String(driver.NameCar || '').trim()) blockers.push('vehicle_name_required');
  if (!String(driver.ModelCar || '').trim()) blockers.push('vehicle_model_required');
  if (!String(driver.number_lohh_car || driver.normalized_plate || '').trim()) {
    blockers.push('plate_required');
  }
  if (!docAssetPresent(driver, 'doc_national_id', 'img_id_rksh')) {
    blockers.push('national_id_required');
  }
  if (!docAssetPresent(driver, 'doc_vehicle_registration', 'img_id_car')) {
    blockers.push('vehicle_registration_required');
  }
  if (!docAssetPresent(driver, 'doc_driver_license', '')) {
    blockers.push('driver_license_required');
  }
  if (!profilePhotoPresent(driver)) blockers.push('profile_photo_required');
  return blockers;
}

function submitBlockingReasons(driver, authUser) {
  const blockers = [];
  if (!authUser.emailVerified) blockers.push('EMAIL_NOT_VERIFIED');
  if (!phonePresent(driver)) blockers.push('PHONE_REQUIRED');
  if (!driver.mndob_vill) blockers.push('village_required');
  if (!driver.mndob_type_car && !driver.carRev_mndob && !driver.car_rev_mndob) {
    blockers.push('vehicle_type_required');
  }
  if (!String(driver.NameCar || '').trim()) blockers.push('vehicle_name_required');
  if (!String(driver.ModelCar || '').trim()) blockers.push('vehicle_model_required');
  if (!String(driver.number_lohh_car || driver.normalized_plate || '').trim()) {
    blockers.push('plate_required');
  }
  if (!profilePhotoPresent(driver)) blockers.push('profile_photo_required');
  if (!docAssetPresent(driver, 'doc_national_id', 'img_id_rksh')) {
    blockers.push('national_id_required');
  }
  if (!docAssetPresent(driver, 'doc_vehicle_registration', 'img_id_car')) {
    blockers.push('vehicle_registration_required');
  }
  if (!docAssetPresent(driver, 'doc_driver_license', '')) {
    blockers.push('driver_license_required');
  }
  return blockers;
}

function sameCountry(claims, driver) {
  if (claims.super_admin === true) return true;
  const target = driver.Rev_dloh_agent || driver.Rev_dolh;
  return typeof claims.country_id === 'string' && target && target.path === claims.country_id;
}

function idempotencyId(uid, op, key) {
  return crypto.createHash('sha256').update(`${uid}:${op}:${key}`).digest('hex').slice(0, 40);
}

function normalizePlate(raw) {
  return String(raw || '')
    .trim()
    .toUpperCase()
    .replace(/\s|-/g, '');
}

function plateClaimDocPath(plateRaw) {
  if (plateRaw.length < 3) return null;
  const plateHash = crypto
    .createHash('sha256')
    .update(`plate:${plateRaw}`)
    .digest('hex')
    .slice(0, 40);
  return `driver_vehicle_plate_claims/${plateHash}`;
}

/** Returns error code or null if claim allowed for uid. */
function plateClaimConflict(claimData, uid) {
  if (!claimData) return null;
  const owner = String(claimData.driverId || '');
  if (owner && owner !== uid) return 'PLATE_ALREADY_CLAIMED';
  return null;
}

/**
 * In-memory race simulation for tests — serializes tx callbacks.
 */
async function simulatePlateClaimRace({plateRaw, driverA, driverB}) {
  const store = new Map();
  const path = plateClaimDocPath(plateRaw);
  if (!path) {
    return {oneSucceeds: false, secondRejected: false, raceConditionSafe: false};
  }

  let chain = Promise.resolve();
  const attempt = (uid) => {
    const run = chain.then(async () => {
      const conflict = plateClaimConflict(store.get(path), uid);
      if (conflict) return {ok: false, code: conflict};
      store.set(path, {
        driverId: uid,
        normalizedPlate: plateRaw,
        registration_flow_version: FLOW_VERSION,
      });
      return {ok: true};
    });
    chain = run.catch(() => {});
    return run;
  };

  const [a, b] = await Promise.all([attempt(driverA), attempt(driverB)]);
  const successes = [a, b].filter((r) => r.ok).length;
  const rejections = [a, b].filter((r) => r.code === 'PLATE_ALREADY_CLAIMED').length;
  return {
    oneSucceeds: successes === 1,
    secondRejected: rejections === 1,
    raceConditionSafe: successes === 1 && rejections === 1,
    results: {driverA: a, driverB: b},
  };
}

async function readIdempotency(tx, id) {
  const ref = db.doc(`driver_registration_idempotency/${id}`);
  const snap = await tx.get(ref);
  return {ref, snap};
}

/**
 * submitDriverApplicationV2 — authenticated driver submits for review.
 */
exports.submitDriverApplicationV2 = async (data, context) => {
  const auth = requireAuth(context);
  const uid = auth.uid;
  const idempotencyKey = String((data && data.idempotencyKey) || '').trim();
  if (!idempotencyKey) fail('invalid-argument', 'idempotencyKey required');

  let authUser;
  try {
    authUser = await admin.auth().getUser(uid);
  } catch (_) {
    fail('failed-precondition', 'AUTH_USER_MISSING');
  }

  const ref = db.doc(`user/${uid}`);
  const idempDocId = idempotencyId(uid, 'submit', idempotencyKey);
  let result;

  await db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await readIdempotency(tx, idempDocId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      result = {...(idempSnap.data().result || {}), fromIdempotency: true};
      return;
    }

    const snap = await tx.get(ref);
    if (!snap.exists) fail('not-found', 'Driver profile not found.');
    const driver = snap.data() || {};
    if (driver.ismndob !== true && driver.ismndom !== true) {
      fail('failed-precondition', 'Not a driver profile.');
    }

    const status = String(driver.registration_status || 'draft');
    const allowed = new Set(['draft', 'needs_changes', 'rejected', '']);
    if (status === 'pending_review') {
      result = {
        ok: true,
        idempotent: true,
        registration_status: 'pending_review',
        driverId: uid,
      };
      return;
    }
    if (status === 'approved' || status === 'suspended' || status === 'blocked') {
      fail('failed-precondition', `SUBMIT_NOT_ALLOWED_FROM_${status || 'unknown'}`);
    }
    if (!allowed.has(status) && status !== 'changes_requested') {
      fail('failed-precondition', `SUBMIT_NOT_ALLOWED_FROM_${status}`);
    }

    const blockers = submitBlockingReasons(driver, authUser);
    if (blockers.length) {
      fail('failed-precondition', blockers.join(','));
    }

    // V2 plate uniqueness claim (transactional). Legacy duplicates untouched.
    const plateRaw = normalizePlate(
      driver.normalized_plate || driver.number_lohh_car || '',
    );
    let plateClaimRef = null;
    if (plateRaw.length >= 3) {
      const claimPath = plateClaimDocPath(plateRaw);
      plateClaimRef = db.doc(claimPath);
      const claimSnap = await tx.get(plateClaimRef);
      const conflict = plateClaimConflict(
        claimSnap.exists ? claimSnap.data() || {} : null,
        uid,
      );
      if (conflict) fail('already-exists', conflict);
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const attempt = Number(driver.reviewAttemptCount || 0) + 1;
    const reviewVersion = Number(driver.reviewVersion || 0) + 1;
    const isResubmit =
      status === 'needs_changes' || status === 'changes_requested' || status === 'rejected';

    const patch = {
      registration_flow_version: FLOW_VERSION,
      registration_status: 'pending_review',
      submission_status: 'pending_review',
      actev_mndob: false,
      account_status: 'inactive',
      operational_status: 'offline',
      ngl: false,
      auto_activated: false,
      reviewAttemptCount: attempt,
      reviewVersion,
      // Presence only — no OTP / Auth phone link.
      phone_present: phonePresent(driver),
      email_verified_mirror: authUser.emailVerified === true,
      registration_documents_status: docStatus.registrationDocumentsStatus({
        ...driver,
        registration_flow_version: FLOW_VERSION,
      }),
      normalized_plate: plateRaw || driver.normalized_plate || '',
      updatedAt: now,
    };
    if (isResubmit) {
      patch.resubmittedAt = now;
    } else {
      patch.submittedAt = now;
    }

    tx.update(ref, patch);
    if (plateClaimRef && plateRaw) {
      tx.set(
        plateClaimRef,
        {
          driverId: uid,
          normalizedPlate: plateRaw,
          updatedAt: now,
          registration_flow_version: FLOW_VERSION,
        },
        {merge: true},
      );
    }
    tx.set(db.collection('admin_audit_log').doc(), {
      action: isResubmit
        ? 'DRIVER_APPLICATION_RESUBMITTED'
        : 'DRIVER_APPLICATION_SUBMITTED',
      target: ref,
      actor: uid,
      driverId: uid,
      oldStatus: status || 'draft',
      newStatus: 'pending_review',
      createdAt: now,
      metadata: {reviewAttemptCount: attempt, reviewVersion},
    });

    result = {
      ok: true,
      driverId: uid,
      registration_status: 'pending_review',
      reviewAttemptCount: attempt,
      reviewVersion,
      actev_mndob: false,
      isResubmit: !!isResubmit,
      countryPath:
        (driver.Rev_dolh && driver.Rev_dolh.path) ||
        (driver.Rev_dloh_agent && driver.Rev_dloh_agent.path) ||
        null,
    };
    tx.set(idempRef, {
      status: 'completed',
      result,
      completedAt: now,
      uid,
      op: 'submit',
    });
  });

  // Notifications are secondary — never fail submit.
  if (result && result.ok && !result.idempotent && !result.fromIdempotency) {
    try {
      const countryRef = result.countryPath
        ? db.doc(result.countryPath)
        : null;
      await regNotif.notifyAdminsDriverApplication({
        driverId: result.driverId,
        countryRef,
        reviewVersion: result.reviewVersion,
        reviewAttemptCount: result.reviewAttemptCount,
        isResubmit: result.isResubmit === true,
        registrationStatus: 'pending_review',
      });
    } catch (e) {
      console.error('submitDriverApplicationV2 notify failed', e);
    }
  }

  return result;
};

/**
 * reviewDriverApplicationV2 — approve | reject | request_changes
 */
exports.reviewDriverApplicationV2 = async (data, context) => {
  const claims = requireReviewer(context);
  const action = String((data && data.action) || '').trim();
  if (!['approve', 'reject', 'request_changes'].includes(action)) {
    fail('invalid-argument', 'action must be approve|reject|request_changes');
  }
  const driverId = String((data && data.driverId) || '').trim();
  if (!/^[A-Za-z0-9_-]{6,128}$/.test(driverId)) {
    fail('invalid-argument', 'Valid driverId is required.');
  }
  const reason = String((data && data.reason) || '').trim();
  const expectedVersion = data && data.reviewVersion != null
    ? Number(data.reviewVersion)
    : null;
  const idempotencyKey = String((data && data.idempotencyKey) || '').trim();
  if (!idempotencyKey) fail('invalid-argument', 'idempotencyKey required');

  if (action !== 'approve' && reason.length < 3) {
    fail('invalid-argument', 'A review reason is required.');
  }

  let fieldsToFix = [];
  if (action === 'request_changes') {
    const raw = Array.isArray(data.fieldsToFix) ? data.fieldsToFix : [];
    fieldsToFix = raw.map(String).filter((f) => ALLOWED_FIELDS_TO_FIX.has(f));
    if (fieldsToFix.length === 0) fieldsToFix = ['other'];
  }

  const ref = db.doc(`user/${driverId}`);
  const idempDocId = idempotencyId(context.auth.uid, action, idempotencyKey);
  let result;
  let authUser = null;

  if (action === 'approve') {
    try {
      authUser = await admin.auth().getUser(driverId);
    } catch (_) {
      fail('failed-precondition', 'AUTH_USER_MISSING');
    }
  }

  await db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await readIdempotency(tx, idempDocId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      result = {...(idempSnap.data().result || {}), fromIdempotency: true};
      return;
    }

    const snap = await tx.get(ref);
    if (!snap.exists) fail('not-found', 'Driver profile not found.');
    const driver = snap.data() || {};
    if (driver.ismndob !== true && driver.ismndom !== true) {
      fail('failed-precondition', 'Target is not a driver.');
    }
    if (!sameCountry(claims, driver)) {
      fail('permission-denied', 'Driver is outside reviewer scope.');
    }

    const status = String(driver.registration_status || '');
    const reviewVersion = Number(driver.reviewVersion || 0);
    if (expectedVersion != null && expectedVersion !== reviewVersion) {
      fail('aborted', 'DRIVER_REVIEW_STALE');
    }

    if (status !== 'pending_review') {
      fail('failed-precondition', `DRIVER_REVIEW_STALE:${status || 'unknown'}`);
    }

    if ((driver.registration_flow_version || 0) === FLOW_VERSION && action === 'approve') {
      const blockers = approvalBlockingReasonsV2(driver, authUser);
      if (blockers.length) fail('failed-precondition', blockers.join(','));
    } else if (action === 'approve') {
      if (!driver.mndob_vill) fail('failed-precondition', 'village_required');
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const nextVersion = reviewVersion + 1;
    const patch = {
      reviewVersion: nextVersion,
      reviewed_at: now,
      reviewed_by: context.auth.uid,
      updatedAt: now,
      registration_documents_status: docStatus.registrationDocumentsStatus({
        ...driver,
        registration_flow_version: FLOW_VERSION,
      }),
    };

    let newStatus;
    let auditAction;
    if (action === 'approve') {
      newStatus = 'approved';
      auditAction = 'DRIVER_APPLICATION_APPROVED';
      Object.assign(patch, {
        registration_status: 'approved',
        submission_status: 'approved',
        actev_mndob: true,
        account_status: 'active',
        operational_status: 'offline',
        ngl: false,
        approvedAt: now,
        approvedBy: context.auth.uid,
        approved_at: now,
        vehicle_review_status: 'approved',
        document_review_status: 'approved',
        registration_documents_status: 'complete',
        rejectionReason: admin.firestore.FieldValue.delete(),
        rejection_reason: admin.firestore.FieldValue.delete(),
        changeRequestReason: admin.firestore.FieldValue.delete(),
        fieldsToFix: [],
        requested_changes: [],
        auto_activated: false,
      });
    } else if (action === 'reject') {
      newStatus = 'rejected';
      auditAction = 'DRIVER_APPLICATION_REJECTED';
      Object.assign(patch, {
        registration_status: 'rejected',
        submission_status: 'rejected',
        actev_mndob: false,
        account_status: 'inactive',
        rejectionReason: reason,
        rejection_reason: reason,
        rejectedAt: now,
        rejectedBy: context.auth.uid,
      });
    } else {
      newStatus = 'needs_changes';
      auditAction = 'DRIVER_CHANGES_REQUESTED';
      const docFix = fieldsToFix.some((f) =>
        ['national_id', 'vehicle_registration', 'driver_license', 'other'].includes(f),
      );
      Object.assign(patch, {
        registration_status: 'needs_changes',
        submission_status: 'changesRequested',
        actev_mndob: false,
        account_status: 'inactive',
        changeRequestReason: reason,
        changesRequestedAt: now,
        changesRequestedBy: context.auth.uid,
        fieldsToFix,
        rejection_reason: reason,
        registration_documents_status: docFix
          ? 'needs_reupload'
          : docStatus.registrationDocumentsStatus({
              ...driver,
              registration_flow_version: FLOW_VERSION,
            }),
        // Nested array values cannot use FieldValue.serverTimestamp().
        requested_changes: [
          {
            section: fieldsToFix[0] || 'other',
            adminMessage: reason,
            createdBy: context.auth.uid,
            resolved: false,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ],
      });
    }

    tx.update(ref, patch);
    tx.set(db.collection('admin_audit_log').doc(), {
      action: auditAction,
      target: ref,
      actor: context.auth.uid,
      driverId,
      oldStatus: status,
      newStatus,
      reason,
      fieldsToFix,
      createdAt: now,
      metadata: {reviewVersion: nextVersion},
    });

    result = {
      ok: true,
      driverId,
      action,
      registration_status: newStatus,
      reviewVersion: nextVersion,
      actev_mndob: action === 'approve',
    };
    tx.set(idempRef, {
      status: 'completed',
      result,
      completedAt: now,
      uid: context.auth.uid,
      op: action,
    });
  });

  if (action === 'approve' || action === 'reject' || action === 'request_changes') {
    try {
      const existing = (await admin.auth().getUser(driverId)).customClaims || {};
      await admin.auth().setCustomUserClaims(driverId, {
        ...existing,
        driver: true,
        driver_active: action === 'approve',
      });
    } catch (_) {
      /* claims best-effort */
    }
  }

  // Notifications secondary — never rollback review.
  if (result && result.ok && !result.fromIdempotency) {
    try {
      await regNotif.notifyDriverReviewResult({
        driverId,
        action,
        reviewVersion: result.reviewVersion,
        registrationStatus: result.registration_status,
        reason,
      });
    } catch (e) {
      console.error('reviewDriverApplicationV2 notify failed', e);
    }
  }

  return result;
};

exports._testSubmitBlockingReasons = submitBlockingReasons;
exports._testApprovalBlockingReasonsV2 = approvalBlockingReasonsV2;
exports._testNormalizePlate = normalizePlate;
exports._testPlateClaimDocPath = plateClaimDocPath;
exports._testPlateClaimConflict = plateClaimConflict;
exports._testSimulatePlateClaimRace = simulatePlateClaimRace;
exports._testPhonePresent = phonePresent;
exports._testRegistrationDocumentsStatus = docStatus.registrationDocumentsStatus;
exports.driverIsOperationallyApproved = regNotif.driverIsOperationallyApproved;
exports.FLOW_VERSION = FLOW_VERSION;
exports.ALLOWED_FIELDS_TO_FIX = [...ALLOWED_FIELDS_TO_FIX];
