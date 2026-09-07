# TOURi TAXI — FINANCE F3-C1D DEPLOYMENT REPORT

**APPROVED CODE (review):** `fad73797aec44645c587cb6eea8e7536a2c9f4a0`  
**IMPLEMENTATION:** `565b1cd`  
**DEPLOY HEAD:** `4c646f8e2a63a03ff2729741bafe5cd70bd5509e` (docs-only descendant: F3-C1R review)  
**PROJECT:** `tutorial-multi-language-70gx4j`  
**FUNCTIONS WORKSPACE:** `admin/ara_oatan_app/firebase/functions` (codebase `functions`)  
**NOT USED:** `admin/Admi/firebase/functions`

---

## A — Pre-deploy gate

| Check | Result |
|---|---|
| Branch | `recovery/admin-finance-f3c1-write-path` |
| HEAD | `4c646f8` (approved docs-only descendant of `fad7379`) |
| Worktree at deploy | packaging-only untracked Admi module copies for `index.js` load (see Packaging note); no finance code edits |
| Firebase project | `tutorial-multi-language-70gx4j` |
| Directory | Customer `ara_oatan_app/firebase` |

### Packaging note (deploy hygiene, not a finance change)

`index.js` requires `driver_registration_v2.js` → modules that exist under **Admin** `Admi/firebase/functions` but are not present in this Customer functions tree on git. Firebase analysis failed until identical files were copied **locally (untracked)** for package load:

- `driver_submit_validation.js`
- `driver_country_resolver.js`
- `driver_country_config.js`
- (+ companions referenced by the same graph)

Copies were **removed after deploy** and **not committed**. They do not alter C1 booking snapshot semantics. Peer functions were **not** redeployed.

---

## B — Exact exports

| Item | Value |
|---|---|
| **EXPORT NAME** | `createCashBooking` |
| REGION | `us-central1` |
| GENERATION | **1st** (`gcfv1` / Firebase Version `v1`) |
| Trigger | callable |
| Entry point | `createCashBooking` |
| Codebase | `functions` |

| Item | Value |
|---|---|
| **EXPORT NAME** | `finalizeNGeniusBooking` |
| REGION | `us-central1` |
| GENERATION | **1st** |
| Trigger | callable |
| Entry point | `finalizeNGeniusBooking` |
| Codebase | `functions` |

CLI filter used:

```bash
firebase deploy --only functions:functions:createCashBooking,functions:functions:finalizeNGeniusBooking \
  --project tutorial-multi-language-70gx4j
```

(`functions:` without codebase prefix → `No function matches`)

---

## C — Pre-deploy production versions

See also `FINANCE_F3C1D_PREDEPLOY_MANIFEST.md`.

| Function | Runtime | Version | Update time | Hash |
|---|---|---|---|---|
| createCashBooking | nodejs22 | 5 | 2026-08-27T12:30:33.392Z | `ac043d1187e7918da50125875858281eb882bd37` |
| finalizeNGeniusBooking | nodejs22 | 1 | 2026-08-21T00:45:08.370655628Z | `5199f5eef4b95bd0139b402fc593f8583ee18462` |

---

## D — Local test gate

| Suite | Result |
|---|---|
| `ngenius_payments_unit.test.js` | PASS |
| Fixtures 50/7.5/0→42.5 and 800/120/120→560 | PASS |
| `financial_accounting_v2.test.js` (Admi functions) | PASS |
| F1 semantics + money precision (Flutter) | PASS |

**TESTS: PASS**

---

## E — Deployment

```
✔ functions[functions:finalizeNGeniusBooking(us-central1)] Successful update operation.
✔ functions[functions:createCashBooking(us-central1)] Successful update operation.
✔ Deploy complete!
```

**Expected changed production functions: 2 — observed: 2**

---

## F — Post-deploy versions

| Function | Runtime | Version | Update time | Hash |
|---|---|---|---|---|
| createCashBooking | nodejs22 | **6** | **2026-09-05T22:53:41.881Z** | `4818e92fa609c0fd48645f232f3b1c2a58ed9b86` |
| finalizeNGeniusBooking | nodejs22 | **2** | **2026-09-05T22:53:39.903Z** | `4818e92fa609c0fd48645f232f3b1c2a58ed9b86` |

Unrelated peer still on prior package:

| Function | Hash (unchanged) |
|---|---|
| normalizeCashBookingCompatibility | `ac043d1187e7918da50125875858281eb882bd37` |
| approveDriverRegistration | `bd1326c7693c53c51a38f9a2a9d86323bc4ef608` |
| submitDriverApplicationV2 | `7d4a7bc6b79b0bd473ad580131fd01273b127f57` |
| requestEmailVerificationOtp | `f2eb79445f57313ee1881f67071767c87cf96502` |

