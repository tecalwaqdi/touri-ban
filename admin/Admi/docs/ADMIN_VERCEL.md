# استضافة لوحة التحكم على Vercel

## مسار URL: Vercel مقابل Firebase

| الاستضافة | `base-href` عند البناء | رابط الدخول المتوقع |
|-----------|------------------------|---------------------|
| **Vercel** (هذا المستند) | `/` | `https://<vercel-domain>/homePage` |
| **Firebase Hosting** | `/admin/` | `https://<project>.web.app/admin/homePage` |

لا تخلط بينهما: بناء Vercel بـ `/admin/` يكسر المسارات على نطاق الجذر، وبناء Firebase بـ `/` يكسر المسارات تحت `/admin/`.

راجع أيضاً `docs/WEB_DASHBOARD.md`.

## حالة النشر (2026-08-06)

| | |
|--|--|
| الحساب | `tecalwaqdi` |
| المشروع | `tecalwaqdis-projects/web` |
| Production | https://web-phi-flax-80.vercel.app |
| Deployment | https://web-67ecy1nyn-tecalwaqdis-projects.vercel.app |
| Inspect | https://vercel.com/tecalwaqdis-projects/web/GjUUMAQXQvFkMmwQrekEX5pn3FZQ |

صفحة الدخول المتوقعة: https://web-phi-flax-80.vercel.app/homePage

### مهم بعد النشر

أضف النطاق في Firebase Console → Authentication → Settings → **Authorized domains**:

- `web-phi-flax-80.vercel.app`

(وأي نطاق مخصص لاحقاً)

## المشروع محلياً

- المسار: `admin/Admi`
- البناء: `./scripts/build_web_admin.sh /` → `build/web`
- النشر السريع (مخرجات جاهزة):

```bash
cd admin/Admi
./scripts/build_web_admin.sh /
cd build/web
npx vercel@latest deploy --prod --yes --archive=tgz
```

> ملاحظة: رفع مجلد `Admi` كاملاً يفشل بعدد الملفات؛ انشر `build/web` فقط أو استخدم `--archive=tgz` مع `.vercelignore`.

## إعداد مشروع جديد من Git (اختياري)

1. New Project → المستودع
2. Root Directory: `admin/Admi`
3. Build: `bash scripts/vercel_build.sh`
4. Output: `build/web`

## تحقق

1. فتح `/homePage` وتسجيل الدخول
2. إضافة دولة/منطقة/مدينة والتأكد من الحقول الجغرافية
3. إضافة وكيل مع دولة
