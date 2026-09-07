# Shared Component Map (Phase 0)

**Scope:** `admin/Admi`  
**Rule for future phases:** Before changing ANY shared component — search usages, list screens, capture behavior, add regression coverage, change, re-test **every** affected screen.

**Code modified this phase:** none

---

## Import frequency (approx, `import '/components/...'`)

| Imports | Component file |
|--------:|----------------|
| 106 | `admin_ui.dart` |
| 38 | `admin_crud_feedback.dart` |
| 37 | `admin_layout_widget.dart` |
| 27 | `menu2_widget.dart` |
| 23 | `admin_enterprise_kit.dart` |
| 20 | `admin_edit_shell.dart` |
| 18 | `admin_image_picker.dart` |
| 17 | `admin_firestore_list.dart` |
| 13 | `admin_confirm_dialog.dart` |
| 12 | `admin_super_admin_gate.dart` |
| 10 | `admin_region_picker.dart` |
| 10 | `admin_status_badge.dart` |
| 8 | `profile_photo_image.dart` |
| 4 | `admin_driver_documents_panel.dart` |

---

## Highest-risk shared components (Top 15)

| # | Component | File | Why high risk |
|--:|-----------|------|---------------|
| 1 | `AdminFirestoreList` | `lib/components/admin_firestore_list.dart` | Used by Drivers, Customers, Bookings, Agents, Landmarks, Support, Notifications, Audit, Companies, Tour Guides, SuperAdmins, Partner/Company lists. **`didUpdateWidget` still compares `countQueryBuilder` by identity on main → reload/skeleton flicker.** |
| 2 | `AdminLayoutWidget` | `lib/components/admin_layout_widget.dart` | Global shell for most panel pages; padding/sidebar breakpoints affect every screen. |
| 3 | `Menu2Widget` | `lib/components/menu2_widget.dart` | Navigation + RBAC visibility; role-pending UI; finance section gates. |
| 4 | `AdminUi` | `lib/components/admin_ui.dart` | Design tokens, cards, spacing, search debounce, loaders — ~96 files touch `AdminUi` / cards. |
| 5 | `AdminDriverDocumentsPanel` | `lib/components/admin_driver_documents_panel.dart` | Drawer + profile; **always renders `AdminDriverLifecycleStrip` on main** → duplicate lifecycle vs header. |
| 6 | `AdminDriverLifecycleStrip` | `lib/components/admin_driver_lifecycle_strip.dart` | Status/lifecycle ownership conflict with `AdminDriverStatusStack`. |
| 7 | `AdminDriverStatusStack` | `lib/admin/admindrever/admin_drivers_ui_shared.dart` | List rows + drawer + profile; duplicate risk when composed with documents strip. |
| 8 | `AdminStatusBadge` / `AdminStatusBadgeUnified` | `admin_enterprise_kit.dart` + `admin_status_badge.dart` | **Two badge systems** coexist. |
| 9 | `AdminOpsFilterBar` / filter bars | `admin_ops_filter_bar.dart` + page-local bars | Filter `reloadKey` coupling to Firestore list. |
| 10 | `AdminFinancialV2Panel` | `admin_financial_v2_panel.dart` | Finance math/presentation shared via Profits host; Finance V3 paused. |
| 11 | `AdminConfirmDialog` / CRUD feedback | `admin_confirm_dialog.dart`, `admin_crud_feedback.dart` | Global list reload notifications. |
| 12 | `AdminGeoHubWidget` | `lib/admin/admin_geo/admin_geo_hub_widget.dart` | Shared by 3 wrapper routes; **direct route not registered**. |
| 13 | `AdminMediaResolver` / profile photo | media + `profile_photo_image.dart` | CORS / Storage errors on local origins. |
| 14 | `AdminEditShell` / `AdminCrudPage` | `admin_edit_shell.dart`, `admin_crud_page.dart` | Shared form chrome for some CRUD. |
| 15 | `AuthUserStreamWidget` + `AppStateNotifier` | nav / auth | Session splash, claims timing, whole-app rebuilds. |

---

## Component catalog

### Shell / chrome

| Component | File | Stateful? | Used by | Data | Visual | Risks |
|-----------|------|-----------|---------|------|--------|-------|
| `AdminLayoutWidget` | `admin_layout_widget.dart` | Stateless | Most panel screens (~38+ widgets) | none | Sidebar/drawer, padding, max width | Inconsistent: many CRUD pages skip it |
| `Menu2Widget` | `menu2_widget.dart` | Stateful (model) | Via AdminLayout | `AdminRoleService` | Sidebar sections | Role pending blank; finance menu complexity |
| `AdminThemeToggle` | `admin_theme_toggle.dart` | Stateful | AppBar / menu | theme | dark/light | — |
| `AdminSuperAdminGate` | `admin_super_admin_gate.dart` | Stateless | gated pages | role | deny chrome | — |

