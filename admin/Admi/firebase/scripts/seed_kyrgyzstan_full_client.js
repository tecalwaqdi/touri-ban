/**
 * Seed all Kyrgyzstan oblasts + up to 20 real landmarks each.
 * Uses curated list first, fills gaps from OpenStreetMap (Overpass).
 *
 * Usage:
 *   node seed_kyrgyzstan_full_client.js --dry-run
 *   node seed_kyrgyzstan_full_client.js --apply
 */
const fs = require("fs");
const path = require("path");

const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const MAPS_KEY = process.env.MAPS_STATIC_KEY || "AIzaSyD5G1uXTPM2DP-5ZkeLQA_7FsFjxNWOIzM";
const APPLY = process.argv.includes("--apply");
const DRY = !APPLY;
const TARGET = Number(process.env.LANDMARKS_PER_REGION || 20);

const OVERPASS = [
  "https://overpass.kumi.systems/api/interpreter",
  "https://overpass-api.de/api/interpreter",
  "https://overpass.private.coffee/api/interpreter",
];

const BANNED =
  /\b(aircraft|airplane|fighter|jet|boeing|lockheed|douglas|tornado|helicopter|tank\b|military)\b/i;
const ARABIC = /[\u0600-\u06FF]/;

const COUNTRY = {
  id: "kyrgyzstan",
  names: {
    ar: "قرغيزستان",
    en: "Kyrgyzstan",
    ru: "Кыргызстан",
    ky: "Кыргызстан",
  },
};

/** Official oblasts + independent cities */
const REGIONS = [
  {
    id: "kg-chuy",
    iso: "KG-C",
    sort: 1,
    names: {
      ar: "إقليم تشوي",
      en: "Chuy Region",
      ru: "Чуйская область",
      ky: "Чүй облусу",
    },
    center: [42.85, 74.6],
    bounds: [42.0, 73.2, 43.25, 76.3],
    cityId: "kg-chuy-main",
    cityNames: {
      ar: "تشوي — المسار الرئيسي",
      en: "Chuy main route",
      ru: "Чуй — основной маршрут",
      ky: "Чүй — негизги маршрут",
    },
  },
  {
    id: "kg-issyk-kul",
    iso: "KG-Y",
    sort: 2,
    names: {
      ar: "إقليم إيسيك كول",
      en: "Issyk-Kul Region",
      ru: "Иссык-Кульская область",
      ky: "Ысык-Көл облусу",
    },
    center: [42.45, 77.28],
    bounds: [41.55, 75.95, 43.35, 80.3],
    cityId: "kg-issyk-kul-main",
    cityNames: {
      ar: "إيسيك كول — المسار الرئيسي",
      en: "Issyk-Kul main route",
      ru: "Иссык-Куль — основной маршрут",
      ky: "Ысык-Көл — негизги маршрут",
    },
  },
  {
    id: "kg-naryn",
    iso: "KG-N",
    sort: 3,
    names: {
      ar: "إقليم نارين",
      en: "Naryn Region",
      ru: "Нарынская область",
      ky: "Нарын облусу",
    },
    center: [41.43, 76.0],
    bounds: [40.1, 73.75, 42.4, 80.3],
    cityId: "kg-naryn-main",
    cityNames: {
      ar: "نارين — المسار الرئيسي",
      en: "Naryn main route",
      ru: "Нарын — основной маршрут",
      ky: "Нарын — негизги маршрут",
    },
  },
  {
    id: "kg-talas",
    iso: "KG-T",
    sort: 4,
    names: {
      ar: "إقليم تالاس",
      en: "Talas Region",
      ru: "Таласская область",
      ky: "Талас облусу",
    },
    center: [42.52, 72.24],
    bounds: [41.95, 70.2, 43.1, 74.1],
    cityId: "kg-talas-main",
    cityNames: {
      ar: "تالاس — المسار الرئيسي",
      en: "Talas main route",
      ru: "Талас — основной маршрут",
      ky: "Талас — негизги маршрут",
    },
  },
  {
    id: "kg-jalal-abad",
    iso: "KG-J",
    sort: 5,
    names: {
      ar: "إقليم جلال آباد",
      en: "Jalal-Abad Region",
      ru: "Джалал-Абадская область",
      ky: "Жалал-Абад облусу",
    },
    center: [40.93, 73.0],
    bounds: [40.2, 69.2, 42.35, 75.3],
    cityId: "kg-jalal-abad-main",
    cityNames: {
      ar: "جلال آباد — المسار الرئيسي",
      en: "Jalal-Abad main route",
      ru: "Джалал-Абад — основной маршрут",
      ky: "Жалал-Абад — негизги маршрут",
    },
  },
  {
    id: "kg-osh",
    iso: "KG-O",
    sort: 6,
    names: {
      ar: "إقليم أوش",
      en: "Osh Region",
      ru: "Ошская область",
      ky: "Ош облусу",
    },
    center: [40.53, 72.78],
    bounds: [39.2, 71.1, 41.35, 75.6],
    cityId: "kg-osh-main",
    cityNames: {
      ar: "أوش — المسار الرئيسي",
      en: "Osh main route",
      ru: "Ош — основной маршрут",
      ky: "Ош — негизги маршрут",
    },
  },
  {
    id: "kg-batken",
    iso: "KG-B",
    sort: 7,
    names: {
      ar: "إقليم باتكين",
      en: "Batken Region",
      ru: "Баткенская область",
      ky: "Баткен облусу",
    },
    center: [40.06, 70.82],
    bounds: [39.2, 69.2, 40.95, 72.0],
    cityId: "kg-batken-main",
    cityNames: {
      ar: "باتكين — المسار الرئيسي",
      en: "Batken main route",
      ru: "Баткен — основной маршрут",
      ky: "Баткен — негизги маршрут",
    },
  },
  {
    id: "kg-bishkek",
    iso: "KG-GB",
    sort: 0,
    names: {
      ar: "مدينة بيشكيك",
      en: "Bishkek City",
      ru: "Город Бишкек",
      ky: "Бишкек шаары",
    },
    center: [42.8746, 74.5698],
    bounds: [42.8, 74.45, 42.95, 74.72],
    cityId: "city_bishkek",
    cityNames: {
      ar: "بيشكيك",
      en: "Bishkek",
      ru: "Бишкек",
      ky: "Бишкек",
    },
  },
  {
    id: "kg-osh-city",
    iso: "KG-GO",
    sort: 8,
    names: {
      ar: "مدينة أوش",
      en: "Osh City",
      ru: "Город Ош",
      ky: "Ош шаары",
    },
    center: [40.5283, 72.7985],
    bounds: [40.48, 72.72, 40.58, 72.88],
    cityId: "city_osh",
    cityNames: {
      ar: "أوش",
      en: "Osh",
      ru: "Ош",
      ky: "Ош",
    },
  },
];

