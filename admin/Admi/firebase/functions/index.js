const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// ── Custom claims sync ──────────────────────────────────────────────────────

function deriveClaimsFromUserData(data) {
  const claims = {};
  const rule = data.isAdminRule ?? data.IsAdminRule ?? 0;
  const ruleNum = typeof rule === "string" ? parseInt(rule, 10) : rule;

  if (data.isAdmin === true || data.IsAdmin === true || ruleNum === 1) {
    claims.super_admin = true;
    claims.finance = true;
    claims.support = true;
  }
  if (ruleNum === 2) {
    claims.country_admin = true;
    // Do NOT grant finance — that unlocked unscoped order lists in rules.
    claims.support = true;
  }
  if (data.isagent === true || data.Isagent === true) {
    claims.agent = true;
    claims.support = true;
  }
  if (ruleNum === 3 || data.is_partner === true || data.isPartner === true) {
    claims.partner = true;
  }
  if (ruleNum === 4) {
    claims.transport_manager = true;
  }

  const countryRef = data.Rev_dloh_agent ?? data.Rev_dolh;
  if (countryRef && countryRef.path) {
    claims.country_id = countryRef.path;
  }
  if (data.partner_mkan && data.partner_mkan.path) {
    claims.partner_mkan_id = data.partner_mkan.path;
  }
  if (data.transport_company && data.transport_company.path) {
    claims.transport_company_id = data.transport_company.path;
  }

  return claims;
}

async function syncClaimsForUid(uid) {
  const snap = await db.doc(`user/${uid}`).get();
  if (!snap.exists) {
    await admin.auth().setCustomUserClaims(uid, {});
    return {};
  }
  const claims = deriveClaimsFromUserData(snap.data());
  await admin.auth().setCustomUserClaims(uid, claims);
  return claims;
}

exports.syncUserClaimsOnWrite = functions.firestore
  .document("user/{uid}")
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    if (!change.after.exists) {
      return null;
    }
    await syncClaimsForUid(uid);
    return null;
  });

exports.refreshMyClaims = functions.https.onCall(async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const claims = await syncClaimsForUid(context.auth.uid);
  return {claims};
});

// ── Server-only panel user creation ─────────────────────────────────────────

const PRIVILEGED_FIELDS = [
  "isAdmin",
  "IsAdmin",
  "isAdminRule",
  "IsAdminRule",
  "isagent",
  "Isagent",
  "isPartner",
  "Rev_dloh_agent",
  "partner_mkan",
  "transport_company",
];

function callerIsAdmin(callerClaims) {
  return callerClaims.super_admin === true || callerClaims.country_admin === true;
}

function hydrateUserData(raw) {
  const data = {...raw};
  const refFields = [
    "Rev_dloh_agent",
    "Rev_dolh",
    "partner_mkan",
    "transport_company",
    "mndob_vill",
    "mndob_type_car",
    "mndob_user",
    "region_ref",
  ];
  for (const field of refFields) {
    if (typeof data[field] === "string" && data[field].includes("/")) {
      data[field] = db.doc(data[field]);
    }
  }
  const timeFields = [
    "created_time",
    "agentDateReg",
    "agentDateEnd",
    "agent_date_reg",
    "agent_date_end",
  ];
  for (const field of timeFields) {
    if (typeof data[field] === "string") {
      const d = new Date(data[field]);
      if (!Number.isNaN(d.getTime())) {
        data[field] = admin.firestore.Timestamp.fromDate(d);
      }
    }
  }
  const geoFields = [
    "agent_geo_center",
    "agent_bounds_sw",
    "agent_bounds_ne",
    "geo_center",
    "bounds_sw",
    "bounds_ne",
  ];
  for (const field of geoFields) {
    const value = data[field];
    if (value && typeof value === "object" && !(value instanceof admin.firestore.GeoPoint)) {
      const lat = value.latitude ?? value.lat;
      const lng = value.longitude ?? value.lng ?? value.lon;
      if (typeof lat === "number" && typeof lng === "number") {
        data[field] = new admin.firestore.GeoPoint(lat, lng);
      }
    }
  }
  return data;
}

