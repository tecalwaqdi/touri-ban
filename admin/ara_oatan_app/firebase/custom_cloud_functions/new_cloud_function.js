const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.newCloudFunction = functions.https.onCall(async (data, context) => {
  const ordersRef = admin.firestore().collection("order");

  try {
    // جلب الطلبات التي حالتها "بإنتظار قبول المندوب"
    const snapshot = await ordersRef
      .where("halh_order", "==", "بإنتظار قبول المندوب")
      .get();

    if (snapshot.empty) {
      return { message: "لا توجد مستندات مطابقة" };
    }

    // تحديث كل المستندات دفعة واحدة
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      batch.update(doc.ref, {
        halh_order: "ملغي",
      });
    });

    await batch.commit();

    return {
      message: "تم تحديث جميع الطلبات بنجاح",
      count: snapshot.size,
    };
  } catch (error) {
    return { error: error.message };
  }
});
