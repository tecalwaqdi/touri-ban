# TOURi TAXI — MAIN SECURITY SOURCE PARITY

**Date:** 2026-09-08  
**Branch:** `recovery/main-security-parity` → **merged to `main`** (`0965253`)  
**Method:** Clean worktree from `origin/main`; cherry-pick `-n` of `83344c5` security file set only (no demo/UI); plus minimal guard scripts.

## Result SHAs

| | |
|--|--|
| **OLD MAIN** | `d50d620ad97132a958351c0a6f2c44783bf6b6fb` |
| **NEW MAIN** | `096525327b115bbe709570ffbf2168398651f856` |
| **SECURITY BASELINE** | `83344c5` equivalent (Rules byte-match live; Payment/Functions semantic match) |

## Ancestry

| Commit | Role |
|--------|------|
| `d50d620` | OLD MAIN / Admin live |
| `1a91b44`…`95e373a` | Demo-mode feature history (**excluded**) |
| `83344c5` | Approved live F03/F07 security patch |
| `a4964ff` | Docs/cutover on feature branch (**excluded**) |

**ALREADY_IN_MAIN (before):** none of F03/F07 protections  
**MISSING_FROM_MAIN (before):** full `83344c5` security file set  
**CONFLICTS:** none (cherry-pick applied cleanly onto `d50d620`)

## Selected files (canonical patch)

1. `admin/Admi/firebase/firestore.rules`  
2. `admin/Admi/firebase/functions/agent_country_assignment.js`  
3. `admin/Admi/firebase/functions/driver_financial_summary_v2.js`  
4. `admin/Admi/firebase/functions/index.js` (createPanelUser rate validation)  
5. `admin/Admi/firebase/functions/test/agent_handoff_security_f03_f07.test.js`  
6. `admin/services/payment-api/src/lib/auth/verify.ts`  
7. `admin/services/payment-api/src/lib/payments/status-handler.ts`  
8. `admin/services/payment-api/src/app/api/payments/refund/route.ts`  
9. `admin/services/payment-api/src/lib/auth/verify.f07.test.ts`  
10. `admin/services/payment-api/src/lib/auth/verify.f07.node.test.ts`  
11. `admin/services/payment-api/tsconfig.json` (exclude `*.node.test.ts` for typecheck)  
12. `admin/Admi/firebase/functions/package.json` (`test:security-f03-f07`)  
13. `admin/services/payment-api/package.json` (`test:f07`)  
14. `admin/Admi/firebase/scripts/security_f03_f07_guard.sh`

**Excluded:** Demo Mode, Admin UI, AGENT_HANDOFF docs from `83344c5`, feature dirty tree.

## Rules vs live

| | |
|--|--|
| Live ruleset | `d5980f32-5120-471f-8d61-d9bc748e8ea3` |
| Live sha256 | `4bf5e1b5829409bac513e143a3fdbe9bff28d2734aa6efff266be615875efe53` |
| Main candidate sha256 | **identical** `4bf5e1b…` |
| Verdict | **MATCH** (byte hash) |

## Functions vs live

| Function | Classification |
|----------|----------------|
| `getDriverFinancialSummaryV2` | **SEMANTIC_MATCH** (source now equals approved `83344c5` behavior) |
| `createPanelUser` | **SEMANTIC_MATCH** |
| `updateCountryAgentAssignment` | **SEMANTIC_MATCH** |

No Function redeploy in this phase.

## Payment vs live

Source now contains `resolveFinanceAccess` / `assertResourceCountryAccess` from `83344c5`.  
Live Render already on `83344c5`.  
Verdict: **SEMANTIC_MATCH** (no Payment redeploy).

## Tests

| Suite | Result |
|-------|--------|
| `node --test` F03/F07 + C3 | **34/34 PASS** |
| agent_order_snapshot | **4/4 PASS** |
| payment `test:f07` | **5/5 PASS** |
| payment `npm test` | **93/93 PASS** |
| payment typecheck/build | **PASS** |
| `security_f03_f07_guard.sh` | **PASS** |
| NEW FAILURES | **0** |

## Deployment

| Action | Status |
|--------|--------|
| PRODUCTION RULES DEPLOY | **NO** |
| FUNCTION DEPLOY | **NO** |
| PAYMENT DEPLOY | **NO** |
| REASON | source parity only; live already secured |

## Reproducibility

Fresh clean worktree from `origin/main` + this commit; no untracked deps required for security tests beyond `npm ci` in functions/payment-api.
