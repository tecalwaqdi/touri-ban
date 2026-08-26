import { describe, expect, it } from "vitest";
import {
  analyzeNGeniusPaymentLinks,
  buildMobileSdkPayload,
  extractHostedPaymentCode,
  extractHostedPaymentPageUrl,
  extractPaymentAuthorizationUrl,
  isHostedPaymentPageUrl,
} from "@/lib/ngenius/payment-url";
import { canReuseHostedPaymentSession } from "@/lib/payments/create";
import { normalizePaymentPurpose } from "@/lib/payments/guards";

describe("hosted payment page URL", () => {
  const hpp =
    "https://paypage.sandbox.ngenius-payments.com/?code=abc123XYZ";

  it("accepts paypage hosts with code", () => {
    expect(isHostedPaymentPageUrl(hpp)).toBe(true);
    expect(
      isHostedPaymentPageUrl(
        "https://paypage.ngenius-payments.com/?code=prodCode",
      ),
    ).toBe(true);
    expect(
      isHostedPaymentPageUrl(
        "https://paypage.ksa.ngenius-payments.com/?code=ksaCode",
      ),
    ).toBe(true);
  });

  it("rejects API gateway and card API links", () => {
    expect(
      isHostedPaymentPageUrl(
        "https://api-gateway.ksa.ngenius-payments.com/transactions/outlets/x/orders/y",
      ),
    ).toBe(false);
    expect(
      isHostedPaymentPageUrl(
        "https://api-gateway.sandbox.ngenius-payments.com/transactions/outlets/x/payment/card",
      ),
    ).toBe(false);
    expect(isHostedPaymentPageUrl("https://paypage.ngenius-payments.com/")).toBe(
      false,
    );
  });

  it("extracts only _links.payment when it is HPP", () => {
    expect(
      extractHostedPaymentPageUrl({
        _links: {
          payment: { href: hpp },
          "payment:card": {
            href: "https://api-gateway.sandbox.ngenius-payments.com/x",
          },
          "cnp:payment-link": {
            href: "https://api-gateway.sandbox.ngenius-payments.com/y",
          },
        },
      }),
    ).toBe(hpp);

    expect(
      extractHostedPaymentPageUrl({
        _links: {
          "payment:card": {
            href: "https://api-gateway.sandbox.ngenius-payments.com/x",
          },
        },
      }),
    ).toBeNull();
  });

  it("reports safe link diagnostics without full URLs", () => {
    const diag = analyzeNGeniusPaymentLinks({
      _links: {
        payment: { href: hpp },
        "cnp:payment-link": {
          href: "https://api-gateway.sandbox.ngenius-payments.com/y?secret=1",
        },
      },
    });
    expect(diag.hasPaymentHref).toBe(true);
    expect(diag.hasCnpPaymentLink).toBe(true);
    expect(diag.selectedLinkKind).toBe("payment");
    expect(diag.paymentHrefHost).toBe("paypage.sandbox.ngenius-payments.com");
    expect(JSON.stringify(diag)).not.toContain("secret=1");
    expect(JSON.stringify(diag)).not.toContain("abc123XYZ");
  });
});

describe("mobile SDK payload", () => {
  const auth =
    "https://api-gateway.sandbox.ngenius-payments.com/transactions/paymentAuthorization";
  const hpp =
    "https://paypage.sandbox.ngenius-payments.com/?code=sdkCode99";

  it("extracts authorization URL and payment code", () => {
    expect(
      extractPaymentAuthorizationUrl({
        _links: { "payment-authorization": { href: auth } },
      }),
    ).toBe(auth);
    expect(extractHostedPaymentCode(hpp)).toBe("sdkCode99");
    expect(
      extractPaymentAuthorizationUrl({
        _links: { payment: { href: hpp } },
      }),
    ).toBeNull();
  });

  it("builds additive SDK payload when both links present", () => {
    const payload = buildMobileSdkPayload({
      reference: "ord-1",
      _links: {
        "payment-authorization": { href: auth },
        payment: { href: hpp },
      },
    });
    expect(payload).toEqual({
      gatewayAuthorizationUrl: auth,
      payPageUrl: hpp,
      paymentCode: "sdkCode99",
      orderReference: "ord-1",
    });
  });

  it("returns null when auth link missing (HPP-only order)", () => {
    expect(
      buildMobileSdkPayload({
        _links: { payment: { href: hpp } },
      }),
    ).toBeNull();
  });
});

describe("session HPP reuse", () => {
  const now = Date.parse("2026-08-26T12:00:00.000Z");
  const fresh = new Date(now - 5 * 60 * 1000);
  const stale = new Date(now - 20 * 60 * 1000);

  it("reuses only pending sessions with fresh HPP in same env", () => {
    expect(
      canReuseHostedPaymentSession(
        {
          status: "pending",
          environment: "production",
          payment_url:
            "https://paypage.ngenius-payments.com/?code=alive",
          hpp_refreshed_at: fresh,
        },
        "production",
        now,
      ),
    ).toBe(true);
  });

  it("does not reuse failed/expired/paid or env mismatch or API urls", () => {
    expect(
      canReuseHostedPaymentSession(
        {
          status: "failed",
          environment: "production",
          payment_url: "https://paypage.ngenius-payments.com/?code=x",
          hpp_refreshed_at: fresh,
        },
        "production",
        now,
      ),
    ).toBe(false);
    expect(
      canReuseHostedPaymentSession(
        {
          status: "pending",
          environment: "sandbox",
          payment_url: "https://paypage.ngenius-payments.com/?code=x",
          hpp_refreshed_at: fresh,
        },
        "production",
        now,
      ),
    ).toBe(false);
    expect(
      canReuseHostedPaymentSession(
        {
          status: "pending",
          environment: "production",
          payment_url:
            "https://api-gateway.ksa.ngenius-payments.com/transactions/outlets/a/orders/b",
          hpp_refreshed_at: fresh,
        },
        "production",
        now,
      ),
    ).toBe(false);
  });

  it("does not reuse HPP older than TTL", () => {
    expect(
      canReuseHostedPaymentSession(
        {
          status: "pending",
          environment: "production",
          payment_url: "https://paypage.ngenius-payments.com/?code=old",
          hpp_refreshed_at: stale,
        },
        "production",
        now,
      ),
    ).toBe(false);
  });
});

describe("purpose aliases", () => {
  it("maps booking_payment and wallet_topup", () => {
    expect(normalizePaymentPurpose("booking_payment")).toBe("booking");
    expect(normalizePaymentPurpose("wallet_topup")).toBe("wallet");
    expect(normalizePaymentPurpose("booking")).toBe("booking");
  });
});
