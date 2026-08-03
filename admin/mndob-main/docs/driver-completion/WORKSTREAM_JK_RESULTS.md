# WORKSTREAM J / K RESULTS — Customer + Admin sync

**Date:** 2026-07-28  
**Deploy:** None  
**Device QA:** TBD

## J — Customer

- Aliases in `TouryBookingStatusCodes` / `BookingStatusLocalizer`:
  - `trip_started` → `trip_in_progress`
  - `driver_arriving` → `driver_assigned`
- Existing `completed` → `trip_completed` retained

## K — Admin

- Extended slim `TourySystemStatusCodes` (`driver_arriving`, cancel variants, `expired`, `awaiting_driver`)
- `AdminBookingStatusLabel` includes `driver_arriving`
- `requestChangesPatch` sets `operational_status: offline` (mirror driver compat)

## Deferred

- Admin UI read-back for `requested_changes` list
- Full rename customer class to TourySystemStatusCodes

## Gate

**Not Production Ready** — Device QA + Deploy pending.
