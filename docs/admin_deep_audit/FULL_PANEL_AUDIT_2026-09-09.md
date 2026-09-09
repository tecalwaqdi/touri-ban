# فحص شامل للوحة التحكم — Touri Admin Panel

**التاريخ:** 2026-09-09
**النطاق:** `admin/Admi` — لوحة تحكم Flutter Web (477 ملف Dart، 150,497 سطر، 75 مسارًا)
**نوع الفحص:** فحص تنفيذي حقيقي (بناء + اختبارات + تحليل ساكن) وليس مراجعة كود فقط.
**سلسلة الأدوات المستخدمة في الفحص:** Flutter 3.47.2 / Dart 3.13.2
**سلسلة الأدوات المثبّتة للإنتاج:** Flutter 3.44.8 (`scripts/ensure_pinned_flutter.sh`)

---

## 1. الخلاصة التنفيذية

اللوحة **في حالة هندسية جيدة** وأفضل بكثير مما يوحي به حجمها. الأساسات الحرجة — قواعد الأمان على الخادم، الحساب المالي، ومنظومة الترجمة — مبنية بشكل صحيح ومختبَرة فعليًا.

| المحور | النتيجة | الدليل |
|--------|---------|--------|
| البناء للإنتاج | **ناجح** | `flutter build web --release` → `✓ Built build/web` |
| الاختبارات | **ناجحة** | 556 اختبارًا نجح، 2 متخطّى، 0 فشل |
| التحليل الساكن | **نظيف** | 42 تنبيهًا، **0 أخطاء** |
| قواعد Firestore | **محكمة** | منع افتراضي + تحقق من الأدوار على الخادم |
| دقة الأموال | **صحيحة** | وحدات صغرى صحيحة + منع خلط العملات |
| تكافؤ مفاتيح الترجمة | **100%** | 7 لغات × 2,230 مفتاحًا، صفر نقص |
| حماية المسارات | **كاملة** | 73/75 مسارًا محمي (المتبقيان هما الدخول) |
| تكامل مستمر (CI) | **غائب** | لا يوجد أي workflow يشغّل الاختبارات |

**الحكم:** الأساس الأمني والمحاسبي سليم، ولا توجد ثغرة تسمح بتصعيد صلاحيات أو تلاعب مالي من العميل. الفجوات الحقيقية ثلاث فئات: **حوكمة** (غياب CI وترويسات الأمان)، **أداء** (حزمة غير مقسّمة)، و**تسريبات نطاق وعرض** (قراءات غير محصورة بالدولة، ومفتاح Maps مشحون، وخطأ عرض ×10 لعملات الثلاث خانات). كلها قابلة للإصلاح بتغييرات صغيرة ومحدّدة — لا تحتاج إعادة هيكلة.

---

## 2. النتائج مرتبة حسب الخطورة

### حرجة (Critical)

#### C-1 — بيانات اعتماد سوبر-أدمن مكتوبة في المستودع وتشير لمشروع الإنتاج

```
test/seed_production_test.dart:33   const email = 'demo.super@arawatan.sa';
test/seed_production_test.dart:34   const password = 'Demo@2026';
lib/backend/admin_demo_seed.dart:40 const kDemoSeedPassword = 'Demo@2026';
lib/backend/admin_demo_seed.dart:49 static const _superEmail = 'demo.super@arawatan.sa';
tool/seed_production_main.dart:26   defaultValue: 'demo.super@arawatan.sa';
tool/seed_production_main.dart:30   defaultValue: 'Demo@2026';
admin/mndob-main/integration_test/cash_confirm_ui_runtime_test.dart:23
```

المشروع المستهدف هو مشروع الإنتاج نفسه (`.firebaserc` → `tutorial-multi-language-70gx4j`).

الأخطر أن الاختبار **ينشئ الحساب إن لم يكن موجودًا** ويمنحه صلاحية سوبر أدمن كاملة:

```50:59:admin/Admi/test/seed_production_test.dart
            await UserRecord.collection.doc(uid).set(
                  createUserRecordData(
                    email: email,
                    displayName: 'سوبر أدمن التعبئة',
                    uid: uid,
                    actevUser: true,
                    createdTime: getCurrentTimestamp,
                    isAdmin: true,
                    isAdminRule: AdminRoleService.ruleSuperAdmin,
                  ),
```

