# TOURi TAXI — ADMIN PERFORMANCE P2A REPORT

**MODE:** Finance query scoping + pagination + first-useful-data  
**NO production deploy**  
**NO finance semantics / financial writes**

---

## Pre-change query audit (P1 tip)

### Finance Hub / Agent Finance
| Field | Value |
|---|---|
| COLLECTION | `order` |
| FILTERS | optional `Rev_dolh` / `mndob_user` |
| DATE RANGE | `data_order` range |
| STATUS FILTER | **none server-side** (all orders in range) |
| ORDER BY | `data_order` DESC |
| LIMIT | pages of 30 up to **100000** |
| CLIENT FILTERS | QA + operational completed via F1 |
| SUMMARY SOURCE | full scanned set |
| TABLE SOURCE | same full set |

### Reconciliation
Same scanner with **thisYear** preset + settlements `limit(500)`.

### Settlements
Live `financial_settlements` limit **200** (P1 stable stream) — all statuses client-filtered.

---

## P2A architecture

| Concern | Strategy |
|---|---|
| ROW DELIVERY | Modern `status_code IN [completed, trip_completed]` + date + country, page size **40**, `onFirstPage` callback |
| SUMMARY | Chunked modern + narrow legacy `halh` equality candidates → frozen `isOperationallyCompleted` → F1/B1 aggregate on **full eligible set** |
| LEGACY | `halh == مكتمل` / `completed` then helper (empty `status_code` path inside frozen engine) |
| Settlements | Live first page **40** `orderBy createdAt DESC` + one-shot older pages; period maps ≤200 for summary cards |
| NO silent 100k fallback | `FirebaseException` → `StateError('finance_query_unavailable:…')` |

### Summary metric classification
| Metric | Class |
|---|---|
| Completed / financial quality / B1 axes / money totals | **CANONICAL_SCAN_REQUIRED** (completed-candidate scan) |
| Firestore `sum()` on gross | **NOT used** (QA / partial / legacy would diverge) |
| Settlement open count cards | Bounded period maps (PERIOD METRIC, labeled) |

---

## Indexes (source only — NOT deployed to prod in P2A)

Added to `firestore.indexes.json`:
- `order`: `halh` ASC + `data_order` DESC
- `order`: `Rev_dolh` ASC + `halh` ASC + `data_order` DESC

Already present (used):
- `status_code` + `data_order` DESC
- `Rev_dolh` + `status_code` + `data_order` DESC
- `financial_settlements`: `countryId` + `createdAt` DESC

---

# TOURi TAXI — ADMIN PERFORMANCE P2A REPORT

BASE: `recovery/admin-performance-p1-shell-listeners` @ `fa1ebe4` / tip `dd8bd33`

BRANCH: `recovery/admin-performance-p2a-finance-queries`

COMMIT: _(filled after commit)_

PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p2a-lbc3hkqo.web.app

================================
FINANCE HUB
================================

ORDER QUERY BEFORE:
all orders in date range (up to 100k pages of 30)

AFTER:
modern completed `whereIn` + date + country; first page 40; summary via chunked completed candidates + legacy `halh`

FIRST PAGE SIZE:
40

FIRST USEFUL DATA:
onFirstPage callback (rows before summary) — wall ms **NOT_MEASURED** (browser HAR)

SUMMARY COMPLETE:
background completed-candidate scan — **NOT_MEASURED**

SUMMARY SEMANTICS:
UNCHANGED (F1 aggregate on full eligible set; mandatory test 100 vs page 25)

================================
RECONCILIATION
================================

QUERY BEFORE:
thisYear all-order scan

AFTER:
same completed-candidate path + parallel settlements maps ≤200; early B1 on first page (labeled incomplete until full)

FIRST PAGE SIZE:
40

FIRST USEFUL DATA:
early partial B1 rows — **NOT_MEASURED**

SUMMARY COMPLETE:
full scan + settlements — **NOT_MEASURED**

B1 SEMANTICS:
UNCHANGED

================================
SETTLEMENTS
================================

BEFORE FIRST LOAD:
live limit 200

AFTER FIRST LOAD:
live limit **40** + load-more one-shot; period summary maps ≤200

PAGINATION:
PASS

LIVE FIRST PAGE:
YES

LISTENER LEAK:
0 (P1 owner preserved)

================================
SCOPE
================================

COUNTRY ACCOUNTANT SERVER SCOPED:
YES (Rev_dolh / countryId when `usesCountryFinanceScope`)

CROSS-COUNTRY ROW LEAK:
0 (unit)

CROSS-COUNTRY TOTAL LEAK:
0 (unit)

================================
QA
================================

QA ROWS:
0 in live aggregates (unit)

QA TOTAL CONTRIBUTION:
0

GOLDEN:
EXCLUDED

================================
READS
================================

FINANCE HUB BEFORE:
O(all orders in period)

AFTER:
O(completed candidates + first page 40) — exact live counts **NOT_MEASURED** (depends on dataset)

RECONCILIATION BEFORE:
O(year all orders)

AFTER:
O(completed candidates)

SETTLEMENTS BEFORE:
200 live

AFTER:
40 live (+ optional older pages / ≤200 maps)

READ REDUCTION:
architecture: large (completed-only vs all-status); live % **NOT_MEASURED**

================================
N+1
================================

FINANCE N+1 BEFORE:
trip labels from order snapshots (no per-row get)

AFTER:
unchanged presentation path (no new N+1)

================================
INDEXES
================================

NEW INDEXES REQUIRED:
halh+data_order; Rev_dolh+halh+data_order (in source JSON)

DEPLOYED PROD:
NO

================================
TIMINGS
================================

ACCOUNTANT WARM:

FINANCE FIRST DATA:
NOT_MEASURED

RECONCILIATION FIRST DATA:
NOT_MEASURED

SETTLEMENTS FIRST DATA:
NOT_MEASURED

SUMMARY TIMES:
NOT_MEASURED

MEASUREMENT SOURCE:
code-path + unit tests (no Chrome HAR this pass)

================================
REGRESSION
================================

F2:
PASS

B1:
PASS

B2:
PASS

PERF-P1:
PASS

COUNTRY SCOPE:
PASS

================================
TESTS
================================

ANALYZE:
PASS

P2A:
PASS

FINANCE:
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

PRODUCTION DATA MUTATIONS:
0

PRODUCTION DEPLOY:
NO

CUSTOMER:
UNCHANGED

DRIVER:
UNCHANGED

================================
FINAL
================================

PERF-P2A:
READY_FOR_HUMAN_QA

NEXT:
PERF-P2B

STOP.
