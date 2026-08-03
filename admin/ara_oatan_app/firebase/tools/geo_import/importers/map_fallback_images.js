'use strict';

/**
 * For landmarks still missing photos, attach an open Wikimedia Maps static
 * preview centered on the real coordinates (not a fake stock photo).
 * This is a location-accurate visual until a Commons photo is linked.
 */
const fs = require('fs');
const path = require('path');

const COLLECTED = path.join(__dirname, '..', 'datasets', 'collected');

function mapPreviewUrl(lat, lng) {
  // Wikimedia maps static endpoint (OSM-based, open data)
  return (
    'https://maps.wikimedia.org/img/osm-intl,14,' +
    `${lat},${lng},800x500.png`
  );
}

function applyMapFallbacks(countryKey) {
  const file = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  let added = 0;
  let already = 0;
  for (const row of data.regions || []) {
    for (const lm of row.landmarks || []) {
      if (lm.images?.[0]?.url) {
        already += 1;
        continue;
      }
      const lat = lm.location?.latitude;
      const lng = lm.location?.longitude;
      if (typeof lat !== 'number' || typeof lng !== 'number') continue;
      lm.images = [
        {
          url: mapPreviewUrl(lat, lng),
          license: 'ODbL / Wikimedia Maps',
          attribution: '© OpenStreetMap contributors / Wikimedia Maps',
          source: 'wikimedia_maps_fallback',
          isMapPreview: true,
        },
      ];
      added += 1;
    }
  }
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
  return { country: countryKey, photoAlready: already, mapFallbackAdded: added };
}

if (require.main === module) {
  const countries = process.argv.slice(2);
  const list = countries.length ? countries : ['SA', 'KG', 'UZ', 'RU'];
  for (const c of list) console.log(applyMapFallbacks(c));
}

module.exports = { applyMapFallbacks, mapPreviewUrl };
