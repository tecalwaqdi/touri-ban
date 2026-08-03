# WORKSTREAM D RESULTS — Home + Online eligibility

**Date:** 2026-07-28  
**Deploy:** None  
**Device QA:** TBD

## Delivered

- `DriverEligibilityService` reasons: pending / rejected / suspended / blocked / village / docs / vehicle / GPS / permission / active trip / offline
- `DriverOnlineState.goOnline` / `goOffline` write `operational_status`, `is_online`, `last_*_at` (server timestamps); offline blocked during active trip
- Home inactive banner uses `evaluateAccount()` granular messages (not only approved vs go-online)
- Map panel chip already gates via `goOnline` eligibility errors

## Tests

`test/driver_eligibility_service_test.dart` present.

## Deferred

- Async GPS banner via FutureBuilder on Home
- `fcmUnavailable` evaluation when token stream empty
- Device proof of go-online → Ready

## Gate

**Not Production Ready** — Device QA pending; Deploy none.
