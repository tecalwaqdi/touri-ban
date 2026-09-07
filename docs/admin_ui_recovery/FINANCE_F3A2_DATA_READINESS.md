# TOURi TAXI — FINANCE F3-A2 DATA READINESS REPORT

**BASE (F2 frozen):** `07e0af66f0624a921110c563acc007cf9f157e2b`  
**F3-A TIP:** `fa9e4d3` (`recovery/admin-finance-f3a-audit`)  
**BRANCH:** `recovery/admin-finance-f3a2-data-readiness`  
**COMMIT:** `148af113524451fa65a8c14666019de499f3bf14`  
**PROJECT:** `tutorial-multi-language-70gx4j`  
**SCOPE:** READ-ONLY AUDIT + REMEDIATION DESIGN — no mutation, no backfill execution, no deploy

---

## Method

| Item | Detail |
|---|---|
| Orders | Full field dump of `status_code==completed` non-`fin*_` docs |
| Write path | `admin/ara_oatan_app/firebase/functions/ngenius_payments.js` `createCashBooking` + online paid create |
| Cash | `admin/Admi/firebase/functions/cash_collection_realization.js` + Driver `confirmCashCollection` |
| Settlement eligibility | `financial_accounting_v2.js` `eligible` + `settlement_ledger.js` |
| Agent | `agent_order_snapshot.js` (FIN-9) |
| Tests | `flutter analyze` finance files; F1 + QA fixture tests PASS |

---

## PART A — The two non-`fin*` completed trips

### Important reclassification

| Order | F3-A label | F3-A2 label |
|---|---|---|
| `03392f80…` | “real” | **GOLDEN / functional_test** (`golden_cycle=TOURi_GOLDEN_1`, `functional_test=true`) — **not production traffic**; missed by `AdminQaFixture` prefixes |
| `7b9a80c3…` | “real” | **Non-fixture production-like** cash booking (`created_by_function=true`, no golden markers) |

Both share the **same money-field write gap**.

---

### TRIP 1 — Golden cycle (exclude from live KPIs going forward)

| Item | Value |
|---|---|
| ORDER ID | `03392f80a1007caa396054888b200465fb2c3c23476d9c6f8a81d6421d756647` |
| DISPLAY / IDorder | `CASH-03392F80A1` |
| COUNTRY | `countries/saudi_arabia` |
| DRIVER | `user/DZbM2HXJeNTCwiVUtahiaT79paH2` (`GOLDEN Driver 1`) |
| CUSTOMER | `user/t11H0KfxuRMQF5KmbmAPSOvBkbt2` (`GOLDEN Customer 1`) |
| AGENT AT TRIP TIME | **MISSING** (no snapshot fields) |
| STATUS_CODE | `completed` |
| PAYMENT METHOD | `Cash` |
| COMPLETION | `completedAt` `2026-08-24T11:26:22.279Z` |
| Markers | `functional_test=true`, `golden_cycle=TOURi_GOLDEN_1`, `created_by_function=true` |

| Field | Value | Class |
|---|---|---|
| `total` | 200 | PRESENT |
| `amount_halalas` | 20000 | PRESENT |
| `total_app` | 30 | PRESENT |
| `total_vat` | 0 | ZERO_EXPLICIT |
| `ksm` | 0 | ZERO_EXPLICIT |
| `SrSAAH` | 100 | PRESENT |
| `total_taim` | 2 | PRESENT |
| `total_mndob2` | — | **MISSING** |
| `total_mndob` | — | **MISSING** |
| `financial_snapshot` | — | MISSING |
| Agent snapshot fields | — | MISSING |
| `payment_status` | `pending_cash` | PRESENT |
| `cash_collection_status` | `pending` | PRESENT |
| Settlement refs | — | MISSING |
| Gateway / payment refs | — | MISSING / N/A (cash) |

**Financial status (F1 Hub):** PARTIAL  
**Recoverability (money):** see matrix — formula-safe when `ksm==0`  
**Disposition:** treat as **QA/golden fixture** (expand exclusion); do not count as production completed trip

