const crypto = require("crypto");
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const axios = require("axios");

const PROD_IDENTITY =
  "https://api-gateway.ngenius-payments.com/identity/auth/access-token";
const PROD_GATEWAY_BASE =
  "https://api-gateway.ngenius-payments.com/transactions/outlets";
const SANDBOX_IDENTITY =
  "https://api-gateway.sandbox.ngenius-payments.com/identity/auth/access-token";
const SANDBOX_GATEWAY_BASE =
  "https://api-gateway.sandbox.ngenius-payments.com/transactions/outlets";
const DEFAULT_RETURN_URL =
  "https://tutorial-multi-language-70gx4j.web.app/payment-return.html";
const PAYMENT_SESSIONS = "payment_sessions";
const WEBHOOK_EVENTS = "webhook_events";
const WALLET_TOPUP_PACKAGES_PATH = "settings/wallet_topup_packages";

// Secret Manager bindings require Cloud Billing on the Firebase project.
// Until billing is enabled, functions read NGENIUS_* from process.env and
// deploy without `secrets: [...]`.
// After billing + secrets exist, deploy with TOURY_USE_SM_SECRETS=true so
// Cloud Functions injects the bound secrets into process.env.
const useSecretManager =
  String(process.env.TOURY_USE_SM_SECRETS || "").toLowerCase() === "true";

/** Secrets required by payment callables that talk to N-Genius. */
const NGENIUS_PAYMENT_SECRETS = [
  "NGENIUS_API_KEY",
  "NGENIUS_OUTLET_REF",
];

/** Secrets required by webhook (auth token + gateway verify). */
const NGENIUS_WEBHOOK_SECRETS = [
  "NGENIUS_API_KEY",
  "NGENIUS_OUTLET_REF",
  "NGENIUS_WEBHOOK_SECRET",
];

const paymentRuntime = {
  timeoutSeconds: 60,
  ...(useSecretManager ? {secrets: NGENIUS_PAYMENT_SECRETS} : {}),
};

const webhookRuntime = {
  timeoutSeconds: 15,
  ...(useSecretManager ? {secrets: NGENIUS_WEBHOOK_SECRETS} : {}),
};

const cashRuntime = {
  timeoutSeconds: 60,
};

/**
 * Production is opt-in only.
 * Missing / invalid NGENIUS_PRODUCTION ⇒ Sandbox.
 * Even with NGENIUS_PRODUCTION=true, require NGENIUS_ALLOW_PRODUCTION=true.
 */
function parseProductionFlag(raw) {
  if (raw == null) return false;
  const value = String(raw).trim().toLowerCase();
  if (!value) return false;
  if (["true", "1", "production", "prod"].includes(value)) return true;
  if (["false", "0", "sandbox", "sand", "test"].includes(value)) return false;
  return false;
}

function isNGeniusProductionEnabled() {
  return parseProductionFlag(process.env.NGENIUS_PRODUCTION);
}

function assertNGeniusEnvironmentSafe() {
  if (!isNGeniusProductionEnabled()) return;
  if (String(process.env.NGENIUS_ALLOW_PRODUCTION || "").toLowerCase() !==
    "true") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "N-Genius production is blocked. Set NGENIUS_ALLOW_PRODUCTION=true only after explicit approval.",
    );
  }
}

function ngeniusConfig() {
  // Safe default: Sandbox unless NGENIUS_PRODUCTION is an explicit true-like value.
  const production = isNGeniusProductionEnabled();
  return {
    apiKey: process.env.NGENIUS_API_KEY || "",
    outletRef: process.env.NGENIUS_OUTLET_REF || "",
    production,
    realm: process.env.NGENIUS_REALM ||
      (production ? "networkinternational" : "ni"),
    redirectUrl: process.env.NGENIUS_REDIRECT_URL || DEFAULT_RETURN_URL,
    cancelUrl: process.env.NGENIUS_CANCEL_URL || DEFAULT_RETURN_URL,
    webhookSecret: process.env.NGENIUS_WEBHOOK_SECRET || "",
    webhookHeader: String(
      process.env.NGENIUS_WEBHOOK_HEADER || "x-toury-webhook-token",
    ).toLowerCase(),
    requireAppCheck:
      String(process.env.NGENIUS_REQUIRE_APP_CHECK || "false") === "true",
  };
}

function requireAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required.",
    );
  }
}

function requireAppCheck(context) {
  // Default OFF until App Check is rolled out to production builds.
  // Set NGENIUS_REQUIRE_APP_CHECK=true after App Check is live.
  const { requireAppCheck: enabled } = ngeniusConfig();
  if (enabled && !process.env.FUNCTIONS_EMULATOR && !context.app) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "App Check verification is required.",
    );
  }
}

function sanitizeString(value, maxLen = 256) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLen);
}

function gatewayOutletBase() {
  const { outletRef, production } = ngeniusConfig();
  if (!outletRef) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "N-Genius outlet reference is not configured.",
    );
  }
  const base = production ? PROD_GATEWAY_BASE : SANDBOX_GATEWAY_BASE;
  return `${base}/${outletRef}`;
}

function safeInteger(value, min, max, fieldName) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid ${fieldName}.`,
    );
  }
  return parsed;
}

function documentPath(value, collectionName) {
  const path = sanitizeString(value, 180);
  const parts = path.split("/");
  if (parts.length !== 2 || parts[0] !== collectionName || !parts[1]) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid ${collectionName} reference.`,
    );
  }
  return path;
}

function percentOf(amountHalalas, percent) {
  const safePercent = Number(percent);
  if (!Number.isFinite(safePercent) || safePercent <= 0) return 0;
  return Math.round(amountHalalas * safePercent / 100);
}

