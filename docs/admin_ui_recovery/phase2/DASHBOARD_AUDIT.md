# Phase 2 — Dashboard Audit

**Base:** `5885660`  
**Canonical:** `Home22Dashboard` `/home22Dashboard`  
**Layout:** `AdminLayoutWidget` (`padContent: false`)

## Visible / structural problems (pre-fix)

1. Oversized gradient hero + decorative landscape icon (excessive whitespace / visual weight)  
2. Triple refresh affordances (hero sync + stats header + “تحديث الآن”)  
3. Heavy gradient quick-action tiles (minHeight 78, strong shadows)  
4. Heavy gradient KPI cards dominating viewport  
5. Inactive drivers KPI linked to legacy `AdminDrivers`  
6. Several KPI title == subtitle (weak hierarchy)  
7. Alerts loading as sparse spinner card (layout jump)  
8. No Dashboard financial number KPIs (good — links only)

## Block inventory (post-contract)

| Section | Widget | Source | Status |
|---------|--------|--------|--------|
| Hero | `_DashboardHeroBanner` | auth profile | REWORK → compact |
| Alerts | `AdminOperationalAlerts` | driver/support/dash | REWORK → compact load |
| Quick actions | `_DashboardQuickActionsGrid` | role routes | REWORK → restrained |
| Stats header | `AdminPageHeader` | role copy | KEEP (single refresh) |
| Summary strip | `_DashboardSummaryStrip` | DashboardStats | KEEP |
| KPI groups | `_DashboardGroupSection` | DashboardStats | REWORK → compact cards |
| Sync note | `_DashboardSyncNote` | loadedAt | KEEP |

## Loading

Existing loader already paints cache then soft-refreshes with linear progress. Kept. No AdminFirestoreList changes.

## Charts

No separate chart widgets beyond summary strip pills — no decorative charts added.
