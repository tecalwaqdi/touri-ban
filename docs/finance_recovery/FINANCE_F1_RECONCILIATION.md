# Finance F1 — Reconciliation (re-run of F0 samples under new semantics)

**Branch:** `recovery/admin-finance-f1-foundation`  
**Method:** Same F0 sample trip IDs; evaluated with F1 axes.  
**No live writes.** QA fixtures excluded from live KPI contribution.

Legend:

- **In completed count?** = operational completion (status_code / legacy)
- **In financial totals?** = COMPLETE money resolution + in completed set + not fixture

---

## Sample 1 — Live cash uncollected

| Field | Value |
|---|---|
| Trip ID | `03392f80a1007caa396054888b200465fb2c3c23476d9c6f8a81d6421d756647` |
| Operational completed? | YES (`status_code=completed`) |
| Payment paid? | NO (`pending_cash`) |
| Cash collected? | NO |
| Money resolution quality | PARTIAL / UNRESOLVED (`total_mndob2` / `total_mndob` missing) |
| Gross / Company / VAT / Driver | Prefer fields incomplete; do **not** fabricate |
| Agent attribution | MISSING (no snapshot) |
| Settlement | none |
| Outstanding | uncollected — not recognized as COMPLETE receivable |
| Included in completed count? | YES |
| Included in financial totals? | NO |
| Why? | Ops complete; money incomplete → count yes, amount no |

---

## Sample 2 — Live cash uncollected (50 SAR shape)

| Field | Value |
|---|---|
| Trip ID | `7b9a80c30646f77148cf443a15db766e65a6105f003565683ac1d35b0e9d04d3` |
| Operational completed? | YES |
| Payment paid? | NO |
| Cash collected? | NO |
| Money quality | PARTIAL (total+app present; mndob/mndob2 missing) |
| Included in completed count? | YES |
| Included in financial totals? | NO |
| Why? | Same as sample 1 |

---

## Sample 3 — QA fixture cash collected (50 / 7.5 / 0 / 42.5)

| Field | Value |
|---|---|
| Trip ID | `fin7_ctrl_1788321182908` |
| Operational completed? | YES |
| Payment paid? | YES (`cash_collected`) |
| Cash collected? | YES |
| Money quality | COMPLETE (preferred fields present) |
| Gross / Company / VAT / Driver | 50 / 7.5 / 0 / 42.5 |
| Agent | MISSING |
| Included in completed count (live KPI)? | **NO** (fixture excluded) |
| Included in financial totals (live KPI)? | **NO** |
| Why? | `isFinanceQaFixture` / `AdminQaFixture` — diagnostics only |

---

## Sample 4 — QA fixture + agent minor

| Field | Value |
|---|---|
| Trip ID | `fin_rt_cash_1788391755618` |
| Operational completed? | YES |
| Payment paid? / Cash collected? | YES / YES |
| Money quality | COMPLETE for core split |
| Agent attribution | CONFIDENT (`agent_id` + `agent_amount_minor`) — historical snapshot preserved |
| Live KPI inclusion | **NO** (fixture) |
| Why? | Fixture exclusion; agent snapshot not rewritten |

---

## Sample 5 — Paid online, cancelled (counterexample)

| Field | Value |
|---|---|
| Trip ID | `669eb8e5b99d521e2ac938ec180df0dfdfc0415834bfc316d1f9bb8d2a8d1ec0` |
| Operational completed? | **NO** (`cancelled_by_driver`) |
| Payment paid? | YES (`paid`) — payment axis independent |
| Cash collected? | N/A (online) |
| Money quality | May be COMPLETE on fields |
| Included in completed count? | **NO** |
| Included in financial totals (completed revenue)? | **NO** |
| Why? | Payment must not make incomplete/cancelled trip completed |

---

## Invariants checked

1. No unexplained inclusion of cancelled+paid into completed count.  
2. Incomplete money does not silently enter COMPLETE gross as zero.  
3. Fixtures do not inflate live completed count / value.  
4. Agent missing → not backfilled from current country agent.

**Unexplained difference vs fabricated live totals:** N/A — F1 does not publish a single live dashboard number yet; projection is explainable per sample.
