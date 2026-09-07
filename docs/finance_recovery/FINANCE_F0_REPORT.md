# Finance F0 report

**Base SHA:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Branch:** `recovery/admin-finance-audit`  
**Phase:** F0 audit only — **no financial logic changes**.

Related:

- `docs/admin_ui_recovery/PHASE4_DEFERRED_BLOCKERS.md` — Driver Edit parked  
- Sibling docs in this folder (inventory, matrix, field contract, money flow, trip completion, recon sample)

---

## Trip completion

| Item | Finding |
|---|---|
| Canonical operational field | `order.status_code` |
| Canonical completed values | `completed`, `trip_completed` |
| Payment affects completion (preferred engines)? | **NO** |
| Incorrect implementations | `OrderStatusHelper.isPaid` treats Arabic «مكتملة» as paid; `countsTowardRevenue` follows that |

---

## Financial sources

| Item | Finding |
|---|---|
| Number of finance UI surfaces | ~11 primary routes + dashboard/bookings/profits overlap |
| Calculation engines | ≥2 client (`FinancialAccountingEngine`, `financial_engine`/`OrderStatusHelper`) + CF `financial_accounting_v2` + settlement ledger |
| Duplicate calculations | Hub / Channels / Reports / Profits / Dashboard may re-aggregate |
| Conflicting calculations | Ops completed ≠ finance collected; legacy paid conflation; gross field fallbacks |

---

## Money flow

| Item | Finding |
|---|---|
| Cash flow | Customer → driver holds cash when collected → driver owes company fee/VAT → settlement |
| Online flow | Customer → company/gateway → company owes driver net → settlement |
| Who holds cash | Driver after cash_collected |
| Who owes company | Driver (cash commission side) |

---

## Field contract

| Item | Finding |
|---|---|
| Canonical snapshot | Prefer `total_mndob2` + `total_app` + `total_vat` + `total_mndob` (+ v3 `financial_snapshot` when present) |
| Legacy fields | `halh`, `halh_order`, `halh_text`, `ksm`, bare `total` as fallback |
| Conflicts | Live cash completes often lack preferred gross/net fields |

---

## Settlements

| Item | Finding |
|---|---|
| Canonical source | `financial_settlements` + `settlement_ledger.js` / `settlement_payments.js` |
| Preview math | `SettlementPreview` (cash liability − online entitlement) |
| Issues | Sparse settlements in sample; eligible lines depend on complete+collected+money confidence |

---

## Role / country

| Role | Access |
|---|---|
| Super Admin | Full `_financeRoutes` + settlements/audit/reports |
| Finance staff | Finance route set |
| Country Agent | **Only** `AdminAgentFinance` among finance screens (not global settlements/audit) |
| Country rule | ONE COUNTRY ↔ agent via `Rev_dloh_agent`; exclusive agent preferred for provable commission; multi-agent possible in data → confidence drops |
| Cross-country risks | Agent UI filters by scoped country; global finance screens Super-Admin/finance — verify CF always re-check claims (F1) |

---

## Reconciliation

| Item | Finding |
|---|---|
| Sample trips | See `FINANCE_RECONCILIATION_SAMPLE.md` |
| Fully explainable | **NO** |
| Unexplained | Missing money fields on live completes; agent snapshot gaps |

---

## Proposed accountant UI (design only — do not implement)

### A) Financial summary
- قيمة الرحلات المكتملة (ops-complete gross)
- المحصل فعليًا / غير المحصل
- عمولة الشركة / الضريبة / صافي السائقين
- المستحق للشركة / المستحق للسائقين
- Clear fixture exclusion toggle (never mix into live KPIs)

### B) Money movement
Per trip: method, who holds now, who owes whom, refs.

### C) Settlements
Payer, payee, due, paid, remaining, status, date, reference.

### D) Reports / audit
Filters: date, country, agent, driver, payment method, trip status, collection status, settlement status.

Avoid decorative KPI overload and developer workflow copy.

---

## Fixtures

Preserve existing QA finance fixtures (`fin7_ctrl_*`, `fin_rt_*`, `is_test_fixture`).  
Do not delete. Do not use as production KPI truth.

---

## Final gates

| Gate | Value |
|---|---|
| FINANCIAL TRUTH ESTABLISHED | **PARTIAL** (contract known; live field completeness not) |
| SAFE_TO_START_FINANCE_IMPLEMENTATION | **YES with constraints** (F1 must not “fix” by mutating live cash; must separate axes; must exclude fixtures) |
| CODE FINANCIAL LOGIC CHANGED | **NO** |
| PRODUCTION DEPLOYED | **NO** |
| DRIVER EDIT TOUCHED | **NO** |
