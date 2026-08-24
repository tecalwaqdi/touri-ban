const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function approvalBlockingReasons(data) {
  const blockers = [];
  const status = data.registration_status || '';
  if (status === 'suspended' || status === 'blocked') blockers.push('account_suspended_or_blocked');
  if (!data.mndob_vill) blockers.push('village_required');
  if (!data.mndob_type_car && !data.car_rev_mndob) blockers.push('vehicle_type_required');
  if (!/^https?:\/\//.test(data.photo_url || '')) blockers.push('profile_photo_required');
  if (!/^https?:\/\//.test(data.img_id_rksh || '')) blockers.push('id_document_required');
  const open = (data.requested_changes || []).filter((e) => e && e.resolved !== true);
  if (open.length) blockers.push('open_requested_changes');
  return blockers;
}

function requireReviewer(context) {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  const claims = context.auth.token || {};
  if (claims.super_admin !== true && claims.country_admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Reviewer role required.');
  }
  return claims;
}

function targetId(data) {
  const id = typeof data?.driverId === 'string' ? data.driverId.trim() : '';
  if (!/^[A-Za-z0-9_-]{6,128}$/.test(id)) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid driverId is required.');
  }
  return id;
}

function sameCountry(claims, driver) {
  if (claims.super_admin === true) return true;
  const target = driver.Rev_dloh_agent || driver.Rev_dolh;
  return typeof claims.country_id === 'string' && target && target.path === claims.country_id;
}

async function reviewDriver(action, data, context) {
  const claims = requireReviewer(context);
  const driverId = targetId(data);
  const reason = typeof data?.reason === 'string' ? data.reason.trim() : '';
  if (action !== 'approved' && reason.length < 3) {
    throw new functions.https.HttpsError('invalid-argument', 'A review reason is required.');
  }
  const ref = db.doc('user/' + driverId);
  let result;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Driver profile not found.');
    const driver = snap.data() || {};
    if (driver.ismndob !== true && driver.ismndom !== true) {
      throw new functions.https.HttpsError('failed-precondition', 'Target is not a driver.');
    }
    if (!sameCountry(claims, driver)) {
      throw new functions.https.HttpsError('permission-denied', 'Driver is outside reviewer scope.');
    }
    if (action === 'approved') {
      const blockers = approvalBlockingReasons(driver);
      if (blockers.length) throw new functions.https.HttpsError('failed-precondition', blockers.join(','));
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    const patch = {
      actev_mndob: action === 'approved',
      ismndob: true,
      ismndom: true,
      ngl: false,
      registration_status: action,
      submission_status: action === 'changes_requested' ? 'changesRequested' : action,
      account_status: action === 'approved' ? 'active' : 'inactive',
      operational_status: 'offline',
      reviewed_at: now,
      reviewed_by: context.auth.uid,
    };
    if (action === 'approved') {
      patch.vehicle_review_status = 'approved';
      patch.document_review_status = 'approved';
      patch.approved_at = now;
      patch.requested_changes = [];
      patch.rejection_reason = admin.firestore.FieldValue.delete();
    } else {
      patch.rejection_reason = reason;
      if (action === 'changes_requested') {
        patch.requested_changes = [{
          section: typeof data.section === 'string' ? data.section : 'general',
          adminMessage: reason,
          createdBy: context.auth.uid,
          resolved: false,
          createdAt: now,
        }];
      }
    }
    tx.update(ref, patch);
    tx.set(db.collection('admin_audit_log').doc(), {
      action: 'driver_' + action,
      target: ref,
      actor: context.auth.uid,
      reason,
      createdAt: now,
      country: driver.Rev_dloh_agent || driver.Rev_dolh || null,
    });
    result = {driverId, action};
  });
  const existing = (await admin.auth().getUser(driverId)).customClaims || {};
  await admin.auth().setCustomUserClaims(driverId, {
    ...existing,
    driver: true,
    driver_active: action === 'approved',
  });
  return {ok: true, ...result, contractVersion: 2};
}

exports.approveDriverRegistration = (data, context) => reviewDriver('approved', data, context);
exports.rejectDriverRegistration = (data, context) => reviewDriver('rejected', data, context);
exports.requestDriverChanges = (data, context) => reviewDriver('changes_requested', data, context);
exports._testApprovalBlockingReasons = approvalBlockingReasons;

function autoActivationBlockingReasons(data) {
  const blockers = [];
  const status = data.registration_status || '';
  if (status === 'suspended' || status === 'blocked' || status === 'rejected') {
    blockers.push('account_not_eligible');
  }
  if (!data.mndob_vill) blockers.push('village_required');
  if (!data.mndob_type_car && !data.car_rev_mndob) blockers.push('vehicle_type_required');
  const open = (data.requested_changes || []).filter((e) => e && e.resolved !== true);
  if (open.length) blockers.push('open_requested_changes');
  return blockers;
}

/** Temporary cash-wave path: driver self-activates after registration submit.
 * Registration V2 (`registration_flow_version === 2`) MUST NOT call this —
 * activation is only via reviewDriverApplicationV2 approve.
 */
exports.autoActivateDriver = async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }
  const driverId = context.auth.uid;
  const ref = db.doc('user/' + driverId);
  let action = 'auto_activated';
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new functions.https.HttpsError('not-found', 'Driver profile not found.');
    }
    const driver = snap.data() || {};
    if (driver.ismndob !== true && driver.ismndom !== true) {
      throw new functions.https.HttpsError('failed-precondition', 'Target is not a driver.');
    }
    // Hard isolation: Registration V2 never auto-activates.
    if (Number(driver.registration_flow_version || 0) === 2) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'AUTO_ACTIVATE_DISABLED_FOR_REGISTRATION_V2',
      );
    }
    const status = driver.registration_status || '';
    if (driver.actev_mndob === true && status === 'approved') {
      action = 'already_active';
      return;
    }
    const blockers = autoActivationBlockingReasons(driver);
    if (blockers.length) {
      throw new functions.https.HttpsError('failed-precondition', blockers.join(','));
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    tx.update(ref, {
      actev_mndob: true,
      ismndob: true,
      ismndom: true,
      ngl: false,
      registration_status: 'approved',
      submission_status: 'approved',
      account_status: 'active',
      operational_status: 'offline',
      vehicle_review_status: 'approved',
      document_review_status: 'approved',
      auto_activated: true,
      approved_at: now,
      reviewed_at: now,
      reviewed_by: 'auto_activate',
      rejection_reason: admin.firestore.FieldValue.delete(),
      requested_changes: [],
    });
  });
  const existing = (await admin.auth().getUser(driverId)).customClaims || {};
  await admin.auth().setCustomUserClaims(driverId, {
    ...existing,
    driver: true,
    driver_active: true,
  });
  return {ok: true, driverId, action, contractVersion: 2};
};
exports._testAutoActivationBlockingReasons = autoActivationBlockingReasons;
