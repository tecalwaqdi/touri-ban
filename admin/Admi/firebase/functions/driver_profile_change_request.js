/**
 * Approved-driver profile data change requests.
 * Creates a CHANGE REQUEST only — never overwrites the live approved profile
 * until Admin / Country Agent explicitly approves.
 */
"use strict";

const admin = require("firebase-admin");
const functions = require("firebase-functions/v1");
const regNotif = require("./driver_registration_notifications.js");

const COLLECTION = "driver_data_change_requests";
const ALLOWED_SECTIONS = new Set([
  "personal_info",
  "vehicle",
  "national_id",
  "vehicle_registration",
  "driver_license",
  "plate",
  "location",
  "documents",
  "other",
]);

/** Whitelist of profile fields that may be applied on approve. */
const ALLOWED_APPLY_KEYS = new Set([
  "display_name",
  "ID_hoyh_MNDOB",
  "birth_date",
  "photo_url",
  "photo_storage_path",
  "NameCar",
  "vehicle_make",
  "ModelCar",
  "vehicle_color",
  "seat_count",
  "text_type_car_mndob",
  "number_lohh_car",
  "normalized_plate",
  "doc_national_id",
  "doc_vehicle_registration",
  "doc_driver_license",
  "doc_driver_license_front",
  "doc_driver_license_back",
  "img_id_rksh",
  "img_id_car",
  "region_display",
  "city_display",
  "mndob_vill_text",
  "mdenh_aml",
]);

const FORBIDDEN_APPLY_KEYS = new Set([
  "uid",
  "ismndob",
  "ismndom",
  "actev_mndob",
  "ngl",
  "registration_status",
  "submission_status",
  "wallet",
  "walletId",
  "wallet_id",
  "walletBalance",
  "currentBalance",
  "total_app",
  "finance",
  "super_admin",
  "isAdmin",
  "IsAdmin",
  "approvedAt",
  "approvedBy",
  "approved_at",
  "rejectedAt",
  "rejectedBy",
  "requested_changes",
  "fieldsToFix",
  "reviewVersion",
  "pending_data_change_request_id",
  "pending_data_change_request_at",
]);

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required.",
    );
  }
  return context.auth.uid;
}

function isPanelReviewer(token) {
  if (!token || typeof token !== "object") return false;
  return (
    token.super_admin === true ||
    token.country_admin === true ||
    token.agent === true ||
    token.IsAdmin === true ||
    token.isAdmin === true
  );
}

function sanitizeProposedValues(raw) {
  const out = {};
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return out;
  for (const [k, v] of Object.entries(raw)) {
    if (FORBIDDEN_APPLY_KEYS.has(k)) continue;
    if (ALLOWED_SECTIONS.has(k)) continue;
    if (!ALLOWED_APPLY_KEYS.has(k)) continue;
    if (v == null) continue;
    if (typeof v === "string") {
      const t = v.trim();
      if (!t) continue;
      out[k] = t;
    } else if (typeof v === "number" && Number.isFinite(v)) {
      out[k] = v;
    } else if (typeof v === "boolean") {
      out[k] = v;
    }
  }
  return out;
}

/** Merge document upload URLs into proposed field values. */
function mergeDocumentUploads(proposed, documentUploads) {
  const out = { ...proposed };
  if (!documentUploads || typeof documentUploads !== "object") return out;
  for (const [field, meta] of Object.entries(documentUploads)) {
    if (!ALLOWED_APPLY_KEYS.has(field)) continue;
    if (!meta || typeof meta !== "object") continue;
    const url = String(meta.url || meta.previewUrl || "").trim();
    const storagePath = String(meta.storagePath || "").trim();
    if (url) out[field] = url;
    if (storagePath && field === "photo_url") {
      out.photo_storage_path = storagePath;
    }
  }
  return out;
}

function buildCurrentSnapshot(userData, keys) {
  const out = {};
  for (const k of keys) {
    if (Object.prototype.hasOwnProperty.call(userData, k)) {
      out[k] = userData[k];
    }
  }
  return out;
}

