# Finance V3 Data Model

## Existing (V2) — keep

- `order` pricing majors: `total`, `total_app`, `total_vat`, `total_mndob`, `total_mndob2`, `ksm`, `currency`
- Settlement graph: `financial_settlements*`, claims, lines, payments, allocations
- `financial_periods`, `financial_config/runtime`
- LEGACY: `wallets`, `company_payments`

## Prospective (V3) — additive only

### `order.financial_snapshot` (map, server-authored when enabled)

See Dart `TripFinancialSnapshot` / JS `financial_snapshot_v3.js`.

Rules:

- Written once at price lock / trip completion (whichever is configured).
- Never overwritten by later commission config.
- Missing on historical orders → recognition falls back to V2 field analysis + `legacy_unprovable` where needed.

### `financial_events/{eventId}` (future)

Idempotent domain events. Not written in this foundation PR.

### `accounting_journal/{journalId}` (future)

Balanced debit/credit entries. Not written until CoA + flags ready.

### `finance_daily_rollups/{id}` (future read model)

Rebuildable. Never source of truth.

## Money

Always minor units (int) + ISO currency. Use `MoneyAmount` / JS `toMinor`.
