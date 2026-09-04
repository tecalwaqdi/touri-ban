# TOURi TAXI — Admin UI Forensic Audit (Phase 0)

**Mode:** AUDIT ONLY  
**Primary tree:** `admin/Admi`  
**Date:** 2026-09-04  
**Auditor method:** Source router inventory + component/state/duplicate scans + production version probes + hotfix branch diff review  

**CODE CHANGES:** 0 (documentation only)  
**DATABASE CHANGES:** 0  
**DEPLOYS:** 0  
**COMMITS:** 0  

Hotfix / Finance V3 / Safari freeze / redesign work is **stopped**. Existing branches and commits are **preserved**.

**Non-findings (explicitly excluded):** Local tooling process exits, intentional stop of leftover hotfix local servers, and non-Admin apps. These are **not** product failures, crashes, regressions, P0, or P1.

**Phase 0 status:** COMPLETE (documents below + companion files). Phase 1 not started.

---

## 1. Repository state (recorded, unchanged)

| Item | Value |
|------|-------|
| Working branch (main worktree) | `main` |
| HEAD | `6eff3e061dd58269a9cdef6fbd46c6848342a6d6` |
| HEAD subject | `release(admin): canonicalize Firebase WIP as 1.0.16+2018 Admin source` |
| Tracking | `main...origin/main` |
| Admin pubspec (source) | **`1.0.16+2018`** |
| Dirty worktree | **YES** — large uncommitted set across Admin functions, Customer, Driver (unrelated to this audit). **Do not treat dirty files as production.** |
| Admin-related branches | `hotfix/admin-driver-landmark-ui` (+ origin), `admin-recovery-clean`, `admin-v2`, `feature/touri-admin-maps-traffic-eta` |
| Hotfix worktree | `/tmp/admin_hotfix_6eff3e0` @ `227602a` on `hotfix/admin-driver-landmark-ui` (clean vs origin) |
| Other worktrees | baseline / recovery-clean / admin-v2 (prunable) — left untouched |

### Live production vs source

| Surface | Version | Notes |
|---------|---------|-------|
| **Render** `https://touri-ban-1.onrender.com/version.json` | **`1.0.15+2017`** | LIVE production Admin |
| **Firebase Hosting** `.../admin/version.json` | **`1.0.15+2017`** | LIVE (root redirects to `/admin/`) |
| `firebase/hosting_public/build_provenance.json` (repo artifact) | `1.0.15+2017` @ `358783a` | Matches live; older than main HEAD |
| **Main source pubspec** | **`1.0.16+2018`** | SOURCE ahead of live → **NOT_DEPLOYED** relative to production |
| Hotfix branch pubspec | `1.0.18+2020` @ `227602a` | **HOTFIX_BRANCH_ONLY** — not merged, not production |

**Mandatory rule:** Never cite Render/Firebase UI as evidence of main or hotfix source behavior.

---

## 2. Router inventory

- Router file: `lib/flutter_flow/nav/nav.dart`
- **`FFRoute` count: 71** (including `_initialize`)
- Auth: `globalAuthRedirect` + `requireAuth` on panel routes
- Role: `AdminRoleService.canAccessRoute` + menu-level gates
- Full table: [`SCREEN_INVENTORY.md`](./SCREEN_INVENTORY.md)

### Notable router facts

1. **Canonical Drivers menu target:** `Admindrever` → `/drever`
2. **Parallel Drivers route still registered:** `AdminDrivers` → `/adminDrivers`
3. **Legacy copy routes still registered:** `AdminDriversCopy`, `AdminAgentCopy`
4. **`AdminGeoHub` `/adminGeoHub` has widget + path constants but is NOT in GoRouter** — reached only via `AdminDol` / `Adminregion` / `Adminvill` wrappers
5. Many CRUD routes lack `AdminLayoutWidget` (fullscreen FlutterFlow forms)

---

## 3. Global shell audit (no modifications)

