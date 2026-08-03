# تحليل الباك اند المفصول عن الفرونت اند

## مشروع أرى وطن / Tory Taxi

إصدار الوثيقة: 0.1  
تاريخ الإعداد: 2026-04-04  
نوع الوثيقة: تحليل معماري وتحويل من تطبيق Flutter متصل مباشرة بقاعدة البيانات إلى Backend مستقل.

## 1. الملخص التنفيذي

المشروع الحالي ليس مبنيًا على باك اند مستقل بالمعنى التقليدي، بل يعتمد على:

- Flutter كواجهة أمامية.
- Firebase Authentication للمصادقة.
- Firestore كمخزن بيانات رئيسي.
- Firebase Storage للملفات.
- Cloud Functions لبعض المهام الخلفية.
- استدعاءات API خارجية مباشرة من التطبيق.

هذا يعني أن منطق النظام موزع اليوم بين:

1. الواجهة الأمامية نفسها.
2. Firestore Rules.
3. Cloud Functions.
4. مزودي خدمات خارجيين.

إذا كان الهدف هو تحويل النظام إلى Backend مستقل، فالمطلوب ليس فقط "نقل الملفات"، بل إعادة تعريف حدود المسؤوليات بين:

- `Frontend Client`
- `Backend API`
- `Database`
- `Background Jobs`
- `External Integrations`

## 2. ما هو الفرونت اند الآن

الفرونت اند الحالي موجود أساسًا داخل مجلد [lib](C:\Users\almrs\Desktop\ara_oatan_app-main\lib)، ويشمل:

- الشاشات والواجهات.
- التنقل بين الصفحات.
- إدارة الحالة داخل التطبيق `FFAppState`.
- أجزاء من منطق الأعمال.
- تنفيذ عمليات إنشاء الطلبات والدفع والقراءة من قاعدة البيانات مباشرة.

أمثلة واضحة:

- [lib/main.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\main.dart)
- [lib/demo_d/demo_d_widget.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\demo_d\demo_d_widget.dart)
- [lib/order/checkout66/checkout66_widget.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\order\checkout66\checkout66_widget.dart)
- [lib/profile/profile05/profile05_widget.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\profile\profile05\profile05_widget.dart)

## 3. ما هو الباك اند الآن

الباك اند الحالي موزع بين عدة أماكن:

### 3.1 طبقة بيانات مباشرة من Flutter
ملف [lib/backend/backend.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\backend\backend.dart) يعرّف عمليات القراءة من Firestore مباشرة من التطبيق.

### 3.2 مخطط البيانات
الكيانات الحالية موجودة في:

- [lib/backend/schema](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\backend\schema)

ومنها:

- `user`
- `order`
- `mkan`
- `countries`
- `cities`
- `villages`
- `payment methods`
- `wallets`
- `transactions`
- `support`
- `chat`
- `reviews`

### 3.3 Cloud Functions
موجودة في:

- [firebase/functions](C:\Users\almrs\Desktop\ara_oatan_app-main\firebase\functions)
- [firebase/custom_cloud_functions](C:\Users\almrs\Desktop\ara_oatan_app-main\firebase\custom_cloud_functions)

وتؤدي وظائف مثل:

- الدفع عبر Braintree.
- إدارة FCM tokens.
- إرسال Push Notifications.
- إلغاء الطلبات آليًا.
- تنبيهات الرسائل الجديدة.

### 3.4 قواعد الوصول
موجودة في:

- [firebase/firestore.rules](C:\Users\almrs\Desktop\ara_oatan_app-main\firebase\firestore.rules)

### 3.5 تكاملات خارجية مباشرة من التطبيق
ملف [lib/backend/api_requests/api_calls.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\backend\api_requests\api_calls.dart) يحتوي على استدعاءات مباشرة من Flutter إلى:

- OpenCage
- Moyasar
- WhatsApp gateway
- Wasl / ELM APIs

وهذا يعني أن جزءًا من مسؤوليات الباك اند موجود اليوم في التطبيق نفسه.

## 4. المشكلة المعمارية الحالية

