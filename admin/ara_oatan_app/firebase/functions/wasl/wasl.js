"use strict";

/**
 * Wasl dispatching v2.28 (guide date 21/05/2025).
 * Base: https://wasl.api.elm.sa/api/dispatching/v2
 * Mobile clients must not call this host. Flags default off.
 *
 * Location hasCustomer:
 * - false: Saudi driver online/available, or assigned/arriving/arrived
 *   before the passenger trip has started. An offer on screen is not a customer.
 * - true: status is trip_started or trip_in_progress only.
 *
 * Trip timestamps (persisted instants only; never Date.now() at sync):
 * - startedWhen ← created_time | requested_at | createdAt
 * - driverAssignTime ← acceptedAt
 * - driverArrivalTime ← driverArrivedAt
 * - pickupTimestamp ← trip_started_at
 * - dropoffTimestamp ← completedAt
 * - customerWaitingTimeInSeconds ← arrival - assign (>= 0)
 * - durationInSeconds ← dropoff - pickup (>= 1)
 *
 * Distance: actual_distance_meters only, accumulated on the server from GPS
 * samples. Planned, remaining, and route estimates are not a substitute.
 *
 * tripCost: persisted customer gross `total` when currency is SAR. That gross
 * already includes VAT and the platform fee. gateway_amount_sar is used only
 * when it matches that gross. Driver net, commission, wallet, and company due
 * are never sent.
 *
 * Eligibility freshness is a Touri operational cache, not a Wasl v2.28 rule.
 * Expiry dates on the Wasl snapshot stay authoritative. A cached VALID result
 * may be reused for 24h. Pending or invalid may be rechecked after 1h.
 * Admin manual refresh is separate. Stale, expired, or invalid eligibility
 * is never treated as VALID, including when Wasl is down.
 */

const BASE_URL = "https://wasl.api.elm.sa/api/dispatching/v2";
const PLATE_LETTERS = ["ا", "ب", "ح", "د", "ر", "س", "ص", "ط", "ع", "ق", "ك", "ل", "م", "ن", "هـ", "و", "ى"];
const LOCATION_MIN_INTERVAL_MS = 30 * 1000;
const LOCATION_MAX_AGE_MS = 2 * 60 * 1000;
const ELIGIBILITY_TTL_MS = 24 * 60 * 60 * 1000;
const PENDING_RECHECK_MS = 60 * 60 * 1000;

const FLAG_NAMES = [
  "WASL_ENABLED",
  "WASL_DRIVER_REGISTRATION_ENABLED",
  "WASL_ELIGIBILITY_ENABLED",
  "WASL_LOCATION_SYNC_ENABLED",
  "WASL_TRIP_SYNC_ENABLED",
];

function flagOn(name, env = process.env) {
  return String(env[name] || "").toLowerCase() === "true";
}

function flags(env = process.env) {
  const enabled = flagOn("WASL_ENABLED", env);
  return {
    enabled,
    driverRegistration: enabled && flagOn("WASL_DRIVER_REGISTRATION_ENABLED", env),
    eligibility: enabled && flagOn("WASL_ELIGIBILITY_ENABLED", env),
    location: enabled && flagOn("WASL_LOCATION_SYNC_ENABLED", env),
    trip: enabled && flagOn("WASL_TRIP_SYNC_ENABLED", env),
  };
}

function isSaudi(iso2) {
  return String(iso2 || "").trim().toUpperCase() === "SA";
}

function credentialPresence(raw) {
  let parsed = raw;
  if (typeof raw === "string") {
    try {
      parsed = JSON.parse(raw || "{}");
    } catch (_) {
      parsed = {};
    }
  }
  parsed = parsed && typeof parsed === "object" ? parsed : {};
  const clientId = String(parsed.clientId || parsed["client-id"] || "").trim();
  const appId = String(parsed.appId || parsed["app-id"] || "").trim();
  const appKey = String(parsed.appKey || parsed["app-key"] || "").trim();
  return {
    clientIdPresent: clientId.length > 0,
    appIdPresent: appId.length > 0,
    appKeyPresent: appKey.length > 0,
    complete: clientId.length > 0 && appId.length > 0 && appKey.length > 0,
  };
}

