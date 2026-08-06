# لوحة التحكم — توري تاكسي (Admin Web)

لوحة إدارة ويب احترافية لمنصة توري تاكسي.

## تشغيل سريع (محلي)

```bash
./scripts/run_web_admin.sh 8080
```

ثم افتح: **http://127.0.0.1:8080/**

## بناء ونشر Production تحت `/admin/`

```bash
./scripts/build_web_admin.sh /admin/
cd firebase && firebase deploy --only hosting
```

الرابط بعد النشر: `https://<project>.web.app/admin/`

دليل كامل: [docs/WEB_DASHBOARD.md](docs/WEB_DASHBOARD.md)