---

### TRIP 2 — Production-like cash booking

| Item | Value |
|---|---|
| ORDER ID | `7b9a80c30646f77148cf443a15db766e65a6105f003565683ac1d35b0e9d04d3` |
| DISPLAY / IDorder | `CASH-7B9A80C306` |
| COUNTRY | `countries/saudi_arabia` |
| DRIVER | `user/RTfKF1RL2XRVMNltxAYDoj4ZxLK2` (`osama`) |
| CUSTOMER | `user/Mdw4ATgSmaQ6LUJ1lbFVkJDL90g1` (`Ara Watan`) |
| AGENT AT TRIP TIME | **MISSING** |
| STATUS_CODE | `completed` |
| PAYMENT METHOD | `Cash` / `TOURY_PAY_CASH` |
| COMPLETION | `completedAt` `2026-08-31T00:04:38.963Z` |
| Markers | `created_by_function=true` (no `functional_test` / `golden_cycle`) |

| Field | Value | Class |
|---|---|---|
| `total` | 50 | PRESENT |
| `amount_halalas` | 5000 | PRESENT |
| `total_app` | 7.5 | PRESENT |
| `total_vat` | 0 | ZERO_EXPLICIT |
| `ksm` | 0 | ZERO_EXPLICIT |
| `SrSAAH` | 50 | PRESENT |
| `total_taim` | 1 | PRESENT |
| `total_mndob2` | — | **MISSING** |
| `total_mndob` | — | **MISSING** |
| Agent snapshot | — | MISSING |
| `payment_status` | `pending_cash` | PRESENT |
| `cash_collection_status` | `pending` | PRESENT |
| Settlement | — | MISSING |

**Financial status (F1 Hub):** PARTIAL  
**Cash:** UNCOLLECTED (canonical pending — not operational omission of completion)

---

## PART B — Write-path root cause (proven)

### `total_mndob2` / `total_mndob`

| Item | Detail |
|---|---|
| EXPECTED WRITER | Server booking create should persist gross (`total_mndob2`) and driver net (`total_mndob`) from verified quote |
| ACTUAL WRITER | `exports.createCashBooking` in `ara_oatan_app/firebase/functions/ngenius_payments.js` (~L1127–1192) |
| WHAT IT WRITES | `total`, `amount_halalas`, `total_app`, `total_vat`, `ksm`, `SrSAAH`, cash pending fields… |
| WHAT IT OMITS | **`total_mndob2`, `total_mndob`** (and does not store `baseFareHalalas` as its own field) |
| ONLINE PATH | Paid N-Genius order create (~L934–999) **same omission** |
| Quote has | `baseFareHalalas`, `appFeeHalalas`, `vatHalalas`, `discountHalalas`, `amountHalalas` via `verifiedBookingAmount` |
| WHY MISSING | **Incomplete Cloud Function write path** (client-side omission of fields that exist in the verified quote) — not migration, not race, not naming mismatch on these two docs |

### `total` / `total_app` / `total_vat`

| Field | Writer | Status on both trips |
|---|---|---|
| `total` | `createCashBooking` ← `quote.amountHalalas/100` | PRESENT |
| `total_app` | ← `quote.appFeeHalalas/100` (15% of **base** fare) | PRESENT |
| `total_vat` | ← `quote.vatHalalas/100` | ZERO_EXPLICIT (country VAT off / 0) |

### Agent snapshot

| Item | Detail |
|---|---|
| EXPECTED WRITER | `syncAgentSnapshotOnOrderCreate` (FIN-9) on `order` create — Admi functions |
| ACTUAL ON THESE TRIPS | **No agent fields present** |
| WHY MISSING | **Not recoverable from trip doc.** Likely FIN-9 not yet live / not attributed at create time, or patch not applied. **Must not** invent from current SA agent (`JkYePqE6…`, 5%). |

---

## PART C — Historical recoverability

Immutable evidence **on the order at trip time**:

- `total`, `total_app`, `total_vat`, `ksm`, `amount_halalas`
- `SrSAAH`, `total_taim` (hourly base × hours ⇒ historical base fare)

`verifiedBookingAmount` contract (same function family):

- `amountHalalas = baseFareHalalas - discountHalalas`
- when `ksm==0` ⇒ `total == baseFare` (gross)

V2 engine already encodes (`financial_accounting_v2.js`):

- if `total_mndob2` missing and `ksm==0` and `total` present → `grossBase = customerPaid`
- if `total_mndob` missing and fees/VAT present and `ksm==0` → `driverNet = total - app - vat` (`DERIVED_FROM_TOTAL`, confidence **derived**)

| Field | Class | Evidence | Classification |
|---|---|---|---|
| `total_mndob2` | MISSING | `total` + `ksm==0`; also `SrSAAH * total_taim` equals `total` on both trips | **SAFE_TO_BACKFILL** (= `total`) with audit |
| `total_mndob` | MISSING | `total - total_app - total_vat` (all PRESENT; `ksm==0`) | **SAFE_TO_BACKFILL** |
| `total` / `total_app` / `total_vat` | PRESENT | — | **NO_ACTION** |
| Agent amount/rate/id | MISSING | none on order | **NOT_RECOVERABLE** (no trip-time snapshot) |
| Cash collected | pending | intentional uncollected | **NO_ACTION** (ops) |
| Gateway fee | N/A cash | — | **NO_ACTION** |

**Forbidden:** current car `sr`, current country VAT flag, current `Agent_total`.

**F1 Hub nuance:** COMPLETE requires engine confidence **high** (stored `total_mndob`), so even V2 “derived” lines stay **PARTIAL** in Hub until fields are persisted or F1 policy is separately redesigned (out of scope — do not change F1 here).

---

## PART D — Historical remediation matrix

| Trip | Field | Missing? | Evidence? | Safe derivation? | Confidence | Proposed action |
|---|---|---|---|---|---|---|
| T1 golden | `total_mndob2` | Y | `total=200`, `ksm=0`, `SrSAAH*hours=200` | Y | High (formula) | Prefer **exclude as golden QA**; else SAFE_BACKFILL=200 |
| T1 golden | `total_mndob` | Y | `200-30-0` | Y | High | Prefer exclude; else SAFE_BACKFILL=170 |
| T1 golden | agent | Y | none | N | — | LEAVE_UNRESOLVED / exclude fixture |
| T2 prod-like | `total_mndob2` | Y | `total=50`, `ksm=0`, `SrSAAH*1=50` | Y | High | **SAFE_BACKFILL**=50 |
| T2 prod-like | `total_mndob` | Y | `50-7.5-0` | Y | High | **SAFE_BACKFILL**=42.5 |
| T2 prod-like | agent | Y | none | N | — | **LEAVE_UNRESOLVED** |
| Both | cash | uncollected | fields present | N/A | — | **NO_ACTION** (driver confirm) |
| Both | settlement | none | N/A | N/A | — | **NO_ACTION** until eligible |

---

## PART E — Future write path (design only)

### Required lifecycle

```
PRICE CALCULATED (verifiedBookingAmount)
  → immutable financial fields written on order create
  → trip accepted / completed (status_code)   // independent
  → cash/online collection handled independently
  → settlement obligation from snapshot + collection
```

### Fields that must become immutable at **booking create** (authoritative)

`total_mndob2`, `total_app`, `total_vat`, `total_mndob`, `total`, (+ FIN-9 agent snapshot on create)

### ONE authoritative write point (recommended)

**Server:** extend `createCashBooking` **and** online paid order create in `ngenius_payments.js` to persist:

| Field | Source from existing quote/session |
|---|---|
| `total_mndob2` | `baseFareHalalas / 100` |
| `total` | `amountHalalas / 100` (unchanged) |
| `total_app` | `appFeeHalalas / 100` (unchanged) |
| `total_vat` | `vatHalalas / 100` (unchanged) |
| `total_mndob` | `(baseFareHalalas - appFeeHalalas - vatHalalas) / 100` |
| optional | `base_fare_halalas` raw for audit |

