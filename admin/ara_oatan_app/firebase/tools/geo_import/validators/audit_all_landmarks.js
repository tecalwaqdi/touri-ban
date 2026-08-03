'use strict';

/**
 * Full quality audit for collected multi-country landmarks.
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const COLLECTED = path.join(ROOT, 'datasets', 'collected');
const REPORTS = path.join(ROOT, 'reports');

const BOUNDS = {
  SA: { sw: { lat: 16, lng: 34.5 }, ne: { lat: 32.5, lng: 56 } },
  KG: { sw: { lat: 39, lng: 69 }, ne: { lat: 43.5, lng: 80.5 } },
  UZ: { sw: { lat: 37, lng: 55.5 }, ne: { lat: 45.7, lng: 73.2 } },
  RU: { sw: { lat: 41, lng: 19 }, ne: { lat: 82, lng: 190 } },
};

function inBounds(lat, lng, b) {
  return (
    lat >= b.sw.lat &&
    lat <= b.ne.lat &&
    lng >= b.sw.lng &&
    lng <= b.ne.lng
  );
}

function auditCountry(key) {
  const file = path.join(COLLECTED, `${key.toLowerCase()}_regions.json`);
  if (!fs.existsSync(file)) {
    return { country: key, error: 'missing_dataset' };
  }
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  const bounds = BOUNDS[key];
  const issues = [];
  let total = 0;
  let ok = 0;
  let withImg = 0;
  let withLicense = 0;
  let withWd = 0;
  let withOsm = 0;
  let badCoord = 0;
  let outBounds = 0;
  let missingName = 0;
  let dups = 0;
  const seen = new Set();
  const regionStats = [];

  for (const row of data.regions || []) {
    const landmarks = row.landmarks || [];
    let regionOk = 0;
    let regionImg = 0;
    for (const lm of landmarks) {
      total += 1;
      const errs = [];
      const lat = lm.location?.latitude;
      const lng = lm.location?.longitude;
      if (typeof lat !== 'number' || typeof lng !== 'number') {
        errs.push('missing_coords');
        badCoord += 1;
      } else if (lat === 0 && lng === 0) {
        errs.push('zero_coords');
        badCoord += 1;
      } else if (!inBounds(lat, lng, bounds)) {
        errs.push('out_of_country_bounds');
        outBounds += 1;
      }

      if (!lm.names?.ar?.trim() && !lm.names?.en?.trim()) {
        errs.push('missing_name');
        missingName += 1;
      }

      const hasImg =
        !!(lm.images?.[0]?.url || lm.images?.[0]?.commonsFile);
      if (hasImg) {
        withImg += 1;
        regionImg += 1;
        if (lm.images[0].license) withLicense += 1;
      } else {
        errs.push('missing_licensed_image');
      }

      if (lm.wikidataId) withWd += 1;
      if (
        lm.osmId ||
        (lm.sources || []).some((s) =>
          /osm|openstreetmap/i.test(String(s.provider || '')),
        )
      ) {
        withOsm += 1;
      }

      const keyName = `${(lm.names?.en || lm.names?.ar || '').toLowerCase()}|${Number(
        lat,
      ).toFixed(4)}|${Number(lng).toFixed(4)}`;
      if (seen.has(keyName)) {
        errs.push('duplicate_nearby');
        dups += 1;
      } else {
        seen.add(keyName);
      }

      // Real place evidence: OSM and/or Wikidata and/or curated dual source
      const realEvidence =
        !!lm.wikidataId ||
        !!lm.osmId ||
        (lm.sources || []).length >= 1;
      if (!realEvidence) errs.push('weak_source_evidence');

      if (errs.length === 0) {
        ok += 1;
        regionOk += 1;
      } else {
        issues.push({
          id: lm.id,
          region: row.regionSlug,
          errs,
          lat,
          lng,
          name: lm.names?.en || lm.names?.ar,
        });
      }
    }
    regionStats.push({
      slug: row.regionSlug,
      count: landmarks.length,
      quotaOk: landmarks.length >= 20,
      withImg: regionImg,
      fullyOk: regionOk,
    });
  }

  return {
    country: key,
    total,
    fullyOk: ok,
    needsWork: total - ok,
    withImg,
    withLicense,
    withWd,
    withOsm,
    badCoord,
    outBounds,
    missingName,
    dups,
    imgCoveragePct: Math.round((100 * withImg) / Math.max(total, 1)),
    regionStats,
    issueSample: issues.slice(0, 40),
    issueCount: issues.length,
  };
}

function runFullAudit() {
  const countries = ['SA', 'KG', 'UZ', 'RU'];
  const rows = countries.map(auditCountry);
  const summary = {
    generatedAt: new Date().toISOString(),
    totals: {
      landmarks: rows.reduce((a, r) => a + (r.total || 0), 0),
      withImg: rows.reduce((a, r) => a + (r.withImg || 0), 0),
      badCoord: rows.reduce((a, r) => a + (r.badCoord || 0), 0),
      outBounds: rows.reduce((a, r) => a + (r.outBounds || 0), 0),
      dups: rows.reduce((a, r) => a + (r.dups || 0), 0),
    },
    countries: rows,
    verdict: null,
  };
  const imgPct = Math.round(
    (100 * summary.totals.withImg) / Math.max(summary.totals.landmarks, 1),
  );
  summary.verdict = {
    coordsOk: summary.totals.badCoord === 0 && summary.totals.outBounds === 0,
    imagesReady: imgPct >= 80,
    imgCoveragePct: imgPct,
    message:
      summary.totals.badCoord === 0 && summary.totals.outBounds === 0
        ? imgPct >= 80
          ? 'Coordinates OK; images coverage good.'
          : `Coordinates OK; images ONLY ${imgPct}% — must link Commons photos.`
        : 'Coordinate problems found — review issueSample.',
  };

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'landmark_quality_audit.json');
  fs.writeFileSync(out, JSON.stringify(summary, null, 2), 'utf8');
  console.log(JSON.stringify(summary.verdict, null, 2));
  console.log('Wrote', out);
  return summary;
}

if (require.main === module) runFullAudit();
module.exports = { runFullAudit, auditCountry };
