# Firebase cutover — Payment API (`paymentApi`)

Same Express service as Render, hosted on Firebase Functions v2.

**Current production (do not wait on this cutover for store releases):**  
Render `https://touri-ban.onrender.com` — keep client `PAYMENT_API_BASE_URL` pointed here.

**Optional later Firebase URL:**  
`https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi`  
**Rollback:** keep Render until Firebase is verified.

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

Point production webhook to:

```
https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi/webhooks/ngenius
```

Header key/value = `NGENIUS_WEBHOOK_HEADER` / `NGENIUS_WEBHOOK_SECRET` (same as Render).

Keep Render webhook until one successful paid booking on Firebase.

## 6) Flutter

Defaults already target Firebase `paymentApi`. Run with:

```bash
cd admin/ara_oatan_app
flutter run \
  --dart-define=ENABLE_ONLINE_PAYMENT=true \
  --dart-define=PAYMENT_BACKEND=external_api \
  --dart-define=PAYMENT_API_BASE_URL=https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi \
  --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
```

## Rollback

```bash
--dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
```

Restore N-Genius webhook to Render `/webhooks/ngenius`.

## AUTH / CAPTURE

Still **PURCHASE** only. Do not switch to AUTH/CAPTURE until outlet confirms support.
