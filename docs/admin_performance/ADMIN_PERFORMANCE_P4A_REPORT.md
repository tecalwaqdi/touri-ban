# TOURi TAXI — ADMIN PERFORMANCE P4A REPORT

**MODE:** Finance critical-path split + summary pipeline optimization  
**NO production deploy** · **NO financial writes** · **NO F1/F2/B1 semantic change**

---

## BASE

| Item | Value |
|---|---|
| Base | P3F `fb5ab5b` / tip `a569b9d` |
| Branch | `recovery/admin-performance-p4a-finance-critical-path` |
| Preview channel | `admin-perf-p4a` |
| Preview URL | https://tutorial-multi-language-70gx4j--admin-perf-p4a-g8gel2s5.web.app/admin/ |

---

## A — Critical path (pre-change, warm Preview evidence + code)

### Finance Hub (before P4A)

| STEP | CALLER | BLOCKS FIRST DATA | BLOCKS SUMMARY | NOTES |
|---|---|---|---|---|
| modern first chunk | `scanCompletedCandidates` | YES | NO | ~530ms direct REST; UI awaited scan orchestration |
| remaining modern chunks | same scan | NO | YES | |
| legacy `halh` ∈ {مكتمل, completed} | same scan | NO | YES | |
| F1 `AccountantFinanceReadModel.aggregate` | `loadHubBundle` | NO | YES | CPU tiny |
| settlements maps ≤200 | **serial after scan** | NO | YES | delayed summary |
| open-settlement KPI | derived from maps | NO | YES | |
| display labels | order snapshot / local | NO | NO | driver name on order |

**Missing ~3.5s after ~530ms query:** route enter → Flutter body mount → first Firestore Listen/HTTP → modern page → setState. Prior measurement used **first Firestore HTTP** as first-data proxy (includes non-row traffic). Summary still waited for full scan + serial settlements.

### Reconciliation (before)

| STEP | BLOCKS FIRST DATA | NOTES |
|---|---|---|
| year completed scan first chunk | YES | |
| B1 on first page with **empty settlements** | YES (wrong) | settlement status could flip later |
| full year scan | SUMMARY | |
| settlements maps | SUMMARY (parallel start) | |
| full B1 | SUMMARY | |

### Settlements (before)

| STEP | BLOCKS FIRST LIST | NOTES |
|---|---|---|
| live `snapshots` first page 40 | YES | P1 stable stream |
| period maps ≤200 | NO for list | but KPIs used **page as temporary totals** |

---

## P4A implementation

1. **`loadModernFirstPage` / `loadHubFirstPage`** — coalesced `modern_page` key (P3).
2. **Completed scan seeds** from first page (`seedModernOrders` + `modernStartAfter`) — no duplicate first modern get.
3. **Hub/Agent:** first page → paint rows → **then** start summary bundle (scan ∥ settlements maps → F1).
4. **Recon:** `loadReconciliationFirstPage` = modern page ∥ settlements maps → B1 (never classify with `[]`).
5. **Full recon summary** independent background Future; metric chips show `—` until full result.
6. **Settlements KPIs:** `—` until period maps ready (no page-as-summary).
7. **Error isolation:** row failure vs summary failure separate on Hub/Recon.
8. **Agent UID:** no truncated UID as agent label (em dash).
9. **B1 memo** retained for identical full inputs.

---

# TOURi TAXI — ADMIN PERFORMANCE P4A REPORT

BASE: P3F `fb5ab5b` / tip `a569b9d`

BRANCH: recovery/admin-performance-p4a-finance-critical-path

COMMIT: `49ad5a56d8d8d609666ca5a5b6b44a737af0dd2c`

PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p4a-g8gel2s5.web.app/admin/

================================
CRITICAL PATH
================================

FINANCE BLOCKERS BEFORE FIRST DATA:
full completed scan (modern+legacy) + serial settlements maps + F1 before bundle Future; UI early rows existed but summary/pipeline still coupled; first-data proxy = any Firestore HTTP

AFTER:
modern_page only → trip rows; summary/settlements after first page

