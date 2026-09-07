# TOURi TAXI — FINANCE F3-A AUDIT

**BASE:** `07e0af66f0624a921110c563acc007cf9f157e2b`  
**BRANCH:** `recovery/admin-finance-f3a-audit`  
**COMMIT:** `8a544a61cb3623d1769a23bcee48f83805d4b727`  
**PROJECT:** `tutorial-multi-language-70gx4j`  
**SCOPE:** AUDIT / DESIGN ONLY — no financial writes, no migration, no production deploy  
**F1/F2:** FROZEN (HUMAN PASS) — semantics not modified

---

## Executive summary

F2 delivered a usable **accountant Finance Hub** on the F1 read model. F3-A finds that **professional end-to-end reconciliation is not yet ready for production accounting**: real completed trips in the sampled corpus are **PARTIAL** (missing `total_mndob2` / `total_mndob`), **cash uncollected**, with **no real settlements** (only QA FIN-8). PDF/CSV export remains deferred. A dedicated Accountant role is **PARTIAL** (Finance claim exists; no separate accountant persona). Proposed F3-B phases are documented below — **not implemented**.

---

## Audit method

| Item | Detail |
|---|---|
| Code base | Exact checkout of F2 final commit |
| Surfaces | Admin routes under `lib/admin/*finance*`, settlements, profits, reports, wallets, reconciliation, agent report |
| Data | Read-only Firestore sample on `tutorial-multi-language-70gx4j` |
| Tests | Finance-targeted Flutter tests + `flutter analyze` on finance paths |
| Writes | **0** |

---

## PART A — FINANCIAL_SURFACE_MATRIX

| Route | Page/Class | Primary data source | Read model | Role access | Semantic source | Export? | Legacy? | Duplicates? | Safety |
|---|---|---|---|---|---|---|---|---|---|
| `/adminFinanceHub` | `AdminFinanceHubWidget` | `order` via `AccountantFinanceLoader` | F1 `AccountantFinanceReadModel` | SuperAdmin / Finance staff | F1/F2 canonical | No (on-screen) | No | Primary | **Safe** |
| `/adminFinanceAgents` | `AdminAgentFinanceWidget` | same loader (country-scoped) | F1 same | Country Agent + SuperAdmin | F1/F2 | No | No | Agent view of Hub | **Safe** |
| `/adminFinanceReports` | `AdminFinanceReportsWidget` | same F1 loader | F1 | SuperAdmin / Finance | F1 (on-screen) | CSV/PDF **deferred** | Exporter legacy | Hub duplicate (intentional) | **Safe** (screen) / **Unknown** (future export) |
| `/adminFinanceChannels` | `AdminFinanceChannelsWidget` | `FinanceCompanyService` / cash-online summary | Diagnostic | Global finance | Mixed / diagnostic | No | Soft-deprecated vs Hub | Overlaps Hub channels | **Partial** |
| `/adminFinanceReceivables` | `AdminFinanceReceivablesWidget` | settlements / exposure | Mixed | Global finance | Pre-F2 style | No | Yes (removed from primary menu) | Overlaps settlements | **Partial** |
| `/adminReconciliation` | `AdminReconciliationWidget` | exception classifier + orders | Diagnostic | Global finance + write gate | V3 rules draft | No | Diagnostic | Not full recon model | **Partial** |
| `/adminSettlements` | `AdminSettlementsWidget` | `financial_settlements` | Ledger docs | SuperAdmin / Finance write | Settlement V2 | Receipt UI | No | — | **Safe** (w/ QA filter) |
| `/adminSettlementDetails` | `AdminSettlementDetailsWidget` | settlement + `financial_settlement_payments` | Ledger | Same | Settlement V2 | Receipt | No | — | **Safe** |
| `/adminSettlementReceipt` | `AdminSettlementReceiptWidget` | payments | Ledger | Same | Settlement V2 | On-screen | No | — | **Safe** |
| `/adminProfits` | `AdminProfitsWidget` | redirects → Hub; panel host leftover | Redirect | Global finance | F2 redirect | No | Soft legacy | Dup of Hub | **Safe** (redirect) |
| `/adminFinancialPeriods` | `AdminFinancialPeriodsWidget` | `financial_periods` | Period docs | Global finance | Periods V2 | No | Unused if empty | — | **Partial** |
| `/adminFinanceAudit` | `AdminFinanceAuditWidget` | audit/events queries | Mixed | Global finance | Audit | No | — | — | **Partial** |
| `/adminDriverWallets` | `AdminDriverWalletsWidget` | `wallets`, `transactions`, `company_payments` | LEGACY wallet | **SuperAdmin only** | Wallet ≠ settlement | No | **Yes** | Not trip earnings | **Unsafe** if mistaken for earnings |
| `/adminReportsHub` | `AdminReportsHubWidget` | nav hub | N/A | SuperAdmin | Mixed entry | Links | Legacy nav | Points at profits/agent | **Partial** |
| `/adminAgentReport` | `AdminAgentReportWidget` | country `order` + `FinancialEngine.aggregate` | **Legacy engine** | SuperAdmin only | **Not F1** | No | **Yes** | Sales ≠ F1 Hub | **Unsafe** |
| Dashboard finance nav | `home22_dashboard_widget` | links only | N/A | role-gated | Nav | No | No | — | **Safe** |
| Booking details money | `AdminBookingDetailsWidget` | single `order` | Order fields | scoped roles | Operational | No | Partial payment UI | — | **Partial** |
| Driver financial panel | `admin_driver_financial_panel` | settlements + preview CF | Settlement client | SuperAdmin/Finance | V2 settlement | No | — | — | **Partial** |
| Legacy finance panel | `AdminLegacyFinancePanel` | `company_payments` | Raw list | embedded | LEGACY unallocated | No | **Yes** | Isolated from V2 KPIs | **Safe** (isolated) |
| Diagnostics finance | `AdminDiagnosticsWidget` | `financial_config`, metrics | Ops | SuperAdmin | Flags | No | Diagnostic | — | **Safe** (ops) |

