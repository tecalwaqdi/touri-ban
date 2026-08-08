import { z } from "zod";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

/** Official N-Genius KSA gateways (docs.ksa.ngenius-payments.com). */
export const NGENIUS_KSA_SANDBOX_BASE_URL =
  "https://api-gateway.sandbox.ksa.ngenius-payments.com";
export const NGENIUS_KSA_PRODUCTION_BASE_URL =
  "https://api-gateway.ksa.ngenius-payments.com";

/**
 * KSA Creating Orders docs: UAT realm `ni`, Production `networkinternational`.
 * Also matches repo CF defaults + deployment guide for production.
 */
export const NGENIUS_KSA_SANDBOX_REALM = "ni";
export const NGENIUS_KSA_PRODUCTION_REALM = "networkinternational";

const envSchema = z.object({
  NGENIUS_ENV: z.enum(["sandbox", "production"]).default("sandbox"),
  NGENIUS_API_KEY: z.string().min(1, "NGENIUS_API_KEY is required"),
  NGENIUS_OUTLET_REF: z.string().min(1, "NGENIUS_OUTLET_REF is required"),
  NGENIUS_WEBHOOK_SECRET: z.string().min(16, "NGENIUS_WEBHOOK_SECRET required"),
  NGENIUS_SANDBOX_BASE_URL: z.string().url().default(NGENIUS_KSA_SANDBOX_BASE_URL),
  NGENIUS_PRODUCTION_BASE_URL: z
    .string()
    .url()
    .default(NGENIUS_KSA_PRODUCTION_BASE_URL),
  NGENIUS_REALM: z.string().optional().default(""),
  NGENIUS_WEBHOOK_HEADER: z.string().default("x-toury-webhook-token"),
  FIREBASE_PROJECT_ID: z.string().min(1),
  FIREBASE_CLIENT_EMAIL: z.string().email(),
  FIREBASE_PRIVATE_KEY: z.string().min(1),
  ALLOWED_APP_ORIGINS: z.string().optional().default(""),
  PAYMENT_RETURN_BASE_URL: z.string().url().optional().or(z.literal("")),
  PAYMENT_CANCEL_BASE_URL: z.string().url().optional().or(z.literal("")),
  PAYMENT_API_PUBLIC_BASE_URL: z.string().url().optional().or(z.literal("")),
  SERVICE_VERSION: z.string().optional().default("0.1.0"),
});

export type AppEnv = z.infer<typeof envSchema> & {
  isProductionNGenius: boolean;
  ngeniusBaseUrl: string;
  ngeniusIdentityUrl: string;
  ngeniusRealm: string;
  allowedOrigins: string[];
  privateKey: string;
};

function normalizePrivateKey(raw: string): string {
  return raw.replace(/\\n/g, "\n").trim();
}

function defaultRealm(isProd: boolean): string {
  return isProd ? NGENIUS_KSA_PRODUCTION_REALM : NGENIUS_KSA_SANDBOX_REALM;
}

/**
 * Optional base64-encoded full service-account JSON (preferred on Render).
 * When set, overrides FIREBASE_CLIENT_EMAIL / FIREBASE_PRIVATE_KEY pair.
 */
function serviceAccountFromBase64(): {
  projectId?: string;
  clientEmail?: string;
  privateKey?: string;
} {
  const b64 = (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 || "").trim();
  if (!b64) return {};
  try {
    const json = JSON.parse(Buffer.from(b64, "base64").toString("utf8")) as {
      project_id?: string;
      client_email?: string;
      private_key?: string;
    };
    return {
      projectId: json.project_id,
      clientEmail: json.client_email,
      privateKey: json.private_key,
    };
  } catch {
    throw new ApiError(
      PaymentErrorCode.CONFIG_ERROR,
      500,
      "FIREBASE_SERVICE_ACCOUNT_BASE64 is not valid base64 JSON",
    );
  }
}

let cached: AppEnv | null = null;

