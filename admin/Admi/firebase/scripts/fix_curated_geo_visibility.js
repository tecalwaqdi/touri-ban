/**
 * Make all curated Saudi regions/cities/landmarks visible in ara_oatan_app.
 *
 * App needs:
 * - cities.dolh → countries/saudi_arabia, acctev=true (prefer region_sa_*)
 * - villages.cities → region_sa_*, villages.lat_ling, acctev=true (prefer city_sa_*)
 * - mkan.id_vill → villages/city_sa_* (app remaps city_makkah → city_sa_makkah)
 *
 * Usage: node fix_curated_geo_visibility.js --apply
 */
const fs = require("fs");
const path = require("path");

const API_KEY = "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const APPLY = process.argv.includes("--apply");

const REGION_MAP = {
  region_makkah: "region_sa_makkah",
  region_riyadh: "region_sa_riyadh",
  region_eastern: "region_sa_eastern",
  region_asir: "region_sa_asir",
  region_tabuk: "region_sa_tabuk",
};

const REGION_SORT = {
  region_makkah: 10,
  region_riyadh: 20,
  region_eastern: 30,
  region_asir: 40,
  region_tabuk: 50,
};

const CITY_MAP = {
  city_makkah: "city_sa_makkah",
  city_jeddah: "city_sa_jeddah",
  city_taif: "city_sa_taif",
  city_riyadh: "city_sa_riyadh",
  city_dammam: "city_sa_dammam",
  city_alkhobar: "city_sa_khobar",
  city_abha: "city_sa_abha",
  city_tabuk: "city_sa_tabuk",
};

