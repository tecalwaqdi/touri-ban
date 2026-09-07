# TOURi TAXI — ACCOUNTANT FINANCE RULES DEPLOY GATE REPORT

SOURCE: `recovery/accountant-finance-read-access-p0` @ `fea6445` (gate docs commit stamped after push)
GATE_DOCS_COMMIT: _(pending)_
WORKING TREE AT GATE START: clean  

RULES DEPLOYED: **YES** (Firestore Rules only)  
ADMIN PRODUCTION HOSTING: **NO**  
FUNCTIONS: **NO**  
INDEXES: **NO**  
P2B MERGED: **NO**

PREVIEW (UI):  
https://tutorial-multi-language-70gx4j--accountant-read-access-j188djm9.web.app/admin/

SCREENSHOTS:  
`admin/Admi/visual_qa_accountant_rules_deploy_gate/shots/`

================================
RULE DIFF (DEPLOYED → fea6445)
================================

PREVIOUS RULES:
- ruleset: `projects/tutorial-multi-language-70gx4j/rulesets/6b56a943-57aa-4fde-abbd-401e741de515`
- updateTime: `2026-09-06T00:35:58.895761Z`
- sha256: `8e508951b734ce97c287017a6f875f634913ee74c3931c632194ce1336b9df30`
- backup: `docs/admin_ui_recovery/rules_backups/deployed_before_6b56a943.rules`

NEW RULES:
- ruleset: `projects/tutorial-multi-language-70gx4j/rulesets/a7926d10-e41b-45d3-863f-3575dde72062`
- createTime: `2026-09-07T04:00:43.439039Z`
- updateTime: `2026-09-07T04:00:45.415461Z`
- sha256: `65fcb6beac7eedfddbf17b5bfe0bd290f742c4fc6f877e8b3c2277783cb5389f`
- matches repo `admin/Admi/firebase/firestore.rules`: **YES**

UNRELATED RULE DELTA: **0**

Semantic change only:

```
function isFinance() {
  // Do NOT include country_admin — that leaked unscoped order lists.
-  return claimBool('finance') || isSuperAdmin();
+  // Profile isAdminRule=5 mirrors other panel roles (claim may lag until
+  // refreshMyClaims). Clients cannot self-set isAdminRule.
+  return claimBool('finance')
+    || currentUserData().isAdminRule == 5
+    || currentUserData().IsAdminRule == 5
+    || isSuperAdmin();
}
```

ACCOUNTANT WRITE additions: **0**  
CUSTOMER / DRIVER / C3 / terminal / statusUpdatedAt changes: **0**

ACCOUNTANT READ paths affected via existing `isFinance()` callers (no new match blocks):
- `order` list/read via `canListOrder` / `panelCanReadOrder`
- wallet / Paymenthistory / ExtraHours / bank / E-paymentduerequests (existing isFinance branches)

NOTE: `financial_settlements` / `financial_audit_events` still gate on `claimBool('finance')` (and Super/Country Admin as coded). Live demo Accountant has `finance: true`, so settlement/audit reads succeed. Profile-only fallback covers `isFinance()` surfaces when claim lags.

ROLLBACK READY: **YES** (previous ruleset id + local backup file)

================================
PRE-DEPLOY TESTS
================================

Dart (Accountant + AUTH-NAV + RBAC): **19/19 PASS**  
Rules emulator (JDK 21) full `firestore_rules.test.js`: **58/58 PASS**  
ACCOUNTANT_READ_ACCESS_P0 emulator: **4/4 PASS** (incl. settlement write DENY)

================================
LIVE ACCOUNT
================================

AUTH: **PASS**  
FINANCE CLAIM: **PASS** (`finance: true` on stored customClaims + ID token)  
ROLE: Accountant  
PROFILE isAdminRule: **5**  
GLOBAL SCOPE: **YES** (no `Rev_dloh_agent`)

================================
LIVE BACKEND PROBES (REST + ID token)
================================

| Resource | Result |
|---|---|
| `order` list | AUTHORIZED (5 docs) |
| `order` completed filter | AUTHORIZED (5 docs) |
| `financial_settlements` list | AUTHORIZED (1 doc) |
| settlement detail `iOYduoa6IXPdkUUdhHLq` | AUTHORIZED |
| `financial_audit_events` | AUTHORIZED (5 docs) |
| `countries` | AUTHORIZED |
| settlement create | REJECT PERMISSION_DENIED |
| settlement update | REJECT PERMISSION_DENIED |
| order `total` patch | REJECT PERMISSION_DENIED |
| wallet create | REJECT PERMISSION_DENIED |
| self `isAdminRule` mutation | REJECT PERMISSION_DENIED |

SUCCESSFUL BUSINESS WRITES: **0**

================================
LIVE PREVIEW ROUTES
================================

FINANCE HUB: **PASS** (authorized empty for selected period; no permission error)  
RECON: **PASS** (loaded B1 classification; trip `CASH-7B9A80C3` visible)  
MONEY MOVEMENT: **PASS** (no permission / raw errors)  
SETTLEMENTS: **PASS** (list authorized; UI empty-state for filters — not `ليس لديك صلاحية`)  
SETTLEMENT DETAIL: **PASS** via REST; UI list empty → click-through **NOT_AVAILABLE** in Preview filters  
AGENT FINANCE: **PASS** (`/adminFinanceAgents`; authorized empty for period)  
REPORTS: **PASS** (no raw `finance_query_unavailable`)  
FINANCE AUDIT (`AdminFinanceAudit` / سجل التدقيق): **PASS** — finance-scoped `financial_audit_events` (**ALLOW BY DESIGN**)  
SETTINGS: **DENY** (sidebar hidden; direct `/settings` → Finance Hub)

================================
ERRORS
================================

PERMISSION_DENIED (Preview network): **0**  
RAW FIREBASE ERROR (UI text): **0**  
FALSE EMPTY DUE TO DENY: **0** (REST proves authorization; empty = filter/period)  
LOGIN REDIRECT: **0**  
SIGNOUT (URL stayed on finance routes; user remains Accountant Demo): **0**

================================
WRITE SECURITY
================================

SETTLEMENT WRITE: **REJECT**  
FINANCIAL SNAPSHOT WRITE: **REJECT**  
WALLET: **REJECT**  
ROLE CHANGE: **REJECT**  
SUCCESSFUL BUSINESS WRITES: **0**

================================
REGRESSION
================================

Rules emulator suite (customer/driver/cash/type_car/accountant): **PASS**  
AUTH NAV dart: **PASS**  
SUPER ADMIN / COUNTRY ADMIN / COUNTRY AGENT / C3: unchanged in rules diff (**PASS** by delta=0 + suite)

================================
PERFORMANCE (smoke)
================================

REST warm samples (ms): order ~500–580 · settlements ~830 · audit ~650  
Preview route wall times ~10s include fixed wait (not P4C regression target)  
No material architecture change to P4C transport.

================================
DEPLOYMENT
================================

RULES: **DEPLOYED**  
ADMIN PRODUCTION: **NO**  
FUNCTIONS: **NO**  
PRODUCTION DATA MUTATIONS: **0**  
P2B MERGED: **NO**

================================
FINAL
================================

ACCOUNTANT_FINANCE_READ_ACCESS: **FROZEN**  
ACCOUNTANT_READY_FOR_HUMAN_QA: **YES**  
ACCOUNTANT_READY_FOR_REAL_USER: **NO**  

NEXT: **FINAL_ACCOUNTANT_HUMAN_QA**

STOP.
