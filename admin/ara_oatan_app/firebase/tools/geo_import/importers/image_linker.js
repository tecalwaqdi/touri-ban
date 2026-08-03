'use strict';

/**
 * Link licensed Wikimedia Commons images to collected landmarks.
 * Priority: Wikidata P18 → Commons search by English name.
 * Allowed licenses only. Never uploads to Firebase Storage.
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const COLLECTED = path.join(ROOT, 'datasets', 'collected');
const REPORTS = path.join(ROOT, 'reports');
const CACHE = path.join(ROOT, 'checkpoints', 'wikidata_images');

const ALLOWED = /^(Public domain|CC0|CC BY(?!-NC)|CC-BY(?!-NC))/i;
const UA = 'TouriTaxiGeoImport/0.3 (image-license pipeline; local dry-run)';

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function stripHtml(html) {
  return String(html || '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

async function fetchJson(url, { retries = 5 } = {}) {
  let lastErr;
  for (let i = 0; i < retries; i++) {
    const res = await fetch(url, { headers: { 'User-Agent': UA } });
    if (res.ok) return res.json();
    lastErr = new Error(`HTTP ${res.status} ${url}`);
    if (res.status === 429 || res.status >= 500) {
      await sleep(2000 * (i + 1));
      continue;
    }
    throw lastErr;
  }
  throw lastErr;
}

async function wikidataP18(qid) {
  const cacheFile = path.join(CACHE, `${qid}.json`);
  if (fs.existsSync(cacheFile)) {
    return JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
  }
  const url =
    'https://www.wikidata.org/w/api.php?action=wbgetclaims&entity=' +
    encodeURIComponent(qid) +
    '&property=P18&format=json';
  const j = await fetchJson(url);
  const claims = j.claims?.P18 || [];
  const file =
    claims[0]?.mainsnak?.datavalue?.value ||
    null;
  const row = { qid, commonsFile: file };
  fs.mkdirSync(CACHE, { recursive: true });
  fs.writeFileSync(cacheFile, JSON.stringify(row), 'utf8');
  return row;
}

async function commonsMeta(fileName) {
  if (!fileName) return null;
  const title = fileName.startsWith('File:') ? fileName : `File:${fileName}`;
  const url =
    'https://commons.wikimedia.org/w/api.php?action=query&titles=' +
    encodeURIComponent(title) +
    '&prop=imageinfo&iiprop=extmetadata|url|size|mime&format=json';
  const j = await fetchJson(url);
  const page = Object.values(j.query.pages || {})[0];
  const ii = page?.imageinfo?.[0];
  if (!ii) return { title, missing: true };
  const m = ii.extmetadata || {};
  return {
    commonsFile: title.replace(/^File:/, ''),
    title,
    license: m.LicenseShortName?.value || null,
    licenseUrl: m.LicenseUrl?.value || null,
    artist: stripHtml(m.Artist?.value).slice(0, 200),
    credit: stripHtml(m.Credit?.value).slice(0, 200),
    url: ii.url,
    descriptionUrl: ii.descriptionurl,
    mime: ii.mime,
    width: ii.width,
    height: ii.height,
    missing: false,
  };
}

async function commonsSearch(name) {
  if (!name || name.length < 3) return null;
  const url =
    'https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srlimit=5&srsearch=' +
    encodeURIComponent(name) +
    '&format=json';
  const j = await fetchJson(url);
  const hit = (j.query?.search || [])[0];
  if (!hit?.title) return null;
  return hit.title.replace(/^File:/, '');
}

function licenseOk(license) {
  if (!license) return false;
  if (/NC|ND/i.test(license) && !/^CC BY-SA/i.test(license)) {
    // allow BY-SA; block NC
    if (/NC/i.test(license)) return false;
  }
  return ALLOWED.test(license) || /^CC BY-SA/i.test(license);
}

async function enrichLandmark(lm, opts = {}) {
  const result = {
    id: lm.id,
    linked: false,
    source: null,
    license: null,
    reason: null,
  };

  let fileName = null;
  if (lm.wikidataId) {
    try {
      const p18 = await wikidataP18(lm.wikidataId);
      fileName = p18.commonsFile;
      result.source = 'wikidata_p18';
      await sleep(900);
    } catch (e) {
      result.reason = `wikidata: ${e.message}`;
    }
  }

  if (!fileName && !opts.wikidataOnly) {
    try {
      fileName = await commonsSearch(lm.names?.en || lm.names?.local || lm.names?.ar);
      if (fileName) result.source = 'commons_search';
      await sleep(1200);
    } catch (e) {
      result.reason = `search: ${e.message}`;
    }
  }

  if (!fileName) {
    result.reason = result.reason || (opts.wikidataOnly ? 'no wikidata image' : 'no commons candidate');
    return { lm, result };
  }

  let meta;
  try {
    meta = await commonsMeta(fileName);
    await sleep(1400);
  } catch (e) {
    result.reason = `meta: ${e.message}`;
    return { lm, result };
  }

  if (!meta || meta.missing) {
    result.reason = 'commons file missing';
    return { lm, result };
  }
  if (!licenseOk(meta.license)) {
    result.reason = `license not allowed: ${meta.license}`;
    result.license = meta.license;
    return { lm, result };
  }

  const image = {
    commonsFile: meta.commonsFile,
    url: meta.url,
    license: meta.license,
    licenseUrl: meta.licenseUrl,
    attribution: meta.artist || meta.credit || 'Wikimedia Commons',
    width: meta.width,
    height: meta.height,
    source: result.source,
  };

  const next = {
    ...lm,
    images: [image],
    verification: {
      ...(lm.verification || {}),
      imagesLicenseVerified: true,
    },
  };
  result.linked = true;
  result.license = meta.license;
  result.commonsFile = meta.commonsFile;
  return { lm: next, result };
}

async function linkCountry(countryKey, opts = {}) {
  const inPath = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  if (!fs.existsSync(inPath)) throw new Error(`Missing dataset ${inPath}`);
  const data = JSON.parse(fs.readFileSync(inPath, 'utf8'));
  const maxPerRegion = Number(opts.maxPerRegion || 20);
  const limitRegions = opts.limitRegions ? Number(opts.limitRegions) : data.regions.length;

  const reportRows = [];
  let linked = 0;
  let skipped = 0;

  for (const region of data.regions.slice(0, limitRegions)) {
    const landmarks = [...(region.landmarks || [])];
    const toProcess = Math.min(maxPerRegion, landmarks.length);
    for (let i = 0; i < toProcess; i++) {
      const lm = landmarks[i];
      // Skip if already has licensed image
      if (lm.images?.[0]?.license && licenseOk(lm.images[0].license)) {
        linked += 1;
        reportRows.push({ id: lm.id, linked: true, source: 'existing', license: lm.images[0].license });
        continue;
      }
      if (opts.wikidataOnly && !lm.wikidataId) {
        skipped += 1;
        continue;
      }
      const { lm: next, result } = await enrichLandmark(lm, {
        wikidataOnly: !!opts.wikidataOnly,
      });
      landmarks[i] = next;
      reportRows.push(result);
      if (result.linked) linked += 1;
      else skipped += 1;
      console.log(
        `  ${region.regionSlug}: ${lm.id} → ${result.linked ? result.license : result.reason}`,
      );
    }
    region.landmarks = landmarks;
  }

  const outPath = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  data.imagesLinkedAt = new Date().toISOString();
  data.imageLinkStats = { linked, skipped, total: linked + skipped };
  fs.writeFileSync(outPath, JSON.stringify(data, null, 2), 'utf8');

  fs.mkdirSync(REPORTS, { recursive: true });
  const reportPath = path.join(REPORTS, `image_links_${countryKey.toLowerCase()}.json`);
  const summary = {
    country: countryKey,
    linked,
    skipped,
    wouldWriteToFirebaseStorage: false,
    rows: reportRows,
  };
  fs.writeFileSync(reportPath, JSON.stringify(summary, null, 2), 'utf8');
  return summary;
}

module.exports = {
  linkCountry,
  licenseOk,
  commonsMeta,
  wikidataP18,
  enrichLandmark,
  isMapPreviewImage,
};

function isMapPreviewImage(image) {
  if (!image) return false;
  if (image.isMapPreview) return true;
  const src = String(image.source || '');
  const url = String(image.url || '');
  return (
    src.includes('maps') ||
    src.includes('wikimedia_maps') ||
    url.includes('maps.wikimedia.org')
  );
}
