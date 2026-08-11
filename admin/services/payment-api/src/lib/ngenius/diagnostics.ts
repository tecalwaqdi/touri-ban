import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import {
  createNGeniusOrder,
  getNGeniusAccessToken,
  isKsaNGeniusHost,
  maskOutletRef,
  normalizeNGeniusApiKeyForBasicAuth,
  resetNGeniusTokenCacheForTests,
  resolveNGeniusIdentityBodyStyle,
  type NGeniusIdentityBodyStyle,
} from "@/lib/ngenius/client";
import { envPresence, getEnv } from "@/lib/security/env";
import { logger } from "@/lib/logging/logger";

export type NGeniusIdentityStatus = "ok" | "failed" | "skipped";
export type NGeniusCreateOrderStatus = "ok" | "failed" | "skipped" | "blocked";

export type NGeniusSafeDiagnostics = {
  ok: boolean;
  environment: "sandbox" | "production";
  baseHost: string;
  identityHost: string;
  realm: string;
  outletRefMasked: string;
  usesProductionBaseUrl: boolean;
  usesSandboxHost: boolean;
  /** Host family (ksa vs global), independent of body style. */
  identityHostFamily: "ksa" | "global";
  /** Actual identity JSON schema used for this realm/host. */
  identityBodyStyle: NGeniusIdentityBodyStyle;
  identityStatus: NGeniusIdentityStatus;
  createOrderStatus: NGeniusCreateOrderStatus;
  providerHttpStatus?: number;
  providerErrorCode?: string;
  providerMessage?: string;
  apiKeyLen?: number;
  hasHostedPaymentUrl?: boolean;
  readiness?: "PRODUCTION_HPP_READY" | "SANDBOX_HPP_READY" | "NOT_READY";
  configured: ReturnType<typeof envPresence>;
  webhookPath: "/webhooks/ngenius";
  notes: string[];
};

function baseHostOf(url: string): string {
  try {
    return new URL(url).host;
  } catch {
    return "invalid-url";
  }
}

export function buildStaticNGeniusDiagnostics(): Omit<
  NGeniusSafeDiagnostics,
  | "identityStatus"
  | "createOrderStatus"
  | "ok"
  | "providerHttpStatus"
  | "providerErrorCode"
  | "providerMessage"
  | "apiKeyLen"
  | "hasHostedPaymentUrl"
  | "readiness"
> {
  const env = getEnv({ requireSecrets: false });
  const baseHost = baseHostOf(env.ngeniusBaseUrl);
  const usesSandboxHost = baseHost.includes("sandbox");
  const notes: string[] = [];
  if (env.NGENIUS_ENV === "production" && usesSandboxHost) {
    notes.push("NGENIUS_ENV=production but base host still contains sandbox");
  }
  if (env.NGENIUS_ENV === "sandbox" && !usesSandboxHost) {
    notes.push("NGENIUS_ENV=sandbox but base host is not a sandbox host");
  }
  const identityBodyStyle = resolveNGeniusIdentityBodyStyle(env.ngeniusRealm, {
    identityUrl: env.ngeniusIdentityUrl,
    baseUrl: env.ngeniusBaseUrl,
  });
  if (
    isArabiaNoteNeeded(env.ngeniusRealm) &&
    isKsaNGeniusHost(env.ngeniusBaseUrl)
  ) {
    notes.push(
      "Arabia realm on KSA host uses CF identity body (grant_type+realm), not realmName.",
    );
  }
  return {
    environment: env.NGENIUS_ENV,
    baseHost,
    identityHost: baseHostOf(env.ngeniusIdentityUrl),
    realm: env.ngeniusRealm,
    outletRefMasked: maskOutletRef(env.NGENIUS_OUTLET_REF),
    usesProductionBaseUrl: env.NGENIUS_ENV === "production",
    usesSandboxHost,
    identityHostFamily: isKsaNGeniusHost(env.ngeniusBaseUrl) ? "ksa" : "global",
    identityBodyStyle,
    configured: envPresence(),
    webhookPath: "/webhooks/ngenius",
    notes,
  };
}

