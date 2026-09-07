# Phase 2 — Dashboard Data Contract

**Canonical screen:** `Home22Dashboard`  
**Loader SoT:** `DashboardStats` via Firestore Aggregate Count (`dashboard_stats_loader.dart`)  
**Phase 2 rule:** Do not invent financial formulas. Do not mark failed metrics as reliable zeros.

## Role scope

| Role | Scope key behavior |
|------|-------------------|
| Super Admin | Global aggregates |
| Country Agent | Country-scoped via `AdminRoleService.scopedCountryRef` / lock |
| Partner / Transport | Different homes — not this Dashboard |

## KPI definitions (operational)

| Label (concept) | Field | Definition | Correctness |
|-----------------|-------|------------|-------------|
| Landmarks | `attractions` | Catalog landmark count | CORRECT if reliable |
| Partner landmarks | `partners` | Partner landmark count | CORRECT if reliable |
| Countries | `countries` | `countries` collection count | CORRECT if reliable |
| Regions | `regions` | regions/cities hierarchy count | CORRECT if reliable |
| Cities | `cities` | villages/cities count | CORRECT if reliable |
| App users | `appUsers` | App customers | CORRECT if reliable |
| Agents | `agents` | Country agents | CORRECT if reliable |
| Representatives (all drivers) | `representatives` | `ismndob == true` | CORRECT if reliable |
| Drivers active | `driversActive` | `actev_mndob == true` | CORRECT if reliable |
| Drivers inactive | `driversInactive` | `actev_mndob == false` | CORRECT if reliable |
| Drivers unknown | `driversUnknown` | `actev_mndob` missing | CORRECT if reliable |
| Tour guides | `tourGuides` | Tour guide users | CORRECT if reliable |
| Transport companies | `transportCompanies` | Companies | CORRECT if reliable |
| Bookings total | `bookingsTotal` | Orders total | CORRECT if reliable |
| Active bookings | `activeBookings` | `ALLNOW == true` | CORRECT if reliable |
| Bookings completed/cancelled/expired | lifecycle fields | Status-coded | CORRECT if reliable |
| Support tickets / open | support fields | Support aggregates | CORRECT if reliable |

## Unreliable display rule

If metric key ∈ `unreliableMetrics`: UI shows **غير مؤكد** — never pretend `0` is SoT.

## Financial KPIs on Dashboard

**None displayed as numbers.** Finance appears only as **quick action links** to existing Finance routes (authoritative screens).  
UNSAFE_TO_DISPLAY as Dashboard KPI: revenue / fees / wallets — deferred to Finance phases.

## Attention strip (alerts)

| Metric | Source | Notes |
|--------|--------|-------|
| Pending driver review | `DriverAdminStatsLoader` | Operational |
| Expiring / expired docs | same | Operational |
| Support open | `AdminSupportStatsLoader` | Operational |
| Active bookings | `peekDashboardStats().activeBookings` | May be 0 if dash cache cold |

## Queries

- Dashboard stats: coordinated parallel aggregate loads with scope cache + TTL  
- Alerts: extra driver + support loads (Dashboard-local; do not redesign global repo in P2)  
