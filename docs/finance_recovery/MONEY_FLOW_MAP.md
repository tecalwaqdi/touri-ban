# Money flow map (F0)

**Base SHA:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**Method:** traced from Admin finance engines + settlement preview + live samples. No assumptions beyond code.

---

## CASH trip (current production-dominant)

```
Customer
  → pays cash to Driver at trip end
  → Driver holds cash (cashHeldByDriver ≈ customer gross when collected)
  → Company is owed platform fee (total_app) + VAT (total_vat)
  → Driver keeps driver net (total_mndob or derived)
  → Agent: prospective share of platform fee if exclusive country agent;
           per-order agent_* snapshot when present (often missing on live)
  → Settlement: typically driverPaysCompany for cash side
       (cashHeld − driverNet) − online offsets
```

| Stage | Who holds money | Who owes whom |
|---|---|---|
| After completed, before collection | Customer unpaid / driver not confirmed | Customer→driver (pending_cash) |
| After `payment_status=cash_collected` | **Driver holds cash** | Driver→company (commission+VAT); driver keeps net |
| After settlement settled | Per settlement payments | Cleared per settlement doc |

Evidence:

- `SettlementPreview`: cashHeld − cashDriverEntitlement = driverCashLiability.
- Live completed cash samples often still `payment_status=pending_cash` → uncollected.
- Fixture cash_collected rows show full `total_mndob2` / `total_app` / `total_mndob` split.

---

## ONLINE / CARD trip (historical + current capability)

Live completed sample in a 40-doc window was **cash-heavy**; online still exists (e.g. cancelled+paid OnlinePayment sample).

Intended flow from engines:

```
Customer
  → pays gateway / company merchant account
  → Company holds gross
  → Company owes Driver net (onlineDriverEntitlement)
  → Company retains total_app + total_vat
  → Agent: same attribution rules on platform fee / snapshot
  → Settlement: often companyPaysDriver (online liability)
```

| Stage | Who holds money | Who owes whom |
|---|---|---|
| After `payment_status=paid/captured` | **Company / gateway** | Company→driver (net) |
| Settlement | Ledger payments | Clears company↔driver net |

---

## Dimensions that must stay separate

1. Trip operational status (`status_code`)
2. Payment method (`PaymentMethod`)
3. Payment status (`payment_status`)
4. Cash collection status (`cash_collection_status`)
5. Who holds cash now (derived: cash collected → driver)
6. Gross / commission / VAT / driver net fields
7. Agent due (snapshot vs prospective)
8. Settlement status (`financial_settlements.status`)
9. Refund / chargeback (payment_status / sparse chargeback surface)

---

## WHO HOLDS CASH (summary)

**After successful cash collection confirmation: Driver.**  
Until then: uncollected (customer still owes / pending_cash).

## WHO OWES COMPANY (summary)

**On cash collected completed trips: Driver owes company commission (+ VAT as modeled).**  
On online paid completed trips: Company already holds; owes driver net.

---

## Gaps (no fix in F0)

- Incomplete money fields on many live cash completes (`total_mndob2` null).
- Sparse per-order agent snapshots → agent due often not trip-explainable.
- Chargeback not first-class in Admin inventory.
- Online completed volume low in sampled window — model must still support online.
