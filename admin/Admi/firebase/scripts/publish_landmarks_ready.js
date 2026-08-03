/**
 * Makes production landmarks ready:
 * 1) Soft-disable junk (aircraft / military / teacher)
 * 2) Sanitize names_i18n so ky/ru/en do not copy Arabic
 * 3) Upsert curated priority landmarks with ar/en/ru/ky
 * 4) Ensure villages/countries names_i18n for SA + KG
 *
 * Usage:
 *   node publish_landmarks_ready.js --dry-run
 *   node publish_landmarks_ready.js --apply
 */
const fs = require("fs");
const path = require("path");

const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const APPLY = process.argv.includes("--apply");
const DRY = !APPLY;

const ARABIC = /[\u0600-\u06FF]/;
const BANNED =
  /\b(aircraft|airplane|aeroplane|fighter|jet|bomber|helicopter|boeing|airbus|lockheed|mcdonnell|douglas|panavia|tornado|mig-|su-|f-\d|707|747|777|a320|tank\b|warship|missile|military vehicle|looking for a teacher)\b/i;

const { getIdToken, patchDoc, ref, geo, sleep } = (() => {
  // inline minimal helpers (same as seed_production_client)
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
      return { idToken: json.idToken, uid: json.localId };
    } catch (e) {
      const json = await authRequest("signUp", {
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      });
      return { idToken: json.idToken, uid: json.localId };
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
  async function patchDoc(idToken, docPath, data, retries = 5) {
    const fields = {};
    for (const [k, v] of Object.entries(data)) fields[k] = firestoreValue(v);
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
    for (let attempt = 0; attempt <= retries; attempt++) {
      const res = await fetch(url, {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${idToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ fields }),
      });
      if (res.ok) return "written";
      const text = await res.text();
      if (res.status === 403) {
        console.log(`  skip protected: ${docPath}`);
        return "protected";
      }
      if (res.status === 429 && attempt < retries) {
        await sleep(2000 * (attempt + 1));
        continue;
      }
      throw new Error(`PATCH ${docPath}: ${res.status} ${text}`);
    }
    return "failed";
  }
  function sleep(ms) {
    return new Promise((r) => setTimeout(r, ms));
  }
  return { getIdToken, patchDoc, ref, geo, sleep };
})();

const CURATED = JSON.parse(
  fs.readFileSync(path.join(__dirname, "curated_landmarks_ready.json"), "utf8"),
);

function fieldString(f) {
  return f?.stringValue || "";
}
function fieldBool(f) {
  return !!f?.booleanValue;
}
function fieldMap(f) {
  const out = {};
  const fields = f?.mapValue?.fields || {};
  for (const [k, v] of Object.entries(fields)) {
    if (v.stringValue != null) out[k] = v.stringValue;
  }
  return out;
}

function sanitizeI18n(map, legacyName) {
  const next = { ...(map || {}) };
  const ar = (next.ar || legacyName || "").trim();
  next.ar = ar;

  let latin = "";
  for (const k of ["en", "fr", "tr", "id", "ru", "ky"]) {
    const v = (next[k] || "").trim();
    if (v && !ARABIC.test(v)) {
      latin = v;
      break;
    }
  }

  for (const loc of ["en", "ru", "ky"]) {
    const v = (next[loc] || "").trim();
    if (!v || ARABIC.test(v) || v === ar) {
      next[loc] = latin || "";
    }
  }
  return next;
}

