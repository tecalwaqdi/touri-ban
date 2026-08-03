'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const dataset = require('../datasets/pilots/sa_makkah_region.js');
const {
  validateLandmark,
  validatePilotDataset,
  inBounds,
  SA_BOUNDS,
  toFirestorePreview,
} = require('../validators/validate_pilot.js');

describe('pilot dataset integrity', () => {
  it('has at least 20 landmarks', () => {
    assert.ok(dataset.landmarks.length >= 20, `got ${dataset.landmarks.length}`);
  });

  it('uses stable ids and unique slugs', () => {
    const ids = new Set();
    const slugs = new Set();
    for (const lm of dataset.landmarks) {
      assert.ok(lm.id.startsWith('lm_sa_'));
      assert.equal(ids.has(lm.id), false);
      assert.equal(slugs.has(lm.slug), false);
      ids.add(lm.id);
      slugs.add(lm.slug);
    }
  });

  it('rejects 0,0 and out-of-country coords', () => {
    const bad = validateLandmark({
      id: 'x',
      slug: 'x',
      cityId: 'c',
      category: 'nature',
      names: { ar: 'أ', en: 'a', ru: 'а', ky: 'а', uz: 'a' },
      shortDescriptions: { ar: 'و', en: 'd', ru: 'д', ky: 'д', uz: 'd' },
      location: { latitude: 0, longitude: 0 },
      sources: [{ provider: 't' }],
      images: [],
      verification: { confidence: 0.9 },
    });
    assert.equal(bad.ok, false);
    assert.ok(bad.errors.some((e) => e.includes('0,0')));
  });

  it('keeps SA points inside country bounds', () => {
    assert.equal(inBounds(21.42, 39.82, SA_BOUNDS), true);
    assert.equal(inBounds(40, 39, SA_BOUNDS), false);
  });

  it('dry-run preview never sets production write flag', () => {
    const preview = toFirestorePreview(dataset);
    assert.ok(preview.landmarks.every((l) => l.wouldWrite === false));
  });

  it('validation report is generated', () => {
    const report = validatePilotDataset(dataset);
    assert.equal(report.landmarkTotal, dataset.landmarks.length);
    assert.ok(report.okCount >= 10);
  });
});
