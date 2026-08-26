const fs = require("fs");
const path = require("path");
const {
  after,
  before,
  beforeEach,
  describe,
  it,
} = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  Timestamp,
} = require("firebase/firestore");

const projectId = "demo-touri-taxi";
let testEnv;

function countryRef(db, id) {
  return doc(db, "countries", id);
}

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
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

describe("Firestore P0 authorization boundaries", () => {
  it("rejects direct client order creation", async () => {
    const db = testEnv
      .authenticatedContext("customer-1")
      .firestore();
    await assertFails(setDoc(doc(db, "order", "cash-1"), {
      USER: doc(db, "user", "customer-1"),
      PaymentMethod: "Cash",
      total: 1,
      amount_halalas: 100,
      status_code: "pending_driver",
    }));
  });

  it("rejects country-admin privilege escalation", async () => {
    const seedDb = testEnv
      .authenticatedContext("seed-paths")
      .firestore();
    const saudi = countryRef(seedDb, "sa");
    await seed({
      "user/admin-sa": {
        isAdminRule: 2,
        Rev_dloh_agent: saudi,
      },
      "user/target": {
        isAdminRule: 0,
        IsAdmin: false,
        Rev_dolh: saudi,
      },
    });

    const db = testEnv.authenticatedContext("admin-sa", {
      country_admin: true,
      country_id: "countries/sa",
    }).firestore();
    await assertFails(updateDoc(doc(db, "user", "target"), {
      IsAdmin: true,
      isAdminRule: 1,
    }));
  });

  it("allows assigned driver to get order details", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const driver = doc(seedDb, "user", "driver-1");
    const customer = doc(seedDb, "user", "customer-1");
    await seed({
      "user/driver-1": {
        ismndob: true,
        actev_mndob: true,
        registration_status: "approved",
      },
      "user/customer-1": { isAdminRule: 0 },
      "order/details-1": {
        USER: customer,
        mndob_user: driver,
        status_code: "driver_assigned",
        ActiveOrder: true,
        IDorder: "CASH-DETAILS1",
        total: 100,
      },
    });

    const db = testEnv.authenticatedContext("driver-1", {
      driver: true,
      driver_active: true,
    }).firestore();
    await assertSucceeds(getDoc(doc(db, "order", "details-1")));
  });

  it("rejects other driver getting assigned order details", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const driver = doc(seedDb, "user", "driver-1");
    await seed({
      "user/driver-1": {
        ismndob: true,
        actev_mndob: true,
        registration_status: "approved",
      },
      "user/driver-2": {
        ismndob: true,
        actev_mndob: true,
        registration_status: "approved",
      },
      "order/details-2": {
        mndob_user: driver,
        status_code: "driver_assigned",
        ActiveOrder: true,
      },
    });

    const db = testEnv.authenticatedContext("driver-2", {
      driver: true,
      driver_active: true,
    }).firestore();
    await assertFails(getDoc(doc(db, "order", "details-2")));
  });

  it("allows customer to get own order details", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const customer = doc(seedDb, "user", "customer-1");
    await seed({
      "user/customer-1": { isAdminRule: 0 },
      "order/details-3": {
        USER: customer,
        status_code: "pending_driver",
        ActiveOrder: false,
      },
    });

    const db = testEnv.authenticatedContext("customer-1").firestore();
    await assertSucceeds(getDoc(doc(db, "order", "details-3")));
  });

  it("allows an assigned driver to mark arrival", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const driver = doc(seedDb, "user", "driver-1");
    await seed({
      "user/driver-1": {
        ismndob: true,
        actev_mndob: true,
      },
      "order/trip-1": {
        mndob_user: driver,
        status_code: "driver_assigned",
        ActiveOrder: true,
      },
    });

    const db = testEnv.authenticatedContext("driver-1", {
      driver: true,
      driver_active: true,
    }).firestore();
    await assertSucceeds(updateDoc(doc(db, "order", "trip-1"), {
      status_code: "driver_arrived",
      ActiveOrder: true,
    }));
  });

  it("rejects skipping from assigned directly to completed", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const driver = doc(seedDb, "user", "driver-1");
    await seed({
      "user/driver-1": {
        ismndob: true,
        actev_mndob: true,
      },
      "order/trip-2": {
        mndob_user: driver,
        status_code: "driver_assigned",
        ActiveOrder: true,
      },
    });

    const db = testEnv.authenticatedContext("driver-1", {
      driver: true,
      driver_active: true,
    }).firestore();
    await assertFails(updateDoc(doc(db, "order", "trip-2"), {
      status_code: "completed",
      ActiveOrder: false,
    }));
  });

  it("rejects driver mutation of financial fields", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const driver = doc(seedDb, "user", "driver-1");
    await seed({
      "user/driver-1": {
        ismndob: true,
        actev_mndob: true,
      },
      "order/trip-3": {
        mndob_user: driver,
        status_code: "driver_arrived",
        ActiveOrder: true,
        total: 100,
      },
    });

    const db = testEnv.authenticatedContext("driver-1", {
      driver: true,
    }).firestore();
    await assertFails(updateDoc(doc(db, "order", "trip-3"), {
      status_code: "trip_in_progress",
      total: 1,
    }));
  });

  it("allows customer to cancel own pending cash order", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const customer = doc(seedDb, "user", "customer-1");
    await seed({
      "user/customer-1": {
        isAdminRule: 0,
      },
      "order/cash-pending-1": {
        USER: customer,
        PaymentMethod: "Cash",
        payment_status: "pending_cash",
        status_code: "pending_driver",
        halh_text: "بانتظار قبول السائق",
        ALLNOW: true,
        ActiveOrder: false,
        total: 100,
        amount_halalas: 10000,
        mndob_user: null,
        // Within first hour — cancel allowed while still unassigned.
        data_order: Timestamp.fromDate(new Date(Date.now() - 10 * 60 * 1000)),
      },
    });

    const db = testEnv.authenticatedContext("customer-1").firestore();
    await assertSucceeds(updateDoc(doc(db, "order", "cash-pending-1"), {
      status_code: "cancelled",
      cancelled_by_code: "cancelled_by_customer",
      ActiveOrder: false,
      ALLNOW: false,
      halh_order: "Canceled",
      halh: "cancelled",
      halh_text: "ملغي",
      NotSestem: "customer_cancelled",
      cancelReason: "customer_cancelled",
      cancellationReason: "customer_cancelled",
      cancelledBy: "customer-1",
    }));
  });

  it("rejects other customer cancelling someone else's order", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const customer = doc(seedDb, "user", "customer-1");
    await seed({
      "order/cash-pending-2": {
        USER: customer,
        PaymentMethod: "Cash",
        payment_status: "pending_cash",
        status_code: "pending_driver",
        ALLNOW: true,
        ActiveOrder: false,
        total: 50,
        amount_halalas: 5000,
      },
    });

    const db = testEnv.authenticatedContext("customer-2").firestore();
    await assertFails(updateDoc(doc(db, "order", "cash-pending-2"), {
      status_code: "cancelled",
      ALLNOW: false,
      ActiveOrder: false,
      halh_text: "ملغي",
      NotSestem: "customer_cancelled",
    }));
  });

  it("rejects customer cancel after trip completed", async () => {
    const seedDb = testEnv.authenticatedContext("seed-paths").firestore();
    const customer = doc(seedDb, "user", "customer-1");
    await seed({
      "order/done-1": {
        USER: customer,
        PaymentMethod: "Cash",
        payment_status: "cash_collected",
        status_code: "completed",
        ALLNOW: false,
        ActiveOrder: false,
        total: 50,
        amount_halalas: 5000,
      },
    });

    const db = testEnv.authenticatedContext("customer-1").firestore();
    await assertFails(updateDoc(doc(db, "order", "done-1"), {
      status_code: "cancelled",
      ALLNOW: false,
      ActiveOrder: false,
      halh_text: "ملغي",
      NotSestem: "customer_cancelled",
    }));
  });
});

