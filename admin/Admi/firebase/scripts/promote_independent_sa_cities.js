/**
 * Promote Jeddah / Taif / Dammam / Khobar / Abha to independent Citie2 cards.
 * Restore Makkah + Riyadh hero images from staging.
 * Rewire villages.cities + mkan.id_cit — no deletes.
 *
 * Usage:
 *   node promote_independent_sa_cities.js           # dry-run
 *   node promote_independent_sa_cities.js --apply
 */
const fs = require("fs");
const path = require("path");

const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const APPLY = process.argv.includes("--apply");
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const RUN = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;

const STAGING_CITIES = path.resolve(
  __dirname,
  "../../../ara_oatan_app/firebase/tools/geo_import/staging/firestore/cities",
);
const CURATED = path.join(__dirname, "curated_landmarks_ready.json");

const COUNTRY = "countries/saudi_arabia";

/** Independent city-cards to show on Citie2 (not nested under a province). */
const INDEPENDENT = [
  {
    regionId: "region_sa_makkah",
    villageId: "city_sa_makkah",
    legacyVillageIds: ["city_makkah"],
    sorting: 10,
    names: {
      ar: "مكة المكرمة",
      en: "Makkah",
      ru: "Мекка",
      ky: "Мекке",
    },
    lat: 21.4225,
    lng: 39.8262,
    restoreImgFromStaging: true,
    keepExistingRegion: true,
  },
  {
    regionId: "region_sa_riyadh",
    villageId: "city_sa_riyadh",
    legacyVillageIds: ["city_riyadh"],
    sorting: 20,
    names: {
      ar: "الرياض",
      en: "Riyadh",
      ru: "Эр-Рияд",
      ky: "Эр-Рияд",
    },
    lat: 24.7136,
    lng: 46.6753,
    restoreImgFromStaging: true,
    keepExistingRegion: true,
  },
  {
    regionId: "region_sa_jeddah",
    villageId: "city_sa_jeddah",
    legacyVillageIds: ["city_jeddah"],
    sorting: 30,
    names: {
      ar: "جدة",
      en: "Jeddah",
      ru: "Джидда",
      ky: "Жидда",
    },
    lat: 21.4858,
    lng: 39.1925,
    // Prefer existing region image if present.
    imgFallback:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Jeddah_Corniche_%28cropped%29.jpg/1280px-Jeddah_Corniche_%28cropped%29.jpg",
  },
  {
    regionId: "region_sa_taif",
    villageId: "city_sa_taif",
    legacyVillageIds: ["city_taif"],
    sorting: 40,
    names: {
      ar: "الطائف",
      en: "Taif",
      ru: "Таиф",
      ky: "Таиф",
    },
    lat: 21.2703,
    lng: 40.4158,
    imgFallback:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Al-Hada%2C_near_al-Taif%2C_Saudi_Arabia_%282%29.jpg/1280px-Al-Hada%2C_near_al-Taif%2C_Saudi_Arabia_%282%29.jpg",
  },
  {
    regionId: "region_sa_dammam",
    villageId: "city_sa_dammam",
    legacyVillageIds: ["city_dammam"],
    sorting: 50,
    names: {
      ar: "الدمام",
      en: "Dammam",
      ru: "Даммам",
      ky: "Даммам",
    },
    lat: 26.4333,
    lng: 50.1,
    imgFallback:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Corniche_Dammam.jpg/1280px-Corniche_Dammam.jpg",
  },
  {
    regionId: "region_sa_khobar",
    villageId: "city_sa_khobar",
    legacyVillageIds: ["city_alkhobar", "city_khobar"],
    sorting: 60,
    names: {
      ar: "الخبر",
      en: "Al Khobar",
      ru: "Аль-Хубар",
      ky: "Аль-Хубар",
    },
    lat: 26.2833,
    lng: 50.2,
    imgFallback:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Khobar_corniche.jpg/1280px-Khobar_corniche.jpg",
  },
  {
    regionId: "region_sa_abha",
    villageId: "city_sa_abha",
    legacyVillageIds: ["city_abha"],
    sorting: 70,
    names: {
      ar: "أبها",
      en: "Abha",
      ru: "Абха",
      ky: "Абха",
    },
    lat: 18.2164,
    lng: 42.5053,
    imgFallback:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Abha_Saudi_Arabia.jpg/1280px-Abha_Saudi_Arabia.jpg",
  },
];

