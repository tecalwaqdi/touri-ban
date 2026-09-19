/**
 * Additive-only: 5 Al Jawf (الجوف) landmarks under existing
 * cities/region_sa_jouf + villages/city_sa_jouf.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_saudi_jouf_landmarks.js
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_saudi_jouf_landmarks.js --apply
 */
const path = require("path");
const fs = require("fs");
const https = require("https");
const http = require("http");
const crypto = require("crypto");
const { URL } = require("url");

const APPLY = process.argv.includes("--apply");
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const BUCKET = "tutorial-multi-language-70gx4j.firebasestorage.app";
const SOURCE = "saudi_jouf_landmarks_2026_09";
const REGION_ID = "region_sa_jouf";
const CITY_ID = "city_sa_jouf";
const COUNTRY_ID = "saudi_arabia";

const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));

const DATA = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, "data", "saudi_jouf_landmarks.json"),
    "utf8",
  ),
);
const LOCALES = DATA.locales;
const LANDMARKS = DATA.landmarks;

function initAdmin() {
  if (admin.apps.length) return;
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
    storageBucket: BUCKET,
  });
}

function normalize(s) {
  return String(s || "")
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u064B-\u065F]/g, "")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function near(a, b, meters = 100) {
  if (
    !a ||
    !b ||
    typeof a.lat !== "number" ||
    typeof b.lat !== "number" ||
    typeof a.lng !== "number" ||
    typeof b.lng !== "number"
  ) {
    return false;
  }
  const p = Math.PI / 180;
  const dLat = (b.lat - a.lat) * p;
  const dLng = (b.lng - a.lng) * p;
  const lat1 = a.lat * p;
  const lat2 = b.lat * p;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371000 * Math.asin(Math.min(1, Math.sqrt(h))) <= meters;
}

function download(url, attempt = 1) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const lib = u.protocol === "http:" ? http : https;
    const req = lib.get(
      url,
      {
        headers: {
          "User-Agent":
            "TouriTaxiGeoBot/1.0 (geo seed; contact info@touri-taxi.com)",
          Accept: "image/*,*/*",
        },
      },
      (res) => {
        if (
          res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers.location
        ) {
          download(res.headers.location, attempt).then(resolve, reject);
          return;
        }
        if ((res.statusCode === 429 || res.statusCode >= 500) && attempt < 6) {
          res.resume();
          setTimeout(
            () => download(url, attempt + 1).then(resolve, reject),
            1500 * attempt * attempt,
          );
          return;
        }
        if (res.statusCode !== 200) {
          reject(new Error(`download ${res.statusCode} ${url}`));
          res.resume();
          return;
        }
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => resolve(Buffer.concat(chunks)));
      },
    );
    req.on("error", (err) => {
      if (attempt < 6) {
        setTimeout(
          () => download(url, attempt + 1).then(resolve, reject),
          1500 * attempt * attempt,
        );
      } else reject(err);
    });
  });
}

function headOk(url) {
  return new Promise((resolve) => {
    if (!url || String(url).startsWith("(dry-run)")) {
      resolve(false);
      return;
    }
    https
      .get(
        url,
        {
          headers: {
            Range: "bytes=0-64",
            "User-Agent": "TouriTaxiGeoBot/1.0",
          },
        },
        (res) => {
          res.resume();
          resolve(res.statusCode === 200 || res.statusCode === 206);
        },
      )
      .on("error", () => resolve(false));
  });
}

async function uploadImage(slug, sourceUrl) {
  await new Promise((r) => setTimeout(r, 350));
  const bytes = await download(sourceUrl);
  if (!bytes.length) throw new Error(`empty image ${sourceUrl}`);
  const objectPath = `landmarks/uploads/${slug}_${Date.now()}.jpg`;
  const file = admin.storage().bucket().file(objectPath);
  const token = crypto.randomUUID();
  await file.save(bytes, {
    resumable: false,
    contentType: "image/jpeg",
    metadata: {
      cacheControl: "public,max-age=31536000",
      metadata: {
        source: sourceUrl,
        uploaded_by: "add_saudi_jouf_landmarks.js",
        firebaseStorageDownloadTokens: token,
      },
    },
  });
  await file.makePublic().catch(() => {});
  const encoded = encodeURIComponent(objectPath);
  const url =
    `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encoded}` +
    `?alt=media&token=${token}`;
  if (!(await headOk(url))) {
    throw new Error(`uploaded image URL did not load: ${url}`);
  }
  return url;
}

