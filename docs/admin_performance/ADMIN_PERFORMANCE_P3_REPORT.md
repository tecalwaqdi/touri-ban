# TOURi TAXI — ADMIN PERFORMANCE P3 REPORT

**MODE:** Shared Finance repository + request coalescing + safe session cache  
**NO production deploy** · **NO financial writes** · **NO F1/F2/B1 semantic change**

---

## BASE

| Item | Value |
|---|---|
| Base | `recovery/admin-performance-p2a-finance-queries` @ `72277ea` (P2A-H) / impl `9f9d6df` |
| Branch | `recovery/admin-performance-p3-finance-repository` |
| Preview channel | `admin-perf-p3` |
| Preview URL | https://tutorial-multi-language-70gx4j--admin-perf-p3-584a0e1t.web.app/admin/ |

---

## A — Request waterfall (pre-P3 code audit)

### Finance Hub (`AccountantFinanceLoader.load` → thisMonth)

| # | CALLER | COLLECTION | PURPOSE | CLASS | DUP? | FIRST DATA? | SUMMARY? | CACHEABLE |
|---|---|---|---|---|---|---|---|---|
| 1 | `FinanceOrderQuery.fetchModernPage` | `order` | first useful modern completed page | PRIMARY ROW | — | YES | NO | YES |
| 2 | `scanCompletedCandidates` modern chunk(s) | `order` | full modern completed candidates | SUMMARY QUERY | **DUP of #1 first page** | NO | YES | YES |
| 3–4 | legacy `halh` ∈ {مكتمل, completed} chunks | `order` | legacy completion candidates | LEGACY FALLBACK | — | NO | YES | YES |
| 5… | `_countOpenSettlements` pages ≤500 | `financial_settlements` | open settlement alert count | SETTLEMENT QUERY | overlaps maps | NO | YES | YES |
| shell | AdminLayout / auth / profile / scope | various | session bootstrap | AUTH/SCOPE | — | often first HTTP | NO | separate |

**Why ~11–12 HTTP:** duplicate modern page+#2, 2 legacy equality scans, multi-page settlement open count, plus shell Firestore.

### Reconciliation (`loadOrdersForCurrentScope` + `loadSettlementsMaps`)

Same modern+legacy pattern for **thisYear**, plus settlements maps ≤200 (chunks of 40). Parallel settlements + orders. Early B1 on first page; full B1 after scan.

**Why ~9–10:** modern page + modern scan dup + 2 legacy + ~1–5 settlement map pages + shell.

---

## P3 architecture

### Shared repository

`AdminFinanceRepository` (`lib/core/finance/admin_finance_repository.dart`)

Pipeline unchanged:

Firestore source → **AdminFinanceRepository** → frozen F1/F2/B1 → UI

### Wins implemented

1. **Unified completed scan** — first modern chunk = first useful rows (no separate `fetchModernPage` + full modern re-scan).
2. **In-flight coalescing** — same cache key → one Future.
3. **Session source cache** — TTL **45s**, max **24** LRU entries; key = `uid|role|scope|kind|range|country|driver`.
4. **Settlements maps shared** — Hub open-count derived from maps (no second ≤500 walk).
5. **B1 memo** — same order/settlement fingerprint skips reclassification.
6. **Label cache** — `AccountantFinanceLabels.countryHumanAr` via repository (presentation only).
7. **Logout** — `AdminSessionCleanup` → `clearSession()`.
8. **Settlement live change** — fingerprint change → `invalidateSettlements()`.
9. **Manual refresh** — Hub/Agent/Reports/Recon `forceRefresh: true` on refresh.

### Money Movement

`AdminFinanceChannelsWidget` still uses `FinanceCompanyService` (diagnostic / F3-A caution). Accountant primary money table remains Finance Hub via repository.

---

## CACHE POLICY

| Kind | Policy |
|---|---|
| Completed scan / settlements maps | TTL **45s**, LRU max **24**, session-scoped keys |
| Display labels | TTL **10m**, max **200** |
| Failures | **not** sticky-cached |
| Live settlements first page | unchanged P1/P2A stream (not long-cached) |