**Status today:** **BROKEN / incomplete** for F1 COMPLETE (fields omitted).  
**Risk if unfixed:** every new cash/online booking remains Hub-PARTIAL.

Do **not** make operational completion fail when money incomplete (PART F).

---

## PART F — Completion gate

Keep:

- `status_code = completed | trip_completed` independent of money completeness

After completion, accounting surfaces:

- `financial_snapshot_status` ∈ {COMPLETE, PARTIAL, UNRESOLVED} (read model — F3-B1)

**Do not** alter operational completion semantics.

---

## PART G — Cash collection semantics (proven)

| Item | Canonical |
|---|---|
| Primary payment field | `payment_status` (`pending_cash` → `cash_collected`) |
| Collection field | `cash_collection_status` (`pending`/`uncollected` → `collected`) |
| Actor markers | `cashCollectedByDriver=true`, `cashCollectedAt`, `cash_confirm_operation_id` |
| Audit | `financial_audit_events` `CASH_COLLECTION_REALIZED` |
| WHO | **Assigned Driver** via callable `confirmCashCollectionV2` (Admin finance CF) |
| Driver UX | `DriverTripService.confirmCashCollection` → CF |
| WHEN | **Separate** from trip finish — requires completed lifecycle + cash method |
| NOT | Customer mark; not implied by `status_code=completed` |

**Real trips collected:** 0  
**Real/prod-like uncollected:** Trip 2 (+ Trip 1 golden pending)

---

## PART H — Cash collection flow status

| Assessment | Detail |
|---|---|
| Status | **FUNCTIONAL** (code path exists; feature-flagged) |
| Caveat | Confirm rejects `FINANCE_DATA_INCOMPLETE` when V2 confidence is `incomplete`; these two trips are **derivable** (`ksm==0`) so confirm should be allowed once driver acts |
| Smallest future fix | Ensure booking writes stored net/gross so confidence=`high`; keep driver confirm UX; document flag `FINANCIAL_CASH_REALIZATION_V2_ENABLED` |

**Do not fix in F3-A2.**

---

## PART I — Settlement eligibility (existing V2)

From `financial_accounting_v2.js` (no new rule invented):

Cash trip eligible when:

1. lifecycle completed  
2. financial confidence ≠ `incomplete` (stored **or** derived)  
3. payment/collection treated as paid (`cash_collected` / paid axis)  
4. recon not in hard difference  
5. not already claimed by another settlement (ledger)

Online: same completion + paid online channel → company pays driver direction.

**These trips today:** completed + cash + **NOT collected** → exclusion `NOT_COLLECTED` even after money derive.

---

## PART J — Why 0 real settlements

| Cause | Applies? |
|---|---|
| No trips qualify | **YES** — uncollected cash |
| Financial fields incomplete for F1 COMPLETE | **YES** for Hub; V2 can still derive |
| Settlement generator not auto-run | **YES** — manual SuperAdmin draft/lock workflow |
| UI/function missing | **NO** — Settlements UI + CF exist |
| Intentional manual workflow | **YES** |

**Exact reason:** no non-QA trip is both **cash-collected** and settlement-drafted; only FIN-8 QA settlement exists.

---

## PART K — Agent history

| Trip | Status |
|---|---|
| T1 / T2 | **MISSING** (no `agent_id` / amount / rate / snapshot_at) |
| Current SA agent | exists (5%) — **FORBIDDEN** as historical backfill |
| Future | FIN-9 on create must remain source of trip-time truth |

---

## PART L — AdminAgentReport QA leakage (audit only)

| Item | Proven |
|---|---|
| Data | `loadAgentReportStats` → country `order` scan |
| Engine | `FinancialEngine.aggregate` + live `agent.agentTotal` % |
| Fixture filter | **Absent** |
| Pollution | **YES** — `fin*` and golden orders in same country can inflate sales/commission |
| Minimal future fix | Filter with `AdminQaFixture.isFixtureOrder` **and** `functional_test`/`golden_cycle`; use trip agent snapshot for commission — never live `%` as historical truth |

