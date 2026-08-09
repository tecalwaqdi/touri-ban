import { getEnv, type AppEnv } from "@/lib/security/env";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { logger } from "@/lib/logging/logger";

type TokenCache = { token: string; expiresAt: number };
let tokenCache: TokenCache | null = null;

/** Official N-Genius identity Content-Type (Pay Page / gateway). */
export const NGENIUS_IDENTITY_CONTENT_TYPE =
  "application/vnd.ni-identity.v1+json";

/**
 * Portal API keys are already Base64 material — use as-is after Basic prefix.
 * Strip accidental "Basic " paste and whitespace; never re-encode.
 */
export function normalizeNGeniusApiKeyForBasicAuth(raw: string): string {
  let key = String(raw || "").trim();
  if (/^basic\s+/i.test(key)) {
    key = key.replace(/^basic\s+/i, "").trim();
  }
  return key;
}

/**
 * Identity request body.
 * - KSA / Arabia hosts (*.ksa.ngenius-payments.com): docs require `{ "realmName": "..." }`
 *   (portal may issue custom realms such as `NIARABIA`).
 * - Global hosts: Firebase CF style `{ grant_type, realm }` (+ realmName alias).
 */
export function isKsaNGeniusHost(baseOrIdentityUrl: string): boolean {
  try {
    return new URL(baseOrIdentityUrl).host.toLowerCase().includes("ksa.ngenius-payments.com");
  } catch {
    return /ksa\.ngenius-payments\.com/i.test(baseOrIdentityUrl);
  }
}

export type NGeniusIdentityBody =
  | { realmName: string }
  | {
      grant_type: "client_credentials";
      realm: string;
      realmName: string;
    };

export function buildNGeniusIdentityBody(
  realm: string,
  options?: { identityUrl?: string; baseUrl?: string },
): NGeniusIdentityBody {
  const value = String(realm || "ni").trim() || "ni";
  const hostHint = options?.identityUrl || options?.baseUrl || "";
  if (isKsaNGeniusHost(hostHint)) {
    return { realmName: value };
  }
  return {
    grant_type: "client_credentials",
    realm: value,
    realmName: value,
  };
}

export function buildNGeniusIdentityRequest(env: Pick<
  AppEnv,
  "ngeniusIdentityUrl" | "NGENIUS_API_KEY" | "ngeniusRealm" | "NGENIUS_ENV" | "ngeniusBaseUrl"
>): {
  url: string;
  method: "POST";
  headers: Record<string, string>;
  body: string;
  bodyJson: NGeniusIdentityBody;
} {
  const apiKey = normalizeNGeniusApiKeyForBasicAuth(env.NGENIUS_API_KEY);
  const bodyJson = buildNGeniusIdentityBody(env.ngeniusRealm, {
    identityUrl: env.ngeniusIdentityUrl,
    baseUrl: env.ngeniusBaseUrl,
  });
  return {
    url: env.ngeniusIdentityUrl,
    method: "POST",
    headers: {
      Accept: NGENIUS_IDENTITY_CONTENT_TYPE,
      "Content-Type": NGENIUS_IDENTITY_CONTENT_TYPE,
      Authorization: `Basic ${apiKey}`,
    },
    body: JSON.stringify(bodyJson),
    bodyJson,
  };
}

function safeProviderErrorSnippet(rawText: string): {
  providerCode?: string;
  providerMessage?: string;
} {
  try {
    const parsed = JSON.parse(rawText) as Record<string, unknown>;
    const code = parsed.code ?? parsed.error ?? parsed.errorCode ?? parsed.status;
    const message =
      parsed.message ??
      parsed.error_description ??
      parsed.errorMessage ??
      parsed.title;
    const out: { providerCode?: string; providerMessage?: string } = {};
    if (typeof code === "string" || typeof code === "number") {
      out.providerCode = String(code).slice(0, 80);
    }
    if (typeof message === "string") {
      out.providerMessage = message.slice(0, 160);
    }
    return out;
  } catch {
    // Non-JSON body — do not log raw text (may contain sensitive fragments).
    return {};
  }
}

