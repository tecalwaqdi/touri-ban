# Finance reconciliation sample (F0)

**Base SHA:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Method:** read-only Admin SDK samples from project `tutorial-multi-language-70gx4j`.  
**No writes.** Fixtures labeled explicitly — not used as live KPI truth.

---

## Sample 1 — Completed cash, uncollected (live)

```
Trip ID: 03392f80a1007caa396054888b200465fb2c3c23476d9c6f8a81d6421d756647
Operational status: completed
Payment method: Cash
Payment status: pending_cash
Gross: total=200; total_mndob2=null
Collected: NO
Collected by: —
Company commission: total_app=30
VAT: total_vat=0
Driver net: total_mndob=null (not stored)
Agent amount: null
Settlement: none
Outstanding: uncollected gross/commission unexplained at field level
Can every SAR be explained: NO (missing total_mndob2 / total_mndob; pending cash)
```

## Sample 2 — Completed cash, uncollected (live)

```
Trip ID: 7b9a80c30646f77148cf443a15db766e65a6105f003565683ac1d35b0e9d04d3
Operational status: completed
Payment method: Cash
Payment status: pending_cash
Gross: total=50; total_mndob2=null
Collected: NO
Collected by: —
Company commission: total_app=7.5
VAT: 0
Driver net: null
Agent amount: null
Settlement: none
Outstanding: uncollected
Can every SAR be explained: NO
```

## Sample 3 — Completed cash collected (QA fixture — not live KPI)

```
Trip ID: fin7_ctrl_1788321182908
Operational status: completed
Payment method: Cash
Payment status: cash_collected
Gross: total_mndob2=50 (= total)
Collected: YES
Collected by: driver (cash_collection_status=collected)
Company commission: 7.5
VAT: 0
Driver net: 42.5  (50 − 7.5 − 0)
Agent amount: null
Settlement: none on doc
Outstanding: driver→company for 7.5 until settled (model)
Can every SAR be explained: YES for money split (fixture)
is_test_fixture: true
```

## Sample 4 — Completed cash collected + agent minor (QA fixture)

```
Trip ID: fin_rt_cash_1788391755618
Operational status: completed
Payment method: cash
Payment status: cash_collected
Gross: 50
Collected: YES / driver
Company commission: 7.5
VAT: 0
Driver net: 42.5
Agent amount: agent_amount_minor=38 (0.38 major if SAR-2 — verify scale in engine)
Agent id: JkYePqE6LkVVkHKbKmdqEmVqDqr1
Settlement: none on doc
Can every SAR be explained: PARTIAL (agent minor vs total_app relationship needs F1 check)
is_test_fixture: true
```

## Sample 5 — Paid but NOT completed (live) — critical counterexample

```
Trip ID: 669eb8e5b99d521e2ac938ec180df0dfdfc0415834bfc316d1f9bb8d2a8d1ec0
Operational status: cancelled_by_driver
Payment method: OnlinePayment
Payment status: paid
Gross: total_mndob2=50
Collected: YES (online paid)
Collected by: company/gateway
Company commission: 7.5
VAT: 0
Driver net: 42.5 (stored) — eligibility for settlement should be rejected by lifecycle
Agent amount: 38 minor + agent_id present
Settlement: none
Outstanding: refund/review path — NOT a completed trip
Can every SAR be explained: PARTIAL (money fields present; ops says cancelled)
Must NOT count as completed trip: YES
```

---

## Sample coverage gaps

| Desired | Availability in sample window |
|---|---|
| Completed online/card live | Sparse — completed sample methods mostly Cash |
| Incomplete but paid | Found (cancelled + paid online) |
| Completed unsettled | Found (completed + pending_cash) |
| Refunded | Query returned empty in this pass |
| Chargeback | No first-class docs sampled |

---

## Verdict

| Question | Answer |
|---|---|
| FULLY EXPLAINABLE across samples? | **NO** |
| UNEXPLAINED DIFFERENCE | Live completed cash missing `total_mndob2`/`total_mndob`; agent snapshot sparse; fixtures fuller than live |
| SAFE to treat fixtures as production truth? | **NO** |
