'use strict';

/**
 * Map collected geo datasets + vehicle catalog → Firestore document payloads.
 * Used by emulator import (writes) and dry-run preview (no writes).
 */

const { COUNTRIES } = require('../config/regions');
const { CATEGORIES } = require('../datasets/vehicles/vehicle_catalog');

function countryDoc(countryKey) {
  const c = COUNTRIES[countryKey];
  return {
    path: `countries/${c.firestoreDocId}`,
    data: {
      naim: c.names.ar,
      naimEnglesh: c.names.en,
      names_i18n: c.names,
      iso_code: c.iso2,
      iso3: c.iso3,
      CurrencySymbol: c.currencySymbol,
      currency_code: c.currencyCode,
      phone_code: c.phoneCode,
      timezone: c.timezone,
      acctev: true,
      saudi: countryKey === 'SA',
      geo_import_id: c.id,
      geo_import_source: 'touri_geo_import',
    },
  };
}

function regionDoc(countryKey, region) {
  const c = COUNTRIES[countryKey];
  const docId = `region_${countryKey.toLowerCase()}_${region.slug}`;
  return {
    path: `cities/${docId}`,
    data: {
      naim: region.names.ar,
      names_i18n: region.names,
      dolh: `countries/${c.firestoreDocId}`,
      acctev: true,
      iso_code: region.code || (region.iso ? `SA-${region.iso}` : ''),
      country_iso: c.iso2,
      geo_import_id: `region_${countryKey.toLowerCase()}_${region.slug}`,
      geo_import_source: 'touri_geo_import',
    },
  };
}

function cityDoc(countryKey, region) {
  const c = COUNTRIES[countryKey];
  const regionDocId = `region_${countryKey.toLowerCase()}_${region.slug}`;
  const cityDocId = `city_${countryKey.toLowerCase()}_${region.hub.slug}`;
  return {
    path: `villages/${cityDocId}`,
    data: {
      naim: region.hub.names.ar,
      names_i18n: region.hub.names,
      cities: `cities/${regionDocId}`,
      dolh: `countries/${c.firestoreDocId}`,
      lat_ling: {
        latitude: region.hub.lat,
        longitude: region.hub.lng,
      },
      acctev: true,
      country_iso: c.iso2,
      geo_import_id: cityDocId,
      geo_import_source: 'touri_geo_import',
    },
  };
}

function mapTsnef(category) {
  const raw = String(category || 'attraction').trim().toLowerCase();
  const map = {
    religious: 'معالم دينية',
    religion: 'معالم دينية',
    place_of_worship: 'معالم دينية',
    mosque: 'معالم دينية',
    historic: 'معالم تاريخية',
    historical: 'معالم تاريخية',
    heritage: 'معالم تاريخية',
    museum: 'معالم سياحية',
    attraction: 'معالم سياحية',
    tourism: 'معالم سياحية',
    tourist: 'معالم سياحية',
    viewpoint: 'معالم سياحية',
    park: 'أماكن ترفيهية',
    entertainment: 'أماكن ترفيهية',
    leisure: 'أماكن ترفيهية',
    cafe: 'مقهى',
    café: 'مقهى',
    restaurant: 'مطاعم',
    food: 'مطاعم',
    market: 'أسواق',
    marketplace: 'أسواق',
    hotel: 'فنادق',
    desert: 'جولة برية',
    sea: 'جولة بحرية',
    beach: 'جولة بحرية',
  };
  if (map[raw]) return map[raw];
  // already Arabic storage label
  if (/[\u0600-\u06FF]/.test(String(category || ''))) return String(category);
  return 'معالم سياحية';
}