### 4.1 منطق الأعمال داخل الواجهة
الفرونت اند الحالي لا يكتفي بعرض البيانات، بل يقوم أيضًا بـ:

- إنشاء الطلبات.
- حساب أجزاء من الأسعار.
- اختيار المندوبين المحتملين.
- استدعاء واجهات الدفع.
- تحديث المحفظة.
- إرسال الإشعارات في بعض السيناريوهات.

هذا يجعل الواجهة الأمامية مسؤولة عن قرارات يجب أن تكون داخل الباك اند.

### 4.2 وصول مباشر لقاعدة البيانات
التطبيق يقرأ ويكتب في Firestore مباشرة. هذه البنية سريعة للبدايات، لكنها تخلق مشاكل عند التوسع:

- صعوبة فرض قواعد أعمال موحدة.
- صعوبة التدقيق المحاسبي.
- صعوبة إخفاء المنطق الحساس.
- اعتماد الأمان على القواعد فقط بدل API صريحة.

### 4.3 مشاكل أمنية واضحة
من الفحص الحالي تظهر مخاطر يجب نقلها إلى Backend مستقل:

- استدعاءات دفع مباشرة من التطبيق.
- تخزين/تمرير بيانات بطاقات دفع داخل قاعدة البيانات بصورة غير مناسبة.
- وجود أسرار وتفاصيل مزودي الخدمات ضمن طبقة قريبة من التطبيق.
- صلاحيات Firestore واسعة جدًا في بعض الـ collections.

### 4.4 تشوه الحدود بين الطبقات
لا يوجد اليوم فصل واضح بين:

- Domain logic
- Persistence
- Integration layer
- Presentation layer

## 5. ملاحظات حرجة قبل فصل الباك اند

### 5.1 عدم اتساق أسماء الـ collections
يوجد عدم اتساق بين `user` و`users`.

أمثلة:

- ملف [lib/backend/schema/user_record.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\backend\schema\user_record.dart) يعتمد collection اسمها `user`.
- ملف [lib/backend/schema/servies/walletservies.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\backend\schema\servies\walletservies.dart) يشير أحيانًا إلى `users`.

هذا يعني أن أي Backend مستقل يجب أن يبدأ أولًا بتوحيد نموذج البيانات.

### 5.2 منطق محفظة داخل Flutter
خدمة المحفظة الحالية في [lib/backend/schema/servies/walletservies.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\backend\schema\servies\walletservies.dart) تقوم مباشرة بـ:

- إنشاء محفظة.
- شحن الرصيد.
- الخصم.
- إنشاء سجل المعاملات.

وهذا منطق Backend صريح ويجب إخراجه بالكامل من التطبيق.

### 5.3 قواعد Firestore متساهلة
ملف [firebase/firestore.rules](C:\Users\almrs\Desktop\ara_oatan_app-main\firebase\firestore.rules) يوضح أن بعض الكيانات تسمح بـ `create/read` للجميع تقريبًا. هذا مقبول أحيانًا في نماذج أولية، لكنه غير مناسب لنظام تشغيل فعلي عند فصل الباك اند.

### 5.4 Cloud Functions جزئية وغير كافية كطبقة Backend كاملة
Cloud Functions الحالية تؤدي مهام متفرقة، لكنها لا تمثل:

- API موحدة
- طبقة خدمة domain
- إدارة أخطاء موحدة
- توثيق endpoints
- مراقبة تشغيل كاملة

## 6. ماذا يجب أن يبقى في الفرونت اند بعد الفصل

بعد فصل الباك اند، الفرونت اند يجب أن يقتصر على:

- عرض الواجهات.
- إدارة تجربة المستخدم.
- التقاط المدخلات.
- استهلاك الـ APIs.
- عرض الحالات والرسائل.
- حفظ cache محلي بسيط إذا لزم.

الفرونت اند لا يجب أن يقوم بـ:

- إنشاء الطلب مباشرة في قاعدة البيانات.
- حساب السعر النهائي الرسمي.
- تحديث الرصيد.
- تحديد المندوب المناسب.
- تنفيذ الدفع الحقيقي.
- تخزين بيانات البطاقة الحساسة.
- تشغيل التكاملات الخارجية الحساسة.

