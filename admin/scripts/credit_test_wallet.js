#!/usr/bin/env node
/**
 * One-shot TEST wallet credit (admin_adjustment).
 *
 * Prerequisites:
 *   gcloud auth application-default login
 *   cd admin/ara_oatan_app/firebase/functions && npm ci
 *
 * Usage:
 *   node scripts/credit_test_wallet.js engosama@gmail.com 1000
 *
 * Credits wallets/{uid} and writes transactions/admin_test_{ts}.
 * Does NOT fake an N-Genius payment.
 */
const path = require("path");
const admin = require(path.join(
  __dirname,
  "../ara_oatan_app/firebase/functions/node_modules/firebase-admin",
));

const email = (process.argv[2] || "").trim().toLowerCase();
const amountSar = Number(process.argv[3] || 1000);
const projectId = "tutorial-multi-language-70gx4j";

if (!email || !email.includes("@")) {
  console.error("Usage: node credit_test_wallet.js <email> [amountSar]");
  process.exit(1);
}
if (!Number.isFinite(amountSar) || amountSar <= 0 || amountSar > 50000) {
  console.error("Invalid amount");
  process.exit(1);
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId,
    });
  }
  const authUser = await admin.auth().getUserByEmail(email);
  const uid = authUser.uid;
  const db = admin.firestore();
  const userRef = db.collection("user").doc(uid);

  const wallets = await db
    .collection("wallets")
    .where("userRef", "==", userRef)
    .limit(1)
    .get();
  const walletRef = wallets.empty
    ? db.collection("wallets").doc(uid)
    : wallets.docs[0].ref;

  const ledgerId = `admin_test_${uid.slice(0, 8)}_${Date.now()}`;
  const ledgerRef = db.collection("transactions").doc(ledgerId);

  let before = 0;
  let after = 0;
  await db.runTransaction(async (tx) => {
    const wallet = await tx.get(walletRef);
    before = wallet.exists ? Number(wallet.data()?.currentBalance || 0) : 0;
    after = before + amountSar;
    tx.set(
      walletRef,
      {
        userRef,
        currentBalance: after,
        walletBalance: after,
        currency: "SAR",
        isActive: true,
        walletUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...(wallet.exists
          ? {}
          : { createdAt: admin.firestore.FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );
    tx.set(ledgerRef, {
      driverId: uid,
      userRef,
      walletRef,
      type: "admin_adjustment",
      amount: amountSar,
      currency: "SAR",
      status: "completed",
      description_code: "test_admin_credit",
      notes: `Test credit for ${email}`,
      balanceBefore: before,
      balanceAfter: after,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  console.log(
    JSON.stringify(
      {
        ok: true,
        email,
        uid,
        amountSar,
        balanceBefore: before,
        balanceAfter: after,
        ledgerId,
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error("FAILED", e.code || "", e.message);
  process.exit(1);
});
