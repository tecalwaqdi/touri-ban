const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const axios = require("axios");

// Secret Manager bindings require secrets to exist in the project.
// Deploy without TOURY_USE_SM_SECRETS (default) and inject keys via
// `firebase functions:secrets:set` only when ready, or process.env.
// Enable with TOURY_USE_SM_SECRETS=true after all secrets exist.
const useSecretManager =
  String(process.env.TOURY_USE_SM_SECRETS || "").toLowerCase() === "true";

const whatsappRuntime = {
  timeoutSeconds: 60,
  ...(useSecretManager ? {secrets: ["ULTRAMSG_TOKEN"]} : {}),
};

const geocodeRuntime = {
  timeoutSeconds: 60,
  ...(useSecretManager ? {secrets: ["OPENCAGE_API_KEY"]} : {}),
};

const mapsRuntime = {
  timeoutSeconds: 60,
  ...(useSecretManager ? {secrets: ["GOOGLE_MAPS_SERVER_API_KEY"]} : {}),
};

const waslRuntime = {
  timeoutSeconds: 60,
  ...(useSecretManager
    ? {
        secrets: [
          "WASL_DISPATCH_CREDENTIALS",
          "WASL_TRACKING_CREDENTIALS",
        ],
      }
    : {}),
};

function requireTrustedClient(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required.",
    );
  }
  // Default off until App Check is rolled out on customer/driver clients.
  const requireAppCheck =
    String(process.env.INTEGRATIONS_REQUIRE_APP_CHECK || "false") === "true";
  if (requireAppCheck && !process.env.FUNCTIONS_EMULATOR && !context.app) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "App Check verification is required.",
    );
  }
}

function text(value, maxLength = 500) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function secretJson(name) {
  try {
    const parsed = JSON.parse(process.env[name] || "{}");
    if (!parsed || typeof parsed !== "object") throw new Error("invalid");
    return parsed;
  } catch (_) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `${name} is not configured.`,
    );
  }
}

async function enforceMessageRateLimit(uid) {
  const ref = admin.firestore().collection("integration_rate_limits").doc(uid);
  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const now = Date.now();
    const current = snapshot.exists ? snapshot.data() : {};
    const windowStartedAt = Number(current.window_started_at || 0);
    const sameWindow = now - windowStartedAt < 60 * 1000;
    const count = sameWindow ? Number(current.count || 0) : 0;
    if (count >= 10) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Too many message requests. Try again shortly.",
      );
    }
    transaction.set(ref, {
      count: count + 1,
      window_started_at: sameWindow ? windowStartedAt : now,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

exports.sendWhatsAppMessage = functions
  .region("us-central1")
  .runWith(whatsappRuntime)
  .https.onCall(async (data, context) => {
    requireTrustedClient(context);
    const to = text(data.to, 32).replace(/[^0-9+]/g, "");
    const body = text(data.message, 1000);
    if (!/^\+?[1-9]\d{7,15}$/.test(to) || body.length < 1) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid recipient and message are required.",
      );
    }
    const token = process.env.ULTRAMSG_TOKEN || "";
    const instance = text(process.env.ULTRAMSG_INSTANCE || "", 80);
    if (!token || !instance) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Messaging service is not configured.",
      );
    }
    await enforceMessageRateLimit(context.auth.uid);
    const response = await axios.post(
      `https://api.ultramsg.com/${instance}/messages/chat`,
      new URLSearchParams({ token, to, body }),
      {
        headers: { "content-type": "application/x-www-form-urlencoded" },
        timeout: 15000,
        validateStatus: (status) => status >= 200 && status < 300,
      },
    );
    return {
      sent: true,
      id: text(response.data && response.data.id, 120),
    };
  });

exports.reverseGeocode = functions
  .region("us-central1")
  .runWith(geocodeRuntime)
  .https.onCall(async (data, context) => {
    requireTrustedClient(context);
    const latitude = Number(data.latitude);
    const longitude = Number(data.longitude);
    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
        !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Valid coordinates are required.",
      );
    }
    const apiKey = process.env.OPENCAGE_API_KEY || "";
    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Geocoding service is not configured.",
      );
    }
    const language = text(data.language, 12) || "en";
    const countryCode = text(data.countryCode, 2).toLowerCase();
    const response = await axios.get(
      "https://api.opencagedata.com/geocode/v1/json",
      {
        params: {
          q: `${latitude},${longitude}`,
          key: apiKey,
          language,
          no_annotations: 0,
          ...(countryCode ? { countrycode: countryCode } : {}),
        },
        timeout: 15000,
      },
    );
    return response.data;
  });

