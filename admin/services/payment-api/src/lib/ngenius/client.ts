import { getEnv } from "@/lib/security/env";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { logger } from "@/lib/logging/logger";

type TokenCache = { token: string; expiresAt: number };
let tokenCache: TokenCache | null = null;

export async function getNGeniusAccessToken(): Promise<string> {
  const env = getEnv();
  if (tokenCache && Date.now() < tokenCache.expiresAt - 30_000) {
    return tokenCache.token;
  }

  const res = await fetch(env.ngeniusIdentityUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/vnd.ni-identity.v1+json",
      Authorization: `Basic ${env.NGENIUS_API_KEY}`,
    },
    body: JSON.stringify({
      grant_type: "client_credentials",
      realm: env.ngeniusRealm,
    }),
    signal: AbortSignal.timeout(12_000),
  });

  if (!res.ok) {
    logger.error("ngenius_identity_failed", { status: res.status });
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
  }
  const data = (await res.json()) as { access_token?: string; expires_in?: number };
  if (!data.access_token) {
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
  }
  tokenCache = {
    token: data.access_token,
    expiresAt: Date.now() + (data.expires_in ?? 300) * 1000,
  };
  return data.access_token;
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

  const res = await fetch(outletOrdersUrl(), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/vnd.ni-payment.v2+json",
      Accept: "application/vnd.ni-payment.v2+json",
    },
    body: JSON.stringify({
      action: "PURCHASE",
      amount: {
        currencyCode: input.currency,
        value: input.amountMinor,
      },
      emailAddress: input.email || undefined,
      merchantAttributes: { redirectUrl, cancelUrl },
      merchantOrderReference: input.merchantOrderReference.slice(0, 50),
    }),
    signal: AbortSignal.timeout(15_000),
  });

  if (!res.ok) {
    logger.error("ngenius_create_order_failed", { status: res.status });
    throw new ApiError(PaymentErrorCode.PROVIDER_UNAVAILABLE, 502);
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
