# Payment Migration — Status Report

**Branch:** `feature/vercel-ngenius-payment-backend`  
**Final status:** `READY_FOR_SANDBOX_CONFIGURATION`

## 1. Executive Summary

Audited the live payment architecture: Checkout66 is the active checkout; N-Genius runs via Firebase Cloud Functions; default builds are **cash-only**. Implemented a new standalone Next.js payment API under `services/payment-api` for Vercel (sandbox by default), with Firebase ID token auth, server-side booking pricing, idempotent session create, status machine, webhook → single booking creation, cancel, and admin-gated refund scaffold. Flutter gained `PAYMENT_BACKEND` / `PAYMENT_API_BASE_URL` flags and `PaymentApiClient`. Existing Firebase payment functions were **not** deleted or deployed against.

## 2. Active Flow Confirmed

| Flow | Files / routes |
|------|----------------|
| Card checkout | `checkout66_widget.dart` → `touryExecuteCardPayment` → CF or Vercel |
| Cash checkout | `toury_booking_service.dart` / `createCashBooking` (independent of Vercel) |
| Payment confirm | `/paymentConfirm` `payment_confirm_widget.dart` |
| Booking (card) | CF `finalizeNGeniusBooking` **or** Vercel webhook `createBookingFromPaidSession` |
| Driver visibility | Orders only after paid finalize / cash create |
| Admin visibility | Booking details payment labels (refund UI still absent) |

## 3. Files Changed (high level)

| Path | Reason | Risk |
|------|--------|------|
| `docs/payment_migration/*` | Audit + deploy/QA docs | Low |
| `services/payment-api/**` | New Vercel backend | Medium |
| `admin/ara_oatan_app/lib/core/toury_payment_flags.dart` | Backend mode flags | Low |
| `admin/ara_oatan_app/lib/core/payments/payment_api_client.dart` | HTTP client | Medium |
| `admin/ara_oatan_app/lib/core/toury_payment_flow.dart` | Route card create to Vercel when flagged | Medium |

## 4. Firestore

- Reuses `payment_sessions`, `webhook_events`, `order`.
- Additive fields: `backend_source`, `environment`, `normalized_status`, `amount_minor`, `booking_created`, `booking_id`, …
- **No rules deployed.** Rules already deny client writes to payment collections.

## 5. Environment Variables

See `services/payment-api/.env.example` (names only). Configure in Vercel project settings.

## 6. Tests

```bash
cd services/payment-api
npm ci
npm test          # 10 passed
npm run typecheck # passed
npm run build     # passed
```

Flutter full suites: **not fully re-run** in this phase (document as deferred / environment-dependent).

## 7. Remaining Manual Steps

1. Connect Vercel account; set root `services/payment-api`.
2. Enter sandbox secrets (N-Genius + Firebase Admin).
3. Configure webhook URL + return/cancel URLs.
4. Device sandbox QA (see `MANUAL_PAYMENT_QA.md`).
5. Production approval before `NGENIUS_ENV=production`.

## 8. Blockers

- No N-Genius sandbox credentials in this environment.
- No Vercel project linked.
- Device E2E not performed.
- Wallet/extra_hours still on Firebase path (Vercel create rejects non-booking purposes by design in this phase).
- Refund gateway execution returns configuration-pending until sandbox credentials + gateway refund link port are completed.
- Webhook auto-booking creates a **shell** order; full trip payload finalize compatibility with existing PaymentConfirm path needs sandbox validation.

## 9. Rollback

```bash
# Flutter builds
--dart-define=PAYMENT_BACKEND=firebase_functions
# or omit PAYMENT_BACKEND; keep ENABLE_ONLINE_PAYMENT as today
```

Keep Firebase Functions. Pause Vercel deployment if needed.

## 10. Final Status

**`READY_FOR_SANDBOX_CONFIGURATION`**

Acceptance gates checklist: audit ✅ · backend scaffold ✅ · token auth ✅ · no Flutter secrets ✅ · server pricing ✅ · idempotent create ✅ · webhook scaffolding ✅ · cash untouched ✅ · backend test/typecheck/build ✅ · sandbox E2E ❌ · production ❌ · Firebase deploy not performed ✅
