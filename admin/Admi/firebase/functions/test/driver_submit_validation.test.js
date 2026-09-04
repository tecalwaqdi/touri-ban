'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const submitValidation = require('../driver_submit_validation.js');
const v2 = require('../driver_registration_v2.js');

function authUser({emailVerified = true} = {}) {
  return {emailVerified};
}

function baseDriver(overrides = {}) {
  return {
    registration_flow_version: 2,
    registration_status: 'draft',
    ismndob: true,
    phoneNumber: '+966500000000',
    mndob_vill: {path: 'villages/x'},
    mndob_type_car: {path: 'type_car/y'},
    NameCar: 'Camry',
    ModelCar: '2020',
    number_lohh_car: 'ABC1234',
    loceshnMndobNow: {latitude: 42.87, longitude: 74.59},
    photo_url: 'https://example.com/photo.jpg',
    photo_storage_path: 'users/u/uploads/photo.jpg',
    img_id_rksh: 'https://example.com/id.jpg',
    img_id_car: 'https://example.com/car.jpg',
    doc_driver_license_front: {
      storagePath: 'users/u/uploads/license-front.jpg',
      side: 'front',
      status: 'pending_review',
    },
    doc_driver_license_back: {
      storagePath: 'users/u/uploads/license-back.jpg',
      side: 'back',
      status: 'pending_review',
    },
    Rev_dolh: {path: 'countries/kg'},
    ...overrides,
  };
}

describe('driver_submit_validation structured rejects', () => {
  it('maps email not verified', () => {
    const {blockers} = submitValidation.collectSubmitBlockers(
      baseDriver(),
      authUser({emailVerified: false}),
      {nationalId: {enabled: true, required: true}},
      {path: 'countries/kg'},
    );
    const payload = submitValidation.buildRejectPayload(blockers);
    assert.strictEqual(payload.reasonCode, 'EMAIL_NOT_VERIFIED');
    assert.ok(payload.details.missingFields.includes('EMAIL_NOT_VERIFIED'));
  });

  it('maps missing documents', () => {
    const {blockers} = submitValidation.collectSubmitBlockers(
      baseDriver({
        doc_driver_license: null,
        img_id_rksh: '',
        img_id_car: '',
        photo_url: '',
        photo_storage_path: '',
      }),
      authUser(),
      {nationalId: {enabled: true, required: true}},
      {path: 'countries/kg'},
    );
    const payload = submitValidation.buildRejectPayload(blockers);
    assert.strictEqual(payload.reasonCode, 'REQUIRED_DOCUMENT_MISSING');
    assert.ok(payload.details.missingDocuments.length >= 1);
  });

  it('maps country missing when country ref absent', () => {
    const {blockers} = submitValidation.collectSubmitBlockers(
      baseDriver(),
      authUser(),
      null,
      null,
    );
    const payload = submitValidation.buildRejectPayload(blockers);
    assert.strictEqual(payload.reasonCode, 'COUNTRY_MISSING');
  });

  it('maps country config missing when requirements empty', () => {
    const {blockers} = submitValidation.collectSubmitBlockers(
      baseDriver(),
      authUser(),
      {},
      {path: 'countries/kg'},
    );
    const payload = submitValidation.buildRejectPayload(blockers);
    assert.strictEqual(payload.reasonCode, 'COUNTRY_CONFIG_MISSING');
  });

  it('maps expiry missing when configured', () => {
    const reqs = {
      driverLicense: {enabled: true, required: true, expiryRequired: true},
    };
    const {blockers, missingExpiryTypes} = submitValidation.collectSubmitBlockers(
      baseDriver({
        doc_driver_license_front: {
          storagePath: 'users/u/uploads/license-front.jpg',
          status: 'pending_review',
        },
        doc_driver_license_back: {
          storagePath: 'users/u/uploads/license-back.jpg',
          status: 'pending_review',
        },
      }),
      authUser(),
      reqs,
      {path: 'countries/kg'},
    );
    const payload = submitValidation.buildRejectPayload(blockers, {missingExpiryTypes});
    assert.strictEqual(payload.reasonCode, 'REQUIRED_EXPIRY_MISSING');
    assert.deepStrictEqual(payload.details.missingExpiryTypes, ['driverLicense']);
  });

  it('complete driver has no blockers', () => {
    const {blockers, missingExpiryTypes} = submitValidation.collectSubmitBlockers(
      baseDriver(),
      authUser(),
      {nationalId: {enabled: true, required: true}},
      {path: 'countries/kg'},
    );
    assert.strictEqual(blockers.length, 0);
    assert.strictEqual(missingExpiryTypes.length, 0);
  });
});

describe('driver_registration_v2 gates (email + phone presence, no OTP)', () => {
  it('blocks submit when email not verified', () => {
    const blockers = v2._testSubmitBlockingReasons(
      baseDriver(),
      authUser({emailVerified: false}),
    );
    assert.ok(blockers.includes('EMAIL_NOT_VERIFIED'));
  });

  it('blocks submit when location missing', () => {
    const blockers = v2._testSubmitBlockingReasons(
      baseDriver({loceshnMndobNow: null}),
      authUser(),
    );
    assert.ok(blockers.includes('LOCATION_MISSING'));
  });
});
