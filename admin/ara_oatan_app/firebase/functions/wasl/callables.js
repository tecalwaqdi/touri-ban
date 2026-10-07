"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const axios = require("axios");
const wasl = require("./wasl");
const actualDistance = require("./actual_distance");

function disabled(reason) {
  return {applied: false, allowed: true, code: reason || "WASL_DISABLED"};
}

async function postWasl(path, body, credentials, method) {
  const headers = wasl.headersFromCredentials(credentials);
  const response = await axios.request({
    url: `${wasl.BASE_URL}${path}`,
    method: method || "post",
    data: body,
    headers,
    timeout: 30000,
    validateStatus: () => true,
  });
  const data = response.data || {};
  if (response.status < 200 || response.status >= 300 || data.success === false) {
    const error = new Error(data.resultCode || `HTTP_${response.status}`);
    error.status = response.status;
    error.resultCode = data.resultCode || null;
    throw error;
  }
  return data;
}

exports.waslOnlineGate = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "AUTHENTICATION_REQUIRED");
  }
  const live = wasl.flags();
  if (!live.enabled || !live.eligibility) return disabled("WASL_DISABLED");
  const snap = await admin.firestore().collection("user").doc(context.auth.uid).get();
  const user = snap.exists ? snap.data() : {};
  const iso = user.country_iso2 || data.countryIso2;
  if (!wasl.isSaudi(iso)) return {applied: false, allowed: true, code: "NON_SA"};
  const gate = wasl.onlineGate({
    countryIso2: "SA",
    localEligible: true,
    wasl: user.wasl || null,
    waslAvailable: false,
  });
  if (gate.allowed) return gate;
  if (!wasl.shouldRefreshEligibility(user.wasl, "stale_online")) {
    return gate;
  }
  return {...gate, code: gate.code === "WASL_UNAVAILABLE" ? "WASL_UNAVAILABLE" : gate.code};
});

exports.waslRefreshDriverEligibility = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "AUTHENTICATION_REQUIRED");
  }
  const token = context.auth.token || {};
  const reviewer = token.super_admin === true || token.admin === true || token.country_admin === true;
  if (!reviewer) {
    throw new functions.https.HttpsError("permission-denied", "REVIEWER_REQUIRED");
  }
  if (!wasl.flags().eligibility) return {ok: false, code: "WASL_DISABLED"};
  const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
  if (!wasl.credentialPresence(credentials).complete) {
    return {ok: false, code: "CREDENTIALS_MISSING"};
  }
  const identity = String(data.identityNumber || "").replace(/\D/g, "");
  if (!/^\d{10}$/.test(identity)) {
    throw new functions.https.HttpsError("invalid-argument", "IDENTITY_REQUIRED");
  }
  const body = await postWasl(`/drivers/eligibility/${identity}`, null, credentials, "get");
  const normalized = wasl.normalizeEligibility(body);
  if (data.driverUid) {
    await admin.firestore().collection("user").doc(String(data.driverUid)).set({
      wasl: {
        ...normalized,
        operational_eligible: wasl.operationalEligible(normalized),
        last_checked_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, {merge: true});
  }
  console.log(wasl.redact({
    operation: "eligibility_specific",
    entity: data.driverUid || null,
    resultCode: body.resultCode || null,
    httpClass: 200,
  }));
  return {ok: true, wasl: normalized};
});

exports.waslRefreshEligibilityBulk = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "AUTHENTICATION_REQUIRED");
  }
  const token = context.auth.token || {};
  if (!(token.super_admin === true || token.admin === true)) {
    throw new functions.https.HttpsError("permission-denied", "ADMIN_REQUIRED");
  }
  if (!wasl.flags().eligibility) return {ok: false, code: "WASL_DISABLED"};
  const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
  if (!wasl.credentialPresence(credentials).complete) return {ok: false, code: "CREDENTIALS_MISSING"};
  const built = wasl.buildEligibilityBulk(data.identityNumbers || []);
  if (!built.ok) return {ok: false, code: "blocked_missing_data", missing: built.missing};
  const body = await postWasl("/drivers/eligibility", built.body, credentials, "post");
  console.log(wasl.redact({operation: "eligibility_bulk", entityCount: built.body.driverIds.length, resultCode: body.resultCode || null, httpClass: 200}));
  return {ok: true, resultCode: body.resultCode || null};
});

