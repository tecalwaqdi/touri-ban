import { FieldValue } from "firebase-admin/firestore";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { PaymentStatus } from "@/lib/payments/status";
import { logger } from "@/lib/logging/logger";
import {
  BookingDraft,
  buildPaidOnlineOrderData,
  paidActivationPatch,
  parseBookingDraft,
  SessionQuote,
} from "@/lib/bookings/build-order";

function isPaidTerminal(session: Record<string, unknown>): boolean {
  return (
    session.normalized_status === PaymentStatus.paid ||
    session.status === "paid" ||
    session.normalized_status === PaymentStatus.captured ||
    session.status === "captured"
  );
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
 * Create or activate dispatchable booking exactly once after verified paid session.
 * Order id = session id (same as existing CF finalizeNGeniusBooking).
 * If an unpaid `payment_pending` order already exists for this session, activate it
 * in place — never create a second booking.
 */
export async function createBookingFromPaidSession(
  sessionId: string,
  session: Record<string, unknown>,
  draftOverride?: BookingDraft,
): Promise<{ bookingId: string; created: boolean; alreadyExisted: boolean }> {
  if (session.booking_created === true && session.booking_id) {
    return {
      bookingId: String(session.booking_id),
      created: false,
      alreadyExisted: true,
    };
  }

  const draftSource = draftOverride || session.booking_draft;
  let draft: BookingDraft;
  try {
    draft =
      draftOverride ||
      (draftSource
        ? parseBookingDraft(draftSource)
        : (() => {
            throw new ApiError(
              PaymentErrorCode.BOOKING_NOT_PAYABLE,
              409,
              "Paid session is missing booking draft; client must finalize with draft",
            );
          })());
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 400);
  }

  if (!isPaidTerminal(session)) {
    throw new ApiError(PaymentErrorCode.PAYMENT_PENDING, 409);
  }

  const preferredOrderId = String(
    session.booking_id || session.unpaid_order_id || sessionId,
  );
  const orderRef = db().collection(COLLECTIONS.orders).doc(preferredOrderId);
  const sessionRef = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);

  // Pre-build paid create payload (may read user). Activation path ignores it.
  const paidCreateData = await buildPaidOnlineOrderData(
    preferredOrderId,
    session as SessionQuote,
    draft,
  );

  let created = false;
  let alreadyExisted = false;
  let bookingId = preferredOrderId;

  await db().runTransaction(async (tx) => {
    const [orderSnap, sessionSnap] = await Promise.all([
      tx.get(orderRef),
      tx.get(sessionRef),
    ]);
    const latest = (sessionSnap.data() || session) as Record<string, unknown>;

    if (latest.booking_created === true && latest.booking_id) {
      alreadyExisted = true;
      bookingId = String(latest.booking_id);
      return;
    }

    if (!isPaidTerminal(latest)) {
      throw new ApiError(PaymentErrorCode.PAYMENT_PENDING, 409);
    }

    if (orderSnap.exists) {
      const existing = orderSnap.data() || {};
      const existingPayment = String(existing.payment_status || "").toLowerCase();
      if (existingPayment === "paid" || existingPayment === "captured") {
        alreadyExisted = true;
        bookingId = orderRef.id;
        tx.set(
          sessionRef,
          {
            booking_created: true,
            booking_id: orderRef.id,
            booking_created_at: FieldValue.serverTimestamp(),
            updated_at: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

      if (isUnpaidDraftOrder(existing)) {
        tx.set(
          orderRef,
          paidActivationPatch(latest as SessionQuote, sessionId),
          { merge: true },
        );
        tx.set(
          sessionRef,
          {
            booking_created: true,
            booking_id: orderRef.id,
            booking_created_at: FieldValue.serverTimestamp(),
            booking_draft: draft,
            updated_at: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        created = true;
        bookingId = orderRef.id;
        return;
      }

      alreadyExisted = true;
      throw new ApiError(PaymentErrorCode.PAYMENT_ALREADY_EXISTS, 409);
    }

    tx.create(orderRef, paidCreateData);
    tx.set(
      sessionRef,
      {
        booking_created: true,
        booking_id: orderRef.id,
        booking_created_at: FieldValue.serverTimestamp(),
        booking_draft: draft,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    created = true;
    bookingId = orderRef.id;
  });

  logger.info("booking_from_payment", {
    sessionPrefix: sessionId.slice(0, 8),
    created,
    alreadyExisted,
    bookingIdPrefix: bookingId.slice(0, 8),
  });

  return { bookingId, created, alreadyExisted };
}
