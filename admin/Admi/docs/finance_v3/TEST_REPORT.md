# Test Report — Finance V3 Foundations

## Unit (Dart)

`test/core/finance/v3/finance_v3_foundation_test.dart`

- Truth terms / unavailable metric
- TripFinancialSnapshot parse + soft balance
- Engine version helpers

## Unit (Functions)

`firebase/functions/test/financial_snapshot_v3.test.js`

- Snapshot validation
- Agent attribution classifier

## Existing V2 regressions (must remain green)

- `financial_accounting_engine_test.dart`
- `finance_controls.test.js`
- settlement ledger/payment tests

## Not executed this session

- Full E2E trip → settlement Production scenario (requires deploy approval)
- Large dataset perf soak
