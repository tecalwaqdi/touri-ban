# Finance V3 Architecture

## Principle

Evolve FIN V2. Do not fork a second recognition engine.

```
Write model (future, flag-gated):
  financial_events → accounting_journal (balanced) → claims/settlements

Recognition (current V2, keep):
  order historical fields → FinancialAccountingEngine / financial_accounting_v2.js

Read models:
  Admin dashboards / reports / rollups (derived from engine or journal)
```

## Engine versioning

`FINANCIAL_ENGINE_VERSION` (config, not yet switched in Production):

| Value | Behavior |
|---|---|
| `v2` | Current Production recognition |
| `v3` | V2 + snapshot preference when present + terminology + stricter DQ |
| `legacy` | Forbidden for new Admin reads |

Only one ledger writer may be active.

## Drill-down contract

Every KPI must expose:

- metric_id
- currency
- filter signature
- source (`server_v2` | `snapshot_v3` | `unavailable`)
- confidence mix
- sample order ids (bounded)

## Forbidden

- Summing mixed currencies
- Using `.limit()` for company totals
- Showing `0` when backend unavailable
- Inventing historical agent/VAT/commission
- Client-authoritative finance writes
