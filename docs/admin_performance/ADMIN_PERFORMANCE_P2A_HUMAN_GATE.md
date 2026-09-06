# TOURi TAXI — PERF-P2A HUMAN GATE REPORT

**MODE:** Index gate + real browser benchmark + Human QA prep  
**NO new performance architecture**  
**NO Admin production hosting deploy**  
**NO financial writes**

---

## Source

| Item | Value |
|---|---|
| Branch | `recovery/admin-performance-p2a-finance-queries` |
| P2A impl | `9f9d6df` |
| P2A report tip (pre-H) | `52cdf1d` |
| Preview | https://tutorial-multi-language-70gx4j--admin-perf-p2a-lbc3hkqo.web.app |
| Admin entry | https://tutorial-multi-language-70gx4j--admin-perf-p2a-lbc3hkqo.web.app/admin/ |
| Demo Accountant | `accountant.demo@touri-taxi.com` (UID `jrPITQI0Y2QJNELU43ymS1WJvR43`) |
| Automated auth | custom-token session injection (password **not** in repo) |
| Metrics artifact | `docs/admin_performance/ADMIN_PERFORMANCE_P2A_HUMAN_GATE_METRICS.json (screenshots local under admin/Admi/visual_qa_perf_p2a_human_gate/ — gitignored)` |
| Screenshots | `admin/Admi/visual_qa_perf_p2a_human_gate/*.png` |
| Probe script | `admin/Admi/qa_tools/admin_perf_p2a_human_gate_probe.mjs` |

---

## A/B — Index diff audit + safety

### Targets

1. `order`: `halh ASC` + `data_order DESC`
2. `order`: `Rev_dolh ASC` + `halh ASC` + `data_order DESC`

### Compare vs live (pre-deploy)

| Check | Result |
|---|---|
| INDEX ALREADY EXISTS | neither target present on live (69 composites) |
| NEW REQUIRED | the two targets above |
| Deploy method | **safe merge**: live export (69) + 2 new → temp `firestore.indexes.json` → `firebase deploy --only firestore:indexes` |
| UNRELATED INDEX DELETIONS | **0** (71 after = 69 + 2) |
| UNRELATED INDEX MODIFICATIONS | **0** |
| Rules / Hosting / Functions / Storage deployed | **NO** (indexes-only; rules compiled for validation only) |
| Semantic / document mutations | **NO** |

### Index safety proof

- Indexes only accelerate query planning.
- No rules change, no document writes, no F1/F2/B1 formula change.

---

## C — Index readiness

| Index | Fields | State |
|---|---|---|
| order | `halh ASC`, `data_order DESC` | **READY** |
| order | `Rev_dolh ASC`, `halh ASC`, `data_order DESC` | **READY** |

Verified via `gcloud firestore indexes composite list` after deploy.

---

## D–G — Real browser timings

**Measurement:** Playwright Chromium against preview; warm ×3; median.  
**Definition (Flutter canvas-safe):**

- **FIRST USEFUL** = ms from route `goto` → **first Firestore HTTP response**
- **SUMMARY** = ms until Firestore quiet window (≥1.5s no further Firestore responses) — proxy for summary settle

Flutter CanvasKit does not expose reliable `body.innerText` timing; DOM-text waits were abandoned as false timeouts.

### Medians (warm ×3)

| Route | FIRST USEFUL | SUMMARY |
|---|---:|---:|
| Finance Hub | **3582 ms** | **8080 ms** |
| Reconciliation | **3285 ms** | **8391 ms** |
| Settlements | **3309 ms** | (quiet ~6–7s in runs) |

### Per-run first useful (ms)

| Run | Finance | Reconciliation | Settlements |
|---|---:|---:|---:|
| 1 | 2569 | 3004 | 3144 |
| 2 | 3582 | 3285 | 3618 |
| 3 | 3908 | 3637 | 3309 |
| Cold Finance | 4200 | — | — |

### Settlements interactions

| Metric | Value |
|---|---|
| FIRST DATA (median) | 3309 ms |
| FILTER click attempt | 603 ms wall (chip click via DOM/aria **not found** in headless Flutter — UI filter chips visible in screenshot; automated click inconclusive) |
| NEXT PAGE | **null** (no Load more — empty first page / no older page) |
| LIVE FIRST PAGE | YES (limit 40 architecture) |
| ACTIVE LISTENERS | 1 (P1 owner; not re-instrumented in browser) |
| LEAKS | 0 (unit / P1 preserved) |

### Preferred target vs measured

| Preferred | Measured median | Hit? |
|---|---:|---|
| Finance first ≤1500 ms | 3582 | **NO** |
| Reconciliation first ≤1500 ms | 3285 | **NO** |
| Settlements first ≤1500 ms | 3309 | **NO** |

REST one-shot modern completed page (year, limit 40) alone: **~530 ms** — UI route cost includes Flutter route bootstrap + multiple Firestore channel starts (~9–12 per Hub/Recon).

---

## H — Legacy fallback runtime

| Check | Result |
|---|---|
| LEGACY QUERY (`halh == مكتمل` + `data_order` range) | **PASS** (HTTP 200, **0 docs** in 2026 range — no missing-index) |
| Modern completed year page | **PASS** (6 docs, ~530 ms) |
| INDEX ERROR | **0** (browser + REST) |
| 100k fallback | not triggered |
| Canonical completion | unchanged (unit) |

