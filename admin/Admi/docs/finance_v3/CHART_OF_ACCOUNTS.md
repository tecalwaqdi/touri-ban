# Chart of Accounts (Target)

Preliminary CoA for Toury Taxi. **Not activated for Production writes yet.**

## Assets

| Code | Name |
|---|---|
| 1000 | Cash / Bank (external — not integrated) |
| 1100 | Payment Gateway Clearing |
| 1200 | Driver Cash Receivable |
| 1210 | Agent Receivable |
| 1290 | Other Receivables |

## Liabilities

| Code | Name |
|---|---|
| 2000 | Driver Payable |
| 2100 | Agent Payable |
| 2200 | VAT Payable |
| 2300 | Refund Payable |

## Revenue

| Code | Name |
|---|---|
| 4000 | Platform Commission Revenue |
| 4100 | Other Service Revenue |

## Expense

| Code | Name |
|---|---|
| 5000 | Payment Gateway Fees |
| 5100 | Agent Commission Expense |
| 5200 | Refund / Adjustment Expense |
| 5300 | Promotional Discount Expense |

## Clearing

| Code | Name |
|---|---|
| 9000 | Cash Collection Clearing |
| 9100 | Online Payment Clearing |
| 9200 | Settlement Clearing |

## Rules

- Journal entries must balance per currency.
- Posted journals immutable (reverse + correct).
- Do not invent bank balances without integration → label **External / Not Integrated**.
