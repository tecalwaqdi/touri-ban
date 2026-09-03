# Parity Report (Baseline)

| Metric | Legacy Admin | V2 Engine | V3 Foundation |
|---|---|---|---|
| Recognition | mixed client | FinancialAccountingEngine + CF | Extends V2 + snapshot overlay for agent fields |
| Cross-currency sum | risk | forbidden | forbidden |
| Fake zero on CF fail | risk | unavailable exception | FinancialMetricValue.unavailable |
| Historical invent rates | risk | not done | explicitly forbidden |

**Status:** V3 foundations landed; full KPI parity matrix pending Production shadow run (not deployed this session).
