import { describe, expect, it } from "vitest";
import { assertCancellable } from "@/lib/payments/guards";
import { PaymentErrorCode } from "@/lib/errors/codes";

describe("cancel attempt vs paid booking", () => {
  it("allows cancelling a pending attempt", () => {
    expect(() => assertCancellable("pending")).not.toThrow();
    expect(() => assertCancellable("created")).not.toThrow();
    expect(() => assertCancellable("authentication_required")).not.toThrow();
  });

  it("does not cancel a paid session as an attempt", () => {
    expect(() => assertCancellable("paid")).toThrow();
    try {
      assertCancellable("paid");
    } catch (e: unknown) {
      expect((e as { code: string }).code).toBe(
        PaymentErrorCode.REFUND_NOT_ALLOWED,
      );
    }
  });
});