/**
 * Independent city cards on Citie2 — village parent is its own region_sa_* doc
 * (not Makkah / Eastern / Asir province shells).
 * Keep in sync with promote_independent_sa_cities.js.
 */
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
  const mask = [];
  for (const [k, v] of Object.entries(data)) {
    fields[k] = firestoreValue(v);
    mask.push(`updateMask.fieldPaths=${encodeURIComponent(k)}`);
  }
  // Always send updateMask so unset fields (e.g. saudi/img) are not wiped.
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
    throw new Error(`PATCH ${docPath}: ${res.status} ${await res.text()}`);
  }
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  const curated = JSON.parse(
    fs.readFileSync(path.join(__dirname, "curated_landmarks_ready.json"), "utf8"),
  );

  const regions = (curated.regions || []).filter((r) => REGION_MAP[r.id]);
  const landmarks = (curated.landmarks || []).filter(
    (lm) => CITY_MAP[lm.cityId] && REGION_MAP[lm.regionId],
  );

  console.log(
    APPLY ? "APPLY mode" : "DRY-RUN mode",
    `| regions=${regions.length} landmarks=${landmarks.length}`,
  );

  let idToken = null;
  if (APPLY) idToken = await getIdToken();

  // Country must stay featured (aldol queries saudi == true).
  console.log(`${APPLY ? "WRITE" : "WOULD_WRITE"} countries/saudi_arabia`);
  if (APPLY) {
    await patchDoc(idToken, "countries/saudi_arabia", {
      naim: "المملكة العربية السعودية",
      naimEnglesh: "Saudi Arabia",
      names_i18n: {
        ar: "المملكة العربية السعودية",
        en: "Saudi Arabia",
        ru: "Саудовская Аравия",
        ky: "Сауд Арабиясы",
      },
      osf: "المملكة العربية السعودية — وجهة الحج والعمرة والسياحة في مدنها الرئيسية.",
      img: "https://flagcdn.com/w320/sa.png",
      hederImg: "https://flagcdn.com/w1280/sa.png",
      iso_code: "SA",
      iso2: "SA",
      CurrencySymbol: "ر.س",
      currency_code: "SAR",
      acctev: true,
      saudi: true,
      num_trteb: 1,
      geo_center: geo(24.7136, 46.6753),
    });
    await sleep(80);
  }

  for (const region of regions) {
    const canonicalRegionId = REGION_MAP[region.id];
    const sort = REGION_SORT[region.id] ?? 99;
    // Province shells that were split into independent city cards stay hidden.
    const hideProvinceShell =
      canonicalRegionId === "region_sa_eastern" ||
      canonicalRegionId === "region_sa_asir";
    const regionPayload = {
      naim: region.names.ar,
      names_i18n: region.names,
      dolh: ref(`countries/${region.countryId}`),
      acctev: !hideProvinceShell,
      sorting: sort,
      source_provider: "curated",
      visibility_fixed_at: new Date().toISOString(),
    };

    // Skip writing province label over city-hub cards (Makkah/Riyadh).
    // Independent city cards are written in the city loop below.
    const isCityHubCard = (region.cities || []).some((c) => {
      const cid = CITY_MAP[c.id];
      return cid && CITY_OWN_REGION[cid] === canonicalRegionId;
    });
    if (!hideProvinceShell && !isCityHubCard) {
      console.log(
        `${APPLY ? "WRITE" : "WOULD_WRITE"} cities/${canonicalRegionId}`,
      );
      if (APPLY) {
        await patchDoc(idToken, `cities/${canonicalRegionId}`, regionPayload);
        await sleep(100);
      }
    } else if (hideProvinceShell) {
      console.log(
        `${APPLY ? "WRITE" : "WOULD_WRITE"} cities/${canonicalRegionId} (hidden province shell)`,
      );
      if (APPLY) {
        await patchDoc(idToken, `cities/${canonicalRegionId}`, regionPayload);
        await sleep(100);
      }
    } else {
      console.log(
        `SKIP province label cities/${canonicalRegionId} (managed as city card)`,
      );
    }

    // Hide legacy duplicate so the list shows one ordered region only.
    console.log(
      `${APPLY ? "HIDE" : "WOULD_HIDE"} cities/${region.id} (legacy)`,
    );
    if (APPLY) {
      await patchDoc(idToken, `cities/${region.id}`, {
        ...regionPayload,
        acctev: false,
        superseded_by: canonicalRegionId,
      });
      await sleep(100);
    }

    for (const city of region.cities || []) {
      const canonicalCityId = CITY_MAP[city.id];
      if (!canonicalCityId) continue;
      const ownRegionId =
        CITY_OWN_REGION[canonicalCityId] || canonicalRegionId;

      // Ensure independent city card exists for Citie2.
      if (ownRegionId !== canonicalRegionId || !hideProvinceShell) {
        const cityCardPayload = {
          naim: city.names.ar,
          names_i18n: city.names,
          dolh: ref(`countries/${region.countryId}`),
          acctev: true,
          sorting:
            {
              city_sa_makkah: 10,
              city_sa_riyadh: 20,
              city_sa_jeddah: 30,
              city_sa_taif: 40,
              city_sa_dammam: 50,
              city_sa_khobar: 60,
              city_sa_abha: 70,
              city_sa_tabuk: 80,
            }[canonicalCityId] || sort,
          lat_ling: geo(city.lat, city.lng),
          source_provider: "curated",
          visibility_fixed_at: new Date().toISOString(),
        };
        console.log(
          `${APPLY ? "WRITE" : "WOULD_WRITE"} cities/${ownRegionId} (city card)`,
        );
        if (APPLY) {
          await patchDoc(idToken, `cities/${ownRegionId}`, cityCardPayload);
          await sleep(80);
        }
      }

      const villagePayload = {
        naim: city.names.ar,
        names_i18n: city.names,
        cities: ref(`cities/${ownRegionId}`),
        dolh: ref(`countries/${region.countryId}`),
        lat_ling: geo(city.lat, city.lng),
        acctev: true,
        sorting: city.sortOrder || 1,
        source_provider: "curated",
        visibility_fixed_at: new Date().toISOString(),
      };

      console.log(
        `${APPLY ? "WRITE" : "WOULD_WRITE"} villages/${canonicalCityId} → ${ownRegionId}`,
      );
      if (APPLY) {
        await patchDoc(idToken, `villages/${canonicalCityId}`, villagePayload);
        await sleep(100);
      }

      console.log(
        `${APPLY ? "HIDE" : "WOULD_HIDE"} villages/${city.id} (legacy)`,
      );
      if (APPLY) {
        await patchDoc(idToken, `villages/${city.id}`, {
          ...villagePayload,
          acctev: false,
          superseded_by: canonicalCityId,
        });
        await sleep(100);
      }
    }
  }

  for (const lm of landmarks) {
    const canonicalCityId = CITY_MAP[lm.cityId];
    const ownRegionId =
      CITY_OWN_REGION[canonicalCityId] || REGION_MAP[lm.regionId];
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
      id_cit: ref(`cities/${ownRegionId}`),
      id_vill: ref(`villages/${canonicalCityId}`),
      Rev_dolh: ref(`countries/${lm.countryId}`),
      dolh: ref(`countries/${lm.countryId}`),
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
      visibility_fixed_at: new Date().toISOString(),
    };
    console.log(
      `${APPLY ? "WRITE" : "WOULD_WRITE"} mkan/${lm.id} → ${canonicalCityId} / ${ownRegionId}`,
    );
    if (APPLY) {
      await patchDoc(idToken, `mkan/${lm.id}`, doc);
      await sleep(120);
    }
  }

  console.log("Done.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
