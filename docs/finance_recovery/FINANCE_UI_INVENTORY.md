# Finance UI inventory (F0 audit)

**Base SHA:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Scope:** Admin (`admin/Admi`) only — audit, no redesign.

Role access references `AdminRoleService.canAccessRoute` (`lib/backend/admin_role_service.dart`).

---

## Primary finance routes

| ROUTE | SCREEN | ROLE ACCESS | DATA SOURCE | QUERY / LOADER | CALCULATION | WRITER | READER | STATUS | LEGACY/CURRENT/DUPLICATE |
|---|---|---|---|---|---|---|---|---|---|
| `/adminFinanceHub` | `AdminFinanceHubWidget` | Super Admin, Finance staff (`_financeRoutes`); agents **no** hub | Orders + finance loaders via hub tiles | Navigation hub | KPI cards from company/agent snapshots | None (UI) | Admin | CURRENT | CURRENT hub |
| `/adminFinanceChannels` | `AdminFinanceChannelsWidget` | Finance routes set | Orders → `FinancialOrderAdapter` / accounting engine | Order queries in widget/loaders | Cash vs online channel KPIs | None | Admin | CURRENT | CURRENT |
| `/adminFinanceReceivables` | `AdminFinanceReceivablesWidget` | Finance routes set | Order financial lines | Order reads | Receivables / outstanding presentation | None | Admin | CURRENT | CURRENT |
| `/adminFinanceAgents` | `AdminAgentFinanceWidget` | Super Admin **and** Country Agent (`_agentRoutes`) | Agents (`user`) + country-scoped orders | Agent list + country filter | Agent attribution / prospective commission | None | Admin + Agent | CURRENT | CURRENT (agent-safe surface) |
| `/adminSettlements` | `AdminSettlementsWidget` | Finance routes (not agent list) | `financial_settlements` (+ order lines) | Settlement list queries | Settlement status presentation | CF settlement writers | Admin | CURRENT | CURRENT |
| `/adminSettlementDetails` | `AdminSettlementDetailsWidget` | Finance routes | Settlement doc + lines | By `settlementId` | Detail + payment progress | CF settlement payments | Admin | CURRENT | CURRENT |
| `/adminSettlementReceipt` | `AdminSettlementReceiptWidget` | Finance routes | Settlement doc | By id | Receipt presentation | None | Admin | CURRENT | CURRENT |
| `/adminReconciliation` | `AdminReconciliationWidget` | Finance routes | Orders / accounting lines | Reconciliation queries | Bucket / recon status | None | Admin | CURRENT | CURRENT |
| `/adminFinanceReports` | `AdminFinanceReportsWidget` | Finance routes | Orders + CSV helpers | Date/country filters | Report aggregates + CSV | None (export) | Admin | CURRENT | CURRENT |
| `/adminFinanceAudit` | `AdminFinanceAuditWidget` | Finance routes | Orders + audit presentation | Audit loaders | Exception / quality flags | None | Admin | CURRENT | CURRENT / diagnostic-leaning |
| `/adminProfits` | `AdminProfitsWidget` | Linked from Finance Hub | Orders / profits UI | Widget queries | Profit presentation | None | Admin | CURRENT | Possibly overlapping with hub KPIs |

---

## Related non-finance routes that show money/trip counts

| ROUTE | SCREEN | ROLE ACCESS | DATA SOURCE | NOTE |
|---|---|---|---|---|
| `/` dashboard (`Home22Dashboard`) | Dashboard stats | Super Admin / Agent | `dashboard_stats_loader.dart` | **Operational** completed count via `status_code` aggregates — not finance ledger |
| Bookings (`AdminALLhgZ`) | Bookings table | Super Admin / Agent | `order` + ops filters | Lifecycle via `status_code`; money columns may appear |
| Booking details | `AdminBookingDetails` | Panel roles | Single order | Shows totals / payment fields |
| Reports hub | `AdminReportsHub` | Panel | Mixed | May include financial report entry points |

---

## Core calculation modules (not screens)

| Path | Role |
|---|---|
| `lib/core/finance/financial_accounting_engine.dart` | Canonical Admin reporting engine (lifecycle ≠ payment buckets) |
| `lib/core/finance/financial_order_adapter.dart` | Order → financial snapshot |
| `lib/core/finance/financial_engine.dart` | Older `OrderStatusHelper` + money helpers (**conflates paid/complete in places**) |
| `lib/core/finance/settlement_preview.dart` | Read-only settlement math preview |
| `lib/core/finance/settlement_ledger_client.dart` | Client to CF settlement ledger |
| `lib/core/finance/finance_company_service.dart` / `finance_company_snapshot.dart` | Company finance snapshot |
| `lib/core/finance/finance_agent_account.dart` / `finance_agent_attribution.dart` | Agent attribution contract |
| `lib/core/finance/finance_cash_online_summary.dart` | Cash/online summary |
| `lib/core/finance/finance_comparable_kpis.dart` | KPI comparables |
| `lib/core/finance/v3/trip_financial_snapshot.dart` | Immutable trip snapshot schema (v3) |
| `lib/core/finance/csv_export.dart` | CSV export helpers |
| `lib/components/admin_finance_kpi_groups.dart` | KPI group widgets |
| `lib/components/admin_financial_v2_panel.dart` | V2 finance panel |
| `lib/components/admin_legacy_finance_panel.dart` | Legacy finance panel |

---

## Cloud Functions (writers / controls)

| File | Purpose |
|---|---|
| `firebase/functions/financial_accounting_v2.js` | Server-side accounting line logic |
| `firebase/functions/settlement_ledger.js` | Settlement create/lock |
| `firebase/functions/settlement_payments.js` | Settlement payments |
| `firebase/functions/finance_controls.js` | Finance controls / feature gates |
| `firebase/functions/finance_aggregation_metrics.js` | Aggregation metrics |
| `firebase/functions/finance_periods.js` | Periods |
| `firebase/functions/finance_policy.js` | Policy |
| `firebase/functions/finance_feature_flags.js` | Feature flags |

Untracked local copy `cash_collection_realization.js` may exist in workspace; **not** assumed part of this branch’s committed tree.

---

## Duplicate / overlap notes (no fix)

1. **Two client engines:** `FinancialAccountingEngine` (preferred reporting) vs `OrderStatusHelper` / `financial_engine.dart` (older; mixes Arabic “مكتملة” into paid).
2. **Dashboard completed** uses operational `status_code` counters; Finance KPIs use accounting engine buckets — definitions differ by design and must not be merged blindly.
3. **Profits + Hub + Channels + Reports** may re-aggregate overlapping metrics with different filters/fixtures.
