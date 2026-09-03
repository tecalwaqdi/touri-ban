# FINANCIAL SYSTEM AUDIT — Toury Taxi (Finance V3 Foundation)

**Audit date:** 2026-09-03  
**Repo HEAD at audit start:** `463c82b` (Admin `1.0.12+2014` on Firebase; Render may lag)  
**Scope:** `admin/Admi`, `admin/mndob-main`, `admin/ara_oatan_app`, `admin/services/payment-api`, Cloud Functions  
**Mode:** Forensic read of real code. No Production deploy. No destructive migration.

---

## 1. Current Architecture

```
Customer (ara_oatan_app) ──writes──► order (pricing fields, PaymentMethod, status_code)
Driver (mndob-main) ──────writes──► order lifecycle + confirmCashCollectionV2 (CF)
Admin (Admi Flutter Web) ─reads───► aggregateFinancialAccountingV2 / Finance UI
                                  └─writes──► settlement_* / periods / adjustments (flagged)
Cloud Functions ──────────truth───► financial_accounting_v2.js (mirror of Dart engine)
                                  └─settlement_ledger.js (immutable-ish settlement records)
                                  └─cash_collection_realization.js
Firestore ──────────────────source──► order, wallets, company_payments, financial_*
payment-api ──────────────optional► online gateway (must remain feature-gated)
```

**Canonical read path today (FIN V2):**  
`FinancialAccountingEngine` (Dart) ↔ `financial_accounting_v2.js` (Functions)  
Admin must use `FinancialAccountingLoader` with `requireCanonicalServer: true` for authoritative totals.

**Write path for settlements:**  
`settlement_ledger.js` — writes ONLY `financial_settlements*`, claims, lines, events, payments, idempotency.  
Never writes order / wallets / company_payments.

---

## 2. Collections Map (proven from Functions + Admin)

| Collection | Role | Writers | Readers |
|---|---|---|---|
| `order` | Trip + embedded pricing snapshot fields | Customer, Driver, CF | All finance engines |
| `wallets` | LEGACY driver wallet balances | Admin SuperAdmin adjust, wallet services | Admin wallets UI |
| `company_payments` | LEGACY company payment artifacts (3 frozen in prod audit) | Legacy paths | Recon / audit |
| `financial_settlements` | Settlement headers | `settlement_ledger.js` | Admin settlements |
| `financial_settlement_claims` | Order↔settlement claim | CF | CF / audit |
| `financial_settlements/{id}/lines` | Settlement lines | CF | CF / detail UI |
| `financial_settlement_payments` | Settlement payments | CF | Admin |
| `financial_payment_allocations` | Allocation | CF | CF |
| `financial_periods` | Soft close periods | `finance_periods.js` | Admin periods |
| `financial_config/runtime` | Feature flags + approver policy | Admin SDK | CF flags |
| `transactions` / wallet tx | Mixed operational | Apps / wallet services | Wallets UI |
| `user` | Drivers/agents (`Agent_total`, country refs) | Apps / Admin | Attribution |
| `countries` / cities / villages | Geo | Admin geo | Filters |

**Not present as full double-entry CoA yet:** no `accounting_journal` collection in production V2. Settlement ledger is the closest posted accounting surface.

---

## 3. Financial Fields Map (order)

| Field | Meaning (canonical V2) | Written by | Immutable? |
|---|---|---|---|
| `total` | Customer gross / booking value | Customer pricing | Historical snapshot in practice |
| `total_app` | Platform commission | Pricing pipeline | Historical |
| `total_vat` | Recorded VAT | Pricing pipeline | Historical |
| `total_mndob` / `total_mndob2` | Driver net | Pricing pipeline | Historical |
| `ksm` | Legacy platform fee alias | Legacy | Prefer `total_app` |
| `currency` | ISO code | Order create | Must not mix |
| `PaymentMethod` | Cash / Online | Customer | Channel |
| `payment_status` | paid / pending_cash / cash_collected / … | Driver CF / payment flows | Lifecycle payment |
| `cash_collection_status` | pending / collected | Driver CF | Cash event |
| `status_code` | Operational lifecycle | Apps | **Ops truth** (not payment) |
| `halh` / `halh_order` | Legacy Arabic/status | Legacy | Fallback only |
| `ALLNOW` / `ActiveOrder` | Ops flags | Apps | Must NOT drive finance status |
| `Rev_dolh` | Country ref | Order | Geo |
| Agent snapshot fields | Prospective FIN-9 | Controlled fixtures | Missing on most history |

