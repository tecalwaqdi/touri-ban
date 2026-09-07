'use strict';

/**
 * F3-C3R2 — Firestore rules emulator gate for agent assignment isolation.
 * Uses the C3D-intended rules (prod + C3-only agent patches).
 */

const fs = require('fs');
const path = require('path');
const assert = require('node:assert/strict');
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
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  collection,
  getDocs,
  query,
  limit,
} = require('firebase/firestore');

const projectId = 'demo-touri-f3c3r2';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');
let testEnv;

async function seed(dataByPath) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [documentPath, data] of Object.entries(dataByPath)) {
      await setDoc(doc(db, documentPath), data);
    }
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(rulesPath, 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

describe('F3-C3R2 agent assignment rules', () => {
  it('blocks direct Isagent / actev_user / country / date assignment mutations', async () => {
    await seed({
      'countries/sa': {naim: 'SA'},
      'user/agent-1': {
        Isagent: true,
        actev_user: true,
        display_name: 'A',
        phone_number: '1',
        photo_url: 'p',
        Rev_dloh_agent: doc(
          testEnv.authenticatedContext('seed').firestore(),
          'countries/sa',
        ),
      },
    });
    // Fix seed with rules disabled for reference field
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'user/agent-1'), {
        Isagent: true,
        actev_user: true,
        display_name: 'A',
        phone_number: '1',
        photo_url: 'p',
        Rev_dloh_agent: doc(ctx.firestore(), 'countries/sa'),
        agent_date_reg: new Date('2020-01-01'),
        agent_date_end: new Date('2030-01-01'),
      });
    });

    const superDb = testEnv
      .authenticatedContext('super-1', {super_admin: true})
      .firestore();

    await assertFails(updateDoc(doc(superDb, 'user', 'agent-1'), {Isagent: false}));
    await assertFails(updateDoc(doc(superDb, 'user', 'agent-1'), {actev_user: false}));
    await assertFails(
      updateDoc(doc(superDb, 'user', 'agent-1'), {
        Rev_dloh_agent: doc(superDb, 'countries', 'other'),
      }),
    );
    await assertFails(
      updateDoc(doc(superDb, 'user', 'agent-1'), {
        agent_date_reg: new Date('2021-01-01'),
      }),
    );
    await assertFails(
      updateDoc(doc(superDb, 'user', 'agent-1'), {
        agent_date_end: new Date('2029-01-01'),
      }),
    );
  });

  it('allows normal name / phone / photo edits for Super Admin', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'countries/sa'), {naim: 'SA'});
      await setDoc(doc(ctx.firestore(), 'user/agent-1'), {
        Isagent: true,
        actev_user: true,
        display_name: 'A',
        phone_number: '1',
        photo_url: 'p',
        Rev_dloh_agent: doc(ctx.firestore(), 'countries/sa'),
      });
    });
    const superDb = testEnv
      .authenticatedContext('super-1', {super_admin: true})
      .firestore();
    await assertSucceeds(
      updateDoc(doc(superDb, 'user', 'agent-1'), {display_name: 'B'}),
    );
    await assertSucceeds(
      updateDoc(doc(superDb, 'user', 'agent-1'), {phone_number: '2'}),
    );
    await assertSucceeds(
      updateDoc(doc(superDb, 'user', 'agent-1'), {photo_url: 'q'}),
    );
  });

  it('Country Admin cannot mutate foreign-country agent assignment', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'countries/sa'), {naim: 'SA'});
      await setDoc(doc(ctx.firestore(), 'countries/ae'), {naim: 'AE'});
      await setDoc(doc(ctx.firestore(), 'user/agent-sa'), {
        Isagent: true,
        actev_user: true,
        display_name: 'SA Agent',
        Rev_dloh_agent: doc(ctx.firestore(), 'countries/sa'),
      });
    });
    const aeAdmin = testEnv
      .authenticatedContext('ae-admin', {
        country_admin: true,
        country_id: 'countries/ae',
      })
      .firestore();
    await assertFails(
      updateDoc(doc(aeAdmin, 'user', 'agent-sa'), {actev_user: false}),
    );
    await assertFails(
      updateDoc(doc(aeAdmin, 'user', 'agent-sa'), {display_name: 'hack'}),
    );
  });

  it('Country Agent cannot mutate assignment fields', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'countries/sa'), {naim: 'SA'});
      await setDoc(doc(ctx.firestore(), 'user/agent-1'), {
        Isagent: true,
        actev_user: true,
        display_name: 'A',
        Rev_dloh_agent: doc(ctx.firestore(), 'countries/sa'),
      });
    });
    const agentDb = testEnv
      .authenticatedContext('agent-1', {agent: true, country_id: 'countries/sa'})
      .firestore();
    await assertFails(
      updateDoc(doc(agentDb, 'user', 'agent-1'), {actev_user: false}),
    );
    await assertFails(
      updateDoc(doc(agentDb, 'user', 'agent-1'), {Isagent: false}),
    );
  });

  it('customer self profile name/phone/photo still allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'user/cust-1'), {
        Isagent: false,
        display_name: 'C',
        phone_number: '1',
        photo_url: 'p',
      });
    });
    const db = testEnv.authenticatedContext('cust-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'user', 'cust-1'), {display_name: 'C2'}),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'user', 'cust-1'), {phone_number: '9'}),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'user', 'cust-1'), {photo_url: 'px'}),
    );
  });

  it('driver online toggle still allowed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'user/drv-1'), {
        ismndob: true,
        actev_mndob: true,
        is_online: false,
        registration_status: 'approved',
        registration_flow_version: 2,
      });
    });
    const db = testEnv.authenticatedContext('drv-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'user', 'drv-1'), {
        is_online: true,
        last_online_at: new Date(),
      }),
    );
  });

  it('customer cannot create orders client-side (booking unchanged)', async () => {
    const db = testEnv.authenticatedContext('cust-1').firestore();
    await assertFails(
      setDoc(doc(db, 'order', 'o1'), {
        USER: doc(db, 'user', 'cust-1'),
        PaymentMethod: 'Cash',
        total: 1,
      }),
    );
  });

  it('driver trip advance still works; terminal regress still blocked', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'user/drv-1'), {ismndob: true, actev_mndob: true});
      await setDoc(doc(db, 'order/trip-1'), {
        mndob_user: doc(db, 'user/drv-1'),
        status_code: 'driver_assigned',
        total: 10,
        total_mndob: 5,
      });
      await setDoc(doc(db, 'order/done-1'), {
        mndob_user: doc(db, 'user/drv-1'),
        status_code: 'completed',
        total: 10,
        total_mndob: 5,
      });
    });
    const db = testEnv.authenticatedContext('drv-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'order', 'trip-1'), {
        status_code: 'driver_arriving',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'order', 'done-1'), {
        status_code: 'driver_arriving',
      }),
    );
  });

  it('chat + landmark reads unchanged for signed-in users', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'chat/c1'), {
        text: 'hi',
        user1: doc(db, 'user/cust-1'),
      });
      await setDoc(doc(db, 'mkan/m1'), {naim: 'spot'});
    });
    const db = testEnv.authenticatedContext('cust-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'chat', 'c1')));
    await assertSucceeds(getDoc(doc(db, 'mkan', 'm1')));
  });

  it('lock collection is client-write denied', async () => {
    const superDb = testEnv
      .authenticatedContext('super-1', {super_admin: true})
      .firestore();
    await assertFails(
      setDoc(doc(superDb, 'agent_country_assignment', 'sa'), {
        country_path: 'countries/sa',
        active_agent_id: 'x',
      }),
    );
  });
});

// Keep unused import lint quiet for environments without collection queries.
void collection;
void getDocs;
void query;
void limit;
void assert;
