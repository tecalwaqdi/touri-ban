# Vercel deployment (sandbox first)

## Do not skip

- Do **not** put real secrets in git.
- Do **not** set `NGENIUS_ENV=production` until explicit approval.
- Do **not** deploy Firebase as part of this migration.

## Steps

1. Create/import a Vercel project linked to this monorepo.
2. Set **Root Directory** to `admin/services/payment-api`.
3. Add environment variables from `admin/services/payment-api/.env.example` (names only in git).
4. Deploy **sandbox** (`NGENIUS_ENV=sandbox`).
5. Note the public URL, e.g. `https://touri-payment-api.vercel.app`.
6. Configure N-Genius sandbox return/cancel URLs and webhook:
   - Return/cancel: `PAYMENT_RETURN_BASE_URL` / `PAYMENT_CANCEL_BASE_URL` (or existing `payment-return.html`)
   - Webhook: `https://<vercel-host>/api/webhooks/ngenius`
   - Header: `x-toury-webhook-token` (or `NGENIUS_WEBHOOK_HEADER`) = `NGENIUS_WEBHOOK_SECRET`
7. Verify `GET https://<vercel-host>/api/health` returns booleans only (no secrets).
8. Point Flutter sandbox builds:
   ```bash
   --dart-define=PAYMENT_BACKEND=vercel_api
   --dart-define=PAYMENT_API_BASE_URL=https://<vercel-host>
   ```
9. Run sandbox E2E card tests (Visa/Mastercard/3DS) on devices.
10. Promote production only after approval + `NGENIUS_ENV=production`.

## Rollback

1. Set Flutter `PAYMENT_BACKEND=firebase_functions` (or omit; default path).
2. Optionally set `PAYMENT_BACKEND=cash_only`.
3. Keep Firebase Functions deployed; do not delete them.
4. Disable Vercel production domain / pause project if needed.

## Firebase Admin credentials on Vercel

Use a **restricted** service account with Firestore + Auth verify access only. Paste `FIREBASE_PRIVATE_KEY` with `\n` escapes in Vercel UI.

## Post-deploy smoke (sandbox)

1. `GET /api/health` — credentials present as booleans only.
2. Authenticated `POST /api/payments/create` with booking draft → payment URL.
3. Simulate or receive webhook with valid secret → one `order` with full trip fields.
4. Repeat webhook → duplicate ignored.
5. Finance `POST /api/payments/refund` — succeeds only with sandbox keys + refundable link; else `REFUND_NOT_CONFIGURED`.

## Gap-closure note

Booking creation after paid is no longer a shell: see `IMPLEMENTATION_GAP_CLOSURE.md`. Wallet/extra-hours stay on Firebase until a dedicated Vercel port.
