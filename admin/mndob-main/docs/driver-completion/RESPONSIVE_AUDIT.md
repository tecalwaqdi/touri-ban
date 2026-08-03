# RESPONSIVE AUDIT — Workstream O

**Date:** 2026-07-28  
**Method:** Static + layout helpers (emulator matrix TBD)

## Target matrices (Device QA)

| Width | Text scale | Locale | Mode | Status |
|-------|------------|--------|------|--------|
| 320 | 1.0 / 1.3 / 1.5 | ar RTL | Light | TBD |
| 360–412 | 1.0 | en/ru/ky | Light/Dark | TBD |
| Large | 1.0 | ar | Light | TBD |
| Keyboard open | — | ar | — | TBD |
| Landscape | — | — | — | Not primary; TBD if supported |

## Code notes

- `SafeArea` used on offer sheet / wallet
- `DriverScaledSafeArea` available for new surfaces
- Home stats rows: overflow risk on 320 — Device QA must verify
- Bottom sheets: offer sheet `isScrollControlled` + SafeArea

## Gate

Responsive **not** Device-verified. Documented only where code helpers exist.
