# Firebase Payment Backend — Future / Legacy / Rollback only

Same Express service as Render, optionally hosted on Firebase Functions v2.

**Current production Payment Backend:**  
Render `https://touri-ban.onrender.com`  
Customer App defaults: `PAYMENT_BACKEND=external_api` + that URL.

**Firebase `paymentApi`:** Future / Legacy / Rollback only. Do **not** point store
builds here unless explicitly rolling back from Render.

**Optional Firebase URL (rollback):**  
`https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi`

## 1) Login

```bash
firebase login --reauth
```

## 2) Secrets (once — paste same values used on Render)

```bash
cd admin/ara_oatan_app/firebase

firebase functions:secrets:set NGENIUS_API_KEY --project tutorial-multi-language-70gx4j
firebase functions:secrets:set NGENIUS_OUTLET_REF --project tutorial-multi-language-70gx4j
firebase functions:secrets:set NGENIUS_WEBHOOK_SECRET --project tutorial-multi-language-70gx4j
```

## 3) Deploy

Deploy **from** `admin/services/payment-api` (Firebase rejects sources outside the project directory).

```bash
bash admin/services/payment-api/scripts/deploy_firebase.sh
```

Or:

```bash
cd admin/services/payment-api
npm ci && npm run build
firebase deploy --only functions:payment-api --project tutorial-multi-language-70gx4j
```

## 4) Smoke

```bash
curl -sS https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi/health
curl -sS https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi/health/ngenius
```

Expect `ok: true` and `identityStatus: ok` (no secrets in JSON).

## 5) N-Genius webhook (portal)

**Production webhook (Render):**

```
https://touri-ban.onrender.com/webhooks/ngenius
```

Header key/value = `NGENIUS_WEBHOOK_HEADER` / `NGENIUS_WEBHOOK_SECRET`.

Firebase webhook URL is only for an explicit Firebase cutover later:

```
https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi/webhooks/ngenius
```

## 6) Flutter (production = Render)

Defaults already target Render. Explicit defines (matches store scripts):

```bash
cd admin/ara_oatan_app
flutter run \
  --dart-define=ENABLE_ONLINE_PAYMENT=true \
  --dart-define=PAYMENT_BACKEND=external_api \
  --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com \
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true \
  --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
```

## Rollback to Firebase Payment Backend (legacy)

```bash
--dart-define=PAYMENT_BACKEND=firebase_functions
# or keep external_api and point URL at paymentApi:
--dart-define=PAYMENT_BACKEND=external_api \
--dart-define=PAYMENT_API_BASE_URL=https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi
```

Point N-Genius webhook at Firebase only while that rollback is active; restore Render afterward.

## AUTH / CAPTURE

Still **PURCHASE** only. Do not switch to AUTH/CAPTURE until outlet confirms support.