exports.waslRegisterSaudiDriver = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "AUTHENTICATION_REQUIRED");
  }
  if (!wasl.flags().driverRegistration) return {ok: false, code: "WASL_DISABLED"};
  const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
  if (!wasl.credentialPresence(credentials).complete) return {ok: false, code: "CREDENTIALS_MISSING"};
  const snap = await admin.firestore().collection("user").doc(context.auth.uid).get();
  const user = snap.data() || {};
  if (!wasl.isSaudi(user.country_iso2)) return {ok: false, code: "NON_SA"};
  const input = user.wasl_input || {};
  const built = wasl.buildDriverPayload({
    identityNumber: user.iDHoyhMNDOB,
    dateOfBirthHijri: input.date_of_birth_hijri,
    dateOfBirthGregorian: user.birth_date,
    email: user.email,
    mobileNumber: user.phoneNumber,
    sequenceNumber: input.vehicle_sequence_number,
    plateLetterRight: input.plate_letter_right,
    plateLetterMiddle: input.plate_letter_middle,
    plateLetterLeft: input.plate_letter_left,
    plateNumber: input.plate_number,
    plateType: input.plate_type,
  });
  if (!built.ok) return {ok: false, code: "blocked_missing_data", missing: built.missing};
  const body = await postWasl("/drivers", built.body, credentials, "post");
  const snapshot = wasl.normalizeRegistration(body);
  await snap.ref.set({
    wasl: {
      ...snapshot,
      last_sync_at: admin.firestore.FieldValue.serverTimestamp(),
      last_checked_at: admin.firestore.FieldValue.serverTimestamp(),
    },
  }, {merge: true});
  return {ok: true, wasl: snapshot};
});

exports.waslSubmitLocationSample = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "AUTHENTICATION_REQUIRED");
  }
  if (!wasl.flags().location) return {ok: false, code: "WASL_DISABLED"};
  const snap = await admin.firestore().collection("user").doc(context.auth.uid).get();
  const user = snap.data() || {};
  const decision = wasl.locationDecision({
    countryIso2: user.country_iso2,
    online: user.is_online === true,
    sample: data || {},
    lastAttemptAt: user.wasl && user.wasl.last_wasl_location_attempt_at,
  });
  if (!decision.send) return {ok: false, code: decision.code};
  const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
  if (!wasl.credentialPresence(credentials).complete) return {ok: false, code: "CREDENTIALS_MISSING"};
  await snap.ref.set({
    wasl: {last_wasl_location_attempt_at: admin.firestore.FieldValue.serverTimestamp()},
  }, {merge: true});
  try {
    const body = await postWasl("/locations", decision.body, credentials, "post");
    const failed = (body.result && body.result.failedVehicles) || [];
    await snap.ref.set({
      wasl: {
        last_wasl_location_success_at: failed.length ? null : admin.firestore.FieldValue.serverTimestamp(),
        last_location_result_code: body.resultCode || null,
        last_failed_vehicles: failed,
      },
    }, {merge: true});
    return {ok: failed.length === 0, failedVehicles: failed, resultCode: body.resultCode || null};
  } catch (error) {
    return {ok: false, code: wasl.classifyHttp(error)};
  }
});

function isCompletedOrder(order) {
  const code = String((order && (order.status_code || order.status)) || "");
  return code === "completed" || code === "trip_completed";
}

async function countryIso(order) {
  const direct = String((order && (order.country_iso2 || order.countryIso2)) || "").trim().toUpperCase();
  if (direct) return direct;
  const ref = order && order.Rev_dolh;
  if (!ref) return "";
  const snap = typeof ref.get === "function"
    ? await ref.get()
    : await admin.firestore().doc(ref.path).get();
  if (!snap.exists) return "";
  const data = snap.data() || {};
  return String(data.iso_code || data.country_iso2 || "").trim().toUpperCase();
}

