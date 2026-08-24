'use strict';

const assert = require('assert');

function isCountryAdminUser(u) {
  return u.isagent === true || u.Isagent === true || u.country_admin === true;
}

function isAdminUser(u) {
  return u.IsAdmin === true || u.isAdmin === true || u.isAdminRule === 1;
}

function filterAdminRecipients(adminDocs, countryRef) {
  const out = [];
  for (const doc of adminDocs) {
    const u = doc.data || doc;
    if (!isAdminUser(u) && !isCountryAdminUser(u)) continue;
    if (isCountryAdminUser(u) && !isAdminUser(u)) {
      const agentCountry = u.Rev_dloh_agent;
      if (
        countryRef &&
        agentCountry &&
        agentCountry.path &&
        countryRef.path &&
        agentCountry.path !== countryRef.path
      ) {
        continue;
      }
      if (!countryRef) continue;
    }
    out.push(doc);
  }
  return out;
}

describe('admin notification country scope', () => {
  const sa = {path: 'countries/sa'};
  const eg = {path: 'countries/eg'};

  it('SuperAdmin receives Saudi application', () => {
    const admins = [
      {id: 'super1', data: {IsAdmin: true, fcm_token: 't1'}},
    ];
    const got = filterAdminRecipients(admins, sa);
    assert.strictEqual(got.length, 1);
  });

  it('Saudi Country Admin receives Saudi application', () => {
    const admins = [
      {
        id: 'sa-agent',
        data: {isagent: true, Rev_dloh_agent: sa, fcm_token: 't2'},
      },
    ];
    const got = filterAdminRecipients(admins, sa);
    assert.strictEqual(got.length, 1);
  });

  it('Egypt Country Admin does NOT receive Saudi application', () => {
    const admins = [
      {
        id: 'eg-agent',
        data: {isagent: true, Rev_dloh_agent: eg, fcm_token: 't3'},
      },
    ];
    const got = filterAdminRecipients(admins, sa);
    assert.strictEqual(got.length, 0);
  });
});
