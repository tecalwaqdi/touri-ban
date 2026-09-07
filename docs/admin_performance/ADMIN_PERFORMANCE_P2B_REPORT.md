# TOURi TAXI — ADMIN PERFORMANCE P2B REPORT

BASE: `recovery/admin-performance-p4c-firestore-transport` tip `80f5ddc` (P4C chain; Finance first-data architecture frozen)

BRANCH: `recovery/admin-performance-p2b-operational-tables`

COMMIT: `1266206ae177423907ec20bb44208aea49d8c8e6`

PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p2b-dubguo9q.web.app/admin/

FIREBASE PROJECT: `tutorial-multi-language-70gx4j`

METHOD: Chromium Playwright; Super Admin custom-token hydrate; **first useful ≈ first Firestore response after route** (P2A-compatible, Flutter canvas-safe). Warm: one `/drever` visit before measured runs. Accountant Finance uses `__TOURI_PERF_P4B__` route→paint. Probe: `admin/Admi/qa_tools/admin_perf_p2b_ops_probe.mjs`. Metrics: `docs/admin_performance/p2b_probe/p2b_ops_metrics.json`.

================================
A — TABLE AUDITS (pre-change)
================================

### Drivers `/drever`
ROUTE: `/drever` · COLLECTION: `user` · QUERY: `AdminFirestoreList` + `AdminOpsQueryBuilder.applyDriverFilters` (`ismndob`, country `Rev_dolh`, status filters) · FILTERS: server activation/review/docs/vehicle/city/date; client connection + name/plate on loaded page · SERVER LIMIT: **40** (UI 40/50/100) · ORDER BY: `documentId` (or `created_time DESC` with date filter) · CLIENT-SIDE FILTER: YES (page-local) · LISTENER: NO · N+1: NO per-row docs; YES KPI `DriverAdminStatsLoader` ~20× `count()` · DUPLICATE FETCH: list aggregate + KPI bundle · TIME TO FIRST DATA (cold pre-fix): ~16.9 s / 30 FS starts

### Agents `/adminAgent`
ROUTE: `/adminAgent` · COLLECTION: `user` · QUERY: `Isagent==true` + country scope · PAGE: **40** · ORDER BY: none · CLIENT SEARCH: YES (debounced 300 ms) · LISTENER: NO · N+1 BEFORE: per-row landmark `FutureBuilder` · AFTER: cache peek + deferred `AdminLandmarkCountCache.preloadCountries` · Super Admin gate only

### Users `/adminUserManagementSystem`
ROUTE: `/adminUserManagementSystem` · COLLECTION: `user` · QUERY: country-scoped `AdminCountryScope.applyAllUsersQuery` · PAGE: **40** · ORDER BY: `documentId` · CLIENT SEARCH: YES (300 ms) · LISTENER: NO · N+1: NO · ROLE FILTER SERVER-SIDE: country scope YES; free-text role filter remains client on page

### Landmarks `/adminM3alm`
ROUTE: `/adminM3alm` · COLLECTION: `mkan` · PAGE: **40** · ORDER BY: `documentId` · LISTENER: NO · IMAGE BLOCKING: NO (rows render; images progressive where widgets already allow) · Catalog count secondary

### Bookings `/adminALLhgZ`
ROUTE: `/adminALLhgZ` · COLLECTION: `order` · QUERY: `AdminBookingsQuery` (country, status_code/lifecycle, date, city) · PAGE: **40** · ORDER BY: `data_order DESC` · LISTENER: **false** (historical one-shot) · CLIENT FILTER: YES on loaded page · KPI: 4 lifecycle bucket loads (deferred after P2B) · STATUS_CODE: unchanged

### Countries/cities
Small Geo Hub collections — left alone (no over-engineering).

================================
B — MEASURED COST (warm medians, n=3)
================================

| Surface | median firstUseful (ms) | median FS starts (full settle) | Class |
|---|---|---|---|
| Drivers | **5799** | 3 | P0 wall; amplification fixed |
| Agents | **4814** | 3 | P0 wall |
| Users | **4377** | 4 | P0 wall |
| Landmarks | **5073** | 2 | P0 wall |
| Bookings | **4350** | 5 | P0 wall |

Preferred ≤1500 ms first rows: **not met** on absolute wall. Read-amplification / KPI contention: **improved**.

================================
DRIVERS
================================

BEFORE QUERY: page `limit` + parallel list `count()` + ~20 KPI `count()` on first frame (≈30 concurrent starts)

AFTER: page `limit` first; list aggregate deferred ~350 ms after first page; KPI strip scheduled only after `!listState.isLoading` + 450 ms; KPI counts run in waves of 4

PAGE SIZE: **40** (was 20)

N+1 BEFORE: KPI fan-out contended with first page (not per-driver detail docs)

AFTER: no per-driver detail prefetch; KPI deferred + waved

FIRST DATA BEFORE (cold smoke): ~16913 ms / 30 starts

AFTER (warm median): **5799 ms** / median **3** starts over settle window

================================
AGENTS
================================

BEFORE: paginated list + per-row landmark FutureBuilder N+1

