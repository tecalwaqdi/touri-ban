import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

import { createPaymentApp } from "./server";

/**
 * Firebase Functions v2 HTTPS entry for the same Express payment API.
 * Secrets are bound at deploy time; non-secret defaults match production cutover.
 */
const ngeniusApiKey = defineSecret("NGENIUS_API_KEY");
const ngeniusOutletRef = defineSecret("NGENIUS_OUTLET_REF");
const ngeniusWebhookSecret = defineSecret("NGENIUS_WEBHOOK_SECRET");

function applyFirebaseRuntimeDefaults(): void {
  process.env.NGENIUS_ENV ||= "production";
  process.env.NGENIUS_REALM ||= "NIARABIA";
  process.env.NGENIUS_PRODUCTION_BASE_URL ||=
    "https://api-gateway.ksa.ngenius-payments.com";
  process.env.NGENIUS_SANDBOX_BASE_URL ||=
    "https://api-gateway.sandbox.ngenius-payments.com";
  process.env.NGENIUS_WEBHOOK_HEADER ||= "x-toury-webhook-token";
  process.env.PAYMENT_RETURN_BASE_URL ||=
    "https://tutorial-multi-language-70gx4j.web.app/payment-return.html";
  process.env.PAYMENT_CANCEL_BASE_URL ||=
    process.env.PAYMENT_RETURN_BASE_URL ||
    "https://tutorial-multi-language-70gx4j.web.app/payment-return.html";
  process.env.SERVICE_VERSION ||= "0.2.0";
  process.env.FIREBASE_USE_APPLICATION_DEFAULT ||= "true";
}

applyFirebaseRuntimeDefaults();

const app = createPaymentApp();

export const paymentApi = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "512MiB",
    // App Engine default SA usually has Firestore/Auth admin bindings;
    // Compute Engine default SA on this project fails OAuth token fetch.
    serviceAccount: "tutorial-multi-language-70gx4j@appspot.gserviceaccount.com",
    secrets: [ngeniusApiKey, ngeniusOutletRef, ngeniusWebhookSecret],
  },
  app,
);
