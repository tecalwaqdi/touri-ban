/**
 * Upsert Jeddah + Taif curated landmarks (additive PATCH only).
 * Also ensures villages/city_taif exists.
 * Usage: node publish_jeddah_taif_landmarks.js --apply
 */
const fs = require("fs");
const path = require("path");

const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const APPLY = process.argv.includes("--apply");

const NEW_IDS = new Set([
  "curated_jeddah_souq_alawi",
  "curated_jeddah_rahmah_mosque",
  "curated_jeddah_yacht_club",
  "curated_jeddah_tayebat_museum",
  "curated_taif_al_hada",
  "curated_taif_hada_teleferic",
  "curated_taif_ash_shafa",
  "curated_taif_jabal_daka",
]);

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
  if (json.error) throw new Error(json.error.message);
  return json;
}

async function getIdToken() {
  try {
    const json = await authRequest("signInWithPassword", {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return json.idToken;
  } catch (_) {
    const json = await authRequest("signUp", {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return json.idToken;
  }
}

function firestoreValue(val) {
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
    return { arrayValue: { values: val.map(firestoreValue) } };
  }
  if (val && val._type === "ref") {
    return {
      referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${val.path}`,
    };
  }
  if (val && val._type === "geo") {
    return { geoPointValue: { latitude: val.lat, longitude: val.lng } };
  }
  if (typeof val === "object") {
    const fields = {};
    for (const [k, v] of Object.entries(val)) fields[k] = firestoreValue(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function ref(p) {
  return { _type: "ref", path: p };
}
function geo(lat, lng) {
  return { _type: "geo", lat, lng };
}

async function patchDoc(idToken, docPath, data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) fields[k] = firestoreValue(v);
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${idToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`PATCH ${docPath}: ${res.status} ${text}`);
  }
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  const curated = JSON.parse(
    fs.readFileSync(path.join(__dirname, "curated_landmarks_ready.json"), "utf8"),
  );
  const landmarks = (curated.landmarks || []).filter((lm) => NEW_IDS.has(lm.id));
  if (landmarks.length !== NEW_IDS.size) {
    throw new Error(
      `Expected ${NEW_IDS.size} landmarks, found ${landmarks.length}`,
    );
  }

  // uniqueness checks
  const imgs = [];
  for (const lm of landmarks) {
    for (const k of ["ar", "en", "ru", "ky"]) {
      if (!lm.names?.[k] || !lm.descriptions?.[k]) {
        throw new Error(`Missing i18n on ${lm.id}.${k}`);
      }
    }
    if (lm.img1) imgs.push(lm.img1);
    if (lm.img2) imgs.push(lm.img2);
  }
  const seen = new Set();
  for (const u of imgs) {
    if (seen.has(u)) throw new Error(`Duplicate image URL: ${u}`);
    seen.add(u);
  }

  console.log(APPLY ? "APPLY mode" : "DRY-RUN mode");
  let idToken = null;
  if (APPLY) idToken = await getIdToken();

  // Ensure city_taif village exists (merge)
  const taifCity = curated.regions
    ?.find((r) => r.id === "region_makkah")
    ?.cities?.find((c) => c.id === "city_taif");
  if (taifCity) {
    const villageDoc = {
      naim: taifCity.names.ar,
      names_i18n: taifCity.names,
      id_cit: ref("cities/region_makkah"),
      Rev_dolh: ref("countries/saudi_arabia"),
      Location: geo(taifCity.lat, taifCity.lng),
      acctev: true,
      source_provider: "curated",
    };
    console.log(
      `${APPLY ? "WRITE" : "WOULD_WRITE"} villages/city_taif`,
    );
    if (APPLY) {
      await patchDoc(idToken, "villages/city_taif", villageDoc);
      await sleep(120);
    }
  }

  const report = [];
  for (const lm of landmarks) {
    const doc = {
      naim: lm.names.ar,
      osf: lm.descriptions?.ar || "",
      names_i18n: lm.names,
      osf_i18n: lm.descriptions || {},
      img1: lm.img1 || "",
      img2: lm.img2 || "",
      img3: "",
      sr: lm.sortOrder || 1,
      ismsgd: !!lm.isMosque,
      isfood: true,
      ishmam: true,
      acctev: true,
      as_ads: true,
      ismzod: true,
      isShrek: false,
      id_cit: ref(`cities/${lm.regionId}`),
      id_vill: ref(`villages/${lm.cityId}`),
      Rev_dolh: ref(`countries/${lm.countryId}`),
      Location: geo(lm.lat, lm.lng),
      address: lm.address?.ar || lm.names.ar,
      address_i18n: lm.address || { ar: lm.names.ar },
      tsnef: lm.categoryAr || "معلم سياحي",
      tsnef_i18n: lm.categoryI18n || {
        ar: lm.categoryAr || "معلم سياحي",
        en: lm.categoryEn || "Tourist landmark",
        ru: "Достопримечательность",
        ky: "Туристтик жай",
      },
      rate: lm.rate ?? 4.7,
      add_saat: 2,
      source_provider: "curated",
      img_source: lm.img_source || "wikimedia_commons",
      verified_at: new Date().toISOString(),
    };
    console.log(
      `${APPLY ? "WRITE" : "WOULD_WRITE"} mkan/${lm.id} — ${lm.names.en} → ${lm.cityId} (${lm.lat}, ${lm.lng})`,
    );
    if (APPLY) {
      await patchDoc(idToken, `mkan/${lm.id}`, doc);
      await sleep(150);
    }
    report.push({
      id: lm.id,
      cityId: lm.cityId,
      names: lm.names,
      lat: lm.lat,
      lng: lm.lng,
      img1: lm.img1,
    });
  }

  const out = path.join(__dirname, "publish_jeddah_taif_landmarks_report.json");
  fs.writeFileSync(
    out,
    JSON.stringify(
      { mode: APPLY ? "apply" : "dry-run", count: report.length, landmarks: report },
      null,
      2,
    ),
  );
  console.log("Report:", out);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
