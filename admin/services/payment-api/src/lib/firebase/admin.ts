import { createHash } from "crypto";
import admin from "firebase-admin";
import { getEnv, isFirebaseAdcMode } from "@/lib/security/env";

let initialized = false;

export function initFirebase(): typeof admin {
  if (!initialized) {
    if (!admin.apps.length) {
      if (isFirebaseAdcMode()) {
        // Cloud Functions / ADC: default app + runtime project credentials.
        admin.initializeApp();
      } else {
        const env = getEnv();
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: env.FIREBASE_PROJECT_ID,
            clientEmail: env.FIREBASE_CLIENT_EMAIL,
            privateKey: env.privateKey,
          }),
        });
      }
    }
    initialized = true;
  }
  return admin;
}

export function firebaseReady(): boolean {
  try {
    if (isFirebaseAdcMode()) {
      return true;
    }
    if (Boolean(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64?.trim())) {
      return true;
    }
    return (
      Boolean(process.env.FIREBASE_PROJECT_ID) &&
      Boolean(process.env.FIREBASE_CLIENT_EMAIL) &&
      Boolean(process.env.FIREBASE_PRIVATE_KEY)
    );
  } catch {
    return false;
  }
}

export function db() {
  return initFirebase().firestore();
}

export function auth() {
  return initFirebase().auth();
}

export function sessionIdFor(uid: string, idempotencyKey: string): string {
  return createHash("sha256").update(`${uid}:${idempotencyKey}`).digest("hex");
}

export const COLLECTIONS = {
  paymentSessions: "payment_sessions",
  webhookEvents: "webhook_events",
  orders: "order",
  users: "user",
  typeCar: "type_car",
  countries: "countries",
  walletPackages: "settings/wallet_topup_packages",
} as const;
