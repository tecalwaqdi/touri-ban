/**
 * Fix landmark Location so the CURRENT Play Store customer app shows them
 * in the city list (not only in search).
 *
 * Store builds still GPS-filter the list via SaudiCityRegistry bboxes.
 * Landmarks with id_vill=city_sa_taif but Location outside Taif bbox
 * appear in search (raw items) and disappear from the main list.
 *
 * Usage:
 *   node fix_landmark_list_visibility.js --dry-run
 *   node fix_landmark_list_visibility.js --apply
 *   node fix_landmark_list_visibility.js --apply --city=city_sa_taif
 */
const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const APPLY = process.argv.includes("--apply");
const CITY_ARG = (process.argv.find((a) => a.startsWith("--city=")) || "")
  .replace("--city=", "")
  .trim();

const BOXES = {
  taif: { lat: 21.2703, lng: 40.4158, minLat: 21.15, maxLat: 21.45, minLng: 40.25, maxLng: 40.62 },
  makkah: { lat: 21.4225, lng: 39.8262, minLat: 21.3, maxLat: 21.55, minLng: 39.72, maxLng: 40.02 },
  mecca: { lat: 21.4225, lng: 39.8262, minLat: 21.3, maxLat: 21.55, minLng: 39.72, maxLng: 40.02 },
  jeddah: { lat: 21.5433, lng: 39.1728, minLat: 21.45, maxLat: 21.78, minLng: 39.02, maxLng: 39.38 },
  madinah: { lat: 24.4686, lng: 39.6142, minLat: 24.38, maxLat: 24.58, minLng: 39.48, maxLng: 39.72 },
  medina: { lat: 24.4686, lng: 39.6142, minLat: 24.38, maxLat: 24.58, minLng: 39.48, maxLng: 39.72 },
  riyadh: { lat: 24.7136, lng: 46.6753, minLat: 24.45, maxLat: 25.05, minLng: 46.35, maxLng: 47.05 },
};

function slugFromVillageId(id) {
  let s = String(id || "").toLowerCase();
  if (s.startsWith("city_sa_")) s = s.slice("city_sa_".length);
  else if (s.startsWith("city_")) s = s.slice("city_".length);
  return s;
}

function boxForVillageId(id) {
  return BOXES[slugFromVillageId(id)] || null;
}

function distKm(a, b) {
  const p = 0.017453292519943295;
  const lat1 = a.lat * p;
  const lat2 = b.lat * p;
  const dLat = (b.lat - a.lat) * p;
  const dLng = (b.lng - a.lng) * p;
  const h =
    (1 - Math.cos(dLat)) / 4 +
    Math.cos(lat1) * Math.cos(lat2) * (1 - Math.cos(dLng)) / 4;
  return 12742 * Math.asin(Math.sqrt(Math.min(1, Math.max(0, h))));
}

function passes(box, lat, lng) {
  if (!box) return true;
  if (lat >= box.minLat && lat <= box.maxLat && lng >= box.minLng && lng <= box.maxLng) {
    return true;
  }
  return distKm({ lat, lng }, { lat: box.lat, lng: box.lng }) <= 12;
}

function canonicalVillageId(id) {
  const raw = String(id || "");
  if (raw === "city_alkhobar") return "city_sa_khobar";
  const m = /^city_(.+)$/i.exec(raw);
  if (!m) return raw;
  const slug = m[1].toLowerCase();
  if (slug.startsWith("sa_") || slug.startsWith("kg_") || slug.startsWith("uz_") || slug.startsWith("ru_")) {
    return raw;
  }
  const sa = new Set([
    "makkah", "mecca", "jeddah", "riyadh", "madinah", "medina", "dammam",
    "taif", "abha", "khobar", "jubail", "yanbu", "tabuk", "hail", "najran",
    "jazan", "buraidah", "khamis",
  ]);
  if (sa.has(slug)) return `city_sa_${slug === "mecca" ? "makkah" : slug === "medina" ? "madinah" : slug}`;
  return raw;
}

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
  const signed = await authRequest("signInWithPassword", {
    email: EMAIL,
    password: PASSWORD,
    returnSecureToken: true,
  });
  return signed.idToken;
}

function parseGeo(fields) {
  const loc = fields && fields.Location;
  if (!loc || !loc.geoPointValue) return null;
  return {
    lat: Number(loc.geoPointValue.latitude),
    lng: Number(loc.geoPointValue.longitude),
  };
}

