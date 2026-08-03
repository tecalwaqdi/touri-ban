# Touri Full Recovery Report

**Date:** 2026-07-18  
**Workspace:** `admin/ara_oatan_app` (+ driver/admin siblings)  
**Git:** No commits on this clone; entire tree untracked

## Goal

Restore correct booking status/payment contracts across customer app, Cloud Functions, and shared Firestore `order` docs; document remaining blockers for QA/store gates.

## What was fixed (this session)

| # | Issue | Fix | Status |
|---|-------|-----|--------|
| 1 | CF `awaiting_driver` broke cancel, pending, auto-cancel, list | `ngenius_payments.js` → `status_code=pending_driver` + Arabic `halh_text`; localizer alias; list22; cancel `isPending`; auto-cancel `status_code` | FIXED (local) |
| 2 | Unset payment → cash | Explicit cash only; `touryEnsureCashPaymentIfUnset` no-op | FIXED |
| 3 | Locales (prior) | Restricted `ar/en/ru/ky`; gen-l10n; status localizer | PARTIAL |

## What was not done

| Item | Status |
|------|--------|
| Redeploy Functions / Rules | OPEN |
| N-Genius sandbox E2E | OPEN |
| Driver `google-services.json` package fix | OPEN |
| Full device E2E | OPEN |
| Release builds confirmed | OPEN |
| Integration tests on device | OPEN |
| Git-based deleted-feature proof | OPEN (impossible here) |

## Tests added

| Suite | Path |
|-------|------|
| Booking status/payment regression | `test/regression/booking_status_payment_regression_test.dart` |
| Localization (prior) | `test/localization/*` |

## Production matrix reminder

| App | Path | Ship? |
|-----|------|-------|
| Customer | `admin/ara_oatan_app` | YES (after gates) |
| Driver | `admin/mndob-main` | YES (after package fix) |
| Driver root dup | `mndob-main` | ARCHIVE |
| Admin | `admin/Admi` | YES |
| `arawatan/` | redirect | ARCHIVE |

## Verdict

| Audience | Gate |
|----------|------|
| Internal QA | Ready **after** unit tests pass |
| Store | **NOT READY** |
| Closed testing | When sandbox payment E2E passes (if payment is sandbox-only) |

## Doc index

| Doc | Path |
|-----|------|
| Regression | `docs/audits/01_regression_analysis.md` |
| Inventory | `docs/audits/02_feature_inventory.md` |
| Recovered | `docs/audits/03_recovered_features.md` |
| Full audit | `docs/audits/04_full_system_audit.md` |
| Contracts | `docs/architecture/touri_data_contracts.md` |
| State machine | `docs/architecture/touri_booking_state_machine.md` |
| Changelog | `CHANGELOG_FULL_SYSTEM_RECOVERY.md` |
