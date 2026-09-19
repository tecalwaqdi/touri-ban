/**
 * Additive-only: create the 7 requested Saudi geo locations if missing.
 *
 * Hierarchy (proven project schema):
 *   Region = cities/*   (dolh → countries/saudi_arabia)
 *   City   = villages/* (cities → region, dolh → country)
 *
 * - Jazan / Najran / Hail / Al Bahah / Al Jawf → active Saudi regions
 *   (+ matching capital city docs, Tabuk pattern)
 * - Khamis Mushait → city under region_sa_asir
 * - AlUla → city under region_sa_madinah
 *
 * Safety: never overwrite, never delete, never touch landmarks / existing docs.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_saudi_geo_locations.js
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_saudi_geo_locations.js --apply
 */
const path = require("path");
const https = require("https");
const http = require("http");
const { URL } = require("url");

const APPLY = process.argv.includes("--apply");
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const BUCKET = "tutorial-multi-language-70gx4j.firebasestorage.app";
const COUNTRY = "saudi_arabia";

const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

/** Supported content locales — from Admi/lib/core/i18n/toury_i18n_locales.dart */
const LOCALES = [
  "ar",
  "en",
  "zh_Hans",
  "tr",
  "ur",
  "ru",
  "az",
  "ka",
  "ky",
  "fr",
  "id",
  "pt",
];

function names(map) {
  for (const k of LOCALES) {
    if (!map[k] || !String(map[k]).trim()) {
      throw new Error(`Missing translation for locale ${k}: ${JSON.stringify(map)}`);
    }
  }
  return map;
}

const REGIONS = [
  {
    id: "region_sa_jazan",
    cityId: "city_sa_jazan",
    sorting: 80,
    lat: 16.8894,
    lng: 42.5706,
    naim: "جازان",
    names: names({
      ar: "جازان",
      en: "Jazan",
      zh_Hans: "吉赞",
      tr: "Cizan",
      ur: "جازان",
      ru: "Джазан",
      az: "Cazan",
      ka: "ჯაზანი",
      ky: "Жазан",
      fr: "Jizan",
      id: "Jazan",
      pt: "Jazan",
    }),
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Sunset_in_Jazan.jpg/1280px-Sunset_in_Jazan.jpg",
  },
  {
    id: "region_sa_najran",
    cityId: "city_sa_najran",
    sorting: 90,
    lat: 17.565,
    lng: 44.2289,
    naim: "نجران",
    names: names({
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
    }),
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Mud_architecture_of_Najran%2C_Saudi_Arabia.jpg/1280px-Mud_architecture_of_Najran%2C_Saudi_Arabia.jpg",
  },
  {
    id: "region_sa_hail",
    cityId: "city_sa_hail",
    sorting: 100,
    lat: 27.5114,
    lng: 41.7208,
    naim: "حائل",
    names: names({
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
    }),
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Hail_heritage.jpg/1280px-Hail_heritage.jpg",
  },
  {
    id: "region_sa_baha",
    cityId: "city_sa_baha",
    sorting: 110,
    lat: 20.0129,
    lng: 41.4677,
    naim: "الباحة",
    names: names({
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
    }),
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/%D8%A7%D9%84%D8%A8%D8%A7%D8%AD%D8%A9_-_1.jpeg/1280px-%D8%A7%D9%84%D8%A8%D8%A7%D8%AD%D8%A9_-_1.jpeg",
  },
  {
    id: "region_sa_jouf",
    cityId: "city_sa_jouf",
    sorting: 120,
    lat: 29.9697,
    lng: 40.2064,
    naim: "الجوف",
    names: names({
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
    }),
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/ISS-64_Sakakah_oasis_city%2C_Saudi_Arabia.jpg/1280px-ISS-64_Sakakah_oasis_city%2C_Saudi_Arabia.jpg",
  },
];

const CITIES_ONLY = [
  {
    id: "city_sa_khamis_mushait",
    parentRegionId: "region_sa_asir",
    lat: 18.3,
    lng: 42.7333,
    naim: "خميس مشيط",
    names: names({
      ar: "خميس مشيط",
      en: "Khamis Mushait",
      zh_Hans: "海米斯穆谢特",
      tr: "Hamis Muşayt",
      ur: "خمیس مشیط",
      ru: "Хамис-Мушайт",
      az: "Xamis Muşayt",
      ka: "ხამის-მუშაიტი",
      ky: "Хамис Мушайт",
      fr: "Khamis Mushait",
      id: "Khamis Mushait",
      pt: "Khamis Mushait",
    }),
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Khamis_Mushayt.jpg/1280px-Khamis_Mushayt.jpg",
  },
  {
    id: "city_sa_alula",
    parentRegionId: "region_sa_madinah",
    lat: 26.6085,
    lng: 37.9232,
    naim: "العلا",
    names: names({
      ar: "العلا",
      en: "AlUla",
      zh_Hans: "欧拉",
      tr: "El Ula",
      ur: "العلا",
      ru: "Эль-Ула",
      az: "Əl-Ula",
      ka: "ალ-ულა",
      ky: "Аль-Ула",
      fr: "AlUla",
      id: "AlUla",
      pt: "AlUla",
    }),
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Al_Ula_old_town%2C_Saudi_Arabia_2011.jpg/1280px-Al_Ula_old_town%2C_Saudi_Arabia_2011.jpg",
  },
];

