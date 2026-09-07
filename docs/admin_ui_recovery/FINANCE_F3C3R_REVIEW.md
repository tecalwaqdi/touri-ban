# TOURi TAXI — FINANCE F3-C3R FINAL REVIEW

**BRANCH:** `recovery/admin-finance-f3c3-one-agent-per-country`  
**C3 IMPLEMENTATION COMMIT:** `27fe5042a23d9f3d0789472898b9e8382e6c1169`  
**C2 BASE:** `2029014`  
**REVIEW MODE:** READ-ONLY vs production (no deploy, no seed, no agent/order mutation)  
**C3R FIXES (local, not yet committed):**  
1. Atomic `moveActiveAgentCountry` (single txn; replaces release→claim gap)  
2. `claimCountryAgent` may create `user/{uid}` when `agentPatch` provided (`createPanelUser` path)

**FIREBASE PROJECT:** `tutorial-multi-language-70gx4j`  
**READY_FOR_F3-B:** **NO**

---

## A — EXACT DIFF REVIEW (27fe504 vs 2029014)

| File | Class |
|---|---|
| `admin/Admi/firebase/functions/agent_active.js` | REQUIRED |
| `admin/Admi/firebase/functions/agent_country_assignment.js` | REQUIRED |
| `admin/Admi/firebase/functions/index.js` | REQUIRED |
| `admin/Admi/firebase/firestore.rules` | RULES |
| `admin/ara_oatan_app/firebase/firestore.rules` | RULES |
| `admin/mndob-main/firebase/firestore.rules` | RULES |
| `admin/Admi/lib/admin/edet_agent/edet_agent_widget.dart` | ADMIN |
| `admin/Admi/lib/backend/admin_user_creation.dart` | ADMIN |
| `admin/Admi/lib/core/cloud_functions/cloud_functions_client.dart` | ADMIN |
| `admin/Admi/firebase/functions/test/agent_country_assignment.test.js` | TEST |
| `admin/Admi/firebase/functions/scripts/f3c3_agent_country_assignment_dry_run.js` | DOC/TOOL |
| `docs/admin_ui_recovery/FINANCE_F3C3_ONE_AGENT_PER_COUNTRY.md` | DOC |

**UNRELATED:** `0` product files outside C3 scope.

**RULES NOTE (Customer/Driver copies):** Bringing `ara_oatan_app` / `mndob-main` rules to byte-identity with Admi also syncs a pre-existing Admi `driverCanAdvanceTrip` allowlist (`ALLNOW`, `DATEEND`, `driverHeading`, `speed`, `etaApproximate`, `etaUpdatedAt`) that was already on Admi at C2 but missing from the older Customer/Driver copies. C3 agent hunks are identical across all three (`shasum` match). Treat Admi rules as the production source of truth for blast-radius accounting.

---

## B — RULES BLAST RADIUS

**RULE PATHS CHANGED:**
1. `user/{document}` create via `panelCanProvisionUser` — agent create blocked (`notCreatingAgent`)
2. `user/{document}` update — Super Admin / Country Admin gated by `agentAssignmentFieldsUnchanged()`
3. `agent_country_assignment/{countryId}` — read Super/scoped Country Admin; **all client writes `false`**

**Protected fields (assignment state):** `Isagent`/`isagent`, `Rev_dloh_agent`, `agent_date_reg`, `agent_date_end`, and `actev_user` when subject is/was an agent.

**UNRELATED ACCESS CHANGE:** Customer/Driver mirror sync of `driverCanAdvanceTrip` allowlist vs their C2 copies (see A). **Admi C2→C3 agent delta unrelated access: 0.**

| Surface | Verdict |
|---|---|
| Customer normal ops | UNCHANGED (C3 hunks); mirror allowlist catch-up only if outdated copy was live |
| Driver normal ops | same |
| Auth/profile reads | UNCHANGED |
| Booking writes | UNCHANGED |
| Tracking / chat / landmarks / finance | UNCHANGED for C3 intent |
| Agent assignment fields | MORE RESTRICTIVE (intended) |

**CUSTOMER REGRESSION:** 0 (C3)  
**DRIVER REGRESSION:** 0 (C3; Admi already allowed listed tracking fields)  
**ADMIN NORMAL PROFILE REGRESSION:** 0 (name/phone/photo still writable if assignment fields unchanged)

---

## C — PROTECTED FIELDS

| Attempt | Result |
|---|---|
| Direct client change country / active / Isagent / date window | **BLOCKED** by rules |
| Agent phone / name / photo (assignment fields unchanged) | **ALLOWED** if previously allowed |
| Lock collection client write | **BLOCKED** |

---

## D — SERVER CALLABLE AUTH

