/**
 * Full geography audit + safe cleanup for regions/cities/landmarks.
 *
 * Hierarchy:
 *   countries → cities (regions/cards) → villages (cities) → mkan (landmarks)
 *
 * Safety:
 * - Never hard-deletes documents
 * - Soft-disables only confirmed duplicates (external id OR name+~100m+same city)
 * - Does not disable on name similarity alone
 * - Remaps wrong region/city refs to canonical parents
 * - Unifies Arabic names + sanitizes ar/en/ru/ky i18n
 *
 * Usage:
 *   node audit_and_clean_geography.js            # dry-run (default)
 *   node audit_and_clean_geography.js --apply    # write Firestore
 */
const fs = require("fs");
const path = require("path");

const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const APPLY = process.argv.includes("--apply");
const BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
  "/databases/(default)/documents";

const ARABIC_RE = /[\u0600-\u06FF]/
const NEAR_DEG = 0.0009; // ~100m

/** Legacy → canonical region/city maps (independent SA city cards). */
const REGION_CANON = {
  region_makkah: "region_sa_makkah",
  region_riyadh: "region_sa_riyadh",
  region_eastern: "region_sa_eastern",
  region_asir: "region_sa_asir",
  region_tabuk: "region_sa_tabuk",
};
const CITY_CANON = {
  city_makkah: "city_sa_makkah",
  city_jeddah: "city_sa_jeddah",
  city_taif: "city_sa_taif",
  city_riyadh: "city_sa_riyadh",
  city_dammam: "city_sa_dammam",
  city_alkhobar: "city_sa_khobar",
  city_khobar: "city_sa_khobar",
  city_abha: "city_sa_abha",
  city_tabuk: "city_sa_tabuk",
};
const CITY_OWN_REGION = {
  city_sa_makkah: "region_sa_makkah",
  city_sa_riyadh: "region_sa_riyadh",
  city_sa_jeddah: "region_sa_jeddah",
  city_sa_taif: "region_sa_taif",
  city_sa_dammam: "region_sa_dammam",
  city_sa_khobar: "region_sa_khobar",
  city_sa_abha: "region_sa_abha",
  city_sa_tabuk: "region_sa_tabuk",
};

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
  } catch (_) {
    const json = await authRequest("signUp", {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return { idToken: json.idToken, uid: json.localId };
  }
}

function decodeValue(raw) {
  if (!raw || typeof raw !== "object") return null;
  if ("nullValue" in raw) return null;
  if ("stringValue" in raw) return raw.stringValue;
  if ("booleanValue" in raw) return raw.booleanValue;
  if ("integerValue" in raw) return Number(raw.integerValue);
  if ("doubleValue" in raw) return Number(raw.doubleValue);
  if ("timestampValue" in raw) return raw.timestampValue;
  if ("referenceValue" in raw) {
    const full = raw.referenceValue;
    const idx = full.indexOf("/documents/");
    return idx >= 0 ? full.slice(idx + "/documents/".length) : full;
  }
  if ("geoPointValue" in raw) {
    return {
      lat: Number(raw.geoPointValue.latitude || 0),
      lng: Number(raw.geoPointValue.longitude || 0),
    };
  }
  if ("mapValue" in raw) {
    const out = {};
    const fields = raw.mapValue.fields || {};
    for (const [k, v] of Object.entries(fields)) out[k] = decodeValue(v);
    return out;
  }
  if ("arrayValue" in raw) {
    return (raw.arrayValue.values || []).map(decodeValue);
  }
  return null;
}

function decodeDoc(doc) {
  const id = doc.name.split("/").pop();
  const fields = {};
  for (const [k, v] of Object.entries(doc.fields || {})) {
    fields[k] = decodeValue(v);
  }
  return { id, path: doc.name, ...fields };
}

async function listCollection(idToken, collection) {
  const documents = [];
  let pageToken = "";
  do {
    const url = new URL(`${BASE}/${collection}`);
    url.searchParams.set("pageSize", "300");
    if (pageToken) url.searchParams.set("pageToken", pageToken);
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    if (!res.ok) {
      throw new Error(`${collection}: ${res.status} ${await res.text()}`);
    }
    const payload = await res.json();
    documents.push(...(payload.documents || []).map(decodeDoc));
    pageToken = payload.nextPageToken || "";
  } while (pageToken);
  return documents;
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

async function patchDoc(idToken, docPath, data) {
  const fields = {};
  const mask = [];
  for (const [k, v] of Object.entries(data)) {
    fields[k] = firestoreValue(v);
    mask.push(`updateMask.fieldPaths=${encodeURIComponent(k)}`);
  }
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}?` +
    mask.join("&");
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
    if (res.status === 403) return "protected";
    throw new Error(`PATCH ${docPath}: ${res.status} ${text}`);
  }
  return "ok";
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function idFromRef(value) {
  if (!value) return "";
  if (typeof value === "string") return value.split("/").pop() || value;
  return "";
}

function normalizeAr(input) {
  let s = String(input || "")
    .normalize("NFKC")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ة/g, "ه")
    .replace(/ى/g, "ي")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/[\u064B-\u065F\u0670]/g, "")
    .replace(/ـ/g, "")
    .replace(/[^\u0600-\u06FFa-zA-Z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
  if (s.startsWith("ال") && s.length > 3) s = s.slice(2);
  return s;
}

function normalizeEn(input) {
  return String(input || "")
    .normalize("NFKC")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function near(a, b) {
  if (!a || !b) return false;
  if (!Number.isFinite(a.lat) || !Number.isFinite(b.lat)) return false;
  if (a.lat === 0 && a.lng === 0) return false;
  return (
    Math.abs(a.lat - b.lat) <= NEAR_DEG && Math.abs(a.lng - b.lng) <= NEAR_DEG
  );
}

function osmStatic(lat, lng) {
  const la = Number(lat);
  const ln = Number(lng);
  if (!Number.isFinite(la) || !Number.isFinite(ln)) return "";
  return (
    "https://staticmap.openstreetmap.de/staticmap.php" +
    `?center=${la},${ln}&zoom=14&size=800x500&markers=${la},${ln},lightblue1`
  );
}

function isPlaceholderImage(url) {
  const u = String(url || "").trim().toLowerCase();
  if (!u) return true;
  if (u.startsWith("data:image")) return true;
  if (u.includes("flagcdn.com")) return true;
  return false;
}

function landmarkScore(lm) {
  let score = 0;
  if (String(lm.id).startsWith("curated_")) score += 100;
  if (String(lm.id).startsWith("lm_sa_") || String(lm.id).startsWith("lm_kg_"))
    score += 40;
  if (lm.acctev === true) score += 20;
  if (lm.img1) score += 10;
  if (lm.names_i18n?.en && !ARABIC_RE.test(lm.names_i18n.en)) score += 8;
  if (lm.names_i18n?.ru && !ARABIC_RE.test(lm.names_i18n.ru)) score += 5;
  if (lm.names_i18n?.ky && !ARABIC_RE.test(lm.names_i18n.ky)) score += 5;
  if (lm.wikidata_id || lm.source_osm_id || lm.geo_import_id) score += 15;
  score += Math.min(10, Number(lm.rate || 0) * 2);
  return score;
}

function loadCuratedOfficialNames() {
  const file = path.join(__dirname, "curated_landmarks_ready.json");
  const curated = JSON.parse(fs.readFileSync(file, "utf8"));
  const byId = new Map();
  const byKey = new Map();
  for (const lm of curated.landmarks || []) {
    byId.set(lm.id, lm);
    const key = `${normalizeAr(lm.names?.ar || "")}|${Number(lm.lat).toFixed(3)}|${Number(lm.lng).toFixed(3)}`;
    byKey.set(key, lm);
  }
  return { byId, byKey, curated };
}

function sanitizeI18n(names, official) {
  const next = { ...(names || {}) };
  const ar =
    (official?.names?.ar || next.ar || "").trim() ||
    String(names?.ar || "").trim();
  if (ar) next.ar = ar;
  for (const loc of ["en", "ru", "ky"]) {
    const preferred = (official?.names?.[loc] || "").trim();
    const current = String(next[loc] || "").trim();
    if (preferred) {
      next[loc] = preferred;
      continue;
    }
    if (!current || ARABIC_RE.test(current) || current === ar) {
      // leave empty rather than Arabic clone
      if (ARABIC_RE.test(current) || current === ar) next[loc] = "";
    }
  }
  return next;
}

/** Stable JSON for map compare (Firestore field order varies). */
function stableStringify(value) {
  if (value == null) return "null";
  if (typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) {
    return `[${value.map((v) => stableStringify(v)).join(",")}]`;
  }
  const keys = Object.keys(value).sort();
  return `{${keys
    .map((k) => `${JSON.stringify(k)}:${stableStringify(value[k])}`)
    .join(",")}}`;
}

function i18nMapsEqual(a, b) {
  return stableStringify(a || {}) === stableStringify(b || {});
}

function buildActions(data, curated) {
  const { countries, cities, villages, landmarks } = data;
  const villageById = new Map(villages.map((v) => [v.id, v]));
  const cityById = new Map(cities.map((c) => [c.id, c]));

  const report = {
    mode: APPLY ? "apply" : "dry-run",
    scannedAt: new Date().toISOString(),
    counts: {
      countries: countries.length,
      regions_cities: cities.length,
      villages: villages.length,
      landmarks: landmarks.length,
      landmarks_active: landmarks.filter((l) => l.acctev !== false).length,
    },
    regionSummary: [],
    duplicateClusters: [],
    wrongRegion: [],
    legacyIdRemaps: [],
    nameFixes: [],
    i18nFixes: [],
    duplicateImages: [],
    imageFixes: [],
    softDisable: [],
    villageParentFixes: [],
    notes: [],
  };

  // Region/city summary
  for (const region of cities.filter((c) => c.acctev !== false)) {
    const kids = villages.filter(
      (v) => idFromRef(v.cities) === region.id && v.acctev !== false,
    );
    const lms = landmarks.filter(
      (l) => idFromRef(l.id_cit) === region.id && l.acctev !== false,
    );
    report.regionSummary.push({
      id: region.id,
      name: region.naim || region.names_i18n?.ar || "",
      cities: kids.map((k) => ({ id: k.id, name: k.naim })),
      landmarkCount: lms.length,
    });
  }

  // Village parent fixes (city → own region card)
  for (const v of villages) {
    if (v.acctev === false) continue;
    const expectedRegion = CITY_OWN_REGION[v.id];
    if (!expectedRegion) continue;
    const currentParent = idFromRef(v.cities);
    if (currentParent && currentParent !== expectedRegion) {
      report.villageParentFixes.push({
        villageId: v.id,
        from: currentParent,
        to: expectedRegion,
        name: v.naim,
      });
    }
  }

  // Landmark wrong region / legacy remap
  const activeLandmarks = landmarks.filter((l) => l.acctev !== false);
  for (const lm of activeLandmarks) {
    let cityId = idFromRef(lm.id_vill);
    let regionId = idFromRef(lm.id_cit);
    const remappedCity = CITY_CANON[cityId];
    const remappedRegion = REGION_CANON[regionId];
    if (remappedCity || remappedRegion) {
      report.legacyIdRemaps.push({
        landmarkId: lm.id,
        name: lm.naim,
        cityFrom: cityId,
        cityTo: remappedCity || cityId,
        regionFrom: regionId,
        regionTo:
          remappedRegion ||
          CITY_OWN_REGION[remappedCity || cityId] ||
          regionId,
      });
      cityId = remappedCity || cityId;
      regionId = remappedRegion || CITY_OWN_REGION[cityId] || regionId;
    }

    const village = villageById.get(cityId);
    const expectedRegion =
      CITY_OWN_REGION[cityId] || idFromRef(village?.cities) || "";
    if (expectedRegion && regionId && expectedRegion !== regionId) {
      report.wrongRegion.push({
        landmarkId: lm.id,
        name: lm.naim,
        cityId,
        currentRegion: regionId,
        expectedRegion,
      });
    }
  }

  // Duplicate detection
  const clusters = [];
  const assigned = new Set();

  // By external identity first
  const byExt = new Map();
  for (const lm of activeLandmarks) {
    const keys = [
      lm.geo_import_id && `gid:${lm.geo_import_id}`,
      lm.geo_import_slug && `slug:${lm.geo_import_slug}`,
      lm.source_osm_id && `osm:${lm.source_osm_id}`,
      lm.wikidata_id && `wd:${lm.wikidata_id}`,
    ].filter(Boolean);
    for (const k of keys) {
      if (!byExt.has(k)) byExt.set(k, []);
      byExt.get(k).push(lm);
    }
  }
  for (const [key, group] of byExt.entries()) {
    const uniq = [...new Map(group.map((g) => [g.id, g])).values()];
    if (uniq.length < 2) continue;
    const sorted = uniq.sort((a, b) => landmarkScore(b) - landmarkScore(a));
    clusters.push({
      reason: `external_id:${key}`,
      keep: sorted[0].id,
      disable: sorted.slice(1).map((x) => x.id),
      names: sorted.map((x) => x.naim),
    });
    for (const x of sorted) assigned.add(x.id);
  }

  // By normalized name + proximity + same city
  for (let i = 0; i < activeLandmarks.length; i++) {
    const a = activeLandmarks[i];
    if (assigned.has(a.id)) continue;
    const group = [a];
    const aCity = CITY_CANON[idFromRef(a.id_vill)] || idFromRef(a.id_vill);
    const aName = normalizeAr(a.naim || a.names_i18n?.ar || "");
    const aEn = normalizeEn(a.names_i18n?.en || "");
    if (!aName && !aEn) continue;
    for (let j = i + 1; j < activeLandmarks.length; j++) {
      const b = activeLandmarks[j];
      if (assigned.has(b.id)) continue;
      const bCity = CITY_CANON[idFromRef(b.id_vill)] || idFromRef(b.id_vill);
      if (aCity && bCity && aCity !== bCity) continue;
      const bName = normalizeAr(b.naim || b.names_i18n?.ar || "");
      const bEn = normalizeEn(b.names_i18n?.en || "");
      const nameSame =
        (aName && bName && aName === bName) || (aEn && bEn && aEn === bEn);
      if (!nameSame) continue;
      if (!near(a.Location, b.Location)) continue; // require coords proximity
      group.push(b);
    }
    if (group.length < 2) continue;
    const sorted = group.sort((x, y) => landmarkScore(y) - landmarkScore(x));
    clusters.push({
      reason: "name_and_nearby_same_city",
      keep: sorted[0].id,
      disable: sorted.slice(1).map((x) => x.id),
      names: sorted.map((x) => x.naim),
      coords: sorted.map((x) => x.Location),
    });
    for (const x of sorted) assigned.add(x.id);
  }
  report.duplicateClusters = clusters;
  for (const c of clusters) {
    for (const id of c.disable) {
      report.softDisable.push({
        landmarkId: id,
        keep: c.keep,
        reason: c.reason,
      });
    }
  }

  // Duplicate images (same img1 on different active landmarks)
  const byImg = new Map();
  for (const lm of activeLandmarks) {
    const url = String(lm.img1 || "").trim();
    if (!url) continue;
    if (!byImg.has(url)) byImg.set(url, []);
    byImg.get(url).push(lm.id);
  }
  for (const [url, ids] of byImg.entries()) {
    if (ids.length < 2) continue;
    const related = ids.filter((id) =>
      clusters.some((c) => c.keep === id || c.disable.includes(id)),
    );
    report.duplicateImages.push({
      img1: url,
      landmarkIds: ids,
      likelyTrueDupCluster: related.length >= 2,
    });
  }

  const disableSet = new Set(report.softDisable.map((d) => d.landmarkId));
  const sharedImgIds = new Set(
    report.duplicateImages.flatMap((d) => d.landmarkIds || []),
  );

  // Official name + i18n + image fixes from curated + unify Arabic
  for (const lm of activeLandmarks) {
    if (disableSet.has(lm.id)) continue;
    const loc = lm.Location || {};
    const key = `${normalizeAr(lm.naim || "")}|${Number(loc.lat || 0).toFixed(3)}|${Number(loc.lng || 0).toFixed(3)}`;
    const official =
      curated.byId.get(lm.id) ||
      curated.byKey.get(key) ||
      null;
    const names = sanitizeI18n(lm.names_i18n || {}, official);
    const officialAr = (official?.names?.ar || names.ar || lm.naim || "").trim();
    if (officialAr && officialAr !== lm.naim) {
      report.nameFixes.push({
        landmarkId: lm.id,
        from: lm.naim,
        to: officialAr,
        source: official ? "curated_official" : "names_i18n.ar",
      });
    }
    const wantOsf = official?.descriptions?.ar || lm.osf || "";
    const wantOsfI18n = official?.descriptions || lm.osf_i18n || {};
    const needI18n =
      !i18nMapsEqual(names, lm.names_i18n || {}) ||
      (wantOsf && wantOsf !== (lm.osf || "")) ||
      (official?.descriptions && !i18nMapsEqual(wantOsfI18n, lm.osf_i18n || {}));
    if (needI18n || (officialAr && officialAr !== lm.naim)) {
      report.i18nFixes.push({
        landmarkId: lm.id,
        names,
        osf: wantOsf,
        osf_i18n: wantOsfI18n,
      });
    }

    const currentImg = String(lm.img1 || "").trim();
    let nextImg = "";
    let imgReason = "";
    if (official?.img1 && official.img1 !== currentImg) {
      nextImg = official.img1;
      imgReason = "curated_official_image";
    } else if (isPlaceholderImage(currentImg) && loc.lat != null) {
      nextImg = osmStatic(loc.lat, loc.lng);
      imgReason = "placeholder_to_osm_static";
    } else if (
      sharedImgIds.has(lm.id) &&
      !official?.img1 &&
      loc.lat != null &&
      currentImg
    ) {
      // Same photo reused across unrelated landmarks — give each a location map
      nextImg = osmStatic(loc.lat, loc.lng);
      imgReason = "shared_image_to_osm_static";
    }
    if (nextImg && nextImg !== currentImg) {
      report.imageFixes.push({
        landmarkId: lm.id,
        from: currentImg.slice(0, 120),
        to: nextImg,
        reason: imgReason,
      });
    }
  }

  report.notes.push(
    "Soft-disable only; no hard deletes.",
    "Name-only similarity without nearby coordinates is never treated as a duplicate.",
    "Image fixes prefer curated Wikimedia URLs; shared/placeholder images fall back to OSM static maps.",
    "Deploy/apply after reviewing dry-run report.",
  );
  return report;
}

async function applyReport(idToken, report, landmarks, villages) {
  const lmById = new Map(landmarks.map((l) => [l.id, l]));
  const results = { patched: 0, protected: 0, errors: [] };

  for (const fix of report.villageParentFixes) {
    try {
      const status = await patchDoc(idToken, `villages/${fix.villageId}`, {
        cities: ref(`cities/${fix.to}`),
        geography_cleaned_at: new Date().toISOString(),
      });
      if (status === "protected") results.protected++;
      else results.patched++;
      await sleep(60);
    } catch (e) {
      results.errors.push(String(e.message || e));
    }
  }

  for (const item of report.softDisable) {
    try {
      const status = await patchDoc(idToken, `mkan/${item.landmarkId}`, {
        acctev: false,
        superseded_by: ref(`mkan/${item.keep}`),
        deactivated_reason: `duplicate:${item.reason}`,
        geography_cleaned_at: new Date().toISOString(),
      });
      if (status === "protected") results.protected++;
      else results.patched++;
      await sleep(60);
    } catch (e) {
      results.errors.push(String(e.message || e));
    }
  }

  const remapById = new Map();
  for (const r of report.legacyIdRemaps) remapById.set(r.landmarkId, r);
  for (const w of report.wrongRegion) {
    const prev = remapById.get(w.landmarkId) || {
      landmarkId: w.landmarkId,
      cityTo: w.cityId,
    };
    prev.regionTo = w.expectedRegion;
    prev.cityTo = prev.cityTo || w.cityId;
    remapById.set(w.landmarkId, prev);
  }

  for (const r of remapById.values()) {
    const payload = {
      geography_cleaned_at: new Date().toISOString(),
    };
    if (r.cityTo) payload.id_vill = ref(`villages/${r.cityTo}`);
    if (r.regionTo) payload.id_cit = ref(`cities/${r.regionTo}`);
    // country stays if known from village
    try {
      const status = await patchDoc(idToken, `mkan/${r.landmarkId}`, payload);
      if (status === "protected") results.protected++;
      else results.patched++;
      await sleep(60);
    } catch (e) {
      results.errors.push(String(e.message || e));
    }
  }

  for (const fix of report.i18nFixes) {
    if (report.softDisable.some((d) => d.landmarkId === fix.landmarkId)) {
      continue; // no need to polish disabled dupes
    }
    const lm = lmById.get(fix.landmarkId);
    const payload = {
      naim: fix.names.ar || lm?.naim || "",
      names_i18n: fix.names,
      geography_cleaned_at: new Date().toISOString(),
    };
    if (fix.osf) payload.osf = fix.osf;
    if (fix.osf_i18n && Object.keys(fix.osf_i18n).length) {
      payload.osf_i18n = fix.osf_i18n;
    }
    try {
      const status = await patchDoc(idToken, `mkan/${fix.landmarkId}`, payload);
      if (status === "protected") results.protected++;
      else results.patched++;
      await sleep(60);
    } catch (e) {
      results.errors.push(String(e.message || e));
    }
  }

  for (const fix of report.imageFixes || []) {
    if (report.softDisable.some((d) => d.landmarkId === fix.landmarkId)) {
      continue;
    }
    try {
      const status = await patchDoc(idToken, `mkan/${fix.landmarkId}`, {
        img1: fix.to,
        geography_cleaned_at: new Date().toISOString(),
      });
      if (status === "protected") results.protected++;
      else results.patched++;
      await sleep(60);
    } catch (e) {
      results.errors.push(String(e.message || e));
    }
  }

  return results;
}

async function main() {
  console.log(APPLY ? "=== APPLY MODE ===" : "=== DRY-RUN MODE ===");
  const { idToken, uid } = await getIdToken();
  console.log("Auth OK", uid);

  // Best-effort elevate for writes
  if (APPLY) {
    await patchDoc(idToken, `user/${uid}`, {
      email: EMAIL,
      display_name: "Geography Cleaner",
      uid,
      actev_user: true,
      IsAdmin: true,
      isAdminRule: 1,
      created_time: new Date(),
    });
  }

  console.log("Listing collections...");
  const [countries, cities, villages, landmarks] = await Promise.all([
    listCollection(idToken, "countries"),
    listCollection(idToken, "cities"),
    listCollection(idToken, "villages"),
    listCollection(idToken, "mkan"),
  ]);
  console.log(
    `countries=${countries.length} cities=${cities.length} villages=${villages.length} mkan=${landmarks.length}`,
  );

  const curated = loadCuratedOfficialNames();
  const report = buildActions(
    { countries, cities, villages, landmarks },
    curated,
  );

  const outPath = path.join(
    __dirname,
    APPLY
      ? "audit_and_clean_geography_apply_report.json"
      : "audit_and_clean_geography_dryrun_report.json",
  );

  if (APPLY) {
    console.log("Applying safe patches...");
    report.applyResults = await applyReport(
      idToken,
      report,
      landmarks,
      villages,
    );

    // Re-scan active landmarks for remaining confirmed dups
    const refreshed = await listCollection(idToken, "mkan");
    const second = buildActions(
      { countries, cities, villages, landmarks: refreshed },
      curated,
    );
    report.recheck = {
      activeLandmarks: second.counts.landmarks_active,
      remainingDuplicateClusters: second.duplicateClusters.length,
      remainingWrongRegion: second.wrongRegion.length,
      remainingLegacyRemaps: second.legacyIdRemaps.length,
      remainingImageFixes: second.imageFixes.length,
      remainingDuplicateImageGroups: second.duplicateImages.length,
      remainingI18nFixes: second.i18nFixes.length,
    };
  }

  fs.writeFileSync(outPath, JSON.stringify(report, null, 2), "utf8");
  console.log("Wrote", outPath);
  console.log(
    JSON.stringify(
      {
        counts: report.counts,
        duplicateClusters: report.duplicateClusters.length,
        softDisable: report.softDisable.length,
        wrongRegion: report.wrongRegion.length,
        legacyIdRemaps: report.legacyIdRemaps.length,
        nameFixes: report.nameFixes.length,
        i18nFixes: report.i18nFixes.length,
        imageFixes: (report.imageFixes || []).length,
        villageParentFixes: report.villageParentFixes.length,
        duplicateImages: report.duplicateImages.length,
        recheck: report.recheck || null,
        applyResults: report.applyResults || null,
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
