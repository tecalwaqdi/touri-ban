'use strict';

const assert = require('assert');
const {
  normalizeCountryPath,
  applyCountryAdminCreateLock,
} = require('../panel_user_country_lock.js');

class HttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

describe('panel_user_country_lock', () => {
  it('normalizes country paths', () => {
    assert.equal(normalizeCountryPath('countries/kg'), 'countries/kg');
    assert.equal(normalizeCountryPath('kg'), 'countries/kg');
    assert.equal(normalizeCountryPath({path: 'countries/kg'}), 'countries/kg');
  });

  it('forces Rev_dolh from country_admin claim (own-country create)', () => {
    const userData = {display_name: 'A', Rev_dolh: 'countries/kyrgyzstan'};
    applyCountryAdminCreateLock(
      userData,
      {country_admin: true, country_id: 'countries/kyrgyzstan'},
      {HttpsError},
    );
    assert.equal(userData.Rev_dolh, 'countries/kyrgyzstan');
    assert.equal(userData.Rev_dloh_agent, 'countries/kyrgyzstan');
  });

  it('rejects foreign Rev_dolh (India)', () => {
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {Rev_dolh: 'countries/india'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
  });

  it('rejects foreign Rev_dolh (Spain)', () => {
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {Rev_dolh: 'countries/spain'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
  });

  it('rejects privileged Super Admin elevation', () => {
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {isAdmin: true, Rev_dolh: 'countries/kyrgyzstan'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
  });

  it('rejects privileged agent / accountant elevation', () => {
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {Isagent: true, Rev_dolh: 'countries/kyrgyzstan'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
    assert.throws(
      () =>
        applyCountryAdminCreateLock(
          {isAdminRule: 5, Rev_dolh: 'countries/kyrgyzstan'},
          {country_admin: true, country_id: 'countries/kyrgyzstan'},
          {HttpsError},
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
  });

  it('allows driver flag without privileged elevation', () => {
    const userData = {
      ismndob: true,
      Rev_dolh: 'countries/kyrgyzstan',
    };
    applyCountryAdminCreateLock(
      userData,
      {country_admin: true, country_id: 'countries/kyrgyzstan'},
      {HttpsError},
    );
    assert.equal(userData.Rev_dolh, 'countries/kyrgyzstan');
    assert.equal(userData.ismndob, true);
  });

  it('ignores super_admin', () => {
    const userData = {Rev_dolh: 'countries/nigeria'};
    applyCountryAdminCreateLock(
      userData,
      {super_admin: true, country_admin: true, country_id: 'countries/kg'},
      {HttpsError},
    );
    assert.equal(userData.Rev_dolh, 'countries/nigeria');
  });
});