async function verifiedBookingAmount(data) {
  const carPath = documentPath(data.carPath, "type_car");
  const countryPath = documentPath(data.countryPath, "countries");
  const bookingHours = safeInteger(data.bookingHours, 1, 24 * 30, "booking hours");
  const additionalHours = safeInteger(
    data.additionalHours || 0,
    0,
    bookingHours,
    "additional hours",
  );

  const firestore = admin.firestore();
  const [carSnapshot, countrySnapshot] = await Promise.all([
    firestore.doc(carPath).get(),
    firestore.doc(countryPath).get(),
  ]);
  if (!carSnapshot.exists || !countrySnapshot.exists) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The selected car or country is no longer available.",
    );
  }

  const car = carSnapshot.data() || {};
  const country = countrySnapshot.data() || {};
  if (car.actev === false || car.acctev === false || country.acctev === false) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The selected car or country is inactive.",
    );
  }

  const hourlyRateSar = safeInteger(car.sr, 1, 1000000, "car hourly rate");
  const baseFareHalalas = hourlyRateSar * 100 * bookingHours;
  const rawDiscountHalalas = percentOf(
    hourlyRateSar * 100 * additionalHours,
    car.NesbahkKsm,
  );
  const discountCapHalalas = Math.max(
    0,
    Math.round(Number(car.TotalKsmUb) || 0) * 100,
  );
  const discountHalalas = discountCapHalalas > 0
    ? Math.min(rawDiscountHalalas, discountCapHalalas)
    : 0;
  const amountHalalas = baseFareHalalas - discountHalalas;
  const appFeeHalalas = percentOf(baseFareHalalas, 15);
  const vatHalalas = country.isvat === true
    ? percentOf(baseFareHalalas, country.vat)
    : 0;
  const currency = String(
    country.currency_code || country.currencyCode || country.Currency || "SAR",
  )
    .trim()
    .toUpperCase() || "SAR";

  return {
    amountHalalas,
    currency,
    carPath,
    countryPath,
    bookingHours,
    additionalHours,
    baseFareHalalas,
    appFeeHalalas,
    vatHalalas,
    discountHalalas,
  };
}

async function verifiedExtraHoursAmount(data, uid) {
  const orderPath = documentPath(data.orderPath, "order");
  const extraHours = safeInteger(data.extraHours, 1, 24 * 7, "extra hours");
  const firestore = admin.firestore();
  const orderSnapshot = await firestore.doc(orderPath).get();
  if (!orderSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "Booking not found.");
  }
  const order = orderSnapshot.data() || {};
  const expectedUser = firestore.collection("user").doc(uid);
  if (!order.USER || order.USER.path !== expectedUser.path) {
    throw new functions.https.HttpsError("permission-denied", "Access denied.");
  }
  if (!order.carRev || !order.carRev.path) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The booking has no active vehicle price.",
    );
  }
  const carSnapshot = await order.carRev.get();
  if (!carSnapshot.exists || carSnapshot.data().acctev === false) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The booking vehicle is no longer available.",
    );
  }
  const hourlyRateSar = safeInteger(
    carSnapshot.data().sr,
    1,
    1000000,
    "car hourly rate",
  );
  return {
    amountHalalas: hourlyRateSar * 100 * extraHours,
    orderPath,
    extraHours,
    hourlyRateSar,
  };
}

async function getAccessToken() {
  const { apiKey, production, realm } = ngeniusConfig();
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "N-Genius API key is not configured.",
    );
  }

  const identityUrl = production ? PROD_IDENTITY : SANDBOX_IDENTITY;
  const response = await axios.post(
    identityUrl,
    { grant_type: "client_credentials", realm },
    {
      headers: {
        "Content-Type": "application/vnd.ni-identity.v1+json",
        Authorization: `Basic ${apiKey}`,
      },
      timeout: 12000,
    },
  );

  const token = response.data && response.data.access_token;
  if (!token) {
    throw new functions.https.HttpsError(
      "internal",
      "N-Genius authentication failed.",
    );
  }
  return token;
}

function normalizeStatus(state) {
  const value = String(state || "").toUpperCase();
  if (["PURCHASED", "CAPTURED"].includes(value)) return "paid";
  if (["PARTIALLY_REFUNDED"].includes(value)) return "partially_refunded";
  if (["REFUNDED"].includes(value)) return "refunded";
  if (["CANCELLED", "CANCELED"].includes(value)) return "cancelled";
  if (["EXPIRED"].includes(value)) return "expired";
  if (["FAILED", "DECLINED", "PURCHASE_REVERSED"].includes(value)) {
    return "failed";
  }
  return "pending";
}

/**
 * Pure resolver used by createNGeniusPayment and unit tests.
 * Client-supplied `amount` must never be trusted for wallet top-ups.
 */
function resolveWalletPackageFromCatalog(catalog, packageId, options = {}) {
  const id = sanitizeString(packageId, 64);
  if (!id || !/^[a-zA-Z0-9_-]+$/.test(id)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid packageId is required.",
    );
  }
  if (!catalog || typeof catalog !== "object") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet top-up packages are not configured.",
    );
  }

  const packages = Array.isArray(catalog.packages) ? catalog.packages : [];
  const pkg = packages.find((entry) =>
    entry && sanitizeString(entry.packageId, 64) === id
  );
  if (!pkg) {
    throw new functions.https.HttpsError(
      "not-found",
      "Wallet package not found.",
    );
  }
  if (pkg.enabled !== true) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet package is disabled.",
    );
  }

  const amountMinor = Number(pkg.amountMinor);
  if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet package amountMinor is invalid.",
    );
  }

  const minAmount = Number(catalog.minAmountMinor);
  const maxAmount = Number(catalog.maxAmountMinor);
  if (Number.isInteger(minAmount) && amountMinor < minAmount) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet package is below the minimum allowed amount.",
    );
  }
  if (Number.isInteger(maxAmount) && maxAmount > 0 && amountMinor > maxAmount) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet package exceeds the maximum allowed amount.",
    );
  }

  const currency = sanitizeString(pkg.currency, 8).toUpperCase();
  const allowedCurrencies = Array.isArray(catalog.allowedCurrencies)
    ? catalog.allowedCurrencies.map((c) => String(c).toUpperCase())
    : ["SAR"];
  if (!currency || !allowedCurrencies.includes(currency)) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet package currency is not allowed.",
    );
  }
  // Current N-Genius outlet path is SAR-only in this codebase.
  if (currency !== "SAR") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Unsupported wallet currency for N-Genius.",
    );
  }

  const packageCountry = sanitizeString(pkg.countryCode || "", 8).toUpperCase();
  const requestedCountry = sanitizeString(options.countryCode || "", 8)
    .toUpperCase();
  if (requestedCountry && packageCountry &&
      requestedCountry !== packageCountry) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet package is not available for this country.",
    );
  }

  return {
    amountHalalas: amountMinor,
    currency,
    packageId: id,
    countryCode: packageCountry || null,
    walletPackagePath: WALLET_TOPUP_PACKAGES_PATH,
  };
}