exports.createPanelUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const callerClaims = context.auth.token || {};
  if (!callerClaims.super_admin && !callerClaims.country_admin) {
    throw new functions.https.HttpsError("permission-denied", "Not authorized.");
  }

  const email = (data.email || "").trim();
  const password = data.password || "";
  const userData = data.userData || {};

  if (!email || password.length < 6) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid email/password.");
  }

  for (const field of PRIVILEGED_FIELDS) {
    if (field in userData && !callerClaims.super_admin) {
      if (field === "Rev_dloh_agent" && callerClaims.country_admin) {
        continue;
      }
      throw new functions.https.HttpsError(
        "permission-denied",
        `Cannot set ${field}`,
      );
    }
  }

  if (callerClaims.country_admin && !callerClaims.super_admin) {
    if (userData.Rev_dloh_agent && userData.Rev_dloh_agent !== callerClaims.country_id) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Country scope mismatch.",
      );
    }
    if (!userData.Rev_dloh_agent && callerClaims.country_id) {
      userData.Rev_dloh_agent = db.doc(callerClaims.country_id);
    }
  }

  let userRecord;
  try {
    userRecord = await admin.auth().createUser({email, password});
  } catch (e) {
    const code = (e && e.code) || "";
    if (code === "auth/email-already-exists" || code === "auth/email-already-in-use") {
      throw new functions.https.HttpsError("already-exists", e.message || code);
    }
    if (code === "auth/invalid-email" || code === "auth/invalid-password" || code === "auth/weak-password") {
      throw new functions.https.HttpsError("invalid-argument", e.message || code);
    }
    console.error("createPanelUser auth error", e);
    throw new functions.https.HttpsError("internal", e.message || "Auth create failed");
  }

  const uid = userRecord.uid;
  try {
    const doc = {
      email,
      uid,
      created_time: admin.firestore.FieldValue.serverTimestamp(),
      actev_user: true,
      ...hydrateUserData(userData),
    };

    await db.doc(`user/${uid}`).set(doc, {merge: true});
    await syncClaimsForUid(uid);
  } catch (e) {
    console.error("createPanelUser firestore error", e);
    try {
      await admin.auth().deleteUser(uid);
    } catch (cleanupErr) {
      console.error("createPanelUser cleanup failed", cleanupErr);
    }
    throw new functions.https.HttpsError(
      "internal",
      e.message || "Failed to write user profile",
    );
  }

  return {uid};
});

// ── Gemini proxy (no client keys) ───────────────────────────────────────────

exports.geminiGenerateText = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const token = context.auth.token || {};
  if (!token.super_admin && !token.country_admin && !token.agent) {
    throw new functions.https.HttpsError("permission-denied", "Not authorized.");
  }

  const prompt = data.prompt || "";
  if (!prompt) {
    throw new functions.https.HttpsError("invalid-argument", "prompt required");
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError("failed-precondition", "GEMINI_API_KEY not set");
  }

  const url =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=" +
    apiKey;

  const response = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      contents: [{parts: [{text: prompt}]}],
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new functions.https.HttpsError("internal", errText);
  }

  const json = await response.json();
  const text =
    json.candidates &&
    json.candidates[0] &&
    json.candidates[0].content &&
    json.candidates[0].content.parts &&
    json.candidates[0].content.parts[0] &&
    json.candidates[0].content.parts[0].text;

  return {text: text || ""};
});

// ── Financial aggregation (server-side, paginated) ──────────────────────────

function orderIsPaid(data) {
  if (data.halh_order === "Paid") return true;
  return (data.halh || "").toLowerCase() === "paid";
}

function orderIsCanceled(data) {
  if (data.halh_order === "Canceled") return true;
  return (data.halh || "").toLowerCase() === "canceled";
}

