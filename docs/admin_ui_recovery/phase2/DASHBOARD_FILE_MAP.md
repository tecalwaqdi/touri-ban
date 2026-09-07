# Phase 2 — Dashboard File Map

**Base:** `5885660153f8c8c091a8e87674ce0e7f6c09146e`  
**Canonical route:** `Home22Dashboard` → `/home22Dashboard`

| FILE | PURPOSE | DATA | VISUAL | STATE | USED ELSEWHERE | SAFE TO MODIFY | RISK |
|------|---------|------|--------|-------|----------------|----------------|------|
| `lib/home22_dashboard/home22_dashboard_widget.dart` | Page composition: hero, alerts, quick actions, stats header | none | page chrome | model/menu | Dashboard only | YES | Medium |
| `lib/home22_dashboard/home22_dashboard_model.dart` | FlutterFlow model (Menu2) | none | none | menu model | Dashboard | minimal | Low |
| `lib/home22_dashboard/dashboard_presentation.dart` | Pure helpers (routes, action filter) | none | none | none | tests | YES (new) | Low |
| `lib/components/dashboard_stats_section.dart` | KPI groups + summary strip + loading | `DashboardStats` | cards | load/cache | **Dashboard only** | YES | Medium |
| `lib/backend/dashboard_stats_loader.dart` | Aggregate counts SoT | Firestore aggregates | none | cache/scope | alerts peek, CRUD invalidate | **NO formula changes in P2** | Critical |
| `lib/backend/dashboard_metric_keys.dart` | Unreliable metric keys | keys | none | — | loader/section | NO unless needed | Low |
| `lib/components/admin_operational_alerts.dart` | Attention strip | driver/support/dash peek | strip | local load | Dashboard only | YES (UI/state) | Medium |
| `lib/backend/driver_admin_stats_loader.dart` | Pending/expiry alerts | drivers | — | — | alerts | NO | High |
| `lib/admin/.../admin_support_stats_loader.dart` | Open support counts | support | — | — | alerts | NO | Medium |

## Explicitly frozen / out of scope

- `admin_layout_widget.dart`, `menu2_widget.dart`, `admin_ui.dart` global tokens  
- `admin_firestore_list.dart`  
- Hotfix `227602a`  
- Finance formulas / CF  

## Legacy dashboards (do not promote)

| Route | Status |
|-------|--------|
| `AdminHome` `/adminHome` | Legacy |
| `Home` `/home` | Legacy |
| `home3` `/home3` | Legacy |
