import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

import { createPaymentApp } from "./server";

/**
 * Firebase Functions v2 HTTPS entry for the same Express payment API.
 * Secrets are bound at deploy time; non-secret env vars are read from process.env.
 */
const ngeniusApiKey = defineSecret("NGENIUS_API_KEY");
const ngeniusOutletRef = defineSecret("NGENIUS_OUTLET_REF");
const ngeniusWebhookSecret = defineSecret("NGENIUS_WEBHOOK_SECRET");

export const paymentApi = onRequest(
  {
    region: "us-central1",
    secrets: [ngeniusApiKey, ngeniusOutletRef, ngeniusWebhookSecret],
    // Non-secret runtime env (set in Cloud Console / .env / params — not secrets):
    // NGENIUS_ENV, NGENIUS_REALM, NGENIUS_SANDBOX_BASE_URL, NGENIUS_PRODUCTION_BASE_URL,
    // NGENIUS_WEBHOOK_HEADER, PAYMENT_RETURN_BASE_URL, PAYMENT_CANCEL_BASE_URL, SERVICE_VERSION
  },
  createPaymentApp(),
);