async function paginateOrders(query, pageSize = 500) {
  const all = [];
  let last = null;
  while (true) {
    let q = query.limit(pageSize);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;
    snap.docs.forEach((d) => all.push({id: d.id, ...d.data()}));
    last = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break;
  }
  return all;
}

exports.aggregateFinancialSummary = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const token = context.auth.token || {};
  if (!token.super_admin && !token.finance && !token.country_admin) {
    throw new functions.https.HttpsError("permission-denied", "Not authorized.");
  }

  const countryPath = data.countryPath || null;
  const periodStart = data.periodStart ? new Date(data.periodStart) : null;

  let query = db.collection("order").orderBy("data_order", "descending");
  if (countryPath) {
    query = query.where("Rev_dolh", "==", db.doc(countryPath));
  } else if (token.country_admin && token.country_id && !token.super_admin) {
    query = query.where("Rev_dolh", "==", db.doc(token.country_id));
  }
  if (periodStart) {
    query = query.where("data_order", ">=", periodStart);
  }

  const orders = await paginateOrders(query);

  let totalSales = 0;
  let appProfit = 0;
  let vat = 0;
  let repCommission = 0;
  let deliveryFees = 0;
  let paidCount = 0;
  let pendingCount = 0;
  let canceledCount = 0;
  let totalBookings = 0;
  let pendingSettlements = 0;

  for (const order of orders) {
    totalBookings++;
    if (orderIsCanceled(order)) {
      canceledCount++;
      continue;
    }
    if (orderIsPaid(order)) {
      paidCount++;
      totalSales += order.total || 0;
      appProfit += order.total_app || 0;
      vat += order.total_vat || 0;
      repCommission += order.total_mndob || 0;
      deliveryFees += order.total_mndob2 || 0;
    } else {
      pendingCount++;
      pendingSettlements += Number(order.total || 0);
    }
  }

  const summary = {
    totalSales,
    appProfit,
    vat,
    repCommission,
    deliveryFees,
    paidCount,
    pendingCount,
    canceledCount,
    totalBookings,
    pendingSettlements,
    orderCount: paidCount + pendingCount,
    source: "server",
    loadedAt: new Date().toISOString(),
  };

  const cacheKey = countryPath || token.country_id || "all";
  await db.doc(`admin_financial_cache/${cacheKey.replace(/\//g, "_")}`).set(summary);

  return summary;
});

// ── Audit log (server-only writes) ──────────────────────────────────────────

exports.recordAuditLog = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const token = context.auth.token || {};
  if (!token.super_admin && !token.country_admin && !token.agent && !token.support) {
    throw new functions.https.HttpsError("permission-denied", "Not authorized.");
  }

  await db.collection("admin_audit_log").add({
    actor_uid: context.auth.uid,
    actor_email: context.auth.token.email || "",
    action: data.action || "unknown",
    target: data.target || "",
    details: data.details || "",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {ok: true};
});

// ── Auth cleanup ────────────────────────────────────────────────────────────

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  await db.doc("user/" + user.uid).delete();
});

// ── Booking notifications ───────────────────────────────────────────────────

