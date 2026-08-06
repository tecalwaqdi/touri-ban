import { z } from "zod";
import { requireFinanceOrAdmin, verifyBearerToken } from "@/lib/auth/verify";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { jsonError, jsonOk } from "@/lib/validation/http";
import { PaymentStatus } from "@/lib/payments/status";

export const runtime = "nodejs";

/**
 * Admin refund endpoint scaffold.
 * Full N-Genius refund link execution will use the same gateway flow as CF
 * refundNGeniusPayment; this validates auth + refundability first.
 */
const bodySchema = z.object({
  sessionId: z.string().regex(/^[a-f0-9]{64}$/),
  amountMinor: z.number().int().positive().optional(),
  idempotencyKey: z.string().min(8).max(96),
});

export async function POST(req: Request) {
  try {
    const user = await verifyBearerToken(req.headers.get("authorization"));
    await requireFinanceOrAdmin(user);
    const body = bodySchema.parse(await req.json());
    const snap = await db()
      .collection(COLLECTIONS.paymentSessions)
      .doc(body.sessionId)
      .get();
    if (!snap.exists) {
      throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
    }
    const data = snap.data() || {};
    const status = data.normalized_status || data.status;
    if (status !== PaymentStatus.paid && status !== "paid") {
      throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 409);
    }
    const max = Number(data.amount_minor ?? data.amount_halalas);
    const amount = body.amountMinor ?? max;
    if (amount < 1 || amount > max) {
      throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 400);
    }

    // Intentionally does not call N-Genius until sandbox credentials are configured.
    // Returns a clear code so Flutter/admin can show localized guidance.
    return jsonOk({
      id: body.sessionId,
      status: "refund_pending_configuration",
      amountMinor: amount,
      messageKey: "REFUND_PROVIDER_NOT_CONFIGURED_IN_SANDBOX_YET",
      actor: user.uid,
    });
  } catch (error) {
    return jsonError(error);
  }
}
