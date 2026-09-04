# Phase 3 — Driver List Changed Files

**Branch:** `recovery/admin-phase3-driver-list`  
**Base:** `fe7fc88e264e86b67e35c44fd5869fdfbe6c1a31`

## Modified

| File | Change |
|------|--------|
| `admin/Admi/lib/components/admin_firestore_list.dart` | Add `adminFirestoreListShouldReset`; stop identity-compare on `countQueryBuilder`; soft explicit refresh keeps rows |
| `admin/Admi/lib/admin/admindrever/admindrever_widget.dart` | Remove empty `safeSetState(() {})` in initState postFrame (stats-only) |

## Added tests

| File | Purpose |
|------|---------|
| `admin/Admi/test/admin_firestore_list_reload_gate_test.dart` | Semantic reload gate unit tests |
| `admin/Admi/test/admin_firestore_list_reload_stability_test.dart` | Source regression: no countQueryBuilder identity; soft refresh; no empty setState |
| `admin/Admi/test/admin_drivers_list_presentation_test.dart` | Extra filter signature + client filter helpers |

## Added docs

`docs/admin_ui_recovery/phase3/*`

## Explicitly NOT changed

- Driver profile / documents drawer content
- Dashboard, Finance, Customers, Geo, Landmarks
- Version / pubspec
- Hotfix branch wholesale merge
- Firebase schema / functions / apps
