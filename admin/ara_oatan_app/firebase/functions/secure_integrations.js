const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const axios = require("axios");

const runtime = {
  timeoutSeconds: 60,
  secrets: [
    "ULTRAMSG_TOKEN",
    "OPENCAGE_API_KEY",
    "GOOGLE_MAPS_SERVER_API_KEY",
    "WASL_DISPATCH_CREDENTIALS",
    "WASL_TRACKING_CREDENTIALS",
  ],
};

function requireTrustedClient(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required.",
    );
  }
  const requireAppCheck =
    String(process.env.INTEGRATIONS_REQUIRE_APP_CHECK || "true") !== "false";
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
  .runWith(runtime)
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
  .runWith(runtime)
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
  .runWith(runtime)
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
      return `${latitude},${longitude}`;
    });
    const apiKey = process.env.GOOGLE_MAPS_SERVER_API_KEY || "";
    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Google Routes service is not configured.",
      );
    }
    const language = text(data.language, 12).replace(/[^A-Za-z_-]/g, "") ||
      "en";
    const region = text(data.region, 2).replace(/[^A-Za-z]/g, "") || "sa";
    const response = await axios.get(
      "https://maps.googleapis.com/maps/api/directions/json",
      {
        params: {
          origin: points[0],
          destination: points[points.length - 1],
          ...(points.length > 2
            ? { waypoints: points.slice(1, -1).join("|") }
            : {}),
          mode: "driving",
          language,
          region: region.toLowerCase(),
          key: apiKey,
        },
        timeout: 15000,
      },
    );
    return response.data;
  });

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
  .runWith(runtime)
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
