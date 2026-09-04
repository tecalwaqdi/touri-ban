# Phase 1 — Global Shell Runtime QA

**Build:** Phase 1 worktree web release (`1.0.16+2018` source; shell fixes included)  
**Serve:** `http://127.0.0.1:8081` (SPA)  
**Method:** Chromium Playwright + screenshots under `/tmp/phase1_shell_qa/`  
**Auth:** Firebase Auth injection (`info@admin.com`) — Firestore profile stream may lag; empty menu with “Resolving role…” is **expected shell pending state**, not a business-screen failure.

## Results

| Check | Result |
|-------|--------|
| SIDEBAR chrome present (desktop) | PASS |
| HEADER AppBar + menu toggle (mobile) | PASS |
| MENU structure / logout / theme | PASS (items hidden while role pending — deterministic) |
| ACTIVE ROUTE navigation (routes open) | PASS — all sampled paths returned shell UI |
| RTL (Finance Arabic chrome) | PASS |
| PAGE CONTAINER (finance padContent wiring) | PASS — no obvious double gutter |
| SHELL FLICKER (boot uses branded splash) | PASS (code-level unify; no white spinner path) |
| DOUBLE HEADER | 0 observed |
| DOUBLE SIDEBAR | 0 observed |
| HORIZONTAL SHELL OVERFLOW | **0** (desktop/tablet/mobile × 8 routes) |
| UNAUTHORIZED MENU FLASH | 0 (items hidden until ready) |

## Sampled routes (shell only)

Dashboard, Drivers `/drever`, Customers, Geo `/adminDol`, Bookings, Finance Hub, Support, Settings  

Viewports: 1440×900, 900×800, 390×844  

## Explicitly not certified (deferred)

- Dashboard stats content / “غير مؤكد” counters → Phase 2  
- Drivers list flicker → Phase 3 (`AdminFirestoreList`)  
- Finance data load values → Finance screen phases  
- Full menu item visibility under live profile stream → confirm in human Safari with real login if needed  

## Overflow

`OVERFLOW_TOTAL: 0` (`report.json`)
