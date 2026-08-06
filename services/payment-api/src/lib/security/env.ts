import { z } from "zod";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

const envSchema = z.object({
  NGENIUS_ENV: z.enum(["sandbox", "production"]).default("sandbox"),
  NGENIUS_API_KEY: z.string().min(1, "NGENIUS_API_KEY is required"),
  NGENIUS_OUTLET_REF: z.string().min(1, "NGENIUS_OUTLET_REF is required"),
  NGENIUS_WEBHOOK_SECRET: z.string().optional().default(""),
  NGENIUS_SANDBOX_BASE_URL: z
    .string()
    .url()
    .default("https://api-gateway.sandbox.ngenius-payments.com"),
  NGENIUS_PRODUCTION_BASE_URL: z
    .string()
    .url()
    .default("https://api-gateway.ngenius-payments.com"),
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

let cached: AppEnv | null = null;

/** Lazy env load — health may call with partial=true for presence checks. */
export function getEnv(options?: { requireSecrets?: boolean }): AppEnv {
  if (cached) return cached;

  const requireSecrets = options?.requireSecrets !== false;
  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    if (!requireSecrets) {
      // Soft parse for health booleans only
      const soft = envSchema.partial().safeParse(process.env);
      const data = soft.success ? soft.data : {};
      const isProd = data.NGENIUS_ENV === "production";
      return {
        NGENIUS_ENV: (data.NGENIUS_ENV as "sandbox" | "production") || "sandbox",
        NGENIUS_API_KEY: data.NGENIUS_API_KEY || "",
        NGENIUS_OUTLET_REF: data.NGENIUS_OUTLET_REF || "",
        NGENIUS_WEBHOOK_SECRET: data.NGENIUS_WEBHOOK_SECRET || "",
        NGENIUS_SANDBOX_BASE_URL:
          data.NGENIUS_SANDBOX_BASE_URL ||
          "https://api-gateway.sandbox.ngenius-payments.com",
        NGENIUS_PRODUCTION_BASE_URL:
          data.NGENIUS_PRODUCTION_BASE_URL ||
          "https://api-gateway.ngenius-payments.com",
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
        ngeniusBaseUrl: isProd
          ? data.NGENIUS_PRODUCTION_BASE_URL ||
            "https://api-gateway.ngenius-payments.com"
          : data.NGENIUS_SANDBOX_BASE_URL ||
            "https://api-gateway.sandbox.ngenius-payments.com",
        ngeniusIdentityUrl: `${
          isProd
            ? data.NGENIUS_PRODUCTION_BASE_URL ||
              "https://api-gateway.ngenius-payments.com"
            : data.NGENIUS_SANDBOX_BASE_URL ||
              "https://api-gateway.sandbox.ngenius-payments.com"
        }/identity/auth/access-token`,
        ngeniusRealm: data.NGENIUS_REALM || (isProd ? "networkinternational" : "ni"),
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
  if (data.NGENIUS_ENV === "production") {
    // Explicit production only — never silent.
  }

  const isProd = data.NGENIUS_ENV === "production";
  const base = isProd
    ? data.NGENIUS_PRODUCTION_BASE_URL
    : data.NGENIUS_SANDBOX_BASE_URL;

  cached = {
    ...data,
    isProductionNGenius: isProd,
    ngeniusBaseUrl: base,
    ngeniusIdentityUrl: `${base}/identity/auth/access-token`,
    ngeniusRealm:
      data.NGENIUS_REALM || (isProd ? "networkinternational" : "ni"),
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
  return {
    ngeniusApiKey: Boolean(process.env.NGENIUS_API_KEY),
    ngeniusOutlet: Boolean(process.env.NGENIUS_OUTLET_REF),
    ngeniusWebhookSecret: Boolean(process.env.NGENIUS_WEBHOOK_SECRET),
    firebase: Boolean(
      process.env.FIREBASE_PROJECT_ID &&
        process.env.FIREBASE_CLIENT_EMAIL &&
        process.env.FIREBASE_PRIVATE_KEY,
    ),
  };
}
