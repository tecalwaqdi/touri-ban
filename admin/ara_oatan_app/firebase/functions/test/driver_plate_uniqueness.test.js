'use strict';

const assert = require('assert');
const v2 = require('../driver_registration_v2.js');

describe('driver plate normalization + uniqueness', () => {
  it('normalizePlate trims, uppercases, strips spaces/dashes', () => {
    assert.strictEqual(v2._testNormalizePlate(' abc-123 '), 'ABC123');
    assert.strictEqual(v2._testNormalizePlate('sa 12 34'), 'SA1234');
    assert.strictEqual(v2._testNormalizePlate(''), '');
  });

  it('plateClaimDocPath hashes normalized plate', () => {
    const a = v2._testPlateClaimDocPath(v2._testNormalizePlate('ABC123'));
    const b = v2._testPlateClaimDocPath(v2._testNormalizePlate('abc 123'));
    assert.strictEqual(a, b);
    assert.ok(a.startsWith('driver_vehicle_plate_claims/'));
    assert.strictEqual(v2._testPlateClaimDocPath('ab'), null);
  });

  it('plateClaimConflict allows same owner, rejects other owner', () => {
    assert.strictEqual(
      v2._testPlateClaimConflict({driverId: 'uid-a'}, 'uid-a'),
      null,
    );
    assert.strictEqual(
      v2._testPlateClaimConflict({driverId: 'uid-a'}, 'uid-b'),
      'PLATE_ALREADY_CLAIMED',
    );
    assert.strictEqual(v2._testPlateClaimConflict(null, 'uid-b'), null);
  });

  it('concurrent submit race: one succeeds, second rejected', async () => {
    const race = await v2._testSimulatePlateClaimRace({
      plateRaw: 'RACE1234',
      driverA: 'driver-a',
      driverB: 'driver-b',
    });
    assert.strictEqual(race.oneSucceeds, true, JSON.stringify(race));
    assert.strictEqual(race.secondRejected, true, JSON.stringify(race));
    assert.strictEqual(race.raceConditionSafe, true, JSON.stringify(race));
  });

  it('resubmit by same driver keeps claim', async () => {
    const first = await v2._testSimulatePlateClaimRace({
      plateRaw: 'SAME999',
      driverA: 'driver-x',
      driverB: 'driver-x',
    });
    assert.strictEqual(first.results.driverA.ok, true);
    assert.strictEqual(first.results.driverB.ok, true);
  });
});
