'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

const review = require(path.join(__dirname, '..', 'driver_document_review.js'));

describe('driver_document_review gates', () => {
  it('allRequiredDocumentsApproved requires approved reviewStatus', () => {
    const driver = {
      doc_national_id: {storagePath: 'users/a/uploads/x', reviewStatus: 'pending_review'},
      doc_vehicle_registration: {storagePath: 'users/a/uploads/y', reviewStatus: 'approved'},
      doc_driver_license: {storagePath: 'users/a/uploads/z', reviewStatus: 'approved'},
    };
    assert.equal(review.allRequiredDocumentsApproved(driver), false);
  });

  it('allRequiredDocumentsApproved passes when all approved', () => {
    const driver = {
      doc_national_id: {storagePath: 'users/a/uploads/x', reviewStatus: 'approved'},
      doc_vehicle_registration: {storagePath: 'users/a/uploads/y', reviewStatus: 'approved'},
      doc_driver_license: {storagePath: 'users/a/uploads/z', reviewStatus: 'approved'},
    };
    assert.equal(review.allRequiredDocumentsApproved(driver), true);
  });

  it('firstBlockingExpiredDocument null without country config', () => {
    const driver = {
      doc_driver_license: {
        reviewStatus: 'approved',
        expiryDate: new Date('2020-01-01T00:00:00Z'),
      },
    };
    assert.equal(review.firstBlockingExpiredDocument(driver, null, new Date('2026-08-26')), null);
  });

  it('firstBlockingExpiredDocument blocks expired configured doc', () => {
    const reqs = {
      driverLicense: {
        enabled: true,
        required: true,
        expiryRequired: true,
        operationalBlockingOnExpiry: true,
      },
    };
    const driver = {
      doc_driver_license: {
        reviewStatus: 'approved',
        expiryDate: new Date('2026-08-01T00:00:00Z'),
      },
    };
    assert.equal(
      review.firstBlockingExpiredDocument(driver, reqs, new Date('2026-08-26T12:00:00Z')),
      'driverLicense',
    );
  });

  it('buildExpiryEventId is deterministic', () => {
    const a = review.buildExpiryEventId({
      uid: 'u1',
      documentType: 'driverLicense',
      kind: 'expiring',
      expiryIso: '2026-09-01',
      threshold: '30',
    });
    const b = review.buildExpiryEventId({
      uid: 'u1',
      documentType: 'driverLicense',
      kind: 'expiring',
      expiryIso: '2026-09-01',
      threshold: '30',
    });
    assert.equal(a, b);
    assert.match(a, /^driver_document_expiring:/);
  });
});
