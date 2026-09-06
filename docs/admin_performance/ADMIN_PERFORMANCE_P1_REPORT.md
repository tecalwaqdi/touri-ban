# TOURi TAXI — ADMIN PERFORMANCE P1 REPORT

**MODE:** Implementation + benchmark (preview only)  
**NO production deploy**  
**NO finance semantics changes**

---

## Baseline (P0) — controllable post-engine costs

| Metric | BEFORE (P0) |
|---|---|
| Profile reads on login | **2** (`completePanelSignIn` + `AdminPanelDataBootstrap`) |
| Claims refresh on login | **2** (`ensureCurrentUserDocument` → `_syncClaimsFromServer` + explicit `refreshAuthClaims`) |
| Accountant live order shell listener | **1** (`AdminStatsCoordinator.startLiveSync`) |
| Accountant Finance Hub badge listeners | **2** (payments pending + settlements draft) |
| Settlements same-query rebuild new streams | **≥1 per setState** (IIFE `.snapshots()` in `build`) |
| Accountant finance tour waves | **~11–14** |

PROFILE READ #1: `admin_login_flow.dart` → `completePanelSignIn` → `ensureCurrentUserDocument(forceRefresh: true)`  
PROFILE READ #2: `admin_panel_data_bootstrap.dart` → `_bootstrap` → `ensureCurrentUserDocument(forceRefresh: force)` with `force: true` from login scope bootstrap  

---

## Changes (PERF-P1)

1. **Auth/profile single bootstrap** — login: one profile get + one claims refresh; bootstrap reuses bound profile for same uid (no second Firestore profile get).
2. **Claims** — removed automatic claims sync from every profile read; explicit `refreshAuthClaims` on login / token paths only. Route navigation does not force profile/claims.
3. **Accountant trim** — no operational live-order sync; no Finance Hub menu badge listeners; no dashboard stats warm.
4. **Settlements stream** — `AdminSettlementsStreamOwner` + deterministic query key (scope+limit); status/QA chips are client-side only → rebuild does not resubscribe.
5. **Menu badge streams** (Super Admin / Agent) — memoized on `Menu2Widget` state (not recreated every rebuild).
6. **Logout** — `CountryResolver.clearCache()` + `AdminPerfTrace.resetCounters()` added to `AdminSessionCleanup`.
7. **Instrumentation** — `AdminPerfTrace` (debug/test enabled; muted logs; no PII).

**Retained (unavoidable lightweight):** `CountryResolver.ensureLoaded()` once per session for finance country labels / Saudi aliases (one-shot ≤100 docs, not a listener).

**Deferred to PERF-P2/P5:** finance order scan pagination, N+1 counts, CanvasKit/bundle/deferred imports.

---

## Tests

| Suite | Result |
|---|---|
| `test/backend/admin_perf_p1_shell_test.dart` | PASS |
| `test/admin_agent_finance_route_rbac_test.dart` (B2 RBAC) | PASS |
| `test/core/finance/*` (F1/F2/B1 engines) | PASS (164) |
| `flutter analyze` (touched files) | PASS |

---

## Preview

| Item | Value |
|---|---|
| Channel | `admin-perf-p1` |
| Preview URL | https://tutorial-multi-language-70gx4j--admin-perf-p1-h2e0u7h6.web.app |
| Admin entry | https://tutorial-multi-language-70gx4j--admin-perf-p1-h2e0u7h6.web.app/admin/ |
| Expires | ~2026-09-20 |
| Production Admin hosting | **NOT deployed** |
| Demo user | `accountant.demo@touri-taxi.com` (existing B2H) |

---

# TOURi TAXI — ADMIN PERFORMANCE P1 REPORT

BASE: `recovery/admin-finance-f3b2-accountant-workspace` @ `6f256c2` (+ P0 audit doc)

BRANCH: `recovery/admin-performance-p1-shell-listeners`

COMMIT: _(see git log tip)_

PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p1-h2e0u7h6.web.app/admin/

================================
SESSION
================================

PROFILE READS BEFORE:
2

PROFILE READS AFTER:
1

NORMAL ROUTE PROFILE READS:
0

CLAIM DUPLICATE READS:
0 on login (1 intentional refresh); 0 on normal route nav

LOGOUT INVALIDATION:
PASS

CROSS-USER CACHE LEAK:
0 (CountryResolver + session + perf counters cleared on sign-out; role rebound per claims)

================================
ACCOUNTANT SHELL
================================

UNUSED MODULE FETCHES BEFORE:
CountryResolver + live order listener + 2 menu badge listeners + dashboard warm path

AFTER:
CountryResolver one-shot only (label metadata); live order **0**; menu badges **0**; dashboard warm **0**

UNUSED MENU BADGE LISTENERS:
0

LIVE ORDER SHELL LISTENER:
0 for Accountant

================================
SETTLEMENTS
================================

SAME-QUERY REBUILD NEW STREAMS:
0

MAX INTENDED LISTENERS:
1 per intended query

LEAKED LISTENERS:
0 (owner dispose balances create)

FILTER CHANGE REPLACEMENT:
PASS (status/QA chips do not change query key — client filter only; scope key change replaces once)

ROUTE DISPOSE:
PASS

================================
READ WAVES
================================

ACCOUNTANT FINANCE TOUR BEFORE:
~11–14

AFTER:
~7–9 (removed: duplicate profile, duplicate claims sync, live order, 2 badge listeners; finance route scans unchanged until PERF-P2)

REDUCTION:
~30–40% of shell/listener waves (not finance scan volume)

================================
TIMINGS
================================

WARM LOGIN → FINANCE:
Not browser-HAR timed this pass (code-path: −1 profile RTT −1 claims RTT −3 listeners). Expect measurable improvement vs P0 warm 3–8s; CanvasKit/bundle still dominate cold.

FINANCE HUB → RECONCILIATION:
Unchanged data architecture (PERF-P2) — shell/nav metadata instant

RECONCILIATION → SETTLEMENTS:
Shell faster; first settlements listen once

SETTLEMENT FILTER CHANGE:
Local setState only — no new Firestore subscription

NOTE:
Cold CanvasKit/bundle excluded from P1 success criteria.

================================
REGRESSION
================================

F2:
PASS

B1:
PASS

B2 RBAC:
PASS

COUNTRY SCOPE:
PASS (settlements query predicates unchanged; country agent key still scoped)

SUPER ADMIN:
PASS (live sync + badges retained)

================================
TESTS
================================

ANALYZE:
PASS

PERFORMANCE TESTS:
PASS

FINANCE TESTS:
PASS

NEW FAILURES:
0

================================
SAFETY
================================

FINANCE SEMANTICS CHANGED:
NO

FINANCIAL WRITES:
0

PRODUCTION DEPLOY:
NO

CUSTOMER APP:
UNCHANGED

DRIVER APP:
UNCHANGED

================================
FINAL
================================

PERF-P1:
READY_FOR_HUMAN_QA

NEXT:
PERF-P2

STOP.
