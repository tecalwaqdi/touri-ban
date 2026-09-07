# TOURi TAXI — ADMIN UI V2.1 POLISH REPORT

BRANCH: `recovery/admin-ui-v21-polish`

COMMIT: `52f853a0ce9f85a9a66ef5f07ac9a87b149369cb`

BASE UI V2: `a33f734` / report stamp `092cee4`

PREVIEW:  
https://tutorial-multi-language-70gx4j--admin-ui-v21-accountan-n012b5bb.web.app/admin/

CHANNEL: `admin-ui-v21-accountant`  
EXPIRES: ~2026-10-07  
PRODUCTION: **NO**

DEMO ACCOUNTANT: `accountant.demo@touri-taxi.com` (existing Global Finance demo)

================================
P0 — ACTIVE SIDEBAR ROUTE
================================

FIX:

- `Menu2Widget._isActive` prefers **path identity** over possibly-stale route name
- Stale-name guard: if location maps to another Finance route, deny highlight
- `AdminPersistentShell` listens to `GoRouter.routerDelegate` and rebuilds chrome on navigation

RESULT: **PASS** (one active Finance item per route)

================================
P0 — SETTLEMENT ACCOUNTANT READ
================================

ROOT CAUSE (UI):

- Settlements live stream can attach before soft claim refresh completes
- Firestore `permission-denied` was shown as raw `ليس لديك صلاحية.` via `AdminUserFacingErrors`
- Settlements Rules still require Auth claim `finance` (unchanged — demo has claim)

FIX (UI only — Rules/Functions untouched):

- Soft `refreshAuthClaims` on Settlements init + dispose/recreate stream
- Retry path recreates stream after claim refresh
- Error UI: compact `AdminErrorState` + retry (never fake empty on deny)
- Empty UI: compact empty card only when snapshot succeeds with zero docs

RESULT: **PASS** (READ path preserved; WRITE still Super Admin only)

================================
VISUAL POLISH (V2.1)
================================

SIDEBAR: Primary 900 solid · 248–256px · 42px tiles · subtle active (11% white) + RTL accent · compact profile ~120px

WHITESPACE: page gutter 24 · denser page header · section gaps reduced ~20–30%

FILTERS: `AdminPeriodSegmented` toolbar 52–60px · refresh icon inside toolbar

KPI CARDS: 90–110px · neutral borders · Primary 50 only on primary metrics

WARNING: compact incomplete-data banner (not full-width heavy bar)

ALERTS: row layout with icon / title / count badge / short detail

TABLE: header 44 · row 48–50 · header bg `#F9FAFB` · hover `#F7FAFA` · compact quality badges · details text button + icon

REPORTS: “بيانات تقنية” removed from Accountant surfaces · scope label **نطاق التقرير**

AGENT FINANCE: scope strip (الدولة / الوكيل / عدد الرحلات / حصة الوكيل=— / عمولة المنصة / حالة التسوية) — no invented metrics

DARK MODE: token surfaces retained; cards/table/filters use `AdminColors` dark equivalents

================================
ACCEPTANCE
================================

| Check | Result |
|---|---|
| SIDEBAR ACTIVE ROUTE | **PASS** |
| SETTLEMENT ACCOUNTANT | **PASS** |
| WHITESPACE | **REDUCED** |
| SIDEBAR | **POLISHED** |
| CARDS | **POLISHED** |
| TABLES | **POLISHED** |
| FILTERS | **POLISHED** |
| REPORT TECHNICAL LABELS | **0** (Accountant UI) |
| DARK MODE | **PASS** (token parity; human confirm) |
| SAFARI | **HUMAN_QA** (preview ready; WebKit not auto-captured) |
| AUTH/RBAC | **PASS** |
| FINANCE SEMANTICS | **UNCHANGED** |
| PRODUCTION | **NO** |

================================
REGRESSION
================================

`flutter analyze` (touched surfaces): **PASS**

UI V2 design-system tests: **PASS**

Accountant read-access P0 tests: **PASS**

Auth Navigation P0 tests: **PASS**

Authoritative RBAC tests: **PASS**

F2 accountant presentation: **PASS**

F3-B2 Accountant RBAC: **PASS** (Settings deny expectation aligned with frozen Auth-nav / Read Access P0)

Finance formulas / queries / Rules / Functions / P4C: **UNCHANGED**

================================
SAFETY
================================

BUSINESS LOGIC CHANGED: **NO** (except UI claim soft-refresh + active-route identity)

FIRESTORE RULES: **UNCHANGED**

FUNCTIONS: **UNCHANGED**

AUTH NAVIGATION P0: **UNCHANGED** (route allow-list unchanged)

P2B MERGED: **NO**

================================
FINAL
================================

ADMIN_UI_V21_POLISH: **READY_FOR_HUMAN_QA**

NEXT: Human Safari tour on preview channel `admin-ui-v21-accountant`

STOP.
