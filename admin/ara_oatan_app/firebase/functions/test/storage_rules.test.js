'use strict';

const fs = require('fs');
const path = require('path');
const {
  after,
  before,
  beforeEach,
  describe,
  it,
} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {doc, setDoc} = require('firebase/firestore');
const {getBytes, ref, uploadBytes} = require('firebase/storage');

const projectId = 'demo-touri-taxi';
const bucket = `${projectId}.appspot.com`;
const docPath = 'users/driver-sa/uploads/national_id.jpg';
let testEnv;

async function seedFirestore(dataByPath) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [documentPath, data] of Object.entries(dataByPath)) {
      await setDoc(doc(db, documentPath), data);
    }
  });
}

async function seedStorageObject(objectPath, bytes) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const storage = context.storage(bucket);
    await uploadBytes(ref(storage, objectPath), bytes, {
      contentType: 'image/jpeg',
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../firestore.rules'),
        'utf8',
      ),
    },
    storage: {
      host: '127.0.0.1',
      port: 9199,
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../storage.rules'),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

after(async () => {
  await testEnv.cleanup();
});

describe('Storage country-scoped driver documents', () => {
  beforeEach(async () => {
    await seedFirestore({
      'countries/sa': {name: 'Saudi Arabia'},
      'countries/eg': {name: 'Egypt'},
      'user/driver-sa': {ismndob: true, Rev_dolh: 'countries/sa'},
      'user/driver-eg': {ismndob: true, Rev_dolh: 'countries/eg'},
      'user/admin-sa': {isAdminRule: 2, Rev_dloh_agent: 'countries/sa'},
      'user/super-1': {IsAdmin: true},
      'user/customer-1': {ismndob: false},
    });
    await seedStorageObject(docPath, Uint8Array.from([0xff, 0xd8, 0xff]));
  });

  it('DRIVER_OWN_DOC_READ = PASS', async () => {
    const storage = testEnv.authenticatedContext('driver-sa').storage(bucket);
    await assertSucceeds(getBytes(ref(storage, docPath)));
  });

  it('DRIVER_OTHER_DOC_DENY = PASS', async () => {
    const storage = testEnv.authenticatedContext('driver-eg').storage(bucket);
    await assertFails(getBytes(ref(storage, docPath)));
  });

  it('SUPERADMIN_DOC_READ = PASS', async () => {
    const storage = testEnv
      .authenticatedContext('super-1', {super_admin: true})
      .storage(bucket);
    await assertSucceeds(getBytes(ref(storage, docPath)));
  });

  it('COUNTRY_ADMIN_SAME_COUNTRY = PASS', async () => {
    const storage = testEnv
      .authenticatedContext('admin-sa', {
        super_admin: false,
        country_admin: true,
        country_id: 'countries/sa',
      })
      .storage(bucket);
    await assertSucceeds(getBytes(ref(storage, docPath)));
  });

  it('COUNTRY_ADMIN_OTHER_COUNTRY_DENY = PASS', async () => {
    await seedFirestore({
      'user/admin-eg': {isAdminRule: 2, Rev_dloh_agent: 'countries/eg'},
    });
    const storage = testEnv
      .authenticatedContext('admin-eg', {
        super_admin: false,
        country_admin: true,
        country_id: 'countries/eg',
      })
      .storage(bucket);
    await assertFails(getBytes(ref(storage, docPath)));
  });

  it('ANONYMOUS_DENY = PASS', async () => {
    const storage = testEnv.unauthenticatedContext().storage(bucket);
    await assertFails(getBytes(ref(storage, docPath)));
  });

  it('PUBLIC_BYPASS_DENY = PASS', async () => {
    const storage = testEnv
      .authenticatedContext('customer-1')
      .storage(bucket);
    await assertFails(getBytes(ref(storage, docPath)));
  });
});

describe('Storage upload security', () => {
  beforeEach(async () => {
    await seedFirestore({
      'user/driver-sa': {ismndob: true},
      'user/driver-eg': {ismndob: true},
    });
  });

  it('EXECUTABLE_MIME_DENY = PASS', async () => {
    const storage = testEnv.authenticatedContext('driver-sa').storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'users/driver-sa/uploads/evil.exe'),
        Uint8Array.from([0x4d, 0x5a, 0x90, 0x00]),
        {contentType: 'application/x-msdownload'},
      ),
    );
  });

  it('OVERSIZED_UPLOAD_DENY = PASS', async () => {
    const storage = testEnv.authenticatedContext('driver-sa').storage(bucket);
    const oversized = new Uint8Array(15 * 1024 * 1024 + 1);
    await assertFails(
      uploadBytes(
        ref(storage, 'users/driver-sa/uploads/huge.jpg'),
        oversized,
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('WRONG_USER_PATH_DENY = PASS', async () => {
    const storage = testEnv.authenticatedContext('driver-sa').storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'users/driver-eg/uploads/stolen.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff]),
        {contentType: 'image/jpeg'},
      ),
    );
  });
});

