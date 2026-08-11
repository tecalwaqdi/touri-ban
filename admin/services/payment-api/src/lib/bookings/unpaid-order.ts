import { FieldValue } from "firebase-admin/firestore";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import {
  BookingDraft,
  buildUnpaidOnlineOrderData,
  SessionQuote,
} from "@/lib/bookings/build-order";
import { logger } from "@/lib/logging/logger";

function isAlreadyPaidOrder(data: Record<string, unknown>): boolean {
  const payment = String(data.payment_status || "").toLowerCase();
  return payment === "paid" || payment === "captured" || payment === "authorized";
}

function isUnpaidDraftOrder(data: Record<string, unknown>): boolean {
  const status = String(data.status_code || "");
  const payment = String(data.payment_status || "").toLowerCase();
  return (
    status === "payment_pending" &&
    (payment === "unpaid" || payment === "pending" || payment === "failed")
  );
}

/**
 * Persist an unpaid online booking (payment_pending / unpaid / ALLNOW=false)
 * so the customer can retry without rebuilding the trip. Never dispatchable.
 */
export async function ensureUnpaidBookingOrder(params: {
  orderId: string;
  sessionId: string;
  userId: string;
  sessionQuote: SessionQuote;
  draft: BookingDraft;
}): Promise<{ orderId: string; created: boolean }> {
  const { orderId, sessionId, userId, sessionQuote, draft } = params;
  const orderRef = db().collection(COLLECTIONS.orders).doc(orderId);
  const sessionRef = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);
  const unpaidData = {
    ...(await buildUnpaidOnlineOrderData(
      orderId,
      { ...sessionQuote, user_id: userId },
      draft,
    )),
    booking_draft: draft,
  };

  let created = false;
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    if (snap.exists) {
      const existing = snap.data() || {};
      const owner = existing.USER;
      const ownerId =
        owner && typeof owner === "object" && "id" in owner
          ? String((owner as { id: string }).id)
          : String(owner || "").split("/").pop();
      if (ownerId && ownerId !== userId) {
        throw new ApiError(PaymentErrorCode.BOOKING_NOT_OWNED, 403);
      }
      if (isAlreadyPaidOrder(existing)) {
        throw new ApiError(PaymentErrorCode.PAYMENT_ALREADY_EXISTS, 409);
      }
      // Keep existing unpaid draft; refresh session link + latest ngenius ref.
      tx.set(
        orderRef,
        {
          payment_session_id: sessionId,
          ngeniusOrderId: sessionQuote.provider_order_ref || null,
          booking_draft: draft,
          payment_status: "unpaid",
          status_code: "payment_pending",
          ALLNOW: false,
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else {
      tx.create(orderRef, unpaidData);
      created = true;
    }
    tx.set(
      sessionRef,
      {
        unpaid_order_id: orderId,
        booking_id: orderId,
        // Still false until paid activation — prevents double-create semantics.
        booking_created: false,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  logger.info("unpaid_booking_ensured", {
    orderIdPrefix: orderId.slice(0, 8),
    sessionPrefix: sessionId.slice(0, 8),
    created,
  });

  return { orderId, created };
}

/**
 * Load an existing unpaid order for retry payment. Uses server-stored pricing.
 */
export async function loadPayableUnpaidOrder(params: {
  orderPath: string;
  userId: string;
}): Promise<{
  orderId: string;
  order: Record<string, unknown>;
  carPath: string;
  countryPath: string;
  bookingHours: number;
  additionalHours: number;
  amountMinor: number;
  currency: string;
  draft: unknown;
}> {
  const parts = params.orderPath.trim().replace(/^\//, "").split("/");
  if (parts.length !== 2 || parts[0] !== "order" || !parts[1]) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, "Invalid orderPath");
  }
  const orderId = parts[1];
  const snap = await db().collection(COLLECTIONS.orders).doc(orderId).get();
  if (!snap.exists) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_FOUND, 404);
  }
  const order = snap.data() || {};
  const owner = order.USER;
  const ownerId =
    owner && typeof owner === "object" && "id" in owner
      ? String((owner as { id: string }).id)
      : String(owner || "").split("/").pop();
  if (ownerId !== params.userId) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_OWNED, 403);
  }
  if (isAlreadyPaidOrder(order)) {
    throw new ApiError(PaymentErrorCode.PAYMENT_ALREADY_EXISTS, 409);
  }
  if (!isUnpaidDraftOrder(order)) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 409);
  }

  const carRef = order.carRev;
  const countryRef = order.Rev_dolh;
  const carPath =
    carRef && typeof carRef === "object" && "path" in carRef
      ? String((carRef as { path: string }).path)
      : "";
  const countryPath =
    countryRef && typeof countryRef === "object" && "path" in countryRef
      ? String((countryRef as { path: string }).path)
      : "";
  if (!carPath || !countryPath) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 409);
  }

  const amountMinor = Number(order.amount_halalas ?? order.pricing_quote_halalas);
  if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
    throw new ApiError(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH, 409);
  }

  return {
    orderId,
    order,
    carPath,
    countryPath,
    bookingHours: Math.max(1, Number(order.total_taim) || 1),
    additionalHours: Math.max(0, Number(order.additional_hours) || 0),
    amountMinor,
    currency: String(order.currency || "SAR"),
    draft: order.booking_draft || null,
  };
}
