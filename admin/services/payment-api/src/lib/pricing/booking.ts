import { percentOfMinor, majorToMinor, isSupportedCurrency } from "@/lib/currency/minor";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

export type BookingPriceInput = {
  hourlyRateMajor: number;
  bookingHours: number;
  additionalHours: number;
  discountPercentOnAdditional?: number;
  discountCapMajor?: number;
  platformFeePercent?: number;
  vatPercent?: number;
  applyVat?: boolean;
  currency: string;
};

export type BookingPriceQuote = {
  currency: string;
  amountMinor: number;
  baseFareMinor: number;
  discountMinor: number;
  platformFeeMinor: number;
  vatMinor: number;
  bookingHours: number;
  additionalHours: number;
};

/**
 * Server-side booking quote — mirrors CF verifiedBookingAmount using integer minor units.
 * hourlyRateMajor is the integer vehicle hourly rate from Firestore (e.g. car.sr).
 */
export function calculateBookingQuote(input: BookingPriceInput): BookingPriceQuote {
  const currency = input.currency.toUpperCase();
  if (!isSupportedCurrency(currency)) {
    throw new ApiError(PaymentErrorCode.UNSUPPORTED_CURRENCY, 400);
  }
  if (
    !Number.isInteger(input.bookingHours) ||
    input.bookingHours < 1 ||
    input.bookingHours > 24 * 30
  ) {
    throw new ApiError(PaymentErrorCode.INVALID_HOURS, 400);
  }
  if (
    !Number.isInteger(input.additionalHours) ||
    input.additionalHours < 0 ||
    input.additionalHours > input.bookingHours
  ) {
    throw new ApiError(PaymentErrorCode.INVALID_HOURS, 400);
  }
  if (!Number.isInteger(input.hourlyRateMajor) || input.hourlyRateMajor < 1) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, "Invalid hourly rate");
  }

  const hourlyMinor = majorToMinor(input.hourlyRateMajor, currency);
  const baseFareMinor = hourlyMinor * input.bookingHours;
  const rawDiscount = percentOfMinor(
    hourlyMinor * input.additionalHours,
    input.discountPercentOnAdditional ?? 0,
  );
  const capMinor =
    input.discountCapMajor && input.discountCapMajor > 0
      ? majorToMinor(Math.round(input.discountCapMajor), currency)
      : 0;
  const discountMinor =
    capMinor > 0 ? Math.min(rawDiscount, capMinor) : rawDiscount;
  const amountMinor = baseFareMinor - discountMinor;
  if (amountMinor <= 0) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, "Zero payable amount");
  }

  const platformFeeMinor = percentOfMinor(
    baseFareMinor,
    input.platformFeePercent ?? 15,
  );
  const vatMinor =
    input.applyVat === true
      ? percentOfMinor(baseFareMinor, input.vatPercent ?? 0)
      : 0;

  return {
    currency,
    amountMinor,
    baseFareMinor,
    discountMinor,
    platformFeeMinor,
    vatMinor,
    bookingHours: input.bookingHours,
    additionalHours: input.additionalHours,
  };
}
