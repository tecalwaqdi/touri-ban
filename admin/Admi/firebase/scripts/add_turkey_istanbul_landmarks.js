/**
 * Additive: Turkey + Istanbul region/city + 7 landmarks.
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_turkey_istanbul_landmarks.js
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_turkey_istanbul_landmarks.js --apply
 */
"use strict";

const path = require("path");
const APPLY = process.argv.includes("--apply");
const PROJECT_ID = "tutorial-multi-language-70gx4j";

const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));

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

function names(partial) {
  const out = { ...partial };
  for (const loc of LOCALES) {
    if (!out[loc] || !String(out[loc]).trim()) {
      out[loc] = partial.en || partial.ar || "";
    }
  }
  return out;
}

const COUNTRY = {
  id: "turkey",
  iso2: "TR",
  currency_code: "TRY",
  CurrencySymbol: "₺",
  phone_code: "+90",
  timezone: "Europe/Istanbul",
  lat: 38.9637,
  lng: 35.2433,
  names: names({
    ar: "تركيا",
    en: "Turkey",
    tr: "Türkiye",
    ru: "Турция",
    fr: "Turquie",
  }),
};

const REGION = {
  id: "region_tr_istanbul",
  cityId: "city_tr_istanbul",
  lat: 41.0082,
  lng: 28.9784,
  names: names({
    ar: "إسطنبول",
    en: "Istanbul",
    tr: "İstanbul",
    ru: "Стамбул",
    fr: "Istanbul",
  }),
};

const LANDMARKS = [
  {
    id: "lm_tr_istanbul_hagia-sophia",
    lat: 41.0086,
    lng: 28.9802,
    names: names({
      ar: "آيا صوفيا",
      en: "Hagia Sophia",
      tr: "Ayasofya",
    }),
  },
  {
    id: "lm_tr_istanbul_blue-mosque",
    lat: 41.0054,
    lng: 28.9768,
    names: names({
      ar: "المسجد الأزرق",
      en: "Blue Mosque",
      tr: "Sultanahmet Camii",
    }),
  },
  {
    id: "lm_tr_istanbul_topkapi",
    lat: 41.0115,
    lng: 28.9833,
    names: names({
      ar: "قصر توبكابي",
      en: "Topkapi Palace",
      tr: "Topkapı Sarayı",
    }),
  },
  {
    id: "lm_tr_istanbul_grand-bazaar",
    lat: 41.0107,
    lng: 28.968,
    names: names({
      ar: "البازار الكبير",
      en: "Grand Bazaar",
      tr: "Kapalıçarşı",
    }),
  },
  {
    id: "lm_tr_istanbul_galata",
    lat: 41.0256,
    lng: 28.9741,
    names: names({
      ar: "برج غلطة",
      en: "Galata Tower",
      tr: "Galata Kulesi",
    }),
  },
  {
    id: "lm_tr_istanbul_bosphorus",
    lat: 41.039,
    lng: 29.0,
    names: names({
      ar: "مضيق البوسفور",
      en: "Bosphorus",
      tr: "Boğaz",
    }),
  },
  {
    id: "lm_tr_istanbul_basilica-cistern",
    lat: 41.0084,
    lng: 28.9779,
    names: names({
      ar: "صهريج البازيليك",
      en: "Basilica Cistern",
      tr: "Yerebatan Sarnıcı",
    }),
  },
];

function init() {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
    });
  }
  return admin.firestore();
}

