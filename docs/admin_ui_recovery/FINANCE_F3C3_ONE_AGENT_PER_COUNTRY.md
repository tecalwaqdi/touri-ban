# TOURi TAXI — FINANCE F3-C3 ONE AGENT PER COUNTRY REPORT

**BASE:** `recovery/admin-finance-f3c2-agent-snapshot` @ `2029014`  
**BRANCH:** `recovery/admin-finance-f3c3-one-agent-per-country`  
**PRODUCTION DEPLOY:** NO  
**PRODUCTION DATA WRITES:** 0  

---

## A — AGENT_MUTATION_MATRIX

| Source | File | Function/action | Create? | Change country? | Activate? | Deactivate? | Server validated? | Concurrency safe? | Risk |
|---|---|---|---|---|---|---|---|---|---|
| Admin CF | `Admi/firebase/functions/index.js` | `createPanelUser` | YES | YES (on create) | YES | NO | **YES (F3-C3 claim)** | **YES** | Was race; now locked |
| Admin CF | `agent_country_assignment.js` | `assignActiveCountryAgent` | NO | NO | YES | NO | YES | YES | Low |
| Admin CF | `agent_country_assignment.js` | `reassignActiveCountryAgent` | NO | YES | YES | YES (old) | YES | YES | Explicit only |
| Admin CF | `agent_country_assignment.js` | `deactivateCountryAgent` | NO | NO | NO | YES | YES | YES | Low |
| Admin CF | `agent_country_assignment.js` | `updateCountryAgentAssignment` | NO | YES | YES | YES | YES | YES | Replaces direct edit |
| Admin UI | `admin_add_agent_widget.dart` | create via `AdminUserCreation` | YES | YES | YES | NO | via CF | via CF | Error mapped AR |
| Admin UI | `edet_agent_widget.dart` | save profile | NO | YES | YES | YES | **via CF (F3-C3)** | via CF | Was direct write |
| Admin UI | `admin_agent_widget.dart` | delete agent | NO | NO | NO | delete | Delete only | N/A | Lock may orphan until C3D cleanup |
| Client fallback | `admin_user_creation.dart` secondary Auth | create user doc | YES | YES | YES | NO | **BLOCKED for agents** | N/A | Rules + code block |
| Firestore rules | Super Admin update | direct field write | — | was YES | was YES | was YES | **BLOCKED assignment fields** | N/A | Bypass closed |
| Scripts | `seed_demo_users.js` etc. | seed | YES | YES | YES | — | NO | NO | LEGACY / offline only |
| Customer C2 | `agent_order_snapshot.js` | booking snapshot | NO | NO | NO | NO | N/A | N/A | Read-only resolve |

**TOTAL AGENT MUTATION PATHS (production-relevant):** 8  
**SERVER SAFE (after C3):** createPanelUser + 4 callables + UI wired  
**UNSAFE (mitigated):** Super Admin direct assignment writes → rules blocked  
**LEGACY:** seed scripts (not production panel)

---

## B — Canonical active rule

**RULE:** `isAgentActiveAt(data, at)` in `agent_active.js`  
Identical to C2: `Isagent`/`isagent` + `actev_user !== false` + optional `agent_date_reg` / `agent_date_end`.

**DATE WINDOW:** Enforced for “active now”. Overlapping effective windows among assigned agents rejected with `AGENT_COUNTRY_DATE_OVERLAP` on claim.

---

## C — Country identity

Canonical: `countries/{id}` path via `Rev_dloh_agent` / lock `country_path`.  
**CROSS_COUNTRY FALSE MATCH: 0** (path equality only).

---

## D–F — Enforcement design

| Property | Value |
|---|---|
| SERVER AUTHORITATIVE | **YES** |
| ATOMIC | **YES** (Firestore transaction + lock doc) |
| CONCURRENCY SAFE | **YES** (proven unit test) |
| IDEMPOTENT | **YES** (same agent re-claim) |
| COUNTRY LOCK MODEL | `agent_country_assignment/{countryDocId}` · `active_agent_id` |
| AUTO-DEACTIVATE OLD | **NO** on conflict — reject `AGENT_COUNTRY_ALREADY_HAS_ACTIVE_AGENT` |
| EXPLICIT TRANSFER | `reassignActiveCountryAgent` (Super Admin) |
| ROLLBACK SAFE | Auth user deleted if create claim fails |

---

## G — Zero agents

**ALLOWED.** Chad / Niger / Nigeria / cp5 remain empty. No auto-create.

---

## H–J — Create / move / reactivate

Create active agent → claim before commit.  
Country move while active → release old + claim new (explicit path in update callable).  
Reactivate blocked if another active.

---

## L–N — Auth / rules

| Role | Assign / activate / reassign |
|---|---|
| Super Admin | YES (all callables) |
| Country Admin | createPanelUser + assign/deactivate in own country; **no** reassign |
| Country Agent | NO |

**BYPASS PATHS:** Client agent create blocked (rules + no fallback). Assignment field client updates blocked (`agentAssignmentFieldsUnchanged`).

**FIRESTORE RULES CHANGED: YES** (Admi + synced ara_oatan + mndob byte-identical copies)  
**DIRECT PROTECTED FIELD WRITE: BLOCKED**  
Rules alone cannot query uniqueness → lock + CF remain source of truth.

---

## O — Audit

Successful claim / release / reassign writes `admin_audit_log` with actor, country, previous/new agent, action, source.

---

## P — C2 preserved

Booking resolver still: `none` / attributed / `ambiguous` — **PRESERVED** (Customer tests PASS).

---

## Q — Historical

**OLD ORDERS / SNAPSHOTS MODIFIED: 0**

---

## R — Live precheck

| Bucket | Count |
|---|---|
| 0 active | 4 |
| 1 active | 9 |
| 2+ | **0** |
| Conflicts | **0** |

---

## S — Tests

| Suite | Result |
|---|---|
| Unit (active + assignment) | PASS |
| Concurrency | PASS (exactly one success) |
| C2 agent snapshot | PASS |
| F1 + money precision | PASS |
| NEW FAILURES | 0 |

---

## U — Dry-run seed plan

**UNIQUENESS RECORDS REQUIRED: YES**  
**EXISTING 1-ACTIVE:** 9 (seed lock docs)  
**ZERO-AGENT:** chad, niger, nigeria, cp5_*  
**CONFLICTS:** []  
**PRODUCTION DATA WRITES: 0** (`--apply` refused)

Script: `scripts/f3c3_agent_country_assignment_dry_run.js`

---

## V — Deploy blast radius (do not deploy)

| Surface | Items |
|---|---|
| Functions | `createPanelUser`, `assignActiveCountryAgent`, `reassignActiveCountryAgent`, `deactivateCountryAgent`, `updateCountryAgentAssignment` |
| Rules | Admi (+ synced Customer/Driver copies) |
| Admin | `edet_agent`, `admin_user_creation`, `cloud_functions_client` |
| Indexes | none new (existing Isagent+Rev_dloh_agent) |
| Seed | dry-run only |

**PRODUCTION DEPLOY: NO**

---

## FINAL

```
F3-C3: READY_FOR_REVIEW
ONE COUNTRY = ONE ACTIVE AGENT: CODE_ENFORCED
READY_FOR_F3-C3D: YES
READY_FOR_F3-B: NO
```

**STOP.**
