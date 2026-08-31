'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const countryConfig = require('../driver_country_config.js');

test('operationalBaseline has safe auto-seed blocking defaults', () => {
  const baseline = countryConfig.operationalBaseline();
  assert.equal(baseline.driverLicense.operationalBlockingOnExpiry, false);
  assert.equal(baseline.vehicleRegistration.operationalBlockingOnExpiry, false);
  assert.equal(baseline.vehicleInsurance.required, false);
  assert.equal(baseline.profilePhoto.enabled, true);
});

test('classifyRequirements distinguishes missing empty configured malformed', () => {
  assert.equal(countryConfig.classifyRequirements(null), 'missing');
  assert.equal(countryConfig.classifyRequirements({}), 'empty');
  assert.equal(
    countryConfig.classifyRequirements({
      profilePhoto: {enabled: true, required: true},
    }),
    'configured',
  );
  assert.equal(countryConfig.classifyRequirements([]), 'malformed');
});

test('buildInitializationPatch preserves configured custom config', () => {
  const custom = {
    profilePhoto: {enabled: true, required: false},
    nationalId: {enabled: true, required: true},
  };
  assert.equal(countryConfig.buildInitializationPatch(custom), null);
  assert.ok(countryConfig.buildInitializationPatch(null));
  assert.ok(countryConfig.buildInitializationPatch({}));
});

test('validateTypeCarForMarket rejects cross-market refs', () => {
  const car = {
    actev: true,
    country_iso2: 'KG',
    dolh: {path: 'countries/kyrgyzstan'},
  };
  const ok = countryConfig.validateTypeCarForMarket(
    car,
    'countries/kyrgyzstan',
    'KG',
  );
  assert.equal(ok.ok, true);
  const bad = countryConfig.validateTypeCarForMarket(
    car,
    'countries/saudi_arabia',
    'SA',
  );
  assert.equal(bad.reasonCode, 'VEHICLE_TYPE_MARKET_MISMATCH');
});

test('evaluateMarketReadiness requires requirements and catalog', () => {
  const ready = countryConfig.evaluateMarketReadiness({
    enabledRequirements: 3,
    activeVehicles: 2,
    acctev: true,
  });
  assert.equal(ready.registrationReady, true);
  const noCars = countryConfig.evaluateMarketReadiness({
    enabledRequirements: 3,
    activeVehicles: 0,
    acctev: true,
  });
  assert.equal(noCars.reasonCode, 'MISSING_VEHICLE_CATALOG');
});
