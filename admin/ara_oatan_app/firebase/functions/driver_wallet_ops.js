/**
 * Driver wallet + accept ops (Admin SDK only).
 * - acceptDriverOrder: cash wallet gate + atomic claim
 * - payCompanyFromWallet: debit wallet → company payment ledger
 */
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

const countryFinance = require("./vendor/country_finance.js");
const companyDue = require("./vendor/company_due.js");
const accounting = require("./vendor/financial_accounting_v2");
const MIN_CASH_WALLET = countryFinance.MIN_CASH_WALLET_SAR;

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

const ACTIVE_DRIVER_TRIP_CODES = new Set([
  "driver_assigned",
  "driver_arriving",
  "driver_arrived",
  "trip_started",
  "trip_in_progress",
]);

const TERMINAL_BOOKING_CODES = new Set([
  "completed",
  "trip_completed",
  "cancelled",
  "canceled",
  "cancelled_by_customer",
  "cancelled_by_driver",
  "cancelled_by_admin",
  "expired",
]);

const ACTIVE_DRIVER_HALH = new Set([
  "مقبول",
  "وصل المندوب",
  "تم البدء في الرحلة",
]);

function refPath(ref) {
  if (!ref) return "";
  if (typeof ref.path === "string") return ref.path;
  return String(ref);
}

/** Busy flags written by accept (camel + snake) or client schema. */
function driverBusyFlagsSet(driver) {
  const d = driver || {};
  return (
    d.mndonNewacc === true ||
    d.mndon_newacc === true ||
    d.mndob_busy === true ||
    (typeof d.active_order_id === "string" && d.active_order_id.trim().length > 0)
  );
}

/**
 * True only when the held order is still an in-progress trip for this driver.
 * Missing / terminal / unassigned / other-driver orders are treated as stale.
 */
function isTrulyActiveDriverTrip(orderData, driverPath) {
  if (!orderData || !driverPath) return false;
  const code = String(orderData.status_code || "").toLowerCase().trim();
  if (TERMINAL_BOOKING_CODES.has(code)) return false;
  const assigned = refPath(orderData.mndob_user);
  if (!assigned || assigned !== driverPath) return false;
  if (ACTIVE_DRIVER_TRIP_CODES.has(code)) return true;
  if (!code) {
    if (orderData.ActiveOrder === true || orderData.activeOrder === true) {
      return true;
    }
    const h = String(orderData.halh_text || orderData.halhText || "").trim();
    return ACTIVE_DRIVER_HALH.has(h);
  }
  return false;
}

function setDriverBusyPatch(orderId) {
  return {
    // Canonical Flutter schema field:
    mndon_newacc: true,
    // Legacy camelCase written by older accept paths — keep in sync:
    mndonNewacc: true,
    mndob_busy: true,
    active_order_id: orderId,
  };
}

function clearDriverBusyPatch() {
  return {
    mndon_newacc: false,
    mndonNewacc: false,
    mndob_busy: false,
    active_order_id: admin.firestore.FieldValue.delete(),
  };
}

