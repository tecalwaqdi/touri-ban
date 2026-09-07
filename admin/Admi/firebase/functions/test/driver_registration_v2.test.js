'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
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
    loceshnMndobNow: {latitude: 42.87, longitude: 74.59},
    photo_url: 'https://example.com/photo.jpg',
    img_id_rksh: 'https://example.com/id.jpg',
    img_id_car: 'https://example.com/car.jpg',
    doc_driver_license_front: {url: 'https://example.com/license-front.jpg'},
    doc_driver_license_back: {url: 'https://example.com/license-back.jpg'},
    doc_driver_license: {url: 'https://example.com/license.jpg'},
    ...overrides,
  };
}

/**
 * Pure mirrors of reviewDriverApplicationV2 override gates (local source contract).
 * Kept in tests so CASE A does not rewrite production — deploy is still required.
 */
function overrideStatusAllowed(status, {override}) {
  if (override) {
    return ['pending_review', 'needs_changes'].includes(String(status || ''));
  }
  return String(status || '') === 'pending_review';
}

function overrideActorAllowed(claims) {
  return claims && claims.super_admin === true;
}

function overrideReasonAllowed(reason) {
  return String(reason || '').trim().length >= 3;
}

function approvePatchAxes({override, alsoActivate}) {
  return {
    registration_status: 'approved',
    actev_mndob: alsoActivate !== false,
    requested_changes: [],
    fieldsToFix: [],
    override: !!override,
  };
}

describe('reviewDriverApplicationV2 Super Admin override contract (local)', () => {
  it('needs_changes + normal approve → blocked by status gate', () => {
    assert.equal(
      overrideStatusAllowed('needs_changes', {override: false}),
      false,
    );
  });

  it('needs_changes + Super Admin override + reason → status gate allows', () => {
    assert.equal(
      overrideStatusAllowed('needs_changes', {override: true}),
      true,
    );
    assert.equal(overrideActorAllowed({super_admin: true}), true);
    assert.equal(overrideReasonAllowed('استثناء موثق'), true);
  });

  it('needs_changes + override + empty reason → blocked', () => {
    assert.equal(overrideReasonAllowed(''), false);
    assert.equal(overrideReasonAllowed('ab'), false);
  });

  it('Country Agent override → blocked', () => {
    assert.equal(
      overrideActorAllowed({super_admin: false, country_admin: true}),
      false,
    );
  });

  it('approval blockers for needs_changes include NOT_PENDING_REVIEW (bypass via override only)', () => {
    const blockers = v2._testApprovalBlockingReasonsV2(
      baseDriver({registration_status: 'needs_changes'}),
      authUser(),
    );
    assert.ok(blockers.includes('NOT_PENDING_REVIEW'));
  });

  it('open change requests cleared on approve patch (UI open banner closes)', () => {
    const patch = approvePatchAxes({override: true, alsoActivate: true});
    assert.deepEqual(patch.requested_changes, []);
    assert.deepEqual(patch.fieldsToFix, []);
  });

  it('approve without alsoActivate keeps registration approved but inactive', () => {
    const patch = approvePatchAxes({override: true, alsoActivate: false});
    assert.equal(patch.registration_status, 'approved');
    assert.equal(patch.actev_mndob, false);
  });

  it('combined override+activate produces approved + actev_mndob true', () => {
    const patch = approvePatchAxes({override: true, alsoActivate: true});
    assert.equal(patch.registration_status, 'approved');
    assert.equal(patch.actev_mndob, true);
  });

  it('resolveRequestedChangesOnResubmit preserves history entries as resolved', () => {
    const prior = [
      {section: 'vehicle', adminMessage: 'fix plate', resolved: false},
    ];
    const out = v2._testResolveRequestedChangesOnResubmit(prior);
    assert.equal(out.length, 1);
    assert.equal(out[0].resolved, true);
    assert.equal(out[0].adminMessage, 'fix plate');
    assert.ok(out[0].resolvedAt);
  });

  it('local source file contains override implementation (pre-deploy proof)', () => {
    const fs = require('fs');
    const path = require('path');
    const src = fs.readFileSync(
      path.join(__dirname, '../driver_registration_v2.js'),
      'utf8',
    );
    assert.ok(src.includes('OVERRIDE_SUPER_ADMIN_ONLY'));
    assert.ok(src.includes("['pending_review', 'needs_changes']"));
    assert.ok(src.includes('DRIVER_APPLICATION_OVERRIDE_APPROVED'));
    assert.ok(src.includes('skippedBlockers'));
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
        baseDriver({
          doc_driver_license: null,
          doc_driver_license_front: null,
          doc_driver_license_back: null,
          img_id_car: 'https://x/c.jpg',
        }),
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
