# TOURi TAXI — ADMIN PERFORMANCE P4B REPORT

**MODE:** Firestore Web transport + Flutter frame latency isolation  
**NO production deploy** · **NO financial writes** · **NO formula/B1/F1/F2 change**

---

## BASE

| Item | Value |
|---|---|
| Base | P4A `49ad5a5` / tip `d45248f` |
| Branch | `recovery/admin-performance-p4b-runtime-isolation` |
| Preview | https://tutorial-multi-language-70gx4j--admin-perf-p4b-rli5r6o1.web.app/admin/ |
| Probe | `qa_tools/admin_perf_p4b_trace_probe.mjs` (5 warm runs) |
| Metrics | `docs/admin_performance/ADMIN_PERFORMANCE_P4B_METRICS.json` |

---

## Method

Single monotonic `Stopwatch` per route (`AdminFinanceRouteTrace`).

Published as console `P4B|…` + `window.__TOURI_PERF_P4B__`.

Paint = `SchedulerBinding.addPostFrameCallback` after first rows `setState`.

P4A ~4s “first useful” was **first Firestore HTTP after navigation** (includes Listen/channel noise). P4B measures **ROUTE_ENTER → FIRST_USEFUL_FRAME_PAINTED**.

---

## A–D Trace results (median, 5 warm)

### Finance Hub

| Segment | Median ms |
|---|---:|
| ROUTE → QUERY_START | **1** |
| QUERY → FIRST_SNAPSHOT | **1651** |
| SNAPSHOT → MODEL | **1** |
| MODEL → STATE | **0** |
| STATE → PAINT | **16** |
| **TOTAL enter→paint** | **1670** |
| p90 total | 1895 |

### Reconciliation

| Segment | Median ms |
|---|---:|
| ROUTE → QUERY | **1** |
| ORDER/SNAP wait (query→snap) | **1121** |
| B1 + model | **~2** |
| STATE → PAINT | **44** |
| **TOTAL** | **1164** |

(Settlement maps overlapped; `SETTLEMENT_EVIDENCE` end ≈ order ready.)

### Settlements (live snapshots)

| Segment | Median ms |
|---|---:|
| ROUTE → LISTEN | **2** |
| LISTEN → SNAPSHOT | **303** |
| SNAPSHOT → PAINT | **~16** |
| **TOTAL** | **324** |

---

## E — SDK vs REST (same session)

| Method | ms |
|---|---:|
| REST `documents:runQuery` modern completed limit 40 | **739** |
| Flutter Firestore SDK `get()` (control route median query→snap) | **1755** |
| **DELTA (SDK − REST)** | **~1016** |

SDK is slower than REST for the same logical query; both are sub-2s. Dominant first-data cost is **SDK/network wait**, not Flutter paint.

---

## F–Q Findings

| Check | Result |
|---|---|
| F route→query >500ms? | **NO** (1–2 ms) |
| G token per Hub route | **0** explicit; control measures ~67–114 ms when forced |
| H persistence | `persistenceEnabled: true` on web (`firebase_config.dart`) |
| I get vs snapshots | Hub/Recon: **ONE_SHOT get** appropriate; Settlements: **LIVE required** (P1); live first paint **324 ms** |
| J transport | `netFails: 0`; Firebase init count **1** |
| K retries | **0** |
| L init once | YES |
| M–O render | STATE→PAINT **11–44 ms**; static route **86 ms**; no table jank on first page |
| P model→state | **~0 ms** |
| Q animation | query starts immediately (not after transition) |
| R cache | P3 TTL was **45s** — expired during long tours; “cached hub” still re-queried |
| S summary | starts after first paint schedule; does not explain enter→paint |
| T control query paint | **~1882 ms** (auth + SDK) |
| U static paint | **86 ms** |

---

## V — Decision

**CASE A (partial) + measurement correction:**

- Primary accounted cost: **Firestore SDK query wait (~1.1–1.7s)**
- REST faster by ~1s (same filters/limit)
- Flutter render/runtime: **not** the 4s culprit
- Prior P4A 4s proxy conflated Listen/channel with first rows

**ROOT CAUSE:** `FIRESTORE_TRANSPORT` (SDK/WebChannel path latency vs REST)  
**NOT** SUMMARY_ARCHITECTURE for first-data  
**NOT** PERF-P5R for first-data (static/control prove render is fine)