async function verifiedWalletTopUpAmount(data) {
  // Intentionally ignore client amountMinor; allow curated packages or allow-listed majors.
  const allowedMajors = new Set([100, 200, 300, 500]);
  const packageId = sanitizeString(data.packageId, 64);
  if (packageId) {
    const snapshot = await admin.firestore().doc(WALLET_TOPUP_PACKAGES_PATH).get();
    if (snapshot.exists) {
      try {
        return resolveWalletPackageFromCatalog(snapshot.data(), packageId, {
          countryCode: data.countryCode,
        });
      } catch (_) {
        // Fall through to amountMajor allow-list.
      }
    }
  }
  const major = Number(data.amountMajor);
  if (Number.isFinite(major) && allowedMajors.has(major)) {
    return {
      amountHalalas: Math.round(major * 100),
      currency: "SAR",
      packageId: packageId || `sar_${major}`,
    };
  }
  throw new functions.https.HttpsError(
    "invalid-argument",
    "Invalid wallet top-up package or amount.",
  );
}

function webhookPayloadHash(body) {
  return crypto
    .createHash("sha256")
    .update(typeof body === "string" ? body : JSON.stringify(body || {}))
    .digest("hex");
}

function webhookEventDocId(eventId, payloadHash) {
  const cleanEventId = sanitizeString(eventId, 120).replace(/[^a-zA-Z0-9_-]/g, "");
  if (cleanEventId) return cleanEventId;
  return `hash_${payloadHash.slice(0, 40)}`;
}

function extractPaymentUrl(data) {
  if (!data || typeof data !== "object") return null;
  const links = data._links || {};
  return (
    (links.payment && links.payment.href) ||
    (links["cnp:payment-link"] && links["cnp:payment-link"].href) ||
    null
  );
}

function extractOrderReference(data) {
  const reference = sanitizeString(data && data.reference, 80);
  if (reference) return reference;
  const urn = sanitizeString(data && data._id, 180);
  return urn ? urn.split(":").pop() : "";
}

function sanitizeMerchantOrderReference(value) {
  const cleaned = sanitizeString(value, 37).replace(/[^a-zA-Z0-9-]/g, "-");
  return cleaned.replace(/-+/g, "-").replace(/^-|-$/g, "") || "TouryBooking";
}

function sessionIdFor(uid, idempotencyKey) {
  return crypto
    .createHash("sha256")
    .update(`${uid}:${idempotencyKey}`, "utf8")
    .digest("hex");
}

function sessionResponse(sessionId, data) {
  return {
    id: sessionId,
    reference: sessionId,
    orderReference: sessionId,
    status: data.status || "pending",
    state: data.gateway_state || "",
    source: { transaction_url: data.payment_url || null },
    provider: "ngenius",
    chargedAmount: data.amount_halalas,
    amount_halalas: data.amount_halalas,
    currency: data.currency || "SAR",
  };
}

function normalizeOrderResponse(sessionId, orderData) {
  const payments = orderData && orderData._embedded &&
    orderData._embedded.payment || [];
  const payment = payments[0] || {};
  const state = payment.state || orderData.state || "";
  return {
    id: sessionId,
    reference: sessionId,
    orderReference: sessionId,
    paymentReference: payment.reference || "",
    status: normalizeStatus(state),
    state,
    paymentState: state,
    source: { transaction_url: extractPaymentUrl(orderData) },
    provider: "ngenius",
    chargedAmount:
      Number(orderData && orderData.amount && orderData.amount.value) || null,
  };
}

function gatewayErrorCode(error) {
  const errors = error.response && error.response.data &&
    error.response.data.errors || [];
  return sanitizeString(errors[0] && errors[0].errorCode, 80) ||
    `http_${error.response && error.response.status || "network"}`;
}

function userFacingNGeniusError(error, fallback) {
  const code = gatewayErrorCode(error);
  if (code === "configFetchError") {
    return (
      "Outlet card payments are not fully configured on N-Genius. " +
      "Complete merchant/outlet setup in the N-Genius portal, then retry."
    );
  }
  if (error.code === "ECONNABORTED") {
    return "The payment gateway did not respond in time. Please retry safely.";
  }
  return fallback;
}

async function fetchGatewayOrder(providerOrderRef) {
  const token = await getAccessToken();
  const url = `${gatewayOutletBase()}/orders/${providerOrderRef}`;
  const response = await axios.get(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.ni-payment.v2+json",
    },
    timeout: 10000,
  });
  return response.data;
}

