import { describe, expect, it } from "vitest";
import {
  assertAmountMatch,
  assertBearerPresent,
  assertBookingPurposeOnly,
  assertCancellable,
  assertCurrencyMatch,
  assertOutletMatch,
  assertWebhookSecret,
  computeRefundable,
  normalizePaymentPurpose,
} from "@/lib/payments/guards";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { calculateBookingQuote } from "@/lib/pricing/booking";
import { parseBookingDraft } from "@/lib/bookings/build-order";
import { PaymentStatus, transitionStatus } from "@/lib/payments/status";

function expectCode(fn: () => void, code: PaymentErrorCode) {
  try {
    fn();
    expect.fail("expected throw");
  } catch (e) {
    expect(e).toBeInstanceOf(ApiError);
    expect((e as ApiError).code).toBe(code);
  }
}

describe("auth header", () => {
  it("rejects missing Firebase token", () => {
    expectCode(() => assertBearerPresent(null), PaymentErrorCode.AUTH_REQUIRED);
    expectCode(() => assertBearerPresent(""), PaymentErrorCode.AUTH_REQUIRED);
    expectCode(() => assertBearerPresent("Basic x"), PaymentErrorCode.AUTH_REQUIRED);
  });

  it("accepts Bearer shape (token validity is Firebase Admin)", () => {
    expect(assertBearerPresent("Bearer abc.def.ghi")).toBe("abc.def.ghi");
  });
});

describe("purpose / wallet-extra-hours gate", () => {
  it("rejects extra_hours on external create; booking allowed", () => {
    expectCode(() => assertBookingPurposeOnly("extra_hours"), PaymentErrorCode.INVALID_REQUEST);
    expect(() => assertBookingPurposeOnly("booking")).not.toThrow();
  });

  it("maps purpose aliases", () => {
    expect(normalizePaymentPurpose("wallet_topup")).toBe("wallet");
    expect(normalizePaymentPurpose("booking_payment")).toBe("booking");
  });
});

describe("webhook guards", () => {
  it("rejects invalid webhook secret", () => {
    expectCode(() => assertWebhookSecret("wrong", "secret"), PaymentErrorCode.WEBHOOK_INVALID);
    expectCode(() => assertWebhookSecret(null, "secret"), PaymentErrorCode.WEBHOOK_INVALID);
  });

  it("accepts matching secret", () => {
    expect(() => assertWebhookSecret("secret", "secret")).not.toThrow();
  });

  it("rejects wrong outlet", () => {
    expectCode(
      () => assertOutletMatch("outlet-a", "outlet-b"),
      PaymentErrorCode.WEBHOOK_INVALID,
    );
  });

  it("rejects wrong amount", () => {
    expectCode(() => assertAmountMatch(1000, 999), PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH);
  });

  it("rejects wrong currency", () => {
    expectCode(
      () => assertCurrencyMatch("SAR", "AED"),
      PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH,
    );
  });
});

describe("cancel / refund guards", () => {
  it("rejects cancellation of paid payment", () => {
    expectCode(() => assertCancellable(PaymentStatus.paid), PaymentErrorCode.REFUND_NOT_ALLOWED);
  });

  it("allows cancel of pending", () => {
    expect(() => assertCancellable(PaymentStatus.pending)).not.toThrow();
  });

  it("computes full and partial refundable amounts", () => {
    expect(computeRefundable(5000, 0).amount).toBe(5000);
    expect(computeRefundable(5000, 1000, 2000).amount).toBe(2000);
    expectCode(() => computeRefundable(5000, 5000), PaymentErrorCode.REFUND_NOT_ALLOWED);
    expectCode(() => computeRefundable(5000, 0, 6000), PaymentErrorCode.REFUND_NOT_ALLOWED);
  });
});

describe("idempotency / race model", () => {
  it("duplicate paid transition stays paid", () => {
    expect(
      transitionStatus(PaymentStatus.paid, PaymentStatus.paid),
    ).toBe(PaymentStatus.paid);
  });

  it("paid cannot become pending via polling race", () => {
    expect(
      transitionStatus(PaymentStatus.paid, PaymentStatus.pending),
    ).toBe(PaymentStatus.paid);
  });
});

describe("pricing mismatch and unsupported currency", () => {
  it("server pricing rejects unsupported currency", () => {
    expectCode(
      () =>
        calculateBookingQuote({
          hourlyRateMajor: 10,
          bookingHours: 1,
          additionalHours: 0,
          currency: "ZZZ",
        }),
      PaymentErrorCode.UNSUPPORTED_CURRENCY,
    );
  });

  it("documents cash flow independence (no card purpose)", () => {
    // Cash never calls payment-api create; purpose gate is irrelevant.
    expect(() => assertBookingPurposeOnly("booking")).not.toThrow();
  });
});

describe("malformed booking draft", () => {
  it("rejects missing draft object", () => {
    expectCode(() => parseBookingDraft(null), PaymentErrorCode.BOOKING_NOT_PAYABLE);
  });

  it("rejects out-of-range coordinates", () => {
    expectCode(
      () => parseBookingDraft({ pickupLat: 999, pickupLng: 1 }),
      PaymentErrorCode.INVALID_REQUEST,
    );
  });
});
