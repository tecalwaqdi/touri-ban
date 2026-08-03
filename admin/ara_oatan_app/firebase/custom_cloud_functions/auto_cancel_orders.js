const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const PENDING_HALH_TEXT = "بإنتظار قبول المندوب";
const PENDING_STATUS_CODES = ["pending_driver", "awaiting_driver"];

/**
 * Cancels orders still awaiting a driver after 60 minutes.
 * Queries both legacy Arabic halh_text and machine status_code.
 */
exports.autoCancelOrders = functions.pubsub
  .schedule("every 1 minutes")
  .timeZone("Asia/Riyadh")
  .onRun(async () => {
    try {
      const nowMs = Date.now();
      const sixtyMinutesMs = 60 * 60 * 1000;
      const ordersRef = admin.firestore().collection("order");

      const [byHalh, ...byCodeSnaps] = await Promise.all([
        ordersRef.where("halh_text", "==", PENDING_HALH_TEXT).get(),
        ...PENDING_STATUS_CODES.map((code) =>
          ordersRef.where("status_code", "==", code).get(),
        ),
      ]);

      const docsById = new Map();
      for (const snap of [byHalh, ...byCodeSnaps]) {
        snap.forEach((doc) => docsById.set(doc.id, doc));
      }

      if (docsById.size === 0) {
        console.log("No orders awaiting acceptance.");
        return null;
      }

      const updates = [];
      docsById.forEach((doc) => {
        const data = doc.data();
        if (!data.data_order) return;

        const orderTimeMs = data.data_order.toMillis
          ? data.data_order.toMillis()
          : new Date(data.data_order).getTime();
        if (isNaN(orderTimeMs)) return;

        if (nowMs - orderTimeMs >= sixtyMinutesMs) {
          updates.push(
            doc.ref.update({
              halh_text: "ملغي",
              status_code: "cancelled",
              cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
            }),
          );
        }
      });

      if (updates.length) {
        await Promise.all(updates);
        console.log(`Cancelled ${updates.length} orders after 60 minutes.`);
      }

      return null;
    } catch (error) {
      console.error("autoCancelOrders error:", error);
      throw error;
    }
  });
