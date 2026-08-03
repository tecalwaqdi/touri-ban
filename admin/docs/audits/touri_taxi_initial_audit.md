# التدقيق الأولي لنظام Touri Taxi

**تاريخ التدقيق:** 2026-07-21  
**النطاق:** `D:\Projects\ara\admin` وكل المجلدات الفرعية  
**الحالة عند كتابة هذا التقرير:** تدقيق قرائي قبل التعديلات الرئيسية؛ لم يتم أي نشر أو اتصال دفع حقيقي.

## الخلاصة التنفيذية

تم تحديد مصادر التطبيقات الفعلية الثلاثة ومشروع Firebase المشترك. توجد أعمال سابقة كثيرة غير ملتزمة داخل مستودعي العميل والإدارة، لذلك لم تُنشأ نقطة حفظ Git جديدة كي لا تُضمَّن تغييرات موجودة أو ملفات إعداد حساسة دون تمييز. مستودع Git الأب جديد بلا commits ويرى مجلد `admin` كاملًا كملف غير متعقب.

النظام **غير جاهز للنشر** حاليًا. أهم الأسباب هي تضارب جذور نشر Firebase، عدم نشر وظائف N-Genius، مسار نقدي احتياطي يثق بسعر العميل، ثغرات أدوار وانتقالات رحلة في قواعد Firestore، تعطل قبول الطلبات غير المسندة وفق القواعد المحلية، ونواقص مؤكدة في ترجمة الإدارة والمندوب والموقع الافتراضي.

## خريطة المشاريع ومصدر الحقيقة

| الدور | المسار الفعلي | الهوية | Firebase | الدليل والحكم |
|---|---|---|---|---|
| تطبيق العميل | `ara_oatan_app` | Android `com.mycompany.araoatanapp`، iOS `com.mycompany.araoatanapp2`، الإصدار `9.1.10+18` | `tutorial-multi-language-70gx4j` | `pubspec.yaml` وGradle وXcode وملفا Google متطابقة مع العميل؛ أحدث تاريخ Git خاص بالدفع N-Genius موجود هنا. |
| تطبيق المندوب | `mndob-main` | Android `com.mycompany.mndob2`، iOS `com.mycompany.mndob3`، الإصدار `2.0.2+9` | المشروع نفسه | مشروع Flutter مستقل وظيفيًا. `google-services.json` متعدد العملاء ويحتوي فعلًا client مطابقًا لـ`com.mycompany.mndob2`؛ التقارير القديمة التي اعتبرته mismatch غير دقيقة. |
| لوحة الإدارة | `Admi` | Android/iOS `com.mycompany.tutorialmultilanguageapp`، الإصدار `1.0.3+2005` | المشروع نفسه | نقطة الدخول تستخدم خدمات وثيم الإدارة ومساراتها؛ مشروع Flutter للويب/Android. |
| Cloud Functions الفعلية المرشحة كمصدر وحيد | `ara_oatan_app/firebase/functions` و`ara_oatan_app/firebase/custom_cloud_functions` | codebases: `functions` و`custom_cloud_functions` | المشروع نفسه، region المستخدم `us-central1` | هذه النسخة وحدها تحتوي N-Genius والخرائط الآمنة مع اختبارات حديثة، لكنها لا تحتوي كل وظائف الإدارة بعد؛ يلزم دمجها قبل اعتبارها المصدر النهائي. |
| قواعد Firestore/Storage المرشحة كمصدر وحيد | `ara_oatan_app/firebase/firestore.rules`، `storage.rules`، `firestore.indexes.json` | — | المشروع نفسه | قواعد Storage متطابقة بين التطبيقات، لكن Firestore والفهارس مختلفة؛ يلزم توحيدها ثم تعطيل جذور النشر القديمة. |

### مجلدات مساندة وليست نسخ مصدر

