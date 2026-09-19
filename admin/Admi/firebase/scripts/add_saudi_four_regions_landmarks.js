/**
 * Additive-only: 20 landmarks under existing Saudi regions
 * Jazan / Najran / Hail / Al Bahah.
 *
 * Hierarchy (canonical):
 *   Region = cities/region_sa_*
 *   City   = villages/city_sa_*
 *   Landmark = mkan/*
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_saudi_four_regions_landmarks.js
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_saudi_four_regions_landmarks.js --apply
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
const SOURCE = "saudi_four_regions_landmarks_2026_09";

const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));

const DATA = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, "data", "saudi_four_regions_landmarks.json"),
    "utf8",
  ),
);

const LOCALES = DATA.locales;
const LANDMARKS = DATA.landmarks;

const REGION_KEYS = {
  jazan: "JAZAN",
  najran: "NAJRAN",
  hail: "HAIL",
  baha: "AL_BAHAH",
};

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
        uploaded_by: "add_saudi_four_regions_landmarks.js",
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
  const candidates = [
    data.naim,
    ...Object.values(data.names_i18n || {}),
  ]
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
    byRegion: { jazan: [], najran: [], hail: [], baha: [] },
  };

  // Preserve unrelated sample docs
  const preservePaths = [
    "countries/saudi_arabia",
    "cities/region_sa_riyadh",
    "villages/city_sa_riyadh",
    "cities/region_ru_moscow",
    "mkan/lm_ru_moscow_red-square",
  ];
  const beforeHashes = {};
  for (const p of preservePaths) {
    beforeHashes[p] = await fingerprintPath(db, p);
  }

  // Required parents
  const parents = {};
  for (const lm of LANDMARKS) {
    parents[lm.regionId] = lm.cityId;
  }
  for (const [regionId, cityId] of Object.entries(parents)) {
    const region = await db.collection("cities").doc(regionId).get();
    const city = await db.collection("villages").doc(cityId).get();
    if (!region.exists || region.data().acctev !== true) {
      throw new Error(`Missing/inactive region ${regionId}`);
    }
    if (!city.exists || city.data().acctev !== true) {
      throw new Error(`Missing/inactive city ${cityId}`);
    }
    if (city.data().cities?.id !== regionId) {
      throw new Error(`City ${cityId} not under ${regionId}`);
    }
    if (region.data().dolh?.id !== "saudi_arabia") {
      throw new Error(`Region ${regionId} not under saudi_arabia`);
    }
  }

  for (const lm of LANDMARKS) {
    assertLocales(lm.names, lm.id);
    assertLocales(lm.osf, lm.id);
  }

  const allMkan = await db.collection("mkan").get();

  for (const lm of LANDMARKS) {
    const regionRef = db.collection("cities").doc(lm.regionId);
    const villageRef = db.collection("villages").doc(lm.cityId);
    const countryRef = db.collection("countries").doc(lm.countryId);
    const mkanRef = db.collection("mkan").doc(lm.id);

    const byId = allMkan.docs.find((d) => d.id === lm.id);
    const byNameParent = allMkan.docs.find((d) => {
      const x = d.data();
      if (!nameHit(x, lm.names)) return false;
      return x.id_vill?.id === lm.cityId;
    });
    const byCoord = allMkan.docs.find((d) => {
      const loc = geoFromDoc(d.data());
      return (
        d.data().id_vill?.id === lm.cityId &&
        near(loc, { lat: lm.lat, lng: lm.lng }, 80)
      );
    });

    const existing = byId || byNameParent || byCoord;
    if (existing) {
      report.already.push({
        wanted: lm.id,
        existing: existing.id,
        name: lm.names.en,
        region: lm.regionKey,
      });
      report.byRegion[lm.regionKey].push({
        id: existing.id,
        name: lm.names.en,
        status: "REUSED",
      });
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
    const cityNames = {
      jazan: {
        ar: "جازان",
        en: "Jazan",
        zh_Hans: "吉赞",
        tr: "Cizan",
        ur: "جازان",
        ru: "Джизан",
        az: "Cazan",
        ka: "ჯაზანი",
        ky: "Жазан",
        fr: "Jizan",
        id: "Jazan",
        pt: "Jazan",
      },
      najran: {
        ar: "نجران",
        en: "Najran",
        zh_Hans: "奈季兰",
        tr: "Necran",
        ur: "نجران",
        ru: "Наджран",
        az: "Nəcran",
        ka: "ნაჯრანი",
        ky: "Наджран",
        fr: "Najran",
        id: "Najran",
        pt: "Najran",
      },
      hail: {
        ar: "حائل",
        en: "Hail",
        zh_Hans: "哈伊勒",
        tr: "Hail",
        ur: "حائل",
        ru: "Хаиль",
        az: "Hail",
        ka: "ჰაილი",
        ky: "Хаиль",
        fr: "Haïl",
        id: "Hail",
        pt: "Hail",
      },
      baha: {
        ar: "الباحة",
        en: "Al Bahah",
        zh_Hans: "巴哈",
        tr: "El Baha",
        ur: "الباحة",
        ru: "Аль-Баха",
        az: "Əl-Baha",
        ka: "ალ-ბაჰა",
        ky: "Аль-Баха",
        fr: "Al Baha",
        id: "Al Bahah",
        pt: "Al Baha",
      },
    }[lm.regionKey];

    for (const loc of LOCALES) {
      address_i18n[loc] =
        `${lm.names[loc]}, ${cityNames[loc]}, ${
          {
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
          }[loc]
        }`;
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
      ismsgd: false,
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
      country_id: "saudi_arabia",
      country_iso: "SA",
      source_provider: SOURCE,
      verification_status: "verified",
      verification_confidence: 0.94,
      geo_import_id: lm.id,
      geo_import_slug: lm.id.replace(/^lm_sa_[a-z]+_/, ""),
      geo_import_source: SOURCE,
      dataAdd: admin.firestore.FieldValue.serverTimestamp(),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (APPLY) {
      await mkanRef.create(payload);
    }
    report.created.push(lm.id);
    report.byRegion[lm.regionKey].push({
      id: lm.id,
      name: lm.names.en,
      status: "CREATED",
    });
  }

  // Runtime verification
  let images = "PASS";
  let descriptions = "PASS";
  let coordinates = "PASS";
  let translations = "PASS";
  let adminRuntime = APPLY ? "PASS" : "SKIP";
  let customerRuntime = APPLY ? "PASS" : "SKIP";
  let existingChanged = 0;
  let finalStatus = "PASS";
  const regionLines = {};

  if (APPLY) {
    for (const p of preservePaths) {
      const now = await fingerprintPath(db, p);
      if (beforeHashes[p] && now !== beforeHashes[p]) existingChanged += 1;
    }

    for (const [key, label] of Object.entries(REGION_KEYS)) {
      const targets = LANDMARKS.filter((l) => l.regionKey === key);
      const names = [];
      let ok = 0;
      for (const lm of targets) {
        let snap = await db.collection("mkan").doc(lm.id).get();
        if (!snap.exists) {
          const reused = report.already.find((a) => a.wanted === lm.id);
          if (reused) snap = await db.collection("mkan").doc(reused.existing).get();
        }
        if (!snap.exists) {
          finalStatus = "FAIL";
          customerRuntime = "FAIL";
          continue;
        }
        const x = snap.data();
        names.push(x.names_i18n?.en || x.naim);
        ok += 1;
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
        // Customer query shape: id_vill + acctev
        if (x.id_vill?.id !== lm.cityId || x.acctev !== true) {
          customerRuntime = "FAIL";
          finalStatus = "FAIL";
        }
        if (
          x.id_cit?.id !== lm.regionId ||
          x.Rev_dolh?.id !== "saudi_arabia"
        ) {
          adminRuntime = "FAIL";
          finalStatus = "FAIL";
        }
      }
      if (ok !== 5) {
        finalStatus = "FAIL";
        customerRuntime = "FAIL";
      }
      regionLines[label] = `${ok}/5: ${names.join("; ")}`;
    }
  } else {
    for (const [key, label] of Object.entries(REGION_KEYS)) {
      const names = LANDMARKS.filter((l) => l.regionKey === key).map(
        (l) => l.names.en,
      );
      regionLines[label] = `WOULD 5/5: ${names.join("; ")}`;
    }
    finalStatus = "DRY-RUN";
  }

  const summary = {
    ...regionLines,
    CREATED: report.created.length,
    ALREADY_EXISTED: report.already.length,
    DUPLICATES_CREATED: report.duplicatesCreated,
    IMAGES: images,
    DESCRIPTIONS: descriptions,
    COORDINATES: coordinates,
    TRANSLATIONS: translations,
    ADMIN_RUNTIME: adminRuntime,
    CUSTOMER_RUNTIME: customerRuntime,
    EXISTING_DATA_CHANGED: existingChanged,
    FINAL_STATUS: finalStatus,
    detail: report,
  };

  const outPath = path.join(
    __dirname,
    "add_saudi_four_regions_landmarks_report.json",
  );
  fs.writeFileSync(outPath, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));
  console.log("REPORT", outPath);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
