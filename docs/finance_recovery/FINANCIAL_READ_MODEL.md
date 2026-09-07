# Financial Read Model (F1)

**Module:** `admin/Admi/lib/core/finance/accountant_finance_read_model.dart`  
**Type:** Deterministic **read-only projection** over existing orders.  
**Not:** a new ledger, Firestore write path, or UI redesign.

---

## Entry point

```dart
AccountantFinanceReadModel.aggregate(
  orders: orders,
  scope: AccountantFinanceScope(...),
  currency: 'SAR',
);
```

---

## Exposed fields

| Field | Rule |
|---|---|
| `completedTripCount` | Operationally completed, in scope, non-fixture, matching currency |
| `completedTripsWithCompleteFinancialData` | COMPLETE money resolution |
| `completedTripsWithPartialFinancialData` | PARTIAL |
| `completedTripsWithUnresolvedFinancialData` | UNRESOLVED |
| `completedGross` | Sum gross **only** for COMPLETE |
| `collectedAmount` | COMPLETE + financially paid (engine) |
| `uncollectedAmount` | COMPLETE + not paid |
| `companyCommission` / `vat` / `driverNet` | COMPLETE only |
| `companyReceivable` | Cash COMPLETE+paid → signed cash position / fee+VAT |
| `driverPayable` | Online COMPLETE+paid → driver net |
| `settledAmount` / `outstandingAmount` | Order settlement markers + paid outstanding (read-only) |
| `refundAmount` / `chargebackAmount` | Explicit payment_status / markers |
| `qaFixturesExcluded` | Count skipped fixtures |
| `unattributedAgentCompleted` | Completed with agent attribution MISSING |
| `source` / `confidenceNote` | Provenance |

---

## Completed count vs reconciliable value

Example intent for F2 UI (not built in F1):

- رحلات مكتملة: `completedTripCount`
- قيمة مالية موثقة: `completedGross` (COMPLETE only)
- رحلات ببيانات مالية ناقصة: `partial + unresolved`

---

## Dependencies

1. `FinancialTripSemantics` — completion / payment / collection / fixture
2. `FinancialOrderAdapter` — OrderRecord → snapshot
3. `FinancialAccountingEngine` — amounts + confidence (existing contracts)
4. `FinancialAmountResolution` — quality gate
5. `AdminQaFixture` — KPI exclusion

---

## Explicit non-goals (F1)

- No persistence of resolution objects
- No settlement_ledger / financial_settlements mutation
- No inventing payment method enums
- No silent reconstruction of missing money fields into COMPLETE totals
- No Finance UI redesign
