# TOURi TAXI — AGENT HANDOFF SECURITY DEPLOY GATE

**Project:** `tutorial-multi-language-70gx4j`  
**Admin:** `admin/Admi`  
**Production Admin:** https://touri-ban-1.onrender.com/admin/  
**Date (UTC):** 2026-09-08  

---

## A — SECURITY PATCH FREEZE

| Item | Value |
|------|--------|
| **SECURITY COMMIT** | `83344c5fa901dcea7c87de54ece7bf99667a2646` |
| Message | `fix(security): enforce agent rates and country isolation` |
| **PUSHED** | **YES** → `origin/feature/admin-finance-demo-mode` |
| WORKING TREE | **DIRTY** (unrelated demo/UI/hosting/untracked provisioning artifacts — **excluded** from security commit) |

Security commit paths only:

- `admin/Admi/firebase/firestore.rules`
- `admin/Admi/firebase/functions/agent_country_assignment.js`
- `admin/Admi/firebase/functions/driver_financial_summary_v2.js`
- `admin/Admi/firebase/functions/index.js` (`createPanelUser` rate validation)
- `admin/Admi/firebase/functions/test/agent_handoff_security_f03_f07.test.js`
- `admin/services/payment-api/src/lib/auth/verify.ts`
- `admin/services/payment-api/src/lib/payments/status-handler.ts`
- `admin/services/payment-api/src/app/api/payments/refund/route.ts`
- payment-api F07 unit tests
- `docs/admin_ui_recovery/AGENT_HANDOFF_SECURITY_GATE.md`

---

## B — EXACT DEPLOYMENT DIFF (repo → production)

### Firestore Rules
| | |
|--|--|
| Pre-deploy ruleset | `projects/.../rulesets/1727c00c-7c2f-4a98-9a8d-10aba54b6d89` |
| Pre-deploy SHA-256 | `65c3cf00326387d9e75ca98ccd9099e627484d3f6631b376eb282a83d38df353` |
| Matched repo parent | `95e373a` rules (zero drift) |
| Post-deploy ruleset | `projects/.../rulesets/d5980f32-5120-471f-8d61-d9bc748e8ea3` |
| Post-deploy SHA-256 | `4bf5e1b5829409bac513e143a3fdbe9bff28d2734aa6efff266be615875efe53` |

Surfaces: `Agent_total` / commercial rates lock, settlement child country scope, `type_car` GLOBAL Super-Admin-only write, historical agent snapshot immutability.

### Admin Functions (only these three)
| Function | Result |
|----------|--------|
| `getDriverFinancialSummaryV2` | Updated (F07 country scope) |
| `updateCountryAgentAssignment` | Updated (F03 rate validation 0–100) |
| `createPanelUser` | Updated (F03 rate validation on create) |

### Payment API
| Surface | Result |
|---------|--------|
| Firebase `paymentApi` (us-central1 / Cloud Run) | **Deployed** F07 auth (`rule=2` ≠ global) |
| Render `https://touri-ban.onrender.com` (production client default) | **NOT deployed** — CLI requires `render login` (no API token in environment) |

### Admin Web
**UNCHANGED** (no Flutter deploy; not required for these fixes).

---

## J — ROLLBACK READY

| Asset | Previous | Rollback |
|-------|----------|----------|
| Rules | ruleset `1727c00c-…` + backup `docs/admin_ui_recovery/rules_backups/deployed_before_f03_f07_1727c00c.rules` | Re-release prior ruleset / redeploy backup file |
| Functions | prior 1st-gen revisions of the three callables | Redeploy prior commit `95e373a` for those three only |
| Payment Firebase | prior `paymentApi` revision | Redeploy prior payment-api commit |
| Payment Render | unchanged (still pre-F07) | N/A this gate |

**Rollback of Rules/Functions was NOT executed** — those surfaces passed live QA.  
**Production Payment (Render) still permits cross-country** → gate **BLOCKED** until Render deploy.

---

## LIVE SECURITY (post-deploy)

