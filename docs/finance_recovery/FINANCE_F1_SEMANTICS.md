# Finance F1 — Financial Semantics

**Branch:** `recovery/admin-finance-f1-foundation`  
**Base (F0 checkpoint):** `2cda3d4c70f98c657aeda34e60842ac14f6d2f84`  
**Driver clean base:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Phase:** F1 foundation — semantics + read model. **No UI redesign. No DB migration.**

---

## Non-negotiable axes (never collapse)

| Axis | Meaning | Canonical signals |
|---|---|---|
| Operational completion | Trip finished in ops | `status_code` ∈ `{completed, trip_completed}`; legacy Arabic «مكتمل*» **only if** `status_code` empty |
| Payment | Money captured / marked paid | `payment_status` ∈ `{paid, cash_collected, captured}` + legacy `halh_order=Paid` / `halh=paid` |
| Cash collection | Driver confirmed cash in hand | `payment_status=cash_collected` **or** `cash_collection_status=collected` |
| Settlement | Company↔driver settlement done | Order markers / `financial_settlements` (F1 read-only; no ledger mutation) |

**Forbidden equivalences:**

- `tripCompleted ≠ paymentPaid`
- `tripCompleted ≠ cashCollected`
- `tripCompleted ≠ settlementExists`
- `tripCompleted ≠ walletMovement`
- `paymentPaid ≠ tripCompleted`

---

## Proven defect fixed

`OrderStatusHelper.isPaid` previously treated Arabic «مكتمل / مكتملة» as **paid**.

`countsTowardRevenue` inherited that conflation.

**F1 change:** `isPaid` uses payment markers only. Arabic complete → `isOperationallyCompleted` only.

---

## Helpers (single meanings)

| Helper | Home | Meaning |
|---|---|---|
| `FinancialTripSemantics.isOperationallyCompleted` | `financial_trip_semantics.dart` | Ops complete via `FinancialAccountingEngine.normalizedLifecycleStatus` |
| `OrderStatusHelper.isOperationallyCompleted` | `financial_engine.dart` | Same rule for OrderRecord (incl. Arabic when code empty) |
| `FinancialTripSemantics.isPaymentPaid` / `OrderStatusHelper.isPaid` | | Payment axis only |
| `FinancialTripSemantics.isCashCollected` / `OrderStatusHelper.isCashCollected` | | Collection axis |
| `FinancialTripSemantics.isSettlementCompleteOnOrder` | | Settlement marker on order (not ledger rewrite) |
| `FinancialTripSemantics.isFinanceQaFixture` | | Alias → `AdminQaFixture` |
| `FinancialAgentAttributionResolver` | | CONFIDENT / LEGACY / MISSING — **never** backfill current country agent |

---

## Consumers of `OrderStatusHelper` (audit)

| Consumer | API used | Expected meaning | F1 action |
|---|---|---|---|
| `financial_engine.dart` `FinancialEngine.orderFinancials` | `isPaid` / pending / canceled | **Payment** received → include money in legacy revenue helpers | Keep payment-only; defect removed |
| `financial_engine.dart` `countPaid` | `isPaid` | Paid **payment** count | Keep |
| `admin_booking_details_widget.dart` | `statusOf == paid` | Refund eligibility (payment) | Keep — now correct without Arabic complete |
| `admin_booking_details_sections.dart` | `statusOf` | Payment chip | Keep |
| `admin_a_l_lhg_z_widget.dart` | `isCanceled` | Cancel filter | Unchanged |
| Dashboard / Bookings KPIs | `AdminOpsCounters.completedStatusCodes` | Operational completed | Already status_code-based — no change |
| `FinancialAccountingEngine` | lifecycle vs payment enums | Preferred finance engine | Source of truth for new read model |

**Not auto-rewritten in F1:** every dashboard card / PDF / CSV path. New accountant path = `AccountantFinanceReadModel`. Proven wrong completion-via-isPaid path fixed at helper root.

---

## Money resolution

`FinancialAmountResolution` (read-only):

- Uses existing `FinancialAccountingEngine.analyze` — **no new formulas**
- Quality: `COMPLETE` | `PARTIAL` | `UNRESOLVED`
- Incomplete → still counts in **completed trip count**; **does not** enter amount totals
- Missing values are **not** treated as zero in accountant totals

---

## Fixtures

`AdminQaFixture` prefixes (`fin7_ctrl_`, `fin_rt_*`, …) + `is_test_fixture`.

Live accountant KPIs: fixtures contribute **0**. Diagnostics may still list them.

---

## Agent attribution

Historical `agent_id` / `agent_amount_minor` / attribution status on trip (or `financial_snapshot`).

Missing snapshot → `MISSING` — **do not** assign current `Rev_dloh_agent`.

---

## Scope

`AccountantFinanceScope`:

- Super Admin: `includeAllCountries: true`
- Country Agent: `countryPaths` only — aggregation filters before totaling (no global then UI-filter)
