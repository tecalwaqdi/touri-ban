/**
 * Seeds production data via Firebase Client SDK + Auth REST (no Admin SDK).
 *
 * Safety:
 * - Requires SEED_ALLOW_PRODUCTION=1
 * - Requires SEED_FIREBASE_API_KEY, SEED_EMAIL, SEED_PASSWORD from env
 * - Does not embed live credentials in source
 *
 * Run: SEED_ALLOW_PRODUCTION=1 SEED_FIREBASE_API_KEY=... SEED_EMAIL=... SEED_PASSWORD=... node seed_production_client.js
 */

const fs = require("fs");
const path = require("path");

if (String(process.env.SEED_ALLOW_PRODUCTION || "") !== "1") {
  console.error(
    "Refusing to run: set SEED_ALLOW_PRODUCTION=1 after reviewing target project.",
  );
  process.exit(1);
}

const API_KEY = String(process.env.SEED_FIREBASE_API_KEY || "").trim();
const PROJECT_ID = String(
  process.env.SEED_PROJECT_ID || "tutorial-multi-language-70gx4j",
).trim();
const EMAIL = String(process.env.SEED_EMAIL || "").trim();
const PASSWORD = String(process.env.SEED_PASSWORD || "").trim();

if (!API_KEY || !EMAIL || !PASSWORD) {
  console.error(
    "Missing SEED_FIREBASE_API_KEY / SEED_EMAIL / SEED_PASSWORD environment variables.",
  );
  process.exit(1);
}

const DATA = JSON.parse(
  fs.readFileSync(path.join(__dirname, "production_seed_data.json"), "utf8"),
);

async function authRequest(endpoint, body) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
  );
  const json = await res.json();
  if (json.error) {
    const err = new Error(json.error.message);
    err.code = json.error.message;
    throw err;
  }
  return json;
}