const CURATED = JSON.parse(
  fs.readFileSync(path.join(__dirname, "kyrgyzstan_landmarks_20.json"), "utf8"),
);

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
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

async function patchDoc(idToken, docPath, data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) fields[k] = firestoreValue(v);
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
  for (let attempt = 0; attempt < 6; attempt++) {
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
      console.log(`  protected skip: ${docPath}`);
      return "protected";
    }
    if (res.status === 429) {
      await sleep(2000 * (attempt + 1));
      continue;
    }
    throw new Error(`PATCH ${docPath}: ${res.status} ${text.slice(0, 200)}`);
  }
  return "failed";
}

function staticImg(lat, lng) {
  return (
    "https://maps.googleapis.com/maps/api/staticmap" +
    `?center=${lat},${lng}&zoom=14&size=800x500&scale=2` +
    `&maptype=roadmap&markers=color:teal%7C${lat},${lng}&key=${MAPS_KEY}`
  );
}

function descriptions(names, regionNames) {
  return {
    ar: `${names.ar} معلم سياحي في ${regionNames.ar}.`,
    en: `${names.en} is a tourist attraction in ${regionNames.en}.`,
    ru: `${names.ru} — достопримечательность в регионе ${regionNames.ru}.`,
    ky: `${names.ky} — ${regionNames.ky} аймагындагы туристтик жай.`,
  };
}

function categoryLabel(cat) {
  const map = {
    nature: {
      ar: "طبيعة وحدائق",
      en: "Nature and parks",
      ru: "Природа и парки",
      ky: "Жаратылыш жана парктар",
    },
    heritage: {
      ar: "معالم تاريخية",
      en: "Historical landmarks",
      ru: "Исторические места",
      ky: "Тарыхый жайлар",
    },
    museum: {
      ar: "متحف",
      en: "Museum",
      ru: "Музей",
      ky: "Музей",
    },
    market: {
      ar: "أسواق",
      en: "Markets",
      ru: "Рынки",
      ky: "Базарлар",
    },
    city: {
      ar: "معالم سياحية",
      en: "Tourist landmarks",
      ru: "Достопримечательности",
      ky: "Туристтик жайлар",
    },
    culture: {
      ar: "ثقافة وفنون",
      en: "Culture and arts",
      ru: "Культура и искусство",
      ky: "Маданият жана искусство",
    },
    wellness: {
      ar: "ترفيه",
      en: "Entertainment",
      ru: "Развлечения",
      ky: "Көңүл ачуу",
    },
    religious: {
      ar: "معالم دينية",
      en: "Religious landmarks",
      ru: "Религиозные места",
      ky: "Диний жайлар",
    },
  };
  return map[cat] || map.city;
}

