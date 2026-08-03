'use strict';

/** Saudi Arabia approximate bounding box (degrees). */
const SA_BOUNDS = {
  sw: { lat: 16.0, lng: 34.5 },
  ne: { lat: 32.5, lng: 56.0 },
};

/** Makkah Region approximate bounding box. */
const MAKKAH_REGION_BOUNDS = {
  sw: { lat: 18.5, lng: 38.5 },
  ne: { lat: 23.5, lng: 43.0 },
};

const ALLOWED_LICENSES = new Set([
  'Public domain',
  'CC0',
  'CC BY',
  'CC BY 2.0',
  'CC BY 3.0',
  'CC BY 4.0',
  'CC BY-SA',
  'CC BY-SA 2.0',
  'CC BY-SA 3.0',
  'CC BY-SA 4.0',
]);

const REQUIRED_LANGS = ['ar', 'en', 'ru', 'ky', 'uz'];

function inBounds(lat, lng, box) {
  return (
    lat >= box.sw.lat &&
    lat <= box.ne.lat &&
    lng >= box.sw.lng &&
    lng <= box.ne.lng
  );
}

function looksMojibake(text) {
  return /�/.test(text) || /Ã.|Â./.test(text);
}

function looksArabic(text) {
  return /[\u0600-\u06FF]/.test(text);
}

function validateLandmark(lm, ctx = {}) {
  const errors = [];
  const warnings = [];

  if (!lm.id) errors.push('missing id');
  if (!lm.slug) errors.push('missing slug');
  if (!lm.cityId) errors.push('missing cityId');
  if (!lm.category) errors.push('missing category');

  for (const lang of REQUIRED_LANGS) {
    if (!lm.names?.[lang]?.trim()) errors.push(`missing names.${lang}`);
    if (!lm.shortDescriptions?.[lang]?.trim()) {
      warnings.push(`missing shortDescriptions.${lang}`);
    }
  }

  const lat = lm.location?.latitude;
  const lng = lm.location?.longitude;
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    errors.push('missing coordinates');
  } else {
    if (lat === 0 && lng === 0) errors.push('coordinates are 0,0');
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) errors.push('coordinates out of range');
    // Detect swapped lat/lng for SA region (lng would look like ~21)
    if (Math.abs(lat) > 40 && Math.abs(lng) < 30) {
      errors.push('possible lat/lng swap');
    }
    if (!inBounds(lat, lng, SA_BOUNDS)) {
      errors.push('coordinates outside Saudi Arabia bounds');
    }
    if (ctx.requireMakkahRegion && !inBounds(lat, lng, MAKKAH_REGION_BOUNDS)) {
      errors.push('coordinates outside Makkah Region approximate bounds');
    }
  }

  if (!lm.sources || lm.sources.length === 0) {
    errors.push('missing sources');
  } else if (lm.sources.length < 2 && !lm.wikidataId && !lm.unesco) {
    warnings.push('fewer than 2 sources and no Wikidata/UNESCO id');
  }

  for (const lang of REQUIRED_LANGS) {
    const name = lm.names?.[lang] || '';
    const desc = lm.shortDescriptions?.[lang] || '';
    if (looksMojibake(name) || looksMojibake(desc)) {
      errors.push(`mojibake in ${lang}`);
    }
  }

  // Non-Arabic locales should not be Arabic-script only copies without note
  for (const lang of ['en', 'ru', 'ky', 'uz']) {
    const name = lm.names?.[lang] || '';
    if (name && looksArabic(name) && lang !== 'ar') {
      warnings.push(`names.${lang} contains Arabic script`);
    }
  }

  const identical =
    REQUIRED_LANGS.every((l) => lm.names?.[l] === lm.names?.ar) &&
    (lm.names?.ar || '').length > 0;
  if (identical) {
    warnings.push('all language names identical to Arabic — likely incomplete translation');
  }

  const images = lm.images || [];
  if (images.length === 0) {
    warnings.push('no licensed image attached');
  }
  for (const img of images) {
    if (!img.license) errors.push(`image ${img.commonsFile || '?'} missing license`);
    else if (![...ALLOWED_LICENSES].some((l) => img.license.startsWith(l.replace(/ \d.*/, '')) || img.license === l || ALLOWED_LICENSES.has(img.license))) {
      // softer check
      const ok = ALLOWED_LICENSES.has(img.license) || /^(Public domain|CC0|CC BY)/i.test(img.license);
      if (!ok) errors.push(`image license not allowed: ${img.license}`);
    }
  }

  const confidence = lm.verification?.confidence ?? 0;
  const status = lm.verification?.status || (confidence >= 0.8 ? 'verified' : 'needs_review');
  if (confidence < 0.7 && status !== 'needs_review') {
    warnings.push('low confidence without needs_review status');
  }

  return {
    id: lm.id,
    ok: errors.length === 0,
    errors,
    warnings,
    status,
    confidence,
  };
}