exports.getRoadRoute = functions
  .region("us-central1")
  .runWith(mapsRuntime)
  .https.onCall(async (data, context) => {
    requireTrustedClient(context);
    if (!Array.isArray(data.points) || data.points.length < 2 ||
        data.points.length > 25) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Between 2 and 25 route points are required.",
      );
    }
    const points = data.points.map((point) => {
      const latitude = Number(point && point.latitude);
      const longitude = Number(point && point.longitude);
      if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
          !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Route coordinates are invalid.",
        );
      }
      return {latitude, longitude};
    });
    const apiKey =
      process.env.GOOGLE_MAPS_SERVER_API_KEY ||
      (() => {
        try {
          const cfg = functions.config();
          return (
            (cfg.google && cfg.google.maps_server_api_key) ||
            (cfg.integrations && cfg.integrations.google_maps_server_api_key) ||
            ""
          );
        } catch (_) {
          return "";
        }
      })();
    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Google Routes service is not configured.",
      );
    }
    const language = text(data.language, 12).replace(/[^A-Za-z_-]/g, "") ||
      "en";
    const region = text(data.region, 2).replace(/[^A-Za-z]/g, "") || "sa";
    const wantOptimal =
      data.routingPreference === "TRAFFIC_AWARE_OPTIMAL" ||
      data.optimal === true;
    const routingPreference = wantOptimal
      ? "TRAFFIC_AWARE_OPTIMAL"
      : "TRAFFIC_AWARE";

    try {
      return await computeGoogleRoutes({
        apiKey,
        points,
        language,
        region,
        routingPreference,
      });
    } catch (routesErr) {
      console.error("getRoadRoute_routes_api_failed", {
        message: String((routesErr && routesErr.message) || routesErr).slice(0, 240),
      });
      // Fallback: legacy Directions (no live traffic) so apps stay usable.
      try {
        const legacy = await computeLegacyDirections({
          apiKey,
          points,
          language,
          region,
        });
        legacy.fallback = true;
        legacy.fallbackReason = "routes_api_unavailable";
        return legacy;
      } catch (legacyErr) {
        console.error("getRoadRoute_directions_fallback_failed", {
          message: String((legacyErr && legacyErr.message) || legacyErr).slice(0, 240),
        });
        throw new functions.https.HttpsError(
          "unavailable",
          "Route service temporarily unavailable.",
        );
      }
    }
  });

function parseDurationSeconds(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, Math.round(value));
  }
  if (typeof value === "string") {
    const m = value.trim().match(/^(\d+(?:\.\d+)?)s$/i);
    if (m) return Math.max(0, Math.round(Number(m[1])));
    const asNum = Number(value);
    if (Number.isFinite(asNum)) return Math.max(0, Math.round(asNum));
  }
  return 0;
}

function latLngBody(point) {
  return {
    location: {
      latLng: {
        latitude: point.latitude,
        longitude: point.longitude,
      },
    },
  };
}

async function computeGoogleRoutes({
  apiKey,
  points,
  language,
  region,
  routingPreference,
}) {
  const body = {
    origin: latLngBody(points[0]),
    destination: latLngBody(points[points.length - 1]),
    travelMode: "DRIVE",
    routingPreference,
    languageCode: language.replace("_", "-"),
    regionCode: region.toUpperCase(),
  };
  if (points.length > 2) {
    body.intermediates = points.slice(1, -1).map(latLngBody);
  }
  // BEST_GUESS traffic model is supported with OPTIMAL + departure time.
  if (routingPreference === "TRAFFIC_AWARE_OPTIMAL") {
    body.trafficModel = "BEST_GUESS";
    body.departureTime = new Date().toISOString();
  }

  const fieldMask = [
    "routes.duration",
    "routes.staticDuration",
    "routes.distanceMeters",
    "routes.polyline.encodedPolyline",
    "routes.legs.duration",
    "routes.legs.staticDuration",
    "routes.legs.distanceMeters",
    "routes.legs.polyline.encodedPolyline",
  ].join(",");

  const response = await axios.post(
    "https://routes.googleapis.com/directions/v2:computeRoutes",
    body,
    {
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": fieldMask,
      },
      timeout: 15000,
    },
  );

  const routes = Array.isArray(response.data && response.data.routes)
    ? response.data.routes
    : [];
  if (!routes.length) {
    throw new Error("routes_api_empty");
  }
  const route = routes[0] || {};
  const distanceMeters = Number(route.distanceMeters || 0);
  const durationSeconds = parseDurationSeconds(route.duration);
  const staticDurationSeconds = parseDurationSeconds(route.staticDuration);
  const encodedPolyline =
    (route.polyline && route.polyline.encodedPolyline) || "";

  const legs = Array.isArray(route.legs)
    ? route.legs.map((leg) => {
      const legEncoded =
        (leg.polyline && leg.polyline.encodedPolyline) || "";
      return {
        distanceMeters: Number(leg.distanceMeters || 0),
        durationSeconds: parseDurationSeconds(leg.duration),
        staticDurationSeconds: parseDurationSeconds(leg.staticDuration),
        encodedPolyline: legEncoded,
      };
    })
    : [];

  // Legacy Directions-shaped payload so older app builds keep decoding polylines.
  const legacyLegs = (legs.length ? legs : [{
    distanceMeters,
    durationSeconds,
    staticDurationSeconds,
    encodedPolyline,
  }]).map((leg) => ({
    distance: {value: leg.distanceMeters, text: `${leg.distanceMeters} m`},
    duration: {value: leg.durationSeconds, text: `${leg.durationSeconds} s`},
    steps: leg.encodedPolyline
      ? [{polyline: {points: leg.encodedPolyline}}]
      : [],
  }));

  return {
    ok: true,
    status: "OK",
    source: "routes_api",
    routingPreference,
    trafficAware: true,
    approximate: false,
    distanceMeters,
    durationSeconds,
    staticDurationSeconds,
    encodedPolyline,
    legs,
    routes: [
      {
        overview_polyline: {points: encodedPolyline},
        legs: legacyLegs,
      },
    ],
  };
}