| المسار | النوع | القرار |
|---|---|---|
| `store_release` | سكربت بناء وأربع حزم AAB قديمة | ليس تطبيقًا مكررًا. أحدث حزمة عميل فيه `9.1.9+17` وأحدث مندوب `2.0.1+8`، وهما أقدم من المصدر الحالي. لا تُستخدم كدليل على البناء الحالي. |
| `docs` | تقارير سابقة | مرجع تاريخي فقط؛ بعض النتائج قديمة أو متناقضة ويجب تحديثها بالأدلة الحالية. |
| `.tools/node-v22.23.1-win-x64` | Node محلي مطابق لوظائف العميل | أداة بناء محلية، وليست Backend آخر. |
| `.tools/firebase-cli` | Firebase CLI محلي | أداة فقط. |
| مجلدات FlutterFlow ذات أسماء `copy` داخل `lib` | شاشات قديمة داخل المصدر نفسه | لا تُحذف عشوائيًا. يلزم إثبات عدم وجود route أو import إليها قبل أي تنظيف لاحق. |

لا توجد مشاريع Flutter إضافية تحت `D:\Projects\ara` غير المشاريع الثلاثة المذكورة. المراجع القديمة إلى `D:\Projects\ara\mndob-main` أو `arawatan` لم تعد موجودة في الجرد الحالي.

## خريطة المجلدات المختصرة

```text
admin/
├─ Admi/                    Flutter Admin + Firebase mirror + admin scripts
├─ ara_oatan_app/           Flutter Customer + canonical Firebase candidate
├─ mndob-main/              Flutter Driver + Firebase mirror
├─ store_release/           historical AAB artifacts/build script
├─ docs/                    cross-system audits/release reports
└─ .tools/                  pinned Node 22 and Firebase tooling
```

## Firebase والبيئات

- Project ID المكتشف في `.firebaserc` وملفات Android/iOS: `tutorial-multi-language-70gx4j`.
- لا يوجد `firebase_options.dart` في التطبيقات؛ التهيئة native، مع خيارات ويب مولدة/مضمّنة في ملفات Firebase الخاصة بكل تطبيق.
- ملفات `google-services.json` تحتوي عدة Firebase clients. Gradle يختار client بحسب `applicationId`، والعميل والمندوب والإدارة جميعًا موجودون.
- لا توجد بيئة production منفصلة مثبتة في الملفات؛ اسم المشروع نفسه تعليمي/مشترك، ولذلك لا يمكن اعتباره إنتاجيًا لمجرد أنه مستخدم حاليًا.
- كل من `Admi/firebase/firebase.json` و`ara_oatan_app/firebase/firebase.json` يعلن codebase باسم `functions` و`custom_cloud_functions`، و`mndob-main` يعلن `functions` أيضًا، بينما exports مختلفة. نشر نسخة قديمة يمكنه حذف/استبدال وظائف النسخة الأخرى.
- أعداد الفهارس مختلفة تقريبًا: الإدارة 65، العميل 21، المندوب 6. هذا دليل على drift وليس ثلاث بيئات مستقلة.
- قواعد Storage متطابقة حاليًا؛ قواعد Firestore ليست متطابقة.

## إصدارات الأدوات

| الأداة | الإصدار المكتشف | ملاحظة |
|---|---|---|
| Flutter | `3.44.4` stable | من `flutter.version.json` المحلي. |
| Dart | `3.12.2` | مرفق مع Flutter. |
| Node في PATH | `26.3.0` | لا يطابق runtime وظائف Firebase. |
| Node المحلي المثبت للمشروع | `22.23.1` | يطابق `ara_oatan_app/firebase/functions` الذي يطلب Node 22. |
| npm | `11.16.0` | النظام. |
| Java | OpenJDK `21.0.10` | Android Studio JBR؛ Java غير موجود في PATH دون ضبط المسار. |

## الحزم الرئيسية

| التطبيق/الخدمة | حزم رئيسية وإصدارات |
|---|---|
| العميل | Firebase Core `3.14.0`، Auth `5.6.0`، Firestore `5.6.9`، Functions `5.5.2`، Messaging `15.2.7`، Storage `12.4.7`، Maps `2.12.2`، Geolocator `10.0.1`، Easy Localization `^3.0.8`، WebView `4.13.0`. |
| المندوب | نفس خط Firebase تقريبًا، Maps `2.12.2`، Geolocator `14.0.1`، Background Geolocation `^5.0.1`، Easy Localization `^3.0.8`. |
| الإدارة | نفس خط Firebase تقريبًا، Maps `2.12.2`، Geolocator `14.0.1`، Google Fonts `^8.1.0`. |
| Functions المرشحة | `firebase-admin ^13.10.0`، `firebase-functions ^7.2.5`، `axios ^1.18.1`، Node 22. |
| Functions القديمة في الإدارة/المندوب | Firebase Functions 4/Admin 11 مع حزم Braintree/Stripe/Razorpay قديمة وغير مستخدمة في مصدر N-Genius الحالي. |