**التخفيف الحالي:** تحققتُ من الحزمة المبنية فعليًا — كلمة المرور **لا تُشحن** للمتصفح، لأن `admin_demo_seed.dart` ملف يتيم لا يشير إليه أي كود في `lib/`، فيحذفه الـtree-shaking:

```bash
$ grep -c "Demo@2026" build/web/main.dart.js   # → 0
```

لكن هذا التخفيف **عرضي وهش**: بمجرد أن يربط أحدهم زر "تعبئة بيانات تجريبية" بالشاشة، تُشحن كلمة المرور لكل متصفح يفتح اللوحة.

**المخاطرة الفعلية:** إن كان الحساب حيًا في Firebase Auth للإنتاج، فأي شخص لديه وصول للمستودع (أو لتاريخه) يستطيع الدخول كسوبر أدمن.

**الإجراء المطلوب:**
1. التحقق فورًا من وجود `demo.super@arawatan.sa` في Firebase Auth للإنتاج، وتعطيله/حذفه إن وُجد.
2. تدوير كلمة المرور، ونقلها كليًا إلى متغيرات بيئة (`String.fromEnvironment`) كما فعلت أدوات `qa_tools` الأخرى بشكل صحيح.
3. حذف `lib/backend/admin_demo_seed.dart` — فهو ميت تمامًا داخل `lib/`، ووجوده داخل شجرة الإنتاج خطر دائم.
4. الاعتبار: البيانات موجودة في تاريخ git منذ `36358b9` (الاستيراد الأول)، فالتدوير إلزامي ولا يكفي الحذف.

---

### عالية (High)

#### H-1 — لا يوجد تكامل مستمر (CI) للوحة التحكم إطلاقًا

`admin/Admi/.github/workflows/` يحتوي على ملف واحد فقط: `ios-ipa.yml`.
لا يوجد أي workflow يشغّل `flutter analyze` أو `flutter test`.

النتيجة: **556 اختبارًا لا تحرس أي دمج**. أي تغيير يمكن أن يكسر الحساب المالي أو RBAC ويُدمج دون أن يلاحظ أحد. وقيمة هذه الاختبارات عالية جدًا (تغطي المحاسبة، التسويات، الصلاحيات)، فبقاؤها بلا بوابة إهدار كامل لها.

المفارقة أن النمط الصحيح موجود في المستودع نفسه: `admin/ara_oatan_app/.github/workflows/localization-checks.yml` يشغّل 6 فحوصات ترجمة آليًا. اللوحة فقط محرومة منه.

**الإجراء:** إضافة workflow يشغّل `flutter pub get` + `flutter analyze --fatal-infos` + `flutter test` على كل PR يمس `admin/Admi/**`، مع تثبيت Flutter 3.44.8 لمطابقة الإنتاج.

#### H-2 — مضيف الإنتاج (Render) بلا أي ترويسات أمان

`vercel.json` يضبط ترويسات الحماية:

```12:19:admin/Admi/vercel.json
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" }
      ]
    }
  ]
```

بينما `render.yaml` — وهو **مسار النشر الفعلي للإنتاج** (`last_manual_trigger: 2026-09-07`, ورسائل الـcommit تذكر "Render release") — يضبط ترويسات `Cache-Control` فقط ولا يضبط أيًا من:

- `X-Frame-Options` / `frame-ancestors` → لوحة التحكم قابلة للتضمين في iframe (clickjacking).
- `X-Content-Type-Options: nosniff`
- `Strict-Transport-Security`
- `Content-Security-Policy`
- `Referrer-Policy`

**الإجراء:** نقل ترويسات الأمان من `vercel.json` إلى `render.yaml` وإضافة HSTS وCSP وReferrer-Policy. لوحة إدارية تدير المال والسائقين يجب ألا تكون قابلة للتأطير.

#### H-3 — لا يوجد أي تقسيم للكود: حزمة 13MB في ملف واحد

```bash
$ grep -rn "deferred as" lib/ | wc -l   # → 0
$ ls -lh build/web/main.dart.js         # → 13M  (2.62 MB مضغوط gzip)
$ du -sh build/web                      # → 53M
```

كل الـ75 مسارًا و150 ألف سطر تُجمَّع في `main.dart.js` واحد. المستخدم الذي يريد فتح شاشة واحدة يحمّل التطبيق كله، بالإضافة إلى CanvasKit (‏7MB wasm).

مساهم رئيسي مفاجئ: **كتالوجات الترجمة وحدها 36,902 سطرًا (24% من قاعدة الكود)** مكتوبة كـ`const` maps في Dart وتُجمَّع كلها في الحزمة:

