import { timingSafeEqual } from "crypto";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { PaymentStatus } from "@/lib/payments/status";

/** Pure webhook secret check (no I/O). Timing-safe when lengths match. */
export function assertWebhookSecret(
  provided: string | null | undefined,
  expected: string | null | undefined,
): void {
  if (!expected || !provided) {
    throw new ApiError(PaymentErrorCode.WEBHOOK_INVALID, 401);
  }
  const a = Buffer.from(provided, "utf8");
  const b = Buffer.from(expected, "utf8");
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    throw new ApiError(PaymentErrorCode.WEBHOOK_INVALID, 401);
  }
}

/** Outlet must match configured sandbox/production outlet. */
export function assertOutletMatch(
  sessionOutlet: string | null | undefined,
  configuredOutlet: string,
): void {
  if (sessionOutlet && sessionOutlet !== configuredOutlet) {
    throw new ApiError(PaymentErrorCode.WEBHOOK_INVALID, 400);
  }
}

/** Gateway amount must equal session minor units. */
export function assertAmountMatch(
  sessionAmountMinor: number,
  gatewayAmountMinor: number | null | undefined,
): void {
  if (gatewayAmountMinor == null) return;
  if (Number(sessionAmountMinor) !== Number(gatewayAmountMinor)) {
    throw new ApiError(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH, 409);
  }
}

export function assertCurrencyMatch(
  sessionCurrency: string,
  gatewayCurrency: string | null | undefined,
): void {
  if (!gatewayCurrency) return;
  if (sessionCurrency.toUpperCase() !== gatewayCurrency.toUpperCase()) {
    throw new ApiError(PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH, 409);
  }
}

/** Customer may cancel only non-terminal unpaid sessions. */
export function assertCancellable(status: string): void {
  const s = status as PaymentStatus;
  if (
    s === PaymentStatus.paid ||
    s === PaymentStatus.refunded ||
    s === PaymentStatus.partially_refunded ||
    status === "paid"
  ) {
    throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 409);
  }
}

export function computeRefundable(
  amountMinor: number,
  alreadyRefundedMinor: number,
  requestedMinor?: number,
): { remaining: number; amount: number } {
  const remaining = amountMinor - alreadyRefundedMinor;
  if (remaining <= 0) {
    throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 409);
  }
  const amount = requestedMinor ?? remaining;
  if (!Number.isInteger(amount) || amount < 1 || amount > remaining) {
    throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 400);
  }
  return { remaining, amount };
}

/** Wallet / extra-hours stay on Firebase until dedicated Vercel port. */
export function assertBookingPurposeOnly(purpose: string): void {
  if (purpose !== "booking") {
    throw new ApiError(
      PaymentErrorCode.INVALID_REQUEST,
      400,
      "WALLET_EXTRA_HOURS_USE_FIREBASE_BACKEND",
    );
  }
}

export function assertBearerPresent(authorizationHeader: string | null): string {
  if (!authorizationHeader || !authorizationHeader.startsWith("Bearer ")) {
    throw new ApiError(PaymentErrorCode.AUTH_REQUIRED, 401);
  }
  const token = authorizationHeader.slice("Bearer ".length).trim();
  if (!token) throw new ApiError(PaymentErrorCode.AUTH_REQUIRED, 401);
  return token;
}