| Area | Finding |
|------|---------|
| Sidebar | `Menu2Widget` inside `AdminLayoutWidget`; gradient teal chrome (`AdminUi.sidebarGradient`) |
| Top bar | AppBar only when sidebar collapses (`showAdminInlineSidebar`); teal brand bar + theme toggle |
| Page scaffold | Constrained content max width (~1370–1520); `AdminUi.pagePadding` |
| Route guards | GoRouter redirect + `canAccessRoute`; finance staff limited; country agent denied global finance + AdminDol/AdminAgent |
| Theme | FlutterFlowTheme + AdminUi brand teal/mint/sage |
| Typography | Theme defaults **`fontFamily: 'cairo'`** via Google Fonts |
| RTL/LTR | Arabic-first UI; technical values often LTR — consistency uneven per screen |
| Breakpoints | Sidebar ~1100+; table layout ≥900; stacked header <520 |
| Cards / buttons / fields | Shared via `AdminUi` / enterprise kit — density varies; many legacy FlutterFlow forms ignore kit |
| Dialogs / drawers | Confirm dialog shared; Drivers + Support use large drawers |
| Tables | Mix of `AdminFirestoreList` + custom DataTable-ish builders |
| Loading | Skeletons in Firestore list; SpinKit; full-page splash “جاري تحميل لوحة التحكم…” on auth bootstrap |
| Empty / error | Present in list component; wording/i18n uneven |

### Shell inconsistencies

- Not all authenticated screens use `AdminLayoutWidget` (~35+ widget files lack it)
- Duplicate entry points for Drivers and Geo
- Role-pending sidebar state can delay navigation clarity
- Local `http://127.0.0.1` Admin can stick on splash / Storage CORS — **SOURCE_ONLY / environment**, not proof of production regression

---

## 4. State management audit

### Patterns observed (approx)

| Pattern | Scale |
|---------|------|
| `setState` | ~90 files / ~471 calls |
| `FutureBuilder` | ~29 files / ~33 |
| `StreamBuilder` | ~19 files / ~25 |
| `AppStateNotifier` / ChangeNotifier-style | nav + app_state (not Riverpod) |
| `ValueNotifier` / form controllers | FlutterFlow form field controllers |
| `addPostFrameCallback` / `Timer` | present across ~51 files with timer/post-frame patterns |
| Provider / Riverpod | **not** primary Admin architecture |

### High-risk pages / mechanisms

| Risk | Where | Detail |
|------|-------|--------|
| Reload loop / flicker | `AdminFirestoreList.didUpdateWidget` **on main** | Still resets when `countQueryBuilder` identity changes — parents recreate lambdas on `setState` |
| Ephemeral lambdas | Drivers list parent, other list hosts | query/count builders recreated each rebuild |
| Whole-page rebuild | list hosts with filter chips | setState on search/filter rebuilds list widget |
| Duplicate loaders | auth splash + page skeleton | sequential loaders feel like “vibration” |
| Multiple listeners | Firestore list live sub + count refresh + role session ready | cancellation via generation counters helps but reset path clears UI |
| Business in UI | finance hubs / panels | CF results + formatting mixed into widgets |
| Direct queries in UI trees | various admin screens | FlutterFlow query patterns remain |

**Do not fix in Phase 0.** Phase 3 is the designated first implementation window for list reload gating (with full shared usage audit).

---

## 5. Duplicate UI audit (exact hotspots)

| Screen / file | Duplication |
|---------------|-------------|
| `admin_drivers_details_drawer.dart` + `admin_driver_documents_panel.dart` | Drawer shows phone + `AdminDriverStatusStack`; documents panel **always** embeds `AdminDriverLifecycleStrip` on main → **duplicate lifecycle/status storytelling** |
| `driver_profile_body.dart` | `AdminDriverStatusStack` plus badge extension helpers — risk of stacked status presentation |
| `/drever` vs `/adminDrivers` | Two full list UIs for drivers |
| `/adminDriversCopy`, `/adminAgentCopy` | Legacy copy trees still routed |
| `AdminStatusBadge` vs `AdminStatusBadgeUnified` | Dual chip systems across finance vs drivers/support |
| Geo: `AdminDol`/`Adminregion`/`Adminvill` vs missing `/adminGeoHub` | Three URLs, one hub widget — mental duplicate |
| Finance: Hub + Profits + Agent Finance + legacy wallets | Overlapping money surfaces (by design debt, not always visual dual-render) |

---

## 6. Visual consistency classification (per domain)

| Domain | Spacing/density | Hierarchy | RTL | Responsive | Loading | Overall |
|--------|-----------------|-----------|-----|------------|---------|---------|
| Shell | Medium | OK | OK | Good | Splash risk | YELLOW |
| Dashboard | Medium | OK | OK | OK | OK | YELLOW |
| Drivers list | Busy chips | Mixed EN/AR labels | OK | Table/card switch | **ORANGE flicker** | ORANGE |
| Driver profile/drawer | Dense | Overloaded status | OK | Drawer width | OK | ORANGE |
| Customers | Similar to drivers | OK | OK | OK | list shared risk | YELLOW |
| Geo hub | Improving | OK | OK | OK | OK | YELLOW |
| Landmarks | Mixed | OK | OK | OK | list | YELLOW |
| Bookings | Dense tables | OK | OK | OK | list | YELLOW |
| Finance family | KPI-heavy | Mixed | OK | OK | CF load states | YELLOW |
| Support/Notifications | Enterprise kit | OK | OK | OK | list | YELLOW |
| Legacy copies | Unknown/outdated | — | — | — | — | RED |

