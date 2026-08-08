import { describe, expect, it } from "vitest";
import {
  buildNGeniusCreateOrderBody,
  classifyNGeniusCreateOrderFailure,
  sanitizeMerchantOrderReference,
} from "@/lib/ngenius/client";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

describe("N-Genius create-order payload", () => {
  const base = {
    amountMinor: 30000,
    currency: "SAR",
    merchantOrderReference: "Toury-abc123",
    redirectUrl: "https://tutorial-multi-language-70gx4j.web.app/payment-return.html",
    cancelUrl: "https://tutorial-multi-language-70gx4j.web.app/payment-return.html",
  };

  it("builds official Pay Page PURCHASE body with SAR minor units", () => {
    const body = buildNGeniusCreateOrderBody(base);
    expect(body).toEqual({
      action: "PURCHASE",
      amount: { currencyCode: "SAR", value: 30000 },
      merchantAttributes: {
        redirectUrl: base.redirectUrl,
        cancelUrl: base.cancelUrl,
      },
      merchantOrderReference: "Toury-abc123",
    });
    expect(body).not.toHaveProperty("emailAddress");
    expect(Number.isInteger(body.amount.value)).toBe(true);
  });

  it("includes emailAddress only when valid", () => {
    expect(
      buildNGeniusCreateOrderBody({ ...base, email: "a@b.com" }).emailAddress,
    ).toBe("a@b.com");
    expect(
      buildNGeniusCreateOrderBody({ ...base, email: "not-an-email" }),
    ).not.toHaveProperty("emailAddress");
    expect(
      buildNGeniusCreateOrderBody({ ...base, email: "" }),
    ).not.toHaveProperty("emailAddress");
  });

  it("sanitizes merchantOrderReference to alphanumeric + hyphen only", () => {
    expect(
      sanitizeMerchantOrderReference(
        "أحمد / حجز جديد — 3 ساعات - الرياض",
      ),
    ).toMatch(/^[a-zA-Z0-9-]+$/);
    expect(
      sanitizeMerchantOrderReference("Toury booking #12!"),
    ).toBe("Toury-booking-12");
    expect(sanitizeMerchantOrderReference("@@@")).toBe("TouryBooking");
  });

  it("strips Arabic/spaces from merchantOrderReference in create body", () => {
    const body = buildNGeniusCreateOrderBody({
      ...base,
      merchantOrderReference: "User Name / New booking — 2 hours",
    });
    expect(body.merchantOrderReference).toMatch(/^[a-zA-Z0-9-]+$/);
    expect(body.merchantOrderReference).not.toContain(" ");
    expect(body.merchantOrderReference).not.toContain("/");
  });

  it("rejects non-integer or non-positive amount", () => {
    expect(() =>
      buildNGeniusCreateOrderBody({ ...base, amountMinor: 10.5 }),
    ).toThrow(ApiError);
    expect(() =>
      buildNGeniusCreateOrderBody({ ...base, amountMinor: 0 }),
    ).toThrow(ApiError);
  });

  it("rejects non-https redirect/cancel URLs", () => {
    expect(() =>
      buildNGeniusCreateOrderBody({
        ...base,
        redirectUrl: "http://insecure.example/return",
      }),
    ).toThrow(ApiError);
  });

  it("uppercases currencyCode", () => {
    expect(
      buildNGeniusCreateOrderBody({ ...base, currency: "sar" }).amount
        .currencyCode,
    ).toBe("SAR");
  });
});

describe("classifyNGeniusCreateOrderFailure", () => {
  it("classifies configFetchError as PROVIDER_OUTLET_NOT_CONFIGURED", () => {
    const body = JSON.stringify({
      message: "Unprocessable Entity",
      code: 422,
      errors: [
        {
          message:
            "Failed to get configuration of type: ae.network.transaction.domain.config.Outlet",
          localizedMessage: "{error.processing.configFetchError}",
          errorCode: "configFetchError",
          domain: "processing",
        },
      ],
    });
    expect(classifyNGeniusCreateOrderFailure(422, body)).toBe(
      PaymentErrorCode.PROVIDER_OUTLET_NOT_CONFIGURED,
    );
  });

  it("does not treat generic 422 as card decline", () => {
    const body = JSON.stringify({
      message: "Unprocessable Entity",
      code: 422,
    });
    expect(classifyNGeniusCreateOrderFailure(422, body)).toBe(
      PaymentErrorCode.PROVIDER_UNAVAILABLE,
    );
    expect(classifyNGeniusCreateOrderFailure(422, body)).not.toBe(
      "PAYMENT_FAILED" as never,
    );
  });
});
