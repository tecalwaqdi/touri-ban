# TOURi TAXI — FINANCE F3-C2 AGENT SNAPSHOT REPORT

**BASE:** `recovery/admin-finance-f3c1-write-path` @ `c5dc537` (F3-C1D docs tip; impl `565b1cd`)  
**BRANCH:** `recovery/admin-finance-f3c2-agent-snapshot`  
**PRODUCTION DEPLOY:** NO  
**HISTORICAL BACKFILL:** NO  

---

## A — Current agent model (proven)

| Item | Exact |
|---|---|
| **COUNTRY COLLECTION/PATH** | `countries/{countryId}` |
| **AGENT COLLECTION/PATH** | `user/{uid}` with `Isagent == true` |
| **COUNTRY→AGENT FIELD** | *(none on country doc)* — agents attach via user field |
| **AGENT→COUNTRY FIELD** | `Rev_dloh_agent` → `DocumentReference` / path `countries/...` |
| **ACTIVE FIELD** | `actev_user` (+ optional `agent_date_reg` / `agent_date_end`) |
| **RATE FIELD** | `Agent_total` (percent 0–100 of platform fee) |
| **BASIS FIELD** | canonical string `percent_of_platform_fee` (FIN-9); not stored on user |
| **ORDER COUNTRY** | `Rev_dolh` |

Legacy display: `dolh_agent` (name text). Optional: `agent_currency_code`.

---

## B — One active agent per country

| Layer | Enforcement |
|---|---|
| **DATABASE** | **NO** — no unique constraint |
| **ADMIN** | **PARTIAL** — create UI does not block a second agent for same country (`admin_add_agent_widget.dart`) |
| **FUNCTIONS** | **PARTIAL** — FIN-9 / F3-C2 **refuse to attribute** when `>1` active (`ambiguous`); do not invent |

**Business invariant at booking:** if multiple active agents → `agent_attribution_status: ambiguous` (no pick).

---

## C — Canonical snapshot fields (FIN-9 / F1)

Reused existing names (no new parallel schema):

| Semantic | Field |
|---|---|
| Agent ID | `agent_id` |
| Scope | `agent_scope` = `country_exclusive` |
| Rate | `agent_rate` |
| Basis | `agent_rate_type` = `percent_of_platform_fee` |
| Amount | `agent_amount_minor` + `agent_amount` |
| Currency | `agent_currency` |
| Timestamp | `agent_snapshot_at` (ISO) |
| Version/source | `agent_snapshot_version` = `FIN-9` |
| Status | `agent_attribution_status` |
| Ambiguity | `agent_ambiguous_agent_ids` |

Country at trip time remains on order `Rev_dolh` (same booking create).

---

## D — Commission basis

**Supported:** `percent_of_platform_fee` only (repository-proven).

Agent share is **not** an extra customer charge and is **not** deducted again from driver net / VAT / gross.

---

## E — Calculation

**Canonical helper:** `computeAgentAmountMinor(platformFeeHalalas, Agent_total)`  
`agent_amount_minor = round(platformFeeMinor * rate / 100)`

Platform fee source at booking: verified quote **`appFeeHalalas`** (same integer that becomes `total_app`).

**DUPLICATE FORMULA: NO** (matches Admin `agent_order_snapshot.js` FIN-9).

**5% of 7.50:** `round(750 * 5 / 100) = 38` → **0.38 SAR**

**CUSTOMER TOTAL CHANGED: NO**  
**DRIVER NET CHANGED: NO**

---

## F — No agent

`agent_attribution_status: none` + `agent_snapshot_at` + version  
(= explicit **NO_AGENT_AT_BOOKING**)

Booking remains operational. Future country agent must **not** be attached to this trip.

---

## G — Invalid config

| Case | Status | Booking |
|---|---|---|
| Multiple active agents | `ambiguous` | allowed |
| Rate missing / ≤0 | `rate_missing` (+ `agent_id`) | allowed |
| Platform fee missing | `platform_missing` | allowed (money path still fails separately if quote incomplete) |

**Decision:** agent share is **not** required to create a booking. Persist explicit unresolved status; **never** fabricate amount 0 as `attributed`.

---

## H / I — Cash + online

| Path | Snapshot | Atomic with money |
|---|---|---|
| `createCashBooking` | YES | YES — same `transaction.create` `orderData` |
| `finalizeNGeniusBooking` | YES | YES — same create |

Payment / gateway semantics unchanged.

---

## J — Immutability

| Writer | Behavior |
|---|---|
| Customer create (F3-C2) | Initial write only |
| Admin `syncAgentSnapshotOnOrderCreate` | Skips if `agent_id` **or** `agent_snapshot_at` already set |
| Agent reassignment / rate change on `user` | Does **not** rewrite order snapshot fields |

**POST-CREATE OVERWRITES (dangerous): 0** for orders that already carry F3-C2/FIN-9 stamp.

---

## K — Historical

**BACKFILL: NO**  
Known trips `03392f80…` / `7b9a80c3…` untouched.  
**CURRENT AGENT USED FOR OLD TRIP: NO**

---

## L — FIN-9

Fixture semantics: rate from `Agent_total`, basis `percent_of_platform_fee`, amount minors via round; F1 treats `attributed` + amount as confident. QA `fin9_ctrl_*` remains fixture-filtered.

---

## M — Golden discovery (report only)

`CASH-03392F80A1` / `TOURi_GOLDEN_1` / `functional_test` still missed by `AdminQaFixture`. **Not fixed in C2.**

---

## O — F1/F2 compatibility

| Snapshot state | Read model |
|---|---|
| `attributed` + id + amount | COMPLETE / `hasProvableAgentSnapshot` / confident |
| `none` | NO_AGENT (explicit; `isAgentUnattributed`) |
| `ambiguous` / `rate_missing` / `platform_missing` | UNRESOLVED / unattributed |
| Missing fields (legacy) | PARTIAL / missing — **never** infer current agent |

No F1/F2 UI redesign.

---

## P — Migration / index / rules

| | |
|---|---|
| Firestore migration | **NO** |
| New index | **NO** (uses existing `Isagent` + `Rev_dloh_agent` query) |
| Rules update | **NO** |
| IAM change | **NO** |

---

## Q — Deploy blast radius (do not deploy)

| Export | Why |
|---|---|
| **`createCashBooking`** | writes agent + money snapshot |
| **`finalizeNGeniusBooking`** | same |

Admin `syncAgentSnapshotOnOrderCreate` already deployed; becomes no-op when booking stamp present.

**PRODUCTION DEPLOY: NO**

---

## Implementation files

- `admin/ara_oatan_app/firebase/functions/agent_order_snapshot.js` (new)
- `admin/ara_oatan_app/firebase/functions/ngenius_payments.js` (wire atomic)
- `admin/ara_oatan_app/firebase/functions/test/agent_order_snapshot.test.js` (new)
- `admin/ara_oatan_app/firebase/functions/test/ngenius_payments_unit.test.js` (asserts)

---

## Tests

| Suite | Result |
|---|---|
| Customer agent_order_snapshot | PASS |
| N-Genius unit | PASS |
| Admin FIN-9 agent_order_snapshot | PASS |
| financial_accounting_v2 | PASS |
| F1 + money_precision | PASS |
| New failures | 0 |

---

## FINAL

```
F3-C2: READY_FOR_REVIEW
READY_FOR_F3-C2D: YES
READY_FOR_F3-B: NO
```

**STOP.**