**Surface totals (classification):**

| Class | Count (approx) |
|---|---|
| TOTAL inventoried | 19 |
| TRUSTED (F1/F2 canonical) | 5 (Hub, Agent Finance, Finance Reports on-screen, Settlements list/detail/receipt) |
| PARTIAL | 8 |
| UNSAFE | 2 (Driver Wallets if used as earnings; Agent Report legacy) |
| LEGACY / deferred export | 4+ |

---

## PART B — DATA SOURCES (exact collections)

| Collection | Authoritative purpose |
|---|---|
| `order` | Trip operational + **immutable-intended** money majors (`total`, `total_mndob2`, `total_app`, `total_vat`, `total_mndob`, payment/cash fields, optional agent snapshot) |
| `financial_settlements` | Settlement grouping + state (`status`, `direction`, `absoluteSettlementAmountMinor`, `paidConfirmedMinor`, `outstandingMinor`, `eligibleOrderIds`, …) |
| `financial_settlement_payments` | Confirmed/pending/reversed payments against a settlement |
| `financial_settlement_claims` | Claim graph for settlement lines (sample exists) |
| `financial_settlement_lines` | Line items (empty in sample) |
| `financial_settlement_events` | Settlement audit events (empty in sample) |
| `financial_settlement_allocations` | Allocations (empty in sample) |
| `financial_settlement_counters` | Code sequences (pay/settlement) |
| `financial_periods` | Accounting periods (empty in sample) |
| `financial_config` | Runtime flags/config (1 doc sampled) |
| `financial_aggregation_metrics` | Ops metrics (diagnostics) |
| `financial_events` | Future V3 events (**not written**) |
| `accounting_journal` | Future CoA journal (**not written**) |
| `company_payments` | **LEGACY** wallet-side company payment records — **not** trip settlement lines |
| `wallets` | Driver wallet balances (LEGACY tool surface) |
| `transactions` | Wallet ledger entries |
| `user` | Agent profile (`Agent_total`, `Rev_dloh_agent`) — **not** historical trip truth |