/** Province shells that would duplicate the independent city cards. */
const HIDE_EMPTY_SHELLS = [
  "region_sa_eastern", // Dammam + Khobar promoted
  "region_sa_asir", // Abha promoted
  "region_eastern",
  "region_asir",
  "region_makkah",
  "region_riyadh",
];

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

async function getDoc(idToken, docPath) {
  const res = await fetch(`${DOCS}/${docPath}`, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`GET ${docPath}: ${res.status}`);
  return res.json();
}

function fieldString(doc, key) {
  return doc?.fields?.[key]?.stringValue || "";
}

async function patchDoc(idToken, docPath, data) {
  const fields = {};
  const mask = [];
  for (const [k, v] of Object.entries(data)) {
    fields[k] = firestoreValue(v);
    mask.push(`updateMask.fieldPaths=${encodeURIComponent(k)}`);
  }
  const url = `${DOCS}/${docPath}?${mask.join("&")}`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${idToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) {
    throw new Error(`PATCH ${docPath}: ${res.status} ${await res.text()}`);
  }
}

async function runQuery(idToken, structuredQuery) {
  const res = await fetch(RUN, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${idToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ structuredQuery }),
  });
  if (!res.ok) throw new Error(`runQuery: ${res.status} ${await res.text()}`);
  return res.json();
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function loadStagingImg(regionId) {
  const p = path.join(STAGING_CITIES, `${regionId}.json`);
  if (!fs.existsSync(p)) return "";
  const d = JSON.parse(fs.readFileSync(p, "utf8"));
  return typeof d.img === "string" ? d.img : "";
}

async function remapLandmarksForVillage(idToken, villageId, regionId, report) {
  const villagePath = `projects/${PROJECT_ID}/databases/(default)/documents/villages/${villageId}`;
  const rows = await runQuery(idToken, {
    from: [{ collectionId: "mkan" }],
    where: {
      fieldFilter: {
        field: { fieldPath: "id_vill" },
        op: "EQUAL",
        value: { referenceValue: villagePath },
      },
    },
  });

  let n = 0;
  for (const row of rows) {
    const name = row.document?.name;
    if (!name) continue;
    const id = name.split("/").pop();
    const currentCit = (
      row.document.fields?.id_cit?.referenceValue || ""
    ).split("/").pop();
    if (currentCit === regionId) continue;
    report.push({ mkan: id, from: currentCit || null, to: regionId, villageId });
    if (APPLY) {
      await patchDoc(idToken, `mkan/${id}`, {
        id_cit: ref(`cities/${regionId}`),
        promoted_independent_at: new Date().toISOString(),
      });
      await sleep(60);
    }
    n++;
  }
  return n;
}