function isArabiaNoteNeeded(realm: string): boolean {
  return /^niarabia$/i.test(String(realm || "").trim());
}

/** Identity-only probe — never logs tokens or API keys. */
export async function probeNGeniusIdentity(): Promise<NGeniusSafeDiagnostics> {
  const env = getEnv();
  const base = buildStaticNGeniusDiagnostics();
  resetNGeniusTokenCacheForTests();
  const apiKeyLen = normalizeNGeniusApiKeyForBasicAuth(env.NGENIUS_API_KEY).length;

  try {
    // Uses primary body + one alternate retry on HTTP 400.
    await getNGeniusAccessToken();
    return {
      ...base,
      ok: true,
      identityStatus: "ok",
      createOrderStatus: "skipped",
      apiKeyLen,
      readiness: "NOT_READY",
      notes: [
        ...base.notes,
        "Identity OK. Create-order not probed (use POST /health/ngenius/hpp-probe with ALLOW_HPP_PROBE=true).",
      ],
    };
  } catch (error) {
    logger.error("ngenius_identity_probe_failed", {
      name: error instanceof Error ? error.name : "unknown",
      code: error instanceof ApiError ? error.code : undefined,
    });
    return {
      ...base,
      ok: false,
      identityStatus: "failed",
      createOrderStatus: "skipped",
      providerErrorCode:
        error instanceof ApiError ? error.code : PaymentErrorCode.PROVIDER_UNAVAILABLE,
      apiKeyLen,
      readiness: "NOT_READY",
    };
  }
}

/**
 * Auth + create hosted payment page order only.
 * Does not capture/pay a card. Requires ALLOW_HPP_PROBE=true.
 */
export async function probeNGeniusHostedPaymentPage(): Promise<NGeniusSafeDiagnostics> {
  const allow = String(process.env.ALLOW_HPP_PROBE || "").toLowerCase() === "true";
  const base = buildStaticNGeniusDiagnostics();
  if (!allow) {
    return {
      ...base,
      ok: false,
      identityStatus: "skipped",
      createOrderStatus: "blocked",
      readiness: "NOT_READY",
      notes: [
        ...base.notes,
        "Set ALLOW_HPP_PROBE=true temporarily to run create-order probe (no card capture).",
      ],
    };
  }

  const identity = await probeNGeniusIdentity();
  if (identity.identityStatus !== "ok") {
    return {
      ...identity,
      createOrderStatus: "skipped",
      readiness: "NOT_READY",
    };
  }

  try {
    const order = await createNGeniusOrder({
      amountMinor: 100,
      currency: "SAR",
      merchantOrderReference: `TouryProbe-${Date.now().toString(36)}`,
    });
    const hasUrl = Boolean(order.paymentUrl);
    const readiness =
      hasUrl && base.environment === "production"
        ? "PRODUCTION_HPP_READY"
        : hasUrl
          ? "SANDBOX_HPP_READY"
          : "NOT_READY";
    logger.info("ngenius_hpp_probe_result", {
      environment: base.environment,
      readiness,
      hasHostedPaymentUrl: hasUrl,
      outletRefMasked: base.outletRefMasked,
    });
    return {
      ...identity,
      ok: hasUrl,
      createOrderStatus: hasUrl ? "ok" : "failed",
      hasHostedPaymentUrl: hasUrl,
      readiness,
      notes: [
        ...base.notes,
        "Create-order returned hosted payment page URL. Do not complete a real card payment from automation.",
        "Unset ALLOW_HPP_PROBE after the probe.",
      ],
    };
  } catch (error) {
    logger.error("ngenius_hpp_probe_create_failed", {
      code: error instanceof ApiError ? error.code : undefined,
      name: error instanceof Error ? error.name : "unknown",
    });
    return {
      ...identity,
      ok: false,
      createOrderStatus: "failed",
      providerErrorCode:
        error instanceof ApiError ? error.code : PaymentErrorCode.PROVIDER_UNAVAILABLE,
      readiness: "NOT_READY",
    };
  }
}
