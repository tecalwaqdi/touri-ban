# TOURi TAXI — FINANCE F3-C2R REVIEW REPORT

**BRANCH:** `recovery/admin-finance-f3c2-agent-snapshot`  
**COMMIT:** `b4eefdad727a4d12f0f0c8903bc50aa6e0884b24`  
**BASE:** F3-C1 `c5dc537`  
**REVIEW:** code review only — **no code changes, no deploy, no data mutation**

---

## A — Exact diff classification

| File | Class |
|---|---|
| `admin/ara_oatan_app/firebase/functions/agent_order_snapshot.js` | **REQUIRED** |
| `admin/ara_oatan_app/firebase/functions/ngenius_payments.js` | **REQUIRED** |
| `.../test/agent_order_snapshot.test.js` | **TEST** |
| `.../test/ngenius_payments_unit.test.js` | **TEST** |
| `docs/admin_ui_recovery/FINANCE_F3C2_AGENT_SNAPSHOT.md` | **DOC** |

**UNRELATED DIFF: 0**

---

## B — Agent amount semantics

Share of platform fee (`appFeeHalalas` / `total_app`), basis `percent_of_platform_fee`:

`agent_amount_minor = round(platformFeeMinor * Agent_total / 100)`

Proven live:

| Input | Result |
|---|---|
| 750 minors × 5% | **38 → 0.38** |
| 12000 minors × 5% | **600 → 6.00** |

Merge of money majors + agent fields: `total`, `total_mndob`, `total_app` unchanged.

**AGENT SHARE BASIS:** percent of canonical `total_app` (quote `appFeeHalalas`)  
**CUSTOMER TOTAL IMPACT: 0**  
**DRIVER NET IMPACT: 0**  
**DOUBLE DEDUCTION RISK: NO**

---

## C / D — Active agent resolution

| Count | Behavior | Persisted |
|---|---|---|
| 0 | continue booking | `agent_attribution_status: none` + stamp |
| 1 | attribute that agent | full FIN-9 attributed fields |
| 2+ | **no pick** | `ambiguous` + sorted `agent_ambiguous_agent_ids` · **no** `agent_id` / amount |

**MULTIPLE ACTIVE AGENT: EXPLICIT_UNRESOLVED**  
**RANDOM AGENT SELECTION: 0**

---

## E — Country match

Resolver query: `Isagent==true` **AND** `Rev_dloh_agent ==` booking country ref (`quote.countryPath` / `session.countryPath` → order `Rev_dolh`).

Wrong-country agent → filtered out → `none`.

**CROSS_COUNTRY AGENT RISK: 0**

---

## F — Active window (exact rule)

`isActiveAgent`:

1. `Isagent` / `isagent` === true  
2. `actev_user !== false`  
3. If `agent_date_end` present (Timestamp or parseable string) and &lt; now → inactive  
4. If `agent_date_reg` present and &gt; now → inactive  

Not “actev_user only” — date window applied when fields exist (same as Admin FIN-9).

---

## G — Immutability

| Writer | Role |
|---|---|
| Customer create (C2) | Initial atomic write |
| Admin `syncAgentSnapshotOnOrderCreate` | Post-create merge; **returns null / skips** if `agent_id` **or** `agent_snapshot_at` set |

C2 always stamps `agent_snapshot_at` (including `none` / `ambiguous`).  
Current agent reassignment / `Agent_total` / deactivation on `user` do **not** rewrite order fields.

**POST-CREATE AGENT SNAPSHOT WRITERS (dangerous overwrite): 0**  
**CURRENT AGENT/RATE CHANGE AFFECTS OLD TRIP: NO**

---

## H — FIN-9 compatibility

Same field names, statuses, equation, and `agent_snapshot_version: FIN-9`.  
No conflicting interpretation; Customer uses same `round(platform * rate / 100)` helper pattern as Admin FIN-9.

---

## I — Precision

Integer minors only in `computeAgentAmountMinor`; major = `minor / 100`.  
7.50×5% → 0.38; 120×5% → 6.00. No float percent-of-float path for the share.

---

## J — Cash vs online

Both call `buildBookingAgentSnapshot` with quote/session `appFeeHalalas` + `countryPath`; both `...agentFields` on same `orderData` as money → `transaction.create`.

Payment method does not change agent share semantics.

---

## K — Failure safety

| Failure | Result |
|---|---|
| Invalid/missing rate | `rate_missing` · **no** amount |
| Platform/country missing | `platform_missing` · **no** amount |
| Ambiguous | `ambiguous` · **no** amount / id |
| Agent_total = 0 | `rate_missing` (not attributed zero) |
| Firestore query throw | booking create fails (not silent zero attribution) |

Unsupported alternate basis: not stored on agent; only `percent_of_platform_fee` written when attributed.

**MISSING→ZERO: 0 · INVALID→ZERO: 0 · AMBIGUOUS→FALSE ATTRIBUTION: 0**

---

## L — Atomicity

**CASH: PASS** · **ONLINE: PASS**  
Money + agent in same `transaction.create` · no async agent patch on Customer path.

---

## M — Tests run

Agent Customer · N-Genius · Admin FIN-9 · V2 · F1 · money_precision → **PASS** · **NEW FAILURES: 0**

Matrix notes: wrong-country proven live (→ `none`); unsupported basis N/A (hardcoded FIN-9 basis only).

---

## N — Deploy blast radius

**FUNCTIONS REQUIRING DEPLOY:** `createCashBooking`, `finalizeNGeniusBooking`  
**UNRELATED FUNCTION DEPLOY REQUIRED: NO**  
**PRODUCTION DEPLOY: NO**

---

## FINAL

```
F3-C2 REVIEW: PASS
READY_FOR_F3-C2D: YES
READY_FOR_F3-B: NO
```

**STOP.**
