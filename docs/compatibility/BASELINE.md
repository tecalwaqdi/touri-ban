# Baseline (2026-08-27)

```
BASELINE_ADMIN_ANALYZE=PASS (4 info issues, exit 0)
BASELINE_ADMIN_TEST=PASS (84 tests, 2 skipped)
BASELINE_ADMIN_BUILD=NOT_RUN

BASELINE_CUSTOMER_ANALYZE=PASS (0 issues)
BASELINE_CUSTOMER_TEST=PASS (222 tests)

BASELINE_DRIVER_ANALYZE=PASS (298 info issues, exit 0)
BASELINE_DRIVER_TEST=PASS (228 tests)

BASELINE_FUNCTIONS_TEST=PARTIAL
  - node --test without emulator: storage/rules tests FAIL (ECONNREFUSED) = PRE_EXISTING / environment
  - dedicated unit scripts exist (test:unit, test:rules)

BASELINE_RULES_TEST=NOT_RUN (requires firebase emulators:exec)

BASELINE_PAYMENT_API_TEST=PASS (93 tests)
BASELINE_PAYMENT_API_TYPECHECK=PASS
```

Post-change Admin targeted tests: PASS (`admin_i18n_theme_test`, `phase_8a_csv_errors_test`).
