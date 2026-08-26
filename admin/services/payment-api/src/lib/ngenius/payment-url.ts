/**
 * Hosted Payment Page URL helpers.
 * Never construct paypage URLs — only accept provider hrefs that look like HPP.
 */

export function paymentHrefHost(url: string | null | undefined): string | null {
  try {
    if (!url) return null;
    return new URL(url).host.toLowerCase();
  } catch {
    return null;
  }
}

/**
 * True when href is an N-Genius Hosted Payment Page,
 * not an API order resource or cnp payment-link endpoint.
 *
 * Accepts global + KSA paypage hosts, e.g.:
 * - paypage.ngenius-payments.com
 * - paypage.sandbox.ngenius-payments.com
 * - paypage.ksa.ngenius-payments.com
 */
export function isHostedPaymentPageUrl(url: string | null | undefined): boolean {
  if (!url || typeof url !== "string") return false;
  const trimmed = url.trim();
  if (!trimmed.startsWith("https://")) return false;
  let parsed: URL;
  try {
    parsed = new URL(trimmed);
  } catch {
    return false;
  }
  const host = parsed.host.toLowerCase();
  // Never open API gateway resources in the WebView.
  if (host.includes("api-gateway")) return false;
  if (!host.endsWith("ngenius-payments.com")) return false;

  const isPaypageHost =
    host.startsWith("paypage.") ||
    host.includes(".paypage.") ||
    /(^|\.)paypage\./.test(host);
  // Some MSA portals serve HPP under paypage.* only; require that family.
  if (!isPaypageHost) return false;

  // Must carry the order access code (query). Do not rewrite/re-encode.
  if (!parsed.searchParams.has("code")) return false;
  return true;
}

export type SafePaymentLinkDiagnostics = {
  hasPaymentHref: boolean;
  paymentHrefHost: string | null;
  hasPaymentCardLink: boolean;
  hasCnpPaymentLink: boolean;
  availablePaymentLinkKeys: string[];
  selectedLinkKind: "payment" | "none";
};

/** Inspect N-Genius order _links without logging full URLs (may contain secrets). */
export function analyzeNGeniusPaymentLinks(
  data: unknown,
): SafePaymentLinkDiagnostics {
  const obj = data as {
    _links?: Record<string, { href?: string } | undefined>;
  };
  const links = obj?._links || {};
  const keys = Object.keys(links).filter((k) =>
    /payment|pay|cnp/i.test(k),
  );
  const paymentHref = links.payment?.href || null;
  const cardHref = links["payment:card"]?.href || null;
  const cnpHref = links["cnp:payment-link"]?.href || null;
  return {
    hasPaymentHref: Boolean(paymentHref),
    paymentHrefHost: paymentHrefHost(paymentHref),
    hasPaymentCardLink: Boolean(cardHref),
    hasCnpPaymentLink: Boolean(cnpHref),
    availablePaymentLinkKeys: keys.slice(0, 12),
    selectedLinkKind:
      paymentHref && isHostedPaymentPageUrl(paymentHref) ? "payment" : "none",
  };
}

/**
 * Only `_links.payment.href` when it is a real Hosted Payment Page URL.
 * Never fall back to payment:card or cnp:payment-link (API resources).
 */
export function extractHostedPaymentPageUrl(data: unknown): string | null {
  const obj = data as {
    _links?: { payment?: { href?: string } };
  };
  const href = obj?._links?.payment?.href;
  if (!href || !isHostedPaymentPageUrl(href)) {
    return null;
  }
  // Return provider string as-is (no rewrite / re-encode).
  return href;
}

/**
 * Mobile SDK auth URL — `_links.payment-authorization.href`.
 * Must be an N-Genius API gateway URL (not HPP).
 */
export function extractPaymentAuthorizationUrl(
  data: unknown,
): string | null {
  const obj = data as {
    _links?: { "payment-authorization"?: { href?: string } };
  };
  const href = obj?._links?.["payment-authorization"]?.href;
  if (!href || typeof href !== "string") return null;
  const trimmed = href.trim();
  if (!trimmed.startsWith("https://")) return null;
  let parsed: URL;
  try {
    parsed = new URL(trimmed);
  } catch {
    return null;
  }
  const host = parsed.host.toLowerCase();
  if (!host.endsWith("ngenius-payments.com")) return null;
  if (!host.includes("api-gateway")) return null;
  if (!/paymentAuthorization/i.test(parsed.pathname)) return null;
  return trimmed;
}

/** Extract HPP `code` query param for legacy CardPaymentRequest.code. */
export function extractHostedPaymentCode(payPageUrl: string | null): string | null {
  if (!payPageUrl || !isHostedPaymentPageUrl(payPageUrl)) return null;
  try {
    const code = new URL(payPageUrl).searchParams.get("code");
    return code && code.trim() ? code.trim() : null;
  } catch {
    return null;
  }
}

/**
 * Additive Mobile SDK payload (no merchant secrets).
 * Safe to return to Flutter for native bridge only.
 */
export function buildMobileSdkPayload(orderBody: unknown): {
  gatewayAuthorizationUrl: string;
  payPageUrl: string;
  paymentCode: string;
  orderReference: string | null;
} | null {
  const payPageUrl = extractHostedPaymentPageUrl(orderBody);
  const gatewayAuthorizationUrl = extractPaymentAuthorizationUrl(orderBody);
  const paymentCode = extractHostedPaymentCode(payPageUrl);
  if (!payPageUrl || !gatewayAuthorizationUrl || !paymentCode) {
    return null;
  }
  const obj = orderBody as { reference?: string; _id?: string };
  return {
    gatewayAuthorizationUrl,
    payPageUrl,
    paymentCode,
    orderReference: obj.reference || obj._id || null,
  };
}
