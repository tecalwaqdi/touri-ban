# Phase 1 — Global Shell File Map

**Base:** `6eff3e061dd58269a9cdef6fbd46c6848342a6d6`  
**Branch:** `recovery/admin-phase1-global-shell`  
**Scope:** Admin chrome only (`admin/Admi`)

| FILE | PURPOSE | USED BY | STATE OWNERSHIP | VISUAL OWNERSHIP | CAN CHANGE? | RISK |
|------|---------|---------|-----------------|------------------|-------------|------|
| `lib/main.dart` | App root, locale RTL Directionality, themes via AdminUi | entire Admin | locale/themeMode | Directionality wrapper | YES (RTL/theme wiring only) | Medium — affects all routes |
| `lib/flutter_flow/nav/nav.dart` | GoRouter, auth redirect, panel home, `_AuthLoadingScreen`, `_PanelSessionGate`, `adminCurrentRouteName` | all routes | AppStateNotifier + session gates | splash vs loading vs panel | YES (loading chrome only) | High — auth UX |
| `lib/core/admin_splash_screen.dart` | Branded startup splash | nav loading overlay | animation local | branded teal splash | YES (reuse for auth loading) | Low |
| `lib/components/admin_layout_widget.dart` | Canonical sidebar/drawer + content max width + optional page padding | ~34 STANDARD_SHELL routes | none (stateless) | shell chrome | **YES — primary** | High — all shell pages |
| `lib/components/menu2_widget.dart` | Sidebar nav sections, role visibility, active route, logout | AdminLayout | AuthUserStream + AdminRoleService | sidebar UI | **YES — primary** | High — menu flash |
| `lib/components/menu2_model.dart` | FlutterFlow model for Menu2 | Menu2 | model | none | minimal | Low |
| `lib/components/admin_ui.dart` | Brand tokens, `pagePadding`, themes, cards | ~106 imports | none | density tokens | **YES — tokens only** | High blast radius — keep presentational |
| `lib/components/admin_theme_toggle.dart` | Light/dark toggle | AppBar + Menu2 | theme mode | chrome control | YES if needed | Low |
| `lib/components/admin_edit_shell.dart` | Fullscreen CRUD scaffold (not sidebar) | many forms | loading flag | edit chrome | Document only in P1; avoid broad rewrite | Medium |
| `lib/components/admin_crud_page.dart` | Crud page + AdminLayout | some CRUD | — | shell wrap | Prefer not in P1 | Medium |
| `lib/components/admin_super_admin_gate.dart` | Deny chrome with AdminLayout | gated pages | role | deny UI | No unless shell bug | Low |
| `lib/flutter_flow/flutter_flow_util.dart` | `showAdminInlineSidebar`, breakpoints, `closeDrawerIfOpen` | AdminLayout | MediaQuery | responsive switch | YES (breakpoint only if needed) | Medium |
| `lib/flutter_flow/flutter_flow_theme.dart` | Cairo + theme families | global | theme | typography | Prefer AdminUi themes; avoid page patches | Medium |
| `lib/backend/admin_role_service.dart` | Role/claims for menu visibility | Menu2, guards | RBAC phase | none | **NO business rule changes** — read only for shell | Critical |
| `lib/backend/admin_panel_session.dart` | Scope ready for panel home | `_PanelSessionGate` | session | loading gate | NO business changes | Medium |
| `lib/backend/admin_route_guard.dart` | Route access helpers | nav | — | — | NO | Medium |
| `lib/auth/firebase_auth/auth_util.dart` | `loggedIn`, user streams | shell | auth | — | NO | Critical |
| `lib/components/menu_widget.dart` | **Legacy** menu | unused by current shell | — | — | DO NOT revive | Low |
| `lib/l10n/nav_translations.dart` | Menu labels | Menu2 | — | labels | Only if shell label bug | Low |

## Explicitly out of Phase 1 (do not change)

| FILE | WHY |
|------|-----|
| `lib/components/admin_firestore_list.dart` | Deferred to Phase 3 (Driver/List) |
| All `lib/admin/**` page bodies except shell wiring (`padContent`) | Screen phases |
| Hotfix `227602a` Driver/Landmark/Customer diffs | Preserved, not merged |

## Route → layout summary

See `GLOBAL_SHELL_AUDIT.md` matrix.

| Kind | Count |
|------|------:|
| STANDARD_SHELL (`AdminLayoutWidget`) | 34 |
| VIA_GEO_HUB (wrappers → hub w/ AdminLayout) | 3 |
| CUSTOM_SCAFFOLD (own AppBar) | 9 |
| LEGACY_SCAFFOLD | 5 |
| NO_STANDARD_SHELL / thin / forms | ~18 |
| AUTH_BOOTSTRAP | 1 |
