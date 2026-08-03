# 04 — Full System Audit

**Date:** 2026-07-18  
**Systems:** Customer (`admin/ara_oatan_app`), Driver (`admin/mndob-main`), Admin (`admin/Admi`), Firebase `tutorial-multi-language-70gx4j`

## Executive verdict

| Gate | Result |
|------|--------|
| Internal QA | **READY** at best after unit tests pass |
| Store release | **NOT READY** |
| Closed testing (sandbox payment) | When N-Genius sandbox E2E passes |

## Architecture snapshot

```
Customer app ──┐
Driver app  ───┼── Firestore `order` + Cloud Functions (N-Genius)
Admin panel ───┘
```

Canonical trip codes: `status_code`. Legacy driver Arabic: `halh_text`. Payment enum: `halh_order` / `payment_status` (not trip completion).

## Component audit

| Component | Path | Bundle IDs | Prod? | Audit notes |
|-----------|------|------------|-------|-------------|
| Customer | `admin/ara_oatan_app` | `com.mycompany.araoatanapp` / iOS `…araoatanapp2` | YES | Status/payment regressions fixed locally |
| Driver | `admin/mndob-main` | `com.mycompany.mndob2` / iOS `…mndob3` | YES | **google-services package mismatch** |
| Driver dup | `mndob-main` (root) | same, older `v2.0.0+6` | NO | Archive |
| Admin | `admin/Admi` | `com.mycompany.tutorialmultilanguageapp` | YES | Same Firebase |
| `arawatan/` | redirect | — | ARCHIVE | Ignore for ship |

## Critical findings

| ID | Severity | Finding | Status |
|----|----------|---------|--------|
| R1 | BLOCKER | CF `awaiting_driver` vs client `pending_driver` / Arabic pending | FIXED (local) |
| R2 | CRITICAL | Unset payment treated as cash | FIXED (local) |
| R3 | CRITICAL | Driver `google-services.json` package = customer ID | OPEN |
| R4 | HIGH | Functions/Rules not redeployed | OPEN |
| R5 | HIGH | No sandbox payment E2E this session | OPEN |
| R6 | MED | Localization status coverage partial | PARTIAL |
| R7 | MED | Empty git clone — no history proof | OPEN |

## Contracts (summary)

| Field | Role |
|-------|------|
| `status_code` | Canonical trip state |
| `halh_text` | Legacy Arabic for driver |
| `payment_status` | `paid` \| `cash_pending` \| `failed` \| `refunded` |
| `PaymentMethod` | Method selector |
| `halh_order` | Paid/Cash **payment** enum — not trip completion |

State machine: `draft → payment → pending_driver → driver_assigned → driver_arrived → trip_in_progress → trip_completed | cancelled`

## Deploy / verify checklist (remaining)

1. Redeploy Cloud Functions (and Rules if changed)
2. Fix driver `google-services.json` package_name → `com.mycompany.mndob2`
3. Run N-Genius sandbox E2E
4. Device E2E: customer ↔ driver ↔ admin
5. Confirm `flutter build` release for customer + driver
6. Run regression unit tests; then device integration tests

## Related docs

- `docs/audits/01_regression_analysis.md`
- `docs/architecture/touri_data_contracts.md`
- `docs/architecture/touri_booking_state_machine.md`
- `docs/implementation/touri_full_recovery_report.md`
- `CHANGELOG_FULL_SYSTEM_RECOVERY.md`
