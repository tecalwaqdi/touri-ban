# TOURi TAXI — FINANCE F3-B1 RECONCILIATION READ MODEL

**PROJECT:** `tutorial-multi-language-70gx4j`  
**BRANCH:** `recovery/admin-finance-f3b1-reconciliation-read-model`  
**MODE:** READ-ONLY model + tests + docs (NO production deploy, NO financial writes, NO backfill)  
**BASE:** post F3-C3D / F3-B0 tip  

---

## Deliverables

| Artifact | Path |
|---|---|
| Canonical read model | `admin/Admi/lib/core/finance/finance_reconciliation_read_model.dart` |
| QA predicate | `admin/Admi/lib/core/finance/finance_reconciliation_qa.dart` |
| Unit tests (matrix) | `admin/Admi/test/core/finance/finance_f3b1_reconciliation_read_model_test.dart` |
| Live read-only census | `admin/Admi/firebase/functions/scripts/f3b1_live_reconciliation_readonly.js` |

**API:**

```dart
FinanceReconciliationReadModel.buildReconciliation({
  required Iterable<OrderRecord> orders,
  required AccountantFinanceScope scope,
  required String currency,
  Iterable<Map<String, dynamic>> settlements = const [],
  Iterable<Map<String, dynamic>> settlementPayments = const [],
  Iterable<Map<String, dynamic>> unallocatedPayments = const [],
})
```

Returns: `records`, `summary`, `exceptions`, `unallocatedPayments`, `diagnosticsExcluded`.

Firestore loading is **out of scope** — pure transform for deterministic tests.

---

## Independent axes (never conflated)

| Axis | Values |
|---|---|
| OPERATIONAL | `completed` / `notCompleted` via frozen `status_code` (+ empty-code Arabic fallback only) |
| FINANCIAL | `COMPLETE` / `PARTIAL` / `UNRESOLVED` |
| COLLECTION | `COLLECTED` / `UNCOLLECTED` / `NOT_APPLICABLE` / `UNKNOWN` |
| AGENT | `COMPLETE` / `NONE` / `AMBIGUOUS` / `MISSING` / `UNRESOLVED` |
| SETTLEMENT | `UNSETTLED` / `PARTIAL` / `SETTLED` / `NOT_REQUIRED` / `UNKNOWN` |
| RECONCILIATION | `RECONCILED` / `NEEDS_REVIEW` / `BLOCKED_BY_MISSING_DATA` |

---

## Financial COMPLETE rule (§D)

Preferred stored fields all present:

- `total_mndob2`
- `total_app`
- `total_vat`
- `total_mndob`

Otherwise reuse `FinancialAmountResolution` quality (PARTIAL / UNRESOLVED).

**missing ≠ 0.** Explicit stored zero remains zero.

Record money fields expose **only stored** preferred components (no engine-derived invention on the record). Obligations (`companyReceivable` / …) require FINANCIAL COMPLETE.

---

## Reconciliation status rules (§L)

**BLOCKED_BY_MISSING_DATA** when:

- operational not completed, OR
- financial PARTIAL / UNRESOLVED, OR
- agent MISSING / UNRESOLVED

**NEEDS_REVIEW** when data is complete enough but:

- agent AMBIGUOUS, OR
- `FINANCIAL_SNAPSHOT_MISMATCH` / `AGENT_AMOUNT_MISMATCH` / `SETTLEMENT_MISMATCH`, OR
- cash UNCOLLECTED (business state), OR
- settlement eligible but `NO_SETTLEMENT` / `SETTLEMENT_PARTIAL`

**RECONCILED** only when:

- operational completed
- financial COMPLETE
- agent COMPLETE or NONE
- cash COLLECTED (or ONLINE / N/A)
- no hard data-quality mismatch issues
- not carrying unsettled-eligible / partial settlement business issues

---

## Issue codes (§M / §N)

| Code | Kind |
|---|---|
| `MISSING_GROSS` | data quality |
| `MISSING_DRIVER_NET` | data quality |
| `PARTIAL_FINANCIAL` / `UNRESOLVED_FINANCIAL` | data quality |
| `MISSING_AGENT_HISTORY` | data quality |
| `AMBIGUOUS_AGENT` / `UNRESOLVED_AGENT` | data quality |
| `FINANCIAL_SNAPSHOT_MISMATCH` | data quality |
| `AGENT_AMOUNT_MISMATCH` | data quality |
| `SETTLEMENT_MISMATCH` | data quality |
| `CASH_NOT_COLLECTED` | business state |
| `NO_SETTLEMENT` | business (only when settlement-eligible) |
| `SETTLEMENT_PARTIAL` | business state |