**Axes remain independent (F1 frozen):**  
`status_code` completion ≠ `payment_status` ≠ cash collection ≠ settlement ledger.

---

## PART C — SOURCE OF TRUTH MATRIX

| Metric | Authoritative source | Fallback? | Missing behavior | Recomputable? | Mutable? | Exportable today? |
|---|---|---|---|---|---|---|
| Completed trips | `order.status_code` ∈ {`completed`,`trip_completed`} | Arabic complete **only if** code empty | Count without inventing money | Yes (rules) | Ops status can change historically — risk | On-screen Hub |
| Gross trip value | `order.total_mndob2` | No fabricate | PARTIAL/UNRESOLVED; omit from COMPLETE sums | No (must be stored) | Should be immutable — Admin paths not hardened in F3-A | Hub (COMPLETE only) |
| Customer paid | `order.total` / payment capture fields | Channel-specific | UNRESOLVED if absent | Partial | Risk | Partial |
| Cash collected | `payment_status=cash_collected` or `cash_collection_status=collected` | No | UNCOLLECTED / UNKNOWN | Rules only | Via cash CF (not audited as write here) | Hub |
| Cash uncollected | completed + cash + not collected | No | Explicit uncollected | Yes | — | Hub |
| Platform fee | `order.total_app` | No | PARTIAL | No | Risk | Hub |
| VAT | `order.total_vat` | No (0 is valid if present) | PARTIAL if field absent | No | Risk | Hub |
| Driver net | `order.total_mndob` | **Never** use gross as net | PARTIAL | No | Risk | Hub |
| Agent share | Trip snapshot (`agent_id`, `agent_amount_minor`, rate/basis) | **Never** current country agent | missing/legacy attribution | No from live agent % | Snapshot should be immutable | Partial (Hub notes unattributed) |
| Company receivable | Cash channel: company fee (+VAT) after collection (F1 signed cash position) | No | Incomplete if money PARTIAL | From COMPLETE lines | Via settlement | Hub |
| Driver receivable / payable | Online: driver net owed by company | No | Incomplete | From COMPLETE | Settlement | Hub |
| Settlement due | `financial_settlements.absoluteSettlementAmountMinor` | No | N/A if no settlement | From locked preview | Ledger CF | Settlements UI |
| Settlement paid | `paidConfirmedMinor` (confirmed payments net of reversals) | No | 0 if none | From payment docs | Ledger CF | Settlements UI |
| Settlement remaining | `outstandingMinor` = due − confirmed paid (server) | No | Canonical on settlement | Yes | Ledger CF | Settlements UI |
| Refund | payment_status / markers | Weak | 0 unless explicit | Partial | — | Counted cautiously in F1 |
| Chargeback | explicit markers only | No first-class field | 0 unless marked | No | — | Weak |
| Discount | `ksm` / engine | Limited | Incomplete | Partial | — | Weak |
| Gateway fee | **Not found as first-class field** | — | UNRESOLVED | — | — | No |
| Wallet movement | `wallets` + `transactions` | — | Separate axis | Ledger | SuperAdmin adjust CF | Wallets UI only |

---

## PART D — PROPOSED READ-ONLY RECONCILIATION MODEL

Per completed trip (proposed; **not written to production**):

| Axis | Values |
|---|---|
| OPERATIONAL_STATUS | from `status_code` (+ guarded Arabic fallback) |
| FINANCIAL_SNAPSHOT_STATUS | `COMPLETE` / `PARTIAL` / `UNRESOLVED` via `FinancialAmountResolution` |
| PAYMENT_METHOD | `CASH` / `ONLINE` / `UNKNOWN` |
| COLLECTION_STATUS | `COLLECTED` / `UNCOLLECTED` / `NOT_APPLICABLE` / `UNKNOWN` |
| SETTLEMENT_STATUS | join to `financial_settlements` eligibility — `UNSETTLED` / `PARTIAL` / `SETTLED` / `NOT_REQUIRED` / `UNKNOWN` |
| RECONCILIATION_STATUS | `RECONCILED` only if COMPLETE + collection consistent + settlement math consistent; else `NEEDS_REVIEW` or `BLOCKED_BY_MISSING_DATA` |

