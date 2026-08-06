import { FieldValue } from "firebase-admin/firestore";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { PaymentStatus } from "@/lib/payments/status";
import { logger } from "@/lib/logging/logger";

/**
 * Create dispatchable booking exactly once after verified paid session.
 * Uses session id as order document id (same as existing CF finalize).
 */
export async function createBookingFromPaidSession(
  sessionId: string,
  session: Record<string, unknown>,
): Promise<{ bookingId: string; created: boolean }> {
  if (session.booking_created === true && session.booking_id) {
    return { bookingId: String(session.booking_id), created: false };
  }

  const orderRef = db().collection(COLLECTIONS.orders).doc(sessionId);
  const sessionRef = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);

  let created = false;
  await db().runTransaction(async (tx) => {
    const [orderSnap, sessionSnap] = await Promise.all([
      tx.get(orderRef),
      tx.get(sessionRef),
    ]);
    const latest = sessionSnap.data() || session;
    if (latest.booking_created === true) {
      return;
    }
    if (
      latest.normalized_status !== PaymentStatus.paid &&
      latest.status !== "paid"
    ) {
      throw new ApiError(PaymentErrorCode.PAYMENT_PENDING, 409);
    }

    if (!orderSnap.exists) {
      const uid = String(latest.user_id);
      tx.set(orderRef, {
        USER: db().collection(COLLECTIONS.users).doc(uid),
        PaymentMethod: "OnlinePayment",
        payment_status: "paid",
        payment_session_id: sessionId,
        ngeniusOrderId: latest.provider_order_ref || null,
        status_code: "pending_driver",
        ALLNOW: true,
        total: Number(latest.amount_minor ?? latest.amount_halalas) / 100,
        currency: latest.currency || "SAR",
        backend_source: "vercel_api",
        pricing_authority: "server",
        carPath: latest.carPath || null,
        countryPath: latest.countryPath || null,
        bookingHours: latest.bookingHours || null,
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        // Draft trip details may be merged later by client finalize compatibility path
        booking_shell: true,
      });
      created = true;
    }

    tx.set(
      sessionRef,
      {
        booking_created: true,
        booking_id: sessionId,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  logger.info("booking_from_payment", {
    sessionPrefix: sessionId.slice(0, 8),
    created,
  });
  return { bookingId: sessionId, created };
}
