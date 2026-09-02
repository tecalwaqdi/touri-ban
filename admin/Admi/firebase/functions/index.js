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

  let query = db.collection("order").orderBy("data_order", "desc");
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

// ── Financial Accounting V2 (read-only, full-dataset) ───────────────────────
const financialV2 = require('./financial_accounting_v2');
const aggMetrics = require('./finance_aggregation_metrics');
const {loadFinanceFeatureFlags, assertFlag} = require('./finance_feature_flags');
const {normalizeErrorCode} = require('./finance_error_codes');

exports.aggregateFinancialAccountingV2 = functions
  .runWith({timeoutSeconds: 300, memory: '1GB'})
  .https.onCall(async (data, context) => {
    const startedAtMs = Date.now();
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
    }
    const token = context.auth.token || {};
    if (!token.super_admin && !token.finance && !token.country_admin) {
      throw new functions.https.HttpsError('permission-denied', 'PERMISSION_DENIED');
    }

    const countryPath = data.countryPath || null;
    const periodStart = data.periodStart ? new Date(data.periodStart) : null;
    const periodEnd = data.periodEnd ? new Date(data.periodEnd) : null;
    const driverId = data.driverId ? String(data.driverId) : null;
    const mode = data.mode || 'totals'; // totals | settlement_preview

    // Agents/country_admin: force country scope server-side.
    let effectiveCountry = countryPath;
    if (token.country_admin && token.country_id && !token.super_admin && !token.finance) {
      effectiveCountry = token.country_id.startsWith('countries/')
        ? token.country_id
        : `countries/${token.country_id}`;
      if (countryPath && countryPath !== effectiveCountry) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'PERMISSION_DENIED',
          {reason: 'Country agent cannot query another country.'},
        );
      }
    }

    const filters = {
      channel: data.channel || null,
      lifecycle: data.lifecycle || null,
      payment: data.payment || null,
      confidence: data.confidence || null,
      currency: data.currency || null,
      driverId,
    };

    let query = db.collection('order').orderBy('data_order', 'desc');
    let applyDateInMemory = false;

    if (driverId) {
      // Prefer driver-scoped query; apply date filters in memory to avoid missing composites.
      query = db
        .collection('order')
        .where('mndob_user', '==', db.doc(`user/${driverId}`))
        .orderBy('data_order', 'desc');
      applyDateInMemory = true;
    } else if (effectiveCountry) {
      query = db
        .collection('order')
        .where('Rev_dolh', '==', db.doc(effectiveCountry))
        .orderBy('data_order', 'desc');
      if (periodStart) {
        query = query.where('data_order', '>=', periodStart);
      }
      if (periodEnd) {
        query = query.where('data_order', '<', periodEnd);
      }
    } else {
      if (periodStart) {
        query = query.where('data_order', '>=', periodStart);
      }
      if (periodEnd) {
        query = query.where('data_order', '<', periodEnd);
      }
    }

    let orders = await paginateOrders(query, 400);
    if (applyDateInMemory) {
      orders = orders.filter((o) => {
        const ts = o.data_order;
        if (!ts) return false;
        const d = ts.toDate ? ts.toDate() : new Date(ts);
        if (periodStart && d < periodStart) return false;
        if (periodEnd && !(d < periodEnd)) return false;
        if (effectiveCountry) {
          const path = o.Rev_dolh && o.Rev_dolh.path ? o.Rev_dolh.path : '';
          if (path !== effectiveCountry) return false;
        }
        return true;
      });
    }
    const byCurrency = {};
    const lines = [];
    let missingPaymentStatus = 0;
    let missingLifecycle = 0;
    let missingDriver = 0;
    let unsupportedCurrency = 0;

    for (const order of orders) {
      const line = financialV2.analyzeOrder(order.id, order);
      if (!order.payment_status) missingPaymentStatus++;
      if (!order.status_code) missingLifecycle++;
      if (!line.driverId) missingDriver++;
      if (!line.currencySupported) unsupportedCurrency++;
      if (!financialV2.matchesFilters(line, filters)) continue;
      lines.push(line);
      financialV2.accumulate(byCurrency, line);
    }

    // Exposure across currencies
    const exposure = {};
    for (const [code, t] of Object.entries(byCurrency)) {
      exposure[code] = {
        driversOweCompanyMinor: t.cashDriversOweCompanyMinor,
        companyOwesDriversMinor:
          t.cashCompanyOwesDriversMinor + t.onlineCompanyOwesDriversMinor,
        netTripExposureMinor:
          t.cashDriversOweCompanyMinor -
          t.cashCompanyOwesDriversMinor -
          t.onlineCompanyOwesDriversMinor,
        incompleteLines: t.incompleteLines,
      };
    }

    const quality = {
      totalLines: lines.length,
      high: lines.filter((l) => l.confidence === 'high').length,
      derived: lines.filter((l) => l.confidence === 'derived').length,
      incomplete: lines.filter((l) => l.confidence === 'incomplete').length,
      reconciled: lines.filter((l) => l.reconStatus === 'reconciled').length,
      reconciliationDifference: lines.filter((l) => l.reconStatus === 'difference').length,
      unsupportedCurrency,
      missingPaymentStatus,
      missingLifecycle,
      missingDriver,
      docsScanned: orders.length,
    };

    const result = {
      source: 'server_v2',
      filterSignature: [
        effectiveCountry || 'all',
        periodStart ? periodStart.toISOString() : '',
        periodEnd ? periodEnd.toISOString() : '',
        driverId || '',
        filters.channel || '',
        filters.lifecycle || '',
        filters.payment || '',
        filters.confidence || '',
        filters.currency || '',
      ].join('|'),
      byCurrency,
      exposure,
      quality,
      loadedAt: new Date().toISOString(),
      // Read-only: never write cache/orders/wallets.
    };

    if (mode === 'settlement_preview') {
      if (!driverId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'driverId required for settlement_preview',
        );
      }
      const currency =
        financialV2.normalizeCode(data.currency || Object.keys(byCurrency)[0] || 'SAR');
      result.settlementPreview = financialV2.settlePreviewForDriver(lines, currency);
    }

    const metrics = aggMetrics.buildAggregationMetrics({
      startedAtMs,
      ordersScanned: orders.length,
      filters: {
        country: effectiveCountry || 'all',
        periodStart: periodStart ? periodStart.toISOString() : null,
        periodEnd: periodEnd ? periodEnd.toISOString() : null,
        ...filters,
        mode,
      },
      resultCurrencyCount: Object.keys(byCurrency).length,
      cacheHit: false,
      token,
      op: 'aggregateFinancialAccountingV2',
    });
    result.metrics = metrics;
    await aggMetrics.writeAggregationMetric(db, metrics);

    return result;
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

