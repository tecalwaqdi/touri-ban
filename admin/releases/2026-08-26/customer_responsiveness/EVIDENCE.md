# Customer Responsiveness / Idempotency — Evidence (2026-08-26)

## Build
- Version: **9.1.24+37**
- Native N-Genius primary unchanged (`MOBILE_PAYMENT_MODE=sdk`)
- No sandbox / outlet / price / wallet / geo changes

## Root cause (Pay Now double-tap)
```
FILE = lib/order/checkout66/checkout66_widget.dart
HANDLER = _onPayNowPressed
FIRST_AWAIT (before) = touryBlockIfActiveBooking BEFORE setState(_isPaying)
WHEN_LOADING (before) = AFTER await active-booking check
ROOT_CAUSE =
  1) loading lock after first await → second tap enters handler
  2) active-booking gate blocked SAME payment_pending order as "لديك حجز جاري"
```

## Fixes shipped (source)
| Area | Change |
|------|--------|
| ASYNC_GUARD | `TouryAsyncActionGuard` + keys on pay / cash / profile / support / login |
| PAYMENT_UI_STATE | Sync `_isPaying=true` before any await; label `جاري تجهيز الدفع...` |
| BOOKING_IDEMPOTENCY | Same-order resume via `touryIsSameActiveBookingFlow` / `currentOrderId` |
| PAYMENT UX | PaymentConfirm: verifying → pending (bounded poll) → success/fail; lifecycle resume; HPP copy only when `awaitingExternalHpp` |
| PROFILE / SUPPORT / LOGIN | Sync guard + loading before network |
| TESTS | `toury_async_action_guard_test.dart` |

## Automated results
- `flutter analyze` (changed files): 0 issues
- `flutter test`: **185 PASS** (0 fail)
- payment-api: **84 PASS**
- PHYSICAL iPhone: **OFFLINE** (`iPhone (26.6)` listed offline) → `PHYSICAL_DEVICE_REQUIRED`
- Fresh IPA for +37: **NOT BUILT** (blocked on physical/device time; bump done in source)

## Safari watchdog classification
- `TOURI_APP_CRASH = false`
- `EXTERNAL_SAFARI_WATCHDOG_CRASH = true` (simulator MobileSafari)
- Recovery path: resume → status poll → pending/retryable UI (no infinite spinner)

## Owner still required
1. Connect physical iPhone → install 9.1.24+37 → rapid-tap Pay Now proof
2. Deploy payment-api to Render (native SDK session fields) if not already