| الملف | الأسطر |
|-------|-------:|
| `lib/l10n/ui_catalog.dart` | 25,914 |
| `lib/flutter_flow/internationalization.dart` | 6,132 |
| `lib/l10n/admin_translations.dart` | 2,591 |
| `lib/l10n/nav_translations.dart` | 1,333 |
| `lib/l10n/enterprise_translations.dart` | 823 |

ومنها **4 لغات لا تُعرض للمستخدم أصلًا** (`az`, `ka`, `tr`, `zh_Hans`) — 1,847 مفتاحًا × 4 لغات من النصوص الميتة داخل الحزمة، لأن `main.dart` يعرض 7 لغات فقط.

**الإجراء:**
1. حذف اللغات الأربع غير المعروضة من الكتالوج (مكسب فوري بلا مخاطرة).
2. نقل الكتالوجات إلى أصول JSON تُحمَّل عند الطلب بدل `const` maps في Dart.
3. استخدام `deferred as` للوحدات الثقيلة غير المستخدمة في كل جلسة (المالية، التقارير، الجغرافيا).

---

#### H-4 — مفتاح Google Maps حقيقي يُشحن فعليًا في حزمة الإنتاج

```7:7:admin/Admi/lib/components/admin_location_service.dart
const kAdminGoogleMapsApiKey = 'AIzaSyBOPqaoFQ3KTFEgnWSJ_9S-9bPAp8rU2HM';
```

هذا ليس مفتاح Firebase Web (العام بطبيعته). إنه مفتاح Maps مستخدم فعليًا (`admin_location_section.dart:19`، `admin_location_service.dart:101`)، وتحققتُ من الحزمة المبنية:

```bash
$ grep -c "AIzaSyBOPqaoFQ3KTFEgnWSJ_9S-9bPAp8rU2HM" build/web/main.dart.js   # → 2
```

أي أنه مكشوف لكل من يفتح اللوحة. إن لم يكن مقيَّدًا بـHTTP referrer وبالـAPIs المطلوبة فقط في GCP، فهو قابل للاستغلال لاستنزاف الحصة والفوترة.

**الإجراء:** تقييد المفتاح فورًا بنطاق اللوحة وبـAPIs محددة، أو تمرير طلبات الـGeocoding عبر Cloud Function وسيطة بدل كشف المفتاح للعميل. (هذا مختلف عن مفتاح iOS في L-2 أدناه.)

#### H-5 — عرض المبالغ يقسم على 100 دائمًا، ويكسر عملات الثلاث خانات

النظام يعرّف أُسّ الوحدات الصغرى لكل عملة بشكل صحيح:

```9:22:admin/Admi/lib/core/finance/money_amount.dart
  /// ISO 4217 minor-unit exponents we support for reporting.
  static const Map<String, int> _exponentByCode = {
    'SAR': 2,
    'AED': 2,
    ...
    'TND': 3,
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
    'JOD': 3,
```

لكن طبقة العرض تتجاهله وتقسم على 100 ثابتة:

```68:71:admin/Admi/lib/admin/admin_settlements/admin_settlement_details_widget.dart
  String _money(int? minor, String currency) {
    final symbol = AdminCurrency.symbolByCode[currency] ?? currency;
    final major = (minor ?? 0) / 100.0;
    return AdminOrderMoneyDisplay.formatMajor(major, symbol: symbol);
```

ونفس الخطأ في `lib/core/finance/admin_finance_ui_labels.dart:85`.

**الأثر:** مبلغ 1,000 فلس كويتي (= 1.000 د.ك) يُعرض **10.00 د.ك** — خطأ بمقدار عشرة أضعاف في شاشة تفاصيل التسوية. وليس افتراضيًا: الكويت والبحرين وعُمان والأردن كلها مُعرَّفة في `AdminCurrency.fallbackByIso`، وكلها بأُس 3.

**الإجراء:** استبدال القسمة الثابتة بـ`MoneyAmount(currency: code, minorUnits: minor).displayLabel` أو `CurrencyMoneyPolicy.exponentOrNull(code)`. إصلاح صغير جدًا وأثره مباشر على صحة الأرقام المعروضة للمحاسبين.

#### H-6 — وكيل دولة واحدة يقرأ بيانات كل الدول المالية والتدقيقية

القواعد تحصر التسويات بنطاق الدولة عبر `canReadSettlement()`، لكن أربع مجموعات حسّاسة **تفتقد هذا الحصر تمامًا**:

```1557:1559:admin/Admi/firebase/firestore.rules
    match /financial_periods/{id} {
      allow read: if signedIn() && (isSuperAdmin() || isFinance() || isCountryAdmin());
      allow create, update, delete: if false;
```

```1267:1269:admin/Admi/firebase/firestore.rules
    match /admin_audit_log/{document} {
      allow read: if isSuperAdmin() || isCountryAdmin();
      allow create, update, delete: if false;
```

ونفس النمط في `financial_adjustments` (‏1562) و`financial_audit_events` (‏1571). أي أن `country_admin` مسؤول عن دولة واحدة يقرأ الفترات المالية والتعديلات وأحداث التدقيق وسجل عمليات الإدارة **لكل الدول**. الكتابة ممنوعة (`if false`) فالخطر تسريب لا تلاعب، لكنه تسريب مالي وتشغيلي عابر للنطاقات.

**الإجراء:** تطبيق نفس نمط `canReadSettlement()` — مقارنة `resource.data.countryId` / `countryRef` بـ`claimCountryPath()`، مع إبقاء القراءة الشاملة لـ`super_admin` و`finance` العالمي فقط.

---

### متوسطة (Medium)

#### M-1 — 9 رسائل ستظهر بالعربية دائمًا مهما كانت اللغة المختارة

آلية الترجمة `uiTr(context, arabic)` تستخدم **النص العربي نفسه كمفتاح بحث**:

```25903:25914:admin/Admi/lib/l10n/ui_catalog.dart
String uiTr(BuildContext context, String arabic) {
  final key = kArabicUiLookup[arabic];
  if (key == null) return arabic;
```

فإذا لم يوجد المفتاح، تُعاد **العربية بصمت**. وقياسًا دقيقًا: من 2,462 استدعاءً (1,521 نصًا مميزًا)، **1,505 مغطّى (99%)** — تغطية ممتازة. لكن الـ16 غير المغطّى كلها نصوص تحتوي متغيّرات، فلا يمكن أن تطابق مفتاحًا ثابتًا **أبدًا**:

| الموقع | النص |
|--------|------|
| `lib/home22_dashboard/home22_dashboard_widget.dart:194` | `$greeting، $name` |
| `lib/admin/admindrever/admin_driver_expiry_adapter.dart:156` | `منتهية منذ $d يومًا` |
| `lib/admin/admindrever/admin_driver_expiry_adapter.dart:160` | `متبقي $d يومًا` |
| `lib/admin/admindrever/admin_driver_expiry_adapter.dart:168` | `منتهية منذ ${-diffDays} يومًا` |
| `lib/admin/admindrever/admin_driver_expiry_adapter.dart:174` | `متبقي $diffDays يومًا` |
| `lib/admin/admindrever/admin_driver_expiry_adapter.dart:177` | `متبقي $months أشهر` |
| `lib/admin/admin_agent_finance/admin_agent_finance_widget.dart:244` | `${agents.length} وكلاء` |
| `lib/components/accountant_finance_summary.dart:232` | `$count رحلة تحتاج مراجعة` |
| `lib/admin/admin_finance_reconciliation/…_widget.dart:313` | `تم استبعاد ${…} رحلة من مجاميع الأموال` |

الأثر ملموس: **تحية لوحة القيادة** هي أول ما يراه أي مستخدم بعد الدخول، وستظهر عربية لمدير روسي أو قيرغيزي. وطابور انتهاء صلاحية وثائق السائقين — شاشة تشغيلية يومية — عربي بالكامل في عمود المدة.

**الإجراء:** تحويل هذه التسعة إلى مفاتيح ذات معاملات (placeholders) مثل `ui_days_remaining` مع `{count}`، بدل تمرير نص مُركَّب للبحث. هذه فئة أخطاء لا يلتقطها أي اختبار حالي.

> ملاحظة على التقرير السابق: `ADMIN_FINAL_AUDIT.md` ادّعى «0 missing lookup keys for live `uiTr` calls». الادعاء صحيح للنصوص الثابتة فقط، ولا يشمل النصوص المُركَّبة.

#### M-2 — تسمية `_copy` مضلِّلة، لا تكرار فعلي

المجلدات الثلاثة بلاحقة `_copy` **ليست نسخًا مكرّرة** كما توحي أسماؤها. تحققتُ من كل منها:

