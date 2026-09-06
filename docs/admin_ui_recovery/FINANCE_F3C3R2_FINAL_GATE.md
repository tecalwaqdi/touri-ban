# TOURi TAXI — FINANCE F3-C3R2 FINAL GATE

**BRANCH:** `recovery/admin-finance-f3c3-one-agent-per-country`  
**C3 IMPLEMENTATION:** `27fe5042a23d9f3d0789472898b9e8382e6c1169`  
**C3R FIX COMMIT:** `e1d8c59` (atomic move + createPanelUser claim-create)  
**C3R2 CLOSURE COMMIT:** `e9191a40c5b297d637cd3f2238faa8d565571803`  

**PRODUCTION DEPLOY:** NO  
**SEED:** NO  
**PRODUCTION MUTATION:** NO  
**READY_FOR_F3-B:** NO  

---

## STEP 1 — C3R FIX COMMIT

**C3R FIX COMMIT:** `e1d8c59`  
**REMOTE PUSH:** PASS (`origin/recovery/admin-finance-f3c3-one-agent-per-country`)

Includes:
- `moveActiveAgentCountry` single-transaction country move
- `claimCountryAgent` create-via-`agentPatch` for `createPanelUser`
- focused tests + `FINANCE_F3C3R_REVIEW.md`

---

## STEP 2 — STALE LOCK CLOSURE

Transactional reclaim rule (`classifyLockHolder` inside claim/move txn):

| Classification | Meaning | Claim behavior |
|---|---|---|
| **VALID** | holder exists, Isagent, same country, `actev_user !== false`, inside date window | **CONFLICT** — never steal |
| **STALE** | missing/deleted, inactive, wrong country, expired end, future start | **reclaim** in same txn |
| **AMBIGUOUS** | date field present but unparseable | **REJECT** `AGENT_COUNTRY_LOCK_AMBIGUOUS` — never guess |

Focused tests cover: inactive, moved country, deleted user, expired end, future start, country mismatch, valid protect, ambiguous reject, move rollback.

**STALE LOCK PERMANENT BLOCK RISK:** 0  
**STALE LOCK FALSE RECLAIM RISK:** 0  
**RECLAIM TRANSACTIONAL:** YES  

---

## STEP 3 — RULES PRODUCTION DIFF

Fetched live release `cloud.firestore` ruleset  
`projects/.../rulesets/aeed881c-4d83-4891-bead-fcb614ab136c`  
(updated `2026-08-29`).

**Earlier branch rules were NOT deploy-safe:** they would have *removed* production
`driverCanAdvanceTrip` terminal-status guard and `statusUpdatedAt` allowlist entry.

**C3R2 action:** rebuild all three copies from **production rules + C3-only patches**:

1. `agentAssignmentFieldsUnchanged()`
2. `notCreatingAgent` on `panelCanProvisionUser`
3. Super/Country Admin update gated by assignment freeze
4. Self-update also requires assignment freeze (closes actev/date self-bypass)
5. `match /agent_country_assignment/{id}` client writes `false`

**PRODUCTION C3 DELTA ISOLATED:** YES  
**UNRELATED PRODUCTION RULE CHANGE:** 0  

Preserved from production: terminal status regress block, `statusUpdatedAt`, all other non-agent paths.

Byte-identical across Admi / ara_oatan_app / mndob-main.

---

## STEP 4 — RULES EMULATOR

Suite: `admin/ara_oatan_app/firebase/functions/test/f3c3_agent_assignment_rules.test.js`  
Command: `firebase emulators:exec --only firestore` (JDK 21) against C3D-intended rules.

**Result:** 10/10 PASS  

Covers: blocked assignment field client writes; name/phone/photo allowed; Country Admin foreign blocked; Country Agent blocked; customer profile OK; driver online OK; booking create denied; trip advance + terminal regress preserved; chat/mkan reads; lock write denied.

**RULES EMULATOR:** PASS  
**UNRELATED RULE REGRESSIONS:** 0  
**CUSTOMER / DRIVER / ADMIN PROFILE REGRESSION:** 0 / 0 / 0  

---

## STEP 5 — CREATEPANELUSER COMPENSATION

Module: `panel_user_create_compensation.js`  
Wired into `createPanelUser` catch path with audit row + explicit  
`CREATE_PANEL_USER_COMPENSATION_INCOMPLETE` when Auth cleanup fails.

Tests: Auth+doc cleanup success; Auth orphan reported when delete fails.

**AUTH ORPHAN AFTER FAILED ASSIGNMENT:** 0 (when cleanup succeeds)  
**USER DOC ORPHAN:** 0  
**LOCK CORRUPTION:** 0 (failed claim does not commit lock)  
**COMPENSATION:** PASS  

---

## STEP 6 — MOVE TRANSACTION

`moveActiveAgentCountry`: single Firestore transaction clears old lock + claims new + updates agent.  
FakeDb rollback proven when destination VALID.

**SINGLE TRANSACTION:** YES  
**ROLLBACK:** PASS  

---

## STEP 7 — LIVE DRY RUN (read-only)

```
EXPECTED LOCKS: 9
ZERO-AGENT COUNTRIES: 4 (chad, niger, nigeria, cp5_country_…)
CONFLICTS: 0
EXISTING PROD LOCKS: 0 (NONE)
WRITES: 0
```

---

## STEP 8 — DEPLOYMENT ORDER (C3D only — do not execute here)

Evidence-based sequence to avoid broken agent editing:

1. **Deploy Admin Functions**  
   `createPanelUser`, `assignActiveCountryAgent`, `reassignActiveCountryAgent`,  
   `deactivateCountryAgent`, `updateCountryAgentAssignment`  
   (+ `agent_country_assignment.js`, `agent_active.js`, compensation helper)

2. **Deploy Admin web** that calls those callables (`edet_agent`, create error map)

3. **Deploy Firestore rules** from Admi canonical file  
   (= production + C3-only delta; Customer/Driver mirrors identical)  
   *After* Admin web so assignment edits are not stuck between blocked direct writes and missing UI callables.

4. **Seed locks** (dry-run apply of 9) via Admin SDK script only after 1–3  
   Re-run dry-run immediately before apply; abort if conflicts ≠ 0 or unexpected locks appear.

**INDEXES:** no C3 change  

---

## FINAL

| Gate | Result |
|---|---|
| F3-C3 FINAL REVIEW | **PASS** |
| READY_FOR_F3-C3D | **YES** |
| READY_FOR_F3-B | **NO** |
| PRODUCTION DEPLOY | **NO** |

**STOP.**
