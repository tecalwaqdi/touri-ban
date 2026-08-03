# 02 — Feature Inventory

**Date:** 2026-07-18  
**App:** Customer — `admin/ara_oatan_app` (Touri Taxi)  
**Related:** Driver `admin/mndob-main`, Admin `admin/Admi`

## Shared backend

| Item | Value |
|------|-------|
| Firebase project | `tutorial-multi-language-70gx4j` |
| Shared collection | `order` |
| Payment provider | N-Genius (online) + cash |

## Customer features

| Area | Capability | Notes | Status |
|------|------------|-------|--------|
| Auth | Sign-in / session | FlutterFlow-era stack | Present |
| Booking | Draft → payment → pending driver | `status_code` canonical | FIXED contracts |
| Payment | N-Genius online | Sandbox E2E not verified this session | OPEN verify |
| Payment | Cash book-now | Explicit cash only (no unset→cash) | FIXED |
| Bookings list | Active / history | Must not treat `halh_order` Paid as completed | FIXED |
| Cancel | Pending cancel + auto-cancel | Uses `isPending` + `status_code` queries | FIXED |
| Maps / routes | Pickup, destination, stops, route preview | See maps verification doc | PARTIAL |
| Localization | `ar` / `en` / `ru` / `ky` | Status localizer partial | PARTIAL |
| Account | Profile / account screens | Present | Present |

## Driver features (`admin/mndob-main`)

| Area | Capability | Notes | Status |
|------|------------|-------|--------|
| Order intake | Reads `halh_text` (legacy Arabic) + statuses | Must align with CF writes | FIXED write side |
| Trip lifecycle | Assigned → arrived → in progress → completed | Shared `order` docs | Present |
| Firebase config | `google-services.json` | Package mismatch vs `applicationId` | **OPEN CRITICAL** |

## Admin (`admin/Admi`)

| Area | Notes | Status |
|------|-------|--------|
| Panel | Same Firebase project | Production YES |
| Order oversight | Relies on shared `order` fields | Present |

## Non-production trees

| Path | Role | Status |
|------|------|--------|
| `mndob-main` (repo root) | Older driver duplicate `v2.0.0+6` | ARCHIVE — do not ship |
| `arawatan/` | Redirect only | ARCHIVE |

## Explicitly not proven this session

- Deleted-feature recovery via git (no commits)
- Full device E2E
- Store-ready release builds