| الوحدة | الأسطر | الحقيقة |
|--------|-------:|---------|
| `admin_agent_copy` | 21 | إعادة توجيه legacy إلى Settings |
| `admin_drivers_copy` | 43 | إعادة توجيه legacy إلى `AdminDrivers` |
| `adminadd_mkan_copy` | 1,470 | **شاشة تعديل المعلم** — `routePath = '/adminEdetMkan'` |

أي أن `adminadd_mkan_copy` شاشة مستقلة مشروعة (تعديل) مقابل `adminadd_mkan` (إضافة)، ووجودها في `_agentRoutes` صحيح. الاختلاف الكبير بين الملفين متوقّع لأنهما نموذجا إضافة وتعديل، لا نسختان متباعدتان.

الدين الحقيقي هنا **تسمية فقط**: اسم `_copy` يوحي بكود ميت ويدفع أي مطور للاعتقاد أن حذفه آمن — وحذفه سيكسر تعديل المعالم لوكلاء الدول.

**الإجراء:** إعادة تسمية `adminadd_mkan_copy` → `adminadd_mkan_edit` (والصنف والمسار تبعًا لذلك)، وحذف المجلدين الآخرين بعد التأكد من انقضاء الروابط القديمة.

#### M-3 — قراءة إعدادات النظام متاحة لغير المسجّلين

```1299:1302:admin/Admi/firebase/firestore.rules
    match /Settings/{document} {
      allow read: if true;
      allow create, update, delete: if isSuperAdmin();
    }
```

`allow read: if true` بلا `signedIn()` — أي زائر على الإنترنت يقرأ مجموعة `Settings` كاملة دون تسجيل دخول. الخطورة تتوقف على محتواها (أعلام ميزات، عناوين خدمات داخلية، عتبات تشغيلية).

**الإجراء:** رفعها إلى `allow read: if signedIn()` كحد أدنى، وحصر الحقول الحسّاسة بأدوار الإدارة.

#### M-4 — تجميع مبيعات عابر للعملات في مؤشر واحد

```171:176:admin/Admi/lib/backend/admin_reports_loader.dart
    final f = FinancialEngine.orderFinancials(order);
    if (f.isPaid) {
      paid++;
      sales += f.totalSales;
    }
```

`sales` رقم `double` واحد يُجمع عبر كل الطلبات بغضّ النظر عن عملتها. عند عرض «كل الدول» يصير 1000 د.إ + 50000 سوم = 51000 «وحدة» بلا معنى. التقسيم `salesByCountry` سليم لأن كل دولة بعملة واحدة، لكن **المؤشر الإجمالي مضلِّل**.

ونفس النمط في إحصاءات التسويات:

```103:103:admin/Admi/lib/core/finance/finance_company_service.dart
        outstanding += (d['outstandingMinor'] as num?)?.toInt() ?? 0;
```

يجمع وحدات صغرى من عملات مختلفة في عدد واحد.

المفارقة أن الحل موجود بالفعل في نفس المستودع: `FinancialAccountingEngine.aggregateByCurrency` يجمّع لكل عملة على حدة. المسار القديم `FinancialEngine` فقط هو من يتجاوزه.

**الإجراء:** تحويل مؤشرات لوحة القيادة وإحصاءات التسوية إلى `aggregateByCurrency`، وعرض مؤشر لكل عملة بدل رقم موحّد.

#### M-5 — السائق يستطيع حذف وثائقه الرسمية بعد الاعتماد

```admin/Admi/firebase/storage.rules
    match /users/{userId}/{allPaths=**} {
      allow read: if canReadUserUploads(userId);
      allow create, update: if signedIn()
        && request.auth.uid == userId
        && validUserUpload();
      allow delete: if signedIn() && request.auth.uid == userId;
    }
```

`allow delete` غير مشروط بحالة المراجعة. سائق مُعتمَد يستطيع حذف رخصته أو تأمينه من التخزين بعد الموافقة، فتبقى حالة الاعتماد في Firestore بلا مستند داعم — فجوة امتثال ومراجعة.

**الإجراء:** منع الحذف بعد `registration_status == 'approved'`، أو حصر الحذف بالسوبر أدمن، أو التحويل إلى حذف منطقي (soft-delete) مع أرشفة.

#### M-6 — قواعد Firestore على حافة سقف 1000 تعبير

تعليقات القواعد نفسها توثّق أن الحد قد أُصيب فعلًا وسبّب أعطالًا في الإنتاج:

```
// Own-profile create FIRST — separate statement so panelCanProvisionUser()
// does not burn the 1000-expression budget for normal customer signup.

// Own profile first (separate statement) — avoids recursive isSuperAdmin()
// get() while evaluating currentUserData() from other rules.

// Own-profile update FIRST — critical: the panel OR-chain below exceeds the
// 1000-expression limit and was denying ALL customer profile writes
// (photo_url, phone, display_name, login sync).
```

الترتيب الحالي حلٌّ صحيح لكنه **يعتمد على ترتيب الجُمل**، وهو هشّ: إضافة شرط واحد لسلسلة `allow update` قد تُعيد كسر كتابة ملفات كل العملاء. وكل استدعاء `get()` (تسعة في الملف) يكلّف قراءة مستند إضافية على كل طلب.

**الإجراء:** الاعتماد أكثر على custom claims بدل `get(currentUserRef())` في المسارات الساخنة، وإضافة اختبارات على محاكي Firestore تغطي ميزانية التعبيرات لكل مسار حرج.

#### M-7 — بوابة الكتابة المالية مطبَّقة على نصف العمليات فقط

`FinanceRuntimeGate.canAttemptFinanceWrites` تمنع الكتابة عندما تكون الأرقام المعروضة تقريبية (‏`client_full`) بدل أن تأتي من الخادم. تحققتُ من العمليات الأربع في شاشة تفاصيل التسوية:

| العملية | البوابة |
|---------|---------|
| `_lock` | موجودة |
| `_confirmPayment` | موجودة |
| `_recordPayment` | **مفقودة** |
| `_voidLocked` | **مفقودة** |

النتيجة تناقض منطقي: على نفس البيانات التقريبية، المستخدم **يُمنع** من قفل التسوية لكنه **يستطيع** تسجيل دفعة أو إلغاء تسوية مقفلة. وهاتان العمليتان أخطر من القفل لأنهما تحرّكان مالًا.

**الإجراء:** إضافة نفس الفحص في مقدمة `_recordPayment` و`_voidLocked`، ويفضَّل استخراجه إلى دالة حارسة واحدة تُستدعى من كل عملية كتابة مالية بدل تكرار الشرط.

#### M-8 — زر في شاشة العرض التجريبي يستدعي الخادم الحقيقي

شاشة تفاصيل التسوية تدعم بيانات عرض تجريبية بمعرّفات تبدأ بـ`fixture_` (`settlement_visual_fixture.dart:6-7`). معظم أزرارها محمية بحوار تأكيد لا يكتب شيئًا، لكن زر القفل يستدعي المعالج الحقيقي مباشرة:

```538:541:admin/Admi/lib/admin/admin_settlements/admin_settlement_details_widget.dart
                OutlinedButton(
                  onPressed: () => _lock(fixture),
                  child: Text(uiTr(context, 'قفل التسوية')),
                ),
```

فيصل نداء مُصادَق عليه إلى Cloud Function بمعرّف وهمي مثل `fixture_locked`. الأثر محدود (المستند غير موجود فيفشل النداء)، لكنه سلوك غير مقصود: شاشة معلَّمة «عرض تجريبي» تُحدِث نداءات كتابة حقيقية.

**الإجراء:** في فرع الـfixture، ربط الأزرار بمعالجات وهمية أو تعطيلها، بدل استدعاء `_lock` الحقيقي.

---

### منخفضة (Low)

#### L-1 — منطقة عمياء في التحليل الساكن

`analysis_options.yaml` يستثني `lib/custom_code/**` و`lib/flutter_flow/custom_functions.dart`. شغّلتُ التحليل عليهما يدويًا: **132 سطرًا فقط و14 تنبيه استيراد غير مستخدم** — لا شيء خطر. الاستثناء مقبول لكن يُفضّل تضييقه حتى لا يصير مخبأً مستقبليًا.

#### L-2 — مفتاح Google Maps لنظام iOS مكتوب مباشرة

```admin/Admi/ios/Runner/AppDelegate.swift:11
GMSServices.provideAPIKey("AIzaSyC9cNHrWjo5MVYIgVRZKyvo4f6KxgGEFFM")
```

هذا مفتاح حقيقي (بخلاف مفاتيح Firebase Web العامة بطبيعتها، وهي ليست تسريبًا). يجب التأكد من تقييده بـBundle ID في Google Cloud Console وإلا فهو عرضة لاستنزاف الحصة والفوترة.

#### L-3 — 42 تنبيهًا في التحليل الساكن