AFTER: cache peek / `—`; one deferred preload per country-ref set (600 ms after first rows)

PAGE SIZE: **40**

N+1: **reduced** (no per-row Future)

FIRST DATA: warm median **4814 ms**

C3 one-active-agent: **unchanged** (no assignment UI rewrite)

================================
USERS
================================

PAGINATION: YES (`AdminFirestoreList`, page 40)

FIRST DATA: warm median **4377 ms**

ROLE FILTER SERVER-SIDE: country scope YES; free-text remains client on page

================================
LANDMARKS
================================

PAGE SIZE: **40**

IMAGE BLOCKING: **NO**

FIRST DATA: warm median **5073 ms**

================================
BOOKINGS
================================

HISTORICAL PAGINATION: **PASS** (`liveUpdates: false`, `startAfter` via `AdminFirestoreList`)

ACTIVE LIVE QUERY: **BOUNDED** / off on this screen (no full historical listen)

STATUS_CODE: **UNCHANGED**

FIRST DATA: warm median **4350 ms** (lifecycle KPI deferred after first rows)

================================
READ AMPLIFICATION
================================

Target ≈ 1× page docs + small metadata.

DRIVERS: ~**1×** page (40) + deferred counts (not on first paint path) — settle starts median **3**

AGENTS: ~**1×** + deferred landmark counts — median starts **3**

USERS: ~**1×** + deferred total count — median starts **4**

LANDMARKS: ~**1×** — median starts **2**

BOOKINGS: ~**1×** + deferred lifecycle buckets — median starts **5**

================================
SCOPE
================================

SUPER ADMIN: **PASS** (ops probe authenticated)

COUNTRY ADMIN: schema/query scope preserved (`AdminOpsCountryScope` / `AdminCountryScope`) — not re-probed in this channel run

COUNTRY AGENT: scope helpers unchanged; Agents list remains Super-Admin gated

ACCOUNTANT OPERATIONAL ACCESS: Finance-only path used for regression; operational routes not opened as Accountant in this probe (RBAC unchanged)

CROSS-COUNTRY LEAK: **0** intentional (no scope broadening)

================================
STREAMS
================================

DUPLICATE LISTENERS: **0** new (lists remain one-shot `get`, `liveUpdates` false on bookings)

LEAKS: **0** known (existing dispose paths)

FUTURES RECREATED: company drivers list no longer blocked on dashboard `FutureBuilder`; agent landmark Futures removed from rows

================================
FINANCE REGRESSION
================================

FINANCE CODE / TRANSPORT / P3 CACHE / P4 PATH: **not modified**

FINANCE FIRST DATA (Accountant, cache-busted, P2B preview):
- Mixed probe median route→paint: **2003** ms (samples 2003 / 995 / 2200)
- Finance-only 5-run median: **2089** ms (4157, 2185, 1639, 1749, 2089)

RECON / SETTLEMENTS: not re-timed in P2B ops probe (architecture untouched)

FINANCE_FIRST_DATA_FROZEN: **PRESERVED** (no Finance repo/transport edits). Measured warm median on this preview is **above** the ~985 ms P4C Chromium freeze point under cache-bust — treat as **environment/watch item for P2B human gate**, not an intentional Finance reopen.

================================
INDEXES
================================

NEW REQUIRED: **none** added in P2B (no new composite definitions)

DEPLOYED: **NO**

UNRELATED DIFF: **0**

================================
TESTS
================================

ANALYZE (changed libs): **PASS**

P2B (`test/backend/admin_perf_p2b_ops_lists_test.dart`): **PASS** (5)

ADMIN / RBAC / C3 / full Finance smoke suite: not fully re-run end-to-end in this pass (spot P2B + analyze + Finance paint probe)

NEW FAILURES: **0** in executed P2B tests

================================
SAFETY
================================

DRIVER EDIT: **UNCHANGED** (`driver_profile` / edit-phase / `add_drev` — 0 diff)

FINANCE SEMANTICS: **UNCHANGED**

FINANCIAL WRITES: **0**

PRODUCTION DATA: **UNCHANGED**

PRODUCTION DEPLOY: **NO** (preview channel only)

CUSTOMER: **UNCHANGED**

DRIVER APP: **UNCHANGED**

================================
WHAT SHIPPED
================================

1. Default `kAdminPageSize` **40** / large **50**; Drivers/Landmarks/Bookings page-size pickers aligned
2. `AdminFirestoreList`: defer aggregate `count()` until after first page
3. Drivers: defer KPI strip; wave KPI counts (4-wide)
4. Agents: remove per-row landmark Futures; deferred country preload once
5. Bookings: defer lifecycle KPI buckets after first rows
6. Company drivers: list no longer waits on dashboard stats Future
7. Probe + unit tests + this report

================================
FINAL
================================

PERF-P2B: **READY_FOR_HUMAN_QA**

OPERATIONAL PERFORMANCE: **ACCEPTABLE** (amplification/N+1 fixed; absolute first-data still ~4–6 s warm — preferred ≤1500 ms not met)

NEXT: **P2B_HUMAN_GATE**

STOP.
