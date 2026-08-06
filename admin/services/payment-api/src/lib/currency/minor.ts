/** Integer minor-unit helpers — never use floating point for money. */

export type CurrencyCode = string;

const MINOR_UNITS: Record<string, number> = {
  SAR: 2,
  AED: 2,
  KWD: 3,
  BHD: 3,
  OMR: 3,
  USD: 2,
  EUR: 2,
  GBP: 2,
  RUB: 2,
  KGS: 2,
  UZS: 2,
};

export function minorDigits(currency: CurrencyCode): number {
  const code = currency.toUpperCase();
  if (!(code in MINOR_UNITS)) {
    throw new Error(`UNSUPPORTED_CURRENCY:${code}`);
  }
  return MINOR_UNITS[code];
}

export function isSupportedCurrency(currency: CurrencyCode): boolean {
  return currency.toUpperCase() in MINOR_UNITS;
}

/** Convert major units (integer) to minor. Rejects non-integers. */
export function majorToMinor(major: number, currency: CurrencyCode): number {
  if (!Number.isInteger(major) || major < 0) {
    throw new Error("INVALID_MAJOR_AMOUNT");
  }
  const factor = 10 ** minorDigits(currency);
  return major * factor;
}

export function percentOfMinor(amountMinor: number, percent: number): number {
  if (!Number.isFinite(percent) || percent <= 0) return 0;
  return Math.round((amountMinor * percent) / 100);
}
