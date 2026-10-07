"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const distance = require("../wasl/actual_distance");
const wasl = require("../wasl/wasl");

const start = Date.parse("2026-06-01T08:12:00.000Z");

function north(point, meters) {
  return {
    lat: point.lat + (meters / 6371000) * (180 / Math.PI),
    lng: point.lng,
  };
}

function orderAt(point, at, extra) {
  return {
    status_code: "trip_in_progress",
    tracking_phase: "to_destination",
    returnToPickup: false,
    trip_started_at: new Date(start).toISOString(),
    timestamp: new Date(at).toISOString(),
    mapuser: {latitude: point.lat, longitude: point.lng},
    routeDistanceMeters: 9000,
    plannedDistanceMeters: 9000,
    ...extra,
  };
}

test("actual distance starts at trip start and ignores pre-pickup and estimates", () => {
  const origin = {lat: 24.7, lng: 46.7};
  const pre = distance.decide(
    {},
    orderAt(north(origin, 400), start - 60000, {status_code: "driver_arriving", tracking_phase: "to_pickup"}),
    start,
  );
  assert.equal(pre.write, false);
  assert.equal(pre.reason, "NOT_PASSENGER_TRIP");

  const anchor = distance.step({}, orderAt(origin, start + 1000), start + 5000);
  assert.equal(anchor.reason, "ANCHOR");
  assert.equal(anchor.added, 0);
  assert.equal(anchor.patch.actual_distance_meters, 0);

  const second = north(origin, 120);
  const third = north(origin, 250);
  const seg1 = distance.step(anchor.patch, orderAt(second, start + 15000), start + 20000);
  const seg2 = distance.step(seg1.patch, orderAt(third, start + 30000), start + 35000);
  assert.equal(seg1.reason, "SEGMENT");
  assert.equal(seg2.reason, "SEGMENT");
  assert.ok(seg2.patch.actual_distance_meters > 200);
  assert.ok(seg2.patch.actual_distance_meters < 300);
  assert.notEqual(seg2.patch.actual_distance_meters, 9000);
});

test("duplicate, stale, and impossible jump are ignored; highway speed is kept", () => {
  const origin = {lat: 24.71, lng: 46.71};
  const now = start + 60000;
  const anchored = {
    status_code: "trip_in_progress",
    tracking_phase: "to_destination",
    trip_started_at: new Date(start).toISOString(),
    actual_distance_meters: 100,
    actual_distance_anchor_lat: origin.lat,
    actual_distance_anchor_lng: origin.lng,
    actual_distance_last_at: new Date(start + 10000).toISOString(),
  };
  const duplicate = distance.step(anchored, orderAt(north(origin, 3), start + 20000), now);
  assert.equal(duplicate.reason, "DUPLICATE");
  const stale = distance.step(anchored, orderAt(north(origin, 100), start + 20000), start + 200000);
  assert.equal(stale.reason, "STALE");
  const jump = distance.step(anchored, orderAt(north(origin, 8000), start + 12000), now);
  assert.equal(jump.reason, "IMPOSSIBLE_JUMP");
  const highway = distance.step(anchored, orderAt(north(origin, 1000), start + 30000), now);
  assert.equal(highway.reason, "SEGMENT");
  assert.ok(highway.added > 900 && highway.added < 1100);
});

test("returnToPickup includes the return leg and a one-way trip stops at the destination", () => {
  const origin = {lat: 24.72, lng: 46.72};
  const base = {
    actual_distance_meters: 1500,
    actual_distance_anchor_lat: origin.lat,
    actual_distance_anchor_lng: origin.lng,
    actual_distance_last_at: new Date(start + 10000).toISOString(),
    trip_started_at: new Date(start).toISOString(),
    status_code: "trip_in_progress",
  };
  const stopped = distance.step(
    {...base, returnToPickup: false},
    orderAt(north(origin, 200), start + 25000, {tracking_phase: "at_destination", returnToPickup: false}),
    start + 30000,
  );
  assert.equal(stopped.reason, "HOLD_ANCHOR");
  assert.equal(stopped.added, 0);
  assert.equal(stopped.patch.actual_distance_meters, 1500);

  const back = distance.step(
    {...base, returnToPickup: true},
    orderAt(north(origin, 200), start + 25000, {tracking_phase: "returning_to_pickup", returnToPickup: true}),
    start + 30000,
  );
  assert.equal(back.reason, "SEGMENT");
  assert.ok(back.added > 150);
});

