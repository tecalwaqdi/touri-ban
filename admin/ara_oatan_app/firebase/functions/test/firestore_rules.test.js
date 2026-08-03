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
  setDoc,
  updateDoc,
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
});
