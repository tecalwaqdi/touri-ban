# Admin Screen Inventory (Phase 0)

**Scope:** `admin/Admi` only  
**Source of truth:** `lib/flutter_flow/nav/nav.dart` (`createRouter`)  
**Audit date:** 2026-09-04  
**Canonical main HEAD:** `6eff3e061dd58269a9cdef6fbd46c6848342a6d6` (`1.0.16+2018`)  
**Live production (Render + Firebase `/admin/`):** `1.0.15+2017` @ provenance `358783a` (NOT equal to main pubspec)

**Code modified this phase:** none

---

## Summary

| Metric | Count |
|--------|------:|
| GoRouter `FFRoute` entries | 71 |
| Distinct named screens (excl. `_initialize`) | 70 |
| Sidebar primary destinations (`menu2_widget`) | ~30 |
| Widget with `routePath` but **not** registered in GoRouter | 1 (`AdminGeoHub` `/adminGeoHub`) |
| Legacy / copy routes still registered | several (see LEGACY) |

Parent layout convention:

- **Canonical shell:** `AdminLayoutWidget` + `Menu2Widget` sidebar
- **Many CRUD/edit routes** do **not** wrap `AdminLayoutWidget` (fullscreen form / FlutterFlow pages)
- **Geo list routes** (`AdminDol`, `Adminregion`, `Adminvill`) are thin wrappers that return `AdminGeoHubWidget`

Role access SoT: `AdminRoleService.canAccessRoute` + extra gates in `menu2_widget.dart`.

Health colors are **forensic classifications from source inspection + prior known defects**, not a completed runtime QA pass.

---

## Domains

### GLOBAL SHELL / AUTH

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `_initialize` | `/` | Auth bootstrap → panel home or login | `nav.dart` | auth redirect | n/a | `AuthUserStreamWidget` | Auth + claims | YELLOW (splash/session race) |
| `HomePage` | `/homePage` | Login / public home | `lib/home_page/home_page_widget.dart` | public | none | FlutterFlow | Auth | YELLOW |
| `Settings` | `/settings` | Settings | `lib/settings/settings_widget.dart` | all panel roles | mixed | Menu2 model | local + auth | YELLOW |
| `AdminHome` | `/adminHome` | Legacy admin home | `lib/admin/admin_home/admin_home_widget.dart` | panel | AdminLayout | Menu2 | light | YELLOW (legacy) |
| `Home` | `/home` | Legacy home | `lib/home/home_widget.dart` | auth | none | — | — | ORANGE (legacy / unclear) |
| `home3` | `/home3` | Legacy home3 | `lib/admin/home3/home3_widget.dart` | auth | none | Menu2 model | — | ORANGE (legacy) |

### DASHBOARD

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `Home22Dashboard` | `/home22Dashboard` | Primary dashboard | `lib/home22_dashboard/home22_dashboard_widget.dart` | SA / Agent home | AdminLayout | dashboard_stats, AdminUi | Firestore aggregates / streams | YELLOW |

### DRIVERS

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|---------|---------|--------|
| **`Admindrever`** | **`/drever`** | **Canonical Drivers / Delegates list** | `lib/admin/admindrever/admindrever_widget.dart` | SA / Agent | AdminLayout | **AdminFirestoreList**, counters, filter, **details drawer**, documents panel | `user` (drivers) | **ORANGE** (list flicker via `countQueryBuilder` identity; drawer/doc lifecycle overlap on main) |
| `AdminDrivers` | `/adminDrivers` | Alternate drivers list | `lib/admin/admin_drivers/admin_drivers_widget.dart` | SA / Agent | AdminLayout | AdminFirestoreList | `user` | ORANGE (duplicate surface vs `/drever`) |
| `AdminDriversCopy` | `/adminDriversCopy` | Copy/legacy drivers | `lib/admin/admin_drivers_copy/...` | auth | none/legacy | — | `user` | RED (legacy copy) |
| `DriverProfile` | `/driverProfile` | Full driver profile | `lib/driver_profile/driver_profile_widget.dart` + `driver_profile_body.dart` | SA / Agent / transport | none (page) | StatusStack, documents, financial panels | `user` + docs | **ORANGE** (status stack duplication risk on main) |
| `DriverActivation` | `/driverActivation` | Registration review | `lib/driver_activation/...` | SA / Agent | none | status badges, review body | `user` | YELLOW |
| `addDrev` | `/addDrev` | Add/edit driver | `lib/add_drev/add_drev_widget.dart` | SA / Agent / transport | none | forms | `user` | YELLOW |
| `AdminDriverExpiryQueue` | `/driverDocExpiry` | Doc expiry queue | `lib/admin/admin_driver_expiry_queue/...` | SA / Agent | none/partial | badges | `user` docs | YELLOW |
| `AdminDriverReviewFixture` | `/driverReviewFixture` | QA fixture only | `.../admin_driver_review_fixture/...` | gated by `AdminQaFixtures` | — | badges | fixtures | GREEN (dev-only) |
| `CompanyDrivers` | `/companyDrivers` | Transport-company drivers | `lib/admin/company_drivers/...` | transport | AdminLayout | AdminFirestoreList | `user` scoped | YELLOW |
| `AdminDriverWallets` | `/adminDriverWallets` | Legacy wallets tool | `lib/admin/admin_driver_wallets/...` | **SuperAdmin only** (menu) | AdminLayout | AdminUi | wallets | YELLOW (legacy labeled) |