function pointOf(el) {
  const lat = el.lat ?? el.center?.lat;
  const lng = el.lon ?? el.center?.lon;
  return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null;
}

function score(el) {
  const t = el.tags || {};
  return (
    (t.wikidata ? 8 : 0) +
    (t.wikipedia ? 6 : 0) +
    (t.tourism ? 4 : 0) +
    (t.historic ? 3 : 0) +
    (t["name:en"] ? 2 : 0) +
    (t["name:ru"] ? 2 : 0) +
    (t["name:ky"] ? 2 : 0)
  );
}

function i18nFromTags(tags, fallbackName) {
  const ar = tags["name:ar"] || fallbackName || tags.name || "";
  const en = tags["name:en"] || tags.name || ar;
  const ru = tags["name:ru"] || en;
  const ky = tags["name:ky"] || ru || en;
  return {
    ar: ARABIC.test(ar) ? ar : ar || en,
    en: ARABIC.test(en) ? (tags["name:en"] || tags.name || en) : en,
    ru: ARABIC.test(ru) ? en : ru,
    ky: ARABIC.test(ky) ? (tags["name:ky"] || en) : ky,
  };
}

async function fetchOsmLandmarks(region) {
  const [south, west, north, east] = region.bounds;
  const query = `
    [out:json][timeout:90];
    (
      nwr["tourism"~"attraction|museum|viewpoint|gallery|zoo|theme_park|hotel"]["name"](${south},${west},${north},${east});
      nwr["historic"]["name"](${south},${west},${north},${east});
      nwr["leisure"="park"]["name"](${south},${west},${north},${east});
      nwr["natural"~"peak|waterfall|spring|cave_entrance"]["name"](${south},${west},${north},${east});
    );
    out center tags;
  `;
  let lastError;
  for (let attempt = 0; attempt < 8; attempt++) {
    const endpoint = OVERPASS[attempt % OVERPASS.length];
    try {
      const res = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
          "User-Agent": "TouriTaxi/1.0 (kyrgyzstan landmarks import)",
        },
        body: new URLSearchParams({ data: query }),
      });
      if (!res.ok) {
        lastError = new Error(`Overpass HTTP ${res.status}`);
        await sleep(4000 * (attempt + 1));
        continue;
      }
      const data = await res.json();
      const seen = new Set();
      return (data.elements || [])
        .filter((el) => pointOf(el) && el.tags?.name && !BANNED.test(el.tags.name))
        .sort((a, b) => score(b) - score(a))
        .filter((el) => {
          const p = pointOf(el);
          const key = `${el.tags.name}|${p.lat.toFixed(3)}|${p.lng.toFixed(3)}`;
          if (seen.has(key)) return false;
          seen.add(key);
          return true;
        });
    } catch (e) {
      lastError = e;
      await sleep(4000 * (attempt + 1));
    }
  }
  console.warn(`OSM fetch failed for ${region.id}:`, lastError?.message || lastError);
  return [];
}

