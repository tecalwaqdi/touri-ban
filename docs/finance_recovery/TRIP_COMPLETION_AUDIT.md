# Trip completion audit (F0)

**Base SHA:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`

---

## Canonical operational field (proven)

| Item | Value |
|---|---|
| Field | `order.status_code` (string) |
| Canonical completed values | `completed`, legacy alias `trip_completed` |
| Source of truth constants | `lib/core/toury_system_status_codes.dart` |
| Ops counters | `AdminOpsCounters.completedStatusCodes` in `lib/backend/admin_ops_counters.dart` |
| Finance lifecycle (preferred) | `FinancialAccountingEngine.normalizedLifecycleStatus` — uses `status_code` first |

**Payment must not determine trip completion.** Preferred engines already separate lifecycle from `payment_status` / channel.

---

## Implementations inventory

### A — Correct operational completion (payment-independent)

| Location | Field used | Value | Payment dependency | Cash dependency | Source |
|---|---|---|---|---|---|
| Dashboard completed KPI | `status_code` | `completed` / `trip_completed` | NO | NO | `dashboard_stats_loader.dart` + `AdminOpsCounters` |
| Bookings lifecycle filters | `status_code` | filter code lists | NO | NO | `admin_ops_filters.dart` |
| Booking status badges | `status_code` then legacy `halh_text` | maps to «مكتملة» | NO for code path | NO | `admin_booking_status_label.dart` |
| Finance accounting lifecycle | `status_code` first | completed / trip_completed | NO | NO | `financial_accounting_engine.dart` |
| Cash collection CF gate (if present) | `status_code` | requires completed before cash confirm | Payment method checked separately | Cash method only | `cash_collection_realization.js` (workspace; confirm deploy separately) |

### B — Incorrect or risky completion / paid conflation

| Location | Field used | Value/status used | Payment dependency | Cash dependency | Defect |
|---|---|---|---|---|---|
| `OrderStatusHelper.isPaid` (`financial_engine.dart`) | `payment_status`, `halh_order`, **`halhText` Arabic** | Matches «مكتمل»/«مكتملة» as **paid** | YES | YES (cash_collected paths) | Treats trip-complete Arabic copy as payment success |
| `OrderStatusHelper.countsTowardRevenue` | via `isPaid` | same | YES | YES | Revenue gate ≠ operational completion |
| Legacy finance lifecycle fallback | `halh` / `halh_order` when `status_code` empty | Arabic complete / weak paid signals | Partial | Partial | Acceptable only as legacy fallback; dangerous if `status_code` missing |
| Collection buckets | lifecycle × payment | `completedAndCollected` etc. | YES (by design for **collection**, not completion) | YES | Not a defect if UI labels keep dimensions separate |

### C — UI strings «مكتملة» that are NOT trip completion

| Location | Meaning |
|---|---|
| Driver documents panels | Document pack completeness |
| Driver counters strip | Document completeness |

These must not feed trip KPIs.

---

## Explicit business examples (expected)

| Ops status | Payment | Count as completed trip? |
|---|---|---|
| `completed` + cash | YES | YES |
| `completed` + online/card | YES | YES |
| `trip_started` / arrived + `paid` | NO | NO |
| `cancelled_*` + `paid` | NO | NO (paid-but-not-completed / review) |

Live sample proving paid ≠ completed:

- Order `669eb8e5…`: `status_code=cancelled_by_driver`, `payment_status=paid`, `PaymentMethod=OnlinePayment`.

---

## Summary

| Question | Answer |
|---|---|
| Canonical operational field | `status_code` |
| Canonical completed values | `completed`, `trip_completed` |
| Payment affects completion in preferred engines? | **NO** |
| Incorrect implementations exist? | **YES** — primarily `OrderStatusHelper.isPaid` Arabic complete→paid |
| Fix in F0? | **NO** |