/** Lazy env load — health may call with partial=true for presence checks. */
export function getEnv(options?: { requireSecrets?: boolean }): AppEnv {
  if (cached) return cached;

  const requireSecrets = options?.requireSecrets !== false;
  const fromSa = serviceAccountFromBase64();
  if (fromSa.projectId) process.env.FIREBASE_PROJECT_ID ||= fromSa.projectId;
  if (fromSa.clientEmail) process.env.FIREBASE_CLIENT_EMAIL ||= fromSa.clientEmail;
  if (fromSa.privateKey) process.env.FIREBASE_PRIVATE_KEY ||= fromSa.privateKey;

  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    if (!requireSecrets) {
      const soft = envSchema.partial().safeParse(process.env);
      const data = soft.success ? soft.data : {};
      const isProd = data.NGENIUS_ENV === "production";
      const sandboxBase =
        data.NGENIUS_SANDBOX_BASE_URL || NGENIUS_KSA_SANDBOX_BASE_URL;
      const prodBase =
        data.NGENIUS_PRODUCTION_BASE_URL || NGENIUS_KSA_PRODUCTION_BASE_URL;
      const base = isProd ? prodBase : sandboxBase;
      return {
        NGENIUS_ENV: (data.NGENIUS_ENV as "sandbox" | "production") || "sandbox",
        NGENIUS_API_KEY: data.NGENIUS_API_KEY || "",
        NGENIUS_OUTLET_REF: data.NGENIUS_OUTLET_REF || "",
        NGENIUS_WEBHOOK_SECRET: data.NGENIUS_WEBHOOK_SECRET || "",
        NGENIUS_SANDBOX_BASE_URL: sandboxBase,
        NGENIUS_PRODUCTION_BASE_URL: prodBase,
        NGENIUS_REALM: data.NGENIUS_REALM || "",
        NGENIUS_WEBHOOK_HEADER:
          data.NGENIUS_WEBHOOK_HEADER || "x-toury-webhook-token",
        FIREBASE_PROJECT_ID: data.FIREBASE_PROJECT_ID || "",
        FIREBASE_CLIENT_EMAIL: data.FIREBASE_CLIENT_EMAIL || "",
        FIREBASE_PRIVATE_KEY: data.FIREBASE_PRIVATE_KEY || "",
        ALLOWED_APP_ORIGINS: data.ALLOWED_APP_ORIGINS || "",
        PAYMENT_RETURN_BASE_URL: data.PAYMENT_RETURN_BASE_URL || "",
        PAYMENT_CANCEL_BASE_URL: data.PAYMENT_CANCEL_BASE_URL || "",
        PAYMENT_API_PUBLIC_BASE_URL: data.PAYMENT_API_PUBLIC_BASE_URL || "",
        SERVICE_VERSION: data.SERVICE_VERSION || "0.1.0",
        isProductionNGenius: isProd,
        ngeniusBaseUrl: base,
        ngeniusIdentityUrl: `${base}/identity/auth/access-token`,
        ngeniusRealm: data.NGENIUS_REALM || defaultRealm(isProd),
        allowedOrigins: (data.ALLOWED_APP_ORIGINS || "")
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean),
        privateKey: normalizePrivateKey(data.FIREBASE_PRIVATE_KEY || ""),
      };
    }
    throw new ApiError(
      PaymentErrorCode.CONFIG_ERROR,
      500,
      `Missing or invalid environment: ${parsed.error.issues
        .map((i) => i.path.join("."))
        .join(", ")}`,
    );
  }

  const data = parsed.data;
  const isProd = data.NGENIUS_ENV === "production";
  const base = isProd
    ? data.NGENIUS_PRODUCTION_BASE_URL
    : data.NGENIUS_SANDBOX_BASE_URL;

  cached = {
    ...data,
    isProductionNGenius: isProd,
    ngeniusBaseUrl: base,
    ngeniusIdentityUrl: `${base}/identity/auth/access-token`,
    ngeniusRealm: data.NGENIUS_REALM || defaultRealm(isProd),
    allowedOrigins: data.ALLOWED_APP_ORIGINS.split(",")
      .map((s) => s.trim())
      .filter(Boolean),
    privateKey: normalizePrivateKey(data.FIREBASE_PRIVATE_KEY),
  };
  return cached;
}

export function resetEnvCacheForTests(): void {
  cached = null;
}

export function envPresence(): {
  ngeniusApiKey: boolean;
  ngeniusOutlet: boolean;
  ngeniusWebhookSecret: boolean;
  firebase: boolean;
} {
  const fromSa = Boolean(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64);
  return {
    ngeniusApiKey: Boolean(process.env.NGENIUS_API_KEY),
    ngeniusOutlet: Boolean(process.env.NGENIUS_OUTLET_REF),
    ngeniusWebhookSecret: Boolean(process.env.NGENIUS_WEBHOOK_SECRET),
    firebase:
      fromSa ||
      Boolean(
        process.env.FIREBASE_PROJECT_ID &&
          process.env.FIREBASE_CLIENT_EMAIL &&
          process.env.FIREBASE_PRIVATE_KEY,
      ),
  };
}
