'use strict';

const assert = require('assert');
const v2 = require('../driver_registration_v2.js');

describe('registration E2E fixture gates', () => {
  it('submit passes with storagePath-only V2 docs', () => {
    const driver = {
      registration_flow_version: 2,
      registration_status: 'draft',
      ismndob: true,
      phoneNumber: '+966500000000',
      mndob_vill: {path: 'villages/x'},
      mndob_type_car: {path: 'type_car/y'},
      NameCar: 'Camry',
      ModelCar: '2020',
      number_lohh_car: 'ABC1234',
      photo_storage_path: 'users/u1/uploads/photo.jpg',
      doc_national_id: {
        storagePath: 'users/u1/uploads/id.jpg',
        status: 'uploaded',
      },
      doc_vehicle_registration: {
        storagePath: 'users/u1/uploads/car.jpg',
        status: 'uploaded',
      },
      doc_driver_license: {
        storagePath: 'users/u1/uploads/lic.jpg',
        status: 'uploaded',
      },
    };
    const blockers = v2._testSubmitBlockingReasons(driver, {
      emailVerified: true,
    });
    assert.deepStrictEqual(blockers, []);
  });

  it('reject flow still blocks approval from draft', () => {
    const blockers = v2._testApprovalBlockingReasonsV2(
      {
        registration_flow_version: 2,
        registration_status: 'draft',
        ismndob: true,
        phoneNumber: '+966500000000',
        mndob_vill: {},
        mndob_type_car: {},
        NameCar: 'x',
        ModelCar: '2020',
        number_lohh_car: 'P1',
        photo_url: 'https://x/p.jpg',
        img_id_rksh: 'https://x/id.jpg',
        img_id_car: 'https://x/car.jpg',
        doc_driver_license: {url: 'https://x/l.jpg'},
      },
      {emailVerified: true},
    );
    assert.ok(blockers.includes('NOT_PENDING_REVIEW'));
  });
});
