import { FieldValue } from "firebase-admin/firestore";
import { z } from "zod";
import { verifyBearerToken } from "@/lib/auth/verify";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { PaymentStatus, toLegacyStatus, transitionStatus } from "@/lib/payments/status";
import { jsonError, jsonOk } from "@/lib/validation/http";

export const runtime = "nodejs";

const bodySchema = z.object({
  sessionId: z.string().regex(/^[a-f0-9]{64}$/),
});

export async function POST(req: Request) {
  try {
    const user = await verifyBearerToken(req.headers.get("authorization"));
    const body = bodySchema.parse(await req.json());
    const ref = db().collection(COLLECTIONS.paymentSessions).doc(body.sessionId);
    const snap = await ref.get();
    if (!snap.exists || snap.data()?.user_id !== user.uid) {
      throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
    }
    const data = snap.data() || {};
    const current = (data.normalized_status || data.status) as PaymentStatus;
    if (
      current === PaymentStatus.paid ||
      current === PaymentStatus.refunded ||
      current === PaymentStatus.partially_refunded
    ) {
      throw new ApiError(PaymentErrorCode.PAYMENT_CANCELLED, 409);
    }
    const next = transitionStatus(current, PaymentStatus.cancelled);
    await ref.set(
      {
        status: toLegacyStatus(next),
        normalized_status: next,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return jsonOk({ id: body.sessionId, status: next });
  } catch (error) {
    return jsonError(error);
  }
}
