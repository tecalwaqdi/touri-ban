/**
 * Normalized payment status state machine.
 * Maps N-Genius gateway states into internal statuses.
 */

export const PaymentStatus = {
  created: "created",
  pending: "pending",
  authentication_required: "authentication_required",
  authorized: "authorized",
  captured: "captured",
  paid: "paid",
  failed: "failed",
  cancelled: "cancelled",
  expired: "expired",
  refunded: "refunded",
  partially_refunded: "partially_refunded",
} as const;

export type PaymentStatus = (typeof PaymentStatus)[keyof typeof PaymentStatus];

/** Allowed forward transitions (from → set of to). */
const ALLOWED: Record<PaymentStatus, ReadonlySet<PaymentStatus>> = {
  created: new Set([
    PaymentStatus.pending,
    PaymentStatus.authentication_required,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.expired,
    PaymentStatus.paid,
    PaymentStatus.authorized,
    PaymentStatus.captured,
  ]),
  pending: new Set([
    PaymentStatus.authentication_required,
    PaymentStatus.authorized,
    PaymentStatus.captured,
    PaymentStatus.paid,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.expired,
  ]),
  authentication_required: new Set([
    PaymentStatus.authorized,
    PaymentStatus.captured,
    PaymentStatus.paid,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.expired,
    PaymentStatus.pending,
  ]),
  authorized: new Set([
    PaymentStatus.captured,
    PaymentStatus.paid,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.refunded,
    PaymentStatus.partially_refunded,
  ]),
  captured: new Set([
    PaymentStatus.paid,
    PaymentStatus.refunded,
    PaymentStatus.partially_refunded,
  ]),
  paid: new Set([
    PaymentStatus.refunded,
    PaymentStatus.partially_refunded,
  ]),
  failed: new Set([PaymentStatus.failed]),
  cancelled: new Set([PaymentStatus.cancelled]),
  expired: new Set([PaymentStatus.expired]),
  refunded: new Set([PaymentStatus.refunded]),
  partially_refunded: new Set([
    PaymentStatus.partially_refunded,
    PaymentStatus.refunded,
  ]),
};

export function mapNGeniusState(raw: string | null | undefined): PaymentStatus {
  const value = String(raw || "").toUpperCase();
  if (["PURCHASED", "CAPTURED"].includes(value)) return PaymentStatus.paid;
  if (value === "PARTIALLY_REFUNDED") return PaymentStatus.partially_refunded;
  if (value === "REFUNDED") return PaymentStatus.refunded;
  if (["CANCELLED", "CANCELED"].includes(value)) return PaymentStatus.cancelled;
  if (value === "EXPIRED") return PaymentStatus.expired;
  if (["FAILED", "DECLINED", "PURCHASE_REVERSED"].includes(value)) {
    return PaymentStatus.failed;
  }
  if (["AWAIT_3DS", "THREE_DS_AUTHENTICATED", "START_PAYMENT"].includes(value)) {
    return PaymentStatus.authentication_required;
  }
  if (value === "AUTHORIZED" || value === "AUTHORISED") {
    return PaymentStatus.authorized;
  }
  if (!value || value === "STARTED" || value === "PENDING") {
    return PaymentStatus.pending;
  }
  return PaymentStatus.pending;
}

/**
 * Apply transition. Returns next status (may stay same).
 * Rejects illegal backward transitions such as paid → pending.
 */
export function transitionStatus(
  current: PaymentStatus,
  next: PaymentStatus,
): PaymentStatus {
  if (current === next) return current;
  const allowed = ALLOWED[current];
  if (!allowed || !allowed.has(next)) {
    return current;
  }
  return next;
}

/** Legacy CF alias used in existing Firestore docs. */
export function toLegacyStatus(status: PaymentStatus): string {
  if (status === PaymentStatus.paid || status === PaymentStatus.captured) {
    return "paid";
  }
  return status;
}