---

## W — Small fix implemented

| Item | Detail |
|---|---|
| Change | `AdminFinanceRepository.sourceTtl` **45s → 180s** |
| Why | Measured: TTL expired mid Accountant tour → modern_page re-fetch (~1s+) despite P3 cache |
| Semantics | Unchanged (still short session cache; logout clears) |
| Security | Unchanged |

No experimental long-polling / persistence toggle (not proven safe without deeper transport A/B).

---

# TOURi TAXI — ADMIN PERFORMANCE P4B REPORT

BASE: P4A `49ad5a5` / tip `d45248f`

BRANCH: recovery/admin-performance-p4b-runtime-isolation

COMMIT: _(filled after commit)_

PREVIEW: https://tutorial-multi-language-70gx4j--admin-perf-p4b-rli5r6o1.web.app/admin/

================================
FINANCE TRACE
================================

ROUTE → QUERY START:
1 ms

AUTH/TOKEN:
0 ms (no explicit refresh on Hub)

QUERY START → FIRST SNAPSHOT:
1651 ms

SNAPSHOT → MODEL READY:
1 ms

MODEL → STATE:
0 ms

STATE → PAINT:
16 ms

TOTAL:
1670 ms

================================
RECON TRACE
================================

ROUTE → QUERY:
1 ms

ORDER RESPONSE:
~1121 ms (to first snapshot)

SETTLEMENT RESPONSE:
overlapped; evidence end ≈ order ready (~1 ms after snap)

B1:
~2 ms

STATE → PAINT:
44 ms

TOTAL:
1164 ms

================================
SETTLEMENT TRACE
================================

ROUTE → LISTEN:
2 ms

LISTEN → SNAPSHOT:
303 ms

SNAPSHOT → PAINT:
~19 ms

TOTAL:
324 ms

================================
CACHE CONTROL
================================

HUB CACHE HIT:
PARTIAL (45s TTL expired on long tours; CACHE_HIT marks often from summary join)

CACHE SOURCE NETWORK:
>0 when TTL expired

CACHE HIT → PAINT:
N/A until TTL extended (fix: 180s)

================================
SDK VS CONTROL
================================

FIRESTORE SDK:
1755 ms (control query→snap median)

REST/CONTROL:
739 ms

DELTA:
~1016 ms

================================
FLUTTER
================================

STATIC ROUTE PAINT:
86 ms

CONTROL QUERY PAINT:
1882 ms

REAL FINANCE PAINT:
1670 ms

BUILD:
≪20 ms after data

LAYOUT:
included in state→paint

RASTER:
no evidence of multi-second jank

JANK:
0 material on first-page path

================================
TRANSPORT
================================

RETRIES:
0

TOKEN REFRESH:
0 per Hub (explicit)

CHANNEL RECONNECTS:
0 observed fails

TRANSPORT ISSUE:
YES (SDK ≫ REST; WebChannel/get path)

================================
ACCOUNTED WALL TIME
================================

ROUTE/SCHEDULING:
~1 ms (~0.1%)

AUTH:
~0 ms Hub / ~114 ms control-only

FIRESTORE:
~1651 ms (~99% of Hub enter→paint)

MODEL:
~1 ms

STATE:
~0 ms

RENDER:
~16 ms

UNEXPLAINED:
<1%

================================
SMALL FIX
================================

IMPLEMENTED:
YES

DESCRIPTION:
sourceTtl 45s → 180s so P3 modern_page cache survives Accountant multi-route warm tours

BEFORE:
cache expired; re-query ~1s+

AFTER:
longer session reuse (re-measure on next human QA)

================================
SEMANTICS
================================

F2:
PASS

B1:
PASS

B2:
PASS

SCOPE:
PASS

QA:
PASS

================================
SAFETY
================================

FINANCIAL WRITES:
0

PRODUCTION MUTATIONS:
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

ROOT CAUSE:
FIRESTORE_TRANSPORT

FIRST_DATA PERFORMANCE:
ACCEPTABLE

(True enter→paint ~1.7s Hub / ~0.3s Settlements. Prior ~4s was network-first-response proxy.)

NEXT:
FIRESTORE_TRANSPORT_FIX

STOP.