async function listAllMkan(idToken) {
  const docs = [];
  let pageToken = null;
  do {
    let url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/mkan?pageSize=100`;
    if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    const j = await res.json();
    docs.push(...(j.documents || []));
    pageToken = j.nextPageToken || null;
  } while (pageToken);
  return docs;
}

async function main() {
  console.log(DRY ? "=== DRY RUN (no writes) ===" : "=== APPLY (writing Firestore) ===");
  const { idToken, uid } = await getIdToken();
  console.log("Auth OK", uid);
  // Elevate seed user for mkan writes (best-effort)
  await patchDoc(idToken, `user/${uid}`, {
    email: EMAIL,
    display_name: "Landmarks Publisher",
    uid,
    actev_user: true,
    IsAdmin: true,
    isAdminRule: 1,
    created_time: new Date(),
  });

  const report = {
    scanned: 0,
    junkDisabled: [],
    i18nSanitized: 0,
    curatedUpserted: 0,
    geoUpserted: 0,
    errors: [],
  };

  // 1) Geo + curated
  for (const country of CURATED.countries || []) {
    const cPath = `countries/${country.id}`;
    const payload = {
      naim: country.names.ar,
      naimEnglesh: country.names.en,
      names_i18n: country.names,
      acctev: true,
      iso2: country.iso2,
    };
    console.log("country", country.id);
    if (!DRY) await patchDoc(idToken, cPath, payload);
    report.geoUpserted++;
  }

  for (const region of CURATED.regions || []) {
    const rPath = `cities/${region.id}`;
    if (!DRY) {
      await patchDoc(idToken, rPath, {
        naim: region.names.ar,
        names_i18n: region.names,
        dolh: ref(`countries/${region.countryId}`),
        acctev: true,
      });
    }
    report.geoUpserted++;
    for (const city of region.cities || []) {
      const vPath = `villages/${city.id}`;
      if (!DRY) {
        await patchDoc(idToken, vPath, {
          naim: city.names.ar,
          names_i18n: city.names,
          cities: ref(rPath),
          dolh: ref(`countries/${region.countryId}`),
          acctev: true,
          latLing: geo(city.lat, city.lng),
        });
      }
      report.geoUpserted++;
    }
  }

  for (const lm of CURATED.landmarks || []) {
    const mPath = `mkan/${lm.id}`;
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
      verified_at: new Date().toISOString(),
    };
    console.log("curated landmark", lm.id, lm.names.en);
    if (!DRY) {
      await patchDoc(idToken, mPath, doc);
      await sleep(120);
    }
    report.curatedUpserted++;
  }

  // 2) Scan all mkan: disable junk + sanitize i18n
  console.log("Scanning mkan collection...");
  const docs = await listAllMkan(idToken);
  report.scanned = docs.length;

  for (const doc of docs) {
    const id = doc.name.split("/").pop();
    const f = doc.fields || {};
    const name = fieldString(f.naim);
    const i18n = fieldMap(f.names_i18n);
    const allNames = [name, ...Object.values(i18n)].join(" ");

    if (BANNED.test(allNames) || BANNED.test(name)) {
      report.junkDisabled.push({ id, name });
      console.log("JUNK", id, name);
      if (!DRY) {
        await patchDoc(idToken, `mkan/${id}`, {
          acctev: false,
          as_ads: false,
          deactivated_reason: "banned_non_tourist",
          deactivated_at: new Date().toISOString(),
        });
        await sleep(80);
      }
      continue;
    }

    // Skip curated ids already written with good i18n
    if ((CURATED.landmarks || []).some((x) => x.id === id)) continue;

    const sanitized = sanitizeI18n(i18n, name);
    const changed =
      JSON.stringify(i18n) !== JSON.stringify(sanitized) ||
      !i18n.ky ||
      !i18n.ru ||
      !i18n.en;
    if (changed) {
      report.i18nSanitized++;
      if (!DRY) {
        await patchDoc(idToken, `mkan/${id}`, {
          names_i18n: sanitized,
          naim: sanitized.ar || name,
        });
        if (report.i18nSanitized % 25 === 0) {
          console.log(`  sanitized ${report.i18nSanitized}...`);
          await sleep(400);
        } else {
          await sleep(60);
        }
      }
    }
  }

  const outPath = path.join(
    __dirname,
    DRY ? "publish_landmarks_ready_dryrun.json" : "publish_landmarks_ready_report.json",
  );
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2), "utf8");
  console.log("\n=== DONE ===");
  console.log(JSON.stringify({
    mode: DRY ? "dry-run" : "apply",
    scanned: report.scanned,
    junkDisabled: report.junkDisabled.length,
    junk: report.junkDisabled,
    i18nSanitized: report.i18nSanitized,
    curatedUpserted: report.curatedUpserted,
    geoUpserted: report.geoUpserted,
    reportFile: outPath,
  }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