لا أخطاء. أبرزها القابل للإصلاح فورًا:

- 4 × `invalid_null_aware_operator` في `lib/admin/admin_reconciliation/admin_reconciliation_widget.dart:182,250,265,278` — يشير إلى سوء فهم لقابلية الإسناد null في مسار المطابقة المالية، يستحق نظرة.
- `unused_element` لـ`_isFinanceOnlyPersona` في `lib/backend/admin_panel_session.dart:115` — منطق صلاحيات مكتوب وغير مستخدم؛ يُتحقق إن كان يُفترض استدعاؤه.
- الباقي: `deprecated_member_use` (‏`value` → `initialValue`) واستيرادات زائدة.

---

## 3. ما هو مُنفَّذ بشكل ممتاز

هذه ليست مجاملة — هي نقاط تحققتُ منها وأنصح بعدم المساس بها:

**قواعد Firestore تفرض الأمان على الخادم فعلًا.** التطبيق Flutter Web أي أن حزمة JS مكشوفة بالكامل، فالحماية الحقيقية يجب أن تكون في القواعد — وهي كذلك. كل مجموعات المالية `create, update, delete: if false` بلا استثناء، والكتابة حصريًا عبر Admin SDK:

```admin/Admi/firebase/firestore.rules
    match /financial_settlements/{id} {
      allow read: if signedIn() && canReadSettlement();
      allow create, update, delete: if false;
```

**منع تصعيد الصلاحيات شامل ومدروس.** `privilegedUserFieldsUnchanged()` يقفل 30+ حقلًا حساسًا، ويستعمل `diff()` بدل مقارنة القيم الافتراضية تحديدًا كي لا يلتفّ عليه `FieldValue.delete()` — وهي ثغرة دقيقة جدًا يغفل عنها الأغلب:

```593:595:admin/Admi/firebase/firestore.rules
        // F03 — Agent commercial rates: client cannot create/update/delete
        // (use diff so FieldValue.delete() cannot bypass get-default equality).
        && agentCommercialRatesUnchanged()
```

**الحساب المالي صحيح رياضيًا.** `MoneyAmount` يعمل بوحدات صغرى صحيحة مع أُس خاص بكل عملة (لا افتراض `×100` للجميع)، و**خلط العملات يرمي استثناءً** بدل أن يُنتج رقمًا خاطئًا بصمت:

```98:104:admin/Admi/lib/core/finance/money_amount.dart
  void _sameCurrency(MoneyAmount other) {
    if (code != other.code) {
      throw ArgumentError(
        'Cannot combine currencies $code and ${other.code}',
      );
    }
  }
```

في منصة متعددة الدول (SAR/AED/KGS) هذا هو الفارق بين تسوية صحيحة وأخرى كارثية.

**تكافؤ الترجمة كامل 100%.** قست المفاتيح بنفسي عبر الكتالوجات الأربعة للغات السبع المعروضة:

| الكتالوج | المفاتيح | النقص في أي لغة |
|----------|---------:|----------------:|
| `kUiCatalog` | 1,847 | 0 |
| `kAdminTranslations` | 191 | 0 |
| `kNavTranslations` | 102 | 0 |
| `kEnterprise` | 90 | 0 |

والقيم المطابقة للإنجليزية قليلة جدًا (ar: 60، ru: 15، ky: 40 من 1,847). كما تحققتُ أن سلسلة الرجوع `ky → ru` أُزيلت فعلًا كما ادّعى الـcommit — القيرغيزية ترجع للإنجليزية مباشرة.

**حماية المسارات مكتملة.** 73 من 75 مسارًا عليها `requireAuth: true`؛ المساران الآخران هما `_initialize` وصفحة الدخول. وRBAC يستخدم **قوائم سماح** أي أن المسار الجديد مرفوض افتراضيًا لكل الأدوار غير السوبر أدمن — وهو الاتجاه الصحيح للفشل.

**بوابة الحماية من التسميم في الاستعلامات.** التعليقات توثّق فهمًا عميقًا لسلوك Firestore: فصل `get` عن `list` تجنبًا لتسميم قوائم `list` باستدعاءات `get()`، واستبعاد `country_admin` من `isFinance()` لأنه سرّب قوائم طلبات غير مقيّدة.

**أعلام الميزات آمنة افتراضيًا.** كل الأعلام الحساسة `defaultValue: false` وتُفعَّل فقط عبر `--dart-define`: `ADMIN_QA_FIXTURES`، `TOURY_ADMIN_USER_CREATE_FALLBACK`. وعميل الدفع يرفض عناوين localhost في وضع الإصدار.

