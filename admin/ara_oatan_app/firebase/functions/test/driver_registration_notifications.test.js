'use strict';

const assert = require('assert');
const notif = require('../driver_registration_notifications.js');

describe('driver_registration_notifications', () => {
  it('localizes ar/en/ur with reason template', () => {
    const ar = notif.localize('driver_rejected', 'ar', {reason: 'وثيقة ناقصة'});
    assert.ok(ar.title.includes('رفض') || ar.title.length > 0);
    assert.ok(ar.body.includes('وثيقة ناقصة'));
    assert.ok(!ar.body.includes('{reason}'));

    const en = notif.localize('driver_rejected', 'en', {reason: 'missing doc'});
    assert.ok(en.body.includes('missing doc'));

    const ur = notif.localize('driver_rejected', 'ur', {reason: 'xyz'});
    assert.ok(ur.body.includes('xyz'));
  });

  it('falls back to en for unknown locale', () => {
    const copy = notif.localize('driver_approved', 'zz');
    const en = notif.localize('driver_approved', 'en');
    assert.strictEqual(copy.title, en.title);
  });

  it('shortReason truncates', () => {
    const long = 'x'.repeat(120);
    const s = notif.shortReason(long, 80);
    assert.ok(s.length <= 80);
  });

  it('driverIsOperationallyApproved V2 requires approved+actev', () => {
    assert.strictEqual(
      notif.driverIsOperationallyApproved({
        registration_flow_version: 2,
        registration_status: 'pending_review',
        actev_mndob: false,
        ismndob: true,
      }),
      false,
    );
    assert.strictEqual(
      notif.driverIsOperationallyApproved({
        registration_flow_version: 2,
        registration_status: 'approved',
        actev_mndob: true,
      }),
      true,
    );
  });

  it('legacy driver with actev remains approved', () => {
    assert.strictEqual(
      notif.driverIsOperationallyApproved({
        ismndob: true,
        actev_mndob: true,
      }),
      true,
    );
  });
});
