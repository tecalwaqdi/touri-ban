# TOURi TAXI — AGENT HANDOFF SECURITY DEPLOY GATE

**Project:** `tutorial-multi-language-70gx4j`  
**Admin:** `admin/Admi`  
**Production Admin:** https://touri-ban-1.onrender.com/admin/  
**Production Payment API:** https://touri-ban.onrender.com  
**Date (UTC):** 2026-09-08  

---

## RENDER PAYMENT API SECURITY CUTOVER (FINAL BLOCKER — CLOSED)

| Item | Value |
|------|--------|
| **SECURITY COMMIT** | `83344c5fa901dcea7c87de54ece7bf99667a2646` |
| **SOURCE VERIFIED** | **YES** (`rule=2` / `country_admin` country-scoped; `assertResourceCountryAccess`; Super Admin + global finance preserved) |
| **RENDER SERVICE** | `touri-ban` (`srv-d9raia710e5c73fk86mg`) |
| **SERVICE TYPE** | `web_service` (Node) |
| **WATCHED BRANCH** | `main` (auto-deploy on commit) |
| **ROOT DIRECTORY** | `admin/services/payment-api` |
| **BUILD COMMAND** | `npm ci && npm run build` |
| **START COMMAND** | `npm start` |
| **PREVIOUS LIVE DEPLOY** | `dep-da803cqjnfac739j80og` |
| **PREVIOUS LIVE SHA** | `90098104564a8c6b598ab41197c515cbe2a780fd` |
| **PREVIOUS VERSION** | `0.2.0` / health ok (pre-F07 auth) |
| **NEW LIVE DEPLOY** | `dep-dafpvs5g1s2s73fl31j0` |
| **NEW LIVE SHA** | `83344c5fa901dcea7c87de54ece7bf99667a2646` |
| **DEPLOY METHOD** | `render deploys create … --commit 83344c5… --clear-cache --wait` (no branch/config change; no force push) |
| **DEPLOY DIFF vs previous live** | **Only** F07 auth surfaces (5 files under `payment-api`) — no pricing/booking/wallet/UI/Rules/Functions |
| **ROLLBACK READY** | **YES** → redeploy commit `9009810…` / deploy id `dep-da803cqjnfac739j80og` |

### Build gate (pre-deploy)

| Check | Result |
|-------|--------|
| `npm test` (vitest) | **PASS** 93/93 |
| F07 node tests (`verify.f07.node.test.ts`) | **PASS** 5/5 |
| `npm run typecheck` | **PASS** |
| `npm run build` | **PASS** |
| NEW FAILURES | **0** |

### Live authorization QA (ephemeral `payment_sessions`, deleted after)

| Case | Result |
|------|--------|
| India → India | **ALLOW** |
| India → Spain (direct session id) | **DENY** HTTP 403 `FORBIDDEN` |
| Spain → Spain | **ALLOW** |
| Spain → India (direct session id) | **DENY** HTTP 403 `FORBIDDEN` |
| Super Admin → India / Spain | **ALLOW** |
| Firebase paymentApi cross-country | **DENY** (unchanged) |
| CROSS_COUNTRY_LEAKAGE | **0** |
| PASSWORDS / RESET LINKS / CLAIMS / REASSIGNS | **0** |
| SAUDI DUAL ROLE / AFRICA DEMOS | **UNCHANGED** |

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
| Render `https://touri-ban.onrender.com` (production client default) | **Deployed** `83344c5` via `dep-dafpvs5g1s2s73fl31j0` — cross-country **DENY** proven |

### Admin Web
**UNCHANGED** (no Flutter deploy; not required for these fixes).

---

## J — ROLLBACK READY

| Asset | Previous | Rollback |
|-------|----------|----------|
| Rules | ruleset `1727c00c-…` + backup `docs/admin_ui_recovery/rules_backups/deployed_before_f03_f07_1727c00c.rules` | Re-release prior ruleset / redeploy backup file |
| Functions | prior 1st-gen revisions of the three callables | Redeploy prior commit `95e373a` for those three only |
| Payment Firebase | prior `paymentApi` revision | Redeploy prior payment-api commit |
| Payment Render | `dep-da803cqjnfac739j80og` @ `9009810…` | `render deploys create srv-d9raia710e5c73fk86mg --commit 90098104564a8c6b598ab41197c515cbe2a780fd` |

**Rollback was NOT executed** — Render cutover live QA **PASS**.

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
| PAYMENT API CROSS COUNTRY (Render production) | **DENY** (post-cutover `83344c5`) |
| TYPE_CAR AGENT WRITE | **DENY** |
| CROSS_COUNTRY_LEAKAGE | **0** |

Ephemeral probe fixtures (`is_test_fixture` drivers + payment_sessions) were created and **deleted**.

Saudi dual-role `info@touri-taxi.com`: **UNCHANGED**.

---

## AGENT QA

Custom-token auth (no password reset). Production Admin URL + Render Payment IDOR.

### Agent A — India (`bander1@gmail.com`)
| | |
|--|--|
| LOGIN | **PASS** |
| OWN COUNTRY | **PASS** |
| OTHER COUNTRY | **DENY** |
| RENDER PAYMENT OWN | **ALLOW** |
| RENDER PAYMENT SPAIN (direct id) | **DENY** 403 |
| AGENT RATE SELF WRITE | **DENY** |