exports.submitDriverProfileChangeRequest = async (data, context) => {
  const uid = requireAuth(context);
  const db = admin.firestore();
  const userRef = db.collection("user").doc(uid);
  const snap = await userRef.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "Driver profile not found.");
  }
  const user = snap.data() || {};
  const status = String(user.registration_status || "").toLowerCase();
  if (status === "needs_changes" || status === "changes_requested") {
    return {
      ok: true,
      reuseExistingCorrection: true,
      success: true,
    };
  }
  const approved = user.actev_mndob === true || status === "approved";
  if (!approved || user.ismndob !== true) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Only approved drivers can request data changes.",
    );
  }

  // One pending request at a time.
  const existingPendingId = String(
    user.pending_data_change_request_id || "",
  ).trim();
  if (existingPendingId) {
    const existing = await db.collection(COLLECTION).doc(existingPendingId).get();
    if (existing.exists && existing.data()?.status === "pending") {
      return {
        ok: true,
        success: true,
        requestId: existingPendingId,
        alreadyPending: true,
      };
    }
  }

  const sections = Array.isArray(data?.sections)
    ? data.sections
        .map((s) => String(s || "").trim())
        .filter((s) => ALLOWED_SECTIONS.has(s))
    : [];
  if (sections.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Select at least one field to change.",
    );
  }

  const reason = String(data?.reason || "").trim();
  if (reason.length < 3) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Please describe what you want to change.",
    );
  }

  // Accept proposedValues (preferred) or legacy requestedFields with real keys.
  let proposed = sanitizeProposedValues(
    data?.proposedValues || data?.requestedFields || {},
  );
  proposed = mergeDocumentUploads(proposed, data?.documentUploads);
  if (Object.keys(proposed).length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Provide the new values or upload the documents you want updated.",
    );
  }

  const ref = db.collection(COLLECTION).doc();
  const payload = {
    id: ref.id,
    driverUid: uid,
    driverDisplayName: String(user.display_name || user.email || uid),
    driverPhone: String(user.phone_number || user.phone_n || ""),
    countryRef: user.Rev_dolh || null,
    status: "pending",
    sections,
    // Keep both for older readers; apply uses proposedValues.
    proposedValues: proposed,
    requestedFields: proposed,
    documentUploads: data?.documentUploads || null,
    reason,
    requestedBy: uid,
    requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    reviewedBy: null,
    reviewedAt: null,
    decision: null,
    changedFields: Object.keys(proposed),
    currentSnapshot: buildCurrentSnapshot(user, Object.keys(proposed)),
  };

  await ref.set(payload);
  await userRef.set(
    {
      pending_data_change_request_id: ref.id,
      pending_data_change_request_at:
        admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // Non-blocking admin notify.
  try {
    await regNotif.notifyAdminsDriverDataChangeRequest({
      driverId: uid,
      requestId: ref.id,
      countryRef: user.Rev_dolh || null,
      sections,
      reason,
    });
  } catch (e) {
    console.warn("notifyAdminsDriverDataChangeRequest failed", e);
  }

  return { ok: true, success: true, requestId: ref.id };
};

exports.reviewDriverProfileChangeRequest = async (data, context) => {
  const reviewerUid = requireAuth(context);
  if (!isPanelReviewer(context.auth.token)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin or Country Agent required.",
    );
  }
  const requestId = String(data?.requestId || "").trim();
  const decision = String(data?.decision || data?.action || "")
    .trim()
    .toLowerCase();
  if (!requestId) {
    throw new functions.https.HttpsError("invalid-argument", "requestId required.");
  }
  if (decision !== "approve" && decision !== "reject") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "decision must be approve or reject.",
    );
  }

  const db = admin.firestore();
  const reqRef = db.collection(COLLECTION).doc(requestId);
  const reqSnap = await reqRef.get();
  if (!reqSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Change request not found.");
  }
  const req = reqSnap.data() || {};
  if (req.status !== "pending") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Change request is not pending.",
    );
  }
  const driverUid = String(req.driverUid || "");
  if (!driverUid) {
    throw new functions.https.HttpsError("failed-precondition", "Missing driverUid.");
  }

  const reason = String(data?.reason || "").trim();
  const batch = db.batch();

  if (decision === "reject") {
    batch.update(reqRef, {
      status: "rejected",
      decision: "rejected",
      reviewedBy: reviewerUid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewReason: reason,
    });
    batch.set(
      db.collection("user").doc(driverUid),
      {
        pending_data_change_request_id: admin.firestore.FieldValue.delete(),
        pending_data_change_request_at: admin.firestore.FieldValue.delete(),
      },
      { merge: true },
    );
    await batch.commit();
    try {
      await regNotif.notifyDriverDataChangeResult({
        driverId: driverUid,
        requestId,
        decision: "rejected",
        reason,
      });
    } catch (_) {}
    return { ok: true, success: true, decision: "rejected" };
  }

  // Approve: prefer explicit applyFields from Admin; else proposedValues.
  const applySource =
    data?.applyFields && typeof data.applyFields === "object"
      ? data.applyFields
      : req.proposedValues || req.requestedFields || {};
  const apply = sanitizeProposedValues(applySource);
  if (Object.keys(apply).length === 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "No applyable field values on this request.",
    );
  }

  // Plate normalize when plate changes.
  if (typeof apply.number_lohh_car === "string") {
    apply.normalized_plate = String(apply.number_lohh_car)
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, "");
  }

  batch.update(reqRef, {
    status: "approved",
    decision: "approved",
    reviewedBy: reviewerUid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    reviewReason: reason,
    appliedFields: Object.keys(apply),
  });

  const userPatch = {
    ...apply,
    pending_data_change_request_id: admin.firestore.FieldValue.delete(),
    pending_data_change_request_at: admin.firestore.FieldValue.delete(),
    profile_update_source: "admin_approved_data_change",
    profile_updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  batch.set(db.collection("user").doc(driverUid), userPatch, { merge: true });
  await batch.commit();

  try {
    await regNotif.notifyDriverDataChangeResult({
      driverId: driverUid,
      requestId,
      decision: "approved",
      reason,
    });
  } catch (_) {}

  return {
    ok: true,
    success: true,
    decision: "approved",
    appliedFields: Object.keys(apply),
  };
};

exports.ALLOWED_APPLY_KEYS = ALLOWED_APPLY_KEYS;
exports.sanitizeProposedValues = sanitizeProposedValues;
