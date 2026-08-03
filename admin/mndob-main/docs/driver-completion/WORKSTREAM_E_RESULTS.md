# WORKSTREAM E RESULTS — Location tracking

**Date:** 2026-07-28  
**Deploy:** None  
**Device QA:** TBD

## Delivered

- `DriverLiveLocationService`: reject 0,0 / out-of-range; high accuracy + 12s timeLimit; weak-accuracy log (threshold 500m)
- Idle sync 20s / trip sync 8s; wake scope restores active trip
- `completeTrip` now calls `stopTracking()` (parity with cancel)
- Platform manifests already declare background location strings

## Deferred (E2)

- Unify triple trackers (`track_order_location` BG geo + Geolocator stream + idle timer)
- Always-permission UX before go-online
- Adaptive battery intervals

## Gate

Unit: `driver_live_location_test.dart` + trip service haversine.  
Device background tracking: **TBD**.