### Agent B — Spain (`trial.agent.es.1@touri-taxi.com`)
| | |
|--|--|
| LOGIN | **PASS** |
| OWN COUNTRY | **PASS** |
| OTHER COUNTRY | **DENY** |
| RENDER PAYMENT OWN | **ALLOW** |
| RENDER PAYMENT INDIA (direct id) | **DENY** 403 |
| AGENT RATE SELF WRITE | **DENY** |

---

## REGRESSION

| Item | Status |
|------|--------|
| C3 | **PASS** |
| ACCOUNTANT | **PASS** (global finance path preserved; Agents not granted accountant) |
| SUPER ADMIN payment read | **PASS** |
| AUTH | **PASS** |
| FINANCE SEMANTICS | **UNCHANGED** |
| PRICING / PAYMENT CALCULATIONS | **UNCHANGED** |
| DEMO MODE / Admin V2 / Customer / Driver | **UNCHANGED** |
| NEW TEST FAILURES | **0** |

---

## HANDOFF READINESS (post Render cutover audit)

Re-ran `audit_existing_country_agents.js` (read-only, 0 mutations).

| Status | Count / notes |
|--------|----------------|
| Pure active Agents (login-ready, non-Saudi) | **8** |
| READY_FOR_HANDOFF (security-cleared) | **8** — India, Indonesia, Kyrgyzstan, Malaysia, Morocco, Portugal, Spain, Tunisia |
| NEEDS_PASSWORD_RESET | **8** (links **not** generated this gate) |
| BLOCKED | Chad / Niger / Nigeria inactive demos (**UNCHANGED**) |
| DUAL_ROLE_NOT_FOR_HANDOFF | `info@touri-taxi.com` **UNCHANGED** |
| PASSWORD LINKS GENERATED | **0** |

### Final account table (no credentials / no reset links)

| COUNTRY | NAME | EMAIL | STATUS | LOGIN QA | COUNTRY ISOLATION | FINANCE SCOPE | PASSWORD SETUP | READY TO GIVE AGENT |
|---------|------|-------|--------|----------|-------------------|---------------|----------------|---------------------|
| India | bander | bander1@gmail.com | READY_FOR_HANDOFF | PASS | PASS | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Indonesia | trial | trial.agent.id.1@touri-taxi.com | READY_FOR_HANDOFF | audit YES | PASS (security) | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Kyrgyzstan | trial | trial.agent.kg.1@touri-taxi.com | READY_FOR_HANDOFF | audit YES | PASS (security) | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Malaysia | trial | trial.agent.my.1@touri-taxi.com | READY_FOR_HANDOFF | audit YES | PASS (security) | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Morocco | trial | trial.agent.ma.1@touri-taxi.com | READY_FOR_HANDOFF | audit YES | PASS (security) | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Portugal | trial | trial.agent.pt.1@touri-taxi.com | READY_FOR_HANDOFF | audit YES | PASS (security) | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Spain | trial | trial.agent.es.1@touri-taxi.com | READY_FOR_HANDOFF | PASS | PASS | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Tunisia | trial | trial.agent.tn.1@touri-taxi.com | READY_FOR_HANDOFF | audit YES | PASS (security) | country-scoped | NEEDS_PASSWORD_RESET | **pending password setup** |
| Saudi Arabia | Touri Super Admin | info@touri-taxi.com | DUAL_ROLE_NOT_FOR_HANDOFF | excluded | n/a | dual | UNCHANGED | **NO** |
| Chad / Niger / Nigeria | demo | demo.agent.*.@touri-taxi.com | BLOCKED | n/a | n/a | n/a | UNCHANGED | **NO** |

Login URL: https://touri-ban-1.onrender.com/admin/

---

## NEXT REQUIRED ACTION (operator)

**PASSWORD_SETUP_AND_HANDOFF** — generate/setup reset links for the 8 pure Agents only. Do not include Saudi dual-role or Africa demos.

---

## FINAL BLOCK

```
# TOURi TAXI — RENDER PAYMENT API SECURITY CUTOVER

SECURITY COMMIT:
83344c5fa901dcea7c87de54ece7bf99667a2646

RENDER SERVICE:
touri-ban (srv-d9raia710e5c73fk86mg)

PREVIOUS LIVE SHA:
90098104564a8c6b598ab41197c515cbe2a780fd

NEW LIVE SHA:
83344c5fa901dcea7c87de54ece7bf99667a2646

================================
BUILD
================================

TESTS:
PASS

TYPECHECK:
PASS

BUILD:
PASS

================================
LIVE SECURITY
================================

INDIA → INDIA:
ALLOW

INDIA → SPAIN:
DENY

SPAIN → SPAIN:
ALLOW

SPAIN → INDIA:
DENY

DIRECT FOREIGN RESOURCE ID:
DENY

GLOBAL PAYMENT ADMIN BY AGENT:
DENY

CROSS_COUNTRY_LEAKAGE:
0

================================
REGRESSION
================================

SUPER ADMIN:
PASS

ACCOUNTANT:
PASS

FINANCE SEMANTICS:
UNCHANGED

PRICING:
UNCHANGED

PAYMENT CALCULATIONS:
UNCHANGED

================================
HANDOFF
================================

PURE ACTIVE AGENTS:
8

READY_FOR_HANDOFF:
8

NEEDS_PASSWORD_RESET:
8

BLOCKED:
3

PASSWORD LINKS GENERATED:
0

================================
FINAL
================================

AGENT_SECURITY_PRODUCTION:
PASS

AGENT_ACCOUNTS_READY_FOR_HANDOFF:
YES

NEXT:
PASSWORD_SETUP_AND_HANDOFF

STOP.
```