**Status: READY (design)** — implementation deferred to F3-B1.

---

## PART E — CASH RECONCILIATION (worked real example)

**Real non-QA completed cash trip** (read-only):

| Field | Value |
|---|---|
| Order (prefix) | `7b9a80c30646…` |
| `status_code` | `completed` |
| `PaymentMethod` | `Cash` |
| `payment_status` | `pending_cash` |
| `cash_collection_status` | `pending` |
| `total` (customer) | `50` SAR |
| `total_app` | `7.5` SAR |
| `total_vat` | `0` |
| `total_mndob2` | **MISSING** |
| `total_mndob` | **MISSING** |
| Agent snapshot | **MISSING** |
| Settlement | **none** |

### Answers against schema

1. Collection happened? **NO** (`pending_cash` / `pending`)  
2. Cash collected amount? **UNRESOLVED** (not collected)  
3. Who holds cash? **Customer still** (not collected) — after collection would be **Driver**  
4. Driver owes company? **Cannot finalize** — fee `7.5` present but gross/net incomplete → F1 quality **PARTIAL** → company receivable **not** entered into COMPLETE Hub totals  
5. Agent due? **UNRESOLVED** (no snapshot; must not invent current agent)  
6. Settlement created? **NO**  
7. Settlement paid? **N/A**  
8. Outstanding? **BLOCKED_BY_MISSING_DATA** for full recon; operationally cash still uncollected  

**Controlled QA reference (excluded from live KPIs):** `fin7_ctrl_*` has complete 50 / 7.5 / 0 / 42.5 + `cash_collected` — proves schema capability, not production health.

---

## PART F — ONLINE RECONCILIATION

In the completed-trip sample (`status_code==completed`):

- **Online trips: 0**
- Production-like corpus appears **cash-dominant / cash-only** for completed rides in this project sample.

Gateway fee, capture IDs, chargeback objects: **not established** as first-class reconciled fields.

**Do not force online assumptions into cash flows.**

---

## PART G — SETTLEMENT RECONCILIATION

**Canonical formula (server):**  
`outstandingMinor = absoluteSettlementAmountMinor - paidConfirmedMinor`  
(confirmed payments minus reversals) — see `settlement_payments.js` `applySettlementPaymentSnapshot`.

### Live sample findings

| Item | Result |
|---|---|
| Real settlements (non-QA) | **0** |
| QA settlements | **1** (`idempotencyKey=fin8_draft_fin7_ctrl_…`, eligible `fin7_ctrl_…`, status `settled`, due 750, paid 750, remaining 0) |
| Settlement payments | 3 — all `FIN8-*` refs → **QA** |
| Settlements without eligible trips | 0 in sample |
| Duplicate coverage / overpay / negative remaining (real) | **N/A** (no real settlements) |
| Completed-but-unsettled obligations (real) | **2** completed cash trips with no settlement + incomplete money |

---

## PART H — QA FIXTURE EXCLUSION

Canonical detectors: `AdminQaFixture` / `isFinanceQaFixture` / `isFinanceQaSettlement`  
Prefixes: `fin7_ctrl_`, `fin9_ctrl_`, `fin_rt_cash_`, `fin_rt_cash_ui_`, `fin_rt_`, plus metadata + `FIN8-` payment refs.

| Surface | Applies same exclusion? |
|---|---|
| Finance Hub / Agent Finance / Finance Reports (F1 loader) | **YES** |
| Settlements list primary counts | **YES** (`isFinanceQaSettlement`) |
| Settlement detail QA badge | **YES** |
| PDF finance export | **N/A** (deferred) |
| CSV finance export | **N/A** (deferred helper only) |
| Dashboard financial KPIs | **Not using F1 loader** — nav only / other stats — **mismatch risk if old profit widgets resurface** |
| `AdminAgentReport` | **NO** — `FinancialEngine.aggregate` without fixture filter → **QA LEAKAGE RISK** |
| Diagnostics | May include fixtures (allowed) |

---

## PART I — `company_payments`