| Callable | Roles | Country scope | Validation | Txn | Audit | Idempotent |
|---|---|---|---|---|---|---|
| `assignActiveCountryAgent` | Super + Country Admin | Country Admin own `country_id` only | agent+country | claim txn | claim | same agent re-claim |
| `reassignActiveCountryAgent` | **Super only** | N/A (super) | country+newAgent | single txn | reassign | same new = no-op |
| `deactivateCountryAgent` | Super + Country Admin | own country | agent+country | release txn | release | — |
| `updateCountryAgentAssignment` | **Super only** | N/A | profile+active+country | claim / **move** / release | via helpers | claim path |
| `createPanelUser` (agent branch) | Super + Country Admin | Country Admin forced to own country | email/password + scope | claim(+create doc) | claim | — |

**Cross-country Country Admin:** **REJECT** (`assertCountryScope` / createPanelUser scope).  
**Country Agent / ordinary user:** **REJECT** (`requireSuperOrCountryAdmin` / createPanelUser gate).

---

## E — COUNTRY ADMIN POLICY

**COUNTRY ADMIN ASSIGNMENT POLICY: PROVEN** (pre-existing `createPanelUser` Country Admin agent create + scoped `Rev_dloh_agent`; C3 continues with scoped `assign`/`deactivate`, not newly invented Super-only expansion).

**May never:** assign/replace/move into another country — enforced by scope checks.  
**Explicit transfer:** Super Admin only (`reassignActiveCountryAgent`).  
**Profile/update callable:** Super Admin only (Admin `edet_agent` path).

---

## F — LOCK MODEL

`agent_country_assignment/{countryDocId}` → `active_agent_id`, `country_path`, `updated_at`, `updated_by`, `source`.

| Invariant | Status |
|---|---|
| 0 active → lock absent or `active_agent_id: null` | YES (seed creates only for 1-active) |
| 1 active → lock points to that uid | YES after successful claim |
| 2+ via approved path | NEVER |
| Post-txn lock == active agent | YES |

---

## G — LOCK STALENESS

| Scenario | Behavior |
|---|---|
| Deactivate | release clears lock |
| Move country | atomic clear old + claim new |
| Delete agent | lock may orphan until next claim; reclaim if holder inactive |
| `agent_date_end` expires | holder fails `isAgentActiveAt`; next claim **reclaims** stale lock |
| Future `agent_date_reg` | treated inactive; reclaimable |
| Explicit reassign | single txn swap |

**STALE LOCK RISK:** residual **YES** (expired holder can leave lock pointer until next claim) — **does not permanently block** country (reclaim on claim). No manual cleanup required for activation.

---

## H — DATE WINDOWS

`windowsOverlap`: `a.startMs <= b.endMs && b.startMs <= a.endMs` (inclusive).  
Missing start → −∞; missing end → +∞.  
Parse via Timestamp `.toDate()` / `Date.parse` / number — **not string order**.

| Case | Result |
|---|---|
| A ends Sep 10, B starts Sep 11 | **allowed** (no overlap) |
| A ends Sep 10 23:59, B starts Sep 10 23:59 | **overlap true** (same instant inclusive) |
| Open / no dates | open-ended / infinite window |

**DATE OVERLAP LOGIC:** PASS  
**TIMEZONE SAFE:** YES (instant ms; ISO/Timestamp)

---

## I — CONCURRENCY

Unit FakeDb serialized txn race: **ONE SUCCESS / ONE CONFLICT** (PASS).  
Idempotent same-agent claim: assignment unchanged; audit may append `agent_country_claim_idempotent` (no idempotency-key dedupe contract).

**TWO SIMULTANEOUS ACTIVATIONS:** ONE_SUCCESS  
**IDEMPOTENT RETRY:** PASS (state)

---

## J — REASSIGNMENT

`reassignCountryAgent`: deactivate old + activate new + lock in **one** transaction.  
Failure → Firestore txn rollback.  
No post-success 0/2 leak from approved path.

**ATOMIC:** PASS  
**ROLLBACK:** PASS

---

## K — NO SILENT REPLACEMENT

Normal `claim` / activate → **REJECT** if another active.  
Only `reassignActiveCountryAgent` replaces.  
**SILENT REPLACEMENT:** 0

---

## L — SEED DRY RUN (read-only)

```
conflicts: 0
seed_count: 9
zero_agent_countries: 4 (chad, niger, nigeria, cp5_country_…)
production_writes: 0
```

Proposed locks (uid only): india, indonesia, kyrgyzstan, malaysia, morocco, portugal, saudi_arabia, spain, tunisia — one active each.

---

## M — EXISTING PRODUCTION LOCKS

**CURRENT PRODUCTION LOCKS: NONE** (0 docs in `agent_country_assignment`)  
**Classify:** NONE → safe to seed in C3D  
**READY_FOR_C3D blocker from locks:** no

---

## N / O — CREATE PANEL USER + AUTH/FIRESTORE

- Non-agent create: unchanged set path (no claim).  
- First active agent: assert + claim (now creates user doc in txn).  
- Second active: conflict.  
- Auth created then claim fails → `deleteUser` + delete user doc.

**AUTH/FIRESTORE PARTIAL FAILURE RISK:** YES (Auth outside Firestore txn)  
**RECOVERY:** best-effort Auth delete + user doc delete; if cleanup fails, orphan Auth possible (logged) — no active duplicate without lock claim success.

