# TOURi TAXI — FINANCE F3-C3D PRODUCTION ROLLOUT

**PROJECT:** `tutorial-multi-language-70gx4j`  
**APPROVED SOURCE HEAD:** `9d4ca3a744ccea73aae2332c3f4a0ba4057e3811`  
**C3 IMPLEMENTATION:** `27fe504` · **C3R:** `e1d8c59` · **C3R2:** `e9191a4`  
**REVIEW DOC:** `docs/admin_ui_recovery/FINANCE_F3C3R2_FINAL_GATE.md`  
**PREDEPLOY:** `docs/admin_ui_recovery/FINANCE_F3C3D_PREDEPLOY_MANIFEST.md`  

**PRODUCTION DEPLOY:** YES (scoped)  
**CUSTOMER APP DEPLOY:** NO  
**DRIVER APP DEPLOY:** NO  
**F3-B:** NO  

---

## 0 — Source / environment

| Check | Result |
|---|---|
| Branch | `recovery/admin-finance-f3c3-one-agent-per-country` |
| Ancestors e1d8c59 / e9191a4 | YES |
| Worktree product code | CLEAN at start |
| Functions workspace | `admin/Admi/firebase/functions` (`admin_functions`) |
| Admin isolation | Built from live provenance `358783a` + C3 Admin patches only |

Packaging note: temporary local copies of unrelated Admi modules were required for Firebase analysis load of `index.js` (same hygiene as F3-C1D). **Removed after deploy; not committed.**

---

## 1 — Pre-deploy live scan

| Metric | Value |
|---|---|
| 0 active | 4 |
| 1 active | 9 |
| 2+ | 0 |
| conflicts | 0 |
| existing locks | 0 |
| LIVE_PREDEPLOY_DRIFT | **NONE** |

---

## 2 — Tests

| Suite | Result |
|---|---|
| assignment + concurrency + move + stale | PASS (25) |
| createPanelUser compensation | PASS |
| C2 agent_order_snapshot | PASS |
| Rules emulator F3-C3 | PASS (10) |
| finance_controls | PASS |

---

## 3–4 — Functions

**Deployed ONLY:**

| # | Export | Op | Region | Gen | Runtime | State | Hash |
|---|---|---|---|---|---|---|---|
| 1 | `createPanelUser` | UPDATE | us-central1 | 1st | nodejs20 | ACTIVE | `ee5d6f13…` |
| 2 | `assignActiveCountryAgent` | CREATE | us-central1 | 1st | nodejs20 | ACTIVE | `ee5d6f13…` |
| 3 | `reassignActiveCountryAgent` | CREATE | us-central1 | 1st | nodejs20 | ACTIVE | `ee5d6f13…` |
| 4 | `deactivateCountryAgent` | CREATE | us-central1 | 1st | nodejs20 | ACTIVE | `ee5d6f13…` |
| 5 | `updateCountryAgentAssignment` | CREATE | us-central1 | 1st | nodejs20 | ACTIVE | `ee5d6f13…` |

**Previous createPanelUser hash:** `7d4a7bc6…`  
**UNRELATED FUNCTIONS UPDATED:** 0  
**FUNCTION ERRORS (new init):** 0  

CLI:

```bash
firebase deploy --only \
  functions:admin_functions:createPanelUser,\
  functions:admin_functions:assignActiveCountryAgent,\
  functions:admin_functions:reassignActiveCountryAgent,\
  functions:admin_functions:deactivateCountryAgent,\
  functions:admin_functions:updateCountryAgentAssignment \
  --project tutorial-multi-language-70gx4j
```

---

## 5–6 — Admin Web

| Field | Value |
|---|---|
| Previous | 1.0.15+2017 @ `358783a` (live 2026-09-04) |
| New | 1.0.15+2017-f3c3d (live 2026-09-06 03:34:29) |
| Isolation | live provenance + `edet_agent` / `admin_user_creation` / C3 callables in `cloud_functions_client` |
| Smoke | PASS — `/admin/` 200, `version.json`/`build_provenance.json`/`main.dart.js` OK, callable string present |
| Customer/Driver hosting | **NO** |

---

## 7–8 — Firestore Rules

| Field | Value |
|---|---|
| Previous ruleset | `aeed881c-4d83-4891-bead-fcb614ab136c` (2026-08-29) |
| New ruleset | `6b56a943-57aa-4fde-abbd-401e741de515` (2026-09-06T00:35:58Z) |
| C3 delta isolated | YES |
| Unrelated rule changes | 0 |
| Terminal-status guard | PRESERVED |
| statusUpdatedAt | PRESERVED |
| LOCAL==DEPLOYED | YES |
| Post-rule regression | 0 (emulator suite PASS; production reads healthy) |

---

## 9–11 — Seed

| Field | Value |
|---|---|
| Pre-seed dry-run | PASS (9/4/0, locks 0) |
| Created | **9** |
| Skipped valid existing | 0 |
| Conflicts | 0 |
| Aborted | 0 |
| Zero-agent untouched | chad, niger, nigeria, cp5_country_* |
| User docs modified | **0** (locks only) |

### Post-seed reconciliation

| Metric | Value |
|---|---|
| Active-agent countries | 9 |
| Locks | 9 |
| Mismatches | 0 |
| Stale | 0 |
| Ambiguous | 0 |
| 2+ conflicts | 0 |

Seed provenance on each lock: `source=f3c3d_seed`, `updated_by=f3c3d_seed`, `seed_commit=9d4ca3a…`

---

## 13 — Authorization (server policy unchanged)

| Role | Result |
|---|---|
| Super Admin | PASS (all callables) |
| Country Admin own country | PASS (assign/create/deactivate scoped) |
| Country Admin foreign | REJECT |
| Country Agent | REJECT |

---

## 14 — C2 defense

`createCashBooking` / `finalizeNGeniusBooking` hash still `d430216…` (C2D). **Not redeployed.** Ambiguous fallback preserved.

---

## 15 — Historical safety

| Check | Result |
|---|---|
| Orders modified | 0 |
| Agent snapshots modified | 0 |
| Money backfill | 0 |
| Settlements | 0 |

---

## 17 — Rollback targets

| Layer | Rollback target |
|---|---|
| Functions | recreatePanelUser hash `7d4a7bc6…`; delete 4 new callables if needed |
| Admin Hosting | previous live release before 2026-09-06 03:34:29 (1.0.15+2017 @ 358783a) |
| Rules | ruleset `aeed881c-4d83-4891-bead-fcb614ab136c` |
| Locks | seed manifest = 9 docs listed in `/tmp/c3d_seed_result.json` with `source=f3c3d_seed` only — do not delete locks later rewritten by callables |

---

## 18 — First real Admin assignment checklist

When an operator next creates/activates/moves/deactivates/transfers:

1. Confirm callable used (`createPanelUser` / `assign*` / `update*` / `reassign*` / `deactivate*`)
2. Country scope matches actor
3. Lock `active_agent_id` matches active user
4. Old agent inactive on transfer/deactivate
5. `admin_audit_log` event present
6. No second active agent for country
7. No historical order/snapshot writes

---

## FINAL

**F3-C3D:** PASS  
**ONE COUNTRY = ONE ACTIVE AGENT:** PRODUCTION_ENFORCED  
**FUTURE MONEY SNAPSHOT:** PRESERVED  
**FUTURE AGENT SNAPSHOT:** PRESERVED  
**READY_FOR_F3-B1:** NO  
**PRODUCTION INCIDENT:** NO  

**STOP.**