---

# TOURi TAXI — ADMIN PERFORMANCE P3 REPORT

BASE: P2A-H `72277ea` / P2A impl `9f9d6df`

BRANCH: `recovery/admin-performance-p3-finance-repository`

COMMIT: 

PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p3-584a0e1t.web.app/admin/

================================
REPOSITORY
================================

SHARED FINANCE REPOSITORY:
AdminFinanceRepository

CACHE POLICY:
session-scoped source + label LRU; forceRefresh / logout / settlement stream invalidate

TTL:
45s finance source; 10m labels

MAX ENTRIES:
24 source / 200 labels

IN-FLIGHT COALESCING:
YES

LOGOUT INVALIDATION:
PASS

SCOPE INVALIDATION:
PASS (key includes country/global scope)

================================
QUERY STARTS
================================

FINANCE HUB BEFORE:
11–12

AFTER:
~9 warm (cold ~13); dedicated cache revisit 13→9

RECONCILIATION BEFORE:
9–10

AFTER:
~8 warm

DUPLICATE LOGICAL STARTS:
0 for unified modern page+scan within one load; cross-route period mismatch (Hub thisMonth vs Recon thisYear) still separate keys by design

================================
CACHE
================================

FINANCE HUB RETURN HIT:
PARTIAL (finance source coalesced/cached; shell still ~9 Firestore HTTP)

RECONCILIATION REUSE:
settlements maps shared with Hub when same session; orders keyed by thisYear separately

LABEL CACHE:
YES (country presentation)

CROSS-USER LEAK:
0 (session clear on logout)

CROSS-COUNTRY CACHE LEAK:
0 (scope in key; unit)

================================
REAL BROWSER TIMINGS
================================

MEDIAN WARM RUNS:
3

FINANCE FIRST DATA:
4697 ms

FINANCE SUMMARY:
8569 ms (quiet-proxy)

RECONCILIATION FIRST DATA:
4014 ms

RECONCILIATION SUMMARY:
8148 ms

SETTLEMENTS FIRST DATA:
4824 ms

BACK TO FINANCE HUB:
3964 ms (same-session after Recon; starts 9)

CACHE HUB REVISIT:
4165 ms first / 9 starts (vs cold 7382 ms / 13 starts)

MEASUREMENT:
REAL_BROWSER (first Firestore HTTP after route goto)

================================
IMPROVEMENT
================================

FINANCE FIRST:
3582 → 4697 ms (−31% — **not improved**; network/shell variance; still SLOW)

RECONCILIATION:
3285 → 4014 ms (−22% wall; starts 9–10 → 8)

SETTLEMENTS:
3309 → 4824 ms

FINANCE SUMMARY:
8080 → 8569 ms

RECONCILIATION SUMMARY:
8391 → 8148 ms

Hub Firestore starts:
11–12 → ~9

Note: wall “first useful” remains dominated by **non-finance shell Firestore** (auth/profile/layout). Repository removed intra-load modern duplicate + settlement open walk; ≤1500 ms target **not met**.

================================
SEMANTICS
================================

F2:
PASS

B1:
PASS

B2:
PASS

QA:
PASS

SCOPE:
PASS

SUMMARY PAGE BUG:
0 (P2A 100/25 test still PASS)

================================
TESTS
================================

ANALYZE:
PASS (touched files)

P3:
PASS (coalesce + repository/session)

P2A:
PASS

FINANCE:
PASS (F2/B1/B2 sampled)

NEW FAILURES:
0

================================
SAFETY
================================

FINANCIAL WRITES:
0

PRODUCTION DATA MUTATION:
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

PERF-P3:
READY_FOR_HUMAN_QA

FINANCE PERFORMANCE:
SLOW

NEXT:
FIX_P3

STOP.

---

## NEXT (FIX_P3 focus)

Remaining wall time is largely **Admin shell Firestore** on every finance route (≈9 HTTP before/around first paint), not duplicate finance candidate loaders. FIX_P3 should trim accountant shell/profile/layout reads without changing finance semantics, then re-benchmark ≤1500 ms / ≤500 ms cached back-nav.
