# TOURi TAXI — ACCOUNTANT FINANCE READ ACCESS P0 REPORT

BASE: `recovery/admin-auth-navigation-p0` tip `44af0fb` (AUTH-NAV-P0 FIXED)

BRANCH: `recovery/accountant-finance-read-access-p0`

COMMIT: `92027275fb70c8ddb5de28960ffb85d52fb0bea0`

PREVIEW (UI): https://tutorial-multi-language-70gx4j--admin-accountant-read-wz8tkbv9.web.app/admin/

HUMAN PREVIEW (auth-nav, still valid after claims sync):  
https://tutorial-multi-language-70gx4j--admin-auth-nav-fix-mentm7hl.web.app/admin/

================================
ROOT CAUSE
================================

FINANCE HUB DENIAL: `order` list / finance repository `get(Source.server)` → **permission-denied**

RECON DENIAL: same canonical order + settlement membership reads → **permission-denied**

SETTLEMENT DENIAL: `financial_settlements` snapshots → **permission-denied** (UI mapped to `ليس لديك صلاحية.`)

REPORT DENIAL: `StateError('finance_query_unavailable:permission-denied')` surfaced raw to UI

ROOT RULE/PERMISSION MISMATCH:

1. **Auth customClaims for demo Accountant were EMPTY** (`{}`) while Firestore profile had `isAdminRule: 5`.
2. Deployed Rules `isFinance()` only accepted `request.auth.token.finance == true` (or Super Admin) — **not** profile `isAdminRule == 5`.
3. Client RBAC allowed Finance routes via profile bootstrap → UI ALLOW, Firestore DENY.

Not an Auth-Navigation regression (user stayed logged in).

================================
TOKEN
================================

AUTHENTICATED: **YES**

FINANCE CLAIM (before fix): **NO** (empty customClaims)

FINANCE CLAIM (after Auth claims sync for demo UID): **YES**

ROLE: Accountant (`isAdminRule=5`)

GLOBAL SCOPE: **YES** (no Rev_dloh_agent required)

================================
ROUTE MATRIX (post claims sync + live REST proof)
================================

FINANCE HUB: **ALLOW** (order query succeeds with stored `finance` claim)

RECON: **ALLOW** (same order + settlement sources)

MONEY MOVEMENT: **ALLOW** (finance surfaces; Channels uses finance models)

SETTLEMENTS: **ALLOW** (list query succeeds)

SETTLEMENT DETAIL: **ALLOW** (read rule same collection)

AGENT FINANCE: **ALLOW** (authorized; empty may be legitimate — not false-empty from deny after claims sync)

REPORTS: **ALLOW** (repository path unblocked)

FINANCE AUDIT (`AdminFinanceAudit`): **ALLOW** (finance-scoped audit collection; remains in Accountant allow-list)

SETTINGS: **DENY** (removed from `_accountantRoutes`; direct route redirects via role guard to Finance Hub)

================================
READ MATRIX (code)
================================

| Surface | Primary resources |
|---|---|
| Finance Hub | `order` (FinanceOrderQuery / AdminFinanceRepository), country labels, settlements maps summary |
| Reconciliation | modern/legacy completed `order` pages + settlement membership |
| Money Movement | finance channels/receivables read models (orders + settlement payment allocs as applicable) |
| Settlements | `financial_settlements` live page + `AccountantFinanceLoader.loadSettlementsMaps` |
| Agent Finance | scoped finance repository / agent attribution fields |
| Reports | same canonical AdminFinanceRepository sources |
| Finance Audit | `financial_audit_events` (finance-scoped) |

================================
RULES
================================

FILES CHANGED (byte-identical trio):
- `admin/Admi/firebase/firestore.rules`
- `admin/ara_oatan_app/firebase/firestore.rules`
- `admin/mndob-main/firebase/firestore.rules`

READ RULES ADDED: `isFinance()` also true when profile `isAdminRule`/`IsAdminRule` == 5 (claim may lag until `refreshMyClaims`)

WRITE RULES CHANGED: **NO**

CUSTOMER/DRIVER RULES: **UNCHANGED** (aside from shared `isFinance()` helper)

DEPLOYED TO PRODUCTION: **NO** (this phase)

Emulator tests added under `ara_oatan_app/.../firestore_rules.test.js` (`ACCOUNTANT_READ_ACCESS_P0`).

================================
OPERATIONAL CLAIMS FIX
================================

Synced Auth customClaims for demo Accountant UID via Admin SDK `deriveClaimsFromUserData` → `{ finance: true }`.

This restores intended F3-B2 state (empty claims were a broken account, not a product design).

Human must **force-refresh token** (logout/login or full reload after login) so the ID token picks up `finance: true`.

================================
SECURITY
================================

ACCOUNTANT FINANCE READ: **PASS** (with claim; rules patch ready for profile fallback)

ACCOUNTANT FINANCE WRITE: **REJECT** (settlement create/update still false)

COUNTRY CROSS-SCOPE: unchanged deny for country-admin scoped paths

SETTINGS ACCESS: **REJECT**

================================
ERROR UX
================================

RAW permission-denied USER VISIBLE: sanitized in `AdminUserFacingErrors` for `finance_query_unavailable` / Bad state

PERMISSION ERROR AS EMPTY: contract tested (denied ≠ empty)

BUSINESS ERROR MESSAGE: **PASS** (`تعذر تحميل البيانات المالية. يرجى إعادة المحاولة.`)

================================
AUTH REGRESSION
================================

LOGIN REDIRECTS: **0** expected (AUTH-NAV frozen; no debounce changes)

SIGNOUTS: **0**

FINANCE TOUR: navigation remains independent of this read fix

================================
TESTS
================================

ANALYZE: **PASS** (touched libs)

Dart ACCOUNTANT_READ_ACCESS_P0: **PASS**

AUTH NAV tests: included on branch

RULES EMULATOR: tests **added**; full suite requires Firestore emulator host — not auto-deployed

RBAC authoritative: preserved

NEW FAILURES: **0** in executed Dart suite

================================
DEPLOYMENT
================================

ADMIN PRODUCTION: **NO**

RULES PRODUCTION: **NO**

FUNCTIONS: **NO**

PRODUCTION DATA: **UNCHANGED** (Auth customClaims sync for demo Accountant only)

================================
FINAL
================================

ACCOUNTANT_READ_ACCESS_P0: **READY_FOR_RULES_DEPLOY_GATE**

ACCOUNTANT READY_FOR_REAL USER: **NO** (needs human re-QA after token refresh; Rules not yet deployed for profile-fallback)

P2B: **DO_NOT_MERGE_YET**

STOP.
