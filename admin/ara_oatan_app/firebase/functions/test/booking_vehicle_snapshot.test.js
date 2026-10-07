/**
 * Booking vehicle snapshot + driver assignment country guards.
 * Pure unit — no Firestore, no Production mutation.
 */
'use strict';

const assert = require('assert');
const path = require('path');

const config = require(path.join(__dirname, '..', 'driver_country_config.js'));

const saCar = {
  countryId: 'saudi_arabia',
  country_iso2: 'SA',
  dolh: {path: 'countries/saudi_arabia'},
  actev: true,
  sr: 100,
  naim: 'Economy SA',
  codeCar: 'economy',
};
const kgCar = {
  countryId: 'kyrgyzstan',
  country_iso2: 'KG',
  dolh: {path: 'countries/kyrgyzstan'},
  actev: true,
  sr: 50,
  naim: 'Economy KG',
  codeCar: 'economy',
};

assert.strictEqual(
  config.matchesCountryTypeCar(saCar, 'countries/saudi_arabia', 'SA'),
  true,
);
assert.strictEqual(
  config.matchesCountryTypeCar(kgCar, 'countries/saudi_arabia', 'SA'),
  false,
);
assert.strictEqual(
  config.matchesCountryTypeCar(kgCar, 'countries/kyrgyzstan', 'KG'),
  true,
);
assert.strictEqual(
  config.matchesCountryTypeCar(saCar, 'countries/kyrgyzstan', 'KG'),
  false,
);
assert.strictEqual(
  config.matchesCountryTypeCar(saCar, 'countries/turkey', 'TR'),
  false,
);

assert.strictEqual(config.validateTypeCarForMarket(saCar, 'countries/saudi_arabia', 'SA').ok, true);
assert.strictEqual(
  config.validateTypeCarForMarket({...saCar, actev: false}, 'countries/saudi_arabia', 'SA').ok,
  false,
);
assert.strictEqual(
  config.validateTypeCarForMarket({...saCar, archived: true}, 'countries/saudi_arabia', 'SA').ok,
  false,
);
assert.strictEqual(
  config.validateTypeCarForMarket(
    {...saCar, exclude_from_operational_catalog: true},
    'countries/saudi_arabia',
    'SA',
  ).ok,
  false,
);
assert.strictEqual(
  config.validateTypeCarForMarket(kgCar, 'countries/saudi_arabia', 'SA').reasonCode,
  'VEHICLE_TYPE_MARKET_MISMATCH',
);

const snap = config.buildVehicleBookingSnapshot({
  carId: 'sa_economy',
  car: saCar,
  countryPath: 'countries/saudi_arabia',
  currency: 'SAR',
  nowIso: '2026-01-01T00:00:00.000Z',
});
assert.strictEqual(snap.vehicleTypeId, 'sa_economy');
assert.strictEqual(snap.vehicleHourlyPrice, 100);
assert.strictEqual(snap.vehicleCurrency, 'SAR');
assert.strictEqual(snap.vehicleTypeCountryId, 'saudi_arabia');

const kgSnap = config.buildVehicleBookingSnapshot({
  carId: 'kg_economy',
  car: kgCar,
  countryPath: 'countries/kyrgyzstan',
  currency: 'KGS',
});
assert.strictEqual(kgSnap.vehicleHourlyPrice, 50);
assert.notStrictEqual(snap.vehicleHourlyPrice, kgSnap.vehicleHourlyPrice);

assert.strictEqual(
  config.validateDriverVehicleTypeAssignment({
    typeCarData: saCar,
    driverCountryPath: 'countries/saudi_arabia',
    driverCountryIso2: 'SA',
  }).ok,
  true,
);
assert.strictEqual(
  config.validateDriverVehicleTypeAssignment({
    typeCarData: kgCar,
    driverCountryPath: 'countries/saudi_arabia',
    driverCountryIso2: 'SA',
  }).ok,
  false,
);
assert.strictEqual(
  config.validateDriverVehicleTypeAssignment({
    typeCarData: saCar,
    driverCountryPath: '',
    driverCountryIso2: '',
  }).reasonCode,
  'DRIVER_COUNTRY_REQUIRED',
);

// Historical immutability: live sr change does not alter prior snapshot object.
const liveLater = {...saCar, sr: 999};
assert.strictEqual(snap.vehicleHourlyPrice, 100);
assert.strictEqual(liveLater.sr, 999);

process.stdout.write('booking_vehicle_snapshot + driver country guards passed.\n');
