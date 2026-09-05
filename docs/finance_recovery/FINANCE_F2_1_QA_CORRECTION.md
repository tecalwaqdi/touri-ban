# Finance F2.1 — Human QA correction notes

## Consistency root cause (proven)

| Surface | Data path | Fixture exclusion | Country scope |
|---|---|---|---|
| Finance Hub (F2) | `AccountantFinanceLoader` → F1 read model | Summary: YES · Table: **NO (bug)** | Super Admin wrongly inherited `AdminCountryScope.activeCountryRef` |
| Reports (F2) | `FinancialAccountingLoader` → CF `server_v2` | **NO** | Explicit filter / all countries |

Human QA: Hub KPIs = 0 while Reports showed ~150 SAR for «هذا الشهر».

**Explanation:** Period contained QA fixtures (`fin7_ctrl_*` / `fin_rt_*`). Hub summary excluded them (0 real COMPLETE totals). Hub table still listed fixtures. Reports CF path included fixtures → 150 SAR.

**F2.1 fix:**

1. Exclude fixtures from money-movement table + report on-screen set (`AdminQaFixture` / `isFinanceQaFixture`).
2. Super Admin all-countries: do not auto-apply `AdminCountryScope.activeCountryRef`.
3. On-screen Reports use the same `AccountantFinanceLoader` / F1 model as Hub.

## Contrast

Shared `AccountantFinanceText` uses `theme.secondaryText` (dark ink) for headings/values — never `theme.info` (white).