| Check | Result |
|-------|--------|
| AGENT RATE SELF WRITE (150 / −1 / clear) | **DENY** (0 successful writes) |
| OTHER COUNTRY user/settlement | **DENY** |
| SETTLEMENT LINES CROSS COUNTRY | **DENY** |
| SETTLEMENT EVENTS CROSS COUNTRY | **DENY** |
| DRIVER SUMMARY CROSS COUNTRY | **DENY** (`Cross-country driver financial summary denied.`) |
| DRIVER SUMMARY OWN COUNTRY | **PASS** (ephemeral fixture; cleaned) |
| PAYMENT API CROSS COUNTRY (Firebase `paymentApi`) | **DENY** |
| PAYMENT API CROSS COUNTRY (Render production) | **FAIL / ALLOW** ← blocks handoff |
| TYPE_CAR AGENT WRITE | **DENY** |
| CROSS_COUNTRY_LEAKAGE (Rules + Functions + Firebase payment) | **0** |
| CROSS_COUNTRY_LEAKAGE (Render payment) | **>0** |

Ephemeral probe fixtures (`is_test_fixture` drivers + payment_sessions) were created and **deleted** (404 confirmed).

Saudi dual-role `info@touri-taxi.com`: **UNCHANGED**.

---

## AGENT QA

Custom-token auth (no password reset). Production Admin URL.

### Agent A — India (`bander1@gmail.com`)
| | |
|--|--|
| LOGIN | **PASS** (custom token; dashboard loading on `/admin/`) |
| OWN COUNTRY | **PASS** (profile + own-country driver summary fixture) |
| OTHER COUNTRY | **DENY** |
| AGENT RATE SELF WRITE | **DENY** |

### Agent B — Spain (`trial.agent.es.1@touri-taxi.com`)
| | |
|--|--|
| LOGIN | **PASS** |
| OWN COUNTRY | **PASS** |
| OTHER COUNTRY | **DENY** |
| AGENT RATE SELF WRITE | **DENY** |

Full UI matrix (landmarks/bookings/settings routes) was not exhaustively crawled; backend isolation for F03/F07 surfaces was proven live.

---

## REGRESSION

| Item | Status |
|------|--------|
| C3 | **PASS** (unit + audit locks MATCH for active pure agents) |
| ACCOUNTANT | **PASS** (finance global path preserved in code; not redeployed UI) |
| AUTH | **PASS** |
| FINANCE SEMANTICS | **UNCHANGED** |
| DEMO MODE / Admin V2 / Customer / Driver | **UNCHANGED** (no UI deploy) |
| NEW TEST FAILURES | **0** (38 functions + 5 payment unit tests pre-deploy) |

---

## HANDOFF READINESS (post-audit)

Re-ran `audit_existing_country_agents.js` (read-only, 0 mutations).

| Status | Count / notes |
|--------|----------------|
| Pure active Agents (login-ready, non-Saudi) | **8** |
| READY_FOR_HANDOFF | **0** — blocked on Render Payment F07 |
| NEEDS_PASSWORD_RESET | **8** (eligible after security PASS; no links generated this gate) |
| BLOCKED | Chad / Niger / Nigeria inactive demos (**UNCHANGED**, not reactivated) |
| DUAL_ROLE_NOT_FOR_HANDOFF | `info@touri-taxi.com` **UNCHANGED** |

### Final account table (no credentials / no reset links)