// ── LEGACY_WALLET_TOOL — not part of settlement V2 ──────────────────────────
// SuperAdmin-only escape hatch. Finance must use settlement ledger / payments.
// Gated by WALLET_SETTLEMENT_ENABLED (default OFF). Optional idempotencyKey.

exports.adminAdjustDriverWallet = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const token = context.auth.token || {};
  // Least privilege: finance removed — settlement V2 is the finance path.
  if (!token.super_admin) {
    throw new functions.https.HttpsError("permission-denied", "PERMISSION_DENIED");
  }
  const flags = await loadFinanceFeatureFlags(db);
  if (!flags.WALLET_SETTLEMENT_ENABLED) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "FEATURE_FLAG_DISABLED",
      {flag: "WALLET_SETTLEMENT_ENABLED"},
    );
  }

  const driverId = String((data && data.driverId) || "").trim();
  const amount = Number(data && data.amount);
  const note = String((data && data.note) || "").trim().slice(0, 500);
  const currency = String((data && data.currency) || "SAR").trim().toUpperCase() || "SAR";
  const idempotencyKey = String((data && data.idempotencyKey) || "").trim();

  if (!driverId) {
    throw new functions.https.HttpsError("invalid-argument", "driverId required.");
  }
  if (!Number.isFinite(amount) || amount === 0 || Math.abs(amount) > 50000) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "amount must be a non-zero number within ±50000.",
    );
  }

  if (idempotencyKey) {
    const priorSnap = await db
      .collection("financial_wallet_adjust_idempotency")
      .doc(idempotencyKey)
      .get();
    if (priorSnap.exists && priorSnap.data() && priorSnap.data().result) {
      return priorSnap.data().result;
    }
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
  const idempRef = idempotencyKey
    ? db.collection("financial_wallet_adjust_idempotency").doc(idempotencyKey)
    : null;

  let balanceBefore = 0;
  let balanceAfter = 0;
  let result = null;

  try {
    await db.runTransaction(async (tx) => {
      if (idempRef) {
        const prior = await tx.get(idempRef);
        if (prior.exists && prior.data() && prior.data().result) {
          result = prior.data().result;
          return;
        }
      }

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
        ...(idempotencyKey ? {idempotencyKey} : {}),
      });

      result = {
        ok: true,
        driverId,
        walletId: walletRef.id,
        amount,
        balanceBefore,
        balanceAfter,
        ledgerId,
        ...(idempotencyKey ? {idempotencyKey} : {}),
      };

      if (idempRef) {
        tx.set(idempRef, {
          result,
          actorUid: context.auth.uid,
          driverId,
          amount,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
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
      balanceBefore: result.balanceBefore,
      balanceAfter: result.balanceAfter,
      note,
      ledgerId: result.ledgerId,
      idempotencyKey: idempotencyKey || null,
      legacyTool: "LEGACY_WALLET_TOOL",
    }),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return result;
});

// ── FIN-9 Agent prospective snapshot (new orders only, onCreate) ────────────
const agentOrderSnapshot = require('./agent_order_snapshot.js');

exports.syncAgentSnapshotOnOrderCreate = functions.firestore
  .document('order/{orderId}')
  .onCreate(async (snap, context) => {
    try {
      await agentOrderSnapshot.applyAgentSnapshotOnCreate({
        db,
        orderId: context.params.orderId,
        order: snap.data() || {},
      });
    } catch (e) {
      console.error(
        'syncAgentSnapshotOnOrderCreate failed',
        context.params.orderId,
        e.message || e,
      );
    }
    return null;
  });

// ── Settlement Ledger V2 (accounting records only; no wallet/order writes) ──
const settlementLedger = require('./settlement_ledger');

function wrapSettlement(fn) {
  return async (data, context) => {
    try {
      return await fn({
        db,
        auth: context.auth,
        data: data || {},
        now: new Date(),
      });
    } catch (e) {
      if (e instanceof settlementLedger.SettlementError) {
        const code = normalizeErrorCode(e.message) || e.code;
        throw new functions.https.HttpsError(
          e.code || 'failed-precondition',
          e.message,
          {...(e.details || {}), errorCode: code},
        );
      }
      throw e;
    }
  };
}

exports.createSettlementDraftV2 = functions
  .runWith({timeoutSeconds: 120, memory: '512MB'})
  .https.onCall(wrapSettlement(settlementLedger.createSettlementDraft));

exports.refreshSettlementDraftV2 = functions
  .runWith({timeoutSeconds: 120, memory: '512MB'})
  .https.onCall(wrapSettlement(settlementLedger.refreshSettlementDraft));

exports.lockSettlementV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(settlementLedger.lockSettlement));