---

## 7. Data / view separation

| Issue | Examples (files) |
|-------|------------------|
| Business values / money formatting in UI | `admin_finance_hub_widget.dart`, `admin_finance_channels_widget.dart` (`formatMoneyAmount`), `admin_reports_hub_widget.dart` (local `_formatMoney` + large inline charts), `admin_settlement_details_widget.dart`, `admin_profits` → `AdminFinancialV2Panel` |
| Adapters mixed with presentation (better than raw, still UI-adjacent) | `admin_bookings_adapter.dart`, `admin_drivers_adapter.dart`, `admin_customers_adapter.dart` — coerce/`toString` of Firestore fields for rows |
| Raw status / enum switches in widgets | `admin_driver_documents_panel.dart` (authStatus switch), driver StatusStack builders, support table badge mappers |
| Firestore query builders in page widgets | All `AdminFirestoreList` hosts (`admindrever_widget`, `adminuser_widget`, `admin_a_l_lhg_z_widget`, `admin_m3alm_widget`, …) pass closures recreated on rebuild |
| Count / filter duplication | Drivers counters strip vs list filters; bookings summary strip vs list query |
| Large “god” screens | `admin_m3alm_widget.dart` (~1841 lines), `admin_reports_hub_widget.dart` (~1581), `adminadd_mkan_copy` (~1471), `AdminAddAgent` (~1674) |

**Positive separation already present (do not regress):** bookings presentation helpers (`admin_bookings_presentation.dart`), some finance CF callables vs pure client math (Finance V3 still paused).

Report only — no refactors in Phase 0.

---

## 8. Screen health matrix (rollup)

| Health | Count | Drivers of classification |
|--------|------:|---------------------------|
| GREEN | 1 | QA fixture route gated |
| YELLOW | 60 | Usable panel screens with polish/consistency / shared-list debt |
| ORANGE | 8 (+1 orphan GeoHub) | Drivers flicker, profile dupes, duplicate Drivers route, auth splash, legacy Home/home3/cite, odd `adminRegesr` RBAC |
| RED | 2 | Routed legacy copy screens (`AdminDriversCopy`, `AdminAgentCopy`) |

**Every GoRouter route** is scored in [`SCREEN_INVENTORY.md`](./SCREEN_INVENTORY.md) (complete matrix).

---

## 9. Recent hotfix review (objective — do not revert yet)

Branch: `origin/hotfix/admin-driver-landmark-ui`  
Commits: `74cd4fa`, `227602a`  
Diff vs `6eff3e0`: 25 files (+Admin Drivers/list/docs + Customer landmark pagination/filter + tests)

| Classification | Items |
|----------------|-------|
| **KEEP** | `AdminFirestoreList` reload gate (drop `countQueryBuilder` identity compare; `adminFirestoreListShouldReset`); documents panel `showLifecycleStrip` ownership; drawer dedupe comments/behavior; `countries_record.driverRequirements` analyzer alignment; focused unit tests for list reload + docs dedupe |
| **REWORK** | Customer `toury_mkan_pagination` / `toury_landmark_filter` — correct problem space but **outside Admin screen-by-screen program**; must not ride an Admin UI merge blindly. Minor finance file touches on branch (`admin_finance_audit`, `admin_reconciliation`) — re-evaluate; Finance V3 remains paused |
| **REVERT_CANDIDATE** | None forced yet — **do not revert**. If Admin-only recovery prefers clean main, Customer landmark commits may be split to a separate branch later |
| **UNRELATED** | QA landmark e2e scripts; pubspec/version bumps for hotfix binary |

**Tests passed ≠ production acceptance.** Human visual gate on hotfix was **incomplete** (Safari splash / automation limits). Do not merge on test green alone.

---

## 10. Production vs source problem tagging

