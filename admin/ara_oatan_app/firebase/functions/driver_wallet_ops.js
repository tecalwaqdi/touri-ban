/**
 * Driver wallet + accept ops (Admin SDK only).
 * - acceptDriverOrder: cash wallet gate + atomic claim
 * - payCompanyFromWallet: debit wallet → company payment ledger
 */
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

const MIN_CASH_WALLET = 200;

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
}

function isCashPayment(data) {
  const m = String(
    data.PaymentMethod || data.paymentMethod || data.payment_method || "",
  ).toLowerCase();
  return m === "cash" || m === "نقدي" || m === "نقدا" || m === "نقد";
}

function isAssignable(statusCode, halhText, halhOrder) {
  const c = String(statusCode || "").toLowerCase().trim();
  if (c === "pending_driver" || c === "awaiting_driver" || c === "pending") {
    return true;
  }
  if (!c) {
    const h = String(halhText || "").trim();
    const o = String(halhOrder || "").trim().toLowerCase();
    return (
      h === "بإنتظار قبول المندوب" ||
      h === "بانتظار قبول المندوب" ||
      o === "pending"
    );
  }
  return false;
}

function logStage(stage, t0, extra = {}) {
  const ms = Date.now() - t0;
  console.log(
    JSON.stringify({
      tag: "acceptDriverOrder",
      stage,
      ms,
      ...extra,
    }),
  );
}

function mapCaughtError(e) {
  if (e instanceof functions.https.HttpsError) return e;
  const code = e && (e.code || e.status);
  const msg = String((e && e.message) || e || "");
  if (
    code === 7 ||
    code === "PERMISSION_DENIED" ||
    msg.includes("PERMISSION_DENIED") ||
    msg.includes("Missing or insufficient permissions")
  ) {
    return new functions.https.HttpsError(
      "unavailable",
      "BOOKING_SERVICE_UNAVAILABLE",
    );
  }
  console.error("acceptDriverOrder_unhandled", code, msg.slice(0, 300));
  return new functions.https.HttpsError(
    "internal",
    "BOOKING_ASSIGNMENT_FAILED",
  );
}

async function resolveWalletRef(firestore, userRef) {
  const q = await firestore
    .collection("wallets")
    .where("userRef", "==", userRef)
    .limit(1)
    .get();
  if (!q.empty) return q.docs[0].ref;
  return firestore.collection("wallets").doc(userRef.id);
}

