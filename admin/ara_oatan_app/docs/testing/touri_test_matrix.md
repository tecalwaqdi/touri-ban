# Touri Test Matrix

**Date:** 2026-07-18  
**App:** `admin/ara_oatan_app`

## Legend

| Status | Meaning |
|--------|---------|
| FIXED | Covered by code fix + preferably unit test |
| PARTIAL | Partial coverage |
| OPEN | Not verified this session |

## Unit / widget

| ID | Area | Case | Artifact | Status |
|----|------|------|----------|--------|
| U1 | Booking status | `pending_driver` / alias `awaiting_driver` | `test/regression/booking_status_payment_regression_test.dart` | FIXED |
| U2 | Payment | Cash only when explicit; unset not cash | same regression test | FIXED |
| U3 | List | Paid ≠ completed | same / list22 logic | FIXED |
| U4 | Localization | ar/en/ru/ky strings | `test/localization/*` | PARTIAL |

## Integration / device (not run this session)

| ID | Area | Case | Status |
|----|------|------|--------|
| I1 | Payment | N-Genius sandbox pay → `pending_driver` | OPEN |
| I2 | Cancel | Cancel while pending after pay | OPEN |
| I3 | Auto-cancel | Expired pending queried by `status_code` | OPEN |
| I4 | Driver | Accept order after customer pay | OPEN |
| I5 | Trip | Full path to `trip_completed` | OPEN |
| I6 | Admin | Order visible with correct fields | OPEN |
| I7 | Cash | Explicit cash book-now → `cash_pending` / pending driver | OPEN |
| I8 | Locale | Status strings in ar/en/ru/ky on device | OPEN |

## Build

| ID | Case | Status |
|----|------|--------|
| B1 | `flutter test` (unit) | Run before QA handoff |
| B2 | `flutter build apk` / iOS release | OPEN — not confirmed |
| B3 | Driver build with corrected google-services | OPEN |

## Exit criteria

| Gate | Required |
|------|----------|
| Internal QA | Unit green + smoke on one device |
| Closed testing | I1–I3 + sandbox pay pass |
| Store | All OPEN items closed; prod payment; package mismatch fixed |