async function computeLegacyDirections({apiKey, points, language, region}) {
  const coords = points.map((p) => `${p.latitude},${p.longitude}`);
  const response = await axios.get(
    "https://maps.googleapis.com/maps/api/directions/json",
    {
      params: {
        origin: coords[0],
        destination: coords[coords.length - 1],
        ...(coords.length > 2
          ? {waypoints: coords.slice(1, -1).join("|")}
          : {}),
        mode: "driving",
        language,
        region: region.toLowerCase(),
        key: apiKey,
      },
      timeout: 15000,
    },
  );
  const data = response.data || {};
  if (data.status !== "OK" || !Array.isArray(data.routes) || !data.routes[0]) {
    throw new Error(`directions_status_${data.status || "unknown"}`);
  }
  const route = data.routes[0];
  let distanceMeters = 0;
  let durationSeconds = 0;
  const legs = [];
  if (Array.isArray(route.legs)) {
    for (const leg of route.legs) {
      const d = Number((leg.distance && leg.distance.value) || 0);
      const t = Number((leg.duration && leg.duration.value) || 0);
      distanceMeters += d;
      durationSeconds += t;
      legs.push({
        distanceMeters: d,
        durationSeconds: t,
        staticDurationSeconds: t,
        encodedPolyline: "",
      });
    }
  }
  const encodedPolyline =
    (route.overview_polyline && route.overview_polyline.points) || "";

  return {
    ok: true,
    status: "OK",
    source: "directions_legacy",
    routingPreference: "TRAFFIC_UNAWARE",
    trafficAware: false,
    approximate: true,
    distanceMeters,
    durationSeconds,
    staticDurationSeconds: durationSeconds,
    encodedPolyline,
    legs,
    routes: data.routes,
  };
}

const waslActions = {
  operating_company: {
    url: "https://wasl.tga.gov.sa/api/tracking/v1/operating-companies",
    secret: "WASL_TRACKING_CREDENTIALS",
  },
  register_driver: {
    url: "https://wasl.api.elm.sa/api/dispatching/v2/drivers",
    secret: "WASL_DISPATCH_CREDENTIALS",
  },
  register_trip: {
    url: "https://wasl.api.elm.sa/api/dispatching/v2/trips",
    secret: "WASL_DISPATCH_CREDENTIALS",
  },
};

exports.waslRequest = functions
  .region("us-central1")
  .runWith(waslRuntime)
  .https.onCall(async (data, context) => {
    requireTrustedClient(context);
    const action = text(data.action, 40);
    const target = waslActions[action];
    if (!target || !data.payload || typeof data.payload !== "object" ||
        Array.isArray(data.payload)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A supported WASL action and payload are required.",
      );
    }
    const credentials = secretJson(target.secret);
    const headers = {
      "content-type": "application/json",
      "client-id": text(credentials.clientId, 160),
      "app-id": text(credentials.appId, 160),
    };
    if (action === "operating_company") {
      headers["x-api-key"] = text(credentials.apiKey, 300);
    } else {
      headers["app-key"] = text(credentials.appKey, 300);
    }
    if (!headers["client-id"] || !headers["app-id"] ||
        !(headers["x-api-key"] || headers["app-key"])) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "WASL credentials are incomplete.",
      );
    }
    const response = await axios.post(target.url, data.payload, {
      headers,
      timeout: 30000,
    });
    return response.data;
  });