exports.markSettlementSettledV2 = functions
  .https.onCall(wrapSettlement(settlementLedger.markSettlementSettled));

exports.voidSettlementV2 = functions
  .runWith({timeoutSeconds: 120, memory: '512MB'})
  .https.onCall(wrapSettlement(settlementLedger.voidSettlement));

exports.allocateLegacyPaymentV2 = functions
  .https.onCall(wrapSettlement(settlementLedger.allocateLegacyPayment));

const settlementPayments = require('./settlement_payments');

exports.createSettlementPaymentV2 = functions
  .https.onCall(wrapSettlement(settlementPayments.createSettlementPayment));

exports.confirmSettlementPaymentV2 = functions
  .runWith({timeoutSeconds: 60, memory: '256MB'})
  .https.onCall(wrapSettlement(settlementPayments.confirmSettlementPayment));

exports.reverseSettlementPaymentV2 = functions
  .https.onCall(wrapSettlement(settlementPayments.reverseSettlementPayment));

exports.allocateExistingPaymentV2 = functions
  .https.onCall(wrapSettlement(settlementPayments.allocateExistingPayment));

exports.aggregateSettlementExposureV2 = functions
  .runWith({timeoutSeconds: 120, memory: '512MB'})
  .https.onCall(wrapSettlement(settlementPayments.aggregateSettlementExposure));

const financeControls = require('./finance_controls');

exports.createFinancialPeriodV2 = functions
  .https.onCall(wrapSettlement(financeControls.createFinancialPeriod));
exports.closeFinancialPeriodV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.closeFinancialPeriod));
exports.reopenFinancialPeriodV2 = functions
  .https.onCall(wrapSettlement(financeControls.reopenFinancialPeriod));
exports.periodCloseChecklistV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.buildPeriodCloseChecklist));
exports.scanFinancialExceptionsV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.scanFinancialExceptions));
exports.listIncompleteOrdersV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.listIncompleteOrders));
exports.detectFinanceOrphansV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.detectOrphans));
exports.createAdjustmentDraftV2 = functions
  .https.onCall(wrapSettlement(financeControls.createAdjustmentDraft));
