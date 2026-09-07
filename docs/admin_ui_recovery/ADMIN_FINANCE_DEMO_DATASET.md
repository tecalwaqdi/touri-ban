# TOURi TAXI — ADMIN FINANCE DEMO DATASET

**Branch:** `feature/admin-finance-demo-mode`  
**Date:** 2026-09-07  
**Seed script:** `admin/Admi/firebase/functions/scripts/seed_admin_finance_demo.js`

---

## MODE

APPLIED (after DRY_RUN)

## PROJECT

`tutorial-multi-language-70gx4j`

## SEED VERSION

`finance_ui_v1`

## SEED GROUP

`TOURI_ADMIN_FINANCE_DEMO`

---

## COUNTS

| Kind | Count |
|------|------:|
| TRIPS (`order/demo_fin_trip_*`) | 13 |
| SETTLEMENTS | 3 |
| MOVEMENTS (settlement payments) | 2 |
| AUDIT EVENTS | 3 |
| STUB DRIVER USER | 1 |
| **TOTAL DOCS** | **22** |

Idempotent re-apply: `duplicate_docs_on_rerun: 0`

---

## SAFETY

| Check | Result |
|-------|--------|
| REAL ORDERS MODIFIED | 0 |
| REAL SETTLEMENTS MODIFIED | 0 |
| REAL WALLETS MODIFIED | 0 |
| REAL USERS MODIFIED | 0 |
| ACCOUNTANT WRITES | 0 |
| Gate `ALLOW_TOURI_DEMO_SEED=YES` | required |
| Project pin | `tutorial-multi-language-70gx4j` only |

Every demo doc carries:

- `is_demo: true`
- `admin_demo_fixture: true`
- `demo_seed_version: finance_ui_v1`
- `demo_seed_group: TOURI_ADMIN_FINANCE_DEMO`
- `exclude_from_real_reporting: true`

Deterministic IDs prefixed `demo_fin_`. No `ActiveOrder`. Cash only. No lifecycle Cloud Functions.

---

## DEMO MODE (Admin client)

| Item | Value |
|------|--------|
| DEFAULT | OFF |
| Toggle label | عرض البيانات التجريبية |
| Badge when ON | وضع تجريبي |
| Banner when ON | أنت تشاهد بيانات تجريبية — لا تمثل معاملات فعلية |
| Who can toggle | Super Admin **or** `accountant.demo@touri-taxi.com` |
| Persistence | local SharedPreferences only (not global server flag) |
| Normal reporting | demo **EXCLUDED** via `AdminQaFixture.shouldExcludeFromFinanceReporting` |
| Demo ON | includes **only** `TOURI_ADMIN_FINANCE_DEMO`; classic QA/fin*/golden still excluded |

---

## SCENARIOS COVERED

A–L cash trips including: collected/uncollected, unsettled/partial/settled, partial money, missing agent snapshot, agent share 5% → 0.38 SAR on 7.50 fee, VAT 800/120/120/560, needs-review marker, non-completed filter proof, previous-month row.

Settlements: unsettled 7.50, partial 3.00/4.50, settled 7.50 — `DRIVER_PAYS_COMPANY`.

---

## UI (human QA after Admin client deploy of this branch)

| Screen | Status |
|--------|--------|
| FINANCE HUB | READY_FOR_HUMAN_QA |
| RECON | READY_FOR_HUMAN_QA |
| MONEY | READY_FOR_HUMAN_QA |
| SETTLEMENTS | READY_FOR_HUMAN_QA |
| SETTLEMENT DETAIL | READY_FOR_HUMAN_QA |
| AGENT FINANCE | READY_FOR_HUMAN_QA |
| REPORTS | READY_FOR_HUMAN_QA |
| AUDIT | READY_FOR_HUMAN_QA (search by demo settlement codes) |

Seed is live in Firestore; Demo Mode UI ships on `feature/admin-finance-demo-mode` (preview before main).

---

## CLEANUP

```bash
ALLOW_TOURI_DEMO_SEED=YES node scripts/seed_admin_finance_demo.js --cleanup
```

SUPPORTED: YES  

DELETION FILTER:

- `admin_demo_fixture == true`
- AND `demo_seed_group == TOURI_ADMIN_FINANCE_DEMO`

Never deletes by prefix alone.

---

## COMMANDS

```bash
cd admin/Admi/firebase/functions
ALLOW_TOURI_DEMO_SEED=YES node scripts/seed_admin_finance_demo.js --dry-run
ALLOW_TOURI_DEMO_SEED=YES node scripts/seed_admin_finance_demo.js --apply
ALLOW_TOURI_DEMO_SEED=YES node scripts/seed_admin_finance_demo.js --cleanup
```

---

## FINAL

DEMO_DATASET: **READY_FOR_HUMAN_QA**

STOP.