## 7. ماذا يجب أن ينتقل إلى الباك اند المستقل

### 7.1 إدارة الهوية والصلاحيات
- تسجيل المستخدمين وربطهم بالأدوار.
- إدارة claims أو roles.
- التحقق من الوصول حسب نوع المستخدم.

### 7.2 إدارة المحتوى الجغرافي والسياحي
- الدول والمناطق والمدن والقرى.
- الأماكن السياحية.
- تصنيفات الأماكن.
- الأماكن المقترحة ومراجعتها.

### 7.3 إدارة الرحلات والطلبات
- إنشاء الطلب.
- التحقق من المدخلات.
- حساب السعر.
- تطبيق الضريبة والرسوم.
- تعيين حالة الطلب.
- اختيار المندوب أو نشر الطلب للمندوبين المؤهلين.

### 7.4 الدفع والمحفظة
- إنشاء intents أو payment sessions.
- التحقق من نتائج الدفع.
- إنشاء قيود مالية Transaction Ledger.
- تحديث المحفظة.
- التعامل مع الاسترداد والإلغاء.

### 7.5 التتبع والمحادثة
- حفظ الرسائل.
- تنبيهات الرسائل.
- تحديث موقع المندوب.
- تاريخ الحالة التشغيلية للرحلة.

### 7.6 الدعم الفني
- إنشاء التذاكر.
- تغيير الحالة.
- الردود الداخلية.
- سجل النشاط.

### 7.7 الشركاء ومزودو الخدمة
- استقبال طلبات الشركاء.
- مراجعة المستندات.
- تفعيل أو رفض الشريك.

### 7.8 المهام الخلفية
- إلغاء الطلبات المتأخرة.
- إرسال الإشعارات.
- التقارير والتنبيهات.
- مزامنة الأنظمة الخارجية.

## 8. شكل الباك اند المستقل المقترح

### 8.1 افتراض التنفيذ
بما أن المشروع الحالي يستخدم JavaScript/Firebase Cloud Functions، فالخيار الأنسب والأقل مقاومة للتحويل هو:

- `Node.js + NestJS` أو `Express/Fastify`

والأفضل تنظيميًا:

- `NestJS`

لأنه يعطي:

- Modules واضحة
- Controllers
- Services
- DTOs
- Guards
- Validation
- Background jobs أسهل تنظيمًا

### 8.2 المعمارية المقترحة

```text
Flutter App
   |
   v
API Gateway / Backend API
   |
   +-- Auth Module
   +-- Users Module
   +-- Places Module
   +-- Booking Module
   +-- Dispatch Module
   +-- Payments Module
   +-- Wallet Module
   +-- Support Module
   +-- Partner Module
   +-- Notification Module
   |
   v
Database + Storage + Message/Job Queue
```

### 8.3 قاعدة البيانات المقترحة
لديك خياران:

1. الاستمرار على Firestore مؤقتًا مع جعل الوصول عبر الباك اند فقط.
2. الانتقال إلى قاعدة علائقية مثل PostgreSQL عند الرغبة في ضبط:
   - المدفوعات
   - القيود المالية
   - العلاقات المعقدة
   - التقارير

التوصية العملية:

- `مرحلة أولى`: ابقِ Firestore كمخزن بيانات.
- `مرحلة ثانية`: انقل الكيانات الحرجة ماليًا وتشغيليًا إلى PostgreSQL إذا احتجت.

## 9. الوحدات المقترحة في الباك اند

### 9.1 Auth Module
المسؤوليات:

- login / register / refresh
- إدارة الأدوار
- حماية الـ endpoints

### 9.2 Users Module
المسؤوليات:

- الملف الشخصي
- الصورة
- العناوين
- الإعدادات

### 9.3 Geography Module
المسؤوليات:

- countries
- regions/cities
- villages
- boundaries لو لزم

### 9.4 Places Module
المسؤوليات:

- استعراض الأماكن
- تفاصيل المكان
- التصنيفات
- اقتراح مكان جديد
- اعتماد المكان

### 9.5 Booking Module
المسؤوليات:

- إنشاء الحجز
- جدولة الرحلة
- اختيار السيارة
- احتساب التسعير
- إلغاء الحجز
- تفاصيل الحجز

### 9.6 Dispatch Module
المسؤوليات:

- ترشيح المندوبين
- إرسال الطلب لهم
- قبول/رفض الطلب
- تتبع حالة التنفيذ

### 9.7 Payment Module
المسؤوليات:

- payment session
- payment callback/webhook
- refunds
- payment history

### 9.8 Wallet Module
المسؤوليات:

- إنشاء المحفظة
- الرصيد
- شحن الرصيد
- سجل المعاملات
- منع التلاعب بالأرصدة

### 9.9 Support Module
المسؤوليات:

- إنشاء التذكرة
- التصنيف
- تغيير الحالة
- سجل الردود

### 9.10 Partner Module
المسؤوليات:

- طلبات الشراكة
- رفع المستندات
- حالة الاعتماد

### 9.11 Notification Module
المسؤوليات:

- push notifications
- WhatsApp
- email
- إشعارات داخلية

## 10. الـ APIs المقترحة

### Auth
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- `GET /auth/me`

### Users
- `GET /users/me`
- `PATCH /users/me`
- `GET /users/me/addresses`
- `POST /users/me/addresses`
- `PATCH /users/me/addresses/:id`
- `DELETE /users/me/addresses/:id`

### Geography
- `GET /countries`
- `GET /countries/:id/cities`
- `GET /cities/:id/villages`

### Places
- `GET /places`
- `GET /places/:id`
- `POST /places/suggestions`
- `POST /partners/places`

### Bookings
- `POST /bookings/quote`
- `POST /bookings`
- `GET /bookings`
- `GET /bookings/:id`
- `POST /bookings/:id/cancel`
- `POST /bookings/:id/schedule`

### Dispatch
- `POST /dispatch/bookings/:id/publish`
- `POST /dispatch/bookings/:id/accept`
- `POST /dispatch/bookings/:id/reject`
- `POST /dispatch/bookings/:id/location`

### Payments
- `POST /payments/intent`
- `POST /payments/webhook`
- `GET /payments/:id`
- `POST /payments/:id/refund`

### Wallet
- `GET /wallet`
- `GET /wallet/transactions`
- `POST /wallet/top-up`
- `POST /wallet/withdraw`

### Support
- `GET /support/tickets`
- `POST /support/tickets`
- `GET /support/tickets/:id`
- `POST /support/tickets/:id/reply`

### Partners
- `POST /partners/applications`
- `GET /partners/applications/:id`

## 11. تقسيم المسؤوليات بين الفرونت والباك

### ما يخص الفرونت اند
- Forms
- UI validation البسيط
- Rendering
- Navigation
- State management
- عرض الأخطاء

### ما يخص الباك اند
- Validation الحقيقي
- Authorization
- Business rules
- Transactions
- Pricing
- Payment verification
- Dispatch logic
- Audit logs
- Notifications orchestration

## 12. خريطة نقل الكيانات الحالية إلى Backend Domain

### المستخدمون
الحالي:
- `user`

المستقبلي:
- `users`
- `user_profiles`
- `user_roles`
- `user_addresses`

### الأماكن
الحالي:
- `mkan`
- `classification`

المستقبلي:
- `places`
- `place_categories`
- `place_media`
- `place_suggestions`

### الحجوزات
الحالي:
- `order`
- `order_mkss`
- `listamaknorder`

المستقبلي:
- `bookings`
- `booking_items`
- `booking_schedule`
- `booking_status_history`

### المدفوعات
الحالي:
- `PaymentMethods`
- `Paymenthistory`
- `wallets`
- `transactions`

المستقبلي:
- `payment_methods`
- `payment_transactions`
- `wallets`
- `wallet_ledger`
- `refunds`

### الدعم
الحالي:
- `support`

المستقبلي:
- `support_tickets`
- `support_ticket_messages`
- `support_ticket_events`

## 13. المخاطر الحالية التي يجب علاجها في الباك اند الجديد

