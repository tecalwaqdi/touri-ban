/**
 * Batch seed via Firestore REST commit (fewer API calls).
 * Run: node seed_production_batch.js
 */

const fs = require("fs");
const path = require("path");

const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const BATCH_SIZE = 80;

const DATA = JSON.parse(
  fs.readFileSync(path.join(__dirname, "production_seed_data.json"), "utf8"),
);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function authRequest(endpoint, body) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${API_KEY}`,
    { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message);
  return json;
}

async function getIdToken() {
  try {
    const j = await authRequest("signInWithPassword", {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return j.idToken;
  } catch (e) {
    const j = await authRequest("signUp", {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return j.idToken;
  }
}

function fv(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (typeof val === "string") return { stringValue: val };
  if (typeof val === "boolean") return { booleanValue: val };
  if (typeof val === "number") {
    return Number.isInteger(val)
      ? { integerValue: String(val) }
      : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(fv) } };
  }
  if (val._ref) {
    return {
      referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${val._ref}`,
    };
  }
  if (val._geo) {
    return { geoPointValue: { latitude: val._geo[0], longitude: val._geo[1] } };
  }
  const fields = {};
  for (const [k, v] of Object.entries(val)) fields[k] = fv(v);
  return { mapValue: { fields } };
}

function docPath(collection, id) {
  return `${collection}/${id}`;
}

function docName(collection, id) {
  return `projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${id}`;
}

function ref(collection, id) {
  return { _ref: docPath(collection, id) };
}

function buildWrites(entries) {
  return entries.map(({ collection, id, data }) => ({
    update: {
      name: docName(collection, id),
      fields: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, fv(v)]),
      ),
    },
    updateMask: { fieldPaths: [] },
    currentDocument: { exists: false },
  }));
}

