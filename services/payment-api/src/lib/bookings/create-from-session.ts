import { FieldValue } from "firebase-admin/firestore";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { PaymentStatus } from "@/lib/payments/status";
import { logger } from "@/lib/logging/logger";
import {
  BookingDraft,
  buildPaidOnlineOrderData,
  parseBookingDraft,
  SessionQuote,
} from "@/lib/bookings/build-order";

/**
 * Create dispatchable booking exactly once after verified paid session.
 * Order id = session id (same as existing CF finalizeNGeniusBooking).
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

  const orderRef = db().collection(COLLECTIONS.orders).doc(sessionId);
  const sessionRef = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);
  const orderData = await buildPaidOnlineOrderData(
    sessionId,
    session as SessionQuote,
    draft,
  );

  let created = false;
  let alreadyExisted = false;

  await db().runTransaction(async (tx) => {
    const [orderSnap, sessionSnap] = await Promise.all([
      tx.get(orderRef),
      tx.get(sessionRef),
    ]);
    const latest = (sessionSnap.data() || session) as Record<string, unknown>;

    if (latest.booking_created === true && latest.booking_id) {
      alreadyExisted = true;
      return;
    }
    if (orderSnap.exists) {
      alreadyExisted = true;
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

    if (
      latest.normalized_status !== PaymentStatus.paid &&
      latest.status !== "paid"
    ) {
      throw new ApiError(PaymentErrorCode.PAYMENT_PENDING, 409);
    }

    tx.create(orderRef, orderData);
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
  });

  logger.info("booking_from_payment", {
    sessionPrefix: sessionId.slice(0, 8),
    created,
    alreadyExisted,
  });

  return { bookingId: sessionId, created, alreadyExisted };
}
