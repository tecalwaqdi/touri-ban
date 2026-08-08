import { describe, expect, it } from "vitest";
import {
  mapNGeniusState,
  PaymentStatus,
  transitionStatus,
} from "@/lib/payments/status";
import { calculateBookingQuote } from "@/lib/pricing/booking";
import { majorToMinor, percentOfMinor } from "@/lib/currency/minor";

describe("status mapping", () => {
  it("maps purchased/captured to paid", () => {
    expect(mapNGeniusState("PURCHASED")).toBe(PaymentStatus.paid);
    expect(mapNGeniusState("CAPTURED")).toBe(PaymentStatus.paid);
  });

  it("blocks paid → pending", () => {
    expect(
      transitionStatus(PaymentStatus.paid, PaymentStatus.pending),
    ).toBe(PaymentStatus.paid);
  });

  it("allows pending → paid", () => {
    expect(
      transitionStatus(PaymentStatus.pending, PaymentStatus.paid),
    ).toBe(PaymentStatus.paid);
  });

  it("allows paid → refunded", () => {
    expect(
      transitionStatus(PaymentStatus.paid, PaymentStatus.refunded),
    ).toBe(PaymentStatus.refunded);
  });
});

describe("webhook order reference extraction", () => {
  it("reads nested N-Genius event.order.reference", async () => {
    const { extractOrderReference } = await import("@/lib/ngenius/client");
    expect(
      extractOrderReference({
        eventName: "PURCHASED",
        order: { reference: "abc-order-ref" },
      }),
    ).toBe("abc-order-ref");
    expect(extractOrderReference({ reference: "flat-ref" })).toBe("flat-ref");
  });
});

describe("pricing", () => {
  it("calculates booking quote in minor units without float drift", () => {
    const quote = calculateBookingQuote({
      hourlyRateMajor: 100,
      bookingHours: 2,
      additionalHours: 0,
      currency: "SAR",
    });
    expect(quote.amountMinor).toBe(20000);
    expect(quote.baseFareMinor).toBe(20000);
    expect(quote.platformFeeMinor).toBe(percentOfMinor(20000, 15));
  });

  it("rejects zero/negative payable after discount abuse path", () => {
    expect(() =>
      calculateBookingQuote({
        hourlyRateMajor: 1,
        bookingHours: 1,
        additionalHours: 1,
        discountPercentOnAdditional: 100,
        discountCapMajor: 1000,
        currency: "SAR",
      }),
    ).toThrow();
  });

  it("converts major to minor", () => {
    expect(majorToMinor(10, "SAR")).toBe(1000);
  });
});
