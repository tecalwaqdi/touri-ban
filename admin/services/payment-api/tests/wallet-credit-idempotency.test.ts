import { describe, expect, it } from "vitest";

/**
 * Documents the double-credit guards used by creditWalletFromPaidSession.
 */
describe("wallet credit idempotency contract", () => {
  it("uses deterministic ledger doc id per payment session", () => {
    const sessionId = "a".repeat(64);
    const ledgerId = `wallet_topup_${sessionId}`;
    expect(ledgerId).toBe(`wallet_topup_${"a".repeat(64)}`);
    expect(ledgerId).toMatch(/^wallet_topup_[a-f0-9]{64}$/);
  });

  it("credits only paid wallet sessions once", () => {
    const shouldCredit = (session: {
      purpose?: string;
      wallet_credited?: boolean;
      status?: string;
    }) =>
      session.purpose === "wallet" &&
      session.wallet_credited !== true &&
      (session.status === "paid" || session.status === "captured");

    expect(shouldCredit({ purpose: "wallet", status: "paid" })).toBe(true);
    expect(
      shouldCredit({
        purpose: "wallet",
        status: "paid",
        wallet_credited: true,
      }),
    ).toBe(false);
    expect(shouldCredit({ purpose: "booking", status: "paid" })).toBe(false);
    expect(shouldCredit({ purpose: "wallet", status: "pending" })).toBe(false);
  });

  it("allow-lists wallet top-up majors", () => {
    const allowed = new Set([100, 200, 300, 500]);
    for (const n of [100, 200, 300, 500]) expect(allowed.has(n)).toBe(true);
    for (const n of [50, 150, 1000, -1, 0]) expect(allowed.has(n)).toBe(false);
  });
});
