/**
 * Adds production countries with localized names, flags, currencies and bounds.
 *
 * Usage:
 *   cd firebase/functions
 *   node ../scripts/seed_supported_countries.js
 *
 * Uses the authenticated client seed account configured by
 * seed_production_client.js, so Firestore security rules still apply.
 */
const { getIdToken, patchDoc, geo } = require("./seed_production_client");
const ISO_CODES = [
  "SA", "AE", "QA", "KW", "BH", "OM",
  "EG", "JO", "IQ", "TR",
  "UZ", "KG", "AZ", "GE",
  "PK", "ID", "MY",
  "MA", "TN", "FR", "RU", "CN",
];
const LOCALES = {
  ar: "ar",
  en: "en",
  zh_Hans: "zh-Hans",
  tr: "tr",
  ur: "ur",
  ru: "ru",
  az: "az",
  ka: "ka",
  ky: "ky",
  fr: "fr",
  id: "id",
};
const VAT = {
  SA: 15, AE: 5, QA: 0, KW: 0, BH: 10, OM: 5,
  EG: 14, JO: 16, IQ: 0, TR: 20, UZ: 12, KG: 12,
  AZ: 18, GE: 18, PK: 18, ID: 11, MY: 8, MA: 20,
  TN: 19, FR: 20, RU: 20, CN: 13,
};

function localizedNames(code) {
  const result = {};
  for (const [key, locale] of Object.entries(LOCALES)) {
    try {
      result[key] =
        new Intl.DisplayNames([locale], { type: "region" }).of(code) || code;
    } catch (_) {
      result[key] = code;
    }
  }
  return result;
}

async function fetchCountry(code) {
  const response = await fetch(`https://restcountries.com/v3.1/alpha/${code}`);
  if (!response.ok) throw new Error(`REST Countries ${code}: ${response.status}`);
  const payload = await response.json();
  return Array.isArray(payload) ? payload[0] : payload;
}

async function fetchBounds(code) {
  const url =
    "https://nominatim.openstreetmap.org/search" +
    `?countrycodes=${code.toLowerCase()}&format=json&limit=1&featuretype=country`;
  const response = await fetch(url, {
    headers: { "User-Agent": "ArraWatanAdmin/1.0 (production seed)" },
  });
  if (!response.ok) return null;
  const list = await response.json();
  const box = list[0]?.boundingbox;
  if (!box || box.length < 4) return null;
  return {
    sw: geo(Number(box[0]), Number(box[2])),
    ne: geo(Number(box[1]), Number(box[3])),
  };
}

async function main() {
  const { idToken } = await getIdToken();
  let order = 1;

  for (const code of ISO_CODES) {
    const country = await fetchCountry(code);
    const names = localizedNames(code);
    const bounds = await fetchBounds(code);
    const currencyCode = Object.keys(country.currencies || {})[0] || "";
    const currency = country.currencies?.[currencyCode] || {};
    const latLng = country.latlng || [0, 0];
    const lower = code.toLowerCase();

    const data = {
      naim: names.ar,
      naimEnglesh: names.en,
      names_i18n: names,
      osf: names.ar,
      acctev: true,
      saudi: code === "SA",
      iso_code: code,
      img: `https://flagcdn.com/w320/${lower}.png`,
      hederImg: `https://flagcdn.com/w1280/${lower}.png`,
      num_trteb: order++,
      isvat: (VAT[code] || 0) > 0,
      vat: VAT[code] || 0,
      vat_percent: VAT[code] || 0,
      CurrencySymbol: currency.symbol || currencyCode,
      currency_code: currencyCode,
      CurrencyFRG: 1,
      geo_center: geo(latLng[0], latLng[1]),
      ...(bounds ? { bounds_sw: bounds.sw, bounds_ne: bounds.ne } : {}),
      updated_at: new Date(),
    };

    const docId = code === "SA" ? "saudi_arabia" : `country_${lower}`;
    await patchDoc(idToken, `countries/${docId}`, data);
    console.log(`Seeded ${code}: ${names.en}`);
    await new Promise((resolve) => setTimeout(resolve, 1100));
  }

  // Remove the duplicate ID used by an early import attempt.
  await patchDoc(idToken, "countries/country_sa", {
    acctev: false,
    duplicate_of: "countries/saudi_arabia",
  });
  console.log(`Done: ${ISO_CODES.length} countries.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