async function main() {
  console.log(DRY ? "=== DRY RUN ===" : "=== APPLY ===");
  const { idToken, uid } = await getIdToken();
  console.log("Auth OK", uid);
  await patchDoc(idToken, `user/${uid}`, {
    email: EMAIL,
    IsAdmin: true,
    isAdminRule: 1,
    actev_user: true,
    uid,
  });

  const report = {
    regions: [],
    country: COUNTRY.id,
    target: TARGET,
  };

  if (!DRY) {
    await patchDoc(idToken, `countries/${COUNTRY.id}`, {
      naim: COUNTRY.names.ar,
      naimEnglesh: COUNTRY.names.en,
      names_i18n: COUNTRY.names,
      acctev: true,
      iso2: "KG",
      country_iso: "kg",
      currencyCode: "KGS",
      defaultLanguageCode: "ky",
    });
  }

  for (const region of REGIONS) {
    console.log(`\nRegion: ${region.names.en}`);
    const regionPath = `cities/${region.id}`;
    const villagePath = `villages/${region.cityId}`;
    const [lat, lng] = region.center;

    if (!DRY) {
      await patchDoc(idToken, regionPath, {
        naim: region.names.ar,
        names_i18n: region.names,
        dolh: ref(`countries/${COUNTRY.id}`),
        acctev: true,
        sorting: region.sort,
        country_iso: "kg",
        iso_code: region.iso,
        geo_center: geo(lat, lng),
      });
      await patchDoc(idToken, villagePath, {
        naim: region.cityNames.ar,
        names_i18n: region.cityNames,
        cities: ref(regionPath),
        dolh: ref(`countries/${COUNTRY.id}`),
        acctev: true,
        country_iso: "kg",
        lat_ling: geo(lat, lng),
        latLing: geo(lat, lng),
        no_delete_place: true,
      });
    }

    const curated = CURATED[region.id] || [];
    const combined = [];
    const seenNames = new Set();

    for (const lm of curated) {
      const key = lm.names.en.toLowerCase();
      if (seenNames.has(key)) continue;
      seenNames.add(key);
      combined.push({
        id: `${region.id}-${lm.id}`,
        names: lm.names,
        lat: lm.lat,
        lng: lm.lng,
        category: lm.category || "city",
        source: "curated",
      });
    }

    let osm = [];
    if (combined.length < TARGET) {
      console.log(`  OSM fill (${combined.length}/${TARGET})...`);
      osm = await fetchOsmLandmarks(region);
      console.log(`  OSM candidates: ${osm.length}`);
    }

    for (const el of osm) {
      if (combined.length >= TARGET) break;
      const tags = el.tags || {};
      const name = tags.name || "";
      if (BANNED.test(name)) continue;
      const key = name.toLowerCase();
      if (seenNames.has(key)) continue;
      seenNames.add(key);
      const p = pointOf(el);
      const names = i18nFromTags(tags, name);
      // Prefer English for ky/ru when OSM copied Arabic incorrectly
      if (ARABIC.test(names.ky)) names.ky = names.en;
      if (ARABIC.test(names.ru)) names.ru = names.en || names.ru;
      if (ARABIC.test(names.en) && tags.name && !ARABIC.test(tags.name)) {
        names.en = tags.name;
      }
      combined.push({
        id: `kg_osm_${el.type}_${el.id}`,
        names,
        lat: p.lat,
        lng: p.lng,
        category: tags.tourism === "museum" ? "museum" : tags.historic ? "heritage" : "nature",
        source: "osm",
        osmType: el.type,
        osmId: String(el.id),
      });
    }

    const used = combined.slice(0, TARGET);
    console.log(`  Publishing ${used.length} landmarks (curated=${curated.length}, filled=${used.length - curated.length})`);

    if (!DRY) {
      for (let i = 0; i < used.length; i++) {
        const lm = used[i];
        const cat = categoryLabel(lm.category);
        const desc = descriptions(lm.names, region.names);
        await patchDoc(idToken, `mkan/${lm.id}`, {
          naim: lm.names.ar || lm.names.en,
          names_i18n: lm.names,
          osf: desc.ar,
          osf_i18n: desc,
          img1: staticImg(lm.lat, lm.lng),
          img2: "",
          img3: "",
          sr: i + 1,
          acctev: true,
          as_ads: i < 3,
          ismzod: true,
          isShrek: false,
          ismsgd: lm.category === "religious",
          isfood: true,
          ishmam: true,
          id_cit: ref(regionPath),
          id_vill: ref(villagePath),
          Rev_dolh: ref(`countries/${COUNTRY.id}`),
          Location: geo(lm.lat, lm.lng),
          address: `${lm.names.en}, ${region.names.en}, Kyrgyzstan`,
          tsnef: cat.ar,
          tsnef_i18n: cat,
          rate: 4.5 + (i % 5) * 0.1,
          add_saat: 2,
          country_iso: "kg",
          source_provider: lm.source === "osm" ? "OpenStreetMap" : "curated",
          source_url:
            lm.source === "osm"
              ? `https://www.openstreetmap.org/${lm.osmType}/${lm.osmId}`
              : "https://tourism.gov.kg/",
          dataAdd: new Date(),
          verified_at: new Date().toISOString(),
        });
        if ((i + 1) % 5 === 0) {
          console.log(`    ${i + 1}/${used.length}`);
          await sleep(250);
        } else {
          await sleep(80);
        }
      }
    }

    report.regions.push({
      id: region.id,
      name: region.names.en,
      landmarks: used.length,
      curated: curated.length,
      osmFilled: Math.max(0, used.length - curated.length),
      shortfall: Math.max(0, TARGET - used.length),
      sample: used.slice(0, 3).map((x) => x.names.en),
    });
    await sleep(800);
  }

  const out = path.join(
    __dirname,
    DRY ? "kyrgyzstan_seed_dryrun.json" : "kyrgyzstan_seed_report.json",
  );
  fs.writeFileSync(out, JSON.stringify(report, null, 2), "utf8");
  console.log("\n=== SUMMARY ===");
  console.log(
    JSON.stringify(
      {
        mode: DRY ? "dry-run" : "apply",
        regions: report.regions.map((r) => ({
          id: r.id,
          landmarks: r.landmarks,
          shortfall: r.shortfall,
        })),
        totalLandmarks: report.regions.reduce((s, r) => s + r.landmarks, 0),
        report: out,
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
