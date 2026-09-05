# Finance F2 — UI Architecture

**Branch:** `recovery/admin-finance-f2-ui`  
**Base:** `055496e61fdb9807644c18efe224d834f77b3dd2` (F1 foundation)

## Canonical entry

| Role | Route | Widget |
|---|---|---|
| Super Admin / Finance staff | `/adminFinanceHub` | `AdminFinanceHubWidget` |
| Country Agent | `/adminFinanceAgents` | `AdminAgentFinanceWidget` |

Both use the **same** F1 stack:

`AccountantFinanceLoader` → `AccountantFinanceReadModel` → presentation rows/labels.

No widget-level money formulas.

## Layers

1. **Load** — `accountant_finance_loader.dart` (scoped Firestore order scan)
2. **Aggregate** — F1 `AccountantFinanceReadModel`
3. **Present row** — `AccountantTripRow` via F1 semantics + amount resolution
4. **Arabic labels** — `AccountantFinanceLabels` / softened `SettlementStateLabels`
5. **UI** — summary strip, alerts, money-movement table, trip details drawer

## Absolute rule

Accountant totals come **only** from `AccountantFinanceReadModel` (or F1 helpers for per-trip display).

## Read-only

Opening Finance does not write orders, settlements, wallets, or agent backfill.
Settlement payment actions remain on settlement details with existing CF handlers.
