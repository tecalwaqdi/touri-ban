# Firebase deploy — Payment API (`paymentApi`)

Scaffold only. **Do not auto-deploy production.** Keep Render as the rollback path until cutover is approved.

Codebase source: `admin/services/payment-api` (registered in `admin/ara_oatan_app/firebase/firebase.json` as codebase `payment-api`).

## Secrets (no values in git)

```bash
cd admin/ara_oatan_app/firebase

firebase functions:secrets:set NGENIUS_API_KEY
firebase functions:secrets:set NGENIUS_OUTLET_REF
firebase functions:secrets:set NGENIUS_WEBHOOK_SECRET
```

## Non-secret env

Set in Cloud Console / Functions env (examples — use your real sandbox/prod values as appropriate):

- `NGENIUS_ENV`
- `NGENIUS_REALM`
- `NGENIUS_SANDBOX_BASE_URL`
- `NGENIUS_PRODUCTION_BASE_URL`
- `NGENIUS_WEBHOOK_HEADER`
- `PAYMENT_RETURN_BASE_URL`
- `PAYMENT_CANCEL_BASE_URL`
- `SERVICE_VERSION`

Firebase Admin uses Application Default Credentials on Functions (no `SERVICE_ACCOUNT_BASE64` required).

## Build + deploy (manual)

```bash
cd admin/services/payment-api
npm ci
npm run build

cd ../../ara_oatan_app/firebase
firebase deploy --only functions:payment-api
# or a single function:
# firebase deploy --only functions:payment-api:paymentApi
```

## Expected URL

```
https://us-central1-<PROJECT_ID>.cloudfunctions.net/paymentApi
```

Health: `GET …/paymentApi/health`  
Webhook path: `POST …/paymentApi/webhooks/ngenius`

## AUTH / CAPTURE

Current create-order action remains **PURCHASE** (not AUTH).

Do **not** switch to AUTH/CAPTURE/VOID until the production outlet is confirmed to support it.
Fallback for “paid online + no driver within 1h”: mark `refund_pending` and refund via payment-api / finance refund path (idempotent).

## Webhook (manual)

Configure N-Genius portal webhook URL to:

```
https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi/webhooks/ngenius
```

(Only after `paymentApi` is deployed. Keep Render webhook until cutover.)

Header key/value must match `NGENIUS_WEBHOOK_HEADER` / `NGENIUS_WEBHOOK_SECRET`.

## Rollback

Leave Render running. Point Flutter `PAYMENT_API_BASE_URL` (and N-Genius webhook) back to Render if needed. Do not delete Render as part of this scaffolding.