### CUSTOMERS / USERS

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `Adminuser` | `/adminuser` | Customers | `lib/admin/adminuser/...` | SA / Agent | AdminLayout | AdminFirestoreList, filter bar | `user` | YELLOW |
| `addUser` | `/addUser` | Add user | `lib/add_user/...` | auth | none | forms | `user` | YELLOW |
| `AdminUserManagementSystem` | `/adminUserManagementSystem` | User mgmt system | `.../admin_user_management_system/...` | SA | AdminLayout | AdminFirestoreList | `user` | YELLOW |
| `adminRegesr` | `/adminRegesr` | Registration (blocked for SA in canAccess?) | `lib/admin_regesr/...` | special | — | — | — | ORANGE (odd RBAC) |

### GEO

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `AdminDol` | `/adminDol` | Countries → Geo hub tab | wrapper → `AdminGeoHubWidget` | SA (Agent denied AdminDol) | via hub | AdminGeoHub | `countries` | YELLOW |
| `Adminregion` | `/adminregion` | Regions → Geo hub | wrapper | SA / Agent | via hub | AdminGeoHub | `cities` | YELLOW |
| `Adminvill` | `/adminvill` | Cities/villages → Geo hub | wrapper | SA / Agent | via hub | AdminGeoHub | `villages` | YELLOW |
| `Admincite` | `/admincite` | Cite (legacy?) | `admincite_widget.dart` | auth | none | — | — | ORANGE |
| `AdminGeoHub` | `/adminGeoHub` | **Unified geo hub** | `lib/admin/admin_geo/admin_geo_hub_widget.dart` | n/a direct | AdminLayout (hub) | AdminUi | countries/cities/villages | **ORANGE** — **route NOT in GoRouter**; only via wrappers |
| `AddDolh` / `EdetDolh` | `/addDolh` `/edetDolh` | Country add/edit | `add_dolh` / `edet_dolh` | SA | none | forms | `countries` | YELLOW |
| `AddReg` / `edetReg` | `/addReg` `/edetReg` | Region add/edit | `add_reg` / `edet_reg` | SA / Agent | none | forms | `cities` | YELLOW |
| `addVill` / `edetVill` | `/addVill` `/edetVill` | Village add/edit | `add_vill` / `edet_vill` | SA / Agent | none | forms | `villages` | YELLOW |
| `AddPlace` | `/addPlace` | Add place | `lib/add_place_widget.dart` | auth | none | — | geo | YELLOW |

### LANDMARKS

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `AdminM3alm` | `/adminM3alm` | Landmarks list | `lib/admin/admin_m3alm/...` | SA / Agent | AdminLayout | AdminFirestoreList, agent landmark list | `mkan` | YELLOW (Africa filter history; live=older binary) |
| `AdminaddMkan` | `/adminaddMkan` | Add landmark | `adminadd_mkan` | SA / Agent | none | location section | `mkan` | YELLOW |
| `AdminaddMkanCopy` | `/adminEdetMkan` | Edit landmark | `adminadd_mkan_copy` | SA / Agent | none | location | `mkan` | YELLOW |

### BOOKINGS

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `AdminALLhgZ` | `/adminALLhgZ` | All bookings | `admin_a_l_lhg_z` | SA / Agent | AdminLayout | AdminFirestoreList, pagination bar | `order` | YELLOW |
| `AdminBookingDetails` | `/adminBookingDetails` | Booking details | `admin_booking_details` | SA / Agent / partner | none/partial | journey section, badges | `order` | YELLOW |
| `PartnerBookings` | `/partnerBookings` | Partner bookings | `partner_bookings` | partner | AdminLayout | AdminFirestoreList | `order` scoped | YELLOW |

