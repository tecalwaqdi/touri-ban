# TOURi TAXI — FINANCE F3-B2 ACCOUNTANT WORKSPACE

**PROJECT:** `tutorial-multi-language-70gx4j`  
**BRANCH:** `recovery/admin-finance-f3b2-accountant-workspace`  
**BASE:** F3-B1 `a613884`  
**MODE:** Implementation + tests — **NO production deploy** — **NO production demo Auth user**

---

## A — RBAC audit (existing)

| Layer | Finding |
|---|---|
| Auth claims | `super_admin`, `country_admin`, `agent`, `support`, `finance`, `partner`, `transport_manager`, `country_id`, … (`AuthClaimKeys`) |
| Profile | `isAdminRule` 1–4 (+ legacy `IsAdmin` / `Isagent` / `is_partner`) |
| Prior finance mapping | `finance` claim existed but was only auto-granted to Super Admin; pure finance staff mapped incorrectly toward Country Agent in places |
| Settlement writes | Client + server previously allowed pure `finance` to write settlements |
| Firestore rules | `financial_*` collections: **read** for `finance`; **writes false** (mutations via callables) |

**No parallel permission system invented.** Accountant = native `finance` claim via **`isAdminRule = 5`**.

---

## Role definition

| Item | Value |
|---|---|
| Persona | **Accountant** (`AdminRole.accountant`) |
| Profile | `isAdminRule: 5` |
| Claim | `finance: true` (optional `country_id` for country scope) |
| Global | no `country_id` → `includeAllCountries` |
| Country | `Rev_dloh_agent` / `country_id` → scoped before rows/totals |
| Read-only | **YES** — `canWriteSettlements` = SuperAdmin only |
| Not Country Agent | Must not reuse agent operational routes |

---

## Surfaces

| Surface | Accountant |
|---|---|
| Finance Hub (`/adminFinanceHub`) | ALLOW (home) |
| Reconciliation workspace (`/adminFinanceReconciliation`) | ALLOW — B1 model |
| Money movement (`AdminFinanceChannels`) | ALLOW read |
| Settlements + detail | ALLOW read; write CTAs gated by `canWriteSettlements` |
| Agent finance | ALLOW read |
| Reports / audit finance | ALLOW read |
| Drivers / users / agents / geo / settings ops | REJECT (route guard → Finance Hub) |

Sidebar for Accountant shows only finance section + settings (unauthorized modules hidden, not merely disabled).

---

## Workspace

- Route: `AdminFinanceReconciliation` / `/adminFinanceReconciliation`
- Title: المصالحة المالية
- Source: **`FinanceReconciliationReadModel.buildReconciliation`** (no second engine)
- Arabic labels via `FinanceReconciliationLabels`
- Loading: `جاري تحميل البيانات المالية...` (no fake 0 ريال)
- Permission deny: `ليس لديك صلاحية لعرض هذه الصفحة`
- QA: B1 `isReconciliationQaFixture` (fin7/fin9/fin_rt/`functional_test`/`TOURi_GOLDEN_1`)

---

## Server / rules

| Gate | Value |
|---|---|
| Firestore financial writes | still `false` for clients |
| Callable settlement writes | `canWriteSettlements` → **SuperAdmin only** (F3-B2) |
| Accountant financial writes | **0** |
| Claims helper | `panel_claims.js` (`deriveClaimsFromUserData`) |

---

## Demo account

| Item | Value |
|---|---|
| Planned email | `accountant.demo@touri-taxi.com` |
| Production user created | **NO** |
| Password in git | **NO** |
| Prep script | `firebase/functions/scripts/f3b2_prepare_accountant_demo.js` (dry-run default; prod create blocked) |
| READY_TO_CREATE_PRODUCTION_DEMO | **YES** (after Human QA → B2D) |

---

## Tests

| Suite | Result |
|---|---|
| `admin_accountant_rbac_f3b2_test.dart` | PASS |
| Agent finance RBAC regression | PASS (finance write now false) |
| B1 / F1 / F2 | PASS |
| `panel_claims_accountant_f3b2.test.js` | PASS |
| Analyze (touched) | PASS |

---

## Preview / deploy

| Item | Value |
|---|---|
| Preview URL | NOT_DEPLOYED (B2 asks no production; isolated preview Auth optional later) |
| Production deploy | **NO** |

---

## Final gates

| Gate | Value |
|---|---|
| F3-B2 | **READY_FOR_HUMAN_QA** |
| READY_FOR_F3-B2D | **YES** |
| READY_FOR_F3-B3 | **NO** |
| ACCOUNTING_FULLY_RUNTIME_VERIFIED | **NO** |

**STOP.**
