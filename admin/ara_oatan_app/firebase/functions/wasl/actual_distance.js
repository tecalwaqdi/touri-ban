"use strict";

/**
 * Canonical actual traveled distance for a passenger trip.
 *
 * Source: successive `mapuser` points already written by the driver GPS
 * pipeline (the same updates as loceshnMndobNow / tracking). This is geodesic
 * segment length, not a booked route.
 *
 * Touri quality thresholds (operational, not a Wasl requirement):
 * - sample age <= 120s
 * - timestamp must move forward
 * - movement under 8m is treated as duplicate/jitter and ignored
 * - segment speed above 55 m/s (~198 km/h) is an impossible jump and ignored
 *   so highway travel around 140 km/h is kept
 *
 * Accumulation starts on the first accepted sample at trip_started /
 * trip_in_progress while tracking_phase is to_destination. Driver-to-pickup
 * is excluded. returnToPickup adds returning_to_pickup only. at_destination
 * and returned_to_pickup refresh the anchor and add nothing. Completion
 * freezes actual_distance_meters and actual_distance_finalized_at.
 * A client-supplied number is never accepted as the total.
 */

const MAX_SAMPLE_AGE_MS = 2 * 60 * 1000;
const MIN_MOVEMENT_METERS = 8;
const MAX_SPEED_MPS = 55;