### AGENTS / RBAC / ORG

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `AdminAgent` | `/adminAgent` | Country agents | `admin_agent` | SA | AdminLayout | AdminFirestoreList | `user` agents | YELLOW |
| `AdminAddAgent` / `EdetAgent` | add/edit | agent CRUD | respective | SA | none | forms | `user` | YELLOW |
| `AdminAgentReport` | `/adminAgentReport` | Agent report | `admin_agent_report` | SA | none | — | mixed | YELLOW |
| `AdminAgentCopy` | `/adminAgentCopy` | Copy legacy | `admin_agent_copy` | auth | none | — | — | RED (legacy) |
| `AdminSuperAdmins` | `/adminSuperAdmins` | Super admins | `admin_super_admins` | SA | AdminLayout | AdminFirestoreList | `user` | YELLOW |
| `AdminAddSuperAdmin` / `EdetSuperAdmin` | add/edit | SA CRUD | respective | SA | none | forms | `user` | YELLOW |
| `AdminTourGuides` | `/adminTourGuides` | Tour guides | `admin_tour_guides` | SA / Agent | AdminLayout | AdminFirestoreList | `user` | YELLOW |
| `AdminPartners` / `AdminAddPartner` | partners | partners | respective | SA / Agent | none/partial | — | partners | YELLOW |
| `AdminTransportCompanies` + add/edit | companies | transport cos | respective | SA / Agent | AdminLayout / none | AdminFirestoreList | `transport_company` | YELLOW |

### VEHICLE TYPES

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `Admintypecar` | `/admintypecar` | Vehicle types | `admintypecar` | SA / Agent | AdminLayout | cards, badges | typecar | YELLOW |
| `CarTypeAddition` | `/carTypeAddition` | Add type | `car_type_addition` | SA / Agent | none | editor | typecar | YELLOW |

### FINANCE / SETTLEMENTS / WALLETS / RECON / AUDIT

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `AdminFinanceHub` | `/adminFinanceHub` | Finance home | `admin_finance_hub` | SA / finance staff | AdminLayout | KPI, badges, CF callables | CF V2 + Firestore | YELLOW (Finance V3 paused; UI polish debt) |
| `AdminAgentFinance` | `/adminFinanceAgents` | Agent finance | `admin_agent_finance` | SA / Agent | AdminLayout | panels | CF / snapshots | YELLOW |
| `AdminProfits` | `/adminProfits` | Profits / driver finance panel host | `admin_profits` | SA | AdminLayout | `AdminFinancialV2Panel` | CF | YELLOW |
| `AdminFinanceChannels` | `/adminFinanceChannels` | Channels | `admin_finance_channels` | SA | AdminLayout | AdminUi | finance | YELLOW (not in primary sidebar list) |
| `AdminFinanceReceivables` | `/adminFinanceReceivables` | Receivables | `admin_finance_receivables` | SA | AdminLayout | AdminUi | finance | YELLOW (hub-linked) |
| `AdminSettlements` | `/adminSettlements` | Settlements list | `admin_settlements` | SA | AdminLayout | AdminUi | settlements | YELLOW |
| `AdminSettlementDetails` | `/adminSettlementDetails` | Settlement detail | same folder | SA | AdminLayout | badges | settlements | YELLOW |
| `AdminSettlementReceipt` | `/adminSettlementReceipt` | Receipt | same | SA | AdminLayout | — | payments | YELLOW |
| `AdminReconciliation` | `/adminReconciliation` | Reconciliation | `admin_reconciliation` | SA | AdminLayout | AdminUi | CF | YELLOW |
| `AdminFinancialPeriods` | `/adminFinancialPeriods` | Periods | `admin_financial_periods` | SA | AdminLayout | AdminUi | periods | YELLOW |
| `AdminFinanceReports` | `/adminFinanceReports` | Finance reports | `admin_finance_reports` | SA | AdminLayout | AdminUi | reports | YELLOW |
| `AdminFinanceAudit` | `/adminFinanceAudit` | Finance audit | `admin_finance_audit` | SA | AdminLayout | AdminUi | audit | YELLOW |
| `AdminDiagnostics` | `/adminDiagnostics` | Diagnostics | `admin_diagnostics` | SA | AdminLayout | AdminUi | system | YELLOW |

### REPORTS / AUDIT (OPS)

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `AdminReportsHub` | `/adminReportsHub` | Reports hub | `admin_reports_hub` | **SA only** | AdminLayout | AdminUi | reports | YELLOW |
| `AdminAuditLog` | `/adminAuditLog` | Audit log | `admin_audit_log` | **SA only** | AdminLayout | AdminFirestoreList | audit entries | YELLOW |

