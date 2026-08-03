# NOT_FOUND root cause report

## Symptom

Cash and card payments show `NOT_FOUND` (or Firebase `not-found`) after tapping Book / Pay.

## Root cause

| Layer | Finding |
|-------|---------|
| Client callable | `makeCloudCall('createCashBooking' \| 'createNGeniusPayment', …)` region `us-central1` |
| Source exports | Present in `firebase/functions/index.js` → `ngenius_payments.js` |
| **Deployed project** | Payment functions **absent**. Live list: FCM, Braintree, chat triggers, `api`, `ffPrivateApiCall*` only |
| Deploy failure | Cloud Billing not enabled on `tutorial-multi-language-70gx4j` → Functions upload 403 + Secret Manager 403 |

This is **not** a Flutter route miss and **not** a display-only issue.

## Fix applied

1. **User-facing:** `ErrorLocalizer` maps `not-found` → translated `error_payment_function_unavailable` (never raw `NOT_FOUND`).
2. **Cash functional:** Firestore Rules allow constrained client cash create; `touryCreateCashBookingFromCurrentState` falls back when CF missing — **creates real `order` docs**.
3. **Card / N-Genius:** Still requires billing + CF deploy + outlet secrets (see `manual_external_requirements.md`).
4. CF source ready: secrets optional via `TOURY_USE_SM_SECRETS`, App Check default off until rolled out.

## How to verify cash

1. Install build from `ara_oatan_app`.
2. Authenticate.
3. Complete checkout → payment method Cash → Book now.
4. Expect success navigation; Firestore `order` document with `payment_status=cash_pending`.
5. Doc id = `sha256(uid + ":cash:" + idempotencyKey)`.

## How to verify card (after billing + deploy)

1. Deploy payment functions.
2. Configure Sandbox outlet + API key.
3. Choose Network payment → Hosted page → finalize → booking created only after server verify.

## Files

- `lib/core/toury_booking_service.dart`
- `lib/backend/cloud_functions/cloud_functions.dart`
- `lib/core/toury_error_localizer.dart`
- `firebase/firestore.rules`
- `firebase/functions/ngenius_payments.js`
