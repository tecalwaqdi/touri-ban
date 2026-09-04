# Phase 2 — Dashboard Changed Files

**Branch:** `recovery/admin-phase2-dashboard`  
**Base:** `5885660153f8c8c091a8e87674ce0e7f6c09146e`  
**Version bump:** NO (remains `1.0.16+2018`)

## New
- `lib/home22_dashboard/dashboard_presentation.dart`
- `test/home22_dashboard/dashboard_presentation_test.dart`
- `docs/admin_ui_recovery/phase2/*`

## Modified
- `lib/home22_dashboard/home22_dashboard_widget.dart` — compact hero, restrained quick actions, single refresh ownership
- `lib/components/dashboard_stats_section.dart` — compact KPI cards, remove triplicate refresh, canonical Drivers routes, subtitle cleanup
- `lib/components/admin_operational_alerts.dart` — compact loading row

## Not modified
- `dashboard_stats_loader.dart` formulas  
- AdminLayout / Menu2 / global AdminUi tokens  
- `admin_firestore_list.dart`  
- Finance / Drivers list / Customer / Driver apps  
