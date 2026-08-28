# Admin static site on Render

Production URL: `https://touri-ban-1.onrender.com`

## Required settings

| Setting | Value |
|---------|--------|
| Root Directory | `admin/Admi` |
| Build Command | `flutter pub get && flutter build web --release --base-href=/ --no-wasm-dry-run` |
| Publish Directory | `build/web` |

## SPA routing (critical)

Flutter Web uses **Path URL Strategy** (`usePathUrlStrategy()`). Direct navigation to routes such as `/home22Dashboard` must rewrite to `index.html`.

1. **Preferred:** include `web/_redirects` in the publish output (copied automatically from `web/`):

   ```
   /*    /index.html   200
   ```

2. **Alternative:** Render Dashboard → Static Site → Redirects/Rewrites:
   - Source: `/*`
   - Destination: `/index.html`
   - Action: **Rewrite** (not 301 redirect)

Without this, deep links return **404** while `/` and `/index.html` work.

## Firebase Auth

Add `touri-ban-1.onrender.com` to Firebase Authentication → Authorized domains if email/password or OAuth redirects fail after deploy.

## Local SPA test

```bash
cd admin/Admi
flutter build web --release --base-href=/ --no-wasm-dry-run
node qa_tools/spa_server.mjs build/web 4193
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:4193/home22Dashboard
# expect 200
```
