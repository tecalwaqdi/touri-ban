/**
 * CF-side mirror of payment-api FX contract (Phase 4 — not wired).
 * When an FX provider is approved, call convertToSarMinor before createNGeniusOrder.
 */

function convertToSarMinor({
  originalAmountMinor,
  originalCurrency,
  exchangeRateMajor,
  originalMinorDigits,
}) {
  if (
    !Number.isInteger(originalAmountMinor) ||
    originalAmountMinor < 0 ||
    !Number.isFinite(exchangeRateMajor) ||
    exchangeRateMajor <= 0
  ) {
    throw new Error("INVALID_FX_INPUT");
  }
  if (String(originalCurrency || "").toUpperCase() === "SAR") {
    return originalAmountMinor;
  }
  const originalMajor = originalAmountMinor / 10 ** originalMinorDigits;
  const sarMinor = Math.round(originalMajor * exchangeRateMajor * 100);
  if (sarMinor < 1) throw new Error("FX_AMOUNT_TOO_SMALL");
  return sarMinor;
}

function buildFxMoneySnapshot({
  originalAmountMinor,
  originalCurrency,
  exchangeRateMajor,
  rateTimestamp,
  fxProvider,
  originalMinorDigits,
}) {
  return {
    originalAmount: originalAmountMinor,
    originalCurrency: String(originalCurrency || "").toUpperCase(),
    exchangeRate: String(exchangeRateMajor),
    convertedAmountSAR: convertToSarMinor({
      originalAmountMinor,
      originalCurrency,
      exchangeRateMajor,
      originalMinorDigits,
    }),
    rateTimestamp:
      rateTimestamp instanceof Date
        ? rateTimestamp.toISOString()
        : String(rateTimestamp || ""),
    fxProvider: String(fxProvider || ""),
  };
}

module.exports = {
  convertToSarMinor,
  buildFxMoneySnapshot,
  FX_FREEZE_POLICY: {
    freezeAt: "payment_session_or_unpaid_order_create",
    gatewayCurrency: "SAR",
    displayCurrency: "originalCurrency",
  },
};