exports.acceptDriverOrder = functions
  .region("us-central1")
  .runWith({ timeoutSeconds: 30, memory: "256MB" })
  .https.onCall(async (data, context) => {
    const t0 = Date.now();
    logStage("accept_start", t0);
    requireAuth(context);
    const uid = context.auth.uid;
    const orderId = String(data.orderId || "").trim();
    const orderPath = String(data.orderPath || "").trim();
    if (!orderId && !orderPath) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "orderId required",
      );
    }

    const firestore = admin.firestore();
    const orderRef = orderPath
      ? firestore.doc(orderPath)
      : firestore.collection("order").doc(orderId);
    const userRef = firestore.collection("user").doc(uid);

    // Defense-in-depth: Auth emailVerified + Firestore actev (checked in tx).
    try {
      const authUser = await admin.auth().getUser(uid);
      if (authUser.emailVerified !== true) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "email-not-verified",
        );
      }
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      throw new functions.https.HttpsError(
        "failed-precondition",
        "driver-disabled",
      );
    }

    let walletRef;
    try {
      walletRef = await resolveWalletRef(firestore, userRef);
      logStage("wallet_loaded", t0, { walletId: walletRef.id });
    } catch (e) {
      throw mapCaughtError(e);
    }

    try {
      await firestore.runTransaction(async (tx) => {
        logStage("transaction_started", t0);
        const [orderSnap, walletSnap, driverSnap] = await Promise.all([
          tx.get(orderRef),
          tx.get(walletRef),
          tx.get(userRef),
        ]);
        logStage("booking_loaded", t0, { orderExists: orderSnap.exists });
        logStage("driver_loaded", t0, { driverExists: driverSnap.exists });

        if (!driverSnap.exists) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "driver-disabled",
          );
        }
        const driver = driverSnap.data() || {};
        const {driverIsOperationallyApproved} = require('./driver_registration_notifications.js');
        if (!driverIsOperationallyApproved(driver)) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'driver-disabled',
          );
        }

        // Block new trip accept when a critical document is expired.
        try {
          const docReview = require('./driver_document_review.js');
          let countryReqs = null;
          const countryRef = driver.Rev_dolh || driver.rev_dolh;
          if (countryRef) {
            const cSnap = await tx.get(countryRef);
            if (cSnap.exists) {
              countryReqs = (cSnap.data() || {}).driver_requirements || null;
            }
          }
          const blocking = docReview.firstBlockingExpiredDocument(
            driver,
            countryReqs,
            new Date(),
          );
          if (blocking) {
            throw new functions.https.HttpsError(
              'failed-precondition',
              'document-expired',
            );
          }
        } catch (e) {
          if (e instanceof functions.https.HttpsError) throw e;
        }

        if (!orderSnap.exists) {
          throw new functions.https.HttpsError("not-found", "BOOKING_NOT_FOUND");
        }
        const order = orderSnap.data() || {};
        const existing = order.mndob_user;
        if (existing) {
          const path =
            typeof existing.path === "string"
              ? existing.path
              : String(existing);
          if (path !== userRef.path) {
            throw new functions.https.HttpsError(
              "already-exists",
              "BOOKING_ALREADY_ASSIGNED",
            );
          }
          // Idempotent re-accept by same driver.
          return;
        }
        if (
          !isAssignable(
            order.status_code,
            order.halh_text || order.halhText,
            order.halh_order,
          )
        ) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "BOOKING_INVALID_STATE",
          );
        }

        let deadlineAt = null;
        if (order.acceptanceDeadline && order.acceptanceDeadline.toDate) {
          deadlineAt = order.acceptanceDeadline.toDate();
        } else if (typeof order.acceptance_deadline_ms === "number") {
          deadlineAt = new Date(order.acceptance_deadline_ms);
        } else {
          const created = order.data_order || order.createdAt || order.created_at;
          if (created && created.toDate) {
            deadlineAt = new Date(created.toDate().getTime() + 60 * 60 * 1000);
          } else if (created) {
            const ms = new Date(created).getTime();
            if (!Number.isNaN(ms)) {
              deadlineAt = new Date(ms + 60 * 60 * 1000);
            }
          }
        }
        if (deadlineAt && Date.now() > deadlineAt.getTime()) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "BOOKING_EXPIRED",
          );
        }

        if (isCashPayment(order)) {
          const bal = walletSnap.exists
            ? Number(walletSnap.data().currentBalance || 0)
            : 0;
          if (bal < MIN_CASH_WALLET) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "insufficient-wallet",
            );
          }
        }

        const lat = Number(data.lat);
        const lng = Number(data.lng);
        const claim = {
          mndob_user: userRef,
          status_code: "driver_assigned",
          ActiveOrder: true,
          ALLNOW: false,
          halh_text: "مقبول",
          halhOrderMndob: "Accepted",
          acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
          START: admin.firestore.FieldValue.serverTimestamp(),
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          naim_mndob_text: String(data.displayName || "").slice(0, 160),
          phone_nu_mndob: Number(data.phone || 0),
          carmndob: String(data.carLabel || "").slice(0, 160),
          NameCar: String(data.NameCar || "").slice(0, 120),
          ModelCar: String(data.ModelCar || "").slice(0, 120),
        };
        if (Number.isFinite(lat) && Number.isFinite(lng) && (lat || lng)) {
          claim.mapuser = new admin.firestore.GeoPoint(lat, lng);
          claim.driver_accept_location = new admin.firestore.GeoPoint(lat, lng);
        }
        tx.update(orderRef, claim);
      });
      logStage("transaction_committed", t0);
      logStage("accept_completed", t0);
      // Notifications are client-side / best-effort — never block accept.
      return { ok: true };
    } catch (e) {
      const mapped = mapCaughtError(e);
      logStage("accept_failed", t0, {
        code: mapped.code,
        message: mapped.message,
      });
      // Return structured payload (not only throw) so Flutter maps Arabic codes.
      if (mapped instanceof functions.https.HttpsError) {
        const msg = mapped.message || "";
        const errorCode =
          msg === "insufficient-wallet"
            ? "DRIVER_WALLET_INSUFFICIENT"
            : msg === "BOOKING_ALREADY_ASSIGNED"
              ? "BOOKING_ALREADY_ASSIGNED"
              : msg === "BOOKING_EXPIRED"
                ? "BOOKING_EXPIRED"
                : msg === "driver-disabled"
                  ? "DRIVER_DISABLED"
                  : msg === "BOOKING_INVALID_STATE"
                    ? "BOOKING_INVALID_STATE"
                    : msg === "BOOKING_NOT_FOUND"
                      ? "BOOKING_NOT_FOUND"
                      : msg === "BOOKING_SERVICE_UNAVAILABLE"
                        ? "BOOKING_SERVICE_UNAVAILABLE"
                        : msg;
        return {
          ok: false,
          error: msg,
          errorCode,
          code: mapped.code,
        };
      }
      throw mapped;
    }
  });

