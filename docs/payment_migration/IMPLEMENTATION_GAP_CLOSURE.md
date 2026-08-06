# Implementation Gap Closure

**Branch:** `feature/vercel-ngenius-payment-backend`  
**Date:** 2026-08-06  
**Status after this work:** `READY_FOR_SANDBOX_CONFIGURATION`

This document closes the gaps that remained after the initial Vercel payment-api scaffold. No Firebase deploy and no Vercel deploy were performed. No production N-Genius was enabled.

---

## 1. Webhook booking creation (complete)

### Problem
Earlier scaffold could leave a paid session without a production-shaped `order` document (“shell”).

### Resolution
Authoritative builder: `admin/services/payment-api/src/lib/bookings/build-order.ts`

| Source | Role |
|--------|------|
| `parseBookingDraft` | Validates Flutter draft (coords, stops, place paths) |
| `buildPaidOnlineOrderData` | Mirrors CF `finalizeNGeniusBooking` + cash field parity |
| `createBookingFromPaidSession` | Firestore transaction: one `order/{sessionId}` per paid session |

**Stored at create time:** `payment_sessions.booking_draft` so webhook and finalize share the same draft.

**Idempotency guarantees:**
- Order id = session id (same as CF).
- Transaction skips if order exists or `booking_created` / `booking_id` set.
- Webhook + polling/finalize cannot create two bookings.
- Session stores `booking_id`, `booking_created`, `booking_created_at`.

**Field parity with CF finalize / cash (non-exhaustive):**  
`USER`, GeoPoints, `carRev`, `Rev_dolh`, city/village, stops (`listAmakn`), waypoints, hours, `additional_hours`, pricing (`total`, `amount_halalas`, `total_app`, `total_vat`, `ksm`, `SrSAAH`, `total_mndob`, `total_mndob2`), `status_code=pending_driver`, `payment_status=paid`, `PaymentMethod=OnlinePayment`, `ALLNOW`, N-Genius refs, `backend_source=vercel_api`, `pricing_authority=server`.

Destination is represented via stops / waypoints (same as CF — no invented destination field).

Commission / driver net: legacy `total_mndob` / `total_mndob2` + fee fields; admin finance engines continue to derive reporting from these existing schema fields.

---

## 2. Driver visibility

Driver open pool (unchanged): `status_code == pending_driver` AND `ALLNOW == true`.

| Scenario | Visible? |
|----------|----------|
| Pending / failed / cancelled online (session only) | No — no `order` |
| Paid online (webhook/finalize) | Yes |
| Cash `pending_driver` | Yes |
| Duplicate paid webhook | No second order / offer |

Tests: `admin/mndob-main/test/payment_visibility_test.dart`

---

## 3. Wallet & extra-hours — explicit decision

### Wallet top-up

| Question | Answer |
|----------|--------|
| Active in production codepaths? | Yes — customer `toury_wallet_ngenius.dart` + CF `createNGeniusPayment` purpose `wallet` + `finalizeNGeniusWalletTopUp` |
| Which app? | Customer (`ara_oatan_app`) |
| Firebase Function? | `createNGeniusPayment`, `finalizeNGeniusWalletTopUp` in `ngenius_payments.js` |
| Fails if CF undeployable? | **Yes** — wallet top-up still requires Firebase Functions |
| Payment-provider secrets in client? | No — secrets stay in CF / Vercel env |
| Client controls monetary amount? | **No** — server package catalog `settings/wallet_topup_packages` |

**Decision: Keep temporarily on Firebase with documented dependency.**  
Vercel `create` rejects `paymentPurpose=wallet` with `WALLET_EXTRA_HOURS_USE_FIREBASE_BACKEND`.  
Do **not** migrate wallet in this wave. When migrating later: server-defined packages only on Vercel.

### Extra hours (in-trip card charge)

| Question | Answer |
|----------|--------|
| Active? | Yes — `add_extra_hours2_widget.dart` → purpose `extra_hours` → `finalizeNGeniusExtraHours` |
| Which app? | Customer |
| Firebase Function? | Same create + `finalizeNGeniusExtraHours` |
| Fails if CF undeployable? | **Yes** for card extra-hours |
| Secrets in client? | No |
| Client controls amount? | **No** — server recomputes from order hourly rate × hours |

**Decision: Keep temporarily on Firebase with documented dependency.**  
Same Vercel rejection for `extra_hours`.  
When migrating: move payment create/finalize to Vercel with server quote from the live order document.

Cash booking and booking card checkout are independent of these two flows.

---

## 4. Refund implementation

| Item | Status |
|------|--------|
| Admin/finance auth (`requireFinanceOrAdmin`) | Implemented |
| Session ownership / lookup | Implemented |
| Refundable-state + max remaining | Implemented (`computeRefundable`) |
| Full/partial minor units | Implemented |
| Idempotency (`payment_refunds` doc id) | Implemented |
| N-Genius `cnp:refund` call | Implemented in `refundNGeniusOrder` |
| Booking/session sync | Implemented |
| Without sandbox API key/outlet | Returns **`REFUND_NOT_CONFIGURED`** (503) — does not pretend success |

**Blocker for live refunds:** sandbox N-Genius credentials + outlet must be configured on Vercel. Until then the endpoint is safe but non-operational for provider calls.

Admin UI: finance-only refund control on booking details; never calls N-Genius directly; shows paid / refunded / remaining; server enforces auth.

---

## 5. Payment feature configuration

| Mode | Behavior |
|------|----------|
| `cash_only` / online off | Cash works; no card create |
| `firebase_functions` | Existing CF path (rollback) |
| `vercel_api` | Requires HTTPS `PAYMENT_API_BASE_URL`; release blocks localhost |

Session stores `backend_source`. Only one backend handles each attempt (flag-selected).

Tests: `admin/ara_oatan_app/test/core/payment_flags_test.dart` + payment-api guard tests.

---

## 6. What remains external

- N-Genius sandbox API key, outlet, webhook secret
- Firebase Admin credentials for Vercel
- Vercel project link + deploy (manual)
- Device sandbox QA (not claimed here)

---

## 7. Rollback

```bash
# Customer / admin builds
--dart-define=ENABLE_ONLINE_PAYMENT=true
--dart-define=PAYMENT_BACKEND=firebase_functions
# omit PAYMENT_API_BASE_URL
```

Keep Firebase payment functions. Pause or undeploy Vercel if needed. Cash path never required Vercel.
