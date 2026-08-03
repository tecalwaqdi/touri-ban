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
    claims.finance = true;
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
  ];
  for (const field of refFields) {
    if (typeof data[field] === "string" && data[field].includes("/")) {
      data[field] = db.doc(data[field]);
    }
  }
  const timeFields = ["created_time", "agentDateReg", "agentDateEnd"];
  for (const field of timeFields) {
    if (typeof data[field] === "string") {
      data[field] = admin.firestore.Timestamp.fromDate(new Date(data[field]));
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
    throw new functions.https.HttpsError("already-exists", e.message);
  }

  const uid = userRecord.uid;
  const doc = {
    email,
    uid,
    created_time: admin.firestore.FieldValue.serverTimestamp(),
    actev_user: true,
    ...hydrateUserData(userData),
  };

  await db.doc(`user/${uid}`).set(doc, {merge: true});
  await syncClaimsForUid(uid);

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
    orderCount: paidCount + pendingCount,
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
    const customerName = data.naim_user_text || "عميل";
    const total = data.total != null ? String(data.total) : "";

    const countryRef = data.Rev_dolh;
    const tokenSet = new Set();
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
        collectTokens(doc, tokenSet);
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
        collectTokens(doc, tokenSet);
      });
    }

    const tokens = Array.from(tokenSet);
    if (tokens.length === 0) {
      console.log("No admin FCM tokens registered.");
      return null;
    }

    const body =
      total.length > 0
        ? `حجز #${orderNumber} من ${customerName} — ${total} ريال`
        : `حجز #${orderNumber} من ${customerName} بانتظار الموافقة`;

    const message = {
      notification: {title: "حجز جديد", body},
      data: {
        type: "new_booking",
        orderId,
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
    console.log(`Booking ${orderId}: sent ${response.successCount}/${tokens.length}`);

    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((res, index) => {
        if (!res.success) invalidTokens.push(tokens[index]);
      });
      await cleanupInvalidTokens(adminDocs, invalidTokens);
    }

    return null;
  });

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