exports.payCompanyFromWallet = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    requireAuth(context);
    const uid = context.auth.uid;
    const amount = Number(data.amount);
    const confirmBelowMin = data.confirmBelowMin === true;
    const reference = String(data.reference || "").trim().slice(0, 120);
    const idempotencyKey = String(
      data.idempotencyKey || `company_pay_${uid}_${Date.now()}`,
    ).slice(0, 128);

    if (!Number.isFinite(amount) || amount <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid amount",
      );
    }

    const firestore = admin.firestore();
    const userRef = firestore.collection("user").doc(uid);
    const walletRef = await resolveWalletRef(firestore, userRef);
    const ledgerRef = firestore
      .collection("transactions")
      .doc(`company_pay_${idempotencyKey}`);
    const companyPayRef = firestore
      .collection("company_payments")
      .doc(idempotencyKey);

    const result = await firestore.runTransaction(async (tx) => {
      const [existing, walletSnap, userSnap] = await Promise.all([
        tx.get(ledgerRef),
        tx.get(walletRef),
        tx.get(userRef),
      ]);
      if (existing.exists) {
        return { ok: true, alreadyProcessed: true, ...(existing.data() || {}) };
      }

      const balanceBefore = walletSnap.exists
        ? Number(walletSnap.data().currentBalance || 0)
        : 0;
      if (amount > balanceBefore) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "INSUFFICIENT_BALANCE",
        );
      }
      const balanceAfter = balanceBefore - amount;
      if (balanceAfter < MIN_CASH_WALLET && !confirmBelowMin) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "BELOW_MIN_REQUIRES_CONFIRM",
        );
      }

      const ledger = {
        userRef,
        walletRef,
        driverId: uid,
        type: "company_payment",
        amount: -Math.abs(amount),
        amountAbs: amount,
        balanceBefore,
        balanceAfter,
        currency: "SAR",
        status: "completed",
        reference: reference || idempotencyKey,
        idempotencyKey,
        description: "company_payment",
        description_code: "company_payment",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      tx.set(
        walletRef,
        {
          userRef,
          currentBalance: balanceAfter,
          walletBalance: balanceAfter,
          currency: (walletSnap.data() || {}).currency || "SAR",
          isActive: true,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      tx.set(ledgerRef, ledger);
      tx.set(companyPayRef, {
        ...ledger,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (userSnap.exists) {
        const totalApp = Number(userSnap.data().total_app || 0);
        if (totalApp > 0) {
          tx.update(userRef, { total_app: Math.max(0, totalApp - amount) });
        }
      }

      return {
        ok: true,
        alreadyProcessed: false,
        balanceBefore,
        balanceAfter,
        amount,
      };
    });

    return result;
  });
