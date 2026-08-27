import { FieldValue } from "firebase-admin/firestore";
import { z } from "zod";
import { verifyBearerToken } from "@/lib/auth/verify";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import {
  PaymentStatus,
  toLegacyStatus,
  transitionStatus,
} from "@/lib/payments/status";
import { assertCancellable } from "@/lib/payments/guards";

const bodySchema = z.object({
  sessionId: z.string().min(8).max(128).optional(),
  bookingId: z.string().min(8).max(128).optional(),
});

/**
 * Abandon the electronic attempt. Does NOT cancel the booking.
 * Provider order is not claimed cancelled unless we called provider cancel
 * (we do not — keep local cancelled/abandoned only).
 */
export async function handleCancelPayment(req: Request) {
  const user = await verifyBearerToken(req.headers.get("authorization"));
  let body: z.infer<typeof bodySchema>;
  try {
    body = bodySchema.parse(await req.json());
  } catch {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400);
  }

  const sessionId = await resolveSessionId(user.uid, body);
  const ref = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);
  const snap = await ref.get();
  if (!snap.exists || snap.data()?.user_id !== user.uid) {
    throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
  }
  const data = snap.data() || {};
  const current = (data.normalized_status || data.status) as PaymentStatus;
  assertCancellable(String(current));
  const next = transitionStatus(current, PaymentStatus.cancelled);
  const bookingId = String(data.booking_id || data.unpaid_order_id || "").trim();

  await db().runTransaction(async (tx) => {
    tx.set(
      ref,
      {
        status: toLegacyStatus(next),
        normalized_status: next,
        abandoned: true,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (bookingId) {
      const orderRef = db().collection(COLLECTIONS.orders).doc(bookingId);
      const orderSnap = await tx.get(orderRef);
      if (orderSnap.exists) {
        const order = orderSnap.data() || {};
        const payment = String(order.payment_status || "").toLowerCase();
        if (payment !== "paid" && payment !== "captured") {
          tx.set(
            orderRef,
            {
              payment_status: "unpaid",
              status_code: "payment_pending",
              last_payment_attempt_status: "cancelled",
              updated_at: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        }
      }
      // Keep user.active_order_id on the unpaid booking so checkout
      // resumes the SAME doc (ONE_BOOKING_PER_CHECKOUT). Session is the
      // attempt lock being released by marking cancelled.
    }
  });

  return {
    id: sessionId,
    status: next,
    bookingId: bookingId || null,
    bookingCancelled: false,
    attemptCancelled: true,
  };
}

async function resolveSessionId(
  uid: string,
  body: z.infer<typeof bodySchema>,
): Promise<string> {
  const sessionId = String(body.sessionId || "").trim();
  if (sessionId) {
    if (!/^[a-f0-9]{64}$/.test(sessionId)) {
      throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400);
    }
    return sessionId;
  }
  const bookingId = String(body.bookingId || "").trim();
  if (!bookingId) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400);
  }
  const q = await db()
    .collection(COLLECTIONS.paymentSessions)
    .where("user_id", "==", uid)
    .where("unpaid_order_id", "==", bookingId)
    .limit(1)
    .get();
  if (q.empty) {
    const q2 = await db()
      .collection(COLLECTIONS.paymentSessions)
      .where("user_id", "==", uid)
      .where("booking_id", "==", bookingId)
      .limit(1)
      .get();
    if (q2.empty) {
      throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
    }
    return q2.docs[0].id;
  }
  return q.docs[0].id;
}