async function main() {
  console.log(APPLY ? "APPLY mode" : "DRY-RUN mode");
  const idToken = await getIdToken();
  const report = {
    regions: [],
    villages: [],
    landmarks: [],
    hidden: [],
    duplicates: [],
  };

  // Promote / refresh each independent city card.
  for (const item of INDEPENDENT) {
    const existing = await getDoc(idToken, `cities/${item.regionId}`);
    let img = fieldString(existing, "img");
    if (item.restoreImgFromStaging) {
      const staged = loadStagingImg(item.regionId);
      if (staged) img = staged;
    }
    if (!img && item.imgFallback) img = item.imgFallback;

    const regionPayload = {
      naim: item.names.ar,
      names_i18n: item.names,
      dolh: ref(COUNTRY),
      acctev: true,
      sorting: item.sorting,
      lat_ling: geo(item.lat, item.lng),
      source_provider: "independent_city_cards",
      visibility_fixed_at: new Date().toISOString(),
    };
    if (img) regionPayload.img = img;

    console.log(
      `${APPLY ? "WRITE" : "WOULD_WRITE"} cities/${item.regionId} (${item.names.ar}) img=${img ? (img.startsWith("data:") ? `data:${img.length}` : "url") : "NONE"}`,
    );
    report.regions.push({
      id: item.regionId,
      name: item.names.ar,
      hadDoc: !!existing,
      imgRestored: !!item.restoreImgFromStaging && !!img,
    });
    if (APPLY) {
      await patchDoc(idToken, `cities/${item.regionId}`, regionPayload);
      await sleep(80);
    }

    const villagePayload = {
      naim: item.names.ar,
      names_i18n: item.names,
      cities: ref(`cities/${item.regionId}`),
      dolh: ref(COUNTRY),
      lat_ling: geo(item.lat, item.lng),
      acctev: true,
      sorting: 1,
      source_provider: "independent_city_cards",
      visibility_fixed_at: new Date().toISOString(),
    };
    if (img && !img.startsWith("data:")) villagePayload.img = img;

    console.log(
      `${APPLY ? "WRITE" : "WOULD_WRITE"} villages/${item.villageId} → ${item.regionId}`,
    );
    report.villages.push({
      id: item.villageId,
      parent: item.regionId,
    });
    if (APPLY) {
      await patchDoc(idToken, `villages/${item.villageId}`, villagePayload);
      await sleep(80);
    }

    for (const legacy of item.legacyVillageIds || []) {
      console.log(
        `${APPLY ? "HIDE" : "WOULD_HIDE"} villages/${legacy} (legacy duplicate)`,
      );
      report.duplicates.push(`villages/${legacy} → ${item.villageId}`);
      if (APPLY) {
        await patchDoc(idToken, `villages/${legacy}`, {
          ...villagePayload,
          acctev: false,
          superseded_by: item.villageId,
        });
        await sleep(60);
      }
    }

    const remapped = await remapLandmarksForVillage(
      idToken,
      item.villageId,
      item.regionId,
      report.landmarks,
    );
    console.log(`  landmarks remapped for ${item.villageId}: ${remapped}`);

    // Also remap landmarks still pointing at legacy village ids.
    for (const legacy of item.legacyVillageIds || []) {
      const remappedLegacy = await remapLandmarksForVillage(
        idToken,
        legacy,
        item.regionId,
        report.landmarks,
      );
      if (remappedLegacy) {
        console.log(
          `  landmarks remapped for legacy ${legacy}: ${remappedLegacy}`,
        );
      }
    }
  }

  // Hide empty province shells to avoid duplicate/empty cards.
  for (const id of HIDE_EMPTY_SHELLS) {
    const doc = await getDoc(idToken, `cities/${id}`);
    if (!doc) continue;
    console.log(`${APPLY ? "HIDE" : "WOULD_HIDE"} cities/${id}`);
    report.hidden.push(id);
    if (APPLY) {
      await patchDoc(idToken, `cities/${id}`, {
        acctev: false,
        superseded_by: id.includes("eastern")
          ? "region_sa_dammam"
          : id.includes("asir")
            ? "region_sa_abha"
            : id.replace("region_", "region_sa_").replace("region_sa_sa_", "region_sa_"),
        visibility_fixed_at: new Date().toISOString(),
      });
      await sleep(60);
    }
  }

  // Keep Madinah / Tabuk (and any other active SA regions) untouched except
  // ensure they stay active if already active — no writes needed.

  // Dedup report: active cities with same Arabic name.
  const activeCities = await runQuery(idToken, {
    from: [{ collectionId: "cities" }],
    where: {
      compositeFilter: {
        op: "AND",
        filters: [
          {
            fieldFilter: {
              field: { fieldPath: "dolh" },
              op: "EQUAL",
              value: {
                referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${COUNTRY}`,
              },
            },
          },
          {
            fieldFilter: {
              field: { fieldPath: "acctev" },
              op: "EQUAL",
              value: { booleanValue: true },
            },
          },
        ],
      },
    },
  });
  const byName = new Map();
  for (const row of activeCities) {
    const name = row.document?.name;
    if (!name) continue;
    const id = name.split("/").pop();
    const naim = row.document.fields?.naim?.stringValue || id;
    if (!byName.has(naim)) byName.set(naim, []);
    byName.get(naim).push(id);
  }
  for (const [naim, ids] of byName.entries()) {
    if (ids.length > 1) {
      report.duplicates.push(`ACTIVE_NAME_DUP "${naim}": ${ids.join(", ")}`);
      console.log(`DUP name "${naim}": ${ids.join(", ")}`);
    }
  }

  const out = path.join(__dirname, "promote_independent_sa_cities_report.json");
  fs.writeFileSync(out, JSON.stringify(report, null, 2));
  console.log("Report:", out);
  console.log("Done.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