exports.notifyAdminsOnNewBooking = functions.firestore
  .document("order/{orderId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const orderId = context.params.orderId;

    if (data.halh_order === "Canceled") {
      return null;
    }

    const orderNumber = data.IDorder || orderId;
    const customerName = data.naim_user_text || "";
    const total = data.total != null ? String(data.total) : "";

    const countryRef = data.Rev_dolh;
    const adminDocs = [];

    const superAdminsSnap = await db
      .collection("user")
      .where("fcm_token", ">", "")
      .limit(200)
      .get();

    for (const doc of superAdminsSnap.docs) {
      const u = doc.data();
      if (u.isAdmin || u.IsAdmin || u.isAdminRule === 1 || u.IsAdminRule === 1) {
        adminDocs.push(doc);
      }
    }

    if (countryRef) {
      const agentsSnap = await db
        .collection("user")
        .where("Rev_dloh_agent", "==", countryRef)
        .where("fcm_token", ">", "")
        .limit(100)
        .get();
      agentsSnap.forEach((doc) => {
        adminDocs.push(doc);
      });
    }

    if (adminDocs.length === 0) {
      console.log("No admin FCM tokens registered.");
      return null;
    }

    // Group tokens by preferred_locale so each admin gets their language.
    const byLocale = new Map();
    for (const doc of adminDocs) {
      const u = doc.data() || {};
      const locale = normalizeNotifLocale(u.preferred_locale);
      if (!byLocale.has(locale)) {
        byLocale.set(locale, {tokens: new Set(), docs: []});
      }
      const bucket = byLocale.get(locale);
      bucket.docs.push(doc);
      collectTokens(doc, bucket.tokens);
    }

    let totalSent = 0;
    let totalTokens = 0;
    for (const [locale, bucket] of byLocale.entries()) {
      const tokens = Array.from(bucket.tokens);
      if (tokens.length === 0) continue;
      totalTokens += tokens.length;
      const copy = bookingNotifCopy(locale, {
        orderNumber,
        customerName: customerName || fallbackCustomerName(locale),
        total,
      });
      const message = {
        notification: {title: copy.title, body: copy.body},
        data: {
          type: "new_booking",
          orderId,
          code: "NEW_BOOKING",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "admin_bookings",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {payload: {aps: {sound: "default", badge: 1}}},
        tokens,
      };
      const response = await admin.messaging().sendEachForMulticast(message);
      totalSent += response.successCount;
      if (response.failureCount > 0) {
        const invalidTokens = [];
        response.responses.forEach((res, index) => {
          if (!res.success) invalidTokens.push(tokens[index]);
        });
        await cleanupInvalidTokens(bucket.docs, invalidTokens);
      }
    }

    console.log(`Booking ${orderId}: sent ${totalSent}/${totalTokens}`);
    return null;
  });

function normalizeNotifLocale(raw) {
  const code = String(raw || "en").split(/[_-]/)[0].toLowerCase();
  return ["ar", "en", "ru", "ky"].includes(code) ? code : "en";
}

function fallbackCustomerName(locale) {
  switch (locale) {
    case "ar":
      return "عميل";
    case "ru":
      return "Клиент";
    case "ky":
      return "Кардар";
    default:
      return "Customer";
  }
}

function bookingNotifCopy(locale, {orderNumber, customerName, total}) {
  const hasTotal = String(total || "").length > 0;
  switch (locale) {
    case "ar":
      return {
        title: "حجز جديد",
        body: hasTotal
          ? `حجز #${orderNumber} من ${customerName} — ${total}`
          : `حجز #${orderNumber} من ${customerName} بانتظار الموافقة`,
      };
    case "ru":
      return {
        title: "Новое бронирование",
        body: hasTotal
          ? `Бронь #${orderNumber} от ${customerName} — ${total}`
          : `Бронь #${orderNumber} от ${customerName} ожидает подтверждения`,
      };
    case "ky":
      return {
        title: "Жаңы брондоо",
        body: hasTotal
          ? `Брон #${orderNumber} — ${customerName} — ${total}`
          : `Брон #${orderNumber} — ${customerName} бекитүүнү күтүүдө`,
      };
    default:
      return {
        title: "New booking",
        body: hasTotal
          ? `Booking #${orderNumber} from ${customerName} — ${total}`
          : `Booking #${orderNumber} from ${customerName} awaiting approval`,
      };
  }
}

function collectTokens(doc, tokenSet) {
  const user = doc.data();
  if (user.fcm_token) tokenSet.add(user.fcm_token);
  (user.fcm_tokens || []).forEach((token) => {
    if (token) tokenSet.add(token);
  });
}