export async function getNGeniusAccessToken(): Promise<string> {
  const env = getEnv();
  if (tokenCache && Date.now() < tokenCache.expiresAt - 30_000) {
    return tokenCache.token;
  }

  const identity = buildNGeniusIdentityRequest(env);
  const res = await fetch(identity.url, {
    method: identity.method,
    headers: identity.headers,
    body: identity.body,
    signal: AbortSignal.timeout(12_000),
  });

  if (!res.ok) {
    const rawText = await res.text().catch(() => "");
    const snippet = safeProviderErrorSnippet(rawText);
    logger.error("ngenius_identity_failed", {
      status: res.status,
      environment: env.NGENIUS_ENV,
      identityPath: "/identity/auth/access-token",
      realmName: env.ngeniusRealm,
      ...snippet,
    });
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
  }
  const data = (await res.json()) as { access_token?: string; expires_in?: number };
  if (!data.access_token) {
    logger.error("ngenius_identity_failed", {
      status: res.status,
      environment: env.NGENIUS_ENV,
      identityPath: "/identity/auth/access-token",
      reason: "missing_access_token",
    });
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
  }
  tokenCache = {
    token: data.access_token,
    expiresAt: Date.now() + (data.expires_in ?? 300) * 1000,
  };
  return data.access_token;
}

/** Test helper — clears cached bearer token. */
export function resetNGeniusTokenCacheForTests(): void {
  tokenCache = null;
}

function outletOrdersUrl(): string {
  const env = getEnv();
  return `${env.ngeniusBaseUrl}/transactions/outlets/${env.NGENIUS_OUTLET_REF}/orders`;
}

export function extractPaymentUrl(data: unknown): string | null {
  const obj = data as {
    _links?: { payment?: { href?: string }; "payment:card"?: { href?: string } };
  };
  return (
    obj?._links?.payment?.href ||
    obj?._links?.["payment:card"]?.href ||
    null
  );
}

export function extractOrderReference(data: unknown): string | null {
  const obj = data as {
    reference?: string;
    _id?: string;
    order?: { reference?: string; _id?: string };
    orderReference?: string;
  };
  // Hosted-order create response OR nested webhook event.order
  return (
    obj.reference ||
    obj._id ||
    obj.order?.reference ||
    obj.order?._id ||
    obj.orderReference ||
    null
  );
}

/** N-Genius: alphanumeric + hyphen only (docs.ksa list-of-order-input-attributes). */
export function sanitizeMerchantOrderReference(value: string): string {
  const cleaned = String(value || "")
    .trim()
    .slice(0, 50)
    .replace(/[^a-zA-Z0-9-]/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  return cleaned.slice(0, 37) || "TouryBooking";
}

function isValidEmailAddress(value: string | undefined): value is string {
  if (!value) return false;
  const email = value.trim();
  if (email.length < 5 || email.length > 128) return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function maskOutletRef(outletRef: string): string {
  const v = String(outletRef || "");
  if (v.length <= 8) return "****";
  return `${v.slice(0, 4)}…${v.slice(-4)}`;
}

export type NGeniusCreateOrderBody = {
  action: "PURCHASE" | "AUTH";
  amount: { currencyCode: string; value: number };
  merchantAttributes: { redirectUrl: string; cancelUrl: string };
  merchantOrderReference: string;
  emailAddress?: string;
};

/**
 * Build the exact KSA Pay Page create-order JSON (no unsupported fields).
 * amount.value must be a positive integer in minor units (halalas for SAR).
 */
export function buildNGeniusCreateOrderBody(input: {
  amountMinor: number;
  currency: string;
  email?: string;
  merchantOrderReference: string;
  redirectUrl: string;
  cancelUrl: string;
}): NGeniusCreateOrderBody {
  const currencyCode = String(input.currency || "SAR").trim().toUpperCase();
  if (!Number.isInteger(input.amountMinor) || input.amountMinor < 1) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, "Invalid amount");
  }
  if (!/^https:\/\//i.test(input.redirectUrl) || !/^https:\/\//i.test(input.cancelUrl)) {
    throw new ApiError(PaymentErrorCode.CONFIG_ERROR, 500, "Invalid payment return URL");
  }

  const body: NGeniusCreateOrderBody = {
    action: "PURCHASE",
    amount: {
      currencyCode,
      value: input.amountMinor,
    },
    merchantAttributes: {
      redirectUrl: input.redirectUrl,
      cancelUrl: input.cancelUrl,
    },
    merchantOrderReference: sanitizeMerchantOrderReference(
      input.merchantOrderReference,
    ),
  };
  if (isValidEmailAddress(input.email)) {
    body.emailAddress = input.email.trim();
  }
  return body;
}

