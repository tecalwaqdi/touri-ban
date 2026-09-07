# Admin UI Execution Plan (Phase 0 → N)

**Method:** ONE Admin screen at a time  
`AUDIT → ROOT CAUSE → DESIGN CONTRACT → IMPLEMENT → TEST → RUNTIME QA → FREEZE → NEXT`

**Do not start Phase 1 until user approves.**

**Absolute:** No Finance V3 formula work; no deploy; no merge of current hotfix into main until an approved screen phase explicitly decides KEEP/REWORK/REVERT for those commits.

---

## Design contract (for later phases — not implemented now)

- Modern enterprise Admin
- Elegant classic cards; **compact**; no giant cards/fields; no excessive whitespace
- Clear hierarchy; **Cairo**; proper Arabic RTL; English/tech values LTR where needed
- Restrained animation; **no screen flicker**; no unnecessary skeleton reload
- Consistent tables + status chips
- Immediate button feedback; duplicate-submit protection
- Responsive desktop / tablet / mobile
- Shared component changes require full usage audit + regression

---

## Dependency-safe execution order

Adjusted from the default preference based on repository dependencies:

### PHASE 1 — GLOBAL SHELL
**Screens/files:** `AdminLayoutWidget`, `Menu2Widget`, `AdminUi` tokens (read-only contract first), auth redirect/`AuthUserStreamWidget` splash behavior  
**Why first:** Every later screen inherits chrome/padding/nav.  
**Shared risk:** Highest — any visual token change touches ~96 files; prefer **contract freeze** before edits.

### PHASE 2 — DASHBOARD
**Route:** `Home22Dashboard` `/home22Dashboard`  
**Why:** Home route for SA/Agent; validates shell + role pending.

### PHASE 3 — DRIVER LIST (canonical only)
**Route:** `Admindrever` `/drever`  
**Files:** `admindrever_widget.dart`, filter/counters, **`admin_firestore_list.dart` (shared — full usage audit required)**  
**Known bugs (main):** list flicker from `countQueryBuilder` identity in `didUpdateWidget`.  
**Hotfix branch:** candidate KEEP for reload gate — but must re-verify under this program, not auto-merge.

### PHASE 4 — DRIVER PROFILE / DRAWER / DOCUMENTS
**Routes:** drawer on `/drever`, `DriverProfile` `/driverProfile`, documents panel, activation review  
**Files:** `admin_drivers_details_drawer.dart`, `admin_driver_documents_panel.dart`, `driver_profile_body.dart`, lifecycle strip, StatusStack  
**Known bugs (main):** lifecycle + status duplication.  
**Decide fate of:** `/adminDrivers`, `/adminDriversCopy` (deprecate vs delete later).

### PHASE 5 — CUSTOMERS
**Route:** `Adminuser` `/adminuser`  
**Shared:** AdminFirestoreList + filter bar (retest after Phase 3).

### PHASE 6 — GEO HUB
**Routes:** `AdminDol` / `Adminregion` / `Adminvill` → `AdminGeoHubWidget`  
**Also:** register-or-document orphan `/adminGeoHub`; CRUD add/edit country/region/village.

### PHASE 7 — LANDMARKS
**Routes:** `AdminM3alm`, add/edit mkan  
**Note:** Customer landmark cache is out of scope unless interface-contract verification is explicitly requested later.

### PHASE 8 — BOOKINGS
**Routes:** `AdminALLhgZ`, `AdminBookingDetails`, `PartnerBookings`.

### PHASE 9 — FINANCE HOME
**Route:** `AdminFinanceHub`  
**Non-negotiable:** no Finance V3 formula / settlement truth changes unless user reopens Finance program.

### PHASE 10 — DRIVER FINANCE / PROFITS PANEL
**Route:** `AdminProfits` + `AdminFinancialV2Panel`.

### PHASE 11 — AGENT FINANCE
**Route:** `AdminAgentFinance`.

### PHASE 12 — SETTLEMENTS
**Routes:** settlements list/details/receipt.

### PHASE 13 — WALLETS
**Route:** `AdminDriverWallets` (legacy tool — classify keep/hide).

### PHASE 14 — CHANNELS / RECEIVABLES / REPORTS (finance)
**Routes:** Channels, Receivables, FinanceReports.

### PHASE 15 — RECONCILIATION / PERIODS / FINANCE AUDIT / DIAGNOSTICS

### PHASE 16 — SUPPORT / NOTIFICATIONS / SETTINGS

### PHASE 17 — RBAC SURFACES
**Routes:** Agents, SuperAdmins, User management, Tour guides, Partners, Transport companies, vehicle types.

### PHASE 18 — LEGACY ROUTE QUARANTINE
**Routes:** `AdminDriversCopy`, `AdminAgentCopy`, `Home`, `home3`, `AdminHome`, unused cite — inventory → hide from router or hard-deprecate.

### PHASE 19 — FINAL GLOBAL QA
Cross-screen: shell, flicker, RTL, breakpoints, role matrices, production vs source parity checklist.

---

## Per-screen phase template (mandatory)

```
CURRENT SCREEN:
FILES:
ROUTES:
DATA SOURCES:
SHARED COMPONENTS:
KNOWN USERS: (other screens sharing components)
KNOWN BUGS:
DESIRED UX:
NON-NEGOTIABLE BUSINESS RULES:
```

Then fix **ONLY** that screen (shared component exception only after usage audit).

---

## Hotfix branch handling (not executed yet)

Branch: `hotfix/admin-driver-landmark-ui` @ `227602a`  
Classification lives in forensic audit:

- **KEEP candidates:** AdminFirestoreList reload gate; driver documents `showLifecycleStrip`; countries_record `driverRequirements` analyzer fix
- **REWORK candidates:** any finance widget touch on that branch; Customer landmark changes (outside Admin screen program)
- **Do not merge to main** until Phase 3–4 accept those KEEP items under this method

---

## Stop conditions

- Phase 0 docs exist and user has reviewed
- User explicitly approves Phase 1
- No deploy / no Finance V3 / no multi-screen drive-by refactors

## Phase 0 completion

| Item | Status |
|------|--------|
| `ADMIN_UI_FORENSIC_AUDIT.md` | COMPLETE |
| `SCREEN_INVENTORY.md` (incl. every-route health matrix) | COMPLETE |
| `SHARED_COMPONENT_MAP.md` | COMPLETE |
| `ADMIN_UI_EXECUTION_PLAN.md` | COMPLETE |
| Code / deploy / Phase 1 | NOT STARTED — await approval |