describe("Email OTP challenge client denial", () => {
  it("customer cannot create email_verification_challenges", async () => {
    const db = testEnv.authenticatedContext("customer-otp-1").firestore();
    await assertFails(setDoc(doc(db, "email_verification_challenges", "c1"), {
      uid: "customer-otp-1",
      otpHash: "x",
      purpose: "email_verification",
    }));
  });

  it("customer cannot read email_verification_challenges", async () => {
    await seed({
      "email_verification_challenges/c1": {
        uid: "customer-otp-1",
        otpHash: "x",
        purpose: "email_verification",
      },
    });
    const db = testEnv.authenticatedContext("customer-otp-1").firestore();
    await assertFails(getDoc(doc(db, "email_verification_challenges", "c1")));
  });

  it("customer cannot update or delete email_verification_challenges", async () => {
    await seed({
      "email_verification_challenges/c1": {
        uid: "customer-otp-1",
        otpHash: "x",
        purpose: "email_verification",
      },
    });
    const db = testEnv.authenticatedContext("customer-otp-1").firestore();
    await assertFails(updateDoc(doc(db, "email_verification_challenges", "c1"), {
      attemptCount: 1,
    }));
    await assertFails(setDoc(doc(db, "email_verification_challenges", "c1"), {
      uid: "customer-otp-1",
      otpHash: "y",
    }));
  });

  it("driver cannot read/write OTP challenges or rate limits", async () => {
    await seed({
      "email_verification_challenges/d1": {
        uid: "driver-otp-1",
        otpHash: "x",
        purpose: "email_verification",
      },
      "email_otp_rate_limits/uid_driver-otp-1_bucket": {count: 1},
      "email_otp_cooldown/driver-otp-1": {lastSentAt: Timestamp.now()},
    });
    const db = testEnv.authenticatedContext("driver-otp-1").firestore();
    await assertFails(getDoc(doc(db, "email_verification_challenges", "d1")));
    await assertFails(setDoc(doc(db, "email_verification_challenges", "d2"), {
      uid: "driver-otp-1",
      otpHash: "z",
    }));
    await assertFails(getDoc(doc(db, "email_otp_rate_limits", "uid_driver-otp-1_bucket")));
    await assertFails(getDoc(doc(db, "email_otp_cooldown", "driver-otp-1")));
  });

  it("other authenticated user cannot access another user's OTP challenge", async () => {
    await seed({
      "email_verification_challenges/c1": {
        uid: "customer-otp-1",
        otpHash: "x",
        purpose: "email_verification",
      },
    });
    const db = testEnv.authenticatedContext("customer-otp-2").firestore();
    await assertFails(getDoc(doc(db, "email_verification_challenges", "c1")));
    await assertFails(updateDoc(doc(db, "email_verification_challenges", "c1"), {
      attemptCount: 99,
    }));
  });
});

