# Legacy Admin Finance Stabilization Report

**Project:** `admin/Admi` (Legacy Touri Taxi Admin)  
**Firebase:** `tutorial-multi-language-70gx4j`  
**Date:** 2026-09-17  
**Scope:** Gap-driven stabilization — Admin Next was not modified.

## Old architecture

- Flutter Web admin (FlutterFlow lineage) with finance surfaces under `lib/admin/admin_finance_*` and `lib/core/finance/*`.
- Dual historical money paths existed: canonical `FinancialAccountingEngine` / CF `aggregateFinancialAccountingV2`, plus legacy `FinancialEngine` double aggregates that coerced schema defaults to `0`.
- Settlement V2 write model already lived in Cloud Functions (`settlement_ledger.js`, `settlement_payments.js`, `finance_controls.js`).

## Authoritative data sources

| Concept | Source |
|--------|--------|
| Trip money | Persisted order majors: `total`, `total_mndob2`, `total_app`, `total_vat`, `total_mndob`, `ksm`, `currency` |
| Recognition | `FinancialAccountingEngine` (Dart) ↔ `financial_accounting_v2.js` (CF) |
| KPI aggregates | CF `aggregateFinancialAccountingV2` via `FinancialAccountingLoader` / `FinanceCompanyService` |
| Settlements | `financial_settlements` (+ `lines`, `events`) |
| Payments | `financial_settlement_payments` (`pending` / `confirmed` / `reversed`) |
| Adjustments / corrections | `financial_adjustments` (draft → approved → reversed) |
| Agent share | FIN-9 order snapshot fields (`agent_amount_minor`, …) when attributed |

## Formulas (operator-facing)

- **Gross:** persisted customer paid / gross base (`total` / `total_mndob2`) via engine line.
- **Touri commission:** persisted `total_app` (never recomputed from live rates for history).
- **VAT/tax:** persisted `total_vat` only.
- **Driver net:** prefer persisted `total_mndob`; derive only when engine confidence allows; UI shows `—` when unprovable.
- **Company claim (cash):** `signedCashMinor` ≈ customer paid − driver net on collected cash trips.
- **Settlement outstanding:** `absoluteSettlementAmountMinor − paidConfirmedMinor`.
- **Missing ≠ 0:** null/absent fields must display unavailable (`—`), not silent zero.

## Historical-data policy

- Persisted authoritative values win.
- Do not rewrite order majors to force agreement across screens.
- Corrections are append-only via `financial_adjustments` + audit events.

## Current cash-only policy

- Current operations are **cash only**.
- Legacy Admin does **not** activate Apple Pay / Moyasar / N-Genius checkout.
- Historical electronic payment methods remain visible for reconciliation and are labeled as historical where shown.

## Current 15% commission rule

- Policy constant: `PlatformCommissionPolicy.currentRatePercent = 15` effective `2026-09-13` UTC.
- Used only to **flag** mismatches on completed trips under the current policy (`platformCommissionRateMismatch`).
- Historical `total_app` is never overwritten to 15%.

## VAT / tax handling

- Stored `total_vat` is SoT.
- Platform fee is not VAT.
- Reports are internal accounting, not tax invoices.

## Driver finance

- Driver panel prefers CF aggregate totals for KPI parity with Hub, then client scan for statement lines.
- Settlement preview / drafts remain CF-mediated (no unsafe wallet adjust expansion).

## Agent finance

- One country = one active agent enforced server-side (`agent_country_assignment.js`).
- Agent Finance scope strip shows: agent share (when snapshotted), Touri commission, cash collected, company due, settled, outstanding.

## Settlements / outstanding / reconciliation / corrections

- Settlement statuses: `draft` → `locked` → `partially_paid` / `settled` / `voided`.
- Payment statuses are separate: `pending` / `confirmed` / `reversed`.
- Reconciliation and Financial Data Quality screens **flag only** — no production auto-fix.
- Bug fixed: cash channel `settledCompanyDueMinor` now uses **paidConfirmedMinor**, not outstanding.

## Reports / exports

- Finance Reports CSV is built from the same `FinanceCompanySnapshot` + on-screen trip rows (`FinanceReportCsvBuilder`).
- Print = browser print of on-screen values.
- Excel: out of scope for this Legacy panel (no package).
- Currencies are not combined into one meaningless total.

## Permissions

- Accountant / finance staff: finance routes including Data Quality.
- Country agents: denied global finance admin routes; Agent Finance remains their finance surface.
- Settlement writes remain Super Admin via existing SoD / runtime gates.

## Known legacy data-quality issues (intentionally not auto-corrected)

- Incomplete historical majors (missing `total_app` / `total_vat` / `total_mndob`).
- Pre-policy commission rates that differ from 15%.
- Historical online payment records.
- Derived driver net where persisted `total_mndob` is absent.
- Schema getters that still default some fields to `0` at the Firestore record layer — presentation/adapters must not treat those as authoritative without `has*` / engine nullability.

## Fixes implemented (this stabilization pass)

- Settled vs outstanding mapping in `FinanceCompanyService` / `FinanceCashOnlineSummary`.
- Settlement stats unavailable flag (no silent zero on load failure).
- Legacy `FinancialEngine` redirected to V2 presentation amounts; reports/agent stats use engine/snapshots.
- Bookings commission nullable (`—` when missing).
- Platform commission mismatch flag + Financial Data Quality screen.
- Agent finance cash/due/settled/outstanding + snapshotted agent share.
- Driver loader CF-first for KPI parity.
- CSV export wired to canonical report values.
- City/country mismatch highlight on booking details.
- Docs: this report + runbook.

## Items intentionally not auto-corrected

- No Production financial migration.
- No bulk rewrite of order majors.
- No Admin Next / customer / driver app changes.
- No reactivation of electronic checkout in Legacy Admin.
