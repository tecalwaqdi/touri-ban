# TOURi TAXI — FINANCE F1 FOUNDATION REPORT

**Branch:** `recovery/admin-finance-f1-foundation`  
**Base (exact F0 checkpoint):** `2cda3d4c70f98c657aeda34e60842ac14f6d2f84`  
**F1 commit:** `4f569226fd3deaff4acc500fff48b8e27c7fc4cd`  
**Driver clean base:** `29b6d58167b9b49d93ea9a306dcdc330deec3ac5`  
**F0 remote:** `origin/recovery/admin-finance-audit` @ `2cda3d4` (pushed; **not** merged to main)

---

## Deliverables

| Artifact | Path |
|---|---|
| Trip semantics | `lib/core/finance/financial_trip_semantics.dart` |
| Amount resolution | `lib/core/finance/financial_amount_resolution.dart` |
| Accountant read model | `lib/core/finance/accountant_finance_read_model.dart` |
| `isPaid` defect fix | `lib/core/finance/financial_engine.dart` |
| Test matrix A–L | `test/core/finance/finance_f1_semantics_test.dart` |
| Docs | `docs/finance_recovery/FINANCE_F1_*.md`, `FINANCIAL_READ_MODEL.md` |

---

## Completion

| Item | Result |
|---|---|
| Canonical field | `order.status_code` |
| Completed values | `completed`, `trip_completed` (+ legacy Arabic complete **only** when code empty) |
| Payment dependency | **NO** |
| Collection dependency | **NO** |
| Settlement dependency | **NO** |
| Broken consumers fixed | `OrderStatusHelper.isPaid` / `countsTowardRevenue` (Arabic «مكتملة» conflation removed) |

---

## Payment

| Item | Result |
|---|---|
| Canonical payment status | `payment_status` (`paid` / `cash_collected` / `captured` / `pending_cash` / …) |
| `isPaid` «مكتملة» conflation | **REMOVED** |

---

## Data quality

| Item | Result |
|---|---|
| COMPLETE / PARTIAL / UNRESOLVED | Via `FinancialAmountResolution` |
| Missing values treated as zero in accountant totals | **NO** |
| Fabricated fallbacks into COMPLETE totals | **0** |

---

## Live KPIs (read model rules)

| Item | Result |
|---|---|
| QA fixtures included | **0** (`AdminQaFixture` / `isFinanceQaFixture`) |
| Completed count | Operational only |
| Reconcilable completed value | COMPLETE resolutions only |
| Partial completed trips | Counted in trip count; excluded from amount sums |

---

## Agent / scope

| Item | Result |
|---|---|
| Historical snapshot | **PRESERVED** |
| Current agent backfill | **0** |
| Super Admin / Country Agent scope | Explicit `AccountantFinanceScope` |
| Cross-country leak in aggregate | Filtered before totaling |

---

## Validation

| Check | Result |
|---|---|
| `flutter analyze` | Exit 0 (pre-existing infos/warnings only; **no new errors**) |
| Finance core tests (`test/core/finance/`) | **PASS** (83) |
| Full `flutter test` | `+367 ~2 -1` |
| Known failure | `phase_8a_csv_errors_test.dart` — **KNOWN_PRE_EXISTING_FINANCE_TEST_FAILURE** (CSV untouched) |
| New failures from F1 | **0** |

---

## Final gates

| Gate | Value |
|---|---|
| FINANCIAL SEMANTICS | **READY** |
| ACCOUNTING READ MODEL | **READY** |
| SAFE_TO_START_FINANCE_UI_F2 | **YES** (semantics/read model only; F2 not started) |
| UI REDESIGNED | **NO** |
| DATABASE MIGRATION | **NO** |
| PRODUCTION DEPLOYED | **NO** |
| DRIVER EDIT TOUCHED | **NO** |

**STOP. DO NOT START F2.**