async function assignedDriver(order) {
  const ref = order && order.mndob_user;
  if (!ref) return {};
  const snap = typeof ref.get === "function"
    ? await ref.get()
    : await admin.firestore().doc(ref.path).get();
  return snap.exists ? (snap.data() || {}) : {};
}

async function syncTripDocument(snap, {force = false} = {}) {
  const orderId = snap.id;
  const order = snap.data() || {};
  const iso = await countryIso(order);
  if (!wasl.isSaudi(iso)) return {ok: false, code: "NON_SA"};
  const previous = order.wasl_trip_sync || {};
  if (!force && previous.status === "success") return {ok: true, code: "ALREADY_SYNCED", tripId: previous.trip_id};
  if (previous.last_error_class === "AUTH_FAILURE" || previous.last_error_class === "ACTIVITY_MISMATCH") {
    return {ok: false, code: "AUTH_FAILURE_STOPPED", tripId: previous.trip_id || null};
  }
  const driver = await assignedDriver(order);
  const built = wasl.buildTripPayload(wasl.canonicalTripInput({id: orderId, ...order, country_iso2: iso}, driver));
  const tripId = built.tripId;
  if (!built.ok) {
    await snap.ref.set({
      wasl_trip_sync: wasl.syncState(previous, {
        status: "blocked_missing_data",
        trip_id: tripId,
        reason: built.reason || null,
        last_error_class: "VALIDATION_REJECTION",
        last_attempt_at: new Date().toISOString(),
      }),
    }, {merge: true});
    await admin.firestore().collection("wasl_outbox").doc(orderId).set({due: false, trip_id: tripId}, {merge: true});
    return {ok: false, code: "blocked_missing_data", reason: built.reason || null, missing: built.missing, tripId};
  }
  const retryGate = wasl.manualRetryAllowed(previous, built);
  if (!retryGate.allowed) {
    return {ok: false, code: retryGate.code, tripId};
  }
  const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
  if (!wasl.credentialPresence(credentials).complete) {
    return {ok: false, code: "CREDENTIALS_MISSING", tripId};
  }
  const attempt = Number(previous.attempt_count || 0) + 1;
  try {
    const body = await postWasl("/trips", built.body, credentials, "post");
    await snap.ref.set({
      wasl_trip_sync: wasl.syncState(previous, {
        status: "success",
        attempt_count: attempt,
        last_attempt_at: new Date().toISOString(),
        last_result_code: body.resultCode || "success",
        synced_at: new Date().toISOString(),
        trip_id: tripId,
        reason: null,
        payload_fingerprint: retryGate.fingerprint,
      }),
    }, {merge: true});
    await admin.firestore().collection("wasl_outbox").doc(orderId).set({due: false, trip_id: tripId}, {merge: true});
    console.log(wasl.redact({operation: "trip_register", entity: orderId, resultCode: body.resultCode || null, httpClass: 200, attempt}));
    return {ok: true, tripId, resultCode: body.resultCode || null};
  } catch (error) {
    const errorClass = wasl.classifyHttp(error);
    const decision = wasl.retryDecision(errorClass, attempt);
    const nextAt = decision.retry ? new Date(Date.now() + decision.delayMs).toISOString() : null;
    await snap.ref.set({
      wasl_trip_sync: wasl.syncState(previous, {
        status: decision.retry ? "retryable_failure" : "permanent_failure",
        attempt_count: attempt,
        last_attempt_at: new Date().toISOString(),
        last_result_code: error.resultCode || null,
        last_error_class: errorClass,
        trip_id: tripId,
        payload_fingerprint: retryGate.fingerprint,
      }),
    }, {merge: true});
    await admin.firestore().collection("wasl_outbox").doc(orderId).set({
      due: decision.retry === true,
      next_attempt_at: nextAt,
      trip_id: tripId,
      last_error_class: errorClass,
    }, {merge: true});
    console.log(wasl.redact({operation: "trip_register", entity: orderId, resultCode: error.resultCode || null, httpClass: error.status || null, attempt, errorClass}));
    return {ok: false, code: errorClass, tripId, retry: decision.retry};
  }
}