function headersFromCredentials(raw) {
  const presence = credentialPresence(raw);
  if (!presence.complete) {
    const error = new Error("CREDENTIALS_MISSING");
    error.code = "CREDENTIALS_MISSING";
    throw error;
  }
  const parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
  return {
    "content-type": "application/json",
    "client-id": String(parsed.clientId || parsed["client-id"]).trim(),
    "app-id": String(parsed.appId || parsed["app-id"]).trim(),
    "app-key": String(parsed.appKey || parsed["app-key"]).trim(),
  };
}

function redact(value) {
  const text = JSON.stringify(value, (key, item) => {
    if (/app-?key|client-?id|app-?id|authorization/i.test(key)) return "[redacted]";
    if (typeof item === "string" && /^\d{10}$/.test(item)) return `${item.slice(0, 2)}******${item.slice(-2)}`;
    if (typeof item === "string" && item.startsWith("+")) return `${item.slice(0, 4)}***`;
    return item;
  });
  return text;
}

function classifyHttp(error) {
  const status = Number(error && (error.status || error.statusCode)) || 0;
  const code = String((error && error.resultCode) || "").toUpperCase();
  if (code.includes("ACTIVITY") || code === "DRIVER_NOT_ALLOWED") return "ACTIVITY_MISMATCH";
  if (status === 401 || status === 403 || code === "UNAUTHORIZED") return "AUTH_FAILURE";
  if (status === 429) return "RATE_LIMIT";
  if (status === 408 || /timeout/i.test(String(error && error.message))) return "TIMEOUT";
  if (!status && error) return "NETWORK";
  if (status >= 500) return "5XX";
  if (status === 400 || code === "BAD_REQUEST" || /duplicate trip|must not|invalid /i.test(code)) {
    return "VALIDATION_REJECTION";
  }
  return status ? "VALIDATION_REJECTION" : "NETWORK";
}

function retryDecision(errorClass, attempt) {
  const transient = ["NETWORK", "TIMEOUT", "5XX", "RATE_LIMIT"].includes(errorClass);
  if (errorClass === "AUTH_FAILURE" || errorClass === "ACTIVITY_MISMATCH") {
    return {retry: false, reason: "stop_retry_storm"};
  }
  if (!transient) return {retry: false, reason: "permanent"};
  if (attempt >= 6) return {retry: false, reason: "attempt_cap"};
  const delayMs = Math.min(60 * 60 * 1000, 30 * 1000 * (2 ** Math.max(0, attempt - 1)));
  return {retry: true, delayMs, sameTripId: true};
}

function waslTripId(orderId) {
  const id = String(orderId || "").trim();
  if (!id) {
    const error = new Error("MISSING_TRIP_ID");
    error.code = "blocked_missing_data";
    throw error;
  }
  return `touri:${id}`;
}

