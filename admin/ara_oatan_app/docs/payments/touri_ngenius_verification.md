# Touri N-Genius Verification

**Date:** 2026-07-18  
**Function focus:** `ngenius_payments.js` (Cloud Functions)

## Contract after successful pay

| Field | Required value | Status |
|-------|----------------|--------|
| `status_code` | `pending_driver` | FIXED locally |
| `halh_text` | Arabic pending (driver-facing) | FIXED locally |
| `payment_status` | `paid` (expected) | Verify on E2E |
| `halh_order` | Paid (payment enum) | Must not drive “completed” UI |

## Verification matrix

| # | Check | How | Status |
|---|-------|-----|--------|
| N1 | Sandbox checkout completes | Device/emulator + sandbox credentials | OPEN |
| N2 | Firestore order fields match contract | Console / listener after webhook | OPEN |
| N3 | Customer sees pending (cancel available) | UI after pay | OPEN |
| N4 | Bookings list not “completed” | list22 / bookings screen | FIXED code; E2E OPEN |
| N5 | Failed payment → failed status | Decline card in sandbox | OPEN |
| N6 | Functions deployed with fix | Firebase deploy | OPEN |

## Anti-regression

| Bug | Fix | Status |
|-----|-----|--------|
| Wrote `awaiting_driver` | Write `pending_driver` + Arabic pending; client alias | FIXED local |

## Gate

| Track | Requirement |
|-------|-------------|
| Closed testing | N1–N4 pass on sandbox |
| Store | Live keys + same checks + redeploy confirmed |

**Session verdict:** N-Genius sandbox E2E **not run** → payment verification **OPEN**.
