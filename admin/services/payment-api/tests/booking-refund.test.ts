import { describe, expect, it } from "vitest";
import { parseBookingDraft } from "@/lib/bookings/build-order";
import {
  mapNGeniusState,
  PaymentStatus,
  transitionStatus,
} from "@/lib/payments/status";
import { refundLinkFromOrder } from "@/lib/ngenius/client";
import { calculateBookingQuote } from "@/lib/pricing/booking";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

describe("booking draft validation", () => {
  it("requires pickup coordinates", () => {
    expect(() => parseBookingDraft({})).toThrow(ApiError);
    try {
      parseBookingDraft({});
    } catch (e) {
      expect((e as ApiError).code).toBe(PaymentErrorCode.INVALID_REQUEST);
    }
  });

  it("parses a valid draft", () => {
    const draft = parseBookingDraft({
      pickupLat: 24.7,
      pickupLng: 46.7,
      cityName: "Riyadh",
      carName: "Sedan",
      tripType: "one_way",
      plannedWaypoints: [{ lat: 24.7, lng: 46.7 }, { lat: 24.8, lng: 46.8 }],
      stops: [{ name: "Mall", address: "x", city: "Riyadh", lat: 24.8, lng: 46.8 }],
    });
    expect(draft.pickupLat).toBe(24.7);
    expect(draft.stops?.length).toBe(1);
    expect(draft.plannedWaypoints?.length).toBe(2);
  });

  it("rejects malformed placePath", () => {
    expect(() =>
      parseBookingDraft({
        pickupLat: 1,
        pickupLng: 1,
        stops: [{ placePath: "bad" }],
      }),
    ).toThrow();
  });
});

describe("refund link extraction", () => {
  it("finds direct cnp:refund link", () => {
    const href = refundLinkFromOrder({
      _embedded: {
        payment: [{ _links: { "cnp:refund": { href: "https://api-gateway.sandbox.ngenius-payments.com/transactions/outlets/x/orders/y/payments/z/cancel" } } }],
      },
    });
    expect(href).toContain("ngenius-payments.com");
  });

  it("returns null when missing", () => {
    expect(refundLinkFromOrder({})).toBeNull();
  });
});

describe("state machine regressions", () => {
  it("paid cannot go back to pending", () => {
    expect(transitionStatus(PaymentStatus.paid, PaymentStatus.pending)).toBe(
      PaymentStatus.paid,
    );
  });
  it("maps declined to failed", () => {
    expect(mapNGeniusState("DECLINED")).toBe(PaymentStatus.failed);
  });
});

describe("pricing mismatch guards", () => {
  it("rejects unsupported currency", () => {
    expect(() =>
      calculateBookingQuote({
        hourlyRateMajor: 10,
        bookingHours: 1,
        additionalHours: 0,
        currency: "XXX",
      }),
    ).toThrow();
  });
});

describe("backend mode constants", () => {
  it("documents supported modes", () => {
    const modes = ["cash_only", "firebase_functions", "vercel_api"] as const;
    expect(modes).toContain("vercel_api");
  });
});
