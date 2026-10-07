'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const docStatus = require('../driver_registration_document_status.js');

describe('driver_license front/back', () => {
  it('submit accepts front without back (back optional)', () => {
    const driver = {
      doc_driver_license_front: {storagePath: 'users/u/front.jpg'},
    };
    assert.equal(docStatus.isLicenseBackRequired(null), false);
    assert.equal(docStatus.driverLicenseSubmitOk(driver, null), true);
    assert.equal(docStatus.statusForType(driver, 'driver_license'), 'complete');
  });

  it('legacy approved driver remains readable', () => {
    const driver = {
      registration_status: 'approved',
      actev_mndob: true,
      doc_driver_license: {url: 'https://example.com/legacy.jpg'},
    };
    assert.equal(docStatus.isApprovedLegacyLicenseOnly(driver), true);
    assert.equal(docStatus.statusForType(driver, 'driver_license'), 'complete');
  });

  it('legacy alone satisfies license requirement', () => {
    const driver = {
      doc_driver_license: {storagePath: 'users/u/legacy.jpg'},
    };
    assert.equal(docStatus.satisfiesLicenseRequirement(driver), true);
    assert.equal(docStatus.statusForType(driver, 'driver_license'), 'complete');
  });

  it('back remains optional even if country config says required', () => {
    const driver = {
      doc_driver_license_front: {storagePath: 'users/u/front.jpg'},
    };
    const reqs = {driverLicenseBack: {required: true}};
    assert.equal(docStatus.isLicenseBackRequired(reqs), false);
    assert.equal(docStatus.driverLicenseSubmitOk(driver, reqs), true);
  });
});