const NAME_ALIASES = {
  جازان: ["جازان", "jazan", "jizan", "gizan"],
  نجران: ["نجران", "najran"],
  حائل: ["حائل", "hail", "ha'il", "ha’il"],
  الباحة: ["الباحة", "al bahah", "al baha", "bahah", "baha"],
  الجوف: ["الجوف", "al jawf", "al jouf", "jawf", "jouf"],
  "خميس مشيط": ["خميس مشيط", "khamis mushait", "khamis mushayt", "khamis"],
  العلا: ["العلا", "alula", "al ula", "al-'ula", "al uła"],
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
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          download(res.headers.location, attempt).then(resolve, reject);
          return;
        }
        if ((res.statusCode === 429 || res.statusCode >= 500) && attempt < 6) {
          res.resume();
          const wait = 1500 * attempt * attempt;
          setTimeout(() => {
            download(url, attempt + 1).then(resolve, reject);
          }, wait);
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
        setTimeout(() => {
          download(url, attempt + 1).then(resolve, reject);
        }, 1500 * attempt * attempt);
      } else {
        reject(err);
      }
    });
  });
}

async function uploadImage(storageFolder, slug, sourceUrl) {
  await new Promise((r) => setTimeout(r, 800));
  const bytes = await download(sourceUrl);
  if (!bytes.length) throw new Error(`empty image ${sourceUrl}`);
  const objectPath = `${storageFolder}/${slug}_${Date.now()}.jpg`;
  const file = admin.storage().bucket().file(objectPath);
  await file.save(bytes, {
    resumable: false,
    contentType: "image/jpeg",
    metadata: {
      cacheControl: "public,max-age=31536000",
      metadata: {
        source: sourceUrl,
        uploaded_by: "add_saudi_geo_locations.js",
      },
    },
  });
  await file.makePublic().catch(() => {});
  const [meta] = await file.getMetadata();
  const token =
    (meta.metadata && meta.metadata.firebaseStorageDownloadTokens) || null;
  const encoded = encodeURIComponent(objectPath);
  const base = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encoded}?alt=media`;
  const url = token ? `${base}&token=${token}` : base;
  // Verify URL loads
  const check = await new Promise((resolve) => {
    https
      .get(url, { headers: { Range: "bytes=0-64", "User-Agent": "TouriTaxiGeoBot/1.0" } }, (res) => {
        res.resume();
        resolve(res.statusCode);
      })
      .on("error", () => resolve(0));
  });
  if (!(check === 200 || check === 206)) {
    throw new Error(`uploaded image URL did not load (${check}): ${url}`);
  }
  return url;
}

function countryRef(db) {
  return db.collection("countries").doc(COUNTRY);
}

function regionRef(db, id) {
  return db.collection("cities").doc(id);
}

function cityRef(db, id) {
  return db.collection("villages").doc(id);
}

function findNameDuplicate(docs, arabicName) {
  const aliases = (NAME_ALIASES[arabicName] || [arabicName]).map(normalize);
  for (const doc of docs) {
    const d = doc.data() || {};
    if (d.dolh && d.dolh.id && d.dolh.id !== COUNTRY) continue;
    const candidates = [
      d.naim,
      ...(Object.values(d.names_i18n || {})),
    ]
      .map(normalize)
      .filter(Boolean);
    if (candidates.some((c) => aliases.includes(c) || aliases.some((a) => c === a))) {
      return doc.id;
    }
  }
  return null;
}

async function createRegion(db, region, imgUrl, report) {
  const ref = regionRef(db, region.id);
  const snap = await ref.get();
  if (snap.exists) {
    report.already.push(`cities/${region.id}`);
    return false;
  }
  const payload = {
    naim: region.naim,
    names_i18n: region.names,
    osf: "",
    acctev: true,
    dolh: countryRef(db),
    sorting: region.sorting,
    country_iso: "SA",
    geo_center: new admin.firestore.GeoPoint(region.lat, region.lng),
    lat_ling: new admin.firestore.GeoPoint(region.lat, region.lng),
    img: imgUrl,
    img_source: "firebase_storage",
    source_provider: "add_saudi_geo_locations_2026",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (APPLY) await ref.create(payload);
  report.created.push(`cities/${region.id}`);
  report.regionsAdded += 1;
  return true;
}

async function createCity(db, city, parentRegionId, imgUrl, report, opts = {}) {
  const ref = cityRef(db, city.id);
  const snap = await ref.get();
  if (snap.exists) {
    report.already.push(`villages/${city.id}`);
    return false;
  }
  const parent = regionRef(db, parentRegionId);
  const parentSnap = await parent.get();
  const parentPending = opts.parentPending === true;
  if (!parentSnap.exists && !(parentPending && !APPLY)) {
    throw new Error(`Missing parent region ${parentRegionId} for ${city.id}`);
  }
  const payload = {
    naim: city.naim,
    names_i18n: city.names,
    osf: "",
    acctev: true,
    dolh: countryRef(db),
    cities: parent,
    sorting: 1,
    country_iso: "SA",
    lat_ling: new admin.firestore.GeoPoint(city.lat, city.lng),
    img: imgUrl,
    img_source: "firebase_storage",
    source_provider: "add_saudi_geo_locations_2026",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (APPLY) await ref.create(payload);
  report.created.push(`villages/${city.id}`);
  report.citiesAdded += 1;
  return true;
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const report = {
    mode: APPLY ? "APPLY" : "DRY-RUN",
    created: [],
    already: [],
    skippedNameDup: [],
    regionsAdded: 0,
    citiesAdded: 0,
    images: [],
    errors: [],
  };

  const [regionsSnap, citiesSnap] = await Promise.all([
    db.collection("cities").get(),
    db.collection("villages").get(),
  ]);
  const regionDocs = regionsSnap.docs;
  const cityDocs = citiesSnap.docs;

  // Preflight: required parents exist
  for (const id of ["region_sa_asir", "region_sa_madinah", COUNTRY]) {
    const col = id === COUNTRY ? "countries" : "cities";
    const ok = (await db.collection(col).doc(id).get()).exists;
    if (!ok) throw new Error(`Required parent missing: ${col}/${id}`);
  }

  for (const region of REGIONS) {
    const nameDupRegion = findNameDuplicate(regionDocs, region.naim);
    if (nameDupRegion && nameDupRegion !== region.id) {
      report.skippedNameDup.push({
        wanted: region.id,
        existing: `cities/${nameDupRegion}`,
        name: region.naim,
      });
      report.already.push(`cities/${nameDupRegion}`);
      continue;
    }

    const regionExists = (await regionRef(db, region.id).get()).exists;
    const cityExists = (await cityRef(db, region.cityId).get()).exists;
    if (regionExists && cityExists) {
      report.already.push(`cities/${region.id}`);
      report.already.push(`villages/${region.cityId}`);
      continue;
    }

    let imgUrl = "";
    if (regionExists) {
      imgUrl = (await regionRef(db, region.id).get()).get("img") || "";
      report.already.push(`cities/${region.id}`);
    } else if (APPLY) {
      imgUrl = await uploadImage("regions/uploads", region.id, region.imageUrl);
      report.images.push({ id: region.id, url: imgUrl, folder: "regions/uploads" });
      await createRegion(db, region, imgUrl, report);
    } else {
      imgUrl = `(dry-run) ${region.imageUrl}`;
      report.images.push({ id: region.id, url: imgUrl, folder: "regions/uploads" });
      await createRegion(db, region, imgUrl, report);
    }

    // Matching capital city (Tabuk / Abha / Jeddah pattern)
    const citySpec = {
      id: region.cityId,
      naim: region.naim,
      names: region.names,
      lat: region.lat,
      lng: region.lng,
      imageUrl: region.imageUrl,
    };
    const nameDupCity = findNameDuplicate(cityDocs, region.naim);
    if (nameDupCity && nameDupCity !== region.cityId) {
      report.skippedNameDup.push({
        wanted: region.cityId,
        existing: `villages/${nameDupCity}`,
        name: region.naim,
      });
      report.already.push(`villages/${nameDupCity}`);
    } else if (cityExists) {
      report.already.push(`villages/${region.cityId}`);
    } else {
      let cityImg = imgUrl;
      if (APPLY) {
        cityImg = await uploadImage("cities/uploads", region.cityId, region.imageUrl);
        report.images.push({
          id: region.cityId,
          url: cityImg,
          folder: "cities/uploads",
        });
      }
      await createCity(db, citySpec, region.id, cityImg, report, {
        parentPending: !regionExists,
      });
    }
  }

  for (const city of CITIES_ONLY) {
    const nameDup = findNameDuplicate(cityDocs, city.naim);
    if (nameDup && nameDup !== city.id) {
      report.skippedNameDup.push({
        wanted: city.id,
        existing: `villages/${nameDup}`,
        name: city.naim,
      });
      report.already.push(`villages/${nameDup}`);
      continue;
    }
    if ((await cityRef(db, city.id).get()).exists) {
      report.already.push(`villages/${city.id}`);
      continue;
    }
    let imgUrl = "";
    if (APPLY) {
      imgUrl = await uploadImage("cities/uploads", city.id, city.imageUrl);
      report.images.push({ id: city.id, url: imgUrl, folder: "cities/uploads" });
    } else {
      imgUrl = `(dry-run) ${city.imageUrl}`;
      report.images.push({ id: city.id, url: imgUrl, folder: "cities/uploads" });
    }
    await createCity(db, city, city.parentRegionId, imgUrl, report);
  }

  console.log(JSON.stringify(report, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
