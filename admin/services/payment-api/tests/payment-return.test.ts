import { describe, expect, it } from "vitest";
import {
  CUSTOMER_PAYMENT_DEEPLINK_BASE,
  DEFAULT_PAYMENT_RETURN_URL,
} from "@/lib/payments/payment-return";

describe("payment return defaults", () => {
  it("does not point at Firebase Admin hosting", () => {
    expect(DEFAULT_PAYMENT_RETURN_URL).toBe(
      "https://touri-ban.onrender.com/payment-return",
    );
    expect(DEFAULT_PAYMENT_RETURN_URL).not.toContain("web.app");
    expect(DEFAULT_PAYMENT_RETURN_URL).not.toContain("/admin");
  });

  it("deep-links into Customer paymentConfirm", () => {
    expect(CUSTOMER_PAYMENT_DEEPLINK_BASE).toBe(
      "araoatanapp://araoatanapp.com/paymentConfirm",
    );
  });
});