| Problem class | LIVE_PRODUCTION (1.0.15+2017) | SOURCE_ONLY (main 1.0.16+2018) | HOTFIX_BRANCH_ONLY (1.0.18+2020) | NOT_DEPLOYED |
|---------------|-------------------------------|--------------------------------|----------------------------------|--------------|
| Drivers list flicker (`countQueryBuilder`) | Likely **YES** if same list code lineage shipped | **YES** present on main | Mitigated in branch (unverified human gate) | Hotfix fix not live |
| Driver lifecycle/status duplicate | Likely **YES** | **YES** on main | Mitigated in branch | Hotfix fix not live |
| Main `1.0.16+2018` vs live `1.0.15+2017` drift | Live older | Source newer | — | Main source not fully live |
| Customer landmark soft-refresh / Saudi filter | Store apps old | Customer dirty/unrelated on main WT | Fixed on hotfix | Needs Customer app update if kept |
| Local Admin splash / Storage CORS on localhost | N/A | Environment | Environment | — |
| Finance V3 | Paused everywhere | Paused | Paused | — |

---

## 11. P0 / P1 (program risks — not change list)

### P0

- **Confusing live Admin with undeployed source/hotfix** during QA
- **Shared `AdminFirestoreList` reload identity bug** still on main (affects many screens)
- **Merging hotfix wholesale** without screen-by-screen method / without splitting Customer changes

### P1

- Duplicate Drivers routes and legacy copy routes still in router
- Driver drawer/profile duplicate status/lifecycle on main
- `AdminGeoHub` path orphan
- Dual status badge systems
- Incomplete shell adoption on CRUD pages
- Dirty main worktree masking what is actually shipped

### P2

- Known pre-existing finance test failure (`phase_8a_csv_errors_test`) — out of scope; Finance V3 paused
- Visual density inconsistency across enterprise kit vs FlutterFlow forms

**Explicitly not P0/P1:** intentional local server termination / tooling exit codes.

---

## 12. Visual consistency audit (classification only)

| Domain | Spacing | Card density | Font hierarchy | Fields/buttons | Table density | Whitespace | RTL | Breakpoints | Loading | Errors |
|--------|---------|--------------|----------------|----------------|---------------|------------|-----|-------------|---------|--------|
| Shell | OK tokens | n/a | Cairo OK | kit buttons | n/a | OK | OK | Good | Splash ORANGE | uneven |
| Dashboard | Medium | Medium | OK | OK | n/a | Medium | OK | OK | OK | OK |
| Drivers list | Busy | Chip-heavy | Mixed AR/EN labels | OK | Dense | Low | OK | Table≥900 | ORANGE flicker | Arabic errors |
| Driver profile/drawer | Dense | Overloaded | Status overload | Action cluster | n/a | Low | OK | Drawer | OK | OK |
| Customers | Similar drivers | Medium | OK | OK | Dense | Medium | OK | OK | shared list | OK |
| Geo hub | Improving | Compacting | OK | OK | Medium | Medium | OK | OK | OK | OK |
| Landmarks | Mixed | Card+list | OK | Large forms | Medium | High on forms | OK | OK | list | OK |
| Bookings | Dense | Strip+table | OK | OK | Dense | Low | OK | OK | list | OK |
| Finance family | KPI-heavy | Large KPIs | Mixed | OK | Medium | Medium-high | OK | OK | CF spinners | mixed |
| Support/Notif | Kit | Medium | OK | OK | Medium | Medium | OK | OK | list | OK |
| Settings | Busy | Mixed | OK | Many toggles | n/a | Medium | OK | OK | heavy setState | OK |
| Legacy copies | Unknown | — | — | — | — | — | — | — | — | — |

No redesign in Phase 0.

---

## 13. Intended next screen (awaiting approval)

**PHASE 1 — GLOBAL SHELL**  
(`AdminLayoutWidget` / `Menu2Widget` / auth splash contract)  

Do **not** start until user approves.

---

## 14. Phase 0 deliverable checklist

| Deliverable | Status |
|-------------|--------|
| Repository / production / source recording | DONE |
| Full router inventory (71 routes) | DONE |
| Domain screen inventory | DONE |
| Global shell audit | DONE |
| Shared component map | DONE |
| State management audit | DONE |
| Duplicate UI audit | DONE |
| Visual consistency classification | DONE |
| Data/view separation audit | DONE |
| Every-route health matrix | DONE |
| Hotfix KEEP/REWORK/REVERT_CANDIDATE | DONE |
| Production vs source tagging | DONE |
| Execution order | DONE |
| Design contract (for later) | DONE |
| Code / DB / deploy / commit changes | **NONE** |
| Phase 1 started | **NO** |

---

## Related docs

- [`SCREEN_INVENTORY.md`](./SCREEN_INVENTORY.md)
- [`SHARED_COMPONENT_MAP.md`](./SHARED_COMPONENT_MAP.md)
- [`ADMIN_UI_EXECUTION_PLAN.md`](./ADMIN_UI_EXECUTION_PLAN.md)