RECON BLOCKERS BEFORE FIRST DATA:
year scan chunk + B1 without settlements

AFTER:
modern_page ∥ settlements maps → B1 first page; full year scan for summary only

SETTLEMENT BLOCKERS:
live first page OK; KPIs painted from page while maps loading

AFTER:
list from live stream; KPIs `—` until period maps

================================
QUERY BUDGET
================================

FINANCE CRITICAL PATH:
1 app start — `modern_page` (coalesced)

FINANCE BACKGROUND:
completed_scan continuation (legacy + further modern) + settlements_maps (parallel inside bundle) + F1 CPU

RECON CRITICAL PATH:
≤2 — modern_page + settlements_maps (then B1 local)

RECON BACKGROUND:
completed_scan (thisYear) + full B1

SETTLEMENT CRITICAL PATH:
1 — live settlements first page listener

BACKGROUND:
settlements_maps period summary

================================
CPU
================================

B1 40 ROWS:
≪100 ms expected (classification; not network) — empty×50 unit <500 ms total

B1 FULL:
network-dominated; memo skips identical fingerprint recompute

F1/F2 SUMMARY CPU:
tiny vs wall (aggregate over in-memory orders)

NETWORK/WAIT:
~3.5–8 s (Firestore + Listen; measurement proxy)

RENDER:
secondary after data

================================
SERVER AGGREGATE AUDIT (S)
================================

METRIC: completedTripCount / money totals (F1)
CURRENT METHOD: client scan + frozen aggregate
SERVER AGG SAFE: NO
WHY: QA exclusion + legacy fallback + frozen completion + amount resolution must match F1 exactly; count() alone is not identical

METRIC: open settlements remaining
CURRENT METHOD: bounded maps walk
SERVER AGG SAFE: NO (without identical open-status predicate + QA filter)
WHY: status set is multi-valued; QA settlements excluded

METRIC: B1 reconciled / unsettled / …
CURRENT METHOD: full classification scan
SERVER AGG SAFE: NO
WHY: MATERIALIZED/WRITE-TIME AGGREGATE MAY HELP (future phase only)

================================
REAL BROWSER
================================

MEDIAN:
3 warm runs

MEASUREMENT:
firestore_network_first_response_and_quiet (Flutter canvas — no reliable DOM first-paint)

FINANCE FIRST:
4052 ms

FINANCE SUMMARY:
8452 ms

RECON FIRST:
5037 ms

RECON SUMMARY:
10446 ms

SETTLEMENTS FIRST:
4336 ms

CACHED BACK HUB:
3186 ms (dedicated cache-nav first Firestore)

================================
IMPROVEMENT
================================

P3F FINANCE:
4089 → 4052 ms (~flat; network proxy)

P3F RECON:
3780 → 5037 ms (slower: first rows now wait for settlement membership — correctness)

P3F SETTLEMENT:
4275 → 4336 ms (~flat)

P3F FINANCE SUMMARY:
7983 → 8452 ms (~flat / env)

P3F RECON SUMMARY:
7409 → 10446 ms (year scan + maps; variance)

NOTE:
Network-first-response proxy remains multi-second (Listen/route wake). Architecture now allows true first rows without waiting for summary; canvas paint not instrumented.

================================
VISUAL
================================

WHOLE PAGE BLOCKED BY SUMMARY:
0 (Hub/Recon/Settlements split loading domains)

FAKE ZERO:
0 (pending summary / period KPIs use — )

RAW UID PLACEHOLDER:
0 (agent label em dash; driver uses snapshot name or —)

DUPLICATE ROWS:
0 (modern+legacy path+dedupe unchanged)

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

================================
TESTS
================================

ANALYZE:
PASS (touched finance/UI files)

P4A:
PASS

FINANCE:
PASS (F1/F2/B1/B2/P2A/P3/P3F sampled)

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

PERF-P4A:
READY_FOR_HUMAN_QA

FIRST-DATA PERFORMANCE:
SLOW

SUMMARY PERFORMANCE:
SLOW

NEXT:
SUMMARY_ARCHITECTURE

STOP.