function safeCreateOrderErrorSnippet(rawText: string): {
  providerCode?: string;
  providerMessage?: string;
  providerDetails?: string;
  providerErrorCode?: string;
} {
  try {
    const parsed = JSON.parse(rawText) as Record<string, unknown>;
    const errors = parsed.errors;
    const firstError =
      Array.isArray(errors) && errors.length > 0
        ? (errors[0] as Record<string, unknown>)
        : null;
    const code =
      parsed.code ??
      parsed.errorCode ??
      parsed.error ??
      firstError?.code ??
      firstError?.errorCode;
    const nestedErrorCode = firstError?.errorCode ?? parsed.errorCode;
    const message =
      parsed.message ??
      parsed.errorMessage ??
      parsed.error_description ??
      firstError?.message ??
      firstError?.description;
    const details =
      parsed.details ??
      parsed.description ??
      firstError?.details ??
      firstError?.field ??
      firstError?.localizedMessage;
    const out: {
      providerCode?: string;
      providerMessage?: string;
      providerDetails?: string;
      providerErrorCode?: string;
    } = {};
    if (typeof code === "string" || typeof code === "number") {
      out.providerCode = String(code).slice(0, 80);
    }
    if (typeof nestedErrorCode === "string" || typeof nestedErrorCode === "number") {
      out.providerErrorCode = String(nestedErrorCode).slice(0, 80);
    }
    if (typeof message === "string") {
      out.providerMessage = message.slice(0, 160);
    }
    if (typeof details === "string") {
      out.providerDetails = details.slice(0, 160);
    } else if (Array.isArray(details)) {
      out.providerDetails = JSON.stringify(details).slice(0, 160);
    }
    return out;
  } catch {
    return {};
  }
}

/**
 * Map N-Genius create-order HTTP failures to stable app codes.
 * Never treat outlet/config failures as card-entry or decline errors.
 */
export function classifyNGeniusCreateOrderFailure(
  status: number,
  rawText: string,
): PaymentErrorCode {
  const snippet = safeCreateOrderErrorSnippet(rawText);
  const haystack = [
    snippet.providerErrorCode,
    snippet.providerCode,
    snippet.providerMessage,
    snippet.providerDetails,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  if (
    haystack.includes("configfetcherror") ||
    haystack.includes("failed to get configuration") ||
    (haystack.includes("outlet") && haystack.includes("config"))
  ) {
    return PaymentErrorCode.PROVIDER_OUTLET_NOT_CONFIGURED;
  }

  if (status === 401 || status === 403) {
    return PaymentErrorCode.PROVIDER_UNAVAILABLE;
  }
  if (status === 422 || status >= 500 || status === 404) {
    return PaymentErrorCode.PROVIDER_UNAVAILABLE;
  }
  return PaymentErrorCode.PROVIDER_UNAVAILABLE;
}

export async function createNGeniusOrder(input: {
  amountMinor: number;
  currency: string;
  email?: string;
  merchantOrderReference: string;
}): Promise<{ providerOrderRef: string; paymentUrl: string; rawState: string }> {
  const env = getEnv();
  const token = await getNGeniusAccessToken();
  const redirectUrl =
    env.PAYMENT_RETURN_BASE_URL ||
    "https://tutorial-multi-language-70gx4j.web.app/payment-return.html";
  const cancelUrl = env.PAYMENT_CANCEL_BASE_URL || redirectUrl;

  const orderBody = buildNGeniusCreateOrderBody({
    amountMinor: input.amountMinor,
    currency: input.currency,
    email: input.email,
    merchantOrderReference: input.merchantOrderReference,
    redirectUrl,
    cancelUrl,
  });

  const res = await fetch(outletOrdersUrl(), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/vnd.ni-payment.v2+json",
      Accept: "application/vnd.ni-payment.v2+json",
    },
    body: JSON.stringify(orderBody),
    signal: AbortSignal.timeout(15_000),
  });

  if (!res.ok) {
    const rawText = await res.text().catch(() => "");
    const snippet = safeCreateOrderErrorSnippet(rawText);
    const appCode = classifyNGeniusCreateOrderFailure(res.status, rawText);
    logger.error("ngenius_create_order_failed", {
      status: res.status,
      environment: env.NGENIUS_ENV,
      action: orderBody.action,
      currencyCode: orderBody.amount.currencyCode,
      amountValue: orderBody.amount.value,
      hasRedirectUrl: Boolean(orderBody.merchantAttributes.redirectUrl),
      hasCancelUrl: Boolean(orderBody.merchantAttributes.cancelUrl),
      hasEmail: Boolean(orderBody.emailAddress),
      merchantOrderReferenceLength: orderBody.merchantOrderReference.length,
      outletRefMasked: maskOutletRef(env.NGENIUS_OUTLET_REF),
      appCode,
      ...snippet,
    });
    // 502 Bad Gateway — provider rejected create-order (not a card error).
    throw new ApiError(appCode, 502);
  }
  const body = await res.json();
  const providerOrderRef = extractOrderReference(body);
  const paymentUrl = extractPaymentUrl(body);
  if (!providerOrderRef || !paymentUrl) {
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
  }
  return {
    providerOrderRef,
    paymentUrl,
    rawState: String((body as { state?: string }).state || "STARTED"),
  };
}

