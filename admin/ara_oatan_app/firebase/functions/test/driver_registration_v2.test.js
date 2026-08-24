'use strict';

const assert = require('assert');
const v2 = require('../driver_registration_v2.js');
const docStatus = require('../driver_registration_document_status.js');

function authUser({emailVerified = true} = {}) {
  return {emailVerified};
}

function baseDriver(overrides = {}) {
  return {
    registration_flow_version: 2,
    registration_status: 'pending_review',
    ismndob: true,
    phoneNumber: '+966500000000',
    mndob_vill: {path: 'villages/x'},
    mndob_type_car: {path: 'type_car/y'},
    NameCar: 'Camry',
    ModelCar: '2020',
    number_lohh_car: 'ABC1234',
    photo_url: 'https://example.com/photo.jpg',
    img_id_rksh: 'https://example.com/id.jpg',
    img_id_car: 'https://example.com/car.jpg',
    doc_driver_license: {url: 'https://example.com/license.jpg'},
    ...overrides,
  };
}

describe('driver_registration_v2 gates (email + phone presence, no OTP)', () => {
  it('blocks submit when email not verified', () => {
    const blockers = v2._testSubmitBlockingReasons(
      baseDriver(),
      authUser({emailVerified: false}),
    );
    assert.ok(blockers.includes('EMAIL_NOT_VERIFIED'));
  });

  it('blocks submit when phone empty on profile → PHONE_REQUIRED', () => {
    const blockers = v2._testSubmitBlockingReasons(
      baseDriver({phoneNumber: '', phone_number: '', phone_n: null, phoneN: null}),
      authUser(),
    );
    assert.ok(blockers.includes('PHONE_REQUIRED'));
    assert.ok(!blockers.includes('PHONE_NOT_VERIFIED'));
  });

  it('allows submit when phone present on profile even if Auth has no phoneNumber', () => {
    const blockers = v2._testSubmitBlockingReasons(
      baseDriver({phoneNumber: '+966512345678'}),
      {emailVerified: true, phoneNumber: null},
    );
    assert.ok(!blockers.includes('PHONE_REQUIRED'));
    assert.ok(!blockers.includes('PHONE_NOT_VERIFIED'));
    assert.ok(!blockers.includes('EMAIL_NOT_VERIFIED'));
  });

  it('does not require Auth phoneNumber for approve', () => {
    const blockers = v2._testApprovalBlockingReasonsV2(
      baseDriver({phoneNumber: '+966512345678'}),
      {emailVerified: true, phoneNumber: null},
    );
    assert.ok(!blockers.includes('PHONE_NOT_VERIFIED'));
    assert.ok(!blockers.includes('PHONE_REQUIRED'));
  });

  it('approve requires email verified + phone present', () => {
    const noEmail = v2._testApprovalBlockingReasonsV2(
      baseDriver(),
      {emailVerified: false},
    );
    assert.ok(noEmail.includes('EMAIL_NOT_VERIFIED'));
    const noPhone = v2._testApprovalBlockingReasonsV2(
      baseDriver({phoneNumber: '', phone_n: null}),
      authUser(),
    );
    assert.ok(noPhone.includes('PHONE_REQUIRED'));
  });

  it('blocks submit when vehicle missing', () => {
    const blockers = v2._testSubmitBlockingReasons(
      baseDriver({NameCar: '', ModelCar: '', number_lohh_car: ''}),
      authUser(),
    );
    assert.ok(blockers.includes('vehicle_name_required'));
  });

  it('blocks when national id missing', () => {
    const noId = v2._testSubmitBlockingReasons(
      baseDriver({img_id_rksh: '', doc_national_id: null}),
      authUser(),
    );
    assert.ok(noId.includes('national_id_required'));
  });

  it('ALLOWED_FIELDS_TO_FIX includes national_id', () => {
    assert.ok(v2.ALLOWED_FIELDS_TO_FIX.includes('national_id'));
  });
});

describe('registration_documents_status authoritative', () => {
  it('complete when required docs present', () => {
    assert.strictEqual(
      docStatus.registrationDocumentsStatus(baseDriver()),
      'complete',
    );
  });

  it('missing when one required doc absent', () => {
    assert.strictEqual(
      docStatus.registrationDocumentsStatus(
        baseDriver({doc_driver_license: null, img_id_car: 'https://x/c.jpg'}),
      ),
      'missing',
    );
  });

  it('needs_reupload when slot flagged', () => {
    assert.strictEqual(
      docStatus.registrationDocumentsStatus(
        baseDriver({
          doc_national_id: {
            storagePath: 'users/u/uploads/id.jpg',
            status: 'needs_reupload',
          },
        }),
      ),
      'needs_reupload',
    );
  });

  it('legacy non-V2 → unknown_legacy', () => {
    assert.strictEqual(
      docStatus.registrationDocumentsStatus(
        baseDriver({registration_flow_version: 1}),
      ),
      'unknown_legacy',
    );
  });

  it('phonePresent ignores Auth — uses profile only', () => {
    assert.strictEqual(docStatus.phonePresent({phoneNumber: '+966500000000'}), true);
    assert.strictEqual(docStatus.phonePresent({phone_n: 966500000000}), true);
    assert.strictEqual(docStatus.phonePresent({}), false);
  });
});