### 13.1 بطاقات الدفع
الملف [lib/backend/schema/payment_methods_record.dart](C:\Users\almrs\Desktop\ara_oatan_app-main\lib\backend\schema\payment_methods_record.dart) يظهر تخزين بيانات بطاقة مثل الرقم و`ccv`. هذا غير مناسب إطلاقًا في باك اند إنتاجي.

التوصية:

- عدم تخزين بيانات البطاقة الخام.
- استخدام tokenization من مزود الدفع.
- حفظ `payment_method_token` أو `last4` و`brand` فقط.

### 13.2 منطق مالي في العميل
المحفظة والدفع والتسويات يجب أن تكون فقط في الباك اند.

### 13.3 صلاحيات عامة جدًا
بعض الـ collections تسمح بإنشاء أو قراءة عامة. يجب استبدال ذلك بـ API محمية.

### 13.4 عدم وجود Audit واضح
النظام يحتاج سجل أحداث واضح لـ:

- إنشاء الطلب
- قبول الطلب
- الدفع
- الإلغاء
- الاسترداد
- تغييرات الدعم

## 14. خطة التحويل المقترحة

### المرحلة 1: التثبيت والتحليل
- توحيد أسماء الـ collections.
- تحديد الكيانات الفعلية المستخدمة وحذف التجريبي.
- جرد جميع نقاط الكتابة المباشرة من Flutter إلى Firestore.

### المرحلة 2: بناء Backend API أساسية
- بناء مشروع Backend مستقل.
- ربط المصادقة.
- بناء Modules الأساسية:
  - auth
  - users
  - geography
  - places
  - bookings

### المرحلة 3: نقل منطق الحجوزات
- نقل إنشاء الطلب.
- نقل حساب الأسعار.
- نقل جدولة الرحلات.
- منع الإنشاء المباشر من Flutter.

### المرحلة 4: نقل المدفوعات والمحفظة
- نقل عمليات الدفع إلى backend webhooks/sessions.
- نقل المحفظة بالكامل.
- إيقاف تخزين أي بيانات بطاقة حساسة.

### المرحلة 5: نقل التشغيل والإشعارات
- نقل dispatch
- نقل الرسائل
- نقل الإشعارات
- نقل المهام المجدولة

### المرحلة 6: قفل الوصول المباشر
- تحديث Firestore rules بحيث يصبح الوصول المباشر محدودًا جدًا أو داخليًا فقط.

## 15. أولويات التنفيذ

إذا أردت فصل الباك اند بأقل مخاطرة، فابدأ بهذا الترتيب:

1. `Auth + Users`
2. `Bookings + Pricing`
3. `Payments`
4. `Wallet`
5. `Dispatch + Notifications`
6. `Support + Partner Applications`

## 16. التوصية النهائية

التطبيق الحالي قابل للفصل إلى Backend مستقل، لكن الطريقة الصحيحة ليست نسخ مجلد `backend` فقط، لأن هذا المجلد في صورته الحالية يحتوي:

- نماذج Firestore
- Helpers
- استدعاءات APIs
- وليس طبقة خدمة مستقلة حقيقية

التوصية العملية هي:

1. إنشاء مشروع Backend جديد مستقل.
2. اعتبار Flutter مجرد `client`.
3. إعادة تعريف كل عملية أعمال مهمة كـ API أو job داخل الباك اند.
4. إبقاء Firestore مؤقتًا إذا أردت تسريع التحويل.
5. نقل المنطق الحساس والمالي أولًا.

## 17. الخلاصة

المشروع الحالي هو Frontend ثقيل مع Backend موزع داخل Firebase والتطبيق نفسه.  
أما الهدف الذي تريده فهو Backend حقيقي مستقل، وهذا يتطلب:

- فصل منطق الأعمال عن Flutter
- توحيد نموذج البيانات
- بناء API طبقية واضحة
- نقل المدفوعات والمحفظة والإشعارات والحجوزات إلى الخادم

وبذلك يصبح:

- Flutter = واجهة فقط
- Backend = مصدر الحقيقة الوحيد
- Database = مخزن بيانات لا يُكتب فيه مباشرة من العميل إلا ضمن أضيق الحدود
