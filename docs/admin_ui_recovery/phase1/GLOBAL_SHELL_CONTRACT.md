# Phase 1 — Global Shell Contract

**Product:** Touri Taxi Admin (`admin/Admi`)  
**Arabic-first:** yes

---

## Ownership model

```
route
  → (optional) AdminEditScaffold / custom form scaffold   // CRUD deep links
  → AdminLayoutWidget                                      // panel screens
       → Menu2Widget (sidebar / drawer)
       → content container (max width + padding XOR page-owned padding)
       → page child
```

**One sidebar.** Canonical: `Menu2Widget` via `AdminLayoutWidget`. Legacy `MenuWidget` must not be reintroduced.

**One mobile header.** When `!showAdminInlineSidebar`, `AdminLayoutWidget` owns AppBar (title + menu + theme). Desktop inline sidebar: page owns in-content titles (no duplicate AppBar).

**Padding XOR rule:**

- Either `AdminLayoutWidget(padContent: true)` applies `AdminUi.pagePadding`, **or**
- Page sets `padContent: false` and applies its own padding/scroll.
- Never both.

---

## Density tokens (shell)

| Token | Contract |
|-------|----------|
| Page padding | Compact: ~12 mobile / ~16–20 desktop; avoid giant gutters |
| Content max width | Cap ~1280–1400 usable column (not ultra-wide sprawl) |
| Sidebar width | ~220–280 by viewport |
| Inline sidebar breakpoint | `width >= kBreakpointLarge` (991) |
| Section gap | `AdminUi.sectionGap` (14) |
| Cards | Elegant, compact — screens own cards later |

---

## Typography

| Role | Source |
|------|--------|
| Global font | Cairo via `FlutterFlowTheme` / `AdminUi` themes |
| Page title | theme title / `AdminPageHeader` (page-owned) |
| Section | titleSmall / titleMedium |
| Body | bodyMedium |
| Caption | labelSmall |
| Button | button / labelMedium |
| Table | bodySmall / label |

Do not patch fonts page-by-page in Phase 1.

---

## RTL / LTR

| Layer | Direction |
|-------|-----------|
| Shell chrome (menu, headers, layout) | Follow app `Directionality` (ar/ur → RTL) |
| Technical values (email, IDs, phones, URLs, codes) | Allowed LTR inside their widgets (`Directionality` / text align as appropriate) |

Do not force entire Admin to LTR.

---

## Auth / claims shell states (deterministic)

| State | UI |
|-------|----|
| App boot (`AppStateNotifier.loading`) | `AdminSplashScreen` |
| Logged in, profile/session preparing | **Same** branded splash (not white spinner) |
| Logged in, role resolving / no user doc yet | Sidebar header + “Resolving role…”; **menu items hidden** |
| Ready | Full role-filtered menu |

Required:

- WRONG MENU FLASH: 0  
- UNAUTHORIZED CONTENT FLASH: 0  
- SHELL FLASH between branded splash and white spinner: 0  

Do not change authentication business rules or claims computation.

---

## Active menu

- Match via `adminCurrentRouteName` (never `GoRouterState.of` release bug).
- Geo: `AdminDol` / `Adminregion` / `Adminvill` each highlight their own route (wrappers).

---

## Responsive

| Width | Shell |
|-------|-------|
| ≥ 991 | Inline sidebar |
| < 991 | Drawer + AppBar toggle |

No horizontal shell overflow; single primary vertical scroll owner per page (page-owned).

---

## Non-goals (Phase 1)

- AdminFirestoreList reload gate  
- Driver/Finance/Landmark page redesign  
- Migrating all CRUD onto AdminLayout  
- Merging hotfix `227602a`  
- Deploy / version bump for store apps  