exports.waslRetryTripSync = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "AUTHENTICATION_REQUIRED");
  }
  const token = context.auth.token || {};
  if (!(token.super_admin === true || token.admin === true)) {
    throw new functions.https.HttpsError("permission-denied", "ADMIN_REQUIRED");
  }
  if (!wasl.flags().trip) return {ok: false, code: "WASL_DISABLED"};
  const orderId = String(data.orderId || "");
  const snap = await admin.firestore().collection("order").doc(orderId).get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "ORDER_NOT_FOUND");
  }
  return syncTripDocument(snap, {force: true});
});

async function applyActualDistance(change) {
  const decision = actualDistance.decide(change.before.data(), change.after.data(), Date.now());
  if (!decision.write) return change.after;
  await change.after.ref.set(decision.patch, {merge: true});
  return change.after.ref.get();
}

exports.onOrderUpdated = async (change) => {
  const current = await applyActualDistance(change);
  if (!wasl.flags().trip) return null;
  const before = change.before.data() || {};
  const after = current.data();
  const completedNow = !isCompletedOrder(before) && isCompletedOrder(after);
  if (completedNow) {
    return syncTripDocument(current, {force: false});
  }
  const previousSync = after.wasl_trip_sync || {};
  const beforeRating = Number(before.customerRating != null ? before.customerRating : before.customer_rating);
  const afterRating = Number(after.customerRating != null ? after.customerRating : after.customer_rating);
  if (previousSync.status !== "success" || !previousSync.trip_id) return null;
  if (!Number.isFinite(afterRating) || afterRating === beforeRating) return null;
  const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
  if (!wasl.credentialPresence(credentials).complete) return {ok: false, code: "CREDENTIALS_MISSING"};
  const patch = wasl.buildTripPatch({tripId: previousSync.trip_id, customerRating: afterRating});
  if (!patch.ok) return {ok: false, code: "blocked_missing_data"};
  const body = await postWasl("/trips", patch.body, credentials, "patch");
  console.log(wasl.redact({operation: "trip_patch", entity: change.after.id, resultCode: body.resultCode || null, httpClass: 200}));
  return {ok: true, tripId: previousSync.trip_id};
};

function locationMoved(before, after) {
  const a = before && before.loceshnMndobNow;
  const b = after && after.loceshnMndobNow;
  if (!b) return false;
  const aLat = a && (a.latitude != null ? a.latitude : a._latitude);
  const bLat = b.latitude != null ? b.latitude : b._latitude;
  const aLng = a && (a.longitude != null ? a.longitude : a._longitude);
  const bLng = b.longitude != null ? b.longitude : b._longitude;
  return aLat !== bLat || aLng !== bLng;
}

