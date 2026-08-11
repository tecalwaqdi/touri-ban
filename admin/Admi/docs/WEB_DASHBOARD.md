# لوحة التحكم — Web Dashboard

لوحة إدارة **توري تاكسي** كتطبيق Flutter Web مستقل، مع Path URL Strategy جاهز للنشر تحت المسار `/admin/`.

## الرابط الافتراضي

| البيئة | الرابط |
|--------|--------|
| محلي (تطوير) | `http://127.0.0.1:8080/` |
| صفحة الدخول | `http://127.0.0.1:8080/homePage` |
| لوحة الرئيسية بعد الدخول | `http://127.0.0.1:8080/home22Dashboard` |
| **إنتاج (افتراضي)** | `https://<your-domain>/admin/` |
| دخول الإنتاج | `https://<your-domain>/admin/homePage` |

المسار الإنتاجي المعتمد: **`/admin/`**

---

## التشغيل المحلي

من مجلد المشروع:

```bash
cd admin/Admi
chmod +x scripts/run_web_admin.sh scripts/build_web_admin.sh
./scripts/run_web_admin.sh 8080
```

أو مباشرة:

```bash
cd admin/Admi
flutter pub get
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8080
```

ثم افتح: **http://127.0.0.1:8080/**

للمتصفح مباشرة (Chrome):

```bash
flutter run -d chrome --web-port=8080
```

---

## بناء Production

```bash
cd admin/Admi
./scripts/build_web_admin.sh /admin/
```

الناتج:

- `build/web/` — مخرجات Flutter
- `build/web_hosting/admin/` — جاهز للاستضافة تحت `/admin/`
- `build/web_hosting/index.html` — إعادة توجيه من `/` إلى `/admin/`

لبناء على جذر الموقع بدل `/admin/`:

```bash
./scripts/build_web_admin.sh /
```

---

## النشر على Vercel

راجع `docs/ADMIN_VERCEL.md`.

**مهم:** Vercel يُبنى بـ `base-href=/` (جذر النطاق). Firebase Hosting يستخدم `/admin/`.

| الاستضافة | أمر البناء | مثال الدخول |
|-----------|------------|-------------|
| Vercel | `./scripts/build_web_admin.sh /` | `https://….vercel.app/homePage` |
| Firebase Hosting | `./scripts/build_web_admin.sh /admin/` | `https://….web.app/admin/homePage` |

Root Directory في Vercel: `admin/Admi`  
Build: `bash scripts/vercel_build.sh`  
Output: `build/web`

---

## النشر على Firebase Hosting

المشروع مضبوط على Firebase project: `tutorial-multi-language-70gx4j`

```bash
cd admin/Admi
./scripts/build_web_admin.sh /admin/

# من مجلد firebase (حيث firebase.json)
cd firebase
firebase login
firebase deploy --only hosting
```

بعد النشر:

- `https://tutorial-multi-language-70gx4j.web.app/admin/`
- أو نطاقك المخصص: `https://admin.example.com/admin/`

### ربط نطاق مخصص

1. Firebase Console → Hosting → Add custom domain  
2. أضف مثلاً `admin.example.com`  
3. ابنِ بـ `./scripts/build_web_admin.sh /` إن أردت الجذر بدون `/admin/`، أو أبقِ `/admin/` كما هو.

---

## النشر على أي استضافة (Nginx / Apache / CDN)

ارفع محتويات `build/web_hosting/` إلى جذر السيرفر.

### Nginx (مثال لمسار `/admin/`)

```nginx
server {
  listen 80;
  server_name admin.example.com;
  root /var/www/toury-admin;
  index index.html;

  location /admin/ {
    try_files $uri $uri/ /admin/index.html;
  }

  location = / {
    return 302 /admin/;
  }

  # كاش الأصول المُجزّأة
  location ~* ^/admin/.+\.(js|css|wasm|woff2|png|jpg)$ {
    expires 30d;
    add_header Cache-Control "public";
  }
}
```

مهم: لأن التطبيق يستخدم **Path URL Strategy**، أي مسار عميق مثل `/admin/home22Dashboard` يجب أن يُعاد كتابته إلى `index.html` (rewrite أعلاه).

---

## المسارات (Routing)

- محرك التوجيه: GoRouter + `usePathUrlStrategy()`
- حماية الدخول والصلاحيات: `admin_route_guard.dart`
- أمثلة مسارات بعد `/admin/`:
  - `homePage` — تسجيل الدخول
  - `home22Dashboard` — الرئيسية
  - `adminFinanceHub` — المركز المالي
  - `adminTourGuides` — المرشدون
  - `drever` — المناديب
  - `adminALLhgZ` — الحجوزات

التنقل في الشريط الجانبي يستخدم `goNamed` (استبدال الصفحة بدون تكديس).

---

## التجاوب (Responsive)

- عرض ≥ ~991px: Sidebar ثابت
- أقل من ذلك: Drawer + AppBar
- الجداول تتحول لتخطيط مكدّس على الشاشات الضيقة
- يعمل على كمبيوتر / لابتوب / تابلت / متصفح الجوال

---

## ملاحظات تشغيل

- الإشعارات Push معطّلة على الويب عمدًا (`AdminPushService` يتخطى `kIsWeb`).
- الخرائط تعتمد على مفتاح Google Maps في `web/index.html`.
- لا تفهرس محركات البحث اللوحة (`noindex` في meta).
- تأكد أن حساب الدخول يملك صلاحية لوحة (Super Admin / وكيل / …).
