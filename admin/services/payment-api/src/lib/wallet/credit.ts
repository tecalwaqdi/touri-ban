import { FieldValue, type DocumentReference } from "firebase-admin/firestore";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import { logger } from "@/lib/logging/logger";

/**
 * Credit driver/customer wallet exactly once for a paid wallet top-up session.
 * Ledger row in `transactions` with idempotency on payment_session_id.
 */
export async function creditWalletFromPaidSession(
  sessionId: string,
  session: Record<string, unknown>,
): Promise<{ credited: boolean; alreadyCredited: boolean; walletId?: string }> {
  if (session.wallet_credited === true) {
    return {
      credited: false,
      alreadyCredited: true,
      walletId: session.wallet_id ? String(session.wallet_id) : undefined,
    };
  }

  const uid = String(session.user_id || "");
  if (!uid) {
    logger.error("wallet_credit_missing_user", {
      sessionIdPrefix: sessionId.slice(0, 8),
    });
    return { credited: false, alreadyCredited: false };
  }

  const localCredit = Number(session.local_credit_amount);
  const amountMinor = Number(session.amount_minor ?? session.amount_halalas ?? 0);
  const creditMajor = Number.isFinite(localCredit) && localCredit > 0
    ? localCredit
    : amountMinor / 100;
  if (!Number.isFinite(creditMajor) || creditMajor <= 0) {
    logger.error("wallet_credit_invalid_amount", {
      sessionIdPrefix: sessionId.slice(0, 8),
    });
    return { credited: false, alreadyCredited: false };
  }
  const currency = String(
    session.local_currency || session.currency || "SAR",
  ).toUpperCase();

  const userRef = db().collection(COLLECTIONS.users).doc(uid);
  const wallets = await db()
    .collection("wallets")
    .where("userRef", "==", userRef)
    .limit(1)
    .get();
  const walletRef: DocumentReference = wallets.empty
    ? db().collection("wallets").doc(uid)
    : wallets.docs[0].ref;

  const ledgerRef = db().collection("transactions").doc(`wallet_topup_${sessionId}`);
  const sessionRef = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);

  let alreadyCredited = false;
  let credited = false;

  await db().runTransaction(async (tx) => {
    const [freshSession, wallet, existingLedger] = await Promise.all([
      tx.get(sessionRef),
      tx.get(walletRef),
      tx.get(ledgerRef),
    ]);
    const fresh = (freshSession.data() || {}) as Record<string, unknown>;
    if (fresh.wallet_credited === true || existingLedger.exists) {
      alreadyCredited = true;
      return;
    }

    const currentBalance = wallet.exists
      ? Number(wallet.data()?.currentBalance || 0)
      : 0;
    const existingCurrency = String(wallet.data()?.currency || "").toUpperCase();
    if (existingCurrency && existingCurrency !== currency) {
      logger.error("wallet_credit_currency_mismatch", {
        sessionIdPrefix: sessionId.slice(0, 8),
      });
      return;
    }
    const nextBalance = currentBalance + creditMajor;

    tx.set(
      walletRef,
      {
        userRef,
        currentBalance: nextBalance,
        walletBalance: nextBalance,
        walletUpdatedAt: FieldValue.serverTimestamp(),
        lastUpdated: FieldValue.serverTimestamp(),
        currency,
        isActive: true,
        updatedAt: FieldValue.serverTimestamp(),
        ...(wallet.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );

    tx.set(ledgerRef, {
      driverId: uid,
      userRef,
      walletRef,
      type: "top_up",
      amount: creditMajor,
      gateway_amount_sar: session.gateway_amount_sar ?? null,
      fx_local_per_sar: session.fx_local_per_sar ?? null,
      amount_minor: amountMinor,
      currency,
      status: "completed",
      reference: String(session.provider_order_ref || sessionId),
      paymentSessionId: sessionId,
      paymentReference: String(session.provider_order_ref || ""),
      idempotencyKey: `wallet_topup_${sessionId}`,
      description_code: "wallet_top_up",
      balanceBefore: currentBalance,
      balanceAfter: nextBalance,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.set(
      sessionRef,
      {
        wallet_credited: true,
        wallet_id: walletRef.id,
        wallet_credited_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    credited = true;
  });

  logger.info("wallet_credit_result", {
    sessionIdPrefix: sessionId.slice(0, 8),
    credited,
    alreadyCredited,
    amountMinor,
  });

  return { credited, alreadyCredited, walletId: walletRef.id };
}
