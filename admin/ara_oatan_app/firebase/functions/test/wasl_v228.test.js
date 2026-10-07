"use strict";

const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const path = require("path");
const wasl = require("../wasl/wasl");

const validDriver = {
  identityNumber: "1234567890",
  dateOfBirthHijri: "1411/01/01",
  dateOfBirthGregorian: "1990-01-01",
  email: "driver@example.com",
  mobileNumber: "+966512345678",
  sequenceNumber: "123456789",
  plateLetterRight: "ا",
  plateLetterMiddle: "ب",
  plateLetterLeft: "ح",
  plateNumber: "1234",
  plateType: "1",
};

test("credentials missing are reported without echoing values", () => {
  const presence = wasl.credentialPresence("{}");
  assert.equal(presence.clientIdPresent, false);
  assert.equal(presence.appIdPresent, false);
  assert.equal(presence.appKeyPresent, false);
  const loaded = wasl.credentialPresence({clientId: "cid", appId: "aid", appKey: "secret-value"});
  assert.equal(loaded.complete, true);
  const redacted = wasl.redact({headers: {"app-key": "secret-value", "client-id": "cid"}});
  assert.equal(redacted.includes("secret-value"), false);
  assert.equal(redacted.includes("[redacted]"), true);
});

test("flags default off", () => {
  const flags = wasl.flags({});
  assert.equal(flags.enabled, false);
  assert.equal(flags.trip, false);
  assert.equal(flags.location, false);
});

test("Saudi registration payload and foreign bypass", () => {
  const built = wasl.buildDriverPayload(validDriver);
  assert.equal(built.ok, true);
  assert.equal(built.body.driver.identityNumber, "1234567890");
  assert.equal(built.body.vehicle.plateType, "1");
  const missing = wasl.buildDriverPayload({...validDriver, sequenceNumber: "12"});
  assert.equal(missing.ok, false);
  assert.ok(missing.missing.includes("vehicle.sequenceNumber"));
  assert.equal(wasl.readiness({country_iso2: "KG"}).scope, "NON_SA");
});

test("registration response stores names gender and rejection without profile overwrite", () => {
  const snapshot = wasl.normalizeRegistration({
    resultCode: "success",
    result: {
      eligibility: "INVALID",
      rejectionReasons: ["DRIVER_REJECTED_MANY_CRIMINAL_RECORD_CHECK"],
      driverFullNameArabic: "اسم",
      driverFullNameEnglish: "Name",
      driverGender: "MALE",
    },
  });
  assert.equal(snapshot.registration_status, "INVALID");
  assert.equal(snapshot.driver_full_name_ar, "اسم");
  assert.deepEqual(snapshot.rejection_reasons, ["DRIVER_REJECTED_MANY_CRIMINAL_RECORD_CHECK"]);
  assert.equal(snapshot.operational_eligible, false);
});

test("eligibility bulk shape, expiry, criminal record, and refresh policy", () => {
  const row = wasl.normalizeEligibility({
    identityNumber: "1234567890",
    driverEligibility: "VALID",
    eligibilityExpiryDate: "2099-01-01T00:00:00.000",
    criminalRecordStatus: "DONE_RESULT_OK",
    vehicles: [{vehicleEligibility: "INVALID", vehicleRejectionReason: "VEHICLE_LICENSE_EXPIRED"}],
  });
  assert.equal(row.vehicle_eligibility, "INVALID");
  assert.equal(row.criminal_record_status, "DONE_RESULT_OK");
  const now = Date.parse("2026-01-01T00:00:00Z");
  const fresh = {driver_eligibility: "VALID", vehicle_eligibility: "VALID", last_checked_at: now - 1000, eligibility_expiry_date: "2099-01-01"};
  assert.equal(wasl.eligibilityFresh(fresh, now), true);
  assert.equal(wasl.shouldRefreshEligibility({...fresh, last_checked_at: now - wasl.ELIGIBILITY_TTL_MS - 1}, "scheduled", now), true);
  assert.equal(wasl.operationalEligible({...fresh, criminal_record_status: "DONE_RESULT_NOT_OK"}, now), false);
});

