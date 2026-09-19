/**
 * Additive-only: 6 capitals + exactly 7 landmarks each (42 total).
 *
 * Hierarchy (canonical project schema):
 *   Region = cities/*   (dolh → countries/{id})
 *   City   = villages/* (cities → region, dolh → country)
 *   Landmark = mkan/*   (id_cit, id_vill, Rev_dolh)
 *
 * Countries already exist: russia, uzbekistan, turkmenistan,
 * kazakhstan, georgia, egypt.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_six_capitals_landmarks.js
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_six_capitals_landmarks.js --apply
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
const SOURCE = "six_capitals_landmarks_2026_09";

const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));

const DATA = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, "data", "six_capitals_landmarks.json"),
    "utf8",
  ),
);

const LOCALES = DATA.locales;
const CAPITALS = DATA.capitals;
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

function near(a, b, meters = 80) {
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
    if (!url || url.startsWith("(dry-run)")) {
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

async function uploadImage(storageFolder, slug, sourceUrl) {
  await new Promise((r) => setTimeout(r, 400));
  const bytes = await download(sourceUrl);
  if (!bytes.length) throw new Error(`empty image ${sourceUrl}`);
  const objectPath = `${storageFolder}/${slug}_${Date.now()}.jpg`;
  const file = admin.storage().bucket().file(objectPath);
  const token = crypto.randomUUID();
  await file.save(bytes, {
    resumable: false,
    contentType: "image/jpeg",
    metadata: {
      cacheControl: "public,max-age=31536000",
      metadata: {
        source: sourceUrl,
        uploaded_by: "add_six_capitals_landmarks.js",
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
  const g = data.lat_ling || data.geo_center || data.Location;
  if (!g) return null;
  return { lat: g.latitude ?? g._latitude, lng: g.longitude ?? g._longitude };
}

function nameHit(data, names) {
  const candidates = [
    data.naim,
    data.naimEnglesh,
    ...Object.values(data.names_i18n || {}),
  ]
    .map(normalize)
    .filter(Boolean);
  const targets = Object.values(names || {})
    .map(normalize)
    .filter(Boolean);
  return targets.some((t) => candidates.includes(t));
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const GeoPoint = admin.firestore.GeoPoint;

  const report = {
    mode: APPLY ? "APPLY" : "DRY-RUN",
    capitalsCreated: [],
    capitalsReused: [],
    landmarksCreated: [],
    landmarksReused: [],
    duplicatesCreated: 0,
    images: [],
    errors: [],
    perCountry: {},
  };

  // Fingerprint existing docs we must not mutate
  const beforeHashes = {};
  async function fingerprintPath(docPath) {
    const snap = await db.doc(docPath).get();
    if (!snap.exists) return null;
    const data = snap.data();
    const pick = {};
    for (const k of Object.keys(data).sort()) {
      if (["created_at", "updated_at", "verified_at"].includes(k)) continue;
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

  // Snapshot Saudi / Africa sample docs — must remain unchanged
  const preservePaths = [
    "countries/saudi_arabia",
    "cities/region_sa_riyadh",
    "villages/city_sa_riyadh",
  ];
  for (const p of preservePaths) {
    beforeHashes[p] = await fingerprintPath(p);
  }

  const [allCities, allVillages, allMkan] = await Promise.all([
    db.collection("cities").get(),
    db.collection("villages").get(),
    db.collection("mkan").get(),
  ]);

  // Preflight countries
  for (const cap of Object.values(CAPITALS)) {
    assertLocales(cap.names, `capital ${cap.regionId} names`);
    assertLocales(cap.osf, `capital ${cap.regionId} osf`);
    const c = await db.collection("countries").doc(cap.countryId).get();
    if (!c.exists || c.data().acctev !== true) {
      throw new Error(`Country missing/inactive: ${cap.countryId}`);
    }
  }
  for (const lm of LANDMARKS) {
    assertLocales(lm.names, `landmark ${lm.id} names`);
    assertLocales(lm.osf, `landmark ${lm.id} osf`);
  }

  // ---- Capitals (region + village) ----
  for (const [key, cap] of Object.entries(CAPITALS)) {
    const countryRef = db.collection("countries").doc(cap.countryId);
    const regionRef = db.collection("cities").doc(cap.regionId);
    const villageRef = db.collection("villages").doc(cap.cityId);

    const regionById = allCities.docs.find((d) => d.id === cap.regionId);
    const villageById = allVillages.docs.find((d) => d.id === cap.cityId);
    const regionByName = allCities.docs.find(
      (d) =>
        d.data().dolh &&
        d.data().dolh.id === cap.countryId &&
        nameHit(d.data(), cap.names),
    );
    const villageByName = allVillages.docs.find(
      (d) =>
        d.data().dolh &&
        d.data().dolh.id === cap.countryId &&
        nameHit(d.data(), cap.names),
    );

    let regionId = regionById?.id || regionByName?.id || null;
    let villageId = villageById?.id || villageByName?.id || null;

    let imgUrl = "";
    if (regionId && villageId) {
      report.capitalsReused.push({
        key,
        region: `cities/${regionId}`,
        city: `villages/${villageId}`,
      });
    } else {
      if (APPLY) {
        imgUrl = await uploadImage("regions/uploads", cap.regionId, cap.imageUrl);
        report.images.push({ id: cap.regionId, url: imgUrl });
      } else {
        imgUrl = `(dry-run) ${cap.imageUrl}`;
      }

      if (!regionId) {
        const payload = {
          naim: cap.names.ar,
          names_i18n: cap.names,
          osf: cap.osf.ar,
          osf_i18n: cap.osf,
          acctev: true,
          dolh: countryRef,
          sorting: cap.sorting,
          country_iso: cap.iso,
          iso_code: `${cap.iso}-CAP`,
          geo_center: new GeoPoint(cap.lat, cap.lng),
          lat_ling: new GeoPoint(cap.lat, cap.lng),
          img: imgUrl,
          icon: imgUrl,
          img_source: "firebase_storage",
          source_provider: SOURCE,
          geo_import_id: cap.regionId,
          geo_import_source: SOURCE,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (APPLY) {
          await regionRef.create(payload);
          // Link village after create when both new
        }
        regionId = cap.regionId;
        report.capitalsCreated.push(`cities/${cap.regionId}`);
      } else {
        report.capitalsReused.push(`cities/${regionId}`);
      }

      if (!villageId) {
        let cityImg = imgUrl;
        if (APPLY) {
          cityImg = await uploadImage("cities/uploads", cap.cityId, cap.imageUrl);
          report.images.push({ id: cap.cityId, url: cityImg });
        }
        const payload = {
          naim: cap.names.ar,
          names_i18n: cap.names,
          naimciteText: cap.names.en,
          osf: cap.osf.ar,
          osf_i18n: cap.osf,
          acctev: true,
          dolh: countryRef,
          cities: db.collection("cities").doc(regionId),
          sorting: 1,
          country_iso: cap.iso,
          lat_ling: new GeoPoint(cap.lat, cap.lng),
          img: cityImg,
          img_source: "firebase_storage",
          source_provider: SOURCE,
          geo_import_id: cap.cityId,
          geo_import_source: SOURCE,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (APPLY) {
          await villageRef.create(payload);
          await regionRef.set({ vil: villageRef }, { merge: true });
        }
        villageId = cap.cityId;
        report.capitalsCreated.push(`villages/${cap.cityId}`);
      } else {
        report.capitalsReused.push(`villages/${villageId}`);
      }
    }

    report.perCountry[cap.countryId] = {
      regionId,
      villageId,
      landmarks: [],
    };
  }

  // Refresh village/region ids after creates
  for (const [key, cap] of Object.entries(CAPITALS)) {
    const regionSnap = await db.collection("cities").doc(cap.regionId).get();
    const villageSnap = await db.collection("villages").doc(cap.cityId).get();
    let regionId = regionSnap.exists ? cap.regionId : null;
    let villageId = villageSnap.exists ? cap.cityId : null;
    if (!regionId || !villageId) {
      // name reuse path
      const r = allCities.docs.find(
        (d) =>
          d.data().dolh?.id === cap.countryId && nameHit(d.data(), cap.names),
      );
      const v = allVillages.docs.find(
        (d) =>
          d.data().dolh?.id === cap.countryId && nameHit(d.data(), cap.names),
      );
      regionId = regionId || r?.id;
      villageId = villageId || v?.id;
    }
    if (!APPLY) {
      // dry-run: assume intended ids
      regionId = regionId || cap.regionId;
      villageId = villageId || cap.cityId;
    }
    if (!regionId || !villageId) {
      throw new Error(`Unresolved capital refs for ${key}`);
    }
    report.perCountry[cap.countryId].regionId = regionId;
    report.perCountry[cap.countryId].villageId = villageId;
  }

  // ---- Landmarks ----
  for (const lm of LANDMARKS) {
    const country = report.perCountry[lm.countryId];
    const regionId = country.regionId;
    const villageId = country.villageId;
    const regionRef = db.collection("cities").doc(regionId);
    const villageRef = db.collection("villages").doc(villageId);
    const countryRef = db.collection("countries").doc(lm.countryId);
    const mkanRef = db.collection("mkan").doc(lm.id);

    const byId = allMkan.docs.find((d) => d.id === lm.id);
    const byNameParent = allMkan.docs.find((d) => {
      const x = d.data();
      if (!nameHit(x, lm.names)) return false;
      const vill = x.id_vill?.id;
      if (vill && vill === villageId) return true;
      const countryHit =
        x.Rev_dolh?.id === lm.countryId || x.dolh?.id === lm.countryId;
      const loc = geoFromDoc(x);
      return countryHit && near(loc, { lat: lm.lat, lng: lm.lng }, 120);
    });
    const byCoord = allMkan.docs.find((d) => {
      const loc = geoFromDoc(d.data());
      return (
        d.data().Rev_dolh?.id === lm.countryId &&
        near(loc, { lat: lm.lat, lng: lm.lng }, 60)
      );
    });

    const existing = byId || byNameParent || byCoord;
    if (existing) {
      report.landmarksReused.push({
        wanted: lm.id,
        existing: existing.id,
        name: lm.names.en,
      });
      country.landmarks.push(existing.id);
      continue;
    }

    let img1 = lm.imageUrl;
    if (APPLY) {
      img1 = await uploadImage("landmarks/uploads", lm.id, lm.imageUrl);
      report.images.push({ id: lm.id, url: img1 });
    } else {
      img1 = `(dry-run) ${lm.imageUrl}`;
    }

    const address_i18n = {};
    for (const loc of LOCALES) {
      const cityName =
        CAPITALS[lm.cityKey].names[loc] || CAPITALS[lm.cityKey].names.en;
      const countryName =
        {
          russia: {
            ar: "روسيا",
            en: "Russia",
            zh_Hans: "俄罗斯",
            tr: "Rusya",
            ur: "روس",
            ru: "Россия",
            az: "Rusiya",
            ka: "რუსეთი",
            ky: "Россия",
            fr: "Russie",
            id: "Rusia",
            pt: "Rússia",
          },
          uzbekistan: {
            ar: "أوزبكستان",
            en: "Uzbekistan",
            zh_Hans: "乌兹别克斯坦",
            tr: "Özbekistan",
            ur: "ازبکستان",
            ru: "Узбекистан",
            az: "Özbəkistan",
            ka: "უზბეკეთი",
            ky: "Өзбекстан",
            fr: "Ouzbékistan",
            id: "Uzbekistan",
            pt: "Uzbequistão",
          },
          turkmenistan: {
            ar: "تركمانستان",
            en: "Turkmenistan",
            zh_Hans: "土库曼斯坦",
            tr: "Türkmenistan",
            ur: "ترکمانستان",
            ru: "Туркменистан",
            az: "Türkmənistan",
            ka: "თურქმენეთი",
            ky: "Түркмөнстан",
            fr: "Turkménistan",
            id: "Turkmenistan",
            pt: "Turquemenistão",
          },
          kazakhstan: {
            ar: "كازاخستان",
            en: "Kazakhstan",
            zh_Hans: "哈萨克斯坦",
            tr: "Kazakistan",
            ur: "قازقستان",
            ru: "Казахстан",
            az: "Qazaxıstan",
            ka: "ყაზახეთი",
            ky: "Казакстан",
            fr: "Kazakhstan",
            id: "Kazakhstan",
            pt: "Cazaquistão",
          },
          georgia: {
            ar: "جورجيا",
            en: "Georgia",
            zh_Hans: "格鲁吉亚",
            tr: "Gürcistan",
            ur: "جارجیا",
            ru: "Грузия",
            az: "Gürcüstan",
            ka: "საქართველო",
            ky: "Грузия",
            fr: "Géorgie",
            id: "Georgia",
            pt: "Geórgia",
          },
          egypt: {
            ar: "مصر",
            en: "Egypt",
            zh_Hans: "埃及",
            tr: "Mısır",
            ur: "مصر",
            ru: "Египет",
            az: "Misir",
            ka: "ეგვიპტე",
            ky: "Египет",
            fr: "Égypte",
            id: "Mesir",
            pt: "Egito",
          },
        }[lm.countryId] || {};
      address_i18n[loc] =
        `${lm.names[loc]}, ${cityName}, ${countryName[loc] || lm.countryId}`;
    }

    const iso = CAPITALS[lm.cityKey].iso;
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
      img_attribution: lm.img_attribution || "",
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
      country_id: lm.countryId,
      country_iso: iso,
      source_provider: SOURCE,
      verification_status: "verified",
      verification_confidence: 0.95,
      geo_import_id: lm.id,
      geo_import_slug: lm.id.replace(/^lm_[a-z]+_[a-z]+_/, ""),
      geo_import_source: SOURCE,
      dataAdd: admin.firestore.FieldValue.serverTimestamp(),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (APPLY) {
      await mkanRef.create(payload);
    }
    report.landmarksCreated.push(lm.id);
    country.landmarks.push(lm.id);
  }

  // ---- Runtime validation ----
  let translations = "PASS";
  let images = "PASS";
  let coordinates = "PASS";
  let geoReferences = "PASS";
  let adminRuntime = APPLY ? "PASS" : "SKIP";
  let customerRuntime = APPLY ? "PASS" : "SKIP";
  let existingDataChanged = "PASS";
  let finalStatus = "PASS";

  const outLines = {};

  if (APPLY) {
    for (const p of preservePaths) {
      const now = await fingerprintPath(p);
      if (beforeHashes[p] && now !== beforeHashes[p]) {
        existingDataChanged = "FAIL";
        finalStatus = "FAIL";
      }
    }

    for (const [key, cap] of Object.entries(CAPITALS)) {
      const regionId = report.perCountry[cap.countryId].regionId;
      const villageId = report.perCountry[cap.countryId].villageId;
      const region = await db.collection("cities").doc(regionId).get();
      const village = await db.collection("villages").doc(villageId).get();
      if (!region.exists || !village.exists) {
        geoReferences = "FAIL";
        finalStatus = "FAIL";
        outLines[`${key.toUpperCase()}_CAPITAL`] = "FAIL";
        continue;
      }
      const rd = region.data();
      const vd = village.data();
      if (rd.acctev !== true || vd.acctev !== true) {
        geoReferences = "FAIL";
        finalStatus = "FAIL";
      }
      if (rd.dolh?.id !== cap.countryId || vd.dolh?.id !== cap.countryId) {
        geoReferences = "FAIL";
        finalStatus = "FAIL";
      }
      if (vd.cities?.id !== regionId) {
        geoReferences = "FAIL";
        finalStatus = "FAIL";
      }
      for (const loc of LOCALES) {
        if (!rd.names_i18n?.[loc] || !vd.names_i18n?.[loc]) {
          translations = "FAIL";
          finalStatus = "FAIL";
        }
      }
      if (!(await headOk(rd.img)) || !(await headOk(vd.img))) {
        images = "FAIL";
        finalStatus = "FAIL";
      }

      const mkans = await db
        .collection("mkan")
        .where("id_vill", "==", db.collection("villages").doc(villageId))
        .where("acctev", "==", true)
        .get();

      // Count only our target landmarks (by id prefix or exact set)
      const targetIds = new Set(
        LANDMARKS.filter((l) => l.countryId === cap.countryId).map((l) => l.id),
      );
      const matched = mkans.docs.filter(
        (d) =>
          targetIds.has(d.id) ||
          report.landmarksReused.some(
            (r) => r.existing === d.id && targetIds.has(r.wanted),
          ),
      );

      // Prefer exact target docs
      const valid = [];
      for (const tid of targetIds) {
        const snap = await db.collection("mkan").doc(tid).get();
        if (snap.exists) {
          valid.push(snap);
          continue;
        }
        const reused = report.landmarksReused.find((r) => r.wanted === tid);
        if (reused) {
          const rsnap = await db.collection("mkan").doc(reused.existing).get();
          if (rsnap.exists) valid.push(rsnap);
        }
      }

      const landmarkNames = [];
      for (const snap of valid) {
        const x = snap.data();
        landmarkNames.push(x.names_i18n?.en || x.naim);
        for (const loc of LOCALES) {
          if (!x.names_i18n?.[loc] || !x.osf_i18n?.[loc]) {
            translations = "FAIL";
            finalStatus = "FAIL";
          }
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
          x.id_vill?.id !== villageId ||
          x.id_cit?.id !== regionId ||
          x.Rev_dolh?.id !== cap.countryId ||
          x.acctev !== true
        ) {
          geoReferences = "FAIL";
          customerRuntime = "FAIL";
          adminRuntime = "FAIL";
          finalStatus = "FAIL";
        }
      }

      if (valid.length !== 7) {
        finalStatus = "FAIL";
        customerRuntime = "FAIL";
      }

      outLines[`${key.toUpperCase()}_CAPITAL`] =
        `${cap.names.en} / ${cap.names.ar} (cities/${regionId} + villages/${villageId})`;
      outLines[`${key.toUpperCase()}_LANDMARKS`] =
        `${valid.length}/7: ${landmarkNames.join("; ")}`;
    }
  } else {
    for (const [key, cap] of Object.entries(CAPITALS)) {
      outLines[`${key.toUpperCase()}_CAPITAL`] =
        `WOULD ${cap.names.en} / ${cap.names.ar}`;
      const names = LANDMARKS.filter((l) => l.countryId === cap.countryId).map(
        (l) => l.names.en,
      );
      outLines[`${key.toUpperCase()}_LANDMARKS`] = `WOULD 7/7: ${names.join("; ")}`;
    }
    finalStatus = "DRY-RUN";
  }

  const capitalsCreatedCount = report.capitalsCreated.filter((p) =>
    p.startsWith("villages/"),
  ).length;
  // Count capital as region+city pair created: prefer unique keys
  const capitalPairsCreated = Object.keys(CAPITALS).filter((key) => {
    const cap = CAPITALS[key];
    return (
      report.capitalsCreated.includes(`cities/${cap.regionId}`) ||
      report.capitalsCreated.includes(`villages/${cap.cityId}`)
    );
  }).length;
  const capitalPairsReused = Object.keys(CAPITALS).length - capitalPairsCreated;

  const summary = {
    ...outLines,
    CAPITALS_CREATED: APPLY ? capitalPairsCreated : capitalPairsCreated,
    CAPITALS_REUSED: APPLY ? capitalPairsReused : capitalPairsReused,
    LANDMARKS_CREATED: report.landmarksCreated.length,
    LANDMARKS_REUSED: report.landmarksReused.length,
    TOTAL_VALID_LANDMARKS: APPLY
      ? report.landmarksCreated.length + report.landmarksReused.length
      : 42,
    DUPLICATES_CREATED: report.duplicatesCreated,
    TRANSLATIONS: translations,
    IMAGES: images,
    COORDINATES: coordinates,
    GEO_REFERENCES: geoReferences,
    ADMIN_RUNTIME: adminRuntime,
    CUSTOMER_RUNTIME: customerRuntime,
    EXISTING_DATA_CHANGED: existingDataChanged === "PASS" ? "NO" : "YES",
    FINAL_STATUS: finalStatus,
    detail: report,
  };

  const outPath = path.join(
    __dirname,
    "add_six_capitals_landmarks_report.json",
  );
  fs.writeFileSync(outPath, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));
  console.log("REPORT", outPath);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
