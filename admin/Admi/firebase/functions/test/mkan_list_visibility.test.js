'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  computeVisibilityPatch,
  passesStoreFilter,
  boxForVillageId,
  clampIntoBox,
} = require('../mkan_list_visibility.js');

class FakeGeoPoint {
  constructor(latitude, longitude) {
    this.latitude = latitude;
    this.longitude = longitude;
  }
}

test('taif pin outside box is NOT clamped — Location preserved', () => {
  const data = {
    id_vill: 'villages/city_sa_taif',
    tsnef: 'معالم سياحية',
    Location: {latitude: 21.4710805, longitude: 40.4971769},
  };
  const result = computeVisibilityPatch(data, FakeGeoPoint);
  assert.equal(result, null);
});

test('taif pin south of bbox keeps Location; only fills missing tsnef', () => {
  const data = {
    id_vill: {id: 'city_sa_taif', path: 'villages/city_sa_taif'},
    Location: {latitude: 21.1233522, longitude: 40.2733962},
  };
  const result = computeVisibilityPatch(data, FakeGeoPoint);
  assert.ok(result && result.changed);
  assert.equal(result.patch.tsnef, 'معالم سياحية');
  assert.equal(result.patch.Location, undefined);
});

test('pin already inside box is left alone', () => {
  const data = {
    id_vill: 'villages/city_sa_taif',
    tsnef: 'معالم سياحية',
    Location: {latitude: 21.27, longitude: 40.42},
  };
  const result = computeVisibilityPatch(data, FakeGeoPoint);
  assert.equal(result, null);
});

test('clampIntoBox helper still works for scripts', () => {
  const box = boxForVillageId('city_sa_taif');
  const next = clampIntoBox(box, 21.5, 40.3);
  assert.equal(next.lat, box.maxLat);
  assert.equal(next.lng, 40.3);
  assert.ok(passesStoreFilter(box, next.lat, next.lng));
});