describe('Storage type_car vehicle images', () => {
  const carPath = 'type_car/uploads/qa_car.jpg';

  beforeEach(async () => {
    await seedFirestore({
      'user/super-1': {IsAdmin: true},
      'user/admin-sa': {isAdminRule: 2, Rev_dloh_agent: 'countries/sa'},
      'user/customer-1': {ismndob: false},
      'user/driver-1': {ismndob: true},
      'user/partner-1': {isAdminRule: 3, isPartner: true},
      'user/company-1': {isAdminRule: 4},
    });
    await seedStorageObject(carPath, Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]));
  });

  it('customer can read type_car image', async () => {
    const storage = testEnv.authenticatedContext('customer-1').storage(bucket);
    await assertSucceeds(getBytes(ref(storage, carPath)));
  });

  it('unauthenticated can read type_car image', async () => {
    const storage = testEnv.unauthenticatedContext().storage(bucket);
    await assertSucceeds(getBytes(ref(storage, carPath)));
  });

  it('super admin can upload/replace type_car image', async () => {
    const storage = testEnv
      .authenticatedContext('super-1', {super_admin: true})
      .storage(bucket);
    await assertSucceeds(
      uploadBytes(
        ref(storage, 'type_car/uploads/qa_new.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
    await assertSucceeds(
      uploadBytes(
        ref(storage, carPath),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xaa, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('customer cannot write type_car image', async () => {
    const storage = testEnv.authenticatedContext('customer-1').storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'type_car/uploads/hack.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('driver cannot write global type_car image', async () => {
    const storage = testEnv.authenticatedContext('driver-1').storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'type_car/uploads/hack.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('partner cannot write type_car image', async () => {
    const storage = testEnv.authenticatedContext('partner-1').storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'type_car/uploads/hack.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('transport company cannot write global type_car image', async () => {
    const storage = testEnv.authenticatedContext('company-1').storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'type_car/uploads/hack.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('country admin cannot write type_car image (storage super-only)', async () => {
    const storage = testEnv
      .authenticatedContext('admin-sa', {
        country_admin: true,
        country_id: 'countries/sa',
      })
      .storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'type_car/uploads/hack.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });
});


describe('Customer profile photo upload', () => {
  const uid = 'customer-photo-1';
  const path = `users/${uid}/profile.jpg`;

  beforeEach(async () => {
    await seedFirestore({
      [`user/${uid}`]: {ismndob: false},
      'user/other-user': {ismndob: false},
    });
  });

  it('OWNER_PROFILE_UPLOAD_ALLOW = PASS', async () => {
    const storage = testEnv.authenticatedContext(uid).storage(bucket);
    await assertSucceeds(
      uploadBytes(
        ref(storage, path),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('CROSS_USER_PROFILE_UPLOAD_DENY = PASS', async () => {
    const storage = testEnv.authenticatedContext(uid).storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, 'users/other-user/profile.jpg'),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });

  it('ANONYMOUS_PROFILE_UPLOAD_DENY = PASS', async () => {
    const storage = testEnv.unauthenticatedContext().storage(bucket);
    await assertFails(
      uploadBytes(
        ref(storage, path),
        Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]),
        {contentType: 'image/jpeg'},
      ),
    );
  });
});