async function syncSessionFromGateway(sessionRef, session, orderData) {
  const normalized = normalizeOrderResponse(sessionRef.id, orderData);
  const gatewayAmount = Number(
    orderData && orderData.amount && orderData.amount.value,
  );
  const expectedAmount = Number(session.amount_halalas);
  const amountMatches = Number.isInteger(gatewayAmount) &&
    gatewayAmount === expectedAmount;
  const outletMatches = !orderData.outletId ||
    orderData.outletId === ngeniusConfig().outletRef;

  if (!amountMatches || !outletMatches) {
    await sessionRef.set({
      status: "security_review",
      gateway_state: normalized.state,
      security_error: !amountMatches ? "amount_mismatch" : "outlet_mismatch",
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Payment verification did not match the booking quote.",
    );
  }

  await sessionRef.set({
    status: normalized.status,
    gateway_state: normalized.state,
    gateway_payment_reference: normalized.paymentReference,
    verified_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return normalized;
}

exports.createNGeniusPayment = functions
  .region("us-central1")
  .runWith(paymentRuntime)
  .https.onCall(async (data, context) => {
    requireAuth(context);
    requireAppCheck(context);
    assertNGeniusEnvironmentSafe();

    const uid = context.auth.uid;
    const purpose = sanitizeString(data.paymentPurpose, 32) || "generic";
    const idempotencyKey = sanitizeString(data.idempotencyKey, 96);
    if (!idempotencyKey || !/^[a-zA-Z0-9_.:-]+$/.test(idempotencyKey)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid payment idempotency key is required.",
      );
    }

    let verifiedQuote = null;
    if (purpose === "booking") {
      verifiedQuote = await verifiedBookingAmount(data);
    } else if (purpose === "extra_hours") {
      verifiedQuote = await verifiedExtraHoursAmount(data, uid);
    } else if (purpose === "wallet") {
      verifiedQuote = await verifiedWalletTopUpAmount(data);
    } else {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Unsupported payment purpose.",
      );
    }
    // Never charge using Flutter-supplied amount.
    const amount = verifiedQuote.amountHalalas;
    const sessionId = sessionIdFor(uid, idempotencyKey);
    const sessionRef = admin.firestore().collection(PAYMENT_SESSIONS).doc(sessionId);
    let existingData = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const existing = await transaction.get(sessionRef);
      if (existing.exists) {
        existingData = existing.data();
        return;
      }
      transaction.create(sessionRef, {
        user_id: uid,
        purpose,
        provider: "ngenius",
        idempotency_key_hash: sessionId,
        amount_halalas: amount,
        currency: verifiedQuote.currency || "SAR",
        status: "creating",
        ...(verifiedQuote || {}),
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    if (existingData) {
      if (existingData.user_id !== uid) {
        throw new functions.https.HttpsError("permission-denied", "Access denied.");
      }
      return sessionResponse(sessionId, existingData);
    }

    try {
      const token = await getAccessToken();
      const { redirectUrl, cancelUrl } = ngeniusConfig();
      const payload = {
        action: "PURCHASE",
        amount: {
          currencyCode: verifiedQuote.currency || "SAR",
          value: amount,
        },
        emailAddress: sanitizeString(data.email, 128) || undefined,
        merchantAttributes: { redirectUrl, cancelUrl },
        merchantOrderReference: sanitizeMerchantOrderReference(
          data.description || `Toury-${sessionId.slice(0, 16)}`,
        ),
      };
      const response = await axios.post(
        `${gatewayOutletBase()}/orders`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/vnd.ni-payment.v2+json",
            Accept: "application/vnd.ni-payment.v2+json",
          },
          timeout: 15000,
        },
      );
      const providerOrderRef = extractOrderReference(response.data);
      const paymentUrl = extractPaymentUrl(response.data);
      if (!providerOrderRef || !paymentUrl) {
        throw new Error("invalid_gateway_order_response");
      }

      const update = {
        provider_order_ref: providerOrderRef,
        payment_url: paymentUrl,
        status: "pending",
        gateway_state: response.data.state || "STARTED",
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };
      await sessionRef.set(update, { merge: true });
      return sessionResponse(sessionId, {
        ...update,
        amount_halalas: amount,
        currency: verifiedQuote.currency || "SAR",
      });
    } catch (error) {
      const errorCode = gatewayErrorCode(error);
      await sessionRef.set({
        status: "failed",
        error_code: errorCode,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.error("createNGeniusPayment failed", {
        code: errorCode,
        status: error.response && error.response.status,
      });
      throw new functions.https.HttpsError(
        "internal",
        userFacingNGeniusError(error, "N-Genius payment creation failed."),
      );
    }
  });

exports.getNGeniusPayment = functions
  .region("us-central1")
  .runWith(paymentRuntime)
  .https.onCall(async (data, context) => {
    requireAuth(context);
    requireAppCheck(context);
    assertNGeniusEnvironmentSafe();

    const sessionId = sanitizeString(data.id, 64);
    if (!/^[a-f0-9]{64}$/.test(sessionId)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment session reference is invalid.",
      );
    }

    const sessionRef = admin.firestore().collection(PAYMENT_SESSIONS).doc(sessionId);
    const snapshot = await sessionRef.get();
    if (!snapshot.exists || snapshot.data().user_id !== context.auth.uid) {
      throw new functions.https.HttpsError("not-found", "Payment session not found.");
    }
    const session = snapshot.data();
    if (!session.provider_order_ref) return sessionResponse(sessionId, session);

    try {
      const orderData = await fetchGatewayOrder(session.provider_order_ref);
      return await syncSessionFromGateway(sessionRef, session, orderData);
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      const errorCode = gatewayErrorCode(error);
      console.error("getNGeniusPayment failed", {
        code: errorCode,
        status: error.response && error.response.status,
      });
      throw new functions.https.HttpsError(
        "internal",
        "N-Genius order lookup failed.",
      );
    }
  });

function optionalDocumentReference(value, collectionName) {
  if (value == null || value === "") return null;
  return admin.firestore().doc(documentPath(value, collectionName));
}

function safeCoordinate(value, min, max, fieldName) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid ${fieldName}.`,
    );
  }
  return parsed;
}

function optionalTimestamp(value) {
  if (value == null || value === "") return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid booking schedule.",
    );
  }
  return admin.firestore.Timestamp.fromDate(parsed);
}

function safeWaypoints(value) {
  if (!Array.isArray(value)) return [];
  return value.slice(0, 30).map((point) => ({
    lat: safeCoordinate(point.lat, -90, 90, "waypoint latitude"),
    lng: safeCoordinate(point.lng, -180, 180, "waypoint longitude"),
  }));
}

function safeStops(value, uid) {
  if (!Array.isArray(value)) return [];
  const firestore = admin.firestore();
  return value.slice(0, 30).map((stop) => {
    const result = {
      naim: sanitizeString(stop.name, 180),
      address: sanitizeString(stop.address, 300),
      textivill: sanitizeString(stop.city, 160),
      user: firestore.collection("user").doc(uid),
    };
    if (stop.lat != null && stop.lng != null) {
      result.loceshn = new admin.firestore.GeoPoint(
        safeCoordinate(stop.lat, -90, 90, "stop latitude"),
        safeCoordinate(stop.lng, -180, 180, "stop longitude"),
      );
    }
    if (stop.placePath) {
      result.Revmkan = optionalDocumentReference(stop.placePath, "mkan");
    }
    return result;
  });
}

async function ownedPaidSession(sessionId, uid) {
  if (!/^[a-f0-9]{64}$/.test(sessionId)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Payment session reference is invalid.",
    );
  }
  const sessionRef = admin.firestore().collection(PAYMENT_SESSIONS).doc(sessionId);
  const snapshot = await sessionRef.get();
  if (!snapshot.exists || snapshot.data().user_id !== uid) {
    throw new functions.https.HttpsError("not-found", "Payment session not found.");
  }
  const session = snapshot.data();
  if (!session.provider_order_ref) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Payment session has not reached the gateway.",
    );
  }
  const orderData = await fetchGatewayOrder(session.provider_order_ref);
  const normalized = await syncSessionFromGateway(sessionRef, session, orderData);
  if (normalized.status !== "paid") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Payment is not complete.",
    );
  }
  return { sessionRef, session: { ...session, status: "paid" } };
}

exports.finalizeNGeniusBooking = functions
  .region("us-central1")
  .runWith(paymentRuntime)
  .https.onCall(async (data, context) => {
    requireAuth(context);
    requireAppCheck(context);
    assertNGeniusEnvironmentSafe();
    const uid = context.auth.uid;
    const sessionId = sanitizeString(data.id, 64);
    const { sessionRef, session } = await ownedPaidSession(sessionId, uid);
    if (session.purpose !== "booking") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "This payment session is not a booking payment.",
      );
    }

    const booking = data.booking && typeof data.booking === "object"
      ? data.booking
      : {};
    const pickupLat = safeCoordinate(
      booking.pickupLat,
      -90,
      90,
      "pickup latitude",
    );
    const pickupLng = safeCoordinate(
      booking.pickupLng,
      -180,
      180,
      "pickup longitude",
    );
    const schedule = optionalTimestamp(booking.schedule);
    const cityRef = optionalDocumentReference(booking.cityPath, "cities");
    const villageRef = optionalDocumentReference(booking.villagePath, "villages");
    const plannedWaypoints = safeWaypoints(booking.plannedWaypoints);
    const stops = safeStops(booking.stops, uid);
    const userRef = admin.firestore().collection("user").doc(uid);
    const userSnapshot = await userRef.get();
    const user = userSnapshot.exists ? userSnapshot.data() : {};
    const orderRef = admin.firestore().collection("order").doc(sessionId);
    const now = admin.firestore.FieldValue.serverTimestamp();
    let alreadyExisted = false;

    await admin.firestore().runTransaction(async (transaction) => {
      const [existingOrder, freshSession] = await Promise.all([
        transaction.get(orderRef),
        transaction.get(sessionRef),
      ]);
      if (existingOrder.exists) {
        alreadyExisted = true;
        return;
      }
      if (!freshSession.exists || freshSession.data().status !== "paid") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Payment verification expired before booking creation.",
        );
      }

      const orderData = {
        USER: userRef,
        total: session.amount_halalas / 100,
        amount_halalas: session.amount_halalas,
        currency: session.currency || "SAR",
        data_order: now,
        acceptanceDeadline: admin.firestore.Timestamp.fromMillis(
          Date.now() + 60 * 60 * 1000,
        ),
        acceptance_deadline_ms: Date.now() + 60 * 60 * 1000,
        LOKESHN: new admin.firestore.GeoPoint(pickupLat, pickupLng),
        mapuser: new admin.firestore.GeoPoint(pickupLat, pickupLng),
        originLatitude: pickupLat,
        originLongitude: pickupLng,
        carRev: admin.firestore().doc(session.carPath),
        Rev_dolh: admin.firestore().doc(session.countryPath),
        cities_user_now: cityRef,
        vill: villageRef,
        vill_text: sanitizeString(booking.cityName, 180),
        cartext: sanitizeString(booking.carName, 160),
        naim_user_text: sanitizeString(user.display_name || user.name, 160),
        phone_numper: Number(user.phone_n || user.phoneN || 0),
        imgProfileClent: sanitizeString(user.photo_url || user.photoUrl, 500),
        total_taim: session.bookingHours,
        total_app: session.appFeeHalalas / 100,
        total_vat: session.vatHalalas / 100,
        ksm: session.discountHalalas / 100,
        SrSAAH: session.baseFareHalalas /
          Math.max(1, session.bookingHours) / 100,
        DriverGuide: booking.driverGuide === true,
        Schedule: schedule,
        fullSchedule: sanitizeString(booking.scheduleLabel, 180),
        listAmakn: stops,
        plannedWaypoints,
        trip_type: sanitizeString(booking.tripType, 32) || "one_way",
        luggage_estimate: Math.max(0, Number(booking.luggageEstimate) || 0),
        routeProvider: sanitizeString(booking.routeProvider, 32) || "waypoints",
        routeVersion: 1,
        plannedDistanceMeters: Math.max(
          0,
          Number(booking.plannedDistanceMeters) || 0,
        ),
        plannedDurationSeconds: Math.max(
          0,
          Number(booking.plannedDurationSeconds) || 0,
        ),
        IDorder: sessionId.slice(0, 12).toUpperCase(),
        // Trip lifecycle (machine): pending_driver. Payment is separate.
        // halh_text kept Arabic for legacy driver queries; status_code is canonical.
        halh_order: "Paid",
        halh: "paid",
        halh_text: "بإنتظار قبول المندوب",
        status_code: "pending_driver",
        payment_status: "paid",
        PaymentMethod: "OnlinePayment",
        ngeniusOrderId: sessionId,
        payment_session_id: sessionId,
        payment_verified_at: now,
        ALLNOW: true,
        ActiveOrder: false,
        ReviewMndonsend: false,
      };
      Object.keys(orderData).forEach((key) => {
        if (orderData[key] == null) delete orderData[key];
      });
      transaction.create(orderRef, orderData);
      transaction.set(sessionRef, {
        booking_id: orderRef.id,
        booking_created_at: now,
        updated_at: now,
      }, { merge: true });
    });

    return {
      id: orderRef.id,
      orderId: orderRef.id,
      status: "paid",
      alreadyExisted,
    };
  });

exports.createCashBooking = functions
  .region("us-central1")
  .runWith(cashRuntime)
  .https.onCall(async (data, context) => {
    requireAuth(context);
    // Cash booking must not depend on N-Genius secrets.
    requireAppCheck(context);
    const uid = context.auth.uid;
    const idempotencyKey = sanitizeString(data.idempotencyKey, 96);
    if (!idempotencyKey || !/^[a-zA-Z0-9_.:-]+$/.test(idempotencyKey)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid booking idempotency key is required.",
      );
    }
    let quote;
    try {
      quote = await verifiedBookingAmount(data);
    } catch (err) {
      if (err instanceof functions.https.HttpsError) throw err;
      console.error("createCashBooking quote failed", err);
      throw new functions.https.HttpsError(
        "unavailable",
        "Booking service cannot access Firestore. Check function IAM.",
      );
    }
    const booking = data.booking && typeof data.booking === "object"
      ? data.booking
      : {};
    const pickupLat = safeCoordinate(
      booking.pickupLat,
      -90,
      90,
      "pickup latitude",
    );
    const pickupLng = safeCoordinate(
      booking.pickupLng,
      -180,
      180,
      "pickup longitude",
    );
    const schedule = optionalTimestamp(booking.schedule);
    const cityRef = optionalDocumentReference(booking.cityPath, "cities");
    const villageRef = optionalDocumentReference(booking.villagePath, "villages");
    const plannedWaypoints = safeWaypoints(booking.plannedWaypoints);
    const stops = safeStops(booking.stops, uid);
    const firestore = admin.firestore();
    const userRef = firestore.collection("user").doc(uid);
    let userSnapshot;
    try {
      userSnapshot = await userRef.get();
    } catch (err) {
      console.error("createCashBooking user get failed", err);
      throw new functions.https.HttpsError(
        "unavailable",
        "Booking service cannot access Firestore. Check function IAM.",
      );
    }
    const user = userSnapshot.exists ? userSnapshot.data() : {};
    const orderId = sessionIdFor(uid, `cash:${idempotencyKey}`);
    const orderRef = firestore.collection("order").doc(orderId);
    const now = admin.firestore.FieldValue.serverTimestamp();
    let alreadyExisted = false;

    await firestore.runTransaction(async (transaction) => {
      const existing = await transaction.get(orderRef);
      if (existing.exists) {
        alreadyExisted = true;
        return;
      }
      const orderData = {
        USER: userRef,
        total: quote.amountHalalas / 100,
        amount_halalas: quote.amountHalalas,
        currency: quote.currency || "SAR",
        currency_code: quote.currency || "SAR",
        data_order: now,
        acceptanceDeadline: admin.firestore.Timestamp.fromMillis(
          Date.now() + 60 * 60 * 1000,
        ),
        acceptance_deadline_ms: Date.now() + 60 * 60 * 1000,
        LOKESHN: new admin.firestore.GeoPoint(pickupLat, pickupLng),
        mapuser: new admin.firestore.GeoPoint(pickupLat, pickupLng),
        originLatitude: pickupLat,
        originLongitude: pickupLng,
        carRev: firestore.doc(quote.carPath),
        Rev_dolh: firestore.doc(quote.countryPath),
        cities_user_now: cityRef,
        vill: villageRef,
        vill_text: sanitizeString(booking.cityName, 180),
        cartext: sanitizeString(booking.carName, 160),
        naim_user_text: sanitizeString(user.display_name || user.name, 160),
        phone_numper: Number(user.phone_n || user.phoneN || 0),
        imgProfileClent: sanitizeString(user.photo_url || user.photoUrl, 500),
        total_taim: quote.bookingHours,
        total_app: quote.appFeeHalalas / 100,
        total_vat: quote.vatHalalas / 100,
        ksm: quote.discountHalalas / 100,
        SrSAAH: quote.baseFareHalalas /
          Math.max(1, quote.bookingHours) / 100,
        DriverGuide: booking.driverGuide === true,
        Schedule: schedule,
        fullSchedule: sanitizeString(booking.scheduleLabel, 180),
        listAmakn: stops,
        plannedWaypoints,
        trip_type: sanitizeString(booking.tripType, 32) || "one_way",
        luggage_estimate: Math.max(0, Number(booking.luggageEstimate) || 0),
        routeProvider: sanitizeString(booking.routeProvider, 32) || "waypoints",
        routeVersion: 1,
        plannedDistanceMeters: Math.max(
          0,
          Number(booking.plannedDistanceMeters) || 0,
        ),
        plannedDurationSeconds: Math.max(
          0,
          Number(booking.plannedDurationSeconds) || 0,
        ),
        IDorder: `CASH-${orderId.slice(0, 10).toUpperCase()}`,
        // Trip lifecycle pending; cash collection tracked via payment_status.
        halh_order: "Cash",
        halh: "pending_cash",
        halh_text: "بإنتظار قبول المندوب",
        status_code: "pending_driver",
        payment_status: "pending_cash",
        cash_collection_status: "uncollected",
        PaymentMethod: "Cash",
        ALLNOW: true,
        ActiveOrder: false,
        ReviewMndonsend: false,
        created_by_function: true,
      };
      Object.keys(orderData).forEach((key) => {
        if (orderData[key] == null) delete orderData[key];
      });
      transaction.create(orderRef, orderData);
    });
    return { id: orderId, orderId, status: "pending_cash", alreadyExisted };
  });

exports.finalizeNGeniusWalletTopUp = functions
  .region("us-central1")
  .runWith(paymentRuntime)
  .https.onCall(async (data, context) => {
    requireAuth(context);
    requireAppCheck(context);
    assertNGeniusEnvironmentSafe();
    const uid = context.auth.uid;
    const sessionId = sanitizeString(data.id, 64);
    const { sessionRef, session } = await ownedPaidSession(sessionId, uid);
    if (session.purpose !== "wallet") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "This payment session is not a wallet top-up.",
      );
    }

    const firestore = admin.firestore();
    const userRef = firestore.collection("user").doc(uid);
    const wallets = await firestore.collection("wallets")
      .where("userRef", "==", userRef)
      .limit(1)
      .get();
    const walletRef = wallets.empty
      ? firestore.collection("wallets").doc(uid)
      : wallets.docs[0].ref;
    const transactionRef = firestore.collection("transactions").doc(sessionId);
    let alreadyCredited = false;

    await firestore.runTransaction(async (transaction) => {
      const [freshSession, wallet, existingTransaction] = await Promise.all([
        transaction.get(sessionRef),
        transaction.get(walletRef),
        transaction.get(transactionRef),
      ]);
      if (existingTransaction.exists ||
          (freshSession.exists && freshSession.data().wallet_credited === true)) {
        alreadyCredited = true;
        return;
      }
      if (!freshSession.exists || freshSession.data().status !== "paid") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Payment verification expired before wallet credit.",
        );
      }

      const amountSar = session.amount_halalas / 100;
      const currentBalance = wallet.exists
        ? Number(wallet.data().currentBalance || 0)
        : 0;
      const nextBalance = currentBalance + amountSar;
      transaction.set(walletRef, {
        userRef,
        currentBalance: nextBalance,
        walletBalance: nextBalance,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        currency: "SAR",
        isActive: true,
      }, { merge: true });
      transaction.create(transactionRef, {
        userRef,
        walletRef,
        transactionId: `TXN-${sessionId.slice(0, 20).toUpperCase()}`,
        amount: amountSar,
        amount_halalas: session.amount_halalas,
        currency: "SAR",
        type: "top_up",
        description_code: "wallet_top_up",
        status: "completed",
        balanceBefore: currentBalance,
        balanceAfter: nextBalance,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        referenceId: sessionId,
        reference: sessionId,
        notes: "ngenius",
      });
      transaction.set(sessionRef, {
        wallet_credited: true,
        wallet_id: walletRef.id,
        wallet_credited_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });

    return {
      id: sessionId,
      status: "paid",
      credited: true,
      alreadyCredited,
    };
  });

exports.createWalletWithdrawalRequest = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    requireAuth(context);
    requireAppCheck(context);
    const uid = context.auth.uid;
    const amountHalalas = safeInteger(
      data.amount,
      100,
      100000000,
      "withdrawal amount",
    );
    const amountSar = amountHalalas / 100;
    const firestore = admin.firestore();
    const userRef = firestore.collection("user").doc(uid);
    const wallets = await firestore.collection("wallets")
      .where("userRef", "==", userRef)
      .limit(1)
      .get();
    if (wallets.empty) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Wallet not found.",
      );
    }

    const walletRef = wallets.docs[0].ref;
    const requestRef = firestore.collection("wallet_withdrawals").doc();
    await firestore.runTransaction(async (transaction) => {
      const wallet = await transaction.get(walletRef);
      if (!wallet.exists || wallet.data().isActive === false) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Wallet is unavailable.",
        );
      }
      const balance = Number(wallet.data().currentBalance || 0);
      const held = Number(wallet.data().pendingWithdrawalAmount || 0);
      if (!Number.isFinite(balance) || !Number.isFinite(held) ||
          balance - held < amountSar) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Insufficient available wallet balance.",
        );
      }
      transaction.update(walletRef, {
        pendingWithdrawalAmount: held + amountSar,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.create(requestRef, {
        userRef,
        walletRef,
        amount: amountSar,
        amount_halalas: amountHalalas,
        currency: "SAR",
        status: "pending_review",
        requested_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        created_by_function: true,
      });
    });

    return {
      id: requestRef.id,
      status: "pending_review",
      amount: amountSar,
      currency: "SAR",
    };
  });

exports.finalizeNGeniusExtraHours = functions
  .region("us-central1")
  .runWith(paymentRuntime)
  .https.onCall(async (data, context) => {
    requireAuth(context);
    requireAppCheck(context);
    assertNGeniusEnvironmentSafe();
    const uid = context.auth.uid;
    const sessionId = sanitizeString(data.id, 64);
    const { sessionRef, session } = await ownedPaidSession(sessionId, uid);
    if (session.purpose !== "extra_hours") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "This payment session is not an extra-hours payment.",
      );
    }
    const firestore = admin.firestore();
    const orderRef = firestore.doc(session.orderPath);
    const extraHoursRef = firestore.collection("ExtraHours").doc(sessionId);
    const historyRef = firestore.collection("Paymenthistory").doc(sessionId);
    let alreadyApplied = false;

    await firestore.runTransaction(async (transaction) => {
      const [freshSession, order, existing] = await Promise.all([
        transaction.get(sessionRef),
        transaction.get(orderRef),
        transaction.get(extraHoursRef),
      ]);
      if (existing.exists ||
          (freshSession.exists && freshSession.data().extra_hours_applied === true)) {
        alreadyApplied = true;
        return;
      }
      if (!freshSession.exists || freshSession.data().status !== "paid") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Payment verification expired before applying extra hours.",
        );
      }
      if (!order.exists || !order.data().USER ||
          order.data().USER.id !== uid) {
        throw new functions.https.HttpsError("permission-denied", "Access denied.");
      }
      const currentHours = Number(order.data().total_taim || 0);
      const amountSar = session.amount_halalas / 100;
      transaction.update(orderRef, {
        total_taim: currentHours + Number(session.extraHours),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.create(extraHoursRef, {
        revUser: firestore.collection("user").doc(uid),
        RevOrder: orderRef,
        RevMndob: order.data().mndob_user || null,
        addSaat: Number(session.extraHours),
        Total: amountSar,
        dateAdd: admin.firestore.FieldValue.serverTimestamp(),
        halh: "Completed",
        paymentGatewayOrderId: sessionId,
        idOrder: sanitizeString(order.data().IDorder, 80),
        payment_status: "paid",
      });
      transaction.create(historyRef, {
        revOrder: orderRef,
        RevUser: firestore.collection("user").doc(uid),
        Osf: "extra_hours",
        DateAdd: admin.firestore.FieldValue.serverTimestamp(),
        total: amountSar,
        ngeniusSessionId: sessionId,
      });
      transaction.set(sessionRef, {
        extra_hours_applied: true,
        extra_hours_applied_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    return {
      id: sessionId,
      orderId: orderRef.id,
      status: "paid",
      applied: true,
      alreadyApplied,
    };
  });

async function requireFinanceRole(context) {
  requireAuth(context);
  const token = context.auth.token || {};
  if (token.super_admin === true || token.finance === true) return;
  const user = await admin.firestore().collection("user").doc(context.auth.uid).get();
  const data = user.exists ? user.data() : {};
  const adminRule = Number(data.isAdminRule || data.IsAdminRule || 0);
  if (data.isAdmin === true || data.IsAdmin === true || [1, 2].includes(adminRule)) {
    return;
  }
  throw new functions.https.HttpsError("permission-denied", "Finance role required.");
}

function refundLinkFromOrder(orderData) {
  const payments = orderData && orderData._embedded &&
    orderData._embedded.payment || [];
  for (const payment of payments) {
    const direct = payment._links && payment._links["cnp:refund"] &&
      payment._links["cnp:refund"].href;
    if (direct) return direct;
    const captures = payment._embedded && payment._embedded["cnp:capture"] || [];
    for (const capture of captures) {
      const link = capture._links && capture._links["cnp:refund"] &&
        capture._links["cnp:refund"].href;
      if (link) return link;
    }
  }
  return null;
}

function assertGatewayUrl(url) {
  const allowedOrigin = new URL(gatewayOutletBase()).origin;
  const parsed = new URL(url);
  if (parsed.protocol !== "https:" || parsed.origin !== allowedOrigin) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The gateway did not provide a valid refund operation.",
    );
  }
  return parsed.toString();
}

exports.refundNGeniusPayment = functions
  .region("us-central1")
  .runWith(paymentRuntime)
  .https.onCall(async (data, context) => {
    await requireFinanceRole(context);
    assertNGeniusEnvironmentSafe();
    requireAppCheck(context);

    const sessionId = sanitizeString(data.id, 64);
    if (!/^[a-f0-9]{64}$/.test(sessionId)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment session reference is invalid.",
      );
    }
    const sessionRef = admin.firestore().collection(PAYMENT_SESSIONS).doc(sessionId);
    const snapshot = await sessionRef.get();
    if (!snapshot.exists) {
      throw new functions.https.HttpsError("not-found", "Payment session not found.");
    }
    const session = snapshot.data();
    const refundAmount = data.amount == null
      ? Number(session.amount_halalas)
      : safeInteger(data.amount, 1, Number(session.amount_halalas), "refund amount");

    try {
      const orderData = await fetchGatewayOrder(session.provider_order_ref);
      await syncSessionFromGateway(sessionRef, session, orderData);
      const refundUrl = refundLinkFromOrder(orderData);
      if (!refundUrl) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This payment is not currently refundable.",
        );
      }
      const token = await getAccessToken();
      const response = await axios.post(
        assertGatewayUrl(refundUrl),
        { amount: { currencyCode: "SAR", value: refundAmount } },
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/vnd.ni-payment.v2+json",
            Accept: "application/vnd.ni-payment.v2+json",
          },
          timeout: 12000,
        },
      );
      const status = normalizeStatus(response.data && response.data.state);
      await sessionRef.set({
        status: status === "refunded" ? "refunded" : "refund_pending",
        refund_amount_halalas: refundAmount,
        refund_requested_by: context.auth.uid,
        refund_requested_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return { id: sessionId, status: status === "refunded" ? status : "pending" };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      const errorCode = gatewayErrorCode(error);
      console.error("refundNGeniusPayment failed", {
        code: errorCode,
        status: error.response && error.response.status,
      });
      throw new functions.https.HttpsError("internal", "N-Genius refund failed.");
    }
  });

exports.ngeniusWebhook = functions
  .region("us-central1")
  .runWith(webhookRuntime)
  .https.onRequest(async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).send("method_not_allowed");
      return;
    }
    try {
      assertNGeniusEnvironmentSafe();
    } catch (error) {
      response.status(503).send("environment_blocked");
      return;
    }
    const config = ngeniusConfig();
    const suppliedSecret = sanitizeString(
      request.get(config.webhookHeader),
      512,
    );
    const expectedSecret = config.webhookSecret;
    const secretMatches = suppliedSecret && expectedSecret &&
      suppliedSecret.length === expectedSecret.length &&
      crypto.timingSafeEqual(
        Buffer.from(suppliedSecret, "utf8"),
        Buffer.from(expectedSecret, "utf8"),
      );
    if (!secretMatches) {
      response.status(401).send("unauthorized");
      return;
    }

    const event = request.body || {};
    if (event.outletId && event.outletId !== config.outletRef) {
      response.status(400).send("outlet_mismatch");
      return;
    }
    const providerOrderRef = extractOrderReference(event.order || {});
    if (!providerOrderRef) {
      response.status(400).send("missing_order_reference");
      return;
    }

    const payloadHash = webhookPayloadHash(event);
    const providerEventId = sanitizeString(
      event.eventId || event.eventName || "",
      120,
    );
    const eventDocId = webhookEventDocId(
      providerEventId || `${providerOrderRef}_${payloadHash.slice(0, 16)}`,
      payloadHash,
    );
    const eventRef = admin.firestore().collection(WEBHOOK_EVENTS).doc(eventDocId);

    try {
      const claim = await admin.firestore().runTransaction(async (transaction) => {
        const existing = await transaction.get(eventRef);
        if (existing.exists && existing.data().processed === true) {
          return { duplicate: true };
        }
        transaction.set(eventRef, {
          provider: "ngenius",
          providerEventId: providerEventId || null,
          providerOrderId: providerOrderRef,
          type: sanitizeString(event.eventName, 80) || "unknown",
          processed: false,
          processing: true,
          receivedAt: admin.firestore.FieldValue.serverTimestamp(),
          payloadHash,
        }, { merge: true });
        return { duplicate: false };
      });

      if (claim.duplicate) {
        response.status(200).send("duplicate");
        return;
      }

      const matches = await admin.firestore()
        .collection(PAYMENT_SESSIONS)
        .where("provider_order_ref", "==", providerOrderRef)
        .limit(1)
        .get();
      if (matches.empty) {
        await eventRef.set({
          processed: true,
          processing: false,
          ignored: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        response.status(200).send("ignored");
        return;
      }

      const sessionSnapshot = matches.docs[0];
      // Gateway re-fetch is the source of truth — never trust payload alone.
      const orderData = await fetchGatewayOrder(providerOrderRef);
      await syncSessionFromGateway(
        sessionSnapshot.ref,
        sessionSnapshot.data(),
        orderData,
      );
      await sessionSnapshot.ref.set({
        last_webhook_event_id: eventDocId,
        last_webhook_event_name: sanitizeString(event.eventName, 80),
        webhook_received_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      await eventRef.set({
        processed: true,
        processing: false,
        sessionId: sessionSnapshot.id,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      response.status(200).send("ok");
    } catch (error) {
      await eventRef.set({
        processed: false,
        processing: false,
        error: gatewayErrorCode(error),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true }).catch(() => null);
      console.error("ngeniusWebhook verification failed", {
        code: gatewayErrorCode(error),
        status: error.response && error.response.status,
      });
      response.status(503).send("verification_failed");
    }
  });

exports.__test = {
  extractPaymentUrl,
  normalizeStatus,
  sanitizeMerchantOrderReference,
  sessionIdFor,
  parseProductionFlag,
  isNGeniusProductionEnabled,
  resolveWalletPackageFromCatalog,
  webhookPayloadHash,
  webhookEventDocId,
};
