# Touri Booking State Machine

**Date:** 2026-07-18  
**Scope:** Trip lifecycle on shared `order` documents

## Trip state machine

```
draft
  → payment
    → pending_driver
      → driver_assigned
        → driver_arrived
          → trip_in_progress
            → trip_completed
            ↘ cancelled (from eligible pending/active states)
```

Terminal: `trip_completed` | `cancelled`

## Payment axis (orthogonal)

```
payment_status: paid | cash_pending | failed | refunded
```

`halh_order` Paid/Cash is a **payment enum**, not a trip state.

## Transitions (expected)

| From | To | Trigger |
|------|-----|---------|
| `draft` | `payment` | Customer starts checkout / pay |
| `payment` | `pending_driver` | N-Genius success **or** explicit cash book-now |
| `pending_driver` | `driver_assigned` | Driver accepts |
| `driver_assigned` | `driver_arrived` | Driver arrives |
| `driver_arrived` | `trip_in_progress` | Trip starts |
| `trip_in_progress` | `trip_completed` | Trip ends |
| `pending_driver` (and other eligible) | `cancelled` | User cancel / auto-cancel |

## Client rules tied to states

| Concern | Rule | Status |
|---------|------|--------|
| Cancel UI | Show when `isPending` (includes `pending_driver`) | FIXED |
| Auto-cancel | Query by `status_code` (and compatible fields) | FIXED |
| Bookings list | Do not mark completed solely because `halh_order` Paid | FIXED |
| Display | Map codes via status localizer; alias `awaiting_driver` | PARTIAL |

## Anti-patterns (fixed)

| Anti-pattern | Status |
|--------------|--------|
| CF writing `awaiting_driver` as live pending | FIXED → `pending_driver` + Arabic `halh_text` |
| Treating unset payment as cash | FIXED |
| Treating Paid as trip_completed | FIXED |

## Status

Machine documented and client/CF alignment **FIXED locally**. Runtime verification on device: **OPEN**.