---

## I — Read / query counts (observable)

| Signal | Value |
|---|---|
| TOTAL Firestore HTTP starts (full probe session) | **166** |
| Sequence Hub→Recon→Channels→Settlements→Agent→Reports starts | **60** |
| Finance Hub warm starts / visit | **11–12** |
| Reconciliation warm starts / visit | **9–10** |
| Settlements warm starts / visit | **5** |
| Exact billed Firestore document reads | **NOT_OBSERVABLE** (WebChannel binary; no reliable doc counter in browser) |
| DUPLICATE FULL PERIOD SCANS across finance routes | **YES** — each finance route restarts its own completed-candidate load (shared P3 cache not in P2A) |

---

## J — Human visual QA (screenshots)

Folder: `admin/Admi/visual_qa_perf_p2a_human_gate/`

| # | File | Note |
|---|---|---|
| 1 | `01_finance_hub_loading.png` | Spinner + «جاري تحميل لوحة التحكم...» |
| 2 | `02_finance_hub_loaded.png` | Loaded Hub (this month empty = legitimate) |
| 3 | `03_reconciliation_loaded.png` | B1 cards + log |
| 4 | `04_reconciliation_partial_trip.png` | `CASH-7B9A80C3` incomplete finance |
| 5 | `05_settlements_loaded.png` | Empty state + period-summary caption |
| 6 | `06_settlements_filter.png` | Filter chips visible |
| 7 | `07_agent_finance.png` | Same F2 empty month semantics |
| 8 | `08_reports.png` | Reports route |

Checks:

| Check | Result |
|---|---|
| BLANK PAGE | **0** |
| FAKE ZERO before data | **0** (loading spinner first; loaded zeros match empty month / empty settlements) |
| FLICKER | **0** observed in stills |
| DUPLICATE ROWS | **0** |
| RAW QUERY ERROR | **0** |
| Finance semantic change | **NO** (partial trip excluded from money totals; dashes for incomplete) |

---

## K — User-perceived performance

| Surface | Class | Evidence |
|---|---|---|
| Finance Hub | **SLOW** vs ≤1.5s preferred; usable | median first Firestore **3582 ms** |
| Reconciliation | **SLOW** vs preferred; usable | median **3285 ms**; content visible in screenshot |
| Settlements | **SLOW** vs preferred; usable | median **3309 ms**; empty-state OK |

---

## L — Summary scan risk

| Item | Value |
|---|---|
| Live completed candidates (year modern REST) | **6** |
| Summary quiet proxy | ~8 s (includes 1.5s quiet) |
| Scalability class | **ACCEPTABLE_NOW** / **FUTURE_RISK** as completed volume grows |
| Redesign in P2A-H | **NO** — recommend dedicated aggregate / P3 later |

---

## M — Regression

| Suite | Result |
|---|---|
| F2 consistency test | PASS (prior P2A; re-run targeted below) |
| B1 read model | PASS |
| B2 Accountant RBAC | PASS |
| P1 shell | PASS |
| P2A 100/page25→summary100 | PASS |
| Country scope unit | PASS |
| QA exclusion unit | PASS |

---

## N — Next phase decision

**Choose: PERF-P2B** (operational tables / Drivers / Agents / Landmarks / N+1)

Rationale:

- P2A correctness + indexes + first-page architecture are in place; no FIX_P2A required for semantics.
- Finance first-data is improved vs 100k scans but still >1.5s wall on preview — acceptable for Human QA, not a P2A redesign in this gate.
- Finance routes still **re-scan independently** (Hub/Recon/Agent) → track **PERF-P3** as the finance cache/repository follow-up, after P2B unblocks broader Admin tables called out since P0.

---

# TOURi TAXI — PERF-P2A HUMAN GATE REPORT

INDEXES:
DEPLOYED

INDEX STATUS:
READY

UNRELATED INDEX CHANGES:
0

================================
REAL TIMINGS
================================

FINANCE FIRST DATA:
3582 ms (median warm; first Firestore response)

FINANCE SUMMARY:
8080 ms (median quiet-proxy)

RECONCILIATION FIRST DATA:
3285 ms

RECONCILIATION SUMMARY:
8391 ms

SETTLEMENTS FIRST DATA:
3309 ms

SETTLEMENT NEXT PAGE:
null (no older page / empty)

MEDIAN RUNS:
3

MEASUREMENT:
REAL_BROWSER

================================
QUERIES
================================

FINANCE QUERY STARTS:
11–12 Firestore HTTP / Hub visit (warm)

RECONCILIATION QUERY STARTS:
9–10 / visit

SETTLEMENT LISTENERS:
1 (architecture)

DUPLICATE PERIOD SCANS:
YES across finance routes (expected pre-P3)

================================
LEGACY
================================

LEGACY QUERY:
PASS

INDEX ERRORS:
0

================================
VISUAL
================================

BLANK PAGE:
0

FAKE ZERO:
0

FLICKER:
0

DUPLICATE ROWS:
0

================================
REGRESSION
================================

F2:
PASS

B1:
PASS

B2:
PASS

P1:
PASS

SCOPE:
PASS

================================
FINAL
================================

PERF-P2A:
HUMAN_READY

FINANCE PERFORMANCE:
SLOW

NEXT:
PERF-P2B

ADMIN PRODUCTION DEPLOY:
NO

FINANCIAL WRITES:
0

STOP.