function parseRefId(fields, key) {
  const v = fields && fields[key];
  if (!v || !v.referenceValue) return "";
  const parts = String(v.referenceValue).split("/");
  return parts[parts.length - 1] || "";
}

function parseBool(fields, key) {
  const v = fields && fields[key];
  if (!v) return false;
  if (typeof v.booleanValue === "boolean") return v.booleanValue;
  return false;
}

function parseString(fields, key) {
  const v = fields && fields[key];
  return v && v.stringValue != null ? String(v.stringValue) : "";
}

async function runQuery(token, body) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
  const json = await res.json();
  if (!Array.isArray(json)) {
    throw new Error(JSON.stringify(json));
  }
  return json.filter((r) => r.document).map((r) => r.document);
}

async function patchDoc(token, docPath, fields) {
  const name = `projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join("&");
  const res = await fetch(
    `https://firestore.googleapis.com/v1/${name}?${mask}`,
    {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ fields }),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message || JSON.stringify(json.error));
  return json;
}

async function getDoc(token, docPath) {
  const name = `projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
  const res = await fetch(`https://firestore.googleapis.com/v1/${name}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const json = await res.json();
  if (json.error) return null;
  return json;
}

function villageRefValue(villageId) {
  return {
    referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/villages/${villageId}`,
  };
}

async function main() {
  console.log(APPLY ? "MODE: APPLY" : "MODE: DRY-RUN");
  const token = await getIdToken();
  console.log("auth ok");

  const villageCache = new Map();
  async function villageCenter(villageId) {
    if (villageCache.has(villageId)) return villageCache.get(villageId);
    const doc = await getDoc(token, `villages/${villageId}`);
    let center = null;
    if (doc && doc.fields && doc.fields.lat_ling && doc.fields.lat_ling.geoPointValue) {
      center = {
        lat: Number(doc.fields.lat_ling.geoPointValue.latitude),
        lng: Number(doc.fields.lat_ling.geoPointValue.longitude),
      };
    }
    villageCache.set(villageId, center);
    return center;
  }

  const structuredQuery = {
    from: [{ collectionId: "mkan" }],
    where: {
      fieldFilter: {
        field: { fieldPath: "acctev" },
        op: "EQUAL",
        value: { booleanValue: true },
      },
    },
    limit: 2000,
  };

  const docs = await runQuery(token, { structuredQuery });
  console.log("active landmarks fetched:", docs.length);

  let scanned = 0;
  let needFix = 0;
  let fixed = 0;
  const samples = [];

  for (const doc of docs) {
    scanned += 1;
    const fields = doc.fields || {};
    const id = String(doc.name || "").split("/").pop();
    let villageId = parseRefId(fields, "id_vill");
    if (!villageId) continue;

    const canon = canonicalVillageId(villageId);
    if (CITY_ARG && canon !== CITY_ARG && villageId !== CITY_ARG) continue;

    const box = boxForVillageId(canon);
    if (!box && !CITY_ARG) continue; // only Saudi hubs need GPS fix

    const geo = parseGeo(fields);
    const villageNeedsCanon = canon !== villageId;
    const locBad = !geo || !passes(box, geo.lat, geo.lng);

    if (!locBad && !villageNeedsCanon) continue;

    needFix += 1;
    const vCenter = (await villageCenter(canon)) || { lat: box.lat, lng: box.lng };
    let next = vCenter;
    if (geo && passes(box, geo.lat, geo.lng)) next = geo;
    else if (vCenter && passes(box, vCenter.lat, vCenter.lng)) next = vCenter;
    else next = { lat: box.lat, lng: box.lng };

    const naim = parseString(fields, "naim");
    if (samples.length < 15) {
      samples.push({
        id,
        naim,
        villageId,
        canon,
        from: geo,
        to: next,
        villageNeedsCanon,
        locBad,
      });
    }

    if (!APPLY) continue;

    const patch = {
      Location: {
        geoPointValue: { latitude: next.lat, longitude: next.lng },
      },
    };
    if (villageNeedsCanon) {
      patch.id_vill = villageRefValue(canon);
    }
    // Ensure category exists for chip screens that whereIn(tsnef).
    if (!parseString(fields, "tsnef")) {
      patch.tsnef = { stringValue: "معالم سياحية" };
    }

    await patchDoc(token, `mkan/${id}`, patch);
    fixed += 1;
    if (fixed % 25 === 0) console.log("fixed", fixed);
  }

  console.log(JSON.stringify({ scanned, needFix, fixed, samples }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
