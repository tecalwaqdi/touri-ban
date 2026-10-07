/**
 * Server-authoritative nearest-driver offer waves.
 *
 * Strategy (deterministic distance-ranked cohorts):
 * 1. Build eligibleDrivers: approved + online (ngl) + available (actev_mndob)
 *    + not on active trip + same order country + vehicle match + fresh GPS.
 * 2. Sort ASC by haversine(driver GPS → pickup).
 * 3. Release offer in cohorts of COHORT_SIZE every OFFER_WINDOW_MS.
 * 4. FCM only to the current wave's UIDs.
 * 5. acceptDriverOrder rejects UIDs outside the current wave (unless open).
 * 6. When a driver accepts, mndob_user is set → waves stop (scheduler no-ops).
 * 7. Search lifetime remains acceptanceDeadline (60 minutes) via autoCancelOrders.
 *
 * Does NOT replace acceptDriverOrder — only gates who may see/claim.
 */
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const {
  driverIsOperationallyApproved,
} = require("./driver_registration_notifications.js");

const COHORT_SIZE = 3;
/** Target offer window; expansion also runs on schedule + client refresh. */
const OFFER_WINDOW_MS = 30 * 1000;
const GPS_MAX_AGE_MS = 5 * 60 * 1000;
/** Same-city proximity gate (km). Cross-city offers are not shown. */
const SAME_CITY_PROXIMITY_KM = 30;