async function main() {
  const db = init();
  const FieldValue = admin.firestore.FieldValue;
  const GeoPoint = admin.firestore.GeoPoint;
  const countryRef = db.collection("countries").doc(COUNTRY.id);
  const regionRef = db.collection("cities").doc(REGION.id);
  const villageRef = db.collection("villages").doc(REGION.cityId);

  const report = { mode: APPLY ? "APPLY" : "DRY_RUN", created: [], reused: [] };

  const countrySnap = await countryRef.get();
  if (!countrySnap.exists) {
    const payload = {
      naim: COUNTRY.names.ar,
      names_i18n: COUNTRY.names,
      iso_code: COUNTRY.iso2,
      iso2: COUNTRY.iso2,
      currency_code: COUNTRY.currency_code,
      CurrencySymbol: COUNTRY.CurrencySymbol,
      phone_code: COUNTRY.phone_code,
      timezone: COUNTRY.timezone,
      acctev: true,
      flagEmoji: "🇹🇷",
      geo_center: new GeoPoint(COUNTRY.lat, COUNTRY.lng),
      Location: new GeoPoint(COUNTRY.lat, COUNTRY.lng),
      updatedAt: FieldValue.serverTimestamp(),
      source: "add_turkey_istanbul_landmarks",
    };
    if (APPLY) await countryRef.set(payload, { merge: true });
    report.created.push(countryRef.path);
  } else {
    if (APPLY) {
      await countryRef.set(
        { acctev: true, iso_code: COUNTRY.iso2, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
    report.reused.push(countryRef.path);
  }

  const regionSnap = await regionRef.get();
  if (!regionSnap.exists) {
    const payload = {
      naim: REGION.names.ar,
      names_i18n: REGION.names,
      dolh: countryRef,
      acctev: true,
      Location: new GeoPoint(REGION.lat, REGION.lng),
      lat_ling: new GeoPoint(REGION.lat, REGION.lng),
      vil: villageRef,
      sorting: 10,
      updatedAt: FieldValue.serverTimestamp(),
      source: "add_turkey_istanbul_landmarks",
    };
    if (APPLY) await regionRef.set(payload, { merge: true });
    report.created.push(regionRef.path);
  } else {
    if (APPLY) {
      await regionRef.set(
        {
          acctev: true,
          dolh: countryRef,
          vil: villageRef,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    report.reused.push(regionRef.path);
  }

  const villageSnap = await villageRef.get();
  if (!villageSnap.exists) {
    const payload = {
      naim: REGION.names.ar,
      names_i18n: REGION.names,
      dolh: countryRef,
      cities: regionRef,
      acctev: true,
      Location: new GeoPoint(REGION.lat, REGION.lng),
      lat_ling: new GeoPoint(REGION.lat, REGION.lng),
      noDeletePlace: false,
      updatedAt: FieldValue.serverTimestamp(),
      source: "add_turkey_istanbul_landmarks",
    };
    if (APPLY) await villageRef.set(payload, { merge: true });
    report.created.push(villageRef.path);
  } else {
    if (APPLY) {
      await villageRef.set(
        {
          acctev: true,
          dolh: countryRef,
          cities: regionRef,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    report.reused.push(villageRef.path);
  }

  for (const lm of LANDMARKS) {
    const ref = db.collection("mkan").doc(lm.id);
    const snap = await ref.get();
    if (snap.exists) {
      if (APPLY) {
        await ref.set(
          {
            acctev: true,
            id_vill: villageRef,
            id_cit: regionRef,
            Rev_dolh: countryRef,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
      report.reused.push(ref.path);
      continue;
    }
    const payload = {
      naim: lm.names.ar,
      names_i18n: lm.names,
      osf: lm.names.en,
      Location: new GeoPoint(lm.lat, lm.lng),
      id_vill: villageRef,
      id_cit: regionRef,
      Rev_dolh: countryRef,
      dolh: countryRef,
      acctev: true,
      tsnef: "معالم سياحية",
      rating: 4.8,
      updatedAt: FieldValue.serverTimestamp(),
      source: "add_turkey_istanbul_landmarks",
    };
    if (APPLY) await ref.set(payload, { merge: true });
    report.created.push(ref.path);
  }

  // Ensure TM/KZ/GE/EG capitals stay active (heal if deactivated).
  const heal = [
    ["turkmenistan", "region_tm_ashgabat", "city_tm_ashgabat"],
    ["kazakhstan", "region_kz_astana", "city_kz_astana"],
    ["georgia", "region_ge_tbilisi", "city_ge_tbilisi"],
    ["egypt", "region_eg_cairo", "city_eg_cairo"],
  ];
  for (const [cId, rId, vId] of heal) {
    if (!APPLY) continue;
    await db.collection("countries").doc(cId).set({ acctev: true }, { merge: true });
    await db.collection("cities").doc(rId).set({ acctev: true }, { merge: true });
    await db.collection("villages").doc(vId).set({ acctev: true }, { merge: true });
    const mk = await db
      .collection("mkan")
      .where("id_vill", "==", db.collection("villages").doc(vId))
      .get();
    for (const doc of mk.docs) {
      if (doc.data().acctev !== true) {
        await doc.ref.set({ acctev: true }, { merge: true });
        report.created.push(`heal:${doc.id}`);
      }
    }
  }

  console.log(JSON.stringify(report, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
