/** Pure payment-lock decision shared with Flutter tests conceptually. */

export const PAYMENT_PENDING_CODES = new Set([
  "payment_pending",
  "pending_payment",
  "awaiting_payment",
]);

export const UNPAID_PAYMENT_STATUSES = new Set([
  "unpaid",
  "pending",
  "failed",
  "cancelled",
  "canceled",
  "expired",
  "",
]);

export const PAID_PAYMENT_STATUSES = new Set([
  "paid",
  "captured",
  "authorized",
]);

export const OPERATIONAL_ACTIVE_CODES = new Set([
  "pending_driver",
  "pending",
  "awaiting_driver",
  "driver_assigned",
  "driver_arriving",
  "driver_arrived",
  "trip_in_progress",
  "trip_started",
  "active",
]);

export const TERMINAL_BOOKING_CODES = new Set([
  "completed",
  "trip_completed",
  "cancelled",
  "canceled",
  "cancelled_by_customer",
  "cancelled_by_driver",
  "cancelled_by_admin",
  "expired",
]);

export type PaymentLockKind =
  | "none"
  | "resumeSame"
  | "resumeUnpaidCheckout"
  | "conflictOtherPayment"
  | "conflictActiveBooking"
  | "paidBlock";

export type PaymentLockDecision = {
  kind: PaymentLockKind;
  activeOrderId: string;
};

export function isUnpaidDraft(params: {
  statusCode?: string;
  paymentStatus?: string;
}): boolean {
  const code = String(params.statusCode || "")
    .trim()
    .toLowerCase();
  const pay = String(params.paymentStatus || "")
    .trim()
    .toLowerCase();
  if (PAID_PAYMENT_STATUSES.has(pay)) return false;
  if (!PAYMENT_PENDING_CODES.has(code)) return false;
  return UNPAID_PAYMENT_STATUSES.has(pay);
}

export function decidePaymentLock(params: {
  currentOrderId?: string | null;
  activeOrderId?: string | null;
  activeStatusCode?: string;
  activePaymentStatus?: string;
}): PaymentLockDecision {
  const activeId = String(params.activeOrderId || "").trim();
  if (!activeId) return { kind: "none", activeOrderId: "" };

  const code = String(params.activeStatusCode || "")
    .trim()
    .toLowerCase();
  const pay = String(params.activePaymentStatus || "")
    .trim()
    .toLowerCase();
  const current = String(params.currentOrderId || "").trim();

  if (TERMINAL_BOOKING_CODES.has(code)) {
    return { kind: "none", activeOrderId: "" };
  }

  const same = Boolean(current) && current === activeId;
  const unpaid = isUnpaidDraft({ statusCode: code, paymentStatus: pay });

  if (same) {
    if (PAID_PAYMENT_STATUSES.has(pay) && !unpaid) {
      return { kind: "paidBlock", activeOrderId: activeId };
    }
    return { kind: "resumeSame", activeOrderId: activeId };
  }

  if (unpaid) {
    if (!current) {
      return { kind: "resumeUnpaidCheckout", activeOrderId: activeId };
    }
    return { kind: "conflictOtherPayment", activeOrderId: activeId };
  }

  if (OPERATIONAL_ACTIVE_CODES.has(code) || code) {
    return { kind: "conflictActiveBooking", activeOrderId: activeId };
  }

  return { kind: "none", activeOrderId: "" };
}