exports.onUserUpdated = async (change) => {
  const live = wasl.flags();
  if (!live.location && !live.driverRegistration) return null;
  const before = change.before.data() || {};
  const after = change.after.data() || {};
  if (live.driverRegistration && !wasl.isSaudi(after.country_iso2)) {
    // Foreign profiles never enter Wasl registration.
  } else if (live.driverRegistration && wasl.isSaudi(after.country_iso2)) {
    const hadInput = before.wasl_input && before.wasl_input.vehicle_sequence_number;
    const hasInput = after.wasl_input && after.wasl_input.vehicle_sequence_number;
    const already = after.wasl && after.wasl.registration_status;
    if (!hadInput && hasInput && !already) {
      const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
      if (wasl.credentialPresence(credentials).complete) {
        const built = wasl.buildDriverPayload({
          identityNumber: after.iDHoyhMNDOB,
          dateOfBirthHijri: after.wasl_input.date_of_birth_hijri,
          dateOfBirthGregorian: after.birth_date,
          email: after.email,
          mobileNumber: after.phoneNumber,
          sequenceNumber: after.wasl_input.vehicle_sequence_number,
          plateLetterRight: after.wasl_input.plate_letter_right,
          plateLetterMiddle: after.wasl_input.plate_letter_middle,
          plateLetterLeft: after.wasl_input.plate_letter_left,
          plateNumber: after.wasl_input.plate_number,
          plateType: after.wasl_input.plate_type,
        });
        if (built.ok) {
          try {
            const body = await postWasl("/drivers", built.body, credentials, "post");
            const snapshot = wasl.normalizeRegistration(body);
            await change.after.ref.set({
              wasl: {
                ...snapshot,
                operational_eligible: wasl.operationalEligible(snapshot),
                last_sync_at: admin.firestore.FieldValue.serverTimestamp(),
                last_checked_at: admin.firestore.FieldValue.serverTimestamp(),
              },
            }, {merge: true});
          } catch (error) {
            console.log(wasl.redact({operation: "driver_register", entity: change.after.id, httpClass: error.status || null, errorClass: wasl.classifyHttp(error)}));
          }
        }
      }
    }
  }
  if (!live.location || !locationMoved(before, after)) return null;
  if (!wasl.isSaudi(after.country_iso2)) return null;
  if (after.is_online !== true && after.ngl !== true) return null;
  const point = after.loceshnMndobNow || {};
  const input = after.wasl_input || {};
  let statusCode = "";
  if (after.active_order_id) {
    const orderSnap = await admin.firestore().collection("order").doc(String(after.active_order_id)).get();
    if (orderSnap.exists) statusCode = (orderSnap.data() || {}).status_code || "";
  }
  const decision = wasl.locationDecision({
    countryIso2: after.country_iso2,
    online: true,
    lastAttemptAt: after.wasl && after.wasl.last_wasl_location_attempt_at,
    sample: {
      updatedWhen: after.last_seen_at || after.gps_updated_at,
      latitude: point.latitude != null ? point.latitude : point._latitude,
      longitude: point.longitude != null ? point.longitude : point._longitude,
      driverIdentityNumber: after.iDHoyhMNDOB,
      vehicleSequenceNumber: input.vehicle_sequence_number,
      statusCode,
    },
  });
  if (!decision.send) return {ok: false, code: decision.code};
  const identity = String(after.iDHoyhMNDOB || "").replace(/\D/g, "");
  const sequence = String(input.vehicle_sequence_number || "").replace(/\D/g, "");
  if (!/^\d{10}$/.test(identity) || !/^\d{9}$/.test(sequence)) {
    return {ok: false, code: "blocked_missing_data"};
  }
  const credentials = process.env.WASL_DISPATCH_CREDENTIALS;
  if (!wasl.credentialPresence(credentials).complete) return {ok: false, code: "CREDENTIALS_MISSING"};
  await change.after.ref.set({
    wasl: {last_wasl_location_attempt_at: admin.firestore.FieldValue.serverTimestamp()},
  }, {merge: true});
  try {
    const body = await postWasl("/locations", decision.body, credentials, "post");
    const failed = wasl.failedVehicles(body);
    await change.after.ref.set({
      wasl: {
        last_wasl_location_success_at: failed.length ? null : admin.firestore.FieldValue.serverTimestamp(),
        last_location_result_code: body.resultCode || null,
        last_failed_vehicles: failed,
      },
    }, {merge: true});
    console.log(wasl.redact({operation: "location", entity: change.after.id, resultCode: body.resultCode || null, httpClass: 200}));
    return {ok: failed.length === 0};
  } catch (error) {
    console.log(wasl.redact({operation: "location", entity: change.after.id, httpClass: error.status || null, errorClass: wasl.classifyHttp(error)}));
    return {ok: false, code: wasl.classifyHttp(error)};
  }
};

exports.waslTripOutbox = async () => {
  if (!wasl.flags().trip) return null;
  const due = await admin.firestore().collection("wasl_outbox").where("due", "==", true).limit(20).get();
  for (const doc of due.docs) {
    const row = doc.data() || {};
    if (row.last_error_class === "AUTH_FAILURE" || row.last_error_class === "ACTIVITY_MISMATCH") continue;
    const nextAt = Date.parse(row.next_attempt_at || "");
    if (Number.isFinite(nextAt) && nextAt > Date.now()) continue;
    const orderSnap = await admin.firestore().collection("order").doc(doc.id).get();
    if (!orderSnap.exists) {
      await doc.ref.set({due: false}, {merge: true});
      continue;
    }
    await syncTripDocument(orderSnap, {force: false});
  }
  return null;
};