function landmarkDoc(countryKey, region, lm) {
  const c = COUNTRIES[countryKey];
  const regionDocId = `region_${countryKey.toLowerCase()}_${region.slug}`;
  const cityDocId = `city_${countryKey.toLowerCase()}_${region.hub.slug}`;
  const image = lm.images?.[0] || null;
  const img1 = image
    ? image.url ||
      (image.commonsFile
        ? `commons://${encodeURIComponent(image.commonsFile)}`
        : '')
    : '';

  return {
    path: `mkan/${lm.id}`,
    data: {
      naim: lm.names.ar || lm.names.en || lm.names.local,
      osf: lm.shortDescriptions?.ar || '',
      names_i18n: lm.names,
      osf_i18n: lm.shortDescriptions || {},
      content_locale: 'ar',
      Location: {
        latitude: lm.location.latitude,
        longitude: lm.location.longitude,
      },
      img1,
      img2: '',
      img3: '',
      img_license: image?.license || '',
      img_attribution: image?.attribution || '',
      images_license_verified: !!(image?.license || image?.url),
      img_source: image?.source || '',
      sr: lm.sortIndex || 1,
      acctev: lm.verification?.status === 'rejected' ? false : true,
      as_ads: (lm.sortIndex || 1) <= 6,
      ismzod: true,
      isShrek: false,
      ismsgd: lm.category === 'religious',
      isfood: true,
      ishmam: true,
      tsnef: mapTsnef(lm.category),
      rate: 4.5,
      add_saat: 2,
      id_cit: `cities/${regionDocId}`,
      id_vill: `villages/${cityDocId}`,
      Rev_dolh: `countries/${c.firestoreDocId}`,
      country_iso: c.iso2,
      wikidata_id: lm.wikidataId || lm.wikidata || null,
      source_provider: (lm.sources || []).map((s) => s.provider).join(','),
      source_url: (lm.sources || [])
        .map((s) => s.url)
        .filter(Boolean)
        .join(' | '),
      source_osm_id: lm.osmId || '',
      verification_status: lm.verification?.status || 'verified',
      verification_confidence: lm.verification?.confidence ?? null,
      geo_import_id: lm.id,
      geo_import_slug: lm.slug,
      geo_import_source: 'touri_geo_import',
    },
  };
}

function vehicleDocs() {
  return CATEGORIES.map((cat) => ({
    path: `type_car/${cat.code}`,
    data: {
      naim: cat.names.ar,
      names_i18n: cat.names,
      codeCar: cat.code,
      sr: cat.hourlyRate,
      agl_saat: cat.minHours,
      actev: true,
      ishafelh: !!cat.isBusLike,
      not: cat.names.en,
      geo_import_id: `vehcat_${cat.code}`,
      geo_import_source: 'touri_geo_import',
    },
  }));
}

/**
 * Build full import plan from collected JSON payloads.
 * @param {object} options
 * @param {Record<string, object>} options.collectedByCountry map SA→sa_regions.json payload
 * @param {string[]} [options.countries]
 * @param {boolean} [options.includeVehicles]
 */
function buildImportPlan(options = {}) {
  const countries = options.countries || ['SA', 'KG', 'UZ', 'RU'];
  const includeVehicles = options.includeVehicles !== false;
  const docs = [];
  const stats = {
    countries: 0,
    regions: 0,
    cities: 0,
    landmarks: 0,
    vehicles: 0,
  };

  for (const key of countries) {
    const collected = options.collectedByCountry?.[key];
    if (!collected) continue;
    const country = COUNTRIES[key];
    if (!country) continue;

    docs.push(countryDoc(key));
    stats.countries += 1;

    const regionBySlug = new Map(country.regions.map((r) => [r.slug, r]));

    for (const row of collected.regions || []) {
      const region = regionBySlug.get(row.regionSlug);
      if (!region) continue;
      docs.push(regionDoc(key, region));
      docs.push(cityDoc(key, region));
      stats.regions += 1;
      stats.cities += 1;

      for (const lm of row.landmarks || []) {
        docs.push(landmarkDoc(key, region, lm));
        stats.landmarks += 1;
      }
    }
  }

  if (includeVehicles) {
    const vehicles = vehicleDocs();
    docs.push(...vehicles);
    stats.vehicles = vehicles.length;
  }

  return {
    generatedAt: new Date().toISOString(),
    target: 'emulator-or-preview',
    wouldWriteToProduction: false,
    stats,
    docs,
  };
}

module.exports = {
  countryDoc,
  regionDoc,
  cityDoc,
  landmarkDoc,
  vehicleDocs,
  buildImportPlan,
};
