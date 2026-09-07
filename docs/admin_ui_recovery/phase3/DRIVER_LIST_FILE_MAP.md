# Phase 3 — Driver List File Map

**Baseline:** `fe7fc88e264e86b67e35c44fd5869fdfbe6c1a31`  
**Branch:** `recovery/admin-phase3-driver-list`  
**Canonical route:** `Admindrever` `/drever`

## Canonical identification

| Item | Value |
|------|--------|
| CANONICAL ROUTE | `Admindrever` → `/drever` |
| SOURCE FILE | `lib/admin/admindrever/admindrever_widget.dart` |
| MODEL | `lib/admin/admindrever/admindrever_model.dart` |
| DATA SOURCE | `UserRecord.collection` via `AdminFirestoreList` + `AdminOpsQueryBuilder.applyDriverFilters` |
| SHARED COMPONENTS | `AdminFirestoreList`, `AdminLayoutWidget`, `AdminStatusBadgeUnified` (list-local) |
| ROLE ACCESS | Super Admin + Country Agent (menu SoT `Admindrever`) |
| LEGACY ROUTES | `AdminDrivers` `/adminDrivers`; `AdminDriversCopy` `/adminDriversCopy` → redirects to AdminDrivers; `Home3` → AdminDrivers |
| SIDEBAR | `Menu2` → `AdmindreverWidget.routeName` |
| DASHBOARD | Phase 2 `canonicalDriversRoute = 'Admindrever'` |

## Directly involved files

| FILE | PURPOSE | DATA OWNERSHIP | STATE OWNERSHIP | VISUAL OWNERSHIP | USED BY OTHER SCREENS | SAFE TO MODIFY | RISK |
|------|---------|----------------|-----------------|------------------|----------------------|----------------|------|
| `admindrever_widget.dart` | Canonical Drivers list page | Filters, stats, search hits, pageSize | Parent setState; list via AdminFirestoreList | Page chrome + wiring | No | YES (Phase 3) | Medium — parent rebuilds affect list |
| `admindrever_model.dart` | FF model / Menu2 | — | Menu2Model | — | No | Only if needed | Low |
| `admin_drivers_filter_bar.dart` | Search + filters + page size | Local geo/vehicle caches | Debounced search; filter UI | Filter chrome | No | YES | Medium — debounce |
| `admin_drivers_query.dart` | Extra filters + client filter/sort | Client-side connection/availability/search | Stateless helpers | — | Expiry queue may import helpers | YES | Low |
| `admin_drivers_adapter.dart` | Row VM + labels | Maps `UserRecord` → row | Stateless | Label strings | List + drawer | Careful — drawer imports | Medium |
| `admin_drivers_table.dart` | Wide table / mobile cards | Rows only | Stateless | Row/card layout | No | YES | Low |
| `admin_drivers_summary_strip.dart` | Counter chips | `DriverAdminStats` + page hints | Stateless | Chips | No | YES | Low |
| `admin_drivers_ui_shared.dart` | Badges, avatar, cells | Row-derived | Stateless | Status badges (`AdminStatusBadgeUnified`) | Drawer/profile widgets | List-only edits careful | Medium — shared with drawer |
| `admin_drivers_details_drawer.dart` | Details drawer | User detail | Drawer state | Drawer UI | List opens it | **NO** (Phase 3 exclude profile) | — |
| `admin_firestore_list.dart` | Shared paginated list | Firestore pages + count | Loading/items/pagination | Skeleton/error/footer | **15+ screens** | YES if backward-compatible | **HIGH** |
| `driver_admin_stats_loader.dart` | Aggregate counters | Count aggregates | Async load in parent | — | Possibly other admin | Prefer no formula change | High if formulas touched |
| `admin_ops_filters.dart` / `admin_ops_search.dart` / `admin_ops_query` | Filter signature + search plan | Shared ops | — | — | Many ops screens | Prefer no change | High |
| `admin_unknown_drivers_loader.dart` | Unknown activation panel | Separate scan | Panel state | — | Drivers unknown filter | Only if list bug | Medium |

## AdminFirestoreList call sites (Phase 3 audit)

| Screen | countQueryBuilder | reloadKey | refreshScope |
|--------|-------------------|-----------|--------------|
| **admindrever** (canonical) | YES | YES | representatives |
| admin_a_l_lhg_z (bookings) | YES | YES | YES |
| admin_m3alm (landmarks) | YES | YES | YES |
| adminuser (customers) | NO | YES | YES |
| admin_suport | NO | YES | YES |
| admin_notifications | NO | YES | YES |
| admin_audit_log | NO | YES | NO |
| admin_drivers (legacy) | NO | NO | YES |
| admin_agent | NO | NO | YES |
| admin_super_admins | NO | NO | YES |
| admin_transport_companies | NO | NO | YES |
| admin_tour_guides | NO | NO | NO |
| admin_user_management_system | NO | NO | YES |
| company_drivers | NO | NO | NO |
| partner_bookings | NO | NO | NO |
| admin_agent_landmark_list | Meta types | — | — |

**TOTAL IMPORTS of `admin_firestore_list.dart`:** 17 (16 widgets + shared list component consumers including pagination bar / landmark list).

**Screens that could regress from a bad gate change:** all of the above — especially bookings + landmarks (also use `countQueryBuilder`).
