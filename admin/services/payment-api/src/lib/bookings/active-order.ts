import { FieldValue, Firestore, Transaction } from "firebase-admin/firestore";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

const TERMINAL_STATUS_CODES = new Set([
  "completed",
  "trip_completed",
  "cancelled",
  "canceled",
  "cancelled_by_customer",
  "cancelled_by_driver",
  "cancelled_by_admin",
  "expired",
]);

export function isCustomerActiveStatusCode(code: unknown): boolean {
  const c = String(code || "").trim().toLowerCase();
  if (!c) return false;
  return !TERMINAL_STATUS_CODES.has(c);
}

/**
 * Claim user.active_order_id inside an open transaction (reads before writes).
 * Throws ACTIVE_BOOKING_EXISTS when another non-terminal order is locked.
 */
export async function assertAndClaimActiveOrderSlot(params: {
  tx: Transaction;
  db: Firestore;
  userId: string;
  orderId: string;
}): Promise<void> {
  const { tx, db, userId, orderId } = params;
  const userRef = db.collection("user").doc(userId);
  const userSnap = await tx.get(userRef);
  const userData = userSnap.exists ? userSnap.data() || {} : {};
  const currentId = String(userData.active_order_id || "").trim();

  if (currentId && currentId !== orderId) {
    const otherSnap = await tx.get(db.collection("order").doc(currentId));
    if (otherSnap.exists && isCustomerActiveStatusCode(otherSnap.data()?.status_code)) {
      throw new ApiError(
        PaymentErrorCode.ACTIVE_BOOKING_EXISTS,
        409,
        currentId,
      );
    }
  }

  tx.set(
    userRef,
    {
      active_order_id: orderId,
      active_order_updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

export async function releaseActiveOrderSlot(params: {
  tx: Transaction;
  db: Firestore;
  userId: string;
  orderId: string;
}): Promise<void> {
  const { tx, db, userId, orderId } = params;
  const userRef = db.collection("user").doc(userId);
  const userSnap = await tx.get(userRef);
  if (!userSnap.exists) return;
  const currentId = String(userSnap.data()?.active_order_id || "").trim();
  if (!currentId || currentId !== orderId) return;
  tx.set(
    userRef,
    {
      active_order_id: FieldValue.delete(),
      active_order_updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