export async function fetchNGeniusOrder(providerOrderRef: string): Promise<unknown> {
  const env = getEnv();
  const token = await getNGeniusAccessToken();
  const url = `${env.ngeniusBaseUrl}/transactions/outlets/${env.NGENIUS_OUTLET_REF}/orders/${providerOrderRef}`;
  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.ni-payment.v2+json",
    },
    signal: AbortSignal.timeout(12_000),
  });
  if (!res.ok) {
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
  }
  return res.json();
}

export function extractGatewayState(orderData: unknown): string {
  const obj = orderData as {
    state?: string;
    _embedded?: { payment?: Array<{ state?: string }> };
  };
  const paymentState = obj._embedded?.payment?.[0]?.state;
  return String(paymentState || obj.state || "");
}

export function extractGatewayAmount(orderData: unknown): {
  currency?: string;
  value?: number;
} {
  const obj = orderData as {
    amount?: { currencyCode?: string; value?: number };
  };
  return {
    currency: obj.amount?.currencyCode,
    value: obj.amount?.value,
  };
}

function assertGatewayUrl(url: string, envBase: string): string {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 400);
  }
  if (!parsed.hostname.endsWith("ngenius-payments.com")) {
    throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 400);
  }
  return parsed.toString();
}

/** Locate cnp:refund link from N-Genius order payload (same as CF). */
export function refundLinkFromOrder(orderData: unknown): string | null {
  const obj = orderData as {
    _embedded?: {
      payment?: Array<{
        _links?: Record<string, { href?: string }>;
        _embedded?: {
          "cnp:capture"?: Array<{
            _links?: Record<string, { href?: string }>;
          }>;
        };
      }>;
    };
  };
  const payment = obj._embedded?.payment?.[0];
  const direct = payment?._links?.["cnp:refund"]?.href;
  if (direct) return direct;
  const captures = payment?._embedded?.["cnp:capture"] || [];
  for (const capture of captures) {
    const link = capture._links?.["cnp:refund"]?.href;
    if (link) return link;
  }
  return null;
}

export async function refundNGeniusOrder(input: {
  providerOrderRef: string;
  amountMinor: number;
  currency: string;
}): Promise<{ state: string }> {
  const env = getEnv();
  const orderData = await fetchNGeniusOrder(input.providerOrderRef);
  const refundUrl = refundLinkFromOrder(orderData);
  if (!refundUrl) {
    throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 409);
  }
  const token = await getNGeniusAccessToken();
  const res = await fetch(assertGatewayUrl(refundUrl, env.ngeniusBaseUrl), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/vnd.ni-payment.v2+json",
      Accept: "application/vnd.ni-payment.v2+json",
    },
    body: JSON.stringify({
      amount: {
        currencyCode: input.currency,
        value: input.amountMinor,
      },
    }),
    signal: AbortSignal.timeout(12_000),
  });
  if (!res.ok) {
    logger.error("ngenius_refund_failed", { status: res.status });
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
  }
  const body = (await res.json()) as { state?: string };
  return { state: String(body.state || "") };
}