test("online gate keeps non-SA unchanged and does not invent VALID", () => {
  assert.equal(wasl.onlineGate({countryIso2: "EG", localEligible: true, wasl: null, waslAvailable: false}).code, "NON_SA");
  const now = Date.parse("2026-01-01T00:00:00Z");
  const valid = {driver_eligibility: "VALID", vehicle_eligibility: "VALID", last_checked_at: now - 1000, eligibility_expiry_date: "2099-01-01"};
  assert.equal(wasl.onlineGate({countryIso2: "SA", localEligible: true, wasl: valid, waslAvailable: true, now}).allowed, true);
  assert.equal(wasl.onlineGate({countryIso2: "SA", localEligible: true, wasl: {...valid, driver_eligibility: "INVALID"}, waslAvailable: true, now}).allowed, false);
  assert.equal(wasl.onlineGate({countryIso2: "SA", localEligible: true, wasl: null, waslAvailable: false, now}).code, "WASL_UNAVAILABLE");
});

test("location cadence, hasCustomer, stale GPS, and foreign skip", () => {
  const now = Date.parse("2026-06-01T12:00:00Z");
  const sample = {
    driverIdentityNumber: "1234567890",
    vehicleSequenceNumber: "123456789",
    latitude: 24.7,
    longitude: 46.7,
    statusCode: "driver_assigned",
    updatedWhen: new Date(now - 1000).toISOString(),
  };
  const online = wasl.locationDecision({countryIso2: "SA", online: true, sample, lastAttemptAt: null, now});
  assert.equal(online.send, true);
  assert.equal(online.body.locations[0].hasCustomer, false);
  const riding = wasl.locationDecision({countryIso2: "SA", online: true, sample: {...sample, statusCode: "trip_in_progress"}, now});
  assert.equal(riding.body.locations[0].hasCustomer, true);
  assert.equal(wasl.hasCustomer("pending_driver"), false);
  assert.equal(wasl.locationDecision({countryIso2: "TR", online: true, sample, now}).code, "NON_SA");
  assert.equal(wasl.locationDecision({countryIso2: "SA", online: true, sample: {...sample, updatedWhen: new Date(now - 10 * 60 * 1000).toISOString()}, now}).code, "STALE_GPS");
  assert.equal(wasl.locationDecision({countryIso2: "SA", online: true, sample, lastAttemptAt: now - 5000, now}).code, "THROTTLED");
  assert.equal(wasl.locationDecision({countryIso2: "SA", online: false, sample, now}).code, "OFFLINE");
});

