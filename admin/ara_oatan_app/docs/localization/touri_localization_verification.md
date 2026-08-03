# Touri Localization Verification

**Date:** 2026-07-18  
**Locales:** `ar` / `en` / `ru` / `ky` only

## Prior session work

| Item | Status |
|------|--------|
| Locale set restricted to ar/en/ru/ky | FIXED (prior) |
| `gen-l10n` | FIXED (prior) |
| Status localizer | PARTIAL |
| Glossary | `docs/localization/touri_translation_glossary.md` |

## Status codes → UI

| Code | Localizer | Status |
|------|-----------|--------|
| `pending_driver` | BookingStatusLocalizer | PARTIAL / FIXED path |
| `awaiting_driver` (alias) | → pending | FIXED |
| `driver_assigned` | BookingStatusLocalizer | PARTIAL |
| `driver_arrived` | BookingStatusLocalizer | PARTIAL |
| `trip_in_progress` | BookingStatusLocalizer | PARTIAL |
| `trip_completed` | BookingStatusLocalizer | PARTIAL |
| `cancelled` | BookingStatusLocalizer | PARTIAL |

Payment labels: `TOURY_PAY_CASH` / `TOURY_PAY_NGENIUS` via payment display helpers.

## Tests

| Suite | Path | Status |
|-------|------|--------|
| Localization tests | `test/localization/*` | PARTIAL (prior) |
| Device visual pass all 4 locales | — | OPEN |

## Verification checklist

| # | Check | Status |
|---|-------|--------|
| L1 | App does not expose unsupported locales | Prior FIXED |
| L2 | Raw `status_code` not shown in UI | PARTIAL |
| L3 | Pending after pay shows localized pending | FIXED code; device OPEN |
| L4 | Glossary terms match UI | PARTIAL |

**Verdict:** Localization recovery **PARTIAL** — good enough for internal QA once unit tests pass; full device locale sweep still OPEN.
