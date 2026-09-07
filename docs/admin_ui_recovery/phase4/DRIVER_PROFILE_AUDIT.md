# Phase 4 — Driver Profile Audit

**Baseline HEAD:** `8ec47962426461ec434fc353901d88aa62dc9311`

## Canonical profile

- **ENTRY:** List → `showAdminDriverDetailsDrawer` (wide dialog / mobile sheet)
- **FULL PAGE:** `DriverProfile` `/driverProfile` via “عرض كامل”
- **LEGACY/RELATED:** `DriverActivation` review body (approval workflow deferred); list documents sheet

## Baseline defects (pre-fix)

| Defect | Location | Root |
|--------|----------|------|
| Phone twice | Header + personal KV | Duplicate ownership |
| Registration/account twice | Header StatusStack + “بيانات التسجيل” StatusStack | Duplicate |
| Lifecycle strip + header statuses | DocumentsPanel always mounts LifecycleStrip | Parent already owns reg/act |
| Connection/availability twice | Header StatusStack + OperationalStatus | Overlapping axes |
| Raw `authStatus` enum | DocumentsPanel “حالة النظام: complete” | Raw data guard |
| Active trip twice | OperationalStatus + KV “رحلة نشطة” | Duplicate |
| Full-page name/email/phone twice | Header + personal | Duplicate |
| Full-page StatusStack + OperationalStatus | حالة الحساب | Duplicate stack |

## Hotfix `227602a` comparison

| OLD HOTFIX CHANGE | PHASE 4 NEED | KEEP CONCEPT? | REIMPLEMENT? |
|-------------------|--------------|---------------|--------------|
| Remove phone KV in drawer | YES | YES | YES |
| Remove second StatusStack section | YES | YES | YES |
| `showLifecycleStrip: false` | YES | YES | YES (compat default true) |
| Profile documents strip off | YES | YES | YES |
| Front/back license model | Already on baseline | Keep | No change to model |
| Wholesale Customer/Landmark | NO | DISCARD | — |

## Rebuild / list interaction

Opening/closing drawer must not remount list with skeleton (Phase 3 freeze). Profile changes do not touch `AdminFirestoreList`.

## Status axes (one visual owner)

| Axis | Source | Owner after fix |
|------|--------|-----------------|
| Registration | `registration_status` / truth | Header StatusStack (reg badge) |
| Account activation | `actev_mndob` | Header StatusStack (account badge) |
| Connection / availability | truth map | `AdminDriverOperationalStatus` section |
| Document completeness | authoritative status helper | Documents panel chip only |
| Expiry aggregate | lifecycle chips | Documents panel when strip shown; else per-doc expiry lines |
