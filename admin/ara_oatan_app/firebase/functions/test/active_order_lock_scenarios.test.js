/**
 * Scenario coverage for Single Active Booking lock (no payment paths).
 * Simulates claim/release with an in-memory transaction + firestore.
 */
const {
  isCustomerActiveStatusCode,
  assertAndClaimActiveOrderSlot,
  releaseActiveOrderSlot,
} = require("../active_order_lock.js");

function assert(cond, msg) {
  if (!cond) throw new Error(msg || "assert failed");
}

class FakeFieldValue {
  static serverTimestamp() {
    return { __ts: true };
  }
  static delete() {
    return { __delete: true };
  }
}

function makeStore(seed = {}) {
  const docs = new Map(
    Object.entries(seed).map(([path, data]) => [path, { ...data }]),
  );
  return {
    docs,
    collection(name) {
      return {
        doc(id) {
          const path = `${name}/${id}`;
          return {
            path,
            id,
            get: async () => ({
              exists: docs.has(path),
              data: () => (docs.has(path) ? { ...docs.get(path) } : undefined),
            }),
          };
        },
      };
    },
  };
}

function makeTxn(store) {
  return {
    async get(ref) {
      return {
        exists: store.docs.has(ref.path),
        data: () =>
          store.docs.has(ref.path) ? { ...store.docs.get(ref.path) } : undefined,
      };
    },
    set(ref, data, opts) {
      const prev = store.docs.get(ref.path) || {};
      const next = opts && opts.merge ? { ...prev, ...data } : { ...data };
      for (const [k, v] of Object.entries(next)) {
        if (v && v.__delete) delete next[k];
      }
      store.docs.set(ref.path, next);
    },
  };
}

async function claim(store, userId, orderId) {
  const firestore = store;
  const userRef = firestore.collection("user").doc(userId);
  const txn = makeTxn(store);
  return assertAndClaimActiveOrderSlot({
    transaction: txn,
    firestore,
    userRef,
    orderId,
    FieldValue: FakeFieldValue,
  });
}

async function release(store, userId, orderId) {
  const userRef = store.collection("user").doc(userId);
  const txn = makeTxn(store);
  await releaseActiveOrderSlot({
    transaction: txn,
    userRef,
    orderId,
    FieldValue: FakeFieldValue,
  });
}

// --- status matrix ---
const active = [
  "payment_pending",
  "pending_driver",
  "driver_assigned",
  "driver_arriving",
  "driver_arrived",
  "trip_started",
  "in_progress",
];
const terminal = [
  "completed",
  "trip_completed",
  "cancelled",
  "canceled",
  "cancelled_by_customer",
  "cancelled_by_driver",
  "cancelled_by_admin",
  "expired",
];
for (const c of active) {
  assert(isCustomerActiveStatusCode(c) === true, `active ${c}`);
}
for (const c of terminal) {
  assert(isCustomerActiveStatusCode(c) === false, `terminal ${c}`);
}

async function run() {
  // payment_pending blocks second booking
  {
    const store = makeStore({
      "user/u1": { active_order_id: "o1" },
      "order/o1": { status_code: "payment_pending" },
    });
    const r = await claim(store, "u1", "o2");
    assert(r.ok === false && r.activeOrderId === "o1", "block payment_pending");
  }

  // pending_driver blocks
  {
    const store = makeStore({
      "user/u1": { active_order_id: "o1" },
      "order/o1": { status_code: "pending_driver" },
    });
    const r = await claim(store, "u1", "o2");
    assert(r.ok === false, "block pending_driver");
  }

  // accepted / in-progress blocks
  {
    const store = makeStore({
      "user/u1": { active_order_id: "o1" },
      "order/o1": { status_code: "driver_assigned" },
    });
    const r = await claim(store, "u1", "o2");
    assert(r.ok === false, "block accepted trip");
  }
  {
    const store = makeStore({
      "user/u1": { active_order_id: "o1" },
      "order/o1": { status_code: "trip_started" },
    });
    const r = await claim(store, "u1", "o2");
    assert(r.ok === false, "block in-progress");
  }

  // same account two devices = same user lock (second claim fails)
  {
    const store = makeStore({
      "user/u1": {},
      "order/oA": { status_code: "pending_driver" },
    });
    const first = await claim(store, "u1", "oA");
    assert(first.ok === true, "device A claim");
    store.docs.set("order/oA", { status_code: "pending_driver" });
    const second = await claim(store, "u1", "oB");
    assert(second.ok === false && second.activeOrderId === "oA", "device B blocked");
  }

  // double tap same orderId is idempotent (allowed)
  {
    const store = makeStore({
      "user/u1": { active_order_id: "o1" },
      "order/o1": { status_code: "payment_pending" },
    });
    const r = await claim(store, "u1", "o1");
    assert(r.ok === true, "double-tap same order ok");
  }

  // allow after completed / cancelled / expired
  for (const code of ["completed", "cancelled_by_customer", "expired"]) {
    const store = makeStore({
      "user/u1": { active_order_id: "o1" },
      "order/o1": { status_code: code },
    });
    const r = await claim(store, "u1", "o2");
    assert(r.ok === true, `allow after ${code}`);
    assert(store.docs.get("user/u1").active_order_id === "o2", `lock moved ${code}`);
  }

  // release clears lock
  {
    const store = makeStore({
      "user/u1": { active_order_id: "o1" },
    });
    await release(store, "u1", "o1");
    assert(!store.docs.get("user/u1").active_order_id, "release clears");
  }

  console.log("active_order_lock scenarios OK");
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
