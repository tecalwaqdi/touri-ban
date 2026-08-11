# Touri Payment API (Express + TypeScript)

Standalone **Node.js / Express** service for **Network International N-Genius** card payments, intended for **Render**.

Firebase (existing project) remains the system of record for Auth, Firestore, Storage, FCM, bookings, and **cash** bookings. This service does **not** migrate data and does **not** create a new Firebase project.

## Endpoints

| Method | Path | Auth |
|--------|------|------|
| GET | `/health` | none |
| POST | `/payments/create` | Firebase ID token (`Authorization: Bearer`) |
| GET | `/payments/status?sessionId=` | Firebase ID token |
| POST | `/webhooks/ngenius` | Shared webhook secret header |

## Safety defaults

- `NGENIUS_ENV=sandbox` unless explicitly set to `production`.
- Never trust client amounts — quotes use Firestore vehicle type + hours.
- Idempotency key → stable `payment_sessions` doc id (no duplicate charges).
- 3-D Secure via N-Genius hosted payment page (`threeDsUrl` / `paymentUrl`).
- Webhook (and status poll when paid) creates the booking **once** in the existing Firestore project.
- Secrets only via environment variables (see `.env.example`).

## Local development

```bash
cd admin/services/payment-api
cp .env.example .env   # fill sandbox values; never commit
npm ci
npm run typecheck
npm test
npm run dev
# listens on PORT (default 3010)
```

## Flutter (customer app) — sandbox card test

Cash stays default until you opt in. Use dart-defines (do **not** hardcode the Render URL in source):

```bash
cd admin/ara_oatan_app
flutter run \
  --dart-define=ENABLE_ONLINE_PAYMENT=true \
  --dart-define=PAYMENT_BACKEND=external_api \
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
```

`PAYMENT_BACKEND=vercel_api` is accepted as a legacy alias of `external_api`.

N-Genius production is **only** controlled by Render `NGENIUS_ENV` — Flutter cannot flip it.
## Deploy (Render)

See [`docs/payment_migration/RENDER_DEPLOYMENT.md`](../../../docs/payment_migration/RENDER_DEPLOYMENT.md).

**Do not deploy until you approve.**