function millis(value) {
  if (value == null || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (value instanceof Date) return value.getTime();
  if (typeof value.toDate === "function") {
    const date = value.toDate();
    return date instanceof Date ? date.getTime() : null;
  }
  if (typeof value === "object" && typeof value._seconds === "number") {
    return value._seconds * 1000;
  }
  if (typeof value === "object" && typeof value.seconds === "number") {
    return value.seconds * 1000;
  }
  const parsed = Date.parse(String(value));
  return Number.isFinite(parsed) ? parsed : null;
}

function ksaTimestamp(ms) {
  if (!Number.isFinite(ms)) return null;
  const shifted = new Date(ms + 3 * 60 * 60 * 1000);
  return shifted.toISOString().replace("Z", "").replace(/(\.\d{3})\d*/, "$1");
}

function firstMillis(source, keys) {
  for (const key of keys) {
    const value = millis(source[key]);
    if (value != null) return value;
  }
  return null;
}

function buildDriverPayload(driver) {
  const missing = [];
  const identity = String(driver.identityNumber || driver.iDHoyhMNDOB || "").replace(/\D/g, "");
  const hijri = String(driver.dateOfBirthHijri || "").trim();
  const gregorian = String(driver.dateOfBirthGregorian || driver.birth_date || "").trim().slice(0, 10);
  const email = String(driver.emailAddress || driver.email || "").trim();
  const mobile = String(driver.mobileNumber || driver.phoneNumber || "").trim();
  const sequence = String(driver.sequenceNumber || "").replace(/\D/g, "");
  const right = String(driver.plateLetterRight || "").trim();
  const middle = String(driver.plateLetterMiddle || "").trim();
  const left = String(driver.plateLetterLeft || "").trim();
  const plateNumber = String(driver.plateNumber || "").replace(/\D/g, "");
  const plateType = String(driver.plateType || "").trim();

  if (!/^\d{10}$/.test(identity)) missing.push("driver.identityNumber");
  if (hijri && !/^\d{4}\/\d{2}\/\d{2}$/.test(hijri)) missing.push("driver.dateOfBirthHijri_format");
  if (gregorian && !/^\d{4}-\d{2}-\d{2}$/.test(gregorian)) missing.push("driver.dateOfBirthGregorian_format");
  if (!hijri && !gregorian) missing.push("driver.dateOfBirth");
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) missing.push("driver.emailAddress");
  if (!/^\+966\d{9}$/.test(mobile)) missing.push("driver.mobileNumber");
  if (!/^\d{9}$/.test(sequence)) missing.push("vehicle.sequenceNumber");
  for (const [name, letter] of [["plateLetterRight", right], ["plateLetterMiddle", middle], ["plateLetterLeft", left]]) {
    if (!PLATE_LETTERS.includes(letter)) missing.push(`vehicle.${name}`);
  }
  if (!/^\d{1,4}$/.test(plateNumber)) missing.push("vehicle.plateNumber");
  const plateTypeNumber = Number(plateType);
  if (!Number.isInteger(plateTypeNumber) || plateTypeNumber < 1 || plateTypeNumber > 11) {
    missing.push("vehicle.plateType");
  }
  if (missing.length) return {ok: false, missing};
  return {
    ok: true,
    body: {
      driver: {
        identityNumber: identity,
        ...(hijri ? {dateOfBirthHijri: hijri} : {}),
        ...(gregorian ? {dateOfBirthGregorian: gregorian} : {}),
        emailAddress: email,
        mobileNumber: mobile,
      },
      vehicle: {
        sequenceNumber: sequence,
        plateLetterRight: right,
        plateLetterMiddle: middle,
        plateLetterLeft: left,
        plateNumber,
        plateType: String(plateTypeNumber),
      },
    },
  };
}

function normalizeRegistration(body) {
  const result = (body && body.result) || {};
  const eligibility = String(result.eligibility || "").toUpperCase();
  return {
    registration_status: eligibility || "PENDING",
    driver_eligibility: eligibility || null,
    eligibility_expiry_date: result.eligibilityExpiryDate || null,
    vehicle_license_expiry_date: result.vehicleLicenseExpiryDate || null,
    rejection_reasons: result.rejectionReasons || [],
    driver_full_name_ar: result.driverFullNameArabic || null,
    driver_full_name_en: result.driverFullNameEnglish || null,
    driver_gender: result.driverGender || null,
    last_result_code: body && body.resultCode || null,
    operational_eligible: eligibility === "VALID",
  };
}

function normalizeEligibility(body) {
  const row = body && body.identityNumber ? body : ((body && body.result) || body || {});
  const vehicles = Array.isArray(row.vehicles) ? row.vehicles : [];
  const vehicle = vehicles[0] || {};
  return {
    driver_eligibility: row.driverEligibility || null,
    vehicle_eligibility: vehicle.vehicleEligibility || vehicle.eligibility || null,
    eligibility_expiry_date: row.eligibilityExpiryDate || null,
    vehicle_eligibility_expiry_date: vehicle.eligibilityExpiryDate || null,
    vehicle_license_expiry_date: vehicle.vehicleLicenseExpiryDate || row.vehicleLicenseExpiryDate || null,
    rejection_reasons: [
      ...(row.driverRejectionReason ? [row.driverRejectionReason] : []),
      ...(Array.isArray(row.rejectionReasons) ? row.rejectionReasons : []),
      ...(vehicle.vehicleRejectionReason ? [vehicle.vehicleRejectionReason] : []),
    ],
    criminal_record_status: row.criminalRecordStatus || null,
    last_result_code: (body && body.resultCode) || null,
  };
}

