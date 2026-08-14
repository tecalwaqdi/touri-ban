'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const { COUNTRIES } = require('../datasets/curated/international_seven_capitals');
const VERIFIED_IMAGES = require('../datasets/curated/international_seven_images');
const STAGING = path.join(__dirname, '..', 'staging', 'firestore');

describe('international seven capitals import', () => {
  it('defines exactly 7 countries with 5 landmarks each', () => {
    assert.equal(COUNTRIES.length, 7);
    for (const c of COUNTRIES) {
      assert.equal(c.landmarks.length, 5, `${c.names.en} landmarks`);
    }
  });

  it('has unique landmark ids and image urls', () => {
    const ids = new Set();
    const imgs = new Set();
    for (const c of COUNTRIES) {
      for (const lm of c.landmarks) {
        assert.ok(!ids.has(lm.id), `duplicate id ${lm.id}`);
        ids.add(lm.id);
        const img = VERIFIED_IMAGES[lm.id];
        assert.ok(img, `missing verified image for ${lm.id}`);
        assert.ok(!imgs.has(img), `duplicate image ${lm.id}`);
        imgs.add(img);
      }
    }
    assert.equal(ids.size, 35);
    assert.equal(imgs.size, 35);
  });

  it('writes staging json for each doc path', () => {
    const expectedCountries = [
      'spain',
      'morocco',
      'portugal',
      'tunisia',
      'indonesia',
      'malaysia',
      'india',
    ];
    for (const id of expectedCountries) {
      const p = path.join(STAGING, 'countries', `${id}.json`);
      assert.ok(fs.existsSync(p), `missing ${p}`);
      const doc = JSON.parse(fs.readFileSync(p, 'utf8'));
      assert.equal(doc.acctev, true);
      assert.ok(doc.names_i18n?.ar && doc.names_i18n?.en);
    }
  });

  it('each capital has exactly five active landmarks in staging', () => {
    for (const c of COUNTRIES) {
      const prefix = `lm_${c.key.toLowerCase()}_${c.region.slug}_`;
      const files = fs
        .readdirSync(path.join(STAGING, 'mkan'))
        .filter((f) => f.startsWith(prefix));
      assert.equal(files.length, 5, `${c.names.en} landmark files`);
    }
  });
});
