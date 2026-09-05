# TOURi TAXI — FINANCE F3-C1R REVIEW REPORT

**BRANCH:** `recovery/admin-finance-f3c1-write-path`  
**COMMIT:** `fad7379` (tip) / implementation `565b1cd`  
**BASE:** `origin/recovery/admin-finance-f3a2-data-readiness`  
**REVIEW:** code review only — **no code changes, no deploy, no data writes**

---

## A — Exact diff classification

Changed files (3):

| File | Classification |
|---|---|
| `admin/ara_oatan_app/firebase/functions/ngenius_payments.js` | **REQUIRED** |
| `admin/ara_oatan_app/firebase/functions/test/ngenius_payments_unit.test.js` | **TEST** |
| `docs/admin_ui_recovery/FINANCE_F3C1_WRITE_PATH.md` | **DOC** |

**UNRELATED DIFF: 0**

Required JS changes only: add `bookingFinancialMajorsFromQuote` / `requireBookingFinancialMajors`; use them in `createCashBooking` + `finalizeNGeniusBooking`; export for tests. No payment/gateway/idempotency edits.

---

## B — `total_mndob` semantics (critical)

### Canonical field meanings (existing)

| Field | Meaning | Schema / engine |
|---|---|---|
| `total_mndob2` | Gross / base fare | Admin `order_record.dart` comment; V2 `grossBase` |
| `total_app` | Platform / company fee | independent of VAT |
| `total_vat` | VAT recorded separately | independent of `total_app` |
| `total_mndob` | Driver net | V2 preferred stored net |
| `total` | Customer amount (`amountHalalas/100`) | booking quote; **not** base+VAT |

### Booking quote construction (`verifiedBookingAmount`)

```text
baseFareHalalas  = car.sr * 100 * hours
appFeeHalalas    = percentOf(baseFare, 15)     // NOT inclusive of VAT
vatHalalas       = isvat ? percentOf(baseFare, country.vat) : 0
amountHalalas    = baseFare - discount         // customer total; VAT NOT added on top
```

### Canonical driver net (V2)

`financial_accounting_v2.js`:

- Stored check: `expected = grossBase - platformFee - recordedVat`
- Derive: `DERIVED_FROM_GROSS_BASE` → same; or when `ksm==0` `customerPaid - platform - vat`

**VAT ≠ 0 proof** (`test/financial_accounting_v2.test.js`):

```text
total=800, total_app=120, total_vat=120
→ derived driverNetMinor=56000 (560)
→ signedCashMinor=24000 (=120+120 = app+vat)
→ recon reconciled
```

With discount + stored gross:

```text
total=700, ksm=100, total_mndob2=800, total_mndob=560, app=120, vat=120
→ confidence high; net = gross − app − vat (not total − app − vat)
```

Online scaled fixture: `500 / 75 / 75 / 350` (= 500−75−75).

**CANONICAL DRIVER NET FORMULA:**  
`total_mndob = total_mndob2 − total_app − total_vat`  
(equivalently in halalas: `baseFare − appFee − vat`)

**PROOF SOURCE:**  
`financial_accounting_v2.js` (stored vs formula + DERIVED_FROM_GROSS_BASE);  
`financial_accounting_v2.test.js` VAT=120 cases;  
`ngenius_payments.js` `verifiedBookingAmount` (VAT separate from app fee).

**DOUBLE VAT RISK: NO**  
- VAT is not inside `total_app`  
- VAT is not added into customer `total` by the quote  
- Driver net subtracts VAT **once**  
- Company cash position = app + VAT (single VAT)

F3-C1 helper matches this exactly. Live check: `80000/12000/12000 → majors {total:800, app:120, vat:120, mndob:560}`.

---

## C — Quote field provenance

| Snapshot | Source field (same quote/session) |
|---|---|
| gross/base | `baseFareHalalas` |
| platform | `appFeeHalalas` |
| VAT | `vatHalalas` |
| customer total | `amountHalalas` **or** session `amount_halalas` |
| driver net | computed only from those three base/app/vat integers |

**QUOTE SINGLE SOURCE: PASS**  
No second Firestore config read inside the helper. Online path uses payment session seeded with `...(verifiedQuote)`.

---

## D — Cash path

`createCashBooking`: `requireBookingFinancialMajors(quote)` then all five fields on `orderData` → `transaction.create(orderRef, orderData)`.

**CASH ATOMIC WRITE: PASS**

---

## E — Online path

`finalizeNGeniusBooking`: same helper on `session`; same five fields on create.