test("completion freezes actual distance and later samples cannot change it", () => {
  const origin = {lat: 24.73, lng: 46.73};
  const before = {
    status_code: "trip_in_progress",
    tracking_phase: "to_destination",
    returnToPickup: false,
    trip_started_at: new Date(start).toISOString(),
    timestamp: new Date(start + 10000).toISOString(),
    mapuser: {latitude: origin.lat, longitude: origin.lng},
    actual_distance_meters: 3200,
    actual_distance_anchor_lat: origin.lat,
    actual_distance_anchor_lng: origin.lng,
    actual_distance_last_at: new Date(start + 10000).toISOString(),
  };
  const done = distance.decide(before, {
    ...orderAt(north(origin, 100), start + 20000),
    status_code: "completed",
    tracking_phase: "completed",
    actual_distance_meters: 99999,
  }, start + 25000);
  assert.equal(done.reason, "FINALIZE");
  assert.ok(done.patch.actual_distance_meters > 3200);
  assert.ok(done.patch.actual_distance_meters < 3400);
  assert.ok(done.patch.actual_distance_finalized_at);
  const later = distance.decide(
    {...before, ...done.patch, status_code: "completed"},
    {...orderAt(north(origin, 500), start + 40000), status_code: "completed", actual_distance_meters: 1},
    start + 45000,
  );
  assert.equal(later.reason, "FINALIZED");
  assert.equal(later.patch.actual_distance_meters, done.patch.actual_distance_meters);
});

test("readiness summaries count Saudi candidates without printing records", () => {
  const {summarizeDrivers, summarizeTrips} = require("../scripts/wasl_readiness_readonly");
  const drivers = summarizeDrivers([
    {country_iso2: "KG", phoneNumber: "+996555000000"},
    {
      country_iso2: "SA",
      registration_status: "approved",
      iDHoyhMNDOB: "1234567890",
      birth_date: "1990-01-01",
      phoneNumber: "+966555000000",
      email: "driver@example.com",
      wasl_input: {
        vehicle_sequence_number: "123456789",
        plate_letter_right: "ا",
        plate_letter_middle: "ب",
        plate_letter_left: "ح",
        plate_number: "1234",
        plate_type: 1,
      },
    },
  ]);
  assert.equal(drivers.saDrivers, 1);
  assert.equal(drivers.waslDataComplete, 1);
  const trips = summarizeTrips([
    {id: "order-sa", country_iso2: "SA", routeDistanceMeters: 5000},
    {country_iso2: "EG", actual_distance_meters: 10},
  ]);
  assert.equal(trips.saTrips, 1);
  assert.equal(trips.blockedMissingActualDistance, 1);
  assert.equal(trips.ready, 0);
});

test("Wasl trip mapping uses finalized actual meters and blocks a route estimate", () => {
  const order = {
    id: "order-distance",
    country_iso2: "SA",
    currency: "SAR",
    total: 90,
    gateway_amount_sar: 90,
    total_mndob: 30,
    sequenceNumber: "123456789",
    driverId: "1234567890",
    created_time: "2026-06-01T08:00:00Z",
    acceptedAt: "2026-06-01T08:05:00Z",
    driverArrivedAt: "2026-06-01T08:10:00Z",
    trip_started_at: "2026-06-01T08:12:00Z",
    completedAt: "2026-06-01T09:12:00Z",
    originLatitude: 24.7,
    originLongitude: 46.7,
    destinationLatitude: 24.8,
    destinationLongitude: 46.8,
    actual_distance_meters: 4321,
    routeDistanceMeters: 9000,
  };
  const built = wasl.buildTripPayload(order);
  assert.equal(built.ok, true);
  assert.equal(built.body.distanceInMeters, 4321);
  assert.equal(built.body.tripCost, 90);
  assert.equal(built.body.customerWaitingTimeInSeconds, 300);
  assert.equal(built.body.durationInSeconds, 3600);
  const missingTime = wasl.buildTripPayload({...order, completedAt: null});
  assert.equal(missingTime.ok, false);
  assert.ok(missingTime.missing.includes("dropoffTimestamp"));
  const estimated = wasl.buildTripPayload({...order, actual_distance_meters: null});
  assert.equal(estimated.reason, "ACTUAL_DISTANCE_MISSING");
  assert.equal(wasl.tripReadiness(estimated && {...order, actual_distance_meters: null}).status, "BLOCKED_MISSING_ACTUAL_DISTANCE");
});
