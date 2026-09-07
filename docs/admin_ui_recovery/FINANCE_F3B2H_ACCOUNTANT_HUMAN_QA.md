# TOURi TAXI — FINANCE F3-B2H ACCOUNTANT HUMAN QA PREP

**MODE:** Preview hosting + demo Accountant Auth (read-only)  
**NO Admin production hosting deploy**  
**PASSWORD:** intentionally omitted from this file  

---

## Source

| Item | Value |
|---|---|
| Branch | `recovery/admin-finance-f3b2-accountant-workspace` |
| Commit | `0e0e5fb` |
| Working tree for release | clean at tip before build |
| Analyze | PASS |
| B2 RBAC / routes | PASS |
| B1 / F1 / F2 | PASS |
| Rules isolation | PASS |

---

## Preview (Hosting channel only)

| Item | Value |
|---|---|
| Channel | `admin-finance-b2-accountant` |
| Preview URL | https://tutorial-multi-language-70gx4j--admin-finance-b2-accou-14zbvme6.web.app |
| Admin entry | https://tutorial-multi-language-70gx4j--admin-finance-b2-accou-14zbvme6.web.app/admin/ |
| Expires | ~2026-10-06 |
| Production Admin hosting | **NOT deployed** |

### Provenance (live on preview)

- `git_commit`: `0e0e5fb93c5b893bd8082af2d24171a9ad493405`
- `phase`: F3-B2H
- includes: F2 Finance Hub, B1 reconciliation model, B2 Accountant workspace, C3 baseline
- `production_hosting_deploy`: false

---

## Demo Accountant

| Item | Value |
|---|---|
| Email | `accountant.demo@touri-taxi.com` |
| UID | `jrPITQI0Y2QJNELU43ymS1WJvR43` |
| `isAdminRule` | **5** |
| Auth claim | `finance: true` only |
| Scope | **GLOBAL** (no `country_id`, no `Rev_dloh_agent`) |
| Super Admin / Country Admin / Agent | **false** |
| Password in repo | **NO** |
| Retained | **YES** (do not delete after QA) |

Auth claim verified via Identity Toolkit sign-in + ID token decode after `setCustomUserClaims`.  
Profile role verified via Firestore `user/{uid}.isAdminRule = 5`.

---

## Expected navigation (Accountant)

Financial section only (route-gated):

- نظرة مالية → `AdminFinanceHub` (landing)
- المصالحة المالية → `AdminFinanceReconciliation`
- حركة الأموال → `AdminFinanceChannels`
- التسويات → `AdminSettlements`
- مالية الوكلاء → `AdminAgentFinance`
- التقارير → `AdminFinanceReports` (+ finance audit when shown)
- Settings / profile / logout

Must **not** show drivers, users, agents mgmt, countries, cities, landmarks, pricing, operational dashboard.

Unauthorized direct routes redirect to Finance Hub (`admin_route_guard`).

---

## Accounting snapshot (read-only live census)

From B1 script (QA excluded):

| Metric | Value |
|---|---|
| REAL COMPLETED | 1 |
| FINANCIAL PARTIAL | 1 |
| CASH UNCOLLECTED | 1 |
| AGENT MISSING | 1 |
| REAL SETTLEMENTS | 0 |
| BLOCKED_BY_MISSING_DATA | 1 |
| QA FIXTURE ROWS (normal) | 0 |
| WRITES | 0 |

---

## Write security

| Check | Result |
|---|---|
| Preview client `canWriteSettlements` | REJECT (SuperAdmin only) |
| Unit `canWriteSettlements({finance:true})` | REJECT |
| Live `createPanelUser` | PERMISSION_DENIED |
| Live `assignActiveCountryAgent` / `reassignActiveCountryAgent` | PERMISSION_DENIED |
| Live settlement V2 callables | Production Functions still validate args before write; **full Functions redeploy of B2 write-gate deferred** (branch `index.js` requires local modules not packaged on this tip — do in B2D) |
| Financial / business mutations during B2H | **0** |

UI mutation buttons remain gated by `canWriteSettlements` in the preview build.

---

## Country Accountant

Emulator/unit fixture only (no second production user): PASS in B2 RBAC tests (own country / foreign 0).

---

## Human QA checklist (screenshots)

1. Landing / Finance Hub  
2. Sidebar (finance-only)  
3. Reconciliation summary  
4. Reconciliation table  
5. Exception / BLOCKED state for historical PARTIAL trip  
6. Settlements list  
7. Settlement detail if any non-QA (expect empty real)  
8. Agent Finance  
9. Reports  
10. One denied direct route (e.g. `/admin/drever` or users)

**Do not declare HUMAN PASS in automation.**

---

## Final gates

| Gate | Value |
|---|---|
| F3-B2H | **READY_FOR_FINAL_HUMAN_QA** |
| READY_FOR_F3-B2D | **NO** (awaits Human PASS) |
| HUMAN PASS | **PENDING** |
| ACCOUNTING_FULLY_RUNTIME_VERIFIED | **NO** |

**STOP.**
