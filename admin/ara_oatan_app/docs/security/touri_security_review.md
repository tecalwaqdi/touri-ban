# Touri Security Review

**Date:** 2026-07-18  
**Scope:** Config / package identity / payment status integrity (session audit)

## Findings

| ID | Severity | Finding | Status |
|----|----------|---------|--------|
| S1 | CRITICAL | Driver `google-services.json` `package_name` = `com.mycompany.araoatanapp` (customer) while `applicationId` = `com.mycompany.mndob2` | OPEN |
| S2 | HIGH | Payment/status CF changes not redeployed — prod may still write wrong codes | OPEN |
| S3 | MED | Unset→cash could create unintended cash orders (pre-fix) | FIXED locally |
| S4 | MED | Empty git clone — no provenance for who/what changed secrets | OPEN |
| S5 | LOW | Archive trees (`mndob-main` root, `arawatan/`) if published could confuse signing/Firebase | ARCHIVE policy |

## Package / Firebase matrix

| App | applicationId / bundle | google-services expectation | Status |
|-----|------------------------|-----------------------------|--------|
| Customer | `com.mycompany.araoatanapp` | Match customer | Assumed OK |
| Driver | `com.mycompany.mndob2` | Must match driver | **MISMATCH** |
| Admin | `com.mycompany.tutorialmultilanguageapp` | Match admin | Assumed OK |

All share Firebase project `tutorial-multi-language-70gx4j` — correct project, wrong Android package registration on driver is still a ship blocker.

## Payment integrity

| Control | Expectation | Status |
|---------|-------------|--------|
| Trip vs payment fields | Never use `halh_order` Paid as trip completed | FIXED |
| Pending after pay | `pending_driver` only (canonical) | FIXED local / deploy OPEN |
| Cash | Explicit method only | FIXED |

## Recommendations before store

1. Regenerate or correct driver `google-services.json` for `com.mycompany.mndob2`  
2. Redeploy Functions; verify webhook auth still enforced  
3. Confirm N-Genius keys are env-scoped (sandbox vs live)  
4. Establish git remote + first commit before store so rollbacks are auditable  

## Verdict

**NOT READY FOR STORE** until S1 and S2 are closed. Internal QA acceptable after unit tests if testers use known-good builds and accept sandbox payment limits.