**لا كلمات مرور مكتوبة في أدوات الفحص.** كل الـ`qa_tools` (20+ سكربت) تقرأ `ADMIN_QA_EMAIL` / `ADMIN_QA_PASSWORD` من البيئة. لا ملفات حسابات خدمة أو مفاتيح خاصة متتبَّعة في git.

**تثبيت صارم لسلسلة أدوات البناء.** `ensure_pinned_flutter.sh` يرفض البناء إن اختلفت نسخة Flutter أو مراجعة المحرك، و`render_build.sh` يتحقق من ملف provenance بعد البناء. هذا مستوى نضج أعلى من المعتاد.

---

## 4. التوصيات مرتبة حسب العائد

| # | الإجراء | الخطورة | الجهد |
|---|---------|---------|-------|
| 1 | تعطيل حساب `demo.super@arawatan.sa` في الإنتاج وتدوير كلمة المرور | حرجة | دقائق |
| 2 | تقييد مفتاح Maps المشحون في الحزمة بـreferrer وAPIs محددة | عالية | دقائق |
| 3 | إصلاح القسمة `/100` → أُسّ العملة (يمنع خطأ ×10 في الكويت/البحرين/عُمان/الأردن) | عالية | صغير |
| 4 | حصر قراءة `financial_periods`/`adjustments`/`audit_events`/`admin_audit_log` بنطاق الدولة | عالية | صغير |
| 5 | حذف `lib/backend/admin_demo_seed.dart` ونقل بيانات الاعتماد لمتغيرات بيئة | حرجة | صغير |
| 6 | إضافة CI يشغّل `analyze` + `test` على كل PR | عالية | صغير |
| 7 | نقل ترويسات الأمان إلى `render.yaml` + إضافة CSP وHSTS | عالية | صغير |
| 8 | رفع `Settings` من `allow read: if true` إلى `signedIn()` | متوسطة | دقائق |
| 9 | إضافة بوابة الكتابة المالية إلى `_recordPayment` و`_voidLocked` | متوسطة | صغير |
| 10 | حذف اللغات الأربع غير المعروضة من `ui_catalog.dart` | عالية (أداء) | صغير |
| 11 | تحويل مؤشرات المبيعات إلى `aggregateByCurrency` | متوسطة | متوسط |
| 12 | إصلاح الرسائل التسع ذات المتغيّرات بمفاتيح ذات معاملات | متوسطة | متوسط |
| 13 | تقييد حذف وثائق السائق بعد الاعتماد في `storage.rules` | متوسطة | صغير |
| 14 | إعادة تسمية `adminadd_mkan_copy` → `adminadd_mkan_edit` | متوسطة | صغير |
| 15 | تقسيم الكود بـ`deferred as` ونقل الكتالوجات إلى JSON | عالية (أداء) | كبير |

---

## 5. ملاحظات منهجية

- الأرقام أعلاه من تشغيل فعلي على هذا المستودع، لا من تقديرات: البناء والاختبارات والتحليل نُفِّذت كلها.
- فحصتُ الحزمة المبنية نفسها (`build/web/main.dart.js`) للتحقق من تسريب المفاتيح وبيانات الاعتماد بدل الاكتفاء بقراءة الكود. وهذا الفرق مهم عمليًا: كلمة مرور الـseed **لا** تُشحن (الملف يتيم فيُحذف)، بينما مفتاح Maps **يُشحن** (مستخدَم فعليًا). قراءة الكود وحدها كانت ستخلط بين الحالتين.
- كل نتيجة واردة من فحص فرعي متخصص أُعيد التحقق منها مباشرة على الملفات قبل إدراجها هنا؛ ما لم يصمد أمام التحقق لم يُدرج.
- قياسات الترجمة نُفِّذت بسكربتات على الكتالوجات الفعلية، لا بالتقدير.
- الفارق في نسخة Flutter (‏3.47.2 للفحص مقابل 3.44.8 للإنتاج) قد يغيّر عدد تنبيهات `deprecated_member_use` قليلًا، لكنه لا يؤثر على نتائج الأمان أو الاختبارات أو الترجمة.
- **لم أختبر ضد Firebase الإنتاج**، ولم أحاول تسجيل الدخول بأي بيانات اعتماد وجدتها. التحقق من حياة حساب `demo.super` متروك لكم ويجب أن يتم فورًا.