| Item | Finding |
|---|---|
| Sample count | 3 |
| Shape | Wallet-linked `type=company_payment`, `status=completed`, amounts negative vs wallet |
| Settlement allocation fields | **Absent** |
| Relation to trip settlements | **None observed** |
| UI | Isolated in `AdminLegacyFinancePanel` / wallets — labeled not part of V2 trip ledger |
| Reports (F1 Hub) | **Not counted** in trip COMPLETE totals |
| Classification | **UNALLOCATED** relative to settlement graph; wallet movement **LEGACY**; treat as **NEEDS_REVIEW** before any allocation UI |

**Rule remains:** no heuristic matching; no silent migration.

---

## PART J — WALLET vs EARNINGS vs SETTLEMENT (accountant model)

```
Trip completes (status_code)
    ↓
Immutable money snapshot on order
    ↓
Cash: customer → driver cash drawer
      Driver owes company (platform fee ± VAT) via SETTLEMENT (DRIVER_PAYS_COMPANY)
Online: gateway → company
      Company owes driver net via SETTLEMENT (COMPANY_PAYS_DRIVER)
    ↓
Agent share = % of platform fee from TRIP SNAPSHOT (not live agent %)
    ↓
Wallet balance = separate LEGACY ledger (may move via company_payments / adjust)
```

**Forbidden collapse:** `wallet.balance ≠ driver trip earnings ≠ cash held ≠ settlement outstanding ≠ company receivable`.

---

## PART K — REPORTS AUDIT

| Report | Claims | Actually uses | F1/F2? | QA excluded? | Partial→0? | Verdict |
|---|---|---|---|---|---|---|
| Finance Hub summary/table | Accountant KPIs | `AccountantFinanceReadModel` | YES | YES | NO (omit) | **TRUSTED** |
| Agent Finance | Same scoped | Same | YES | YES | NO | **TRUSTED** |
| Finance Reports on-screen | Same | Same | YES | YES | NO | **TRUSTED** |
| Finance Channels | Cash/online ops | `FinanceCashOnlineSummary` | Partial | Via company service paths — verify | — | **PARTIALLY_TRUSTED** |
| Settlements | Due/paid/remaining | Ledger fields | Settlement V2 | YES for QA stl | N/A | **TRUSTED** |
| Admin Agent Report | Bookings/sales/commission | `FinancialEngine.aggregate` + **live** `agent.agentTotal` % | **NO** | **NO** | Risk | **UNSAFE / LEGACY** |
| Reports Hub | Navigation | Links | Mixed | — | — | **LEGACY** |
| Profits route | Financial report | Redirects to Hub | F2 | — | — | **LEGACY shell / TRUSTED target** |

---

## PART L — PDF AUDIT

| Item | Status |
|---|---|
| Current finance PDF generator | **Not shipped** (UI copy: CSV/PDF deferred) |
| Settlement receipt | On-screen widget, not accountant PDF pack |
| Arabic RTL / Cairo | Used in some Admin screens; **no** finance PDF pipeline proven |
| QA fixtures in PDF | N/A |
| Risks | Building PDF from legacy Agent Report or unfiltered queries would leak fixtures / wrong agent math |

### Future accountant PDF structure (F3-B3)

Report title · period · scope · generated at (Asia/Riyadh) · summary · completed trips · financially complete / incomplete · gross · collected · uncollected · platform fee · VAT · driver net · agent share · receivables · payables · settlement status · exceptions · detail lines.  
Missing values: **—** (never fake `0.00`).

---

## PART M — CSV AUDIT

| Item | Status |
|---|---|
| Helper | `lib/core/finance/csv_export.dart` — Arabic disclaimer header, Riyadh clock, formula escape |
| UI export | **Deferred** on Finance Reports |
| Encoding | UTF-8 text; **no BOM** currently |
| Test `phase_8a_csv_errors_test` | **FAILS** — expects English `not a tax invoice`, `Currency: SAR`, `ZATCA`; implementation is Arabic (`ليس فاتورة ضريبية`, `العملة:`) |

**Classification:** `KNOWN_PRE_EXISTING_FINANCE_TEST_FAILURE` — **do not** change CSV merely to green the suite in F3-A.

