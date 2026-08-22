/**
 * Currency → SAR FX contract (Phase 4).
 *
 * DO NOT bind a live FX provider here. This module defines:
 * - persisted money fields
 * - freeze timing
 * - conversion helper once a rate is supplied by a future adapter
 *
 * Hook points (when provider is approved):
 * - quoteBooking / handleCreatePayment (create.ts)
 * - calculateBookingQuote result → convert → N-Genius SAR
 * - ensureUnpaidBookingOrder freeze
 * - CF verifiedBookingAmount + createNGeniusPayment (parity)
 */

export type FxMoneySnapshot = {
  /** Local payable in minor units (today's amount_halalas). */
  originalAmount: number;
  /** ISO 4217 of the country price (KGS, RUB, …). */
  originalCurrency: string;
  /**
   * Units of SAR major per 1 unit of original major
   * (e.g. 0.043 means 1 KGS = 0.043 SAR). Store as string for audit.
   */
  exchangeRate: string;
  /** SAR payable in halalas (2 decimal places). */
  convertedAmountSAR: number;
  /** ISO timestamp when the rate was fixed. */
  rateTimestamp: string;
  /** Provider id once chosen (e.g. "manual_ops", "ecb", …). */
  fxProvider: string;
};

export type FxRateQuote = {
  /** SAR major per 1 original major. */
  rate: number;
  rateTimestamp: Date;
  fxProvider: string;
};

/** Interface for a future FX adapter — not implemented / not wired. */
export type FxRateProvider = {
  getRate(fromCurrency: string, toCurrency?: "SAR"): Promise<FxRateQuote>;
};

const SAR_MINOR_DIGITS = 2;

/**
 * Convert local minor units → SAR halalas using a frozen major-to-major rate.
 * Both-currency 2dp path uses Math.round(originalMinor * rate).
 * For 3dp origin currencies, scale via major first.
 */
export function convertToSarMinor(params: {
  originalAmountMinor: number;
  originalCurrency: string;
  /** SAR major per 1 original major. */
  exchangeRateMajor: number;
  originalMinorDigits: number;
}): number {
  const {
    originalAmountMinor,
    exchangeRateMajor,
    originalMinorDigits,
  } = params;
  if (
    !Number.isInteger(originalAmountMinor) ||
    originalAmountMinor < 0 ||
    !Number.isFinite(exchangeRateMajor) ||
    exchangeRateMajor <= 0
  ) {
    throw new Error("INVALID_FX_INPUT");
  }
  if (params.originalCurrency.toUpperCase() === "SAR") {
    return originalAmountMinor;
  }
  const originalMajor =
    originalAmountMinor / 10 ** originalMinorDigits;
  const sarMajor = originalMajor * exchangeRateMajor;
  const sarMinor = Math.round(sarMajor * 10 ** SAR_MINOR_DIGITS);
  if (sarMinor < 1) {
    throw new Error("FX_AMOUNT_TOO_SMALL");
  }
  return sarMinor;
}

/** Build snapshot fields to persist on payment_sessions + order. */
export function buildFxMoneySnapshot(params: {
  originalAmountMinor: number;
  originalCurrency: string;
  rate: FxRateQuote;
  originalMinorDigits: number;
}): FxMoneySnapshot {
  const convertedAmountSAR = convertToSarMinor({
    originalAmountMinor: params.originalAmountMinor,
    originalCurrency: params.originalCurrency,
    exchangeRateMajor: params.rate.rate,
    originalMinorDigits: params.originalMinorDigits,
  });
  return {
    originalAmount: params.originalAmountMinor,
    originalCurrency: params.originalCurrency.toUpperCase(),
    exchangeRate: String(params.rate.rate),
    convertedAmountSAR,
    rateTimestamp: params.rate.rateTimestamp.toISOString(),
    fxProvider: params.rate.fxProvider,
  };
}

/**
 * Freeze timing (product rule):
 * - Capture rate once at first payment_session create OR first unpaid order create.
 * - Reuse frozen snapshot on HPP reuse / unpaid retry / finalize.
 * - Never re-FX on webhook or status poll.
 */
export const FX_FREEZE_POLICY = {
  freezeAt: "payment_session_or_unpaid_order_create",
  gatewayCurrency: "SAR",
  displayCurrency: "originalCurrency",
} as const;
