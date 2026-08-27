import { describe, expect, it } from "vitest";
import {
  decidePaymentLock,
  isUnpaidDraft,
} from "@/lib/payments/lock";

describe("payment lock decision", () => {
  it("resumes same unpaid booking", () => {
    const d = decidePaymentLock({
      currentOrderId: "ord_A",
      activeOrderId: "ord_A",
      activeStatusCode: "payment_pending",
      activePaymentStatus: "unpaid",
    });
    expect(d.kind).toBe("resumeSame");
  });

  it("resumes leftover unpaid checkout instead of other-booking conflict", () => {
    const d = decidePaymentLock({
      currentOrderId: null,
      activeOrderId: "ord_leftover",
      activeStatusCode: "payment_pending",
      activePaymentStatus: "unpaid",
    });
    expect(d.kind).toBe("resumeUnpaidCheckout");
  });

  it("conflicts on a different unpaid booking", () => {
    const d = decidePaymentLock({
      currentOrderId: "ord_A",
      activeOrderId: "ord_B",
      activeStatusCode: "payment_pending",
      activePaymentStatus: "unpaid",
    });
    expect(d.kind).toBe("conflictOtherPayment");
  });

  it("conflicts on operational active booking", () => {
    const d = decidePaymentLock({
      activeOrderId: "ord_live",
      activeStatusCode: "driver_assigned",
      activePaymentStatus: "paid",
    });
    expect(d.kind).toBe("conflictActiveBooking");
  });

  it("ignores terminal bookings", () => {
    const d = decidePaymentLock({
      activeOrderId: "ord_x",
      activeStatusCode: "cancelled_by_customer",
    });
    expect(d.kind).toBe("none");
  });

  it("treats failed payment_pending as unpaid draft", () => {
    expect(
      isUnpaidDraft({
        statusCode: "payment_pending",
        paymentStatus: "failed",
      }),
    ).toBe(true);
  });

  it("does not treat paid as unpaid draft", () => {
    expect(
      isUnpaidDraft({
        statusCode: "payment_pending",
        paymentStatus: "paid",
      }),
    ).toBe(false);
  });
});
