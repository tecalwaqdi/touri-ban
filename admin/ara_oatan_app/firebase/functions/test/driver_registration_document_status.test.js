'use strict';

const assert = require('assert');
const {DriverRegistrationDocumentStatus} = (() => {
  // Mirror Dart helper logic for CF/test parity.
  function urlFrom(data, v2Key, legacyKey) {
    const slot = data[v2Key];
    if (slot && typeof slot === 'object') {
      const p = String(slot.storagePath || '').trim();
      if (p.startsWith('users/') && !p.includes('..')) return p;
      if (typeof slot.url === 'string') {
        const u = slot.url.trim();
        if (u) return u;
      }
    }
    const leg = data[legacyKey];
    if (typeof leg === 'string' && leg.trim()) return leg.trim();
    return '';
  }
  function statusForType(data, type) {
    const map = {
      national_id: ['doc_national_id', 'img_id_rksh'],
      vehicle_registration: ['doc_vehicle_registration', 'img_id_car'],
      driver_license: ['doc_driver_license', ''],
    };
    const keys = map[type];
    if (!keys) return 'missing';
    const slot = data[keys[0]];
    const raw =
      slot && typeof slot === 'object' ? String(slot.status || '').toLowerCase() : '';
    if (raw === 'rejected') return 'rejected';
    if (raw === 'needs_reupload') return 'needs_reupload';
    const url = urlFrom(data, keys[0], keys[1]);
    if (url && (url.startsWith('users/') || /^https:\/\//i.test(url))) {
      return 'complete';
    }
    return 'missing';
  }
  function isComplete(data) {
    const required = ['national_id', 'vehicle_registration', 'driver_license'];
    const photoPath = String(data.photo_storage_path || '').trim();
    const photoOk =
      (photoPath.startsWith('users/') && !photoPath.includes('..')) ||
      /^https:\/\//i.test(String(data.photo_url || ''));
    if (!photoOk) return false;
    return required.every((t) => statusForType(data, t) === 'complete');
  }
  return {DriverRegistrationDocumentStatus: {statusForType, isComplete}};
})();

describe('driverRegistrationDocumentStatus parity', () => {
  it('COMPLETE when all HTTPS present', () => {
    assert.strictEqual(
      DriverRegistrationDocumentStatus.isComplete({
        photo_url: 'https://x/p.jpg',
        img_id_rksh: 'https://x/id.jpg',
        img_id_car: 'https://x/car.jpg',
        doc_driver_license: {url: 'https://x/lic.jpg', status: 'uploaded'},
      }),
      true,
    );
  });

  it('COMPLETE when storagePath present (no URL)', () => {
    assert.strictEqual(
      DriverRegistrationDocumentStatus.isComplete({
        photo_storage_path: 'users/u/uploads/p.jpg',
        doc_national_id: {storagePath: 'users/u/uploads/id.jpg'},
        doc_vehicle_registration: {storagePath: 'users/u/uploads/car.jpg'},
        doc_driver_license: {storagePath: 'users/u/uploads/lic.jpg'},
      }),
      true,
    );
  });

  it('MISSING when license absent', () => {
    assert.strictEqual(
      DriverRegistrationDocumentStatus.isComplete({
        photo_url: 'https://x/p.jpg',
        img_id_rksh: 'https://x/id.jpg',
        img_id_car: 'https://x/car.jpg',
      }),
      false,
    );
    assert.strictEqual(
      DriverRegistrationDocumentStatus.statusForType({}, 'driver_license'),
      'missing',
    );
  });
});
