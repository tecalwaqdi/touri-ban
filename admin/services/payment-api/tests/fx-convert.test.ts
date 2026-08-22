import { describe, expect, it } from "vitest";
import { convertToSarMinor, buildFxMoneySnapshot } from "@/lib/fx/types";

describe("fx convertToSarMinor", () => {
  it("passthrough for SAR", () => {
    expect(
      convertToSarMinor({
        originalAmountMinor: 15000,
        originalCurrency: "SAR",
        exchangeRateMajor: 99,
        originalMinorDigits: 2,
      }),
    ).toBe(15000);
  });

  it("converts 2dp local to SAR halalas", () => {
    // 100.00 KGS * 0.05 = 5.00 SAR → 500 halalas
    expect(
      convertToSarMinor({
        originalAmountMinor: 10000,
        originalCurrency: "KGS",
        exchangeRateMajor: 0.05,
        originalMinorDigits: 2,
      }),
    ).toBe(500);
  });

  it("buildFxMoneySnapshot stores audit fields", () => {
    const snap = buildFxMoneySnapshot({
      originalAmountMinor: 10000,
      originalCurrency: "kgs",
      originalMinorDigits: 2,
      rate: {
        rate: 0.05,
        rateTimestamp: new Date("2026-01-01T00:00:00.000Z"),
        fxProvider: "pending_provider",
      },
    });
    expect(snap.originalCurrency).toBe("KGS");
    expect(snap.convertedAmountSAR).toBe(500);
    expect(snap.fxProvider).toBe("pending_provider");
    expect(snap.exchangeRate).toBe("0.05");
  });
});