test("trip mapping uses gross SAR, same trip id, and blocks missing actual distance", () => {
  const order = {
    id: "order-1",
    country_iso2: "SA",
    sequenceNumber: "123456789",
    driverId: "1234567890",
    created_time: "2026-06-01T08:00:00Z",
    acceptedAt: "2026-06-01T08:05:00Z",
    driverArrivedAt: "2026-06-01T08:10:00Z",
    trip_started_at: "2026-06-01T08:12:00Z",
    completedAt: "2026-06-01T09:12:00Z",
    actual_distance_meters: 5100,
    gateway_amount_sar: 115.5,
    total: 115.5,
    total_mndob: 40,
    total_app: 15,
    currency: "SAR",
    originLatitude: 24.7,
    originLongitude: 46.7,
    destinationLatitude: 24.8,
    destinationLongitude: 46.8,
  };
  const built = wasl.buildTripPayload(order);
  assert.equal(built.ok, true);
  assert.equal(built.body.tripId, "touri:order-1");
  assert.equal(wasl.waslTripId("order-1"), built.body.tripId);
  assert.equal(built.body.tripCost, 115.5);
  assert.equal(built.body.customerWaitingTimeInSeconds, 300);
  assert.equal(built.body.durationInSeconds, 3600);
  assert.equal(built.body.customerRating, 0);
  const blocked = wasl.buildTripPayload({...order, actual_distance_meters: null, routeDistanceMeters: 9000, plannedDistanceMeters: 9000});
  assert.equal(blocked.ok, false);
  assert.equal(blocked.reason, "ACTUAL_DISTANCE_MISSING");
  assert.ok(blocked.missing.includes("distanceInMeters"));
  assert.equal(blocked.tripId, "touri:order-1");
  assert.equal(wasl.tripReadiness({...order, actual_distance_meters: null, routeDistanceMeters: 9000}).status, "BLOCKED_MISSING_ACTUAL_DISTANCE");
  const mismatch = wasl.buildTripPayload({...order, gateway_amount_sar: 10, total: 115.5});
  assert.equal(mismatch.body.tripCost, 115.5);
  assert.notEqual(mismatch.body.tripCost, order.total_mndob);
  const unchanged = wasl.manualRetryAllowed({
    status: "permanent_failure",
    last_error_class: "VALIDATION_REJECTION",
    payload_fingerprint: wasl.payloadFingerprint(built.body),
  }, built);
  assert.equal(unchanged.allowed, false);
  assert.equal(wasl.manualRetryAllowed({last_error_class: "AUTH_FAILURE"}, built).allowed, false);
  const mapped = wasl.canonicalTripInput({
    id: "order-2",
    data_order: "2026-06-01T08:00:00Z",
    acceptedAt: "2026-06-01T08:05:00Z",
    driverArrivedAt: "2026-06-01T08:10:00Z",
    trip_started_at: "2026-06-01T08:12:00Z",
    completedAt: "2026-06-01T09:12:00Z",
    gateway_amount_sar: 80,
    total: 80,
    total_mndob: 20,
    currency: "SAR",
    LOKESHN: {latitude: 24.7, longitude: 46.7},
    destinationLatitude: 24.8,
    destinationLongitude: 46.8,
    vill_text: "الرياض",
    plannedDistanceMeters: 9000,
    routeDistanceMeters: 9000,
  }, {
    country_iso2: "SA",
    iDHoyhMNDOB: "1234567890",
    wasl_input: {vehicle_sequence_number: "123456789"},
  });
  const fromCanonical = wasl.buildTripPayload(mapped);
  assert.equal(fromCanonical.ok, false);
  assert.ok(fromCanonical.missing.includes("distanceInMeters"));
  assert.equal(fromCanonical.tripId, "touri:order-2");
  const withActual = wasl.buildTripPayload({...mapped, actual_distance_meters: 4200});
  assert.equal(withActual.ok, true);
  assert.equal(withActual.body.distanceInMeters, 4200);
  assert.equal(withActual.body.tripCost, 80);
  assert.equal(withActual.body.driverId, "1234567890");
  assert.equal(withActual.body.sequenceNumber, "123456789");
  assert.equal(withActual.body.originCityNameInArabic, "الرياض");
});

test("trip patch is backend shaped and retry stops on auth failure", () => {
  const patch = wasl.buildTripPatch({tripId: "touri:order-1", customerRating: 4, tripCost: 115.5});
  assert.equal(patch.body.trips[0].tripId, "touri:order-1");
  assert.equal(wasl.retryDecision("NETWORK", 1).retry, true);
  assert.equal(wasl.retryDecision("5XX", 2).sameTripId, true);
  assert.equal(wasl.retryDecision("AUTH_FAILURE", 1).retry, false);
  assert.equal(wasl.retryDecision("VALIDATION_REJECTION", 1).retry, false);
  assert.equal(wasl.classifyHttp({status: 500}).includes("5") || wasl.classifyHttp({status: 500}) === "5XX", true);
});

test("eligibility bulk ids and failed vehicles stay structured", () => {
  const bulk = wasl.buildEligibilityBulk(["1234567890", "1098765432"]);
  assert.equal(bulk.ok, true);
  assert.equal(bulk.body.driverIds.length, 2);
  assert.deepEqual(wasl.failedVehicles({result: {failedVehicles: ["123456789"]}}), ["123456789"]);
  assert.equal(wasl.buildEligibilityBulk(["12"]).ok, false);
});
test("flutter sources do not call production Wasl or embed an app key", () => {
  const roots = [
    path.resolve(__dirname, "../../../lib"),
    path.resolve(__dirname, "../../../../mndob-main/lib"),
    path.resolve(__dirname, "../../../../Admi/lib"),
  ];
  const hits = [];
  function walk(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, {withFileTypes: true})) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith(".dart")) {
        const text = fs.readFileSync(full, "utf8");
        if (text.includes("wasl.api.elm.sa") || text.includes("wasl.tga.gov.sa")) hits.push(full);
        if (/app-key'\s*:\s*'[^']+'/.test(text)) hits.push(`${full}:app-key`);
      }
    }
  }
  for (const root of roots) walk(root);
  assert.deepEqual(hits, []);
});