describe("type_car vehicle catalog authorization", () => {
  beforeEach(async () => {
    await seed({
      "type_car/economy_qa": {
        naim: "Economy QA",
        sr: 100,
        actev: true,
        codeCar: "economy_qa",
      },
      "user/super-1": {IsAdmin: true, isAdminRule: 1},
      "user/admin-sa": {isAdminRule: 2, Rev_dloh_agent: "countries/sa"},
      "user/customer-1": {isAdminRule: 0},
      "user/driver-1": {ismndob: true},
      "user/partner-1": {isAdminRule: 3, isPartner: true},
      "user/company-1": {isAdminRule: 4},
    });
  });

  it("customer can read type_car", async () => {
    const db = testEnv.authenticatedContext("customer-1").firestore();
    await assertSucceeds(getDoc(doc(db, "type_car", "economy_qa")));
  });

  it("unauthenticated can read type_car", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(db, "type_car", "economy_qa")));
  });

  it("customer cannot write type_car", async () => {
    const db = testEnv.authenticatedContext("customer-1").firestore();
    await assertFails(updateDoc(doc(db, "type_car", "economy_qa"), {sr: 999}));
    await assertFails(setDoc(doc(db, "type_car", "hack"), {sr: 1, actev: true}));
  });

  it("driver cannot write global type_car pricing", async () => {
    const db = testEnv.authenticatedContext("driver-1").firestore();
    await assertFails(updateDoc(doc(db, "type_car", "economy_qa"), {sr: 999}));
  });

  it("partner cannot write type_car", async () => {
    const db = testEnv.authenticatedContext("partner-1", {
      partner: true,
    }).firestore();
    await assertFails(updateDoc(doc(db, "type_car", "economy_qa"), {sr: 999}));
  });

  it("transport company cannot write global type_car", async () => {
    const db = testEnv.authenticatedContext("company-1", {
      transport_company: true,
    }).firestore();
    await assertFails(updateDoc(doc(db, "type_car", "economy_qa"), {sr: 999}));
  });

  it("super admin can update type_car", async () => {
    const db = testEnv
      .authenticatedContext("super-1", {super_admin: true})
      .firestore();
    await assertSucceeds(
      updateDoc(doc(db, "type_car", "economy_qa"), {sr: 120, actev: true}),
    );
  });

  it("country admin can update type_car per current rules", async () => {
    // SECURITY_FINDING note: rules allow any country admin to edit any type_car
    // (no dolh scope on type_car write). Documented, not silently changed.
    const db = testEnv
      .authenticatedContext("admin-sa", {
        country_admin: true,
        country_id: "countries/sa",
      })
      .firestore();
    await assertSucceeds(
      updateDoc(doc(db, "type_car", "economy_qa"), {sr: 110}),
    );
  });
});


describe('Customer profile self-update', () => {
  const uid = 'customer-profile-1';

  beforeEach(async () => {
    await seed({
      [`user/${uid}`]: {
        actev_user: true,
        display_name: 'Old',
        email: 'c@example.com',
        phone_number: '',
        uid,
      },
      'user/other-user': {
        actev_user: true,
        display_name: 'Other',
        uid: 'other-user',
      },
    });
  });

  it('OWNER_PHONE_NAME_PHOTO_ALLOW = PASS', async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'user', uid), {
        display_name: 'New Name',
        phone_number: '0577118808',
        phone_n: 577118808,
        photo_url: 'https://example.com/p.jpg',
      }),
    );
  });

  it('OWNER_PRIVILEGE_ESCALATION_DENY = PASS', async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(
      updateDoc(doc(db, 'user', uid), {
        isAdmin: true,
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'user', uid), {
        Isagent: true,
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'user', uid), {
        ismndob: true,
      }),
    );
  });

  it('CROSS_USER_UPDATE_DENY = PASS', async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(
      updateDoc(doc(db, 'user', 'other-user'), {
        phone_number: '0500000000',
      }),
    );
  });

  it('ANONYMOUS_UPDATE_DENY = PASS', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      updateDoc(doc(db, 'user', uid), {
        phone_number: '0500000000',
      }),
    );
  });
});
