# Phase 1 — Global Shell Audit

**Base:** `6eff3e0`  
**Branch:** `recovery/admin-phase1-global-shell`  
**Date:** 2026-09-05

## Defects found (pre-fix)

1. **Auth loading chrome mismatch**  
   Boot uses `AdminSplashScreen`; `_AuthLoadingScreen` / `_PanelSessionGate` used a white `CircularProgressIndicator` → shell flash.

2. **Menu hide condition too narrow**  
   `rolePending` required `isRoleResolving && currentUserDocument == null` (AND). Missing-doc or resolving edge cases could still expose menu items briefly.

3. **Double page padding on finance family**  
   `AdminLayoutWidget` default `padContent: true` **and** pages applied `AdminUi.pagePadding` → oversized gutters / whitespace (shell-owned spacing bug).

4. **Wide content column**  
   Max width 1370–1520 encouraged sprawl vs compact enterprise contract.

5. **Incomplete AdminLayout adoption**  
   Proven by matrix (not fixed in Phase 1 — deferred): many CRUD/legacy routes use custom scaffolds. Document only.

## Route → layout matrix (71 GoRouter entries)

| Kind | Count | Notes |
|------|------:|-------|
| STANDARD_SHELL | 34 | Uses `AdminLayoutWidget` |
| VIA_GEO_HUB | 3 | Dol/region/vill → hub (hub uses AdminLayout) |
| CUSTOM_SCAFFOLD | 9 | Own AppBar (forms/details) |
| LEGACY_SCAFFOLD | 5 | Thin/legacy |
| NO_STANDARD_SHELL / thin | ~18 | Forms, profile, activation, etc. |
| AUTH_BOOTSTRAP | 1 | `/` |

### Incomplete AdminLayout (Phase 0 finding proven)

Examples **without** standard shell (defer to screen phases / edit-shell):

- Landmark add/edit, geo CRUD (`AddDolh`, `edetReg`, …)
- `DriverProfile`, `DriverActivation`, `addDrev`
- `AdminBookingDetails`, agent add/edit
- Legacy: `Home`, `home3`, `AdminDriversCopy`, `AdminAgentCopy`

**Not migrated blindly in Phase 1** per contract.

## Sidebar audit

| Item | Finding |
|------|---------|
| Width | 220–280 responsive — OK |
| Desktop inline / mobile drawer | `showAdminInlineSidebar` @ 991 — OK |
| Duplicate menu items | No duplicate destinations in Menu2 sections |
| Active state | `adminCurrentRouteName` — OK pattern |
| Role visibility | `_canShow` + `canAccessRoute` — OK; pending hides items after fix |
| Legacy MenuWidget | Unused — do not revive |
| Logout | Present in sidebar header |

## Header audit

| Item | Finding |
|------|---------|
| Mobile AppBar | Owned by AdminLayout when drawer mode |
| Desktop | No AppBar — page titles in content (intentional) |
| Duplicate header | Avoided when pages don't also add AppBar under AdminLayout |
| Theme toggle | AppBar (mobile) + sidebar |

## Page container audit

| Item | Finding |
|------|---------|
| Double padding | Finance family FIXED (`padContent: false`) |
| List pages | Already `padContent: false` + own padding — OK |
| Max width | Tightened via `AdminShellRules.contentMaxWidth` |
| Scroll | Page-owned — shell does not nest scroll |

## Auth / claims

| Item | Finding |
|------|---------|
| Boot splash | AdminSplashScreen |
| Profile/session wait | Now AdminSplashScreen (unified) |
| Menu flash | Hide nav items while resolving / no user doc |

## Explicit non-changes

- `admin_firestore_list.dart` untouched  
- Hotfix `227602a` not merged  
- No Finance V3 / data / Customer / Driver app changes  