function haversineKm(a, b) {
  const toRad = (d) => (d * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

function pickupOf(order) {
  const lok = order.LOKESHN || order.mapuser;
  if (lok && typeof lok.latitude === "number") {
    return { lat: lok.latitude, lng: lok.longitude };
  }
  const lat = Number(order.originLatitude);
  const lng = Number(order.originLongitude);
  if (Number.isFinite(lat) && Number.isFinite(lng) && (lat !== 0 || lng !== 0)) {
    return { lat, lng };
  }
  return null;
}

function geoOf(user) {
  const g = user.loceshnMndobNow;
  if (g && typeof g.latitude === "number") {
    return { lat: g.latitude, lng: g.longitude };
  }
  return null;
}

function gpsAgeMs(user, nowMs) {
  const ts = user.work_area_updated_at || user.last_seen_at || user.loceshn_updated_at;
  if (ts && typeof ts.toMillis === "function") return nowMs - ts.toMillis();
  if (typeof ts === "number") return nowMs - ts;
  return Number.POSITIVE_INFINITY;
}

function pathOf(ref) {
  if (!ref) return "";
  if (typeof ref.path === "string") return ref.path;
  return String(ref);
}

function isAssignablePending(order) {
  if (order.mndob_user) return false;
  if (order.ALLNOW === false) return false;
  const c = String(order.status_code || "").toLowerCase().trim();
  if (c && c !== "pending_driver" && c !== "awaiting_driver" && c !== "pending") {
    return false;
  }
  return true;
}

function vehicleMatch(driver, order) {
  const orderCar = pathOf(order.carRev);
  if (!orderCar) return true;
  const dCar = pathOf(driver.mndob_type_car || driver.carRev_mndob || driver.car_rev_mndob);
  if (!dCar) return false;
  return dCar === orderCar;
}

function sameCountry(driver, order) {
  const orderCountry = pathOf(order.Rev_dolh);
  if (!orderCountry) return true;
  const dCountry =
    pathOf(driver.work_country_now) ||
    pathOf(driver.dolh) ||
    pathOf(driver.mndob_dolh);
  // Village-derived country is resolved client-side into work_country_now.
  if (!dCountry) return true;
  return dCountry === orderCountry;
}

function driverCityPath(driver) {
  return (
    pathOf(driver.work_city_now) ||
    pathOf(driver.mdenh) ||
    ""
  );
}

function orderCityPath(order) {
  return pathOf(order.cities_user_now) || pathOf(order.cities) || "";
}

async function loadEligibleDrivers(firestore, order, nowMs) {
  const snap = await firestore
    .collection("user")
    .where("actev_mndob", "==", true)
    .where("ismndom", "==", true)
    .where("ismndob", "==", true)
    .where("ngl", "==", true)
    .limit(400)
    .get();

  const pickup = pickupOf(order);
  const scored = [];

  for (const doc of snap.docs) {
    const d = doc.data() || {};
    if (d.active_order_id) continue;
    if (d.mndob_busy === true) continue;
    if (d.mndonNewacc === true || d.mndon_newacc === true) continue;
    if (!driverIsOperationallyApproved(d)) continue;
    if (!sameCountry(d, order)) continue;
    if (!vehicleMatch(d, order)) continue;

    const geo = geoOf(d);
    if (!geo || !pickup) continue;
    const age = gpsAgeMs(d, nowMs);
    if (age > GPS_MAX_AGE_MS) continue;

    const km = haversineKm(geo, pickup);
    if (!Number.isFinite(km)) continue;

    const dCity = driverCityPath(d);
    const oCity = orderCityPath(order);
    const sameCity = dCity && oCity && dCity === oCity;
    // Require same work city and proximity to pickup.
    if (!sameCity) continue;
    if (km > SAME_CITY_PROXIMITY_KM) continue;

    scored.push({ uid: doc.id, km, ref: doc.ref });
  }

  scored.sort((a, b) => a.km - b.km);
  return scored;
}

const WAVE_PUSH_COPY = {
  en: {
    title: "New booking",
    body: (hours, amount, currency) =>
      `A new Touri Taxi booking is available for ${hours} hours with earnings of ${amount} ${currency}. Open the driver app to review it.`,
  },
  ar: {
    title: "حجز جديد",
    body: (hours, amount, currency) =>
      `يتوفر حجز جديد لتاكسي توري لمدة ${hours} ساعة بأرباح ${amount} ${currency}. افتح تطبيق السائق لمراجعته.`,
  },
  fr: {
    title: "Nouvelle réservation",
    body: (hours, amount, currency) =>
      `Une nouvelle course Touri Taxi est disponible pour ${hours} h avec un gain de ${amount} ${currency}. Ouvrez l'app chauffeur pour la consulter.`,
  },
  ru: {
    title: "Новое бронирование",
    body: (hours, amount, currency) =>
      `Доступно новое бронирование Touri Taxi на ${hours} ч. с заработком ${amount} ${currency}. Откройте приложение водителя.`,
  },
  pt: {
    title: "Nova reserva",
    body: (hours, amount, currency) =>
      `Uma nova reserva Touri Taxi está disponível por ${hours} horas com ganhos de ${amount} ${currency}. Abra o app do motorista.`,
  },
  ur: {
    title: "نئی بکنگ",
    body: (hours, amount, currency) =>
      `ٹوری ٹیکسی کی نئی بکنگ ${hours} گھنٹے کے لیے دستیاب ہے، آمدنی ${amount} ${currency}۔ ڈرائیور ایپ کھولیں۔`,
  },
  ky: {
    title: "Жаңы ээлөө",
    body: (hours, amount, currency) =>
      `Touri Taxi жаңы ээлөөсү ${hours} саатка жеткиликтүү, киреше ${amount} ${currency}. Айдоочу колдонмосун ачыңыз.`,
  },
};

function waveLocaleFromPreferred(preferred) {
  const code = String(preferred || "en")
    .trim()
    .replace("_", "-")
    .split("-")[0]
    .toLowerCase();
  return WAVE_PUSH_COPY[code] ? code : "en";
}

async function enqueueWavePush(firestore, orderRef, order, waveUids) {
  if (!waveUids.length) return;
  const hours = order.total_taim ?? order.totalTaim ?? "";
  const amount = order.total_mndob3 ?? order.totalmndob3 ?? order.total_mndob ?? "";
  const currency = order.currency_code || order.currency || "SAR";
  const orderPath = orderRef.path;
  const parameterData = JSON.stringify({
    idorder: orderPath,
    id: orderRef.id,
  });

  // Group recipients by preferred_locale so each driver gets local copy.
  const localeGroups = new Map();
  const docs = await Promise.all(
    waveUids.map((uid) => firestore.collection("user").doc(uid).get()),
  );
  for (let i = 0; i < waveUids.length; i++) {
    const uid = waveUids[i];
    const preferred = docs[i].exists
      ? docs[i].data()?.preferred_locale
      : undefined;
    const locale = waveLocaleFromPreferred(preferred);
    if (!localeGroups.has(locale)) localeGroups.set(locale, []);
    localeGroups.get(locale).push(`user/${uid}`);
  }

  const writes = [];
  for (const [locale, userPaths] of localeGroups.entries()) {
    const copy = WAVE_PUSH_COPY[locale] || WAVE_PUSH_COPY.en;
    writes.push(
      firestore.collection("ff_user_push_notifications").add({
        notification_title: copy.title,
        notification_text: copy.body(hours, amount, currency),
        // Comma-separated paths — sendPushNotifications expects a string.
        user_refs: userPaths.join(","),
        initial_page_name: "TfaselOrser",
        parameter_data: parameterData,
        order_ref: orderRef,
        offer_wave: true,
        source: "order_offer_waves",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: "",
      }),
    );
  }
  await Promise.all(writes);
}

async function applyWave(firestore, orderRef, order, ranked, waveIndex) {
  const start = waveIndex * COHORT_SIZE;
  const cohort = ranked.slice(start, start + COHORT_SIZE);
  const waveUids = cohort.map((c) => c.uid);
  const prevNotified = Array.isArray(order.offer_notified_uids)
    ? order.offer_notified_uids
    : [];
  const notified = Array.from(new Set([...prevNotified, ...waveUids]));
  const exhausted = start + COHORT_SIZE >= ranked.length;
  const until = admin.firestore.Timestamp.fromMillis(Date.now() + OFFER_WINDOW_MS);

  const patch = {
    offer_wave_index: waveIndex,
    offer_wave_uids: waveUids,
    offer_ranked_uids: ranked.map((r) => r.uid),
    offer_ranked_km: ranked.map((r) => Math.round(r.km * 100) / 100),
    offer_notified_uids: notified,
    offer_wave_until: until,
    offer_wave_open: exhausted && waveUids.length === 0,
    offer_wave_strategy: "distance_cohort_asc_v1",
    offer_cohort_size: COHORT_SIZE,
    offer_window_ms: OFFER_WINDOW_MS,
    offer_updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  // When fully exhausted after last cohort window, open remaining eligible.
  if (exhausted && waveIndex > 0 && waveUids.length === 0) {
    patch.offer_wave_open = true;
    patch.offer_wave_uids = [];
  }

  await orderRef.update(patch);
  if (waveUids.length) {
    await enqueueWavePush(firestore, orderRef, order, waveUids);
  }
  return { waveIndex, waveUids, exhausted };
}

async function ensureWaveForOrder(firestore, orderDoc, nowMs) {
  const order = orderDoc.data() || {};
  if (!isAssignablePending(order)) return { skipped: "not_pending" };

  const ranked = await loadEligibleDrivers(firestore, order, nowMs);
  const existingIndex =
    typeof order.offer_wave_index === "number" ? order.offer_wave_index : -1;
  const untilMs =
    order.offer_wave_until && typeof order.offer_wave_until.toMillis === "function"
      ? order.offer_wave_until.toMillis()
      : 0;

  // First wave.
  if (existingIndex < 0 || !Array.isArray(order.offer_ranked_uids)) {
    return applyWave(firestore, orderDoc.ref, order, ranked, 0);
  }

  // Still inside window — keep current cohort.
  if (nowMs < untilMs && !order.offer_wave_open) {
    return { skipped: "window_open", waveIndex: existingIndex };
  }

  // Expand to next cohort.
  const next = existingIndex + 1;
  if (next * COHORT_SIZE >= ranked.length) {
    await orderDoc.ref.update({
      offer_wave_open: true,
      offer_wave_uids: [],
      offer_updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { open: true };
  }
  return applyWave(firestore, orderDoc.ref, { ...order, offer_notified_uids: order.offer_notified_uids }, ranked, next);
}

/** True when uid may accept under current wave rules. */
function isUidInCurrentOfferWave(order, uid) {
  if (!order || !uid) return false;
  if (order.offer_wave_open === true) return true;
  // Legacy orders without wave fields: allow (back-compat) until first scheduler tick.
  if (
    order.offer_wave_index == null &&
    !Array.isArray(order.offer_wave_uids) &&
    !Array.isArray(order.offer_ranked_uids)
  ) {
    return true;
  }
  const wave = Array.isArray(order.offer_wave_uids) ? order.offer_wave_uids : [];
  if (wave.includes(uid)) return true;
  // Cumulative: already-notified prior waves may still accept until someone wins
  // (closer drivers keep eligibility; farther never get early visibility).
  const notified = Array.isArray(order.offer_notified_uids)
    ? order.offer_notified_uids
    : [];
  return notified.includes(uid);
}

exports.isUidInCurrentOfferWave = isUidInCurrentOfferWave;
exports.COHORT_SIZE = COHORT_SIZE;
exports.OFFER_WINDOW_MS = OFFER_WINDOW_MS;
exports.GPS_MAX_AGE_MS = GPS_MAX_AGE_MS;

exports.onOrderCreatedOfferWave = functions
  .region("us-central1")
  .firestore.document("order/{orderId}")
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    if (!isAssignablePending(data)) return null;
    const firestore = admin.firestore();
    try {
      await ensureWaveForOrder(firestore, snap, Date.now());
    } catch (e) {
      console.error("onOrderCreatedOfferWave", snap.id, e && e.message);
    }
    return null;
  });

exports.expandOrderOfferWaves = functions
  .region("us-central1")
  .pubsub.schedule("every 1 minutes")
  .timeZone("Asia/Riyadh")
  .onRun(async () => {
    const firestore = admin.firestore();
    const nowMs = Date.now();
    // Sub-minute expansion: also process docs whose wave_until already passed.
    const pending = await firestore
      .collection("order")
      .where("status_code", "==", "pending_driver")
      .where("ALLNOW", "==", true)
      .limit(80)
      .get();

    let expanded = 0;
    for (const doc of pending.docs) {
      try {
        const result = await ensureWaveForOrder(firestore, doc, nowMs);
        if (result && (result.waveUids || result.open)) expanded += 1;
      } catch (e) {
        console.error("expandOrderOfferWaves", doc.id, e && e.message);
      }
    }
    // Second pass every ~30s via finer schedule would need Cloud Scheduler
    // HTTP; 1-minute + onCreate covers first wave immediately. For 30s
    // cohort timing, tick docs whose until passed even mid-minute:
    const due = pending.docs.filter((d) => {
      const o = d.data() || {};
      if (o.offer_wave_open) return false;
      const until = o.offer_wave_until;
      if (!until || typeof until.toMillis !== "function") return true;
      return until.toMillis() <= nowMs;
    });
    for (const doc of due) {
      try {
        await ensureWaveForOrder(firestore, doc, nowMs);
      } catch (_) {}
    }
    console.log(JSON.stringify({ tag: "expandOrderOfferWaves", expanded, scanned: pending.size }));
    return null;
  });

/** Callable for QA / forced refresh of waves on a single order. */
exports.refreshOrderOfferWave = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
    }
    const orderId = String((data && data.orderId) || "").trim();
    if (!orderId) {
      throw new functions.https.HttpsError("invalid-argument", "orderId required");
    }
    const firestore = admin.firestore();
    const ref = firestore.collection("order").doc(orderId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "BOOKING_NOT_FOUND");
    }
    const result = await ensureWaveForOrder(firestore, snap, Date.now());
    return { ok: true, result };
  });
