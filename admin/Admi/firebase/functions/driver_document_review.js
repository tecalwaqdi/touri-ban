/**
 * Per-document Admin review for Driver Registration V2.
 */
'use strict';

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const crypto = require('crypto');
const regNotif = require('./driver_registration_notifications.js');

const DOC_FIELD_BY_TYPE = {
  nationalId: 'doc_national_id',
  national_id: 'doc_national_id',
  vehicleRegistration: 'doc_vehicle_registration',
  vehicle_registration: 'doc_vehicle_registration',
  driverLicense: 'doc_driver_license_front',
  driver_license: 'doc_driver_license_front',
  driverLicenseFront: 'doc_driver_license_front',
  driver_license_front: 'doc_driver_license_front',
  driverLicenseBack: 'doc_driver_license_back',
  driver_license_back: 'doc_driver_license_back',
  driverLicenseLegacy: 'doc_driver_license',
  vehicleInsurance: 'doc_vehicle_insurance',
  vehicle_insurance: 'doc_vehicle_insurance',
};

const ALLOWED_ACTIONS = new Set(['approve', 'request_replacement', 'reject']);

function requireReviewer(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'AUTHENTICATION_REQUIRED');
  }
  const c = context.auth.token || {};
  if (c.super_admin === true || c.country_admin === true || c.admin === true) {
    return context.auth.uid;
  }
  throw new functions.https.HttpsError('permission-denied', 'REVIEWER_REQUIRED');
}

function fieldToFixCode(documentType) {
  const map = {
    nationalId: 'national_id',
    vehicleRegistration: 'vehicle_registration',
    driverLicense: 'driver_license',
    vehicleInsurance: 'other',
  };
  return map[documentType] || documentType;
}

async function notifyDocumentReview({driverId, documentType, action, reason, version}) {
  const eventId = `drv_doc_${driverId}_${documentType}_v${version}_${action}`;
  const notifRef = admin.firestore().doc(`driver_registration_notifications/${eventId}`);
  const existing = await notifRef.get();
  if (existing.exists) return {ok: true, idempotent: true};

  const type =
    action === 'approve' ? 'driver_document_approved' : 'driver_document_needs_changes';
  await notifRef.set({
    driverId,
    documentType,
    action,
    type,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    deliveryStatus: 'queued',
    reason: String(reason || '').slice(0, 200),
  });

  try {
    const user = await admin.firestore().doc(`user/${driverId}`).get();
    const data = user.data() || {};
    const set = new Set();
    if (data.fcm_token) set.add(String(data.fcm_token));
    (data.fcm_tokens || []).forEach((t) => t && set.add(String(t)));
    if (!set.size) {
      await notifRef.set({deliveryStatus: 'failed', pushError: 'NO_TOKENS'}, {merge: true});
      return {ok: false, stage: 'no_tokens'};
    }
    const locale = regNotif.normalizeLocale(data.preferred_locale);
    const approved = action === 'approve';
    const copyKey = approved
      ? 'driver_document_approved'
      : 'driver_document_needs_changes';
    const {title, body} = regNotif.localize(copyKey, locale, {
      reason: String(reason || '').slice(0, 80),
    });
    await admin.messaging().sendEachForMulticast({
      tokens: [...set],
      notification: {title, body},
      data: {
        type,
        target: 'driver_application_status',
        initialPageName: 'DriverPendingApproval',
        documentType: String(documentType),
      },
    });
    await notifRef.set({deliveryStatus: 'sent'}, {merge: true});
    return {ok: true};
  } catch (e) {
    await notifRef.set(
      {deliveryStatus: 'failed', pushError: String(e && e.message).slice(0, 300)},
      {merge: true},
    );
    return {ok: false, stage: 'push'};
  }
}