**Apps must keep reading these fields** — removing them would break published Customer/Driver apps.

---

## 4–8. Lifecycles (summary)

**Order ops:** searching → assigned → accepted → arrived → started → completed (+ cancel/expire). Primary: `status_code`.

**Payment:** unpaid / pending_cash / paid / cash_collected / refunded… Primary: `payment_status` (+ `PaymentMethod`).

**Cash collection:** completed trip ≠ cash collected. Confirm via `confirmCashCollectionV2` (server).

**Wallet:** LEGACY `currentBalance` — not settlement; SuperAdmin adjust only; must not be treated as trip earnings.

**Settlement:** draft → locked → (partially_)settled / voided. Payments confirm reduce outstanding. Flag-gated.

**Agent attribution:** historical = country-scope only (`Rev_dolh` ↔ `Rev_dloh_agent`); rate from `Agent_total` % of platform fee. Per-order immutable snapshot not on history → `unattributed` / `legacy_unprovable` when ambiguous.

---

## 9–12. RBAC / Functions / Reports

**RBAC (Admin):** SuperAdmin global; Finance staff global finance; Country Agent / Agent → own Agent Finance only (hard deny settlements/audit/periods/diagnostics). Server CF remains authoritative.

**Key CF:** `aggregateFinancialAccountingV2`, `accountantHomeV2`, `scanFinancialExceptionsV2`, settlement\*V2, `confirmCashCollectionV2`, periods\*, adjustments\*.

**Reports UI:** AdminFinanceHub, AdminProfits, AdminFinanceReports, Settlements, Reconciliation, Agent Finance, Wallets (legacy), Diagnostics (SuperAdmin).

---

## 13–15. Duplicate / conflicting / dangerous

| Issue | Evidence | Risk |
|---|---|---|
| Dart engine + JS `financial_accounting_v2.js` must stay in lockstep | Dual implementations | Drift |
| SAR preferred as “primary” UI currency | `finance_ledger_service`, KPIs | Misleading global total |
| `.limit(200/80/500)` on ledger/company reads | `finance_ledger_service`, `finance_company_service` | Understated totals if used for KPIs |
| Client aggregation fallback | Loader without server | Non-authoritative |
| Hardcoded commission elsewhere | Must not introduce 15% in multiple files | Config drift |
| Treating cancelled as MISSING_DRIVER | Fixed 2026-09-03 in `finance_controls.js` | False blockers |
| `company_payments` unallocated | Historical freeze | Visible DQ, no auto-heal |

---

## 16–19. Indexes / perf / security / DQ

- Indexes: order country+date filters need continued inventory vs `firestore.indexes.json` (ops already fixed many). Finance rollups not yet materialized.
- Perf: full `order.get()` in exception scan is O(N) — acceptable for small N; not for global dashboard forever.
- Security: settlement writes server-gated; Agent scope enforced in CF for agent-only.
- DQ: confidence `high|derived|incomplete`; incomplete historical snapshots remain frozen (do not invent).

---

## 20–21. Historical / app-safe fields

- Do not rewrite 49 incomplete / 47 stale pending_cash / old 250 SAR / 3 company_payments.
- Customer + Driver apps depend on order financial majors + payment_status + status_code — **no field removal**.

---

## 22. Recommended Architecture (V3 = evolve V2)

1. Keep `FinancialAccountingEngine` / `financial_accounting_v2.js` as **recognition engine** for historical orders.  
2. Add **immutable trip financial snapshot schema** for prospective trips (server write later, flag-gated).  
3. Add **terminology layer** so UI never labels GMV as “Revenue”.  
4. Add **event/idempotency + journal** as next write model (shadow / dry-run first).  
5. Materialize **daily rollups** as read models only.  
6. Shadow Mode: `FINANCIAL_ENGINE_VERSION=legacy|v2|v3` — single writer for ledger.  
7. No parallel dashboard math.

**This audit’s implementation mandate:** foundations + docs + dry-run tools + tests. **No Production deploy. No destructive backfill apply.**
