# 03 — Recovered Features

**Date:** 2026-07-18  
**Meaning:** Behavior restored or corrected in this recovery session (local code). **Not redeployed** to Firebase Functions/Rules this session.

## Recovered / corrected

| # | Feature | Failure mode | Recovery | Status |
|---|---------|--------------|----------|--------|
| 1 | Post-payment pending state | CF wrote `awaiting_driver`; client expected Arabic pending / `pending_driver` | CF: `status_code=pending_driver` + Arabic `halh_text`; localizer alias `awaiting_driver` | FIXED |
| 2 | Cancel UI / `isPending` | Pending detection missed CF status | Cancel paths use `isPending` | FIXED |
| 3 | Auto-cancel | Queries missed `status_code` | Auto-cancel queries `status_code` too | FIXED |
| 4 | Bookings list | `halh_order` Paid treated as trip completed | `list22` no longer maps Paid → completed | FIXED |
| 5 | Cash book-now | Unset payment coerced to cash | Explicit cash only; `touryEnsureCashPaymentIfUnset` no-op | FIXED |
| 6 | Status display (locales) | Raw / mismatched codes | Status localizer + aliases (partial) | PARTIAL |

## Not recovered (cannot prove / still open)

| Item | Reason | Status |
|------|--------|--------|
| Historically deleted UI features | No git history on this clone | OPEN |
| N-Genius live/sandbox E2E path | Not executed | OPEN |
| Driver Firebase package alignment | `google-services.json` still customer package | OPEN |
| Deployed CF/Rules parity | Local fixes only | OPEN |

## Tests supporting recovery

| Test | Path |
|------|------|
| Booking status / payment regression | `admin/ara_oatan_app/test/regression/booking_status_payment_regression_test.dart` |
| Localization (prior session) | `admin/ara_oatan_app/test/localization/*` |