`NONE` agent (`agent_attribution_status=none`) is a **valid** historical state — not `MISSING_AGENT_HISTORY`.

---

## QA exclusion (§O)

`FinanceReconciliationQa.isReconciliationQaFixture` =

1. Canonical `AdminQaFixture` (fin7 / fin9 / fin_rt / `is_test_fixture`)
2. **Proven B0 markers only:**
   - `functional_test == true` (live golden `CASH-03392F80A1`)
   - `golden_cycle == TOURi_GOLDEN_1`

Do **not** modify frozen F2 `AdminQaFixture`. Normal B1 contribution of golden = **0**.

---

## Scope (§R)

Reuse `AccountantFinanceScope`:

- Super Admin: `includeAllCountries: true`
- Country Agent: `countryPaths` only — applied **before** counts/totals

---

## Money aggregation (§S)

Summary counts include PARTIAL / UNRESOLVED completed trips.  
Money totals only from FINANCIAL COMPLETE records.  
`moneyOmittedIncompleteCount` exposed.

---

## Consistency (§U / §V)

Read-only checks (never repair):

- `total_mndob ≈ total_mndob2 - total_app - total_vat` → `FINANCIAL_SNAPSHOT_MISMATCH`
- settlement `remaining ≈ due - paid` → `SETTLEMENT_MISMATCH`
- `percent_of_platform_fee` agent share vs `computeAgentAmountMinor` → `AGENT_AMOUNT_MISMATCH`

Never recompute agent from current country `Agent_total`.

---

## Unallocated company payments (§X)

Passed through as `unallocatedPayments`. **Never** auto-matched to trips/settlements (`AUTO_MATCHED=0`).

---

## Live read-only census (2026-09-06)

Script: `f3b1_live_reconciliation_readonly.js` — **0 writes**.

| Metric | Value |
|---|---|
| ORDERS_SCANNED | 64 |
| QA_EXCLUDED | 5 |
| REAL COMPLETED | **1** |
| FINANCIAL COMPLETE | 0 |
| FINANCIAL PARTIAL | 1 |
| FINANCIAL UNRESOLVED | 0 |
| CASH COLLECTED | 0 |
| CASH UNCOLLECTED | 1 |
| AGENT COMPLETE | 0 |
| AGENT MISSING | 1 |
| REAL SETTLEMENTS | 0 |
| RECONCILED | 0 |
| NEEDS REVIEW | 0 |
| BLOCKED BY MISSING DATA | 1 |
| UNALLOCATED COMPANY PAYMENTS (count) | 3 |
| UNALLOCATED AMOUNT | not trustworthy (mixed/legacy units; reported raw −1200) |
| AUTO_MATCHED | 0 |

Matches historical `CASH-7B9A80C306`-class trip: COMPLETED + PARTIAL + CASH + UNCOLLECTED + AGENT MISSING + UNSETTLED + BLOCKED.

Golden `TOURi_GOLDEN_1` excluded from normal counts.

---

## Future post-C1/C2 booking verification (when natural traffic exists)

Expect on first legitimate booking:

1. Core money: `total_mndob2` / `total_app` / `total_vat` / `total_mndob` → FINANCIAL COMPLETE  
2. Agent snapshot: `agent_attribution_status` + ids/amounts → COMPLETE / NONE / AMBIGUOUS  
3. Collection: cash pending ≠ collected  
4. Settlement: UNSETTLED until real settlement membership  
5. Reconciliation: RECONCILED only when lifecycle facts are proven consistent  

**ACCOUNTING_FULLY_RUNTIME_VERIFIED:** still **NO** (no natural post-C1/C2 booking).

---

## Safety

| Gate | Value |
|---|---|
| PRODUCTION WRITES | 0 |
| BACKFILL | 0 |
| SETTLEMENT CREATED | 0 |
| WALLET / LEDGER MODIFIED | 0 |
| F1/F2 SEMANTICS MODIFIED | NO |
| PRODUCTION DEPLOY | NO |
| Customer / Driver apps | untouched |

---

## Tests

| Suite | Result |
|---|---|
| B1 matrix | PASS |
| F1 / F2 finance | PASS |
| C2 `agent_order_snapshot` | PASS |
| `flutter analyze` (B1 files) | PASS (clean after unused-var fix) |
| `phase_8a_csv_errors_test` | KNOWN_PRE_EXISTING (unchanged; CSV out of B1 scope) |

---

## Final

| Gate | Value |
|---|---|
| F3-B1 | **READY_FOR_REVIEW** |
| READY_FOR_F3-B2 | **YES** (accountant presentation / Hub wiring next; runtime E2E still open) |
| ACCOUNTING_FULLY_RUNTIME_VERIFIED | **NO** |

**STOP.**
