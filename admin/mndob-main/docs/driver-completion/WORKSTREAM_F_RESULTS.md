# WORKSTREAM F RESULTS — FCM + order offers

**Date:** 2026-07-28  
**Deploy:** None (`addFcmToken` CF not deployed)  
**Device QA:** TBD

## Delivered

- `DriverNewOrderListener` gates on `DriverOnlineState.canReceiveOrders` + ready eligibility; reattaches via `AuthUserStreamWidget` after go-online
- `DriverRideRequestSheet`: 30s auto-reject countdown; dynamic currency symbol
- Push handler: localize Open action; alias `tfasel_order` / `tfaselOrser` → `TfaselOrser`; accept `idorder` param

## Deferred

- Device + Console FCM proof (MASTER_BLOCKERS)
- `fcmUnavailable` eligibility reason wired to token presence
- FCM payload → offer sheet (Firestore listener remains primary)

## Gate

**Not Production Ready** — FCM device proof + Deploy pending.