Unchanged by C1: payment verification, status mapping, webhook, gateway fetch, idempotency session reuse, wallet/extra-hours finalize logic (except booking create money fields).

**ONLINE ATOMIC WRITE: PASS**  
**PAYMENT SEMANTICS CHANGED: NO**

---

## F — Invalid value safety

Helper returns `null` (require throws `failed-precondition`) when:

- missing object  
- non-finite / negative base, app, vat, or amount  
- NaN  
- missing vat field (undefined → NaN → reject)  
- driver net &lt; 0  

**Does not** coerce missing → 0.

**Explicit VAT = 0:** accepted (`Number.isFinite(0) && >= 0`).

**MISSING→ZERO FALLBACK: 0**  
**EXPLICIT ZERO SUPPORTED: YES**

---

## G — Precision

Method (pre-existing booking pattern, reused):

1. Keep money in **integer halalas** on the quote  
2. Persist majors as `halalas / 100` (same `/100` already used for `total` / `total_app` / `total_vat`)

No new rounding policy. Integer 750 → 7.5; 4250 → 42.5; 56000 → 560 are exact binary fractions for these fixtures.

**PRECISION: PASS** (reuse existing major conversion)

---

## H — Post-create overwrite

| Writer | Snapshot fields |
|---|---|
| `finalizeNGeniusExtraHours` | updates `total_taim` only — **not** money snapshot |
| Cash collection CF | payment/collection fields |
| FIN-9 agent snapshot | agent fields |
| Booking create (C1) | initial write only |

No post-create writer found that overwrites `total_mndob2` / `total_app` / `total_vat` / `total_mndob` / `total` in the Customer functions booking module.

**POST-CREATE SNAPSHOT OVERWRITE: 0** → **PASS**

---

## I — Test matrix

| # | Case | Result |
|---|---|---|
| 1 | 50 / 7.5 / 0 / 42.5 | PASS (ngenius unit) |
| 2 | VAT &gt; 0 (800/120/120/560) | PASS (live helper + V2 canonical test) |
| 3 | VAT = 0 accepted | PASS |
| 4 | missing gross rejected | PASS |
| 5 | missing platform rejected | PASS |
| 6 | missing VAT rejected | PASS |
| 7 | NaN rejected | PASS |
| 8–9 | cash/online write both paths (source assert ≥2) | PASS |
| 10–12 | total / app / vat still from same quote sources | PASS |
| 13–15 | no historical / settlement / wallet writes in C1 | PASS (diff scope) |

Ran: `node test/ngenius_payments_unit.test.js` PASS; `financial_accounting_v2` PASS; F1 + money_precision Flutter PASS.

**TESTS: PASS**

---

## J — Deployment blast radius (do not deploy)

Customer Functions codebase (`ara_oatan_app/firebase/functions`), module `ngenius_payments.js`.

Exports that import the module (deploy candidates when approved):

| Function | Needs deploy for C1? |
|---|---|
| **`createCashBooking`** | **YES** (required) |
| **`finalizeNGeniusBooking`** | **YES** (required) |
| `createNGeniusPayment` | same file; redeploy with package if single codebase deploy |
| `getNGeniusPayment` | same |
| `finalizeNGeniusWalletTopUp` | same |
| `createWalletWithdrawalRequest` | same |
| `finalizeNGeniusExtraHours` | same |
| `refundNGeniusPayment` | same |
| `ngeniusWebhook` | same |

Minimum **behavior** change is only the two booking create paths; Firebase often deploys the whole functions package together.

**PRODUCTION DEPLOY: NO**

---

## FINAL

```
UNRELATED DIFF: 0

CANONICAL DRIVER NET: total_mndob2 - total_app - total_vat

DOUBLE VAT RISK: NO

QUOTE SINGLE SOURCE: PASS

CASH ATOMIC WRITE: PASS

ONLINE ATOMIC WRITE: PASS

PAYMENT SEMANTICS CHANGED: NO

MISSING→ZERO FALLBACK: 0

EXPLICIT ZERO SUPPORTED: YES

PRECISION: PASS

POST-CREATE SNAPSHOT OVERWRITE: 0

TESTS: PASS

FUNCTIONS REQUIRING DEPLOY (minimum intent):
  createCashBooking
  finalizeNGeniusBooking
(+ peer exports in same ngenius_payments package if full codebase deploy)

PRODUCTION DEPLOY: NO

F3-C1 REVIEW: PASS

READY_FOR_F3-C1D_DEPLOY: YES

READY_FOR_F3-B: NO
```

STOP.