**NON_AGENT REGRESSION:** 0 (code path)

---

## P — AUDIT

Actions: `agent_country_claim`, `agent_country_claim_idempotent`, `agent_country_release`, `agent_country_reassign`, `agent_country_move`.  
Fields: actor, country, previous/new agent, timestamp, action, source, optional reason. No secrets.

---

## Q — C2 DEFENSIVE FALLBACK

Customer `agent_order_snapshot.js` unchanged by C3; tests PASS including **ambiguous never picks agent**.

**C2 FALLBACK PRESERVED:** YES  
**AMBIGUOUS FALLBACK:** PRESERVED

---

## R — HISTORICAL IMMUTABILITY

C3 writes: `user`, `agent_country_assignment`, `admin_audit_log` only.  
**ORDER WRITES:** 0  
**HISTORICAL AGENT SNAPSHOT WRITES:** 0  
**HISTORICAL MONEY WRITES:** 0

---

## S — ADMIN UI

Conflict Arabic via `AdminUserCreation.authErrorMessage`: **"يوجد وكيل نشط بالفعل لهذه الدولة"**  
`edet_agent` uses `updateCountryAgentAssignment` (Super).  
Reassign callable exists separately (explicit transfer). No broad redesign.

---

## T — TESTS (this review)

| Suite | Result |
|---|---|
| Functions `agent_country_assignment.test.js` | **PASS** (15) after C3R fixes |
| Customer `agent_order_snapshot.test.js` | **PASS** |
| Firestore rules emulator (new C3 helpers) | **NOT COVERED** by existing `phase_8a_rules_isolation` |
| Admin widget unit | not run (mapped AR + callable wire reviewed statically) |
| Finance settlement suites | not required for C3 mutation surface; no C3 finance formula change |

**NEW FAILURES:** 0 in run suites

---

## U — DEPLOYMENT PLAN ONLY (do not execute in C3R)

**FUNCTIONS:**  
`createPanelUser`, `assignActiveCountryAgent`, `reassignActiveCountryAgent`, `deactivateCountryAgent`, `updateCountryAgentAssignment` (+ shared `agent_country_assignment.js` / `agent_active.js`)

**FIRESTORE RULES:** YES (Admi canonical; Customer/Driver mirrors identical)  
**ADMIN WEB:** YES (edet_agent + create error map + CF client)  
**SEED:** YES (dry-run tool → apply only in C3D)  
**INDEXES:** NO change in C3 commit

**ORDER:**
1. Deploy Admin Functions (callables + createPanelUser claim)  
2. Deploy Admin web build that calls callables (before rules block direct assignment edits)  
3. Deploy Firestore rules (block client assignment writes)  
4. Re-run dry-run; seed 9 locks with `--apply` only after C3D approval  
5. Smoke: create non-agent; create first agent; second agent conflict; Super edit; Country Admin cross-country reject

---

================================
FINAL REPORT CARD
================================

**DIFF UNRELATED:** 0 (product); rules mirror catch-up noted  

**UNRELATED ACCESS CHANGE:** 0 on Admi C3 agent delta; Customer/Driver allowlist sync = pre-Admi drift  

**CUSTOMER / DRIVER / ADMIN PROFILE REGRESSION:** 0 (C3 intent)  

**SUPER ADMIN:** PASS  
**COUNTRY ADMIN OWN COUNTRY:** PASS (assign/create/deactivate)  
**COUNTRY ADMIN CROSS COUNTRY:** REJECT  
**COUNTRY AGENT:** REJECT  

**LOCK MODEL:** `agent_country_assignment/{countryDocId}`  
**STALE LOCK RISK:** YES (reclaimable; non-blocking)  
**CURRENT PRODUCTION LOCKS:** NONE  
**EXPECTED SEED:** 9  
**CONFLICTS:** 0  

**TWO SIMULTANEOUS ACTIVATIONS:** ONE_SUCCESS  
**IDEMPOTENT RETRY:** PASS  

**REASSIGNMENT ATOMIC / ROLLBACK:** PASS / PASS  
**SILENT REPLACEMENT:** 0  

**DATE OVERLAP / TIMEZONE:** PASS / PASS  

**CREATE PANEL USER NON_AGENT:** 0  
**AUTH/FIRESTORE PARTIAL FAILURE:** YES — recovery Auth+doc delete  

**C2 AMBIGUOUS FALLBACK:** PRESERVED  
**ORDER / SNAPSHOT WRITES:** 0 / 0  

**FUNCTIONS TESTS:** PASS  
**RULES EMULATOR (C3-specific):** NOT COVERED  
**ADMIN / FINANCE:** static / N/A  

---

## FINAL

**F3-C3 REVIEW:** **PASS** (after local C3R defect fixes; commit before C3D)  

**READY_FOR_F3-C3D:** **YES** — only after committing:
1. atomic country move  
2. createPanelUser claim-create path  

**READY_FOR_F3-B:** **NO**

**STOP.**