async function commitBatch(idToken, writes, retries = 6) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:commit`;
  for (let attempt = 0; attempt <= retries; attempt++) {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${idToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ writes }),
    });
    if (res.ok) return;
    const text = await res.text();
    if (res.status === 429 && attempt < retries) {
      const wait = 3000 * (attempt + 1);
      console.log(`  quota wait ${wait}ms...`);
      await sleep(wait);
      continue;
    }
    throw new Error(`commit failed ${res.status}: ${text}`);
  }
}

async function flush(idToken, queue, label) {
  if (!queue.length) return;
  for (let i = 0; i < queue.length; i += BATCH_SIZE) {
    const chunk = queue.slice(i, i + BATCH_SIZE);
    await commitBatch(idToken, buildWrites(chunk));
    console.log(`  ${label}: ${Math.min(i + BATCH_SIZE, queue.length)}/${queue.length}`);
    await sleep(1200);
  }
  queue.length = 0;
}

async function main() {
  console.log("=== تعبئة دفعية ===");
  const idToken = await getIdToken();
  console.log("Auth OK");

  const queue = [];
  const countryId = DATA.countryId;

  queue.push({
    collection: "countries",
    id: countryId,
    data: {
      naim: DATA.countryName,
      osf: DATA.countryDesc,
      acctev: true,
      saudi: true,
      vat_percent: 15,
      app_commission_percent: 12,
      num_trteb: 1,
    },
  });

  const regionIds = {};
  const cityIds = {};
  for (const region of DATA.regions) {
    regionIds[region.id] = region.id;
    queue.push({
      collection: "cities",
      id: region.id,
      data: { naim: region.name, dolh: ref("countries", countryId), acctev: true },
    });
    for (const city of region.cities) {
      cityIds[city.id] = city.id;
      queue.push({
        collection: "villages",
        id: city.id,
        data: {
          naim: city.name,
          cities: ref("cities", region.id),
          dolh: ref("countries", countryId),
          acctev: true,
        },
      });
    }
  }

  for (const [id, name, sr] of [
    ["type_sedan", "سيدان", 1],
    ["type_suv", "دفع رباعي", 2],
    ["type_van", "فان عائلي", 3],
    ["type_bus", "حافلة سياحية", 4],
  ]) {
    queue.push({ collection: "type_car", id, data: { naim: name, sr, acctev: true } });
  }

  for (const [id, name] of [
    ["cat_heritage", "تراث وثقافة"],
    ["cat_nature", "طبيعة ومغامرات"],
    ["cat_religious", "مواقع دينية"],
    ["cat_modern", "معالم حديثة"],
  ]) {
    queue.push({ collection: "Classification", id, data: { naim: name, acctev: true } });
  }

  console.log("Writing geo...");
  await flush(idToken, queue, "geo");

  const mkanIds = {};
  for (const lm of DATA.landmarks) {
    if (!regionIds[lm.regionId] || !cityIds[lm.cityId]) continue;
    mkanIds[lm.id] = lm.id;
    const addedAt = new Date();
    addedAt.setDate(addedAt.getDate() - (lm.daysAgo ?? 180));
    const data = {
      naim: lm.name,
      osf: lm.description,
      img1: lm.img1,
      img2: lm.img2 || "",
      img3: lm.img3 || "",
      sr: lm.sortOrder,
      ismsgd: !!lm.isMosque,
      isfood: lm.isFood !== false,
      ishmam: lm.isRestroom !== false,
      acctev: true,
      id_cit: ref("cities", lm.regionId),
      id_vill: ref("villages", lm.cityId),
      Rev_dolh: ref("countries", countryId),
      Location: { _geo: [lm.lat, lm.lng] },
      address: lm.address,
      mdh: lm.phone || "+966112345678",
      as_ads: true,
      ismzod: true,
      isShrek: !!lm.isPartner,
      tsnef: lm.category || "معلم سياحي",
      rate: lm.rate ?? 4.6,
      add_saat: 2,
      dataAdd: addedAt,
    };
    if (lm.isPartner) data.EmailUser = `partner.${lm.id}@arawatan.sa`;
    queue.push({ collection: "mkan", id: lm.id, data });
  }
  console.log("Writing landmarks...");
  await flush(idToken, queue, "landmarks");

  const rng = DATA.landmarks.length;
  const baseNow = Date.now();
  for (let monthOffset = 11; monthOffset >= 0; monthOffset--) {
    for (let i = 0; i < 8; i++) {
      const lm = DATA.landmarks[(monthOffset * 3 + i) % rng];
      if (!mkanIds[lm.id]) continue;
      const orderDate = new Date(baseNow - (monthOffset * 28 + i * 4 + 3) * 86400000);
      const total = 450 + monthOffset * 37 + i * 125;
      const isPaid = (monthOffset + i) % 4 !== 0;
      const isCanceled = !isPaid && i === 4;
      const orderId = `order_${orderDate.getFullYear()}${String(orderDate.getMonth() + 1).padStart(2, "0")}_${String(monthOffset * 8 + i + 1).padStart(3, "0")}`;
      const data = {
        total,
        total_app: Math.round(total * 0.12),
        total_vat: Math.round(total * 0.15),
        ALLNOW: !isCanceled && !isPaid,
        Rev_dolh: ref("countries", countryId),
        data_order: orderDate,
        IDorder: `ARW-${orderDate.getFullYear()}${String(orderDate.getMonth() + 1).padStart(2, "0")}-${String(monthOffset * 8 + i + 1).padStart(4, "0")}`,
        naim_user_text: DATA.customerNames[(monthOffset + i) % DATA.customerNames.length],
        halh_order: isCanceled ? "Canceled" : isPaid ? "Paid" : "Pending",
        halh: isCanceled ? "canceled" : isPaid ? "paid" : "pending",
        cartext: lm.name,
        listAmakn: [{ naim: lm.name, mkanRev: [ref("mkan", lm.id)], sr: total }],
      };
      if (lm.isPartner) data.partner_mkans = [ref("mkan", lm.id)];
      queue.push({ collection: "order", id: orderId, data });
    }
  }
  console.log("Writing orders...");
  await flush(idToken, queue, "orders");

  const tickets = [
    "استفسار عن حجز معلم",
    "تأخر وصول المندوب",
    "طلب تعديل موعد",
    "مشكلة في الدفع",
    "اقتراح إضافة معلم",
  ];
  tickets.forEach((subject, t) => {
    const d = new Date();
    d.setDate(d.getDate() - 30 * (t + 1));
    queue.push({
      collection: "support",
      id: `support_${t + 1}`,
      data: {
        id: t + 1,
        naim: subject,
        osf: `تذكرة دعم رقم ${t + 1}`,
        Rev_dolh: ref("countries", countryId),
        data: d,
        halh: t % 2 === 0 ? "Open" : "Closed",
      },
    });
  });
  await flush(idToken, queue, "support");

  console.log("\n=== تم ===");
  console.log(`معالم: ${DATA.landmarks.length}`);
}

main().catch((e) => {
  console.error("فشل:", e.message);
  process.exit(1);
});