function millis(value) {
  if (value == null || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (value instanceof Date) return value.getTime();
  if (typeof value.toDate === "function") {
    const date = value.toDate();
    return date instanceof Date ? date.getTime() : null;
  }
  if (typeof value === "object" && typeof value.seconds === "number") return value.seconds * 1000;
  if (typeof value === "object" && typeof value._seconds === "number") return value._seconds * 1000;
  const parsed = Date.parse(String(value));
  return Number.isFinite(parsed) ? parsed : null;
}

function geoPair(value) {
  if (!value || typeof value !== "object") return null;
  const lat = Number(value.latitude != null ? value.latitude : value._latitude != null ? value._latitude : value.lat);
  const lng = Number(value.longitude != null ? value.longitude : value._longitude != null ? value._longitude : value.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return {lat, lng};
}

function haversineMeters(a, b) {
  const r = 6371000;
  const dLat = (b.lat - a.lat) * Math.PI / 180;
  const dLng = (b.lng - a.lng) * Math.PI / 180;
  const lat1 = a.lat * Math.PI / 180;
  const lat2 = b.lat * Math.PI / 180;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

function isCompleted(order) {
  const code = String((order && (order.status_code || order.status)) || "");
  return code === "completed" || code === "trip_completed";
}

function passengerStarted(order) {
  const code = String((order && order.status_code) || "");
  return code === "trip_started" || code === "trip_in_progress";
}

function storedMeters(order) {
  const value = Number(order && order.actual_distance_meters);
  return Number.isFinite(value) && value >= 0 ? value : 0;
}

function anchorOf(order) {
  const lat = Number(order && order.actual_distance_anchor_lat);
  const lng = Number(order && order.actual_distance_anchor_lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return {lat, lng};
}

function phaseCounts(order) {
  const phase = String((order && order.tracking_phase) || "");
  const back = order && order.returnToPickup === true;
  if (phase === "to_destination" || phase === "") return "count";
  if (phase === "returning_to_pickup" && back) return "count";
  if (phase === "at_destination" || phase === "returned_to_pickup") return "hold";
  return "ignore";
}

function sampleOf(order) {
  return {
    point: geoPair(order && order.mapuser),
    at: millis(order && (order.gps_updated_at || order.timestamp)),
  };
}

/**
 * Pure step from the previous order snapshot to the next GPS write.
 * `next` may be a synthetic in-progress view of a completion write.
 */
function step(previous, next, now) {
  const prev = previous || {};
  const current = next || {};
  if (prev.actual_distance_finalized_at) {
    return {write: false, reason: "FINALIZED"};
  }
  if (!passengerStarted(current)) {
    return {write: false, reason: "NOT_PASSENGER_TRIP"};
  }
  const startedAt = millis(current.trip_started_at || prev.trip_started_at);
  const sample = sampleOf(current);
  if (!sample.point || sample.at == null) return {write: false, reason: "MISSING_SAMPLE"};
  if (startedAt != null && sample.at < startedAt) return {write: false, reason: "PRE_PICKUP"};
  if (now - sample.at > MAX_SAMPLE_AGE_MS || sample.at > now + 5000) {
    return {write: false, reason: "STALE"};
  }
  const lastAt = millis(prev.actual_distance_last_at);
  if (lastAt != null && sample.at <= lastAt) return {write: false, reason: "NON_MONOTONIC"};
  const mode = phaseCounts(current);
  if (mode === "ignore") return {write: false, reason: "PHASE_EXCLUDED"};
  const anchor = anchorOf(prev);
  if (!anchor || lastAt == null) {
    return {
      write: true,
      added: 0,
      reason: "ANCHOR",
      patch: {
        actual_distance_meters: storedMeters(prev),
        actual_distance_anchor_lat: sample.point.lat,
        actual_distance_anchor_lng: sample.point.lng,
        actual_distance_last_at: new Date(sample.at).toISOString(),
      },
    };
  }
  const meters = haversineMeters(anchor, sample.point);
  const elapsed = (sample.at - lastAt) / 1000;
  if (meters < MIN_MOVEMENT_METERS) return {write: false, reason: "DUPLICATE"};
  if (!(elapsed > 0) || meters / elapsed > MAX_SPEED_MPS) {
    return {write: false, reason: "IMPOSSIBLE_JUMP"};
  }
  if (mode === "hold") {
    return {
      write: true,
      added: 0,
      reason: "HOLD_ANCHOR",
      patch: {
        actual_distance_meters: storedMeters(prev),
        actual_distance_anchor_lat: sample.point.lat,
        actual_distance_anchor_lng: sample.point.lng,
        actual_distance_last_at: new Date(sample.at).toISOString(),
      },
    };
  }
  const total = Math.round((storedMeters(prev) + meters) * 1000) / 1000;
  return {
    write: true,
    added: meters,
    reason: "SEGMENT",
    patch: {
      actual_distance_meters: total,
      actual_distance_anchor_lat: sample.point.lat,
      actual_distance_anchor_lng: sample.point.lng,
      actual_distance_last_at: new Date(sample.at).toISOString(),
    },
  };
}

function decide(before, after, now = Date.now()) {
  const prev = before || {};
  const next = after || {};
  if (prev.actual_distance_finalized_at || next.actual_distance_finalized_at) {
    const frozen = prev.actual_distance_finalized_at || next.actual_distance_finalized_at;
    const frozenMeters = Number.isFinite(Number(prev.actual_distance_meters))
      ? Number(prev.actual_distance_meters)
      : Number(next.actual_distance_meters);
    if (Number(next.actual_distance_meters) !== frozenMeters || !next.actual_distance_finalized_at) {
      return {
        write: true,
        reason: "FINALIZED",
        patch: {
          actual_distance_meters: frozenMeters,
          actual_distance_finalized_at: frozen,
        },
      };
    }
    return {write: false, reason: "FINALIZED"};
  }
  const completing = isCompleted(next) && !isCompleted(prev);
  const viewed = completing
    ? {...next, status_code: prev.status_code, tracking_phase: prev.tracking_phase, trip_started_at: next.trip_started_at || prev.trip_started_at}
    : next;
  const moved = step(prev, viewed, now);
  if (completing || (isCompleted(next) && !next.actual_distance_finalized_at)) {
    const meters = moved.patch && moved.patch.actual_distance_meters != null
      ? moved.patch.actual_distance_meters
      : storedMeters(prev);
    return {
      write: true,
      reason: "FINALIZE",
      patch: {
        ...(moved.patch || {}),
        actual_distance_meters: meters,
        actual_distance_finalized_at: new Date(now).toISOString(),
      },
    };
  }
  if (!moved.write && Number(next.actual_distance_meters) !== Number(prev.actual_distance_meters || 0) && next.actual_distance_meters != null) {
    return {
      write: true,
      reason: "REVERT_CLIENT_DISTANCE",
      patch: {actual_distance_meters: storedMeters(prev)},
    };
  }
  return moved;
}

module.exports = {
  MAX_SAMPLE_AGE_MS,
  MIN_MOVEMENT_METERS,
  MAX_SPEED_MPS,
  haversineMeters,
  step,
  decide,
};
