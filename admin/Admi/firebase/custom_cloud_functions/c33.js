const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// يجب أن يكون الاسم هنا "c33" ليتطابق مع ما في FlutterFlow
exports.c33 = functions.firestore
  .document("order/{orderId}")
  .onCreate(async (snap, context) => {
    const newOrderRef = snap.ref;

    // جلب أكبر قيمة موجودة لـ norder
    const ordersSnapshot = await admin
      .firestore()
      .collection("order")
      .orderBy("norder", "desc") // ترتيب المستندات حسب norder بشكل تنازلي
      .limit(1) // أخذ المستند الذي يحتوي على أكبر قيمة لـ norder
      .get();

    let newNorderValue = 1; // القيمة الافتراضية إذا لم تكن هناك مستندات

    if (!ordersSnapshot.empty) {
      // إذا كانت هناك مستندات، الحصول على أكبر قيمة لـ norder
      const lastOrder = ordersSnapshot.docs[0];
      const lastNorder = lastOrder.data().norder;
      newNorderValue = lastNorder + 1; // زيادة الرقم بمقدار 1
    }

    // تحديث المستند الجديد بـ norder المعدل
    return newOrderRef.update({
      norder: newNorderValue,
    });
  });
