#!/usr/bin/env node
/**
 * Fetch Wikimedia Commons license metadata (read-only).
 * Respects ~1 req/sec. No secrets required.
 */
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'checkpoints', 'commons_licenses.json');
const FILES = [
  'Kaba (restored).jpg',
  'Kaaba2.JPG',
  'King Fahd’s Fountain.jpg',
  'Jeddah Corniche 36.jpg',
  'Jannat-ul-Maualla at present.JPG',
  'Jabal Nur.JPG',
  'Masjid al-Namira.jpg',
  'First2.jpg',
  'Muzdalifa.JPG',
  'Jabele thor - panoramio.jpg',
  'Hajj 1965 09.jpg',
];

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function fetchFile(name) {
  const title = `File:${name}`;
  const url =
    'https://commons.wikimedia.org/w/api.php?action=query&titles=' +
    encodeURIComponent(title) +
    '&prop=imageinfo&iiprop=extmetadata|url|size|mime&format=json';
  const res = await fetch(url, {
    headers: { 'User-Agent': 'TouriTaxiGeoImport/0.1 (pilot dry-run; contact: local-dev)' },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${name}`);
  const j = await res.json();
  const page = Object.values(j.query.pages)[0];
  const ii = page.imageinfo && page.imageinfo[0];
  if (!ii) {
    return { title, missing: true };
  }
  const m = ii.extmetadata || {};
  const strip = (html) =>
    String(html || '')
      .replace(/<[^>]+>/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  return {
    title,
    license: m.LicenseShortName?.value || null,
    licenseUrl: m.LicenseUrl?.value || null,
    attributionRequired: m.AttributionRequired?.value || null,
    artist: strip(m.Artist?.value).slice(0, 200),
    credit: strip(m.Credit?.value).slice(0, 200),
    usageTerms: strip(m.UsageTerms?.value).slice(0, 200),
    url: ii.url,
    descriptionUrl: ii.descriptionurl,
    mime: ii.mime,
    width: ii.width,
    height: ii.height,
  };
}

(async () => {
  const out = [];
  for (const f of FILES) {
    try {
      const row = await fetchFile(f);
      out.push(row);
      console.log(JSON.stringify({ file: f, license: row.license, missing: !!row.missing }));
    } catch (e) {
      out.push({ title: `File:${f}`, error: String(e.message || e) });
      console.error(f, e.message || e);
    }
    await sleep(1200);
  }
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(out, null, 2), 'utf8');
  console.log('Wrote', OUT);
})();
