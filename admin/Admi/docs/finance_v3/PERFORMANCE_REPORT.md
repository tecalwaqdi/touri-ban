# Performance Report (Current)

| Surface | Pattern | Classification |
|---|---|---|
| Exception scan | full order collection get | ACCEPTABLE at ~61–low thousands; BLOCKING at tens of thousands without rollups |
| Finance loader | server aggregate preferred | FAST/ACCEPTABLE when CF healthy |
| Ledger UI limits 80–500 | display pagination | OK for tables; **must not** define company totals |
| Future rollups | rebuildable daily | Planned read model |

V3 rule: browser must not O(N) scan all orders for executive KPIs.
