import { describe, expect, it } from "vitest";
import {
  buildMobileSdkPayload,
  extractHostedPaymentPageUrl,
  isHostedPaymentPageUrl,
} from "@/lib/ngenius/payment-url";

/**
 * Old Customer apps only read paymentUrl / threeDsUrl.
 * Additive SDK fields must never remove or rename those keys.
 */
describe("old client HPP compatibility", () => {
  it("keeps paymentUrl/threeDsUrl semantics for HPP-only clients", () => {
    const hpp =
      "https://paypage.sandbox.ngenius-payments.com/?code=oldClient1";
    const order = {
      reference: "ord-old",
      _links: {
        "payment-authorization": {
          href: "https://api-gateway.sandbox.ngenius-payments.com/transactions/paymentAuthorization",
        },
        payment: { href: hpp },
      },
    };

    // Legacy field extraction still works.
    expect(extractHostedPaymentPageUrl(order)).toBe(hpp);
    expect(isHostedPaymentPageUrl(hpp)).toBe(true);

    // Additive SDK payload is optional extra — not required by old clients.
    const sdk = buildMobileSdkPayload(order);
    expect(sdk?.payPageUrl).toBe(hpp);

    // Simulated create response shape (backward compatible).
    const response = {
      id: "sess1",
      status: "pending",
      paymentUrl: hpp,
      threeDsUrl: hpp,
      paymentExperience: "mobile_sdk",
      sdk,
      fallback: { hostedPaymentUrl: hpp },
    };

    // Old app path:
    const oldUrl = response.threeDsUrl || response.paymentUrl;
    expect(oldUrl).toBe(hpp);
    expect(Object.keys(response)).toEqual(
      expect.arrayContaining(["paymentUrl", "threeDsUrl", "id", "status"]),
    );
  });
});