---

## PART M — Legacy surface disposition (design)

| Surface | Disposition |
|---|---|
| Finance Hub / Agent Finance / Finance Reports (F1) | **KEEP** |
| Settlements + detail + receipt | **KEEP** |
| Finance Channels / Receivables / Reconciliation | **DIAGNOSTICS_ONLY** / soft-hide |
| Profits route | **REWIRE_TO_CANONICAL** (already redirects) |
| Driver Wallets | **DIAGNOSTICS_ONLY** / SuperAdmin LEGACY |
| Reports Hub | **DEPRECATE** as finance entry |
| AdminAgentReport | **HIDE** or rewire after QA+snapshot fix |
| Legacy `company_payments` panel | **KEEP** isolated UNALLOCATED |

---

## PART N — Future repair tool design (DO NOT EXECUTE)

Must support:

- DRY RUN  
- trip-by-trip diff (before → proposed)  
- evidence source + confidence + reason  
- audit + rollback manifests  
- idempotency  
- **no** overwrite of existing non-null money  
- **no** current-config inference  
- **no** agent reassignment  
- **no** QA/golden mutation (or explicit exclude list)

Example proposed patch (Trip 2 only):

| Field | Before | Proposed | Evidence |
|---|---|---|---|
| `total_mndob2` | null | 50 | `total` + `ksm=0` |
| `total_mndob` | null | 42.5 | `total - total_app - total_vat` |

---

## PART O — Future validation invariants (design only)

- Prefer stored majors; missing ≠ zero  
- `total_mndob2 >= 0`, fees/VAT/net ≥ 0  
- If `ksm==0`: `total_mndob2` should equal `total`  
- `total_mndob ≈ total_mndob2 - total_app - total_vat` within tolerance  
- Snapshot immutable after finalization  
- Settlement cannot include QA/golden fixtures  
- Trip in at most one active settlement claim  
- Cash collected requires actor + timestamp  

---

## PART P — Readiness gates

| Gate | Result | Note |
|---|---|---|
| GATE 1 Future write path | **FAIL** | `createCashBooking` omits gross/net |
| GATE 2 Historical classification | **PASS** | Both trips classified; T1 golden vs T2 prod-like |
| GATE 3 No fabrication | **PASS** | Only evidence-backed SAFE_TO_BACKFILL proposed |
| GATE 4 Cash collection | **PASS** (semantics) / ops pending | Canonical CF+driver path proven; 0 collected |
| GATE 5 Settlement eligibility | **PASS** (model) | V2 rules clear; 0 eligible real trips today |
| GATE 6 QA leakage scope | **PASS** (scoped) | AgentReport + golden marker gap documented |
| GATE 7 Agent history | **FAIL** | Snapshots missing; backfill forbidden |

---

## PART Q — Next recommended phase

### **OPTION C — F3-C FUTURE FINANCIAL WRITE-PATH FIX**

**Why (evidence):**

1. Systemic defect: booking CF never persists `total_mndob2` / `total_mndob` though quote computes them.  
2. Repairing only 2 historical rows (Option A) leaves **all future** bookings Hub-PARTIAL.  
3. F3-B1 recon UI (Option B) cannot become trustworthy while the write path keeps emitting PARTIAL.  
4. Agent FAIL remains separate (FIN-9 reliability) but money completeness is the dominant Hub blocker.

**Follow-on (not this phase):** after C, optional **F3-A3 SAFE HISTORICAL REPAIR** dry-run for Trip 2 (and policy on golden Trip 1 exclusion).

**Not D:** business numbers for these two money fields are formula-provable; no wait required for gross/net backfill *design*. Agent remains unresolved without invention.

---

## REQUIRED SUMMARY BLOCK

================================  
REAL COMPLETED TRIPS  
================================  

