# PERFORMANCE AUDIT — Workstream N

**Date:** 2026-07-28  
**App:** mndob-main  
**Method:** Static code review + targeted fixes (no device profiling in this session)

## Findings

| ID | Severity | Location | Issue | Fix status |
|----|----------|----------|-------|------------|
| N1 | High | `main.dart` | `userStream` / `jwtTokenStream` listen without cancel | **Fixed** — subscriptions cancelled in dispose |
| N2 | Med | `driver_new_order_listener.dart` | post-frame sync every Auth rebuild | **Mitigated** — ready-state dedupe before attach |
| N3 | Med | `home_widget.dart` | Nested settings StreamBuilder + count Futures in build | Documented; cache deferred (large FF file) |
| N4 | Med | `tfasel_orser_widget.dart` | Nested Order StreamBuilder | Documented; defer full FF rewrite |
| N5 | Med | `driver_home_map_panel.dart` | Route sync side-effect in build path | Documented |
| N6 | Low | Location | Triple trackers (idle timer + BG geo + Geolocator) | Deferred E2; rates 8s/20s kept |
| N7 | Info | Diagnostics | `DriverRuntimeDiagnostics` debug-only | **Added** |

## Implemented this pass

- Cancel auth/JWT stream subscriptions in `MyAppState.dispose`
- Offline queue + lifecycle coordinator avoid duplicate recovery (`_recovering` lock)
- Order listener attach dedupe via `_lastReady`
- Idle location timer always cancelled before restart (`startIdleSync` → `stopIdleSync`)

## Diagnostics (debug)

- active location sync flag
- current order path
- lifecycle / connectivity notes (no secrets)

## Not done (needs Device Profiler)

- Frame build times on low-end Android
- Memory leak soak test with maps
- Firestore read cost under Online+Trip

## Gate

Performance hardening **partial**. Device profiler TBD. Not Production Ready.