function validatePilotDataset(dataset) {
  const results = [];
  const seenIds = new Set();
  const seenSlugs = new Set();
  const nearPairs = [];

  for (const lm of dataset.landmarks || []) {
    if (seenIds.has(lm.id)) {
      results.push({ id: lm.id, ok: false, errors: ['duplicate id'], warnings: [] });
      continue;
    }
    seenIds.add(lm.id);
    if (seenSlugs.has(lm.slug)) {
      results.push({ id: lm.id, ok: false, errors: ['duplicate slug'], warnings: [] });
      continue;
    }
    seenSlugs.add(lm.slug);

    const r = validateLandmark(lm, { requireMakkahRegion: true });
    results.push(r);
  }

  // Coordinate proximity dedupe (~80m ~ 0.0007 deg)
  const list = dataset.landmarks || [];
  for (let i = 0; i < list.length; i++) {
    for (let j = i + 1; j < list.length; j++) {
      const a = list[i].location;
      const b = list[j].location;
      if (!a || !b) continue;
      const dlat = Math.abs(a.latitude - b.latitude);
      const dlng = Math.abs(a.longitude - b.longitude);
      if (dlat < 0.0007 && dlng < 0.0007) {
        nearPairs.push([list[i].id, list[j].id]);
      }
    }
  }

  const okCount = results.filter((r) => r.ok).length;
  const publishable = results.filter(
    (r) => r.ok && (r.confidence ?? 0) >= 0.8 && r.status !== 'needs_review',
  ).length;

  return {
    landmarkTotal: list.length,
    okCount,
    errorCount: results.filter((r) => !r.ok).length,
    publishableCandidateCount: publishable,
    needsReviewCount: results.filter((r) => r.status === 'needs_review').length,
    nearDuplicatePairs: nearPairs,
    results,
  };
}

function toFirestorePreview(dataset) {
  const country = {
    path: `countries/${dataset.country.firestoreMapping.docId}`,
    data: {
      naim: dataset.country.names.ar,
      naimEnglesh: dataset.country.names.en,
      names_i18n: {
        ar: dataset.country.names.ar,
        en: dataset.country.names.en,
        ru: dataset.country.names.ru,
        ky: dataset.country.names.ky,
        uz: dataset.country.names.uz,
      },
      iso_code: dataset.country.iso2,
      CurrencySymbol: dataset.country.currencySymbol,
      acctev: true,
      saudi: true,
      geo_import_id: dataset.country.id,
      geo_import_pilot: dataset.pilotId,
    },
  };

  const region = {
    path: `cities/${dataset.region.firestoreMapping.docId}`,
    data: {
      naim: dataset.region.names.ar,
      names_i18n: dataset.region.names,
      dolh: `countries/${dataset.country.firestoreMapping.docId}`,
      acctev: true,
      iso_code: dataset.region.code,
      country_iso: 'SA',
      geo_import_id: dataset.region.id,
      geo_import_pilot: dataset.pilotId,
    },
  };

  const cities = dataset.cities.map((c) => ({
    path: `villages/${c.firestoreMapping.docId}`,
    data: {
      naim: c.names.ar,
      names_i18n: c.names,
      cities: `cities/${dataset.region.firestoreMapping.docId}`,
      dolh: `countries/${dataset.country.firestoreMapping.docId}`,
      lat_ling: { latitude: c.location.latitude, longitude: c.location.longitude },
      acctev: true,
      country_iso: 'SA',
      geo_import_id: c.id,
      geo_import_pilot: dataset.pilotId,
    },
  }));

  const landmarks = dataset.landmarks.map((lm) => {
    const city = dataset.cities.find((c) => c.id === lm.cityId);
    const img1 = lm.images?.[0]
      ? `commons://${encodeURIComponent(lm.images[0].commonsFile)}`
      : '';
    return {
      path: `mkan/${lm.id}`,
      data: {
        naim: lm.names.ar,
        osf: lm.shortDescriptions.ar,
        names_i18n: lm.names,
        osf_i18n: lm.shortDescriptions,
        content_locale: 'ar',
        Location: {
          latitude: lm.location.latitude,
          longitude: lm.location.longitude,
        },
        img1,
        acctev: lm.verification?.status === 'needs_review' ? false : true,
        as_ads: false,
        tsnef: lm.category,
        id_cit: `cities/${dataset.region.firestoreMapping.docId}`,
        id_vill: city ? `villages/${city.firestoreMapping.docId}` : null,
        Rev_dolh: `countries/${dataset.country.firestoreMapping.docId}`,
        country_iso: 'SA',
        wikidata_id: lm.wikidataId || null,
        source_provider: (lm.sources || []).map((s) => s.provider).join(','),
        source_url: (lm.sources || []).map((s) => s.url).filter(Boolean).join(' | '),
        verified_at: '2026-07-22',
        verification_status: lm.verification?.status || 'verified',
        verification_confidence: lm.verification?.confidence ?? null,
        geo_import_id: lm.id,
        geo_import_pilot: dataset.pilotId,
        geo_import_slug: lm.slug,
      },
      wouldWrite: false,
    };
  });

  return { country, region, cities, landmarks };
}

module.exports = {
  SA_BOUNDS,
  MAKKAH_REGION_BOUNDS,
  ALLOWED_LICENSES,
  REQUIRED_LANGS,
  validateLandmark,
  validatePilotDataset,
  toFirestorePreview,
  inBounds,
};
