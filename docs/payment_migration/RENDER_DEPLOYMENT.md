# Render deployment — Touri Payment API

Express + TypeScript service under `admin/services/payment-api`.

## Do not skip

- Do **not** put real secrets in git.
- Do **not** set `NGENIUS_ENV=production` until explicit approval.
- Do **not** create a new Firebase project or migrate Firestore data.
- Do **not** deploy this service until the product owner approves.

## Create the Render service

1. New **Web Service** on Render.
2. Connect the monorepo Git repo.
3. Settings:
   - **Root Directory:** `admin/services/payment-api`
   - **Runtime:** Node
   - **Build Command:** `npm ci && npm run build`
   - **Start Command:** `npm start`
   - **Instance:** free/starter is fine for sandbox smoke tests
4. Render sets `PORT` automatically; the app reads `process.env.PORT`.

## Environment variables

Copy names from `admin/services/payment-api/.env.example`. Minimum for sandbox:

| Variable | Notes |
|----------|--------|
| `NGENIUS_ENV` | `sandbox` until approved for production |
| `NGENIUS_API_KEY` | N-Genius API key (Basic auth material) |
| `NGENIUS_OUTLET_REF` | Outlet reference |
| `NGENIUS_WEBHOOK_SECRET` | Shared secret for webhook header |
| `NGENIUS_WEBHOOK_HEADER` | Default `x-toury-webhook-token` |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Preferred: base64 of **existing** project service-account JSON |
| or `FIREBASE_PROJECT_ID` + `FIREBASE_CLIENT_EMAIL` + `FIREBASE_PRIVATE_KEY` | Same existing project |
| `NGENIUS_SANDBOX_BASE_URL` | Arabia/`NIARABIA`: `https://api-gateway.sandbox.ksa.ngenius-payments.com`. If unset and realm is `NIARABIA`, the service defaults to this host. |
| `NGENIUS_PRODUCTION_BASE_URL` | Default `https://api-gateway.ksa.ngenius-payments.com` (keep `NGENIUS_ENV=sandbox` until approved) |
| `NGENIUS_REALM` | Use the realm from the portal (`NIARABIA` when issued). Generic docs: sandbox `ni`, production `networkinternational` |
| `PAYMENT_RETURN_BASE_URL` | 3DS / hosted-page return URL |
| `PAYMENT_CANCEL_BASE_URL` | Cancel URL (optional; defaults to return) |
| `ALLOWED_APP_ORIGINS` | Comma-separated CORS origins (optional) |
| `SERVICE_VERSION` | Optional, e.g. `0.2.0` |

Encode service account locally (do not commit the JSON):

```bash
base64 -i serviceAccount.json | tr -d '\n'
```

## After first deploy (still sandbox)

1. Note public URL, e.g. `https://touri-payment-api.onrender.com`.
2. Configure N-Genius sandbox webhook:
   - URL: `https://<render-host>/webhooks/ngenius`
   - Header: `x-toury-webhook-token` = `NGENIUS_WEBHOOK_SECRET`
3. Smoke: `GET https://<render-host>/health` → `ok: true`, configured booleans only (no secrets).
4. Point Flutter sandbox builds:

```bash
--dart-define=ENABLE_ONLINE_PAYMENT=true
--dart-define=PAYMENT_BACKEND=external_api
--dart-define=PAYMENT_API_BASE_URL=https://<render-host>
```

Cash remains available; online is gated by `ENABLE_ONLINE_PAYMENT`.

## Promote production

Only after explicit approval:

1. Set `NGENIUS_ENV=production` and production N-Genius credentials.
2. Point webhook + return URLs to production outlet settings.
3. Rebuild Flutter release with the production Render URL.

## Rollback

1. Flutter: omit online flags or set `PAYMENT_BACKEND=cash_only` / `firebase_functions`.
2. Pause or clear the Render service if needed.
3. Keep existing Firebase Functions; do not delete them as part of this cutover.
