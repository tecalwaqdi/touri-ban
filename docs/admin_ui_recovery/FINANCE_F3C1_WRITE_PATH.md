# TOURi TAXI — FINANCE F3-C1 WRITE PATH REPORT

**BASE:** `af13bf5` (`recovery/admin-finance-f3a2-data-readiness`)  
**BRANCH:** `recovery/admin-finance-f3c1-write-path`  
**COMMIT:** `ac06f2efbe28ac360bcb66d056adbfcd0e69e44d`  
**CODE AREA:** `admin/ara_oatan_app/firebase/functions/ngenius_payments.js`  
(Note: booking create lives in Customer Functions codebase, not `admin/Admi/firebase/functions`.)  
**PRODUCTION DEPLOY:** **NO**

---

## PART A — Authoritative calculation

`verifiedBookingAmount(data)` returns (halalas):

| Quote field | Meaning |
|---|---|
| `baseFareHalalas` | `car.sr * 100 * bookingHours` |
| `discountHalalas` | capped percent of additional hours |
| `amountHalalas` | `baseFareHalalas - discountHalalas` (customer total) |
| `appFeeHalalas` | `percentOf(baseFareHalalas, 15)` |
| `vatHalalas` | `percentOf(baseFareHalalas, country.vat)` if `isvat` else `0` |

Payment session for online booking stores `...(verifiedQuote)` plus `amount_halalas`.

### Sources used by F3-C1 helper `bookingFinancialMajorsFromQuote`

| Snapshot field | BASE SOURCE |
|---|---|
| GROSS `total_mndob2` | `baseFareHalalas / 100` |
| PLATFORM FEE `total_app` | `appFeeHalalas / 100` |
| VAT `total_vat` | `vatHalalas / 100` |
| CUSTOMER TOTAL `total` | `amountHalalas` (or session `amount_halalas`) `/ 100` |
| DRIVER NET `total_mndob` | `(baseFareHalalas - appFeeHalalas - vatHalalas) / 100` |

**DUPLICATE FORMULA ADDED:** NO — single helper shared by cash + online; arithmetic matches V2 stored/high path (`gross − platform − VAT`).

---

## PART B — Driver net semantics

From `financial_accounting_v2.js`:

- Stored: prefer `total_mndob`
- Expected check: `grossBase - platformFee - recordedVat`
- Derive when missing: `DERIVED_FROM_GROSS_BASE` or `DERIVED_FROM_TOTAL` when `ksm==0`

F3-C1 persists **gross-based** net so discounted bookings stay consistent with V2 (net ≠ `total − fee` when discount &gt; 0).

---

## PART C/D — Cash + online create

Both `createCashBooking` and `finalizeNGeniusBooking` now call `requireBookingFinancialMajors(...)` and write atomically inside the existing `transaction.create(orderRef, orderData)`:

- `total_mndob2`, `total_app`, `total_vat`, `total_mndob`, `total`

If quote/session lacks required halalas fields → `failed-precondition` **before** create (no zero invent).

---

## PART E — Atomicity

**YES** — majors are fields on the same `orderData` object passed to `transaction.create`. No second async write.

---

## PART G — Later overwrite audit

| Path | Touches money snapshot? |
|---|---|
| `finalizeNGeniusExtraHours` | Updates **`total_taim` only** (+ extra-hours subdocs). Does **not** rewrite `total_mndob2` / `total_mndob` / fees. **Reported — not changed in C1.** |
| Cash collection CF | Payment/collection fields only |
| FIN-9 agent snapshot | Agent fields only |

---

## PART H — Agent snapshot

**AGENT SNAPSHOT CURRENTLY WRITTEN (in booking create):** **NO**  
(Separate FIN-9 `onCreate` may run after; not part of C1.)  
**MODIFIED IN C1:** **NO**

---

## PART I — QA golden

`CASH-03392F80A1` / `functional_test` + `golden_cycle=TOURi_GOLDEN_1` still missed by `fin*` prefixes.  
**FIXED IN C1:** NO  
**RECOMMENDED NEXT:** minimal `AdminQaFixture` detector for `functional_test` / `golden_cycle` (dedicated phase).

---

## REQUIRED SUMMARY

================================  
ROOT CAUSE  
================================  

createCashBooking: omitted `total_mndob2` / `total_mndob` despite quote having base/fee/VAT  
online create (`finalizeNGeniusBooking`): same omission  

================================  
AUTHORITATIVE CALCULATION  
================================  

GROSS SOURCE: `baseFareHalalas`  
PLATFORM FEE SOURCE: `appFeeHalalas`  
VAT SOURCE: `vatHalalas`  
DRIVER NET SOURCE: `baseFareHalalas - appFeeHalalas - vatHalalas`  
CUSTOMER TOTAL SOURCE: `amountHalalas` / `amount_halalas`  
DUPLICATE FORMULA ADDED: **NO**  

================================  
CASH CREATE  
================================  

total_mndob2: **WRITTEN**  
total_app: WRITTEN  
total_vat: WRITTEN  
total_mndob: **WRITTEN**  
total: WRITTEN  
ATOMIC: **YES**  

================================  
ONLINE CREATE  
================================  

STATUS: **FIXED**  
SNAPSHOT COMPLETE: **YES**  

================================  
AGENT SNAPSHOT  
================================  

CURRENT STATUS: **NO** (not in booking create)  
MODIFIED IN C1: **NO**  

================================  
QA GOLDEN FINDING  
================================  

TOURi_GOLDEN_1: still undetected by finance QA prefixes  
FIXED IN C1: **NO**  
RECOMMENDED NEXT ACTION: dedicated fixture detector for `functional_test`/`golden_cycle`  

================================  
TESTS  
================================  

FUNCTION TESTS (ngenius unit): **PASS**  
FINANCE TESTS (F1 + accounting v2 + agent snap + cash realization): **PASS**  
NEW FAILURES: **0**  

================================  
HISTORICAL DATA  
================================  

BACKFILL: **NO**  
EXISTING PARTIAL TRIPS MODIFIED: **0** (read-only confirm: both still missing gross/net)  
SETTLEMENTS CREATED: **0**  

================================  
SAFETY  
================================  

FINANCIAL FORMULA CHANGED: **NO** (persist existing quote)  
COMMISSION RATE CHANGED: **NO**  
VAT LOGIC CHANGED: **NO**  
WALLET MODIFIED: **NO**  
LEDGER MODIFIED: **NO**  
F1/F2 MODIFIED: **NO**  
PRODUCTION DEPLOY: **NO**  

================================  
FINAL  
================================  

F3-C1: **READY_FOR_REVIEW**  
READY_FOR_PRODUCTION_DEPLOY: **NO** (await diff review)  
READY_FOR_F3-B: **NO**

STOP.