### Proposed canonical CSV schema (F3-B3)

`order_id, completed_at_riyadh, country, driver_name, payment_method, collection_status, financial_quality, gross, customer_total, platform_fee, vat, driver_net, agent_id_snapshot, agent_share, settlement_id, settlement_status, currency`  
Missing → empty cell / `—`, never coerced zero.

---

## PART N — ROLE / COUNTRY SCOPING

| Role | Finance access |
|---|---|
| Super Admin | All finance routes; global Hub |
| Finance staff (`isFinance` claim, not agent) | `_financeRoutes` only |
| Country Agent | **Only** `AdminAgentFinance` among finance; global Hub/settlements **denied** |
| Support / Partner / Transport | No finance admin |

**Loader rule (Hub):** Country Agent query constrained to `scopedCountryRef` **before** totals; Super Admin does not silently inherit reports UI country.

### Risky routes

| Route | Risk |
|---|---|
| `AdminAgentReport` | Country orders aggregated without F1 QA filter; commission from **current** agent % |
| Legacy wallets / `company_payments` lists | Global SuperAdmin reads — OK if labeled LEGACY |
| Any future export that scans `order` without `AccountantFinanceScope` | Cross-country leakage |

Stale `Rev_dloh_agent` on profile is fallback only when RBAC phase non-authoritative — claims `country_id` preferred.

---

## PART O — ACCOUNTANT ROLE

**ACCOUNTANT ROLE EXISTS:** **PARTIAL**

- Exists: Finance capability / `isFinance` / `AdminPermRole.finance` / `isFinanceStaff`
- Missing: dedicated **Accountant** persona distinct from SuperAdmin/Finance writer

### Proposed permissions (design only)

| Allow | Deny |
|---|---|
| View Finance Hub, Money movement, Settlements (read), Reports | Change roles / edit drivers / countries / pricing |
| Export PDF/CSV (when built) | Mutate immutable trip snapshots |
| | Delete historical financial records |
| Settlement payment/approval | **Separate** capability (already closer to SuperAdmin/Finance writers) |

---

## PART P — IMMUTABILITY

| Class | Examples | Notes |
|---|---|---|
| IMMUTABLE FINANCIAL SNAPSHOT (intended) | `total_mndob2`, `total_app`, `total_vat`, `total_mndob`, agent snapshot fields | V3 docs say server-authored once; historical gaps remain |
| MUTABLE OPERATIONAL METADATA | status, locations, support fields | — |
| SETTLEMENT STATE | draft→locked→partially_paid→settled/void | CF-gated |
| AUDIT HISTORY | settlement events / payment reversals | append-oriented |

**Flags (no fix in F3-A):**

- Admin Booking Details does not show a dedicated money-edit form in grep, but order docs remain client-writable under rules unless locked — **needs rules/CF audit in F3-B**
- SuperAdmin **LEGACY** `adminAdjustDriverWallet` mutates wallet, not trip snapshot
- No evidence F3-A of Admin UI rewriting agent snapshot; Agent Report **recomputes** commission live (presentation risk)

---

## PART Q — REAL DATA HEALTH (read-only)

**Sample basis:** Firestore `order` where `status_code==completed` (plus fill), settlements/payments/company_payments limits. **Not a full census.**

| Metric | Value |
|---|---|
| REAL COMPLETED TRIPS | **2** |
| QA COMPLETED (excluded) | **4** |
| FINANCIAL COMPLETE (real) | **0** |
| PARTIAL (real) | **2** |
| UNRESOLVED (real) | **0** |
| CASH COLLECTED (real) | **0** |
| CASH UNCOLLECTED (real) | **2** |
| ONLINE COMPLETED (real) | **0** |
| REAL SETTLEMENTS | **0** |
| QA SETTLEMENTS | **1** (settled) |
| OPEN RECEIVABLES (COMPLETE basis) | **0** (no COMPLETE real trips) |
| OPEN PAYABLES | **0** |
| UNALLOCATED / LEGACY `company_payments` | **3** (wallet company_payment; no settlement link) |
| ORPHAN FINANCIAL RECORDS | Settlement graph mostly QA-only; no real settlement orphans observed |

