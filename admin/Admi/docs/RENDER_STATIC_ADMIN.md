# Admin static site on Render

Production URL: `https://touri-ban-1.onrender.com`

## Canonical toolchain (required)

Pinned in `tooling/FLUTTER_PIN.json` — **do not float to latest stable**.

| Item | Value |
|------|--------|
| Flutter | `3.44.8` |
| Dart | `3.12.2` |
| Engine | `0cd610717bde95fd88343c64f81c11ba4e5c0010` |
| Build | `bash scripts/render_build.sh` |

Build flags (must match Firebase except `--base-href`):

```
flutter build web --release --base-href=/ --no-web-resources-cdn --no-wasm-dry-run
```

`--no-web-resources-cdn` ships local CanvasKit (Firebase Safari-proven). CDN CanvasKit on newer engines was implicated in Render Safari/WebKit blank/stuck loaders.

## Required settings

| Setting | Value |
|---------|--------|
| Root Directory | `admin/Admi` |
| Build Command | `bash scripts/render_build.sh` |
| Publish Directory | `build/web` |

## SPA routing (critical)

Flutter Web uses **Path URL Strategy** (`usePathUrlStrategy()`). Direct navigation to routes such as `/adminSettlementDetails` must **rewrite** to `index.html` (preserve client path — never 301 to `/home22Dashboard`).

### Required — Render Dashboard (production proof)

Static Site → **Redirects/Rewrites**:

| Field | Value |
|-------|--------|
| Source | `/*` |
| Destination | `/index.html` |
| Action | **Rewrite** (not 301 redirect) |

### Cache headers

`index.html`, `version.json`, `flutter_bootstrap.js`, `flutter.js`, `flutter_service_worker.js`, `main.dart.js` must not be long-cache immutable (see `render.yaml`). Mixed-generation (new index + old main) is forbidden.

## Firebase Auth

Add `touri-ban-1.onrender.com` to Firebase Authentication → Authorized domains if email/password or OAuth redirects fail after deploy.

## Local SPA test

```bash
cd admin/Admi
bash scripts/render_build.sh
node qa_tools/spa_server.mjs build/web 4193
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:4193/home22Dashboard
# expect 200
```

## Parity check

After deploy, compare live `build_provenance.json` + SHA256 of `main.dart.js` / `flutter_bootstrap.js` between Firebase (`/admin/`) and Render (`/`). Engine revision must match. `main.dart.js` should match when both were produced from the same commit + pin (base-href differs only in `index.html` / provenance `base_href` field).
