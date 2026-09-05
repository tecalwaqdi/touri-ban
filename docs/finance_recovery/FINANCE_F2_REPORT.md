# TOURi TAXI — FINANCE F2 UI REPORT

**BASE:** `055496e61fdb9807644c18efe224d834f77b3dd2`  
**BRANCH:** `recovery/admin-finance-f2-ui`  
**COMMIT:** _(see git HEAD after push)_  
**PREVIEW:** https://tutorial-multi-language-70gx4j--admin-finance-f2-jbhd7z4e.web.app  
**PRODUCTION DEPLOYED:** NO

---

## Canonical UI

| Item | Value |
|---|---|
| PRIMARY FINANCE ROUTE | `/adminFinanceHub` (`AdminFinanceHubWidget`) |
| COUNTRY AGENT ROUTE | `/adminFinanceAgents` (same F1 model, scoped) |
| DUPLICATE ROUTES | Profits → redirect Hub; Channels diagnostic; Receivables/Reconciliation/Periods/Wallets removed from primary menu |
| CANONICAL READ MODEL USED | **YES** |
| WIDGET-LEVEL FINANCE CALCULATIONS | **0** (totals from `AccountantFinanceReadModel`) |

---

## Summary (UI fields from F1)

Completed trips, reconciliable value, partial count, collected, uncollected, company commission, VAT, driver net, company receivable, driver payable — all from read model.

---

## Money movement / Settlements / Data quality

| Gate | Result |
|---|---|
| Money movement table | READY |
| Cash holder / who owes | PASS (Arabic labels) |
| Raw enums in accountant UI | 0 (labels layer) |
| Settlements Arabic | READY |
| Dev workflow English (Preview/Ledger) | Removed from normal copy |
| COMPLETE / PARTIAL / UNRESOLVED UI | PASS |
| Missing as zero | 0 for incomplete resolutions |

---

## Role scope

| Gate | Result |
|---|---|
| Super Admin | PASS (Hub) |
| Country Agent | PASS (Agent Finance = same model) |
| Cross-country leak | 0 in loader query + scope |

---

## Consistency

| Gate | Result |
|---|---|
| Hub summary vs table completed count | MATCH (same bundle) |
| Finance vs Reports | Reports still LEGACY_DEFERRED_EXPORTER (documented) |

---

## Tests / Preview

| Gate | Result |
|---|---|
| Analyze | PASS (pre-existing infos/warnings only) |
| Finance tests | PASS |
| Known CSV failure | KNOWN_PRE_EXISTING_FINANCE_TEST_FAILURE |
| Preview channel | `admin-finance-f2` |
| PRODUCTION DEPLOYED | **NO** |

---

## Final

| Gate | Value |
|---|---|
| ACCOUNTANT UI | READY_FOR_HUMAN_QA |
| FINANCIAL SEMANTICS CHANGED | **NO** |
| DATABASE MIGRATION | **NO** |
| FINANCE WRITES CHANGED | **NO** (label text only on settlement details) |
| DRIVER EDIT TOUCHED | **NO** |
| READY_FOR_F3 | **NO** |

**STOP. WAIT FOR HUMAN QA.**
