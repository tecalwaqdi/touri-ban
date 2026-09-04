'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

const regNotif = require(path.join(
  __dirname,
  '..',
  'driver_registration_notifications.js',
));

describe('driver_registration_notifications localize', () => {
  it('document review copy resolves all 7 locales', () => {
    for (const key of [
      'driver_document_approved',
      'driver_document_needs_changes',
      'driver_document_expired',
      'driver_document_expiring',
    ]) {
      for (const locale of ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt']) {
        const {title, body} = regNotif.localize(key, locale, {
          reason: 'test reason',
        });
        assert.ok(title.length > 0, `${key}/${locale} title`);
        assert.ok(body.length > 0, `${key}/${locale} body`);
        if (locale === 'fr' && key === 'driver_document_needs_changes') {
          assert.notEqual(title, 'Document needs changes');
        }
      }
    }
  });

  it('fr document needs changes is not English', () => {
    const {title} = regNotif.localize('driver_document_needs_changes', 'fr', {
      reason: 'x',
    });
    assert.notEqual(title, 'Document needs changes');
  });
});