exports.approveAdjustmentV2 = functions
  .https.onCall(wrapSettlement(financeControls.approveAdjustment));
exports.reverseAdjustmentV2 = functions
  .https.onCall(wrapSettlement(financeControls.reverseAdjustment));
exports.createOpeningBalanceV2 = functions
  .https.onCall(wrapSettlement(financeControls.createOpeningBalance));
exports.loadDriverStatementV2 = functions
  .runWith({timeoutSeconds: 120, memory: '512MB'})
  .https.onCall(wrapSettlement(financeControls.loadDriverStatement));
exports.aggregateCompanyPositionV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.aggregateCompanyPosition));
exports.periodDashboardV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.periodDashboard));
exports.accountantHomeV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.accountantHome));
exports.verifySettlementSourceV2 = functions
  .runWith({timeoutSeconds: 120, memory: '512MB'})
  .https.onCall(wrapSettlement(financeControls.verifySettlementAgainstSource));
exports.searchFinanceAuditV2 = functions
  .runWith({timeoutSeconds: 60, memory: '256MB'})
  .https.onCall(wrapSettlement(financeControls.searchFinanceAudit));
exports.financialReportV2 = functions
  .runWith({timeoutSeconds: 180, memory: '1GB'})
  .https.onCall(wrapSettlement(financeControls.financialReport));
exports.financeApprovalPolicyV2 = functions
  .https.onCall(wrapSettlement(financeControls.financeApprovalPolicy));
exports.requestExistingPaymentAllocationV2 = functions
  .https.onCall(wrapSettlement(settlementPayments.requestExistingPaymentAllocation));

// Driver Registration V2 (shared Firebase project) — also exported from
// ara_oatan_app; keep both deployable without losing callables.
const driverRegistrationV2 = require('./driver_registration_v2.js');
const driverFinancialSummaryV2 = require('./driver_financial_summary_v2.js');
const cashCollectionRealization = require('./cash_collection_realization.js');
exports.submitDriverApplicationV2 = functions
  .region('us-central1')
  .https.onCall(driverRegistrationV2.submitDriverApplicationV2);
exports.reviewDriverApplicationV2 = functions
  .region('us-central1')
  .https.onCall(driverRegistrationV2.reviewDriverApplicationV2);

// Driver app — read-only financial summary (completed trips only).
exports.getDriverFinancialSummaryV2 = functions
  .region('us-central1')
  .runWith({timeoutSeconds: 60, memory: '256MB'})
  .https.onCall(async (data, context) => {
    try {
      return await driverFinancialSummaryV2.getDriverFinancialSummaryV2({
        db,
        auth: context.auth,
        data: data || {},
      });
    } catch (e) {
      const code = e.code === 'permission-denied' || e.code === 'unauthenticated'
        ? e.code
        : 'internal';
      throw new functions.https.HttpsError(code, e.message || 'Summary failed');
    }
  });

// Phase C — server-authoritative cash collection (future trips only; flag-gated).
exports.confirmCashCollectionV2 = functions
  .region('us-central1')
  .runWith({timeoutSeconds: 60, memory: '256MB'})
  .https.onCall(async (data, context) => {
    try {
      return await cashCollectionRealization.confirmCashCollectionV2({
        db,
        auth: context.auth,
        data: data || {},
        admin,
      });
    } catch (e) {
      const code =
        e.code === 'permission-denied' ||
        e.code === 'unauthenticated' ||
        e.code === 'failed-precondition' ||
        e.code === 'invalid-argument' ||
        e.code === 'not-found'
          ? e.code
          : 'internal';
      throw new functions.https.HttpsError(code, e.message || 'Cash collection failed', e.details);
    }
  });

// Driver Email OTP verification (Resend) — replaces email link for Registration V2.
const emailVerificationOtp = require('./email_verification_otp.js');
const emailOtpSecrets = ['RESEND_API_KEY', 'EMAIL_OTP_HMAC_SECRET'];

exports.requestEmailVerificationOtp = functions
  .region('us-central1')
  .runWith({timeoutSeconds: 30, memory: '256MB', secrets: emailOtpSecrets})
  .https.onCall((data, context) =>
    emailVerificationOtp.requestEmailVerificationOtp(data || {}, context),
  );

exports.verifyEmailVerificationOtp = functions
  .region('us-central1')
  .runWith({timeoutSeconds: 30, memory: '256MB', secrets: emailOtpSecrets})
  .https.onCall((data, context) =>
    emailVerificationOtp.verifyEmailVerificationOtp(data || {}, context),
  );
