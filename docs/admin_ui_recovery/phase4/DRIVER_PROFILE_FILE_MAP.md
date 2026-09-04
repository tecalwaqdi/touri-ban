# Phase 4 — Driver Profile File Map

**Baseline:** `8ec47962426461ec434fc353901d88aa62dc9311`  
**Branch:** `recovery/admin-phase4-driver-profile`

## Canonical identification

| Item | Value |
|------|--------|
| PROFILE ENTRY POINT | Driver List row / actions → `showAdminDriverDetailsDrawer` |
| DRAWER / PAGE | Drawer/sheet: `AdminDriversDetailsPanel`; Full page: `DriverProfileWidget` `/driverProfile` |
| SOURCE FILES | `admin_drivers_details_drawer.dart`, `driver_profile_widget.dart`, `driver_profile_body.dart` |
| MODEL | `DriverProfileModel` (+ row via `AdminDriverRow`) |
| RELATED | `admin_drivers_ui_shared.dart`, `admin_drivers_adapter.dart` |
| DOCUMENT COMPONENTS | `AdminDriverDocumentsPanel`, `driver_license_document.dart`, `admin_driver_profile_view.dart` |
| STATUS COMPONENTS | `AdminDriverStatusStack`, `AdminDriverOperationalStatus`, `AdminDriverLifecycleStrip`, `AdminDriverStatusTruth` |
| ACTIONS | Edit → AddDrev; Review → DriverActivation; Activate/Suspend; Documents sheet |
| DATA SOURCES | `UserRecord` / `user` collection |
| LEGACY | Separate documents bottom sheet from list; `DriverActivation` review body (workflow deferred) |

## File table

| FILE | PURPOSE | DATA | STATE | VISUAL | USED ELSEWHERE | SAFE | RISK |
|------|---------|------|-------|--------|----------------|------|------|
| `admin_drivers_details_drawer.dart` | Canonical quick profile | UserRecord | Stateless | Drawer sections | List opens | YES | Med |
| `driver_profile_body.dart` | Full-page profile | UserRecord | trip future + actionBusy | Sections | DriverProfile route | YES | Med |
| `driver_profile_widget.dart` | Route shell / load | Firestore stream | loading | Scaffold | Route only | Careful | Low |
| `admin_drivers_ui_shared.dart` | Header/StatusStack/KV | Row | Stateless | Shared chrome | List + profile + review | YES (compat props) | Med |
| `admin_driver_documents_panel.dart` | Documents section | ProfileView.documents | Stateless | Doc cards | Drawer, profile, review, list sheet | YES (`showLifecycleStrip`) | Med |
| `admin_driver_lifecycle_strip.dart` | Reg/docs/act chips | lifecycleChips | Stateless | Chip strip | Documents panel | Prefer via prop | Low |
| `admin_driver_profile_view.dart` | Doc slots + labels | User map | Pure | — | Many | Prefer read-only | High if formulas |
| `driver_license_document.dart` | Front/back/legacy rules | Map slots | Pure | — | ProfileView + Driver app models | Prefer no change | Med |
| `driver_registration_document_status.dart` | Completeness helpers | Map | Pure | — | Shared | Prefer no change | Med |
| `admin_driver_expiry_adapter.dart` | Expiry queue adapter | — | — | — | Expiry queue | NO (out of scope) | — |
| `admin_driver_review_actions.dart` | Suspend/approve patches | Writes | — | — | Profile actions | Call only | High |
| `admin_driver_financial_panel.dart` | Earnings panel | Finance read | — | Panel | Profile | NO Finance change | High |

**AdminFirestoreList / Admindrever list behavior: FROZEN — not modified in Phase 4.**
