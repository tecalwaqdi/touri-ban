# Touri Data Contracts

**Date:** 2026-07-18  
**Collection:** Firestore `order` (shared by customer, driver, admin)  
**Project:** `tutorial-multi-language-70gx4j`

## Field contract

| Field | Owner / writer | Canonical meaning | Consumer notes |
|-------|----------------|-------------------|----------------|
| `status_code` | CF + apps | Trip lifecycle (English codes) | **Canonical** for client pending/cancel/list logic |
| `halh_text` | CF + driver flows | Legacy **Arabic** status text for driver UI | Keep Arabic pending after payment — not `awaiting_driver` |
| `payment_status` | CF / payment paths | Payment outcome | Separate from trip state |
| `PaymentMethod` | Customer book-now | Chosen method | Cash requires **explicit** cash |
| `halh_order` | Payment paths | Paid / Cash **payment enum** | **Not** trip completion |

## Trip `status_code` values

| Code | Meaning |
|------|---------|
| `draft` | Pre-submit / incomplete |
| `payment` | Awaiting / in payment |
| `pending_driver` | Paid or cash-ready; waiting for driver |
| `driver_assigned` | Driver accepted |
| `driver_arrived` | Driver at pickup |
| `trip_in_progress` | Trip started |
| `trip_completed` | Finished |
| `cancelled` | Cancelled |

**Alias (read-only):** `awaiting_driver` → treat as `pending_driver` in localizer (legacy CF bug).

## `payment_status` values

| Value | Meaning |
|-------|---------|
| `paid` | Online payment succeeded |
| `cash_pending` | Cash selected; collect on trip |
| `failed` | Payment failed |
| `refunded` | Refunded |

## `halh_order` (payment enum)

| Value | Meaning | Must not mean |
|-------|---------|---------------|
| Paid | Online paid | Trip completed |
| Cash | Cash booking | Trip completed |

## Invariants

1. After successful N-Genius pay: `status_code=pending_driver` and Arabic pending `halh_text`.
2. Book-now cash only when payment method is explicitly cash — never coerce unset → cash.
3. Bookings list completion uses trip status (`status_code` / localized trip states), not `halh_order` Paid.
4. Cancel / auto-cancel pending detection uses `isPending` + `status_code` (and compatible legacy text).

## Status

| Contract item | Status |
|---------------|--------|
| Documented fields | FIXED (documented) |
| CF write alignment | FIXED locally — **redeploy OPEN** |
| Client readers | FIXED / PARTIAL (localizer) |