async function getIdToken() {
  try {
    const json = await authRequest("signInWithPassword", {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return { idToken: json.idToken, uid: json.localId };
  } catch (e) {
    if (
      String(e.code).includes("EMAIL_NOT_FOUND") ||
      String(e.code).includes("INVALID_LOGIN_CREDENTIALS")
    ) {
      console.log("Creating seed auth user...");
      const json = await authRequest("signUp", {
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      });
      return { idToken: json.idToken, uid: json.localId };
    }
    throw e;
  }
}

function firestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (val instanceof Date) {
    return { timestampValue: val.toISOString() };
  }
  if (typeof val === "string") return { stringValue: val };
  if (typeof val === "boolean") return { booleanValue: val };
  if (typeof val === "number") {
    if (Number.isInteger(val)) return { integerValue: String(val) };
    return { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return {
      arrayValue: { values: val.map((v) => firestoreValue(v)) },
    };
  }
  if (val._type === "ref") {
    return {
      referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${val.path}`,
    };
  }
  if (val._type === "geo") {
    return {
      geoPointValue: { latitude: val.lat, longitude: val.lng },
    };
  }
  if (typeof val === "object") {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = firestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function ref(path) {
  return { _type: "ref", path };
}

function geo(lat, lng) {
  return { _type: "geo", lat, lng };
}

async function patchDoc(idToken, docPath, data, retries = 5) {
  const fields = {};
  const maskParams = [];
  for (const [k, v] of Object.entries(data)) {
    fields[k] = firestoreValue(v);
    // بدون updateMask يستبدل Firestore المستند بالكامل ويمسح باقي الحقول.
    maskParams.push(`updateMask.fieldPaths=${encodeURIComponent(k)}`);
  }
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}` +
    (maskParams.length ? `?${maskParams.join("&")}` : "");

  for (let attempt = 0; attempt <= retries; attempt++) {
    const res = await fetch(url, {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${idToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ fields }),
    });
    if (res.ok) return;

    const text = await res.text();
    if (res.status === 429 && attempt < retries) {
      const wait = 2000 * (attempt + 1);
      console.log(`  rate limit — wait ${wait}ms (${docPath})`);
      await sleep(wait);
      continue;
    }
    throw new Error(`PATCH ${docPath} failed: ${res.status} ${text}`);
  }
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function ensureSuperAdminUser(idToken, uid) {
  await patchDoc(idToken, `user/${uid}`, {
    email: EMAIL,
    display_name: "سوبر أدمن التعبئة",
    uid,
    actev_user: true,
    IsAdmin: true,
    isAdminRule: 1,
    created_time: new Date(),
  });
}

async function main() {
  console.log("=== تعبئة بيانات الإنتاج (Client SDK) ===");
  const { idToken, uid } = await getIdToken();
  console.log("Signed in:", EMAIL);
  await ensureSuperAdminUser(idToken, uid);

  const countryPath = `countries/${DATA.countryId}`;
  await patchDoc(idToken, countryPath, {
    naim: DATA.countryName,
    osf: DATA.countryDesc,
    acctev: true,
    saudi: true,
    vat_percent: 15,
    app_commission_percent: 12,
    num_trteb: 1,
  });

  const regionPaths = {};
  const cityPaths = {};
  let regionCount = 0;
  let cityCount = 0;

  for (const region of DATA.regions) {
    const regionPath = `cities/${region.id}`;
    regionPaths[region.id] = regionPath;
    await patchDoc(idToken, regionPath, {
      naim: region.name,
      dolh: ref(countryPath),
      acctev: true,
    });
    regionCount++;

    for (const city of region.cities) {
      const cityPath = `villages/${city.id}`;
      cityPaths[city.id] = cityPath;
      await patchDoc(idToken, cityPath, {
        naim: city.name,
        cities: ref(regionPath),
        dolh: ref(countryPath),
        acctev: true,
      });
      cityCount++;
    }
  }

  console.log(`Geo: ${regionCount} regions, ${cityCount} cities`);

  const vehicleTypes = [
    ["type_sedan", "سيدان", 1],
    ["type_suv", "دفع رباعي", 2],
    ["type_van", "فان عائلي", 3],
    ["type_bus", "حافلة سياحية", 4],
  ];
  for (const [id, name, sr] of vehicleTypes) {
    await patchDoc(idToken, `type_car/${id}`, {
      naim: name,
      sr,
      acctev: true,
    });
  }

  const categories = [
    ["cat_heritage", "تراث وثقافة"],
    ["cat_nature", "طبيعة ومغامرات"],
    ["cat_religious", "مواقع دينية"],
    ["cat_modern", "معالم حديثة"],
  ];
  for (const [id, name] of categories) {
    await patchDoc(idToken, `Classification/${id}`, {
      naim: name,
      acctev: true,
    });
  }

  const mkanPaths = {};
  let landmarkCount = 0;
  for (const lm of DATA.landmarks) {
    const regionPath = regionPaths[lm.regionId];
    const cityPath = cityPaths[lm.cityId];
    if (!regionPath || !cityPath) continue;

    const mkanPath = `mkan/${lm.id}`;
    mkanPaths[lm.id] = mkanPath;
    const addedAt = new Date();
    addedAt.setDate(addedAt.getDate() - (lm.daysAgo ?? 180));

    const doc = {
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
      id_cit: ref(regionPath),
      id_vill: ref(cityPath),
      Rev_dolh: ref(countryPath),
      Location: geo(lm.lat, lm.lng),
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
    if (lm.isPartner) {
      doc.EmailUser = `partner.${lm.id}@arawatan.sa`;
    }

    await patchDoc(idToken, mkanPath, doc);
    landmarkCount++;
    if (landmarkCount % 5 === 0) {
      console.log(`  landmarks: ${landmarkCount}/${DATA.landmarks.length}`);
      await sleep(500);
    }
  }

  let orderCount = 0;
  const rng = DATA.landmarks.length;
  const baseNow = Date.now();
  for (let monthOffset = 11; monthOffset >= 0; monthOffset--) {
    for (let i = 0; i < 8; i++) {
      const lm = DATA.landmarks[(monthOffset * 3 + i) % rng];
      const mkanPath = mkanPaths[lm.id];
      if (!mkanPath) continue;

      const orderDate = new Date(
        baseNow - (monthOffset * 28 + i * 4 + 3) * 86400000,
      );
      const total = 450 + monthOffset * 37 + i * 125;
      const isPaid = (monthOffset + i) % 4 !== 0;
      const isCanceled = !isPaid && i === 4;
      const halh = isCanceled ? "canceled" : isPaid ? "paid" : "pending";
      const halhOrder = isCanceled ? "Canceled" : isPaid ? "Paid" : "Pending";
      const orderId = `order_${orderDate.getFullYear()}${String(orderDate.getMonth() + 1).padStart(2, "0")}_${String(monthOffset * 8 + i + 1).padStart(3, "0")}`;

      const orderDoc = {
        total,
        total_app: Math.round(total * 0.12),
        total_vat: Math.round(total * 0.15),
        ALLNOW: !isCanceled && !isPaid,
        Rev_dolh: ref(countryPath),
        data_order: orderDate,
        IDorder: `ARW-${orderDate.getFullYear()}${String(orderDate.getMonth() + 1).padStart(2, "0")}-${String(monthOffset * 8 + i + 1).padStart(4, "0")}`,
        naim_user_text:
          DATA.customerNames[(monthOffset + i) % DATA.customerNames.length],
        halh_order: halhOrder,
        halh,
        cartext: lm.name,
        listAmakn: [
          {
            naim: lm.name,
            mkanRev: [ref(mkanPath)],
            sr: total,
          },
        ],
      };
      if (lm.isPartner) {
        orderDoc.partner_mkans = [ref(mkanPath)];
      }

      await patchDoc(idToken, `order/${orderId}`, orderDoc);
      orderCount++;
      if (orderCount % 10 === 0) await sleep(400);
    }
  }

  const tickets = [
    "استفسار عن حجز معلم",
    "تأخر وصول المندوب",
    "طلب تعديل موعد",
    "مشكلة في الدفع",
    "اقتراح إضافة معلم",
  ];
  for (let t = 0; t < tickets.length; t++) {
    const d = new Date();
    d.setDate(d.getDate() - 30 * (t + 1));
    await patchDoc(idToken, `support/support_${t + 1}`, {
      id: t + 1,
      naim: tickets[t],
      osf: `تذكرة دعم رقم ${t + 1} — تم فتحها ضمن بيانات النظام التشغيلية.`,
      Rev_dolh: ref(countryPath),
      data: d,
      halh: t % 2 === 0 ? "Open" : "Closed",
    });
  }

  console.log("\n=== تمت التعبئة بنجاح ===");
  console.log(`معالم: ${landmarkCount}`);
  console.log(`حجوزات: ${orderCount}`);
  console.log(`مناطق: ${regionCount} | مدن: ${cityCount}`);
  console.log(`تذاكر دعم: ${tickets.length}`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error("فشل:", e.message || e);
    process.exit(1);
  });
}

module.exports = {
  getIdToken,
  patchDoc,
  ref,
  geo,
  sleep,
};