---

## PART R — F3-B IMPLEMENTATION PLAN (do not implement in F3-A)

| Phase | Scope |
|---|---|
| **F3-B1** | Canonical reconciliation read model (join trip → snapshot quality → collection → settlement) + exception list; read-only |
| **F3-B2** | Accountant reports UX on recon model; retire/redirect unsafe Agent Report numbers or hard-gate |
| **F3-B3** | PDF + CSV exporters (RTL, Riyadh, `—` for missing, same QA exclusion as Hub) |
| **F3-B4** | Settlement operational workflow polish on **real** eligible trips (still CF semantics unchanged) |
| **F3-B5** | Role/scoping hardening; optional Accountant persona; rules against snapshot mutation |
| **F3-B6** | E2E financial verification on controlled non-destructive fixtures + real-data dry reports |

---

## TESTS / ANALYZE BASELINE

| Check | Result |
|---|---|
| `flutter analyze` finance hub/settlements/core | **PASS** (no issues) |
| `finance_f1_semantics_test` | **PASS** |
| `finance_f2_1_consistency_test` | **PASS** |
| `admin_qa_fixture_test` | **PASS** |
| `finance_csv_escape_test` | **PASS** |
| `phase_8a_csv_errors_test` (finance CSV disclaimer) | **FAIL** → `KNOWN_PRE_EXISTING_FINANCE_TEST_FAILURE` |

---

## REQUIRED SUMMARY BLOCK

================================  
FINANCIAL SURFACES  
================================  

TOTAL: 19  
TRUSTED: 5  
PARTIAL: 8  
UNSAFE: 2  
LEGACY: 4+  

================================  
REAL DATA HEALTH  
================================  

COMPLETED (real): 2  
FINANCIAL COMPLETE: 0  
PARTIAL: 2  
UNRESOLVED: 0  

================================  
CASH  
================================  

COLLECTED: 0  
UNCOLLECTED: 2  
COMPANY RECEIVABLE (COMPLETE basis): 0 (blocked by PARTIAL snapshots)  

================================  
SETTLEMENTS  
================================  

REAL: 0  
SETTLED (QA only): 1  
OPEN (real): 0  
ORPHANS: 0 real observed  

================================  
REPORTS  
================================  

CANONICAL: Hub / Agent Finance / Finance Reports on-screen  
LEGACY: Agent Report, Reports Hub, Profits shell  
QA LEAKAGE: Agent Report (**YES risk**); Hub (**NO**)  

================================  
PDF  
================================  

CURRENT STATUS: deferred / not shipped  
RISKS: building from legacy aggregators  

================================  
CSV  
================================  

CURRENT STATUS: helper only; UI deferred  
KNOWN FAILURE: `phase_8a_csv_errors_test` = `KNOWN_PRE_EXISTING_FINANCE_TEST_FAILURE`  

================================  
ROLES  
================================  

SUPER ADMIN: full finance  
COUNTRY AGENT: Agent Finance only (scoped)  
ACCOUNTANT: PARTIAL (Finance claim; no dedicated persona)  
CROSS-COUNTRY RISKS: Agent Report; any unscoped export  

================================  
RECONCILIATION MODEL  
================================  

STATUS: **READY** (design) / **NOT_READY** (production usability until real COMPLETE + settlements)  

================================  
F3-B PLAN  
================================  

B1: recon read model  
B2: accountant reports  
B3: PDF/CSV  
B4: settlement workflow  
B5: role/scoping  
B6: E2E verification  

================================  
SAFETY  
================================  

FINANCIAL WRITES: 0  
MIGRATIONS: 0  
PRODUCTION DEPLOY: NO  
F1/F2 MODIFIED: NO  
DRIVER MODULE MODIFIED: NO  
GEO COMPAT MODIFIED: NO  

================================  
FINAL  
================================  

F3-A: **READY_FOR_REVIEW**  
READY_TO_IMPLEMENT_F3-B: **NO** (await human review of this audit)

STOP.
