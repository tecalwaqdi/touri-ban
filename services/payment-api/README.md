# Touri Payment API (Vercel)

Standalone Next.js App Router backend for **Network International N-Genius** card payments.

Firebase remains the system of record for Auth, Firestore, Storage, FCM, bookings data, and cash bookings (cash does not require this service).

## Endpoints

| Method | Path | Auth |
|--------|------|------|
| GET | `/api/health` | none |
| POST | `/api/payments/create` | Firebase Bearer |
| GET | `/api/payments/status/[sessionId]` | Firebase Bearer |
| POST | `/api/payments/cancel` | Firebase Bearer |
| POST | `/api/payments/refund` | Firebase Bearer + finance/admin |
| POST | `/api/webhooks/ngenius` | Shared webhook secret header |

## Safety defaults

- `NGENIUS_ENV=sandbox` unless explicitly set to `production`.
- Never trust client amounts — booking quotes use Firestore vehicle/country data.
- Webhook creates booking **once** when status becomes `paid` (idempotent).
- Secrets only via environment variables (see `.env.example`).

## Local development

```bash
cd services/payment-api
cp .env.example .env.local   # fill sandbox values locally; never commit
npm ci
npm run typecheck
npm test
npm run dev
```

## Flutter

Pass:

```bash
--dart-define=PAYMENT_BACKEND=vercel_api
--dart-define=PAYMENT_API_BASE_URL=https://YOUR_VERCEL_URL
```

Default remains Firebase Functions / cash-only flags unchanged until you opt in.

## Deploy

See `docs/payment_migration/VERCEL_DEPLOYMENT.md`.