### SUPPORT / NOTIFICATIONS / SYSTEM

| Route | Path | Screen | Source | Role | Layout | Shared | Backend | Health |
|-------|------|--------|--------|------|--------|--------|---------|--------|
| `AdminSuport` | `/adminSuport` | Support | `admin_suport` | SA / Agent | AdminLayout | AdminFirestoreList, drawers | support | YELLOW |
| `AdminNotifications` | `/adminNotifications` | Notifications | `admin_notifications` | SA / Agent | AdminLayout | AdminFirestoreList | notifications | YELLOW |

---

## Health rollup (forensic)

| Color | Count | Meaning |
|-------|------:|---------|
| GREEN | 1 | Dev fixture / intentionally gated |
| YELLOW | 60 | Usable; cleanup / consistency / shared-list risk |
| ORANGE | 8 | Functional/state/duplication/layout/auth-entry debt |
| RED | 2 | Legacy copy screens still routed |

**Method:** Source inspection only (router + file structure + known shared defects). Not a completed runtime QA pass.

**Out of scope for health scoring:** Local tooling process exits, intentional server stops, and non-Admin apps.

### Complete route health matrix (all 71 GoRouter entries)

| Route | Path | Health | Reason |
|-------|------|--------|--------|
| `_initialize` | `/` | ORANGE | Auth splash / claims timing can delay panel entry |
| `AddPlace` | `/addPlace` | YELLOW | Thin/legacy place route; lifecycle decision later |
| `HomePage` | `/homePage` | YELLOW | Login/public; shell N/A |
| `AdminHome` | `/adminHome` | YELLOW | Legacy home; primary is `Home22Dashboard` |
| `AdminM3alm` | `/adminM3alm` | YELLOW | Usable; inherits `AdminFirestoreList` reload risk |
| `AdminPartners` | `/adminPartners` | YELLOW | Thin redirect-style partners entry |
| `AdminAddPartner` | `/adminAddPartner` | YELLOW | Fullscreen CRUD; shell inconsistency |
| `AdminaddMkan` | `/adminaddMkan` | YELLOW | Fullscreen landmark create |
| `AdminDol` | `/adminDol` | YELLOW | Wrapper → `AdminGeoHubWidget` (countries) |
| `Adminregion` | `/adminregion` | YELLOW | Wrapper → Geo hub (regions) |
| `Admincite` | `/admincite` | ORANGE | Thin/legacy cite route |
| `Adminuser` | `/adminuser` | YELLOW | Customers list; shared list reload risk |
| `AdminDrivers` | `/adminDrivers` | ORANGE | Duplicate Drivers surface vs `/drever` |
| `AdminBookingDetails` | `/adminBookingDetails` | YELLOW | Detail page; shell partial |
| `AdminALLhgZ` | `/adminALLhgZ` | YELLOW | Bookings list; shared list reload risk |
| `AdminAgent` | `/adminAgent` | YELLOW | Agents list; shared list reload risk |
| `AdminAgentReport` | `/adminAgentReport` | YELLOW | Report UI; presentation-heavy |
| `AdminAddAgent` | `/adminAddAgent` | YELLOW | Large fullscreen form |
| `EdetAgent` | `/edetAgent` | YELLOW | Large fullscreen form |
| `AdminSuperAdmins` | `/adminSuperAdmins` | YELLOW | List; shared list reload risk |
| `AdminAddSuperAdmin` | `/adminAddSuperAdmin` | YELLOW | Fullscreen CRUD |
| `EdetSuperAdmin` | `/edetSuperAdmin` | YELLOW | Fullscreen CRUD |
| `AdminSuport` | `/adminSuport` | YELLOW | Support list + drawer; shared list risk |
| `AdminNotifications` | `/adminNotifications` | YELLOW | Notifications list; shared list risk |
| `AdminUserManagementSystem` | `/adminUserManagementSystem` | YELLOW | User mgmt list; shared list risk |
| `adminRegesr` | `/adminRegesr` | ORANGE | Odd RBAC (denied for SuperAdmin in `canAccessRoute`) |
| `Admintypecar` | `/admintypecar` | YELLOW | Vehicle types; polish later |
| `AddDolh` | `/addDolh` | YELLOW | Country create form |
| `AdminaddMkanCopy` | `/adminEdetMkan` | YELLOW | Landmark edit form |
| `AddReg` | `/addReg` | YELLOW | Region create form |
| `edetReg` | `/edetReg` | YELLOW | Region edit form |
| `EdetDolh` | `/edetDolh` | YELLOW | Country edit form |
| `addVill` | `/addVill` | YELLOW | Village create form |
| `edetVill` | `/edetVill` | YELLOW | Village edit form |
| `AdminDriversCopy` | `/adminDriversCopy` | RED | Legacy copy route still registered |
| `DriverActivation` | `/driverActivation` | YELLOW | Registration review; shares docs/status components |
| `AdminDriverExpiryQueue` | `/driverDocExpiry` | YELLOW | Expiry queue; shell partial |
| `AdminDriverReviewFixture` | `/driverReviewFixture` | GREEN | QA fixture gated by `AdminQaFixtures` |
| `CarTypeAddition` | `/carTypeAddition` | YELLOW | Vehicle type form |
| `Adminvill` | `/adminvill` | YELLOW | Wrapper → Geo hub (cities) |
| `addDrev` | `/addDrev` | YELLOW | Driver add/edit form |
| `AdminTransportCompanies` | `/adminTransportCompanies` | YELLOW | Companies list; shared list risk |
| `AddTransportCompany` | `/addTransportCompany` | YELLOW | Company create form |
| `EdetTransportCompany` | `/edetTransportCompany` | YELLOW | Company edit form |
| `Admindrever` | `/drever` | ORANGE | Canonical Drivers; list flicker risk (`countQueryBuilder` identity on main) |
| `AdminTourGuides` | `/adminTourGuides` | YELLOW | Tour guides list; shared list risk |
| `AdminFinanceHub` | `/adminFinanceHub` | YELLOW | Finance home; V3 paused — UI polish only later |
| `AdminFinanceChannels` | `/adminFinanceChannels` | YELLOW | Channels; hub-adjacent |
| `AdminFinanceReceivables` | `/adminFinanceReceivables` | YELLOW | Receivables; hub-adjacent |
| `AdminAgentFinance` | `/adminFinanceAgents` | YELLOW | Agent finance; V3 paused |
| `AdminReconciliation` | `/adminReconciliation` | YELLOW | Reconciliation; V3 paused |
| `AdminFinancialPeriods` | `/adminFinancialPeriods` | YELLOW | Periods |
| `AdminFinanceReports` | `/adminFinanceReports` | YELLOW | Finance reports |
| `AdminFinanceAudit` | `/adminFinanceAudit` | YELLOW | Finance audit |
| `AdminDiagnostics` | `/adminDiagnostics` | YELLOW | Diagnostics |
| `AdminDriverWallets` | `/adminDriverWallets` | YELLOW | Legacy wallets tool (SA menu gate) |
| `addUser` | `/addUser` | YELLOW | Add user form |
| `Home` | `/home` | ORANGE | Legacy large page; unclear role vs dashboard |
| `home3` | `/home3` | ORANGE | Legacy stub still routed |
| `Home22Dashboard` | `/home22Dashboard` | YELLOW | Primary dashboard |
| `AdminProfits` | `/adminProfits` | YELLOW | Profits / financial V2 panel host |
| `AdminSettlements` | `/adminSettlements` | YELLOW | Settlements list |
| `AdminSettlementDetails` | `/adminSettlementDetails` | YELLOW | Settlement detail |
| `AdminSettlementReceipt` | `/adminSettlementReceipt` | YELLOW | Receipt |
| `AdminAuditLog` | `/adminAuditLog` | YELLOW | Audit log list; shared list risk |
| `AdminReportsHub` | `/adminReportsHub` | YELLOW | Ops reports hub (large UI) |
| `PartnerBookings` | `/partnerBookings` | YELLOW | Partner bookings list |
| `CompanyDrivers` | `/companyDrivers` | YELLOW | Company drivers list |
| `Settings` | `/settings` | YELLOW | Settings (high setState density) |
| `AdminAgentCopy` | `/adminAgentCopy` | RED | Legacy copy route still registered |
| `DriverProfile` | `/driverProfile` | ORANGE | Status/lifecycle duplication risk with documents panel |

### Orphan widget route (not in GoRouter)

| Route | Path | Health | Reason |
|-------|------|--------|--------|
| `AdminGeoHub` | `/adminGeoHub` | ORANGE | Declared on widget; **not registered** in `nav.dart`; only via Dol/region/vill wrappers |

## Sidebar vs router gaps

**In sidebar, not always separate menu rows:** Finance Channels / Receivables (reachable from hub).

**In router, weak/no sidebar:** `AdminDrivers`, `AdminHome`, `Home`, `home3`, `Admincite`, copy routes, many CRUD paths.

**Has widget + path, missing GoRouter registration:** `AdminGeoHub` `/adminGeoHub`.
