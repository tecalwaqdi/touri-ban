import { createHash } from "crypto";
import { FieldValue } from "firebase-admin/firestore";
import { z } from "zod";
import { requireFinanceOrAdmin, verifyBearerToken } from "@/lib/auth/verify";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { refundNGeniusOrder } from "@/lib/ngenius/client";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { mapNGeniusState, PaymentStatus, toLegacyStatus, transitionStatus } from "@/lib/payments/status";
import { computeRefundable } from "@/lib/payments/guards";
import { jsonError, jsonOk } from "@/lib/validation/http";
import { getEnv } from "@/lib/security/env";

export const runtime = "nodejs";

const bodySchema = z.object({
  sessionId: z.string().regex(/^[a-f0-9]{64}$/),
  amountMinor: z.number().int().positive().optional(),
  idempotencyKey: z.string().min(8).max(96).regex(/^[a-zA-Z0-9_.:-]+$/),
  reason: z.string().max(300).optional(),
});

export async function POST(req: Request) {
  try {
    const env = getEnv();
    if (!env.NGENIUS_API_KEY || !env.NGENIUS_OUTLET_REF) {
      throw new ApiError(
        PaymentErrorCode.REFUND_NOT_CONFIGURED,
        503,
        "REFUND_NOT_CONFIGURED",
      );
    }

    const user = await verifyBearerToken(req.headers.get("authorization"));
    await requireFinanceOrAdmin(user);
    const body = bodySchema.parse(await req.json());

    const sessionRef = db()
      .collection(COLLECTIONS.paymentSessions)
      .doc(body.sessionId);
    const snap = await sessionRef.get();
    if (!snap.exists) {
      throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
    }
    const data = snap.data() || {};
    const status = String(data.normalized_status || data.status);
    if (status !== PaymentStatus.paid && status !== "paid") {
      throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 409);
    }
    if (!data.provider_order_ref) {
      throw new ApiError(PaymentErrorCode.REFUND_NOT_ALLOWED, 409);
    }

    const max = Number(data.amount_minor ?? data.amount_halalas);
    const already = Number(data.refund_amount_halalas || 0);
    const { remaining, amount } = computeRefundable(max, already, body.amountMinor);

    const refundDocId = createHash("sha256")
      .update(`${body.sessionId}:${body.idempotencyKey}`)
      .digest("hex");
    const refundRef = db().collection("payment_refunds").doc(refundDocId);
    const existingRefund = await refundRef.get();
    if (existingRefund.exists) {
      return jsonOk({
        id: body.sessionId,
        refundId: refundDocId,
        status: existingRefund.data()?.status || "refunded",
        amountMinor: existingRefund.data()?.amount_minor,
        duplicate: true,
      });
    }

    const provider = await refundNGeniusOrder({
      providerOrderRef: String(data.provider_order_ref),
      amountMinor: amount,
      currency: String(data.currency || "SAR"),
    });
    const mapped = mapNGeniusState(provider.state);
    const next = transitionStatus(
      PaymentStatus.paid,
      amount >= remaining ? PaymentStatus.refunded : PaymentStatus.partially_refunded,
    );
    const finalStatus =
      mapped === PaymentStatus.refunded || mapped === PaymentStatus.partially_refunded
        ? mapped
        : next;

    await db().runTransaction(async (tx) => {
      const fresh = await tx.get(refundRef);
      if (fresh.exists) return;
      tx.create(refundRef, {
        session_id: body.sessionId,
        booking_id: data.booking_id || body.sessionId,
        amount_minor: amount,
        currency: data.currency || "SAR",
        reason: body.reason || "",
        actor_uid: user.uid,
        idempotency_key: body.idempotencyKey,
        provider_state: provider.state,
        status: toLegacyStatus(finalStatus),
        created_at: FieldValue.serverTimestamp(),
        backend_source: "vercel_api",
        environment: env.NGENIUS_ENV,
      });
      tx.set(
        sessionRef,
        {
          status: toLegacyStatus(finalStatus),
          normalized_status: finalStatus,
          refund_amount_halalas: already + amount,
          refund_requested_by: user.uid,
          refund_requested_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      if (data.booking_id || data.booking_created) {
        const orderId = String(data.booking_id || body.sessionId);
        tx.set(
          db().collection(COLLECTIONS.orders).doc(orderId),
          {
            payment_status:
              finalStatus === PaymentStatus.refunded ? "refunded" : "partially_refunded",
            refund_amount_halalas: already + amount,
            updated_at: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    });

    return jsonOk({
      id: body.sessionId,
      refundId: refundDocId,
      status: finalStatus,
      amountMinor: amount,
      remainingMinor: remaining - amount,
    });
  } catch (error) {
    return jsonError(error);
  }
}