function expiryStillValid(expiry, now) {
  if (!expiry) return true;
  const ms = millis(expiry);
  if (ms == null) return false;
  return ms > now;
}

function operationalEligible(snapshot, now = Date.now()) {
  if (!snapshot) return false;
  if (snapshot.driver_eligibility !== "VALID") return false;
  if (snapshot.vehicle_eligibility && snapshot.vehicle_eligibility !== "VALID") return false;
  if (snapshot.criminal_record_status === "DONE_RESULT_NOT_OK") return false;
  if (!expiryStillValid(snapshot.eligibility_expiry_date, now)) return false;
  if (!expiryStillValid(snapshot.vehicle_eligibility_expiry_date, now)) return false;
  if (!expiryStillValid(snapshot.vehicle_license_expiry_date, now)) return false;
  return true;
}

function eligibilityFresh(snapshot, now = Date.now()) {
  const checked = millis(snapshot && snapshot.last_checked_at);
  if (checked == null) return false;
  if (!expiryStillValid(snapshot.eligibility_expiry_date, now)) return false;
  if (!expiryStillValid(snapshot.vehicle_eligibility_expiry_date, now)) return false;
  return now - checked <= ELIGIBILITY_TTL_MS;
}

function shouldRefreshEligibility(snapshot, reason, now = Date.now()) {
  if (reason === "admin_manual" || reason === "first_registration") return true;
  if (!snapshot || !snapshot.last_checked_at) return true;
  const age = now - (millis(snapshot.last_checked_at) || 0);
  const status = snapshot.driver_eligibility;
  if (status === "PENDING" || status === "INVALID") return age >= PENDING_RECHECK_MS;
  if (!eligibilityFresh(snapshot, now)) return true;
  const expiry = millis(snapshot.eligibility_expiry_date);
  if (expiry != null && expiry - now <= ELIGIBILITY_TTL_MS) return true;
  return false;
}

function onlineGate({countryIso2, localEligible, wasl, waslAvailable, now = Date.now()}) {
  if (!isSaudi(countryIso2)) {
    return {applied: false, allowed: !!localEligible, code: "NON_SA"};
  }
  if (!localEligible) return {applied: true, allowed: false, code: "LOCAL_INELIGIBLE"};
  if (operationalEligible(wasl, now) && eligibilityFresh(wasl, now)) {
    return {applied: true, allowed: true, code: "WASL_CACHED_VALID"};
  }
  if (!waslAvailable) {
    return {applied: true, allowed: false, code: "WASL_UNAVAILABLE"};
  }
  if (!operationalEligible(wasl, now)) {
    return {applied: true, allowed: false, code: "WASL_NOT_ELIGIBLE"};
  }
  return {applied: true, allowed: false, code: "WASL_STALE"};
}

function hasCustomer(statusCode) {
  const code = String(statusCode || "");
  return code === "trip_started" || code === "trip_in_progress";
}