async function cleanupInvalidTokens(adminDocs, invalidTokens) {
  if (!invalidTokens.length) return;

  const batch = db.batch();
  let writes = 0;

  adminDocs.forEach((doc) => {
    const data = doc.data();
    const current = new Set(
      [data.fcm_token, ...(data.fcm_tokens || [])].filter(Boolean),
    );
    let changed = false;

    invalidTokens.forEach((bad) => {
      if (current.delete(bad)) changed = true;
    });

    if (!changed) return;

    const remaining = Array.from(current);
    const update = {fcm_tokens: remaining};
    if (remaining.length > 0) {
      update.fcm_token = remaining[remaining.length - 1];
    } else {
      update.fcm_token = admin.firestore.FieldValue.delete();
    }

    batch.update(doc.ref, update);
    writes++;
  });

  if (writes > 0) await batch.commit();
}

// ── Admin wallet adjustment (finance / super_admin only) ────────────────────

exports.adminAdjustDriverWallet = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const token = context.auth.token || {};
  if (!token.super_admin && !token.finance) {
    throw new functions.https.HttpsError("permission-denied", "Not authorized.");
  }

  const driverId = String((data && data.driverId) || "").trim();
  const amount = Number(data && data.amount);
  const note = String((data && data.note) || "").trim().slice(0, 500);
  const currency = String((data && data.currency) || "SAR").trim().toUpperCase() || "SAR";

  if (!driverId) {
    throw new functions.https.HttpsError("invalid-argument", "driverId required.");
  }
  if (!Number.isFinite(amount) || amount === 0 || Math.abs(amount) > 50000) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "amount must be a non-zero number within ±50000.",
    );
  }

  const userRef = db.collection("user").doc(driverId);
  const wallets = await db
    .collection("wallets")
    .where("userRef", "==", userRef)
    .limit(1)
    .get();
  const walletRef = wallets.empty
    ? db.collection("wallets").doc(driverId)
    : wallets.docs[0].ref;

  const ledgerId = `admin_adj_${driverId.slice(0, 8)}_${Date.now()}`;
  const ledgerRef = db.collection("transactions").doc(ledgerId);

  let balanceBefore = 0;
  let balanceAfter = 0;

  try {
    await db.runTransaction(async (tx) => {
      const wallet = await tx.get(walletRef);
      balanceBefore = wallet.exists ? Number(wallet.data().currentBalance || 0) : 0;
      balanceAfter = balanceBefore + amount;
      if (balanceAfter < 0) {
        throw new Error("INSUFFICIENT_BALANCE");
      }

      tx.set(
        walletRef,
        {
          userRef,
          currentBalance: balanceAfter,
          walletBalance: balanceAfter,
          currency,
          isActive: true,
          walletUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          ...(wallet.exists
            ? {}
            : {createdAt: admin.firestore.FieldValue.serverTimestamp()}),
        },
        {merge: true},
      );

      tx.set(ledgerRef, {
        driverId,
        userRef,
        walletRef,
        type: "admin_adjustment",
        amount,
        currency,
        status: "completed",
        description_code: amount > 0 ? "admin_credit" : "admin_debit",
        notes: note || `Admin adjustment by ${context.auth.uid}`,
        balanceBefore,
        balanceAfter,
        actorUid: context.auth.uid,
        actorEmail: (context.auth.token && context.auth.token.email) || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  } catch (e) {
    if (String((e && e.message) || e).includes("INSUFFICIENT_BALANCE")) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Insufficient wallet balance for debit.",
      );
    }
    throw e;
  }

  await db.collection("admin_audit_log").add({
    actor_uid: context.auth.uid,
    actor_email: (context.auth.token && context.auth.token.email) || "",
    action: "wallet_adjust",
    target: `wallets/${walletRef.id}`,
    details: JSON.stringify({
      driverId,
      amount,
      balanceBefore,
      balanceAfter,
      note,
      ledgerId,
    }),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    ok: true,
    driverId,
    walletId: walletRef.id,
    amount,
    balanceBefore,
    balanceAfter,
    ledgerId,
  };
});