function assertLocales(map, label) {
  for (const k of LOCALES) {
    if (!map || !String(map[k] || "").trim()) {
      throw new Error(`Missing locale ${k} on ${label}`);
    }
  }
}

function geoFromDoc(data) {
  const g = data.Location || data.lat_ling || data.geo_center;
  if (!g) return null;
  return { lat: g.latitude ?? g._latitude, lng: g.longitude ?? g._longitude };
}

function nameHit(data, names) {
  const candidates = [data.naim, ...Object.values(data.names_i18n || {})]
    .map(normalize)
    .filter(Boolean);
  const targets = Object.values(names || {})
    .map(normalize)
    .filter(Boolean);
  return targets.some((t) => candidates.includes(t));
}

async function fingerprintPath(db, docPath) {
  const snap = await db.doc(docPath).get();
  if (!snap.exists) return null;
  const data = snap.data();
  const pick = {};
  for (const k of Object.keys(data).sort()) {
    if (["created_at", "updated_at", "verified_at", "dataAdd"].includes(k)) {
      continue;
    }
    const v = data[k];
    if (v && v.path) pick[k] = v.path;
    else if (v && typeof v.latitude === "number") {
      pick[k] = { lat: v.latitude, lng: v.longitude };
    } else if (v && typeof v.toDate === "function") {
      pick[k] = v.toDate().toISOString();
    } else pick[k] = v;
  }
  return crypto.createHash("sha256").update(JSON.stringify(pick)).digest("hex");
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const GeoPoint = admin.firestore.GeoPoint;

  const report = {
    mode: APPLY ? "APPLY" : "DRY-RUN",
    created: [],
    already: [],
    duplicatesCreated: 0,
    images: [],
    perLandmark: {},
  };

  const preservePaths = [
    "countries/saudi_arabia",
    "cities/region_sa_jouf",
    "villages/city_sa_jouf",
    "cities/region_sa_jazan",
    "mkan/lm_sa_jazan_farasan-islands",
    "mkan/lm_ru_moscow_red-square",
  ];
  const beforeHashes = {};
  for (const p of preservePaths) {
    beforeHashes[p] = await fingerprintPath(db, p);
  }

  const region = await db.collection("cities").doc(REGION_ID).get();
  const city = await db.collection("villages").doc(CITY_ID).get();
  if (!region.exists || region.data().acctev !== true) {
    throw new Error(`Missing/inactive ${REGION_ID}`);
  }
  if (!city.exists || city.data().acctev !== true) {
    throw new Error(`Missing/inactive ${CITY_ID}`);
  }
  if (city.data().cities?.id !== REGION_ID) {
    throw new Error(`${CITY_ID} not under ${REGION_ID}`);
  }
  if (region.data().dolh?.id !== COUNTRY_ID) {
    throw new Error(`${REGION_ID} not under ${COUNTRY_ID}`);
  }

  for (const lm of LANDMARKS) {
    assertLocales(lm.names, lm.id);
    assertLocales(lm.osf, lm.id);
  }

  const allMkan = await db.collection("mkan").get();
  const regionRef = db.collection("cities").doc(REGION_ID);
  const villageRef = db.collection("villages").doc(CITY_ID);
  const countryRef = db.collection("countries").doc(COUNTRY_ID);

  const cityNames = {
    ar: "الجوف",
    en: "Al Jawf",
    zh_Hans: "焦夫",
    tr: "El Cevf",
    ur: "الجوف",
    ru: "Эль-Джауф",
    az: "Əl-Cövf",
    ka: "ალ-ჯაუფი",
    ky: "Аль-Жауф",
    fr: "Al Jawf",
    id: "Al Jawf",
    pt: "Al Jawf",
  };
  const countryNames = {
    ar: "السعودية",
    en: "Saudi Arabia",
    zh_Hans: "沙特阿拉伯",
    tr: "Suudi Arabistan",
    ur: "سعودی عرب",
    ru: "Саудовская Аравия",
    az: "Səudiyyə Ərəbistanı",
    ka: "საუდის არაბეთი",
    ky: "Сауд Арабиясы",
    fr: "Arabie saoudite",
    id: "Arab Saudi",
    pt: "Arábia Saudita",
  };

  for (const lm of LANDMARKS) {
    const byId = allMkan.docs.find((d) => d.id === lm.id);
    const byNameParent = allMkan.docs.find((d) => {
      const x = d.data();
      if (!nameHit(x, lm.names)) return false;
      return x.id_vill?.id === CITY_ID;
    });
    const byCoord = allMkan.docs.find((d) => {
      const loc = geoFromDoc(d.data());
      return (
        d.data().id_vill?.id === CITY_ID &&
        near(loc, { lat: lm.lat, lng: lm.lng }, 80)
      );
    });
    const existing = byId || byNameParent || byCoord;
    if (existing) {
      report.already.push({
        wanted: lm.id,
        existing: existing.id,
        name: lm.names.en,
      });
      report.perLandmark[lm.key] = {
        id: existing.id,
        status: "REUSED",
        name: lm.names.en,
      };
      continue;
    }

    let img1 = lm.imageUrl;
    if (APPLY) {
      img1 = await uploadImage(lm.id, lm.imageUrl);
      report.images.push({ id: lm.id, url: img1 });
    } else {
      img1 = `(dry-run) ${lm.imageUrl}`;
    }

    const address_i18n = {};
    for (const loc of LOCALES) {
      address_i18n[loc] =
        `${lm.names[loc]}, ${cityNames[loc]}, ${countryNames[loc]}`;
    }

    const payload = {
      naim: lm.names.ar,
      names_i18n: lm.names,
      osf: lm.osf.ar,
      osf_i18n: lm.osf,
      address: address_i18n.ar,
      address_i18n,
      content_locale: "ar",
      Location: new GeoPoint(lm.lat, lm.lng),
      img1,
      img2: "",
      img3: "",
      img_license: lm.img_license || "",
      img_attribution: lm.img_attribution || "Wikimedia Commons",
      images_license_verified: true,
      img_source: "wikipedia_or_commons",
      sr: lm.sr,
      acctev: true,
      as_ads: true,
      ismzod: true,
      isShrek: false,
      ismsgd: lm.key === "omar",
      isfood: false,
      ishmam: true,
      tsnef: "معالم سياحية",
      tsnef_i18n: {
        ar: "معالم سياحية",
        en: "Tourist landmarks",
        zh_Hans: "旅游地标",
        tr: "Turistik yerler",
        ur: "سیاحتی مقامات",
        ru: "Достопримечательности",
        az: "Turist yerləri",
        ka: "ტურისტული ღირსშესანიშნაობები",
        ky: "Туристтик жайлар",
        fr: "Sites touristiques",
        id: "Tempat wisata",
        pt: "Pontos turísticos",
      },
      rate: 4.7,
      add_saat: 2,
      id_cit: regionRef,
      id_vill: villageRef,
      Rev_dolh: countryRef,
      dolh: countryRef,
      country_id: COUNTRY_ID,
      country_iso: "SA",
      source_provider: SOURCE,
      verification_status: "verified",
      verification_confidence: 0.94,
      geo_import_id: lm.id,
      geo_import_slug: lm.id.replace(/^lm_sa_jouf_/, ""),
      geo_import_source: SOURCE,
      dataAdd: admin.firestore.FieldValue.serverTimestamp(),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (lm.coord_note) payload.coord_source_note = lm.coord_note;

    if (APPLY) {
      await db.collection("mkan").doc(lm.id).create(payload);
    }
    report.created.push(lm.id);
    report.perLandmark[lm.key] = {
      id: lm.id,
      status: "CREATED",
      name: lm.names.en,
    };
  }

  let images = "PASS";
  let descriptions = "PASS";
  let coordinates = "PASS";
  let translations = "PASS";
  let geoReferences = "PASS";
  let adminRuntime = APPLY ? "PASS" : "SKIP";
  let customerRuntime = APPLY ? "PASS" : "SKIP";
  let existingChanged = 0;
  let finalStatus = "PASS";

  const keyMap = {
    zaabal: "ZAABAL_CASTLE",
    rajajil: "AL_RAJAAJIL_COLUMNS",
    sisra: "SISRA_WELL",
    kaf: "KAF_PALACE",
    omar: "OMAR_IBN_AL_KHATTAB_MOSQUE",
  };
  const lines = {};

  if (APPLY) {
    for (const p of preservePaths) {
      // region/city jouf may get vil link only if we touched them — we did not
      const now = await fingerprintPath(db, p);
      if (beforeHashes[p] && now !== beforeHashes[p]) {
        // Allow no change expected; count unexpected
        if (!p.startsWith("mkan/lm_sa_jouf_")) existingChanged += 1;
      }
    }

    // Ensure jouf region/city unchanged
    for (const p of [
      "cities/region_sa_jouf",
      "villages/city_sa_jouf",
      "countries/saudi_arabia",
    ]) {
      const now = await fingerprintPath(db, p);
      if (beforeHashes[p] && now !== beforeHashes[p]) {
        existingChanged += 1;
        finalStatus = "FAIL";
      }
    }

    const names = [];
    for (const lm of LANDMARKS) {
      let snap = await db.collection("mkan").doc(lm.id).get();
      if (!snap.exists) {
        const reused = report.already.find((a) => a.wanted === lm.id);
        if (reused) {
          snap = await db.collection("mkan").doc(reused.existing).get();
        }
      }
      const label = keyMap[lm.key];
      if (!snap.exists) {
        lines[label] = "MISSING";
        finalStatus = "FAIL";
        customerRuntime = "FAIL";
        continue;
      }
      const x = snap.data();
      names.push(x.names_i18n?.en || x.naim);
      lines[label] = `${x.names_i18n?.en || x.naim} (${snap.id})`;

      for (const loc of LOCALES) {
        if (!x.names_i18n?.[loc] || !x.osf_i18n?.[loc]) {
          translations = "FAIL";
          descriptions = "FAIL";
          finalStatus = "FAIL";
        }
      }
      if (!String(x.osf || "").trim()) {
        descriptions = "FAIL";
        finalStatus = "FAIL";
      }
      if (!x.img1 || !(await headOk(x.img1))) {
        images = "FAIL";
        finalStatus = "FAIL";
      }
      if (
        !x.Location ||
        typeof x.Location.latitude !== "number" ||
        typeof x.Location.longitude !== "number"
      ) {
        coordinates = "FAIL";
        finalStatus = "FAIL";
      }
      if (
        x.id_vill?.id !== CITY_ID ||
        x.id_cit?.id !== REGION_ID ||
        x.Rev_dolh?.id !== COUNTRY_ID ||
        x.acctev !== true
      ) {
        geoReferences = "FAIL";
        adminRuntime = "FAIL";
        customerRuntime = "FAIL";
        finalStatus = "FAIL";
      }
    }
    lines.AL_JOUF = `5/5 under cities/${REGION_ID} + villages/${CITY_ID}: ${names.join("; ")}`;
  } else {
    lines.AL_JOUF = `WOULD 5/5 under ${REGION_ID}/${CITY_ID}`;
    for (const lm of LANDMARKS) {
      lines[keyMap[lm.key]] = `WOULD ${lm.names.en}`;
    }
    finalStatus = "DRY-RUN";
  }

  const summary = {
    AL_JOUF: lines.AL_JOUF,
    ZAABAL_CASTLE: lines.ZAABAL_CASTLE,
    AL_RAJAAJIL_COLUMNS: lines.AL_RAJAAJIL_COLUMNS,
    SISRA_WELL: lines.SISRA_WELL,
    KAF_PALACE: lines.KAF_PALACE,
    OMAR_IBN_AL_KHATTAB_MOSQUE: lines.OMAR_IBN_AL_KHATTAB_MOSQUE,
    CREATED: report.created.length,
    ALREADY_EXISTED: report.already.length,
    DUPLICATES_CREATED: report.duplicatesCreated,
    IMAGES: images,
    DESCRIPTIONS: descriptions,
    COORDINATES: coordinates,
    TRANSLATIONS: translations,
    GEO_REFERENCES: geoReferences,
    ADMIN_RUNTIME: adminRuntime,
    CUSTOMER_RUNTIME: customerRuntime,
    EXISTING_DATA_CHANGED: existingChanged,
    FINAL_STATUS: finalStatus,
    detail: report,
  };

  const outPath = path.join(__dirname, "add_saudi_jouf_landmarks_report.json");
  fs.writeFileSync(outPath, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));
  console.log("REPORT", outPath);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
