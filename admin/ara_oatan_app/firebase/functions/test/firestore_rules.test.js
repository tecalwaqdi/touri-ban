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