function locationDecision({countryIso2, online, sample, lastAttemptAt, now = Date.now()}) {
  if (!isSaudi(countryIso2)) return {send: false, code: "NON_SA"};
  if (!online) return {send: false, code: "OFFLINE"};
  const at = millis(sample && sample.updatedWhen);
  if (at == null) return {send: false, code: "STALE_OR_MISSING_GPS_TIME"};
  if (now - at > LOCATION_MAX_AGE_MS) return {send: false, code: "STALE_GPS"};
  if (lastAttemptAt && now - millis(lastAttemptAt) < LOCATION_MIN_INTERVAL_MS) {
    return {send: false, code: "THROTTLED"};
  }
  const lat = Number(sample.latitude);
  const lng = Number(sample.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return {send: false, code: "INVALID_COORDINATES"};
  return {
    send: true,
    body: {
      locations: [{
        driverIdentityNumber: String(sample.driverIdentityNumber),
        vehicleSequenceNumber: String(sample.vehicleSequenceNumber),
        latitude: lat,
        longitude: lng,
        hasCustomer: hasCustomer(sample.statusCode) === true,
        updatedWhen: ksaTimestamp(at),
      }],
    },
  };
}

function grossSar(order) {
  const currency = String((order && (order.currency || order.local_currency)) || "").toUpperCase();
  const total = Number(order && order.total);
  const canonical = currency === "SAR" && Number.isFinite(total) && total > 0 ? total : null;
  if (canonical == null) return null;
  const gateway = Number(order.gateway_amount_sar);
  if (Number.isFinite(gateway) && Math.abs(gateway - canonical) < 0.02) return canonical;
  return canonical;
}

function geoPair(value) {
  if (!value || typeof value !== "object") return null;
  const lat = Number(value.latitude != null ? value.latitude : value._latitude != null ? value._latitude : value.lat);
  const lng = Number(value.longitude != null ? value.longitude : value._longitude != null ? value._longitude : value.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return {lat, lng};
}

function finiteOr(primary, fallback) {
  const value = Number(primary);
  if (Number.isFinite(value)) return value;
  return fallback == null ? null : fallback;
}

/**
 * Maps a persisted Touri order (and the assigned driver) onto the v2.28 trip
 * shape. Actual completed distance is the only distance source. Planned or
 * remaining route meters are ignored. Missing mandatory values stay missing.
 */
function canonicalTripInput(order, driver) {
  const src = order || {};
  const drv = driver || {};
  const input = drv.wasl_input || src.wasl_input || {};
  const origin = geoPair(src.LOKESHN);
  const destination = geoPair(src.destination) || geoPair(src.trip_destination) || geoPair(src.tripDestination);
  const explicitDriver = String(src.driverId || "").replace(/\D/g, "");
  const driverIdentity = /^\d{10}$/.test(explicitDriver)
    ? explicitDriver
    : String(drv.iDHoyhMNDOB || drv.identityNumber || "");
  return {
    id: src.id || src.orderId,
    country_iso2: src.country_iso2 || src.countryIso2 || drv.country_iso2 || null,
    created_time: src.created_time || src.data_order || src.requested_at || src.createdAt || null,
    acceptedAt: src.acceptedAt || null,
    driverArrivedAt: src.driverArrivedAt || null,
    trip_started_at: src.trip_started_at || null,
    completedAt: src.completedAt || null,
    actual_distance_meters: src.actual_distance_finalized_at || src.actual_distance_meters != null
      ? src.actual_distance_meters
      : null,
    gateway_amount_sar: src.gateway_amount_sar,
    total: src.total,
    currency: src.currency || src.local_currency || null,
    originLatitude: finiteOr(src.originLatitude, origin && origin.lat),
    originLongitude: finiteOr(src.originLongitude, origin && origin.lng),
    destinationLatitude: finiteOr(src.destinationLatitude, destination && destination.lat),
    destinationLongitude: finiteOr(src.destinationLongitude, destination && destination.lng),
    sequenceNumber: src.sequenceNumber || input.vehicle_sequence_number || null,
    driverId: driverIdentity,
    customerRating: src.customerRating != null ? src.customerRating : src.customer_rating,
    originCityNameInArabic: src.originCityNameInArabic || src.vill_text || null,
    destinationCityNameInArabic: src.destinationCityNameInArabic || src.destination_city_name_ar || null,
  };
}

function buildTripPayload(order) {
  const missing = [];
  const tripId = waslTripId(order.id || order.orderId);
  const started = firstMillis(order, ["created_time", "requested_at", "createdAt"]);
  const assigned = firstMillis(order, ["acceptedAt"]);
  const arrived = firstMillis(order, ["driverArrivedAt"]);
  const pickup = firstMillis(order, ["trip_started_at"]);
  const dropoff = firstMillis(order, ["completedAt"]);
  const distance = Number(order.actual_distance_meters);
  const cost = grossSar(order);
  let reason = null;
  if (started == null) missing.push("startedWhen");
  if (assigned == null) missing.push("driverAssignTime");
  if (arrived == null) missing.push("driverArrivalTime");
  if (pickup == null) missing.push("pickupTimestamp");
  if (dropoff == null) missing.push("dropoffTimestamp");
  if (!Number.isFinite(distance) || distance < 1) {
    missing.push("distanceInMeters");
    reason = "ACTUAL_DISTANCE_MISSING";
  }
  if (cost == null) missing.push("tripCost");
  const waiting = arrived != null && assigned != null ? Math.round((arrived - assigned) / 1000) : null;
  const duration = dropoff != null && pickup != null ? Math.round((dropoff - pickup) / 1000) : null;
  if (waiting == null || waiting < 0) missing.push("customerWaitingTimeInSeconds");
  if (duration == null || duration < 1) missing.push("durationInSeconds");
  const sequence = String(order.sequenceNumber || "").replace(/\D/g, "");
  const driverId = String(order.driverId || "").replace(/\D/g, "");
  if (!/^\d{9}$/.test(sequence)) missing.push("sequenceNumber");
  if (!/^\d{10}$/.test(driverId)) missing.push("driverId");
  for (const key of ["originLatitude", "originLongitude", "destinationLatitude", "destinationLongitude"]) {
    if (!Number.isFinite(Number(order[key]))) missing.push(key);
  }
  let rating = Number(order.customerRating);
  if (!Number.isFinite(rating)) rating = 0;
  if (rating < 0 || rating > 5) missing.push("customerRating");
  if (missing.length) return {ok: false, status: "blocked_missing_data", missing, reason, tripId};
  return {
    ok: true,
    tripId,
    body: {
      sequenceNumber: sequence,
      driverId,
      tripId,
      distanceInMeters: Math.round(distance),
      durationInSeconds: duration,
      customerRating: rating,
      customerWaitingTimeInSeconds: waiting,
      originCityNameInArabic: order.originCityNameInArabic || null,
      destinationCityNameInArabic: order.destinationCityNameInArabic || null,
      originLatitude: Number(order.originLatitude),
      originLongitude: Number(order.originLongitude),
      destinationLatitude: Number(order.destinationLatitude),
      destinationLongitude: Number(order.destinationLongitude),
      pickupTimestamp: ksaTimestamp(pickup),
      dropoffTimestamp: ksaTimestamp(dropoff),
      startedWhen: ksaTimestamp(started),
      tripCost: cost,
      driverArrivalTime: ksaTimestamp(arrived),
      driverAssignTime: ksaTimestamp(assigned),
    },
  };
}

function buildTripPatch({tripId, customerRating, tripCost, originLatitude, originLongitude, destinationLatitude, destinationLongitude}) {
  if (!tripId) return {ok: false, missing: ["tripId"]};
  const body = {tripId};
  if (customerRating != null) {
    if (customerRating < 0 || customerRating > 5) return {ok: false, missing: ["customerRating"]};
    body.customerRating = customerRating;
  }
  if (tripCost != null) body.tripCost = tripCost;
  if (originLatitude != null) body.originLatitude = originLatitude;
  if (originLongitude != null) body.originLongitude = originLongitude;
  if (destinationLatitude != null) body.destinationLatitude = destinationLatitude;
  if (destinationLongitude != null) body.destinationLongitude = destinationLongitude;
  return {ok: true, body: {trips: [body]}};
}

function readiness(driver) {
  if (!isSaudi(driver.country_iso2 || driver.countryIso2)) {
    return {scope: "NON_SA", missing: [], ready: false};
  }
  const payload = buildDriverPayload({
    identityNumber: driver.iDHoyhMNDOB || driver.identityNumber,
    dateOfBirthHijri: driver.wasl_input && driver.wasl_input.date_of_birth_hijri,
    dateOfBirthGregorian: driver.birth_date,
    email: driver.email,
    mobileNumber: driver.phoneNumber,
    sequenceNumber: driver.wasl_input && driver.wasl_input.vehicle_sequence_number,
    plateLetterRight: driver.wasl_input && driver.wasl_input.plate_letter_right,
    plateLetterMiddle: driver.wasl_input && driver.wasl_input.plate_letter_middle,
    plateLetterLeft: driver.wasl_input && driver.wasl_input.plate_letter_left,
    plateNumber: driver.wasl_input && driver.wasl_input.plate_number,
    plateType: driver.wasl_input && driver.wasl_input.plate_type,
  });
  return {
    scope: "SA",
    local_approval_status: driver.registration_status || null,
    wasl_status: driver.wasl && driver.wasl.registration_status || null,
    missing: payload.ok ? [] : payload.missing,
    ready: payload.ok,
  };
}

function tripReadiness(order) {
  if (!isSaudi(order.country_iso2)) return {scope: "NON_SA"};
  const built = buildTripPayload({id: (order && (order.id || order.orderId)) || "missing-id", ...order});
  if (built.ok) return {scope: "SA", status: "READY_TO_SYNC"};
  if (built.reason === "ACTUAL_DISTANCE_MISSING") {
    return {scope: "SA", status: "BLOCKED_MISSING_ACTUAL_DISTANCE", missing: built.missing};
  }
  return {scope: "SA", status: "BLOCKED_MISSING_FIELDS", missing: built.missing};
}

function payloadFingerprint(body) {
  const crypto = require("crypto");
  return crypto.createHash("sha256").update(JSON.stringify(body || {})).digest("hex");
}

function manualRetryAllowed(previous, built) {
  const prev = previous || {};
  if (prev.last_error_class === "AUTH_FAILURE" || prev.last_error_class === "ACTIVITY_MISMATCH") {
    return {allowed: false, code: "AUTH_FAILURE_STOPPED"};
  }
  if (!built || !built.ok) return {allowed: false, code: "blocked_missing_data"};
  const fingerprint = payloadFingerprint(built.body);
  const permanent = prev.status === "permanent_failure" || prev.last_error_class === "VALIDATION_REJECTION";
  if (permanent && fingerprint === prev.payload_fingerprint) {
    return {allowed: false, code: "UNCHANGED_INVALID_PAYLOAD"};
  }
  return {allowed: true, fingerprint};
}

function failedVehicles(body) {
  const list = body && body.result && body.result.failedVehicles;
  return Array.isArray(list) ? list : [];
}

function buildEligibilityBulk(identityNumbers) {
  const ids = (identityNumbers || []).map((id) => String(id).replace(/\D/g, ""));
  if (!ids.length || ids.some((id) => !/^\d{10}$/.test(id))) {
    return {ok: false, missing: ["driverIds"]};
  }
  return {ok: true, body: {driverIds: ids.map((id) => ({id}))}};
}
function syncState(previous, patch) {
  return {
    status: patch.status,
    attempt_count: patch.attempt_count != null ? patch.attempt_count : ((previous && previous.attempt_count) || 0),
    last_attempt_at: patch.last_attempt_at || null,
    last_result_code: patch.last_result_code || null,
    last_error_class: patch.last_error_class || null,
    synced_at: patch.synced_at || null,
    trip_id: patch.trip_id || (previous && previous.trip_id) || null,
    reason: patch.reason != null ? patch.reason : ((previous && previous.reason) || null),
    payload_fingerprint: patch.payload_fingerprint || (previous && previous.payload_fingerprint) || null,
  };
}

module.exports = {
  BASE_URL,
  FLAG_NAMES,
  PLATE_LETTERS,
  LOCATION_MIN_INTERVAL_MS,
  ELIGIBILITY_TTL_MS,
  flags,
  isSaudi,
  credentialPresence,
  headersFromCredentials,
  redact,
  classifyHttp,
  retryDecision,
  waslTripId,
  ksaTimestamp,
  buildDriverPayload,
  normalizeRegistration,
  normalizeEligibility,
  operationalEligible,
  eligibilityFresh,
  shouldRefreshEligibility,
  onlineGate,
  hasCustomer,
  locationDecision,
  grossSar,
  canonicalTripInput,
  buildTripPayload,
  buildTripPatch,
  readiness,
  tripReadiness,
  payloadFingerprint,
  manualRetryAllowed,
  failedVehicles,
  buildEligibilityBulk,
  syncState,
};
