# Phase 3 — Driver List Audit

**Baseline HEAD:** `fe7fc88e264e86b67e35c44fd5869fdfbe6c1a31`  
**Worktree:** `/tmp/admin_phase3_driver_list`  
**Branch:** `recovery/admin-phase3-driver-list`

## 1. Canonical Driver List

- **CANONICAL ROUTE:** `Admindrever` `/drever`
- **LEGACY ROUTES:** `AdminDrivers` `/adminDrivers`; `AdminDriversCopy` `/adminDriversCopy`; `Home3` redirect
- **SOURCE FILE:** `lib/admin/admindrever/admindrever_widget.dart`
- **MODEL:** `AdmindreverModel`
- **DATA SOURCE:** `UserRecord` drivers (`ismndob` / filters via `AdminOpsQueryBuilder`)
- **SHARED:** `AdminFirestoreList`, `AdminLayoutWidget`
- **ROLE ACCESS:** Super Admin + Country Agent (menu)

Routing not changed in Phase 3.

## 2. Runtime baseline (pre-fix, code + local serve)

Observed rebuild chain on Phase 3 baseline **before** edits:

1. Open `/drever` → `AdminFirestoreList` `_start` → skeleton (`INITIAL_LOADING`)
2. Rows paint (`LOADED`)
3. `initState` postFrame: **`safeSetState(() {})`** + `_loadStats()`
4. `_loadStats` → `setState(_statsLoading=true)` → parent rebuild
5. Parent rebuild recreates **new** `countQueryBuilder` / `queryBuilder` lambdas
6. `AdminFirestoreList.didUpdateWidget` compared `oldWidget.countQueryBuilder != widget.countQueryBuilder` (**identity**)
7. `_resetAndLoad()` → `_items.clear()` + `_loading=true` → **skeleton again**
8. Fetch completes → rows reappear (**&lt;1s flicker**)
9. Stats complete → another `setState` → same identity trap risk
10. Builder `_syncTableQaLabel` → another parent `setState` → same risk

Additional triggers: `AdminLayout.updateCallback: () => safeSetState(() {})` (menu), filter/stats retry.

**Hotfix `227602a` evidence only:** same root cause; fix was `adminFirestoreListShouldReset` ignoring closure identity + remove empty `safeSetState`. Re-derived on Phase 3 baseline (not cherry-picked wholesale).

## 3. Flicker root cause (proven)

| Field | Value |
|-------|--------|
| ROOT CAUSE | `AdminFirestoreList.didUpdateWidget` treated `countQueryBuilder` function identity as semantic change |
| TRIGGER | Any parent `setState` while list mounted (stats load, empty post-frame setState, QA label sync, menu callback) |
| BEFORE | loaded → clear → skeleton → loaded |
| AFTER (fix) | parent rebuild with same `reloadKey`/`pageSize`/`query` → **no reset** |

## 4. Rebuild inventory (Driver list tree)

| Mechanism | Location | Effect |
|-----------|----------|--------|
| `safeSetState(() {})` | initState postFrame (**removed**) | Unnecessary full rebuild |
| `setState` stats | `_loadStats` | Rebuilds list props; must not reset |
| `_syncTableQaLabel` → setState | builder → postFrame | Cosmetic QA; must not reset |
| `updateCallback` empty setState | AdminLayout | Menu-driven rebuild; must not reset |
| Filter `onChanged` | Filter bar debounce | Changes `reloadKey` → **intentional** reset |
| `ValueKey(filters\|pageSize\|extra)` | AdminFirestoreList | Recreates State on semantic filter change |
| `EasyDebounce` search | Filter bar | Debounces filter signature updates |
| Stream/Future builders | Not primary on list body | AdminFirestoreList owns futures internally |

## 5. Duplicate list UI (list only)

| Check | Result |
|-------|--------|
| Duplicate status badges on row | No — registration cell + operational cell are distinct axes |
| Duplicate phone/title | No |
| Duplicate filter bars | No — single `AdminDriversFilterBar` |
| Duplicate counters | Summary strip once per list mode; loading skeleton replaces strip during initial list load only |
| Duplicate pagination | Single `AdminListLoadMoreFooter` |
| Dual wide+mobile trees | `AdminUi.useTableLayout` XOR — one active |

Badge API: list uses **`AdminStatusBadgeUnified`** locally. Global badge unification deferred.

## 6. Sorting

Client `sortDriversNewestFirst` on loaded page only. No server sort UI. Not added.

## 7. Scope exclusions honored

Driver profile/drawer content, Finance, Dashboard, Customers, Geo, apps, schema, CF — **unchanged**.