COUNT (non-fin* completed): 2  

TRIP 1: `03392f80…` / `CASH-03392F80A1` — **GOLDEN** (`TOURi_GOLDEN_1`)  
FINANCIAL STATUS: PARTIAL  
MISSING: `total_mndob2`, `total_mndob`, agent snapshot  
RECOVERABILITY: money SAFE_TO_BACKFILL if ever repaired; prefer **exclude as fixture**  

TRIP 2: `7b9a80c3…` / `CASH-7B9A80C306` — prod-like  
FINANCIAL STATUS: PARTIAL  
MISSING: `total_mndob2`, `total_mndob`, agent snapshot  
RECOVERABILITY: money **SAFE_TO_BACKFILL** (50 / 42.5); agent **NOT_RECOVERABLE**  

================================  
ROOT CAUSE  
================================  

TOTAL_MNDOB2: omitted by `createCashBooking` / online order create  
TOTAL_MNDOB: same  
TOTAL_APP: written OK  
TOTAL_VAT: written OK (explicit 0)  
AGENT SNAPSHOT: missing on docs; FIN-9 not evidenced; current-agent backfill FORBIDDEN  

================================  
HISTORICAL REPAIR  
================================  

SAFE_TO_BACKFILL: Trip2 `total_mndob2=50`, `total_mndob=42.5` (and Trip1 if not excluded)  
MANUAL_REVIEW: none for money when `ksm==0`  
NOT_RECOVERABLE: agent snapshot fields  

================================  
FUTURE WRITE PATH  
================================  

STATUS: **BROKEN** (incomplete) for F1 COMPLETE  
AUTHORITATIVE WRITER: `ngenius_payments.js` booking create (cash + online)  
RISK: perpetual PARTIAL Hub totals  

================================  
CASH COLLECTION  
================================  

CANONICAL FIELD/EVENT: `payment_status` + `cash_collection_status` + `confirmCashCollectionV2` / audit event  
CURRENT FLOW: Driver confirms after completion  
REAL TRIPS COLLECTED: 0  
REAL TRIPS UNCOLLECTED: 2 (1 golden + 1 prod-like)  
FLOW STATUS: **FUNCTIONAL**  

================================  
SETTLEMENT READINESS  
================================  

REAL SETTLEMENTS: 0  
WHY: cash not collected + manual settlement workflow; only QA FIN-8 exists  
ELIGIBILITY MODEL: V2 completed + not incomplete + collected/paid + not double-claimed  

================================  
AGENT HISTORY  
================================  

STATUS: MISSING on both  
CURRENT AGENT BACKFILL: **FORBIDDEN**  

================================  
ADMIN AGENT REPORT  
================================  

QA LEAKAGE: **PROVEN**  
MINIMAL FUTURE FIX: fixture+golden filter; snapshot-based commission  

================================  
READINESS GATES  
================================  

GATE 1 FUTURE WRITE PATH: **FAIL**  
GATE 2 HISTORICAL CLASSIFICATION: **PASS**  
GATE 3 NO FABRICATION: **PASS**  
GATE 4 CASH COLLECTION: **PASS** (semantics)  
GATE 5 SETTLEMENT ELIGIBILITY: **PASS** (model)  
GATE 6 QA LEAKAGE SCOPE: **PASS**  
GATE 7 AGENT HISTORY: **FAIL**  

================================  
NEXT RECOMMENDED PHASE  
================================  

**C** — F3-C FUTURE FINANCIAL WRITE-PATH FIX  

WHY: booking CF omits gross/net; fixing history alone cannot make accounting ready.  

================================  
SAFETY  
================================  

FINANCIAL WRITES: 0  
BACKFILL EXECUTED: NO  
SETTLEMENT CREATED: NO  
PRODUCTION DEPLOY: NO  
F1/F2 MODIFIED: NO  

================================  
FINAL  
================================  

F3-A2: **READY_FOR_REVIEW**  
READY_TO_IMPLEMENT_F3-B: **NO**

STOP.