### Lists / tables / filters

| Component | File | Stateful? | Used by | Data | Visual | Risks |
|-----------|------|-----------|---------|------|--------|-------|
| `AdminFirestoreList` | `admin_firestore_list.dart` | **Stateful** | Drivers (`/drever`, `/adminDrivers`), Customers, Bookings, Agents, M3alm, Support, Notifications, Audit, Transport cos, Tour guides, SuperAdmins, Partner bookings, Company drivers | Firestore query + optional live + count | skeleton, pagination, empty/error | **Identity compare of `countQueryBuilder`; ephemeral parent lambdas; whole-list reset** |
| `AdminAgentLandmarkList` | `admin_agent_landmark_list.dart` | Stateful | Landmarks agent views | `mkan` | list | wraps list meta |
| `AdminOpsFilterBar` | `admin_ops_filter_bar.dart` | mixed | ops screens | filter state | chips | reloadKey churn |
| `admin_customers_filter_bar` | `adminuser/...` | — | Customers | filters | bar | local |
| Drivers filter/counters | `admindrever/*`, `admin_driver_counters_strip.dart` | — | Drivers | counts queries | strip | parent setState → list rebuild |

### Driver profile composition

| Component | File | Stateful? | Used by | Data | Visual | Risks |
|-----------|------|-----------|---------|------|--------|-------|
| Details drawer | `admin_drivers_details_drawer.dart` | Stateful | `/drever` | user row | drawer | phone + StatusStack; opens docs panel |
| `AdminDriverDocumentsPanel` | `admin_driver_documents_panel.dart` | Stateless | drawer, profile, review | Storage docs | cards | lifecycle strip always on (main) |
| `driver_profile_body` | `driver_profile_body.dart` | — | `/driverProfile` | profile view | full page | StatusStack + badges extension duplication |
| `AdminDriverFinancialPanel` | `admin_driver_financial_panel.dart` | — | profile/finance | finance | panel | business in UI risk |
| Review body | `driver_registration_review_body.dart` | — | activation | registration | review | — |

### Status / money / cards

| Component | File | Stateful? | Used by | Risks |
|-----------|------|-----------|---------|-------|
| `AdminStatusBadge` (enterprise kit) | `admin_enterprise_kit.dart` | Stateless | Finance, bookings, settlements, notifications | dual badge API |
| `AdminStatusBadgeUnified` | `admin_status_badge.dart` | Stateless | Drivers, support, typecar, fixtures | dual badge API |
| `AdminContentCard` / kit widgets | `admin_ui.dart`, `admin_enterprise_kit.dart` | mixed | widespread | density inconsistency |
| Money formatting | `admin_format.dart` + finance panels | — | finance screens | UI calc duplication |

### Dialogs / feedback

| Component | File | Used by | Risks |
|-----------|------|---------|-------|
| `AdminConfirmDialog` | `admin_confirm_dialog.dart` | CRUD actions | — |
| `admin_crud_feedback` | `admin_crud_feedback.dart` | list reload broadcast | can force multi-list reload |

### Geo / location

| Component | File | Used by | Risks |
|-----------|------|---------|-------|
| `AdminGeoHubWidget` | `admin_geo_hub_widget.dart` | AdminDol/region/vill wrappers | orphan direct route |
| `AdminLocationSection` / pickers | location + region/cache pickers | landmark + geo forms | parent overwrite history (prior commits) |

---

## Usage matrix: `AdminFirestoreList`

Confirmed consumers (import/use):

1. `admindrever_widget.dart` — `/drever` (canonical)
2. `admin_drivers_widget.dart` — `/adminDrivers` (duplicate surface)
3. `adminuser_widget.dart`
4. `admin_a_l_lhg_z_widget.dart`
5. `admin_agent_widget.dart`
6. `admin_m3alm_widget.dart`
7. `admin_suport_widget.dart`
8. `admin_notifications_widget.dart`
9. `admin_audit_log_widget.dart`
10. `admin_super_admins_widget.dart`
11. `admin_transport_companies_widget.dart`
12. `admin_tour_guides_widget.dart`
13. `partner_bookings_widget.dart`
14. `company_drivers_widget.dart`
15. `admin_user_management_system_widget.dart`
16. `admin_agent_landmark_list.dart` (meta / related)

**Any change to reload gating must regression-test all of the above.**

---

## Dual systems to reconcile later (do not change in Phase 0)

1. **Drivers routes:** `/drever` (menu) vs `/adminDrivers` vs `/adminDriversCopy`
2. **Status badges:** `AdminStatusBadge` vs `AdminStatusBadgeUnified`
3. **Driver status ownership:** StatusStack vs LifecycleStrip vs documents header
4. **Geo entry:** three wrappers vs missing `/adminGeoHub` registration
5. **Shell adoption:** AdminLayout pages vs fullscreen FlutterFlow CRUD pages