لا يُوصى بأي ترقية جماعية الآن؛ يجب أولًا تثبيت المصدر الوحيد ثم تنفيذ أقل تغييرات توافق لازمة.

## طريقة التشغيل والبناء

### العميل

```powershell
cd D:\Projects\ara\admin\ara_oatan_app
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

### المندوب

```powershell
cd D:\Projects\ara\admin\mndob-main
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
```

### الإدارة

```powershell
cd D:\Projects\ara\admin\Admi
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
flutter build web
```

### Functions — المصدر الوحيد بعد الدمج

```powershell
cd D:\Projects\ara\admin\ara_oatan_app\firebase\functions
npm ci
npm run lint
npm run test:unit
```

لا يُنفذ `firebase deploy` من أي مسار ضمن هذا التدقيق دون موافقة صريحة.

## حالة Git قبل التعديل

- المستودع الأب `D:\Projects\ara` على `main` بلا commits، ويعرض `admin/` كاملًا كـuntracked.
- `Admi` مستودع مستقل وله history حتى 2026-07-01، لكنه يحتوي عشرات الملفات المعدلة وغير المتعقبة قبل هذه المهمة.
- `ara_oatan_app` مستودع مستقل وله history حتى commit `e0ee0b4` بتاريخ 2026-07-15، لكنه يحتوي عشرات الملفات المعدلة/المحذوفة/غير المتعقبة قبل هذه المهمة.
- `mndob-main` ليس مستودعًا مستقلاً صالحًا؛ يقع تحت المستودع الأب الفارغ.
- لم يتم commit أو stash أو reset. HEAD الحالي في المستودعين المستقلين يشكل مرجعًا للملفات المتعقبة فقط، وليس نقطة حفظ للتغييرات الموجودة.

## نتائج الفحص الأولية حسب الخطورة

### Critical

| المعرّف | المشكلة والسبب الجذري | الملفات/الخدمات المسؤولة |
|---|---|---|
| C-01 | ثلاثة جذور Firebase تشترك في project وcodebase مع exports وقواعد وفهارس مختلفة؛ النشر من المسار الخطأ قد يحذف وظائف أو يعيد قواعد قديمة. | `*/firebase/firebase.json`، `*/firebase/functions/index.js`، قواعد وفهارس المشاريع الثلاثة. |
| C-02 | الدفع N-Genius غير منشور بحسب أدلة المشروع السابقة بسبب Billing/صلاحيات؛ الدفع الإلكتروني لا يمكن اعتباره عاملًا، ولا يجوز اعتماد رجوع WebView كنجاح. | `ara_oatan_app/firebase/functions/ngenius_payments.js` وتقارير النشر السابقة. |
| C-03 | fallback الحجز النقدي يكتب السعر المحسوب في العميل مباشرة إلى Firestore؛ القواعد تتحقق من النطاق فقط ولا تعيد التسعير من مصدر موثوق. هذا يخالف مبدأ server authoritative pricing. | `ara_oatan_app/lib/core/toury_booking_service.dart`، `ara_oatan_app/firebase/firestore.rules`. |
| C-04 | قواعد الطلب لا تسمح للمندوب بقراءة/تحديث الطلب غير المسند الذي تستعلم عنه الواجهة، ولا يظهر استخدام `mzod_user` في schema/الكتابات؛ قبول الطلب قد يفشل دائمًا مع القواعد المحلية. | `mndob-main/lib/now/now_widget.dart`، `driver_new_order_listener.dart`، `firebase/firestore.rules`. |
| C-05 | بعد الإسناد تسمح القواعد للمندوب بتغيير كل حقول الرحلة غير المالية تقريبًا، ومنها الحالة والمندوب والتوقيت، دون فرض state machine. كما أن `completeTrip` لا يتحقق من الحالة السابقة. | `firebase/firestore.rules`، `mndob-main/lib/core/driver_trip_service.dart`. |
| C-06 | صلاحيات الإدارة تعتمد أيضًا على حقول user document. country admin يستطيع تحديث مستند مستخدم ضمن نطاقه دون حماية جميع حقول الامتياز، ثم trigger يحولها إلى custom claims؛ الحقل `is_partner` مفقود من قوائم الحماية. | قواعد Firestore الثلاث، `Admi/firebase/functions/index.js`. |
| C-07 | تسجيل المندوب ينشئ user ثم يحاول تفعيل `ismndob` في update تمنعه القواعد؛ وفي الوقت نفسه لا يجوز السماح بالدور بلا حالة موافقة آمنة. | `mndob-main` auth/registration + Firestore rules. |

### High

| المعرّف | المشكلة والسبب الجذري | الملفات/الخدمات المسؤولة |
|---|---|---|
| H-01 | دالة `getVariableText` في المندوب تفهرس `[en, ar]` باستخدام index قد يكون 2 أو 3 للروسية/القرغيزية، ما يسبب `RangeError`. خريطة FlutterFlow تحتوي 475 EN/AR بلا RU/KY. | `mndob-main/lib/flutter_flow/internationalization.dart`. |
| H-02 | الإدارة تعلن 8 لغات قديمة ولا تعلن `ky`، وجميع خرائطها الأساسية بلا قرغيزية. | `Admi/lib/main.dart`، `internationalization.dart`، `lib/l10n/*`. |
| H-03 | خرائط العميل تحول null أو `0,0` إلى الرياض؛ شاشات تبدأ بـ`0,0`. هذا يفسر ظهور الرياض عند فشل GPS حتى لو كان المستخدم في مكة. | `flutter_flow_google_map.dart`، `toury_maps_config.dart`، widgets التتبع/اقتراح الموقع. |
| H-04 | خدمة موقع العميل ترفض إحداثيات صحيحة إذا كان latitude أو longitude يساوي صفرًا بدل رفض الزوج `0,0` فقط، وتعيد أخطاء أذونات إنجليزية/raw exception. | `ara_oatan_app/lib/core/toury_location_service.dart`. |
| H-05 | تطبيق المندوب يبدأ نظامي تتبع متوازيين بعد القبول، مع كتابات مكررة وعدم تحقق كامل من الإحداثيات/timeout؛ خطر بطارية وتكلفة وسباقات. | `driver_trip_service.dart` وcustom actions وخدمة live location. |
| H-06 | `getRoadRoute` مستخدمة في المندوب لكنها غير مصدرة من نسخة Functions الخاصة به؛ سبب إضافي لضرورة المصدر الموحد. | `driver_directions_service.dart` و`mndob-main/firebase/functions/index.js`. |
| H-07 | أي مستخدم مسجل يستطيع إنشاء مستند push يحدد المستلمين والنص والصفحة؛ trigger لا يتحقق من علاقة المرسل بالمستلم، ما يسمح spam/deep-link injection. | Firestore rules + push notification functions. |
| H-08 | معالج push في المندوب يُنشأ مع routes ويسجل listeners بلا إلغاء، ما يراكم التنقلات والتنبيهات. | `push_notifications_handler.dart` و`nav.dart`. |
| H-09 | Storage يسمح لأي مستخدم مسجل بقراءة جميع `/users/**`، وcatch-all واسع؛ صلاحيات كتابة محتوى الإدارة غير مقيدة دائمًا بالبلد/الملكية. | `firebase/storage.rules`. |
| H-10 | تجميع الإدارة المالي يقبل `countryPath` من country admin قبل فرض claim scope، وcache قابل للقراءة دون scope دقيق. | `Admi/firebase/functions/index.js` وFirestore rules. |

### Medium

| المعرّف | المشكلة | الملفات/الخدمات المسؤولة |
|---|---|---|
| M-01 | branding غير موحد: الإدارة تعرض أسماء قديمة، والمندوب يعرض MNDOB/تهجئة عربية مختلفة، وبعض ترجمات العميل وpermission strings تعرض Ara Watan. | Android/iOS/web وملفات اللغات في التطبيقات الثلاثة. |
| M-02 | JSON المندوب غير متكافئ: EN=972، AR=974، RU=961، KY=962؛ توجد مفاتيح مفقودة، بينما JSON العميل متكافئ 801/801. | `mndob-main/assets/langs/*.json`. |
| M-03 | الدفع/الحالة يحملان أسماء legacy مثل `idMoyser` وroute قديم؛ الاستخدام الحالي read-only غالبًا، لكنه يحتاج توثيق Migration وعدم إعادة إحياء Moyasar. | schemas/navigation/rules. |
| M-04 | admin notification query يحد أول 200 token ثم يصفّي محليًا وقد يفوّت admins؛ تنظيف tokens لا يميز invalid/unregistered عن الأخطاء المؤقتة. | Admin Functions. |
| M-05 | قبول المندوب ذري على order فقط؛ تحديث user والتتبع والإشعار بعد transaction قد يفشل ويترك حالة جزئية. | `DriverTripService.acceptOrder`. |

### Low / ديون تقنية

- أسماء FlutterFlow ومجلدات copies كثيرة تجعل اكتشاف الشاشة الفعلية أصعب.
- README الإدارة والمندوب عامان ولا يشرحان التشغيل أو المصدر الموحد.
- System Node 26 لا يطابق runtime؛ يجب استخدام Node 22 المثبت محليًا.
- ملفات release pack وتوثيقه متناقضة في أرقام نسخة العميل (`9.1.8`/`9.1.9`) وأقدم من المصدر `9.1.10`.

## حالة الفحوص قبل التعديل

| الفحص | النتيجة |
|---|---|
| `npm run lint` في Functions العميل | ناجح. |
| `npm run test:unit` في Functions العميل | ناجح: N-Genius unit checks passed. |
| `node --check` للملفات الرئيسية | ناجح. |
| `flutter analyze --no-pub` | محاولات متوازية علقت بلا output بسبب قفل/ضغط Dart SDK؛ لا تُسجل كنجاح أو فشل، وستعاد تسلسليًا. |
| نواتج بناء سابقة | APK debug موجود للتطبيقات الثلاثة، وrelease APK/AAB سابقة للعميل والمندوب؛ ليست دليلًا على التغييرات الحالية. |

## خطة الإصلاح بالترتيب

1. تثبيت `ara_oatan_app/firebase` كمصدر Firebase وحيد، دمج وظائف الإدارة/المندوب اللازمة فيه، ومنع نشر المرايا القديمة بالخطأ.
2. إصلاح قواعد الأدوار والمستخدمين وطلبات الرحلات وpush وStorage، ثم إضافة اختبارات Emulator تغطي منع رفع الصلاحية والسعر والقبول المتكرر.
3. إزالة fallback النقدي الذي يثق بالعميل، وجعل cash/card يعتمدان على Functions ذات idempotency وتسعير server-side.
4. إصلاح حالة رحلة المندوب، القبول والانتقالات والملكية والتتبع والمسارات والإشعارات.
5. إصلاح Localization للغات الأربع في المندوب والإدارة، ثم تشغيل أداة parity/mojibake/hardcoded scan مشتركة.
6. إصلاح GPS وخرائط العميل وإزالة أي مدينة افتراضية منطقية، مع تحقق الإحداثيات وtimeout ونتائج route الحديثة فقط.
7. استكمال BookingValidation/Pricing واختبارات null/NaN/Infinity/الساعات الإضافية والبنود المالية.
8. توحيد branding الظاهر إلى `Touri Taxi` دون تغيير package/bundle identifiers.
9. تشغيل analyze/test/build تسلسليًا لكل تطبيق، ثم تحديث تقارير الأمان والدفع والترجمة والاختبارات وجاهزية النشر.

## حدود هذا التدقيق

- لم يتم نشر Firebase أو Functions أو قواعد أو فهارس.
- لم يتم استخدام مفاتيح دفع أو خصم حقيقي.
- لا يمكن إثبات سلوك GPS/3DS/background notifications على جهاز فعلي من الفحص الساكن وحده؛ ستبقى اختبارات جهاز موثقة كمتطلبات خارجية.
- لا تُعد التقارير السابقة دليلًا نهائيًا إلا إذا أعيد تشغيل أمر التحقق على الشجرة الحالية.