async function reviewDriverDocument(data, context) {
  const reviewerUid = requireReviewer(context);
  const driverId = String((data && data.driverId) || '').trim();
  const documentType = String((data && data.documentType) || '').trim();
  const action = String((data && data.action) || '').trim();
  const reason = String((data && data.reason) || '').trim();
  if (!driverId || !documentType || !ALLOWED_ACTIONS.has(action)) {
    throw new functions.https.HttpsError('invalid-argument', 'INVALID_ARGS');
  }
  if ((action === 'reject' || action === 'request_replacement') && !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'REASON_REQUIRED');
  }
  const field = DOC_FIELD_BY_TYPE[documentType];
  if (!field) {
    throw new functions.https.HttpsError('invalid-argument', 'UNKNOWN_DOCUMENT_TYPE');
  }

  const idem =
    String((data && data.idempotencyKey) || '').trim() ||
    crypto
      .createHash('sha256')
      .update(`${reviewerUid}:${driverId}:${documentType}:${action}:${Date.now()}`)
      .digest('hex')
      .slice(0, 40);
  const idemRef = admin.firestore().doc(`driver_review_idempotency/${idem}`);
  const prior = await idemRef.get();
  if (prior.exists) {
    return {ok: true, idempotent: true, ...(prior.data() || {})};
  }

  const userRef = admin.firestore().doc(`user/${driverId}`);
  const snap = await userRef.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError('not-found', 'DRIVER_NOT_FOUND');
  }
  const user = snap.data() || {};
  const slotRaw = user[field];
  const slot = slotRaw && typeof slotRaw === 'object' ? {...slotRaw} : {};
  const prevStatus = String(slot.reviewStatus || slot.status || 'uploaded');
  const version = Number(slot.documentVersion || slot.version || 1);

  let nextStatus = 'approved';
  if (action === 'request_replacement') nextStatus = 'needs_replacement';
  if (action === 'reject') nextStatus = 'rejected';

  slot.reviewStatus = nextStatus;
  slot.status = nextStatus === 'needs_replacement' ? 'needs_reupload' : nextStatus;
  slot.reviewReason = reason || '';
  slot.reviewedAt = admin.firestore.FieldValue.serverTimestamp();
  slot.reviewedBy = reviewerUid;
  slot.documentVersion = version;

  const patch = {
    [field]: slot,
    last_document_review_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (nextStatus === 'needs_replacement' || nextStatus === 'rejected') {
    patch.actev_mndob = false;
    patch.ngl = false;
    patch.registration_status = 'needs_changes';
    patch.submission_status = 'changesRequested';
    patch.rejection_reason = reason;
    patch.fieldsToFix = admin.firestore.FieldValue.arrayUnion(fieldToFixCode(documentType));
  }

  await userRef.set(patch, {merge: true});
  await admin.firestore().collection('driver_document_review_audit').add({
    driverUid: driverId,
    documentType,
    field,
    previousStatus: prevStatus,
    newStatus: nextStatus,
    reviewerUid,
    reason,
    submissionVersion: Number(user.reviewVersion || 0),
    documentVersion: version,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const result = {ok: true, documentType, reviewStatus: nextStatus, driverId};
  await idemRef.set({
    ...result,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await notifyDocumentReview({
    driverId,
    documentType,
    action,
    reason,
    version,
  });
  return result;
}

/** Soft gate: each required slot must be explicitly approved (V2). */
function slotApproved(driver, v2Key, legacyKey) {
  const slot = driver[v2Key];
  if (slot && typeof slot === 'object') {
    const st = String(slot.reviewStatus || slot.status || '').toLowerCase();
    if (st === 'approved') return true;
    if (['rejected', 'needs_replacement', 'needs_reupload', 'pending_review', 'uploaded'].includes(st)) {
      return false;
    }
    const hasAsset = !!(slot.storagePath || slot.url);
    if (hasAsset) return false;
    return false;
  }
  if (legacyKey && typeof driver[legacyKey] === 'string' && driver[legacyKey].trim()) return true;
  return false;
}

function allRequiredDocumentsApproved(driver) {
  const docStatus = require('./driver_registration_document_status.js');
  const base = [
    ['doc_national_id', 'img_id_rksh'],
    ['doc_vehicle_registration', 'img_id_car'],
  ];
  for (const [v2, legacy] of base) {
    if (!slotApproved(driver, v2, legacy)) return false;
  }
  if (docStatus.isApprovedLegacyLicenseOnly(driver)) {
    return slotApproved(driver, 'doc_driver_license', '');
  }
  const backRequired = docStatus.isLicenseBackRequired(null);
  if (!slotApproved(driver, 'doc_driver_license_front', '')) {
    // Legacy-only may still satisfy when no front.
    if (!docStatus.satisfiesLicenseRequirement(driver)) return false;
    return true;
  }
  if (backRequired && !slotApproved(driver, 'doc_driver_license_back', '')) return false;
  return true;
}

function utcDay(d) {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function parseExpiryDate(raw) {
  if (!raw) return null;
  if (raw.toDate) return raw.toDate();
  if (raw instanceof Date) return raw;
  if (typeof raw === 'string') {
    const t = Date.parse(raw);
    return Number.isNaN(t) ? null : new Date(t);
  }
  return null;
}

/**
 * Returns first blocking expired document type, or null.
 * Policy: required + expiryRequired + operationalBlockingOnExpiry.
 * Active trip exemption is caller-side.
 */
function firstBlockingExpiredDocument(driver, countryRequirements, now = new Date()) {
  const reqs = countryRequirements && typeof countryRequirements === 'object'
    ? countryRequirements
    : null;
  // No country config → do not invent Saudi defaults (avoid mass-block).
  if (!reqs) return null;
  const enabled = Object.values(reqs).some((v) => v && typeof v === 'object' && v.enabled === true);
  if (!enabled) return null;

  const types = ['driverLicense', 'vehicleRegistration', 'vehicleInsurance', 'nationalId'];
  for (const type of types) {
    const cfg = reqs[type];
    if (!cfg || cfg.enabled === false) continue;
    if (cfg.required !== true) continue;
    if (cfg.expiryRequired !== true) continue;
    if (cfg.operationalBlockingOnExpiry !== true) continue;
    const field = DOC_FIELD_BY_TYPE[type];
    if (!field) continue;
    const slot = driver[field];
    if (!slot || typeof slot !== 'object') continue;
    const review = String(slot.reviewStatus || slot.status || '').toLowerCase();
    if (review === 'needs_replacement' || review === 'rejected' || review === 'needs_reupload') {
      return type;
    }
    const expiry = parseExpiryDate(slot.expiryDate || slot.expiry_date);
    if (!expiry) {
      return type;
    }
    const today = utcDay(now);
    const expiryDay = utcDay(expiry);
    if (expiryDay < today) return type;
  }
  return null;
}

function buildExpiryEventId({uid, documentType, kind, expiryIso, threshold}) {
  return `driver_document_${kind}:${uid}:${documentType}:${expiryIso}:${threshold}`;
}

exports.reviewDriverDocument = reviewDriverDocument;
exports.allRequiredDocumentsApproved = allRequiredDocumentsApproved;
exports.firstBlockingExpiredDocument = firstBlockingExpiredDocument;
exports.buildExpiryEventId = buildExpiryEventId;
exports.DOC_FIELD_BY_TYPE = DOC_FIELD_BY_TYPE;
