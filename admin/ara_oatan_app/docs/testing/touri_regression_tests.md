# Touri Regression Tests

**Date:** 2026-07-18  
**Primary file:** `admin/ara_oatan_app/test/regression/booking_status_payment_regression_test.dart`

## Purpose

Lock contracts that broke cancel UI, pending detection, auto-cancel, bookings list, and cash book-now.

## Cases to keep green

| Case | Assert | Status |
|------|--------|--------|
| Pending codes | `pending_driver` is pending; `awaiting_driver` aliased | FIXED |
| Cancel eligibility | `isPending` true for pending_driver path | FIXED |
| List completion | `halh_order` Paid does **not** imply trip completed | FIXED |
| Cash detection | Unset payment is **not** cash; explicit cash is | FIXED |
| Ensure cash | `touryEnsureCashPaymentIfUnset` is no-op | FIXED |

## Related localization tests (prior session)

| Path | Focus | Status |
|------|-------|--------|
| `test/localization/*` | Locale restriction / string coverage | PARTIAL |

## How to run

```bash
cd admin/ara_oatan_app
flutter test test/regression/booking_status_payment_regression_test.dart
flutter test test/localization
```

## Gaps (not regression-unit covered)

| Gap | Status |
|-----|--------|
| Live N-Genius webhook → Firestore write | OPEN (needs sandbox E2E) |
| Auto-cancel Cloud/query on device | OPEN |
| Driver accept handshake | OPEN |

## Policy

Do not merge payment/status changes without green regression suite above.
