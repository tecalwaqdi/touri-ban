# Financial data source matrix (F0)

**Base SHA:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Rule:** expose sources — do not reconcile or “fix” live totals in F0.

Canonical operational completion: `order.status_code ∈ {completed, trip_completed}`  
(`TourySystemStatusCodes` / `AdminOpsCounters.completedStatusCodes`).

---

| Metric | Business definition | Source collection | Source fields | Filters | Trip status condition | Payment condition | Country scope | Agent scope | Driver scope | Date field | Aggregation method | UI consumers |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Completed trips count (ops) | Operationally finished trips | `order` | `status_code` | Optional country/date | `completed` OR `trip_completed` | **None** | `Rev_dolh` when scoped | Via country | Optional `mndob_user` | `data_order` / created | Count aggregate per code | Dashboard (`dashboard_stats_loader`), Bookings filters |
| Completed trips count (finance lifecycle) | Same operational completion for finance lines | `order` | `status_code` (+ legacy `halh`/`halh_order` only if code missing) | Date/currency/channel | Engine `FinancialLifecycle.completed` | **None** for lifecycle | `Rev_dolh` / snapshot | Attribution separate | `mndob_user` | `data_order` | Count lines | Finance Hub / Channels / Reports / Accounting panels |
| Completed trip gross value | Customer gross for completed trips | `order` | Prefer `total_mndob2`, else `total` | Completed lifecycle | Completed | Not required for gross of completed | Country | — | — | Order date | Sum major→minor | Finance KPIs (`completed_trip_value`) |
| Collected amount | Money considered financially received | `order` | `payment_status`, `PaymentMethod`, channel | Completed+paid buckets | Completed for “collected completed” | `paid` / `cash_collected` / `captured` | Country | — | — | Order date | Sum | Channels / Receivables / Reconciliation |
| Uncollected amount | Completed but not collected | `order` | same | Bucket `completedButNotCollected` | Completed | `pending_cash` / unpaid / unknown | Country | — | — | Order date | Sum | Finance KPIs |
| Company commission | Platform fee | `order` | `total_app` | Eligible lines | Usually completed+collected for settlement | Channel-dependent | Country | — | — | Order date | Sum | Hub / Reports / Settlements preview |
| VAT | Tax on trip | `order` | `total_vat` | Eligible lines | Same as commission scope | Same | Country | — | — | Order date | Sum | Hub / Reports |
| Driver net | Driver share | `order` | `total_mndob` or derived from gross−app−vat; or snapshot `driver_net_minor` | Eligible | Completed (+ collected for settlement) | Channel rules | Country | — | Driver | Order date | Sum | Settlements / Driver finance |
| Outstanding to company | Driver cash liability / platform due | Derived | cash held − driver net (cash); online company fees | Settlement-eligible | Completed + collected | Cash collected / online paid | Country | — | Driver | Period | Settlement preview net | Settlements |
| Outstanding to driver | Company owes driver (esp. online) | Derived | online `driverNet` | Settlement-eligible | Completed + collected | Online paid | Country | — | Driver | Period | Settlement preview | Settlements |
| Settled amount | Recorded settlement payments | `financial_settlements` (+ payments subdocs) | `status`, amounts | Settlement status | N/A (settlement entity) | N/A | Country on settlement | — | Counterparty | Settlement dates | Sum settled | Settlements UI |
| Unsettled amount | Open settlement / eligible unincluded | Settlements + eligible order lines | status ≠ settled | Open | Completed+collected not in settled set | Collected | Country | — | Driver | Period | Diff | Settlements / Receivables |
| Refunds | Refunded payments | `order` | `payment_status=refunded` | — | Any / cancelled | refunded | Country | — | — | Order date | Count/sum | Audit / Reports (sparse) |
| Chargebacks | Chargeback events | **UNKNOWN / sparse in Admin UI** | UNKNOWN | — | — | — | — | — | — | — | — | Not a first-class Admin surface in inventory |
| Agent amount / liability | Agent commission | `order.agent_*` snapshot fields **or** prospective from agent `Agent_total` × country orders | `agent_amount_minor`, `Agent_total` | Country exclusive agent | Attribution rules | Often on platform fee | `Rev_dolh` ↔ `Rev_dloh_agent` | Agent user | — | Period | Sum / prospective | Agent Finance |
| Paid-but-not-completed | Money received without operational complete | `order` | lifecycle ≠ completed + paid | Bucket `paidButNotCompleted` | **Not** completed | paid/captured/cash_collected | Country | — | — | Order date | Count/sum | Reconciliation / Audit |

---

## Conflicts already visible (no fix)

| Conflict | Detail |
|---|---|
| Ops vs finance “completed” | Ops counters ignore payment; some legacy helpers treat Arabic complete as paid |
| Gross field missing | Live cash completed trips often have `total` but **null** `total_mndob2` |
| Fixtures vs live | Fixture IDs (`fin7_ctrl_*`, `fin_rt_cash_*`) carry fuller money fields than many live cash completes |
| Agent snapshot | Many live completed cash trips have **null** `agent_id` / `agent_amount_minor`; attribution falls back to country scope |