**UNRELATED FUNCTIONS UPDATED: 0**

---

## G — Safe runtime QA harness

Canonical detector (`AdminQaFixture` / `isFinanceQaFixture`):

- `is_test_fixture` / `qa_fixture` / `test_fixture`
- ID prefixes: `fin7_ctrl_`, `fin9_ctrl_`, `fin_rt_cash_`, `fin_rt_cash_ui_`, `fin_rt_`

`createCashBooking` today:

- generates hash order IDs (not `fin_*`)
- does **not** stamp `is_test_fixture`
- golden markers `functional_test` / `golden_cycle` are **not** recognized by `AdminQaFixture` (F3-A2 known gap)

**SAFE EXISTING QA BOOKING HARNESS: NO**

**RUNTIME_BOOKING_E2E: BLOCKED_NO_SAFE_QA_HARNESS**

No production booking created. No ordinary production-looking test order.

---

## H–L — Runtime booking / online E2E

| Gate | Result |
|---|---|
| Controlled cash QA order | **NOT CREATED** |
| Financial snapshot live | **NOT_TESTED** |
| Normal finance contribution | **NOT_TESTED** |
| Online runtime | **NOT_RUN_SAFETY** |

---

## M — Historical read-only confirmation

Read via Firestore REST (no writes):

| Order | IDorder | total / app / vat | total_mndob2 | total_mndob |
|---|---|---|---|---|
| `03392f80a1…` | CASH-03392F80A1 | 200 / 30 / 0 | **null** | **null** |
| `7b9a80c306…` | CASH-7B9A80C306 | 50 / 7.5 / 0 | **null** | **null** |

Still PARTIAL as of F3-A2. **No backfill.**

**HISTORICAL ORDERS MODIFIED: 0**

---

## N — Logs

Post-deploy window: only Cloud Functions **UpdateFunction** audit events for the two targets.  
No new runtime exceptions / NaN / transaction failures after this deploy (no post-deploy invocations yet).

Pre-deploy App Check warnings on cash booking are pre-existing (enforcement disabled); not introduced by C1D.

**NEW TARGET FUNCTION ERRORS: 0**

---

## Side effects

| Check | Result |
|---|---|
| Settlements created by fix | 0 |
| Ledger by C1D | 0 |
| Wallet by C1D | 0 |
| Agent backfill | 0 |
| Historical mutation | 0 |
| Admin / mobile deploy | NO |
| Financial semantics (F1/F2) | NO change |

---

## FINAL

```
APPROVED CODE: fad73797aec44645c587cb6eea8e7536a2c9f4a0
PROJECT: tutorial-multi-language-70gx4j

BRANCH: recovery/admin-finance-f3c1-write-path
WORKTREE: packaging hygiene only (untracked; cleaned after deploy)
TESTS: PASS

CREATE CASH EXPORT: createCashBooking
REGION: us-central1
PREVIOUS UPDATE TIME: 2026-08-27T12:30:33.392Z
NEW UPDATE TIME: 2026-09-05T22:53:41.881Z

FINALIZE ONLINE EXPORT: finalizeNGeniusBooking
REGION: us-central1
PREVIOUS UPDATE TIME: 2026-08-21T00:45:08.370655628Z
NEW UPDATE TIME: 2026-09-05T22:53:39.903Z

UNRELATED FUNCTIONS UPDATED: 0

createCashBooking: PASS
finalizeNGeniusBooking: PASS
PRODUCTION FUNCTION DEPLOY: YES
ADMIN PRODUCTION DEPLOY: NO
MOBILE DEPLOY: NO

SAFE QA HARNESS: NO
CASH QA ORDER: NONE
FINANCIAL SNAPSHOT: NOT_TESTED
QUOTE MATCH: NOT_TESTED
NORMAL FINANCE CONTRIBUTION: NOT_TESTED
ONLINE RUNTIME: NOT_RUN_SAFETY

HISTORICAL ORDERS MODIFIED: 0
BACKFILL: 0
SETTLEMENTS CREATED BY FIX: 0
AGENT SNAPSHOT MODIFIED: NO
FINANCIAL SEMANTICS CHANGED: NO

NEW TARGET FUNCTION ERRORS: 0

F3-C1D DEPLOY: PASS
FUTURE CORE FINANCIAL SNAPSHOT: CODE_VERIFIED_ONLY
READY_FOR_F3-C2: YES
READY_FOR_F3-B: NO
```

**STOP.**

### Recommended F3-C2 (out of scope here)

Add a **recognized** Finance QA path (existing `AdminQaFixture.stamp` / `fin_rt_*` contract) so a controlled `createCashBooking` can prove live COMPLETE snapshot without leaking into accountant Hub.