exports._test = {
  driverBusyFlagsSet,
  isTrulyActiveDriverTrip,
  setDriverBusyPatch,
};

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
        // One active trip per driver — heal stale busy flags left by cancel /
        // field-name mismatch (mndonNewacc vs mndon_newacc).
        const heldId = String(driver.active_order_id || "").trim();
        let heldSnap = null;
        if (
          driverBusyFlagsSet(driver) &&
          heldId &&
          heldId !== orderRef.id
        ) {
          heldSnap = await tx.get(firestore.collection("order").doc(heldId));
        }
        if (driverBusyFlagsSet(driver)) {
          const heldActive =
            heldId &&
            heldId !== orderRef.id &&
            isTrulyActiveDriverTrip(
              heldSnap && heldSnap.exists ? heldSnap.data() : null,
              userRef.path,
            );
          if (heldActive) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "DRIVER_BUSY",
            );
          }
          logStage("stale_busy_healed", t0, {
            heldId: heldId || null,
            mndonNewacc: driver.mndonNewacc === true,
            mndon_newacc: driver.mndon_newacc === true,
            mndob_busy: driver.mndob_busy === true,
          });
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
          // Idempotent re-accept by same driver — keep busy flags consistent.
          tx.update(userRef, setDriverBusyPatch(orderRef.id));
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

        // Nearest-first offer waves: only current/prior wave UIDs may claim.
        const { isUidInCurrentOfferWave } = require("./order_offer_waves.js");
        if (!isUidInCurrentOfferWave(order, uid)) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "BOOKING_NOT_IN_OFFER_WAVE",
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
          const walletCurrency = String(
            (walletSnap.data() || {}).currency ||
              order.currency ||
              order.currency_code ||
              "",
          ).toUpperCase();
          if (!walletCurrency) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "FX_CONFIG_MISSING",
            );
          }
          const fx = Number(order.fx_local_per_sar);
          let minimum = MIN_CASH_WALLET;
          if (walletCurrency !== "SAR") {
            if (!Number.isFinite(fx) || fx <= 0) {
              throw new functions.https.HttpsError(
                "failed-precondition",
                "FX_CONFIG_MISSING",
              );
            }
            minimum = countryFinance.minCashLocal(fx);
          }
          if (bal < minimum) {
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
        tx.update(userRef, setDriverBusyPatch(orderRef.id));
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
                        : msg === "DRIVER_BUSY"
                          ? "DRIVER_BUSY"
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
      const [existing, walletSnap, userSnap, ordersSnap, settlementSnap, paymentSnap] =
        await Promise.all([
          tx.get(ledgerRef),
          tx.get(walletRef),
          tx.get(userRef),
          tx.get(
            firestore.collection("order").where("mndob_user", "==", userRef).limit(300),
          ),
          tx.get(
            firestore
              .collection("financial_settlement_payments")
              .where("driverId", "==", uid)
              .limit(200),
          ),
          tx.get(
            firestore.collection("transactions").where("driverId", "==", uid).limit(400),
          ),
        ]);
      if (existing.exists) {
        return { ok: true, alreadyProcessed: true, ...(existing.data() || {}) };
      }

      const balanceBefore = walletSnap.exists
        ? Number(walletSnap.data().currentBalance || 0)
        : 0;
      const walletCurrency = String((walletSnap.data() || {}).currency || "").toUpperCase();
      let cashDueMinor = 0;
      let foreignDue = false;
      ordersSnap.forEach((doc) => {
        const line = accounting.analyzeOrder(doc.id, doc.data() || {});
        if (line.lifecycle !== "completed") return;
        const collected =
          line.payment === "paid" ||
          line.payment === "cashCollected" ||
          line.payment === "captured";
        if (!collected || line.channel !== "cash") return;
        const signed = Number(line.signedCashMinor || 0);
        if (signed <= 0) return;
        if (String(line.currency || "").toUpperCase() !== walletCurrency) {
          foreignDue = true;
          return;
        }
        cashDueMinor += signed;
      });
      let settlementPaidMinor = 0;
      settlementSnap.forEach((doc) => {
        const p = doc.data() || {};
        if (String(p.currency || "").toUpperCase() !== walletCurrency) return;
        if (p.status !== "confirmed") return;
        if (p.direction === "COMPANY_TO_DRIVER") return;
        settlementPaidMinor += Number(p.amountMinor || 0);
      });
      let walletPaidMinor = 0;
      paymentSnap.forEach((doc) => {
        const p = doc.data() || {};
        if (p.type !== "company_due_payment") return;
        if (String(p.currency || "").toUpperCase() !== walletCurrency) return;
        walletPaidMinor += Math.round(Math.abs(Number(p.amountAbs || p.amount || 0)) * 100);
      });
      const serverDue = companyDue.outstandingCompanyDue({
        cashDueMinor,
        settlementPaidMinor,
        walletPaidMinor,
        currency: walletCurrency,
      });
      if (foreignDue && serverDue.major <= 0) {
        throw new functions.https.HttpsError("failed-precondition", "CURRENCY_MISMATCH");
      }
      const decision = companyDue.decideCompanyDuePayment({
        requested: amount,
        walletBalance: balanceBefore,
        walletCurrency,
        serverDue: serverDue.major,
        serverCurrency: walletCurrency,
      });
      if (!decision.ok) {
        throw new functions.https.HttpsError("failed-precondition", decision.code);
      }
      const due = decision.dueBefore;
      const balanceAfter = balanceBefore - amount;
      let floor = MIN_CASH_WALLET;
      if (walletCurrency !== "SAR") {
        const rawCountry = userSnap.exists ? userSnap.data().Rev_dolh : null;
        const countryRef = rawCountry && typeof rawCountry.path === "string"
          ? rawCountry
          : (typeof rawCountry === "string" && rawCountry.startsWith("countries/")
            ? firestore.doc(rawCountry)
            : null);
        const countrySnap = countryRef ? await tx.get(countryRef) : null;
        const fx = countrySnap && countrySnap.exists
          ? countryFinance.resolvedFx(countryFinance.readCountry(countrySnap.data() || {}))
          : null;
        if (fx == null) {
          throw new functions.https.HttpsError("failed-precondition", "FX_CONFIG_MISSING");
        }
        floor = countryFinance.minCashLocal(fx);
      }
      if (balanceAfter < floor && !confirmBelowMin) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "BELOW_MIN_REQUIRES_CONFIRM",
        );
      }

      const ledger = {
        userRef,
        walletRef,
        driverId: uid,
        type: "company_due_payment",
        amount: -Math.abs(amount),
        amountAbs: amount,
        balanceBefore,
        balanceAfter,
        currency: (walletSnap.data() || {}).currency || "SAR",
        status: "completed",
        wallet_before: balanceBefore,
        wallet_after: balanceAfter,
        due_before: Number.isFinite(due) ? due : null,
        due_after: Number.isFinite(due) ? due - amount : null,
        country: data.countryId || data.country || null,
        driver: uid,
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
