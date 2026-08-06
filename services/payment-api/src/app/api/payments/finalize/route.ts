import { z } from "zod";
import { FieldValue } from "firebase-admin/firestore";
import { verifyBearerToken } from "@/lib/auth/verify";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import {
  extractGatewayAmount,
  extractGatewayState,
  fetchNGeniusOrder,
} from "@/lib/ngenius/client";
import { createBookingFromPaidSession } from "@/lib/bookings/create-from-session";
import { parseBookingDraft } from "@/lib/bookings/build-order";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import {
  mapNGeniusState,
  PaymentStatus,
  toLegacyStatus,
  transitionStatus,
} from "@/lib/payments/status";
import { jsonError, jsonOk } from "@/lib/validation/http";

export const runtime = "nodejs";

const bodySchema = z.object({
  sessionId: z.string().regex(/^[a-f0-9]{64}$/),
  /** Optional refresh of draft if session was created without one (legacy). */
  booking: z.unknown().optional(),
});

/**
 * Client finalize path (PaymentConfirm): re-verify with N-Genius then create booking once.
 * Same builder as webhook — duplicate-safe.
 */
export async function POST(req: Request) {
  try {
    const user = await verifyBearerToken(req.headers.get("authorization"));
    const body = bodySchema.parse(await req.json());
    const ref = db().collection(COLLECTIONS.paymentSessions).doc(body.sessionId);
    const snap = await ref.get();
    if (!snap.exists || snap.data()?.user_id !== user.uid) {
      throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
    }
    let session = snap.data() || {};
    if (session.purpose !== "booking") {
      throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 400);
    }

    if (!session.provider_order_ref) {
      throw new ApiError(PaymentErrorCode.PAYMENT_PENDING, 409);
    }

    const orderData = await fetchNGeniusOrder(String(session.provider_order_ref));
    const gatewayState = extractGatewayState(orderData);
    const mapped = mapNGeniusState(gatewayState);
    const current = (session.normalized_status ||
      mapNGeniusState(String(session.gateway_state || session.status))) as PaymentStatus;
    const next = transitionStatus(current, mapped);

    const amount = extractGatewayAmount(orderData);
    if (
      amount.value != null &&
      Number(session.amount_minor ?? session.amount_halalas) !== Number(amount.value)
    ) {
      throw new ApiError(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH, 409);
    }

    await ref.set(
      {
        status: toLegacyStatus(next),
        normalized_status: next,
        gateway_state: gatewayState,
        last_verified_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    session = { ...session, status: toLegacyStatus(next), normalized_status: next };

    if (next !== PaymentStatus.paid) {
      throw new ApiError(PaymentErrorCode.PAYMENT_PENDING, 409);
    }

    const draft = body.booking
      ? parseBookingDraft(body.booking)
      : undefined;
    if (draft) {
      await ref.set({ booking_draft: draft }, { merge: true });
      session = { ...session, booking_draft: draft };
    }

    const result = await createBookingFromPaidSession(body.sessionId, session, draft);
    return jsonOk({
      id: result.bookingId,
      orderId: result.bookingId,
      status: "paid",
      alreadyExisted: result.alreadyExisted,
      created: result.created,
    });
  } catch (error) {
    return jsonError(error);
  }
}
