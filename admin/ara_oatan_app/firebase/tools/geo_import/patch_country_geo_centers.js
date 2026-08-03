/**
 * Idempotent patch: write geo_center + bounds for canonical multi-country docs.
 * Target: tutorial-multi-language-70gx4j (Production customer app).
 *
 * Usage:
 *   node patch_country_geo_centers.js
 */
const SEED = require('../../../../Admi/firebase/scripts/seed_production_client.js');

const PROJECT = 'tutorial-multi-language-70gx4j';

const PATCHES = [
  {
    id: 'kyrgyzstan',
    iso: 'KG',
    center: { lat: 41.2044, lng: 74.7661 },
    sw: { lat: 39.1, lng: 69.2 },
    ne: { lat: 43.3, lng: 80.3 },
    zoom: 6,
  },
  {
    id: 'country_kg',
    iso: 'KG',
    center: { lat: 41.2044, lng: 74.7661 },
    sw: { lat: 39.1, lng: 69.2 },
    ne: { lat: 43.3, lng: 80.3 },
    zoom: 6,
  },
  {
    id: 'saudi_arabia',
    iso: 'SA',
    center: { lat: 24.7136, lng: 46.6753 },
    sw: { lat: 16.0, lng: 34.5 },
    ne: { lat: 32.2, lng: 55.7 },
    zoom: 5.2,
  },
  {
    id: 'country_sa',
    iso: 'SA',
    center: { lat: 24.7136, lng: 46.6753 },
    sw: { lat: 16.0, lng: 34.5 },
    ne: { lat: 32.2, lng: 55.7 },
    zoom: 5.2,
  },
  {
    id: 'saudi-arabia',
    iso: 'SA',
    center: { lat: 24.7136, lng: 46.6753 },
    sw: { lat: 16.0, lng: 34.5 },
    ne: { lat: 32.2, lng: 55.7 },
    zoom: 5.2,
  },
  {
    id: 'russia',
    iso: 'RU',
    center: { lat: 61.524, lng: 105.3188 },
    sw: { lat: 41.1, lng: 19.6 },
    ne: { lat: 81.9, lng: 180.0 },
    zoom: 3.2,
  },
  {
    id: 'country_ru',
    iso: 'RU',
    center: { lat: 61.524, lng: 105.3188 },
    sw: { lat: 41.1, lng: 19.6 },
    ne: { lat: 81.9, lng: 180.0 },
    zoom: 3.2,
  },
  {
    id: 'uzbekistan',
    iso: 'UZ',
    center: { lat: 41.3775, lng: 64.5853 },
    sw: { lat: 37.1, lng: 55.9 },
    ne: { lat: 45.6, lng: 73.2 },
    zoom: 5.5,
  },
  {
    id: 'country_uz',
    iso: 'UZ',
    center: { lat: 41.3775, lng: 64.5853 },
    sw: { lat: 37.1, lng: 55.9 },
    ne: { lat: 45.6, lng: 73.2 },
    zoom: 5.5,
  },
];

function latLngValue(lat, lng) {
  return { geoPointValue: { latitude: lat, longitude: lng } };
}

async function patchOne(idToken, patch) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/countries/${patch.id}` +
    `?updateMask.fieldPaths=iso_code` +
    `&updateMask.fieldPaths=geo_center` +
    `&updateMask.fieldPaths=bounds_sw` +
    `&updateMask.fieldPaths=bounds_ne` +
    `&updateMask.fieldPaths=default_zoom`;

  const body = {
    fields: {
      iso_code: { stringValue: patch.iso },
      geo_center: latLngValue(patch.center.lat, patch.center.lng),
      bounds_sw: latLngValue(patch.sw.lat, patch.sw.lng),
      bounds_ne: latLngValue(patch.ne.lat, patch.ne.lng),
      default_zoom: { doubleValue: patch.zoom },
    },
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${patch.id}: ${res.status} ${text}`);
  }
  console.log('patched', patch.id, patch.iso);
}

(async () => {
  const { idToken } = await SEED.getIdToken();
  for (const patch of PATCHES) {
    await patchOne(idToken, patch);
  }
  console.log('done', PATCHES.length);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
