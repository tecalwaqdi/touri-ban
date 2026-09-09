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

**الحكم:** جاهزة للإنتاج من ناحية الأمان والصحة الوظيفية. الفجوات الحقيقية هي في **الحوكمة (CI)**، **الأداء (حجم الحزمة)**، و**بقايا ديون الترجمة** — لا في الأمان الأساسي.

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

#### M-2 — شاشات مكرّرة حيّة ومتباعدة، إحداها متاحة لوكلاء الدول

ثلاث وحدات بلاحقة `_copy` **مسجّلة كمسارات فعّالة** في `nav.dart` (وليست كودًا ميتًا كما قد يُفترض):

| الوحدة | المسار في nav.dart | الوصول |
|--------|--------------------|--------|
| `AdminaddMkanCopy` | 546 | **وكلاء الدول** (مُدرج في `_agentRoutes:420`) |
| `AdminDriversCopy` | 610 | سوبر أدمن فقط |
| `AdminAgentCopy` | 899 | سوبر أدمن فقط |

والأهم أن `adminadd_mkan_copy` (1,470 سطرًا) و`adminadd_mkan` (1,347 سطرًا) **تباعدتا بالكامل** — قياس الفرق بينهما بعد تطبيع الأسماء أعطى 2,658 سطر اختلاف، أي أنهما عمليًا شاشتان مختلفتان لا نسختان.

الخطر: أي إصلاح تحقق أو أمان يُطبَّق على الأصل لن يصل للنسخة. قواعد Firestore ستظل تحمي البيانات على الخادم (وهذا هو خط الدفاع الحقيقي)، لكن تجربة المستخدم والتحقق من جهة العميل ستتباعدان.

**الإجراء:** تحديد الشاشة المعتمدة، إزالة الأخرى من `nav.dart` ومن `_agentRoutes`، ثم حذف مجلدها.

#### M-3 — السائق يستطيع حذف وثائقه الرسمية بعد الاعتماد

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

#### M-4 — قواعد Firestore على حافة سقف 1000 تعبير

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
| 2 | حذف `lib/backend/admin_demo_seed.dart` ونقل بيانات الاعتماد لمتغيرات بيئة | حرجة | صغير |
| 3 | إضافة CI يشغّل `analyze` + `test` على كل PR | عالية | صغير |
| 4 | نقل ترويسات الأمان إلى `render.yaml` + إضافة CSP وHSTS | عالية | صغير |
| 5 | حذف اللغات الأربع غير المعروضة من `ui_catalog.dart` | عالية | صغير |
| 6 | إصلاح الرسائل التسع ذات المتغيّرات بمفاتيح ذات معاملات | متوسطة | متوسط |
| 7 | توحيد شاشات `_copy` المكرّرة وإزالتها من التوجيه والصلاحيات | متوسطة | متوسط |
| 8 | تقييد حذف وثائق السائق بعد الاعتماد في `storage.rules` | متوسطة | صغير |
| 9 | تقسيم الكود بـ`deferred as` ونقل الكتالوجات إلى JSON | عالية (أداء) | كبير |
| 10 | مراجعة `invalid_null_aware_operator` الأربعة في مسار المطابقة | منخفضة | صغير |

---

## 5. ملاحظات منهجية

- الأرقام أعلاه من تشغيل فعلي على هذا المستودع، لا من تقديرات: البناء والاختبارات والتحليل نُفِّذت كلها.
- فحصتُ الحزمة المبنية نفسها (`build/web/main.dart.js`) للتحقق من تسريب بيانات الاعتماد بدل الاكتفاء بقراءة الكود.
- قياسات الترجمة نُفِّذت بسكربتات على الكتالوجات الفعلية، لا بالتقدير.
- الفارق في نسخة Flutter (‏3.47.2 للفحص مقابل 3.44.8 للإنتاج) قد يغيّر عدد تنبيهات `deprecated_member_use` قليلًا، لكنه لا يؤثر على نتائج الأمان أو الاختبارات أو الترجمة.
- **لم أختبر ضد Firebase الإنتاج**، ولم أحاول تسجيل الدخول بأي بيانات اعتماد وجدتها. التحقق من حياة حساب `demo.super` متروك لكم ويجب أن يتم فورًا.
