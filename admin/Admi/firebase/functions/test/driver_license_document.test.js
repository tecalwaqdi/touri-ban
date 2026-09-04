'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const docStatus = require('../driver_registration_document_status.js');

describe('driver_license front/back', () => {
  it('submit requires front and back', () => {
    const driver = {
      doc_driver_license_front: {storagePath: 'users/u/front.jpg'},
    };
    assert.equal(docStatus.driverLicenseSubmitOk(driver, null), false);
    driver.doc_driver_license_back = {storagePath: 'users/u/back.jpg'};
    assert.equal(docStatus.driverLicenseSubmitOk(driver, null), true);
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

  it('optional back via country config', () => {
    const driver = {
      doc_driver_license_front: {storagePath: 'users/u/front.jpg'},
    };
    const reqs = {driverLicenseBack: {required: false}};
    assert.equal(docStatus.driverLicenseSubmitOk(driver, reqs), true);
  });
});
