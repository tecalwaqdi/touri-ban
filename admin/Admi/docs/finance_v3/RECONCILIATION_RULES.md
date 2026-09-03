# Reconciliation Rules

Detect (non-exhaustive):

- Completed without driver
- Collected before completed
- Online paid not completed
- Incomplete financial record
- Unallocated legacy company_payment (historical — do not auto-heal)
- Settlement totals mismatch
- Journal imbalance (future)
- Wallet balance unprovable from ledger (future)

Severity: critical / high / medium / low  
blocksClose only for true period blockers (not cancelled-without-driver).
