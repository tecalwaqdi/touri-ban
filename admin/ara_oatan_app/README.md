# Toury (ara_oatan_app)

تطبيق حجز الجولات السياحية — Flutter + Firebase.

## التشغيل المحلي

```powershell
cd admin/ara_oatan_app
flutter pub get
flutter run
```

## البناء للإنتاج

```powershell
flutter build apk --release
# أو
flutter build appbundle --release
```

## الدفع (Network International / N-Genius)

**الطريقة المعتمدة:** Cloud Functions (`createNGeniusPayment`, `getNGeniusPayment`, `refundNGeniusPayment`).

1. فعّل **Blaze (الفوترة)** في Firebase Console
2. اضبط إعدادات N-Genius:
   ```powershell
   cd firebase
   firebase functions:config:set ngenius.api_key="..." ngenius.outlet_ref="..." ngenius.production="true"
   ```
3. انشر الدوال من codebase `functions`:
   ```powershell
   cd firebase
   $env:FUNCTIONS_DISCOVERY_TIMEOUT="180"
   firebase deploy --only functions:functions:createNGeniusPayment,functions:functions:getNGeniusPayment,functions:functions:refundNGeniusPayment --project tutorial-multi-language-70gx4j
   ```

يدعم التطبيق بطاقات Visa / Mastercard / Mada عبر Network International مع 3DS عند الحاجة.

> ملاحظة تشغيل: إذا ظهر خطأ `Write access to project ... was denied: please check billing account associated` فالدوال لن تُنشر حتى يملك الحساب صلاحية Billing Admin أو يتم إصلاح ربط حساب الفوترة في Google Cloud.

> آخر محاولة نشر 2026-07-15: تم تحليل الحزمة وتجهيزها للرفع بحجم 58.54KB، ثم توقف الرفع عند نفس خطأ Billing/Write access.

## Firebase

```powershell
cd firebase
firebase deploy --only firestore:rules,firestore:indexes,storage
```

- **المشروع الحالي:** `tutorial-multi-language-70gx4j`
- قبل الإطلاق العام: أنشئ مشروع Firebase إنتاجي واستبدل `google-services.json` و `GoogleService-Info.plist`.
- تم نشر قواعد Firestore من هذا المسار في 2026-07-15؛ أعد النشر بعد أي تغيير في القواعد.
- Runtime دوال العميل مضبوط على Node.js 22.

## App Check (اختياري للتطوير)

```powershell
flutter run --dart-define=ENABLE_FIREBASE_APP_CHECK=true
```

## الاختبارات

```powershell
flutter analyze
flutter test
```

## مسار الحجز الرئيسي

1. `demo_d` — تحديد الموقع
2. `list_vi` — اختيار المعالم
3. `list_car` — اختيار السيارة
4. `checkout66` — الدفع (نقداً أو بطاقة عبر Network International)
5. `paymentConfirm` — تأكيد الدفع الإلكتروني بعد التحقق من N-Genius

## قبل النشر على المتجر

- [ ] مشروع Firebase إنتاجي + قواعد أمان
- [ ] تفعيل/إصلاح Blaze ونشر دوال N-Genius
- [ ] تفعيل App Check في Release
- [ ] Keystore توقيع Release (`android/key.properties`)
- [ ] اختبار الدفع الإلكتروني على جهاز حقيقي