| COUNTRY | NAME | EMAIL | STATUS | LOGIN QA | COUNTRY ISOLATION | FINANCE SCOPE | PASSWORD SETUP | READY TO GIVE AGENT |
|---------|------|-------|--------|----------|-------------------|---------------|----------------|---------------------|
| India | bander | bander1@gmail.com | NEEDS_PASSWORD_RESET | PASS (probe) | PASS (backend) | country-scoped | NOT_ISSUED | **NO** |
| Indonesia | trial | trial.agent.id.1@touri-taxi.com | NEEDS_PASSWORD_RESET | not probed | expected PASS after Render | country-scoped | NOT_ISSUED | **NO** |
| Kyrgyzstan | trial | trial.agent.kg.1@touri-taxi.com | NEEDS_PASSWORD_RESET | not probed | expected PASS after Render | country-scoped | NOT_ISSUED | **NO** |
| Malaysia | trial | trial.agent.my.1@touri-taxi.com | NEEDS_PASSWORD_RESET | not probed | expected PASS after Render | country-scoped | NOT_ISSUED | **NO** |
| Morocco | trial | trial.agent.ma.1@touri-taxi.com | NEEDS_PASSWORD_RESET | not probed | expected PASS after Render | country-scoped | NOT_ISSUED | **NO** |
| Portugal | trial | trial.agent.pt.1@touri-taxi.com | NEEDS_PASSWORD_RESET | not probed | expected PASS after Render | country-scoped | NOT_ISSUED | **NO** |
| Spain | trial | trial.agent.es.1@touri-taxi.com | NEEDS_PASSWORD_RESET | PASS (probe) | PASS (backend) | country-scoped | NOT_ISSUED | **NO** |
| Tunisia | trial | trial.agent.tn.1@touri-taxi.com | NEEDS_PASSWORD_RESET | not probed | expected PASS after Render | country-scoped | NOT_ISSUED | **NO** |
| Saudi Arabia | Touri Super Admin | info@touri-taxi.com | DUAL_ROLE_NOT_FOR_HANDOFF | excluded | n/a | dual | UNCHANGED | **NO** |
| Chad / Niger / Nigeria | demo | demo.agent.*.@touri-taxi.com | BLOCKED | n/a | n/a | n/a | UNCHANGED | **NO** |

Login URL (when handoff eventually approved): https://touri-ban-1.onrender.com/admin/

---

## NEXT REQUIRED ACTION (operator)

1. `render login` then deploy `admin/services/payment-api` @ `83344c5` to production service `touri-ban` / `touri-payment-api`.
2. Re-run India→Spain / Spain→India payment session status probe → expect **DENY**.
3. Only then: password setup links + `READY_FOR_HANDOFF`.

---

## FINAL BLOCK

```
# TOURi TAXI — AGENT HANDOFF SECURITY DEPLOY GATE

SECURITY COMMIT:
83344c5fa901dcea7c87de54ece7bf99667a2646

PUSHED:
YES

================================
DEPLOYED
================================

FIRESTORE RULES:
YES

RULES VERSION/HASH:
d5980f32-5120-471f-8d61-d9bc748e8ea3 / sha256:4bf5e1b5829409bac513e143a3fdbe9bff28d2734aa6efff266be615875efe53

FUNCTIONS:
getDriverFinancialSummaryV2, createPanelUser, updateCountryAgentAssignment (admin_functions)

PAYMENT API:
Firebase paymentApi YES; Render production NO (auth required)

ADMIN WEB:
UNCHANGED

================================
LIVE SECURITY
================================

AGENT RATE SELF WRITE:
DENY

OTHER COUNTRY:
DENY

SETTLEMENT LINES CROSS COUNTRY:
DENY

SETTLEMENT EVENTS CROSS COUNTRY:
DENY

DRIVER SUMMARY CROSS COUNTRY:
DENY

PAYMENT API CROSS COUNTRY:
FAIL (Render ALLOW; Firebase DENY)

TYPE_CAR AGENT WRITE:
DENY

CROSS_COUNTRY_LEAKAGE:
0 (Rules/Functions/Firebase payment); Render payment LEAK remains

================================
AGENT QA
================================

AGENT A COUNTRY:
india

LOGIN:
PASS

OWN COUNTRY:
PASS

OTHER COUNTRY:
DENY

AGENT B COUNTRY:
spain

LOGIN:
PASS

OWN COUNTRY:
PASS

OTHER COUNTRY:
DENY

================================
REGRESSION
================================

C3:
PASS

ACCOUNTANT:
PASS

AUTH:
PASS

FINANCE SEMANTICS:
UNCHANGED

================================
HANDOFF
================================

PURE ACTIVE AGENTS:
8

READY_FOR_HANDOFF:
0

NEEDS_PASSWORD_RESET:
8

BLOCKED:
3 (Chad/Niger/Nigeria demos)

SAUDI DUAL ROLE:
UNCHANGED

INACTIVE AFRICA DEMOS:
UNCHANGED

================================
FINAL
================================

AGENT_SECURITY_PRODUCTION:
BLOCKED

AGENT_ACCOUNTS_READY_FOR_HANDOFF:
NO

STOP.
```
