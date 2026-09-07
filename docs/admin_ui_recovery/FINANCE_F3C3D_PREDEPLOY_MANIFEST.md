# TOURi TAXI — FINANCE F3-C3D PRE-DEPLOY MANIFEST

**Captured:** 2026-09-06T00:27:00Z (approx)  
**Worktree:** `/Users/ventura/ara-ban-f3c1`  
**Branch:** `recovery/admin-finance-f3c3-one-agent-per-country`  
**HEAD:** `9d4ca3a744ccea73aae2332c3f4a0ba4057e3811`  
**Ancestors:** `e1d8c59` YES · `e9191a4` YES · `9d4ca3a` YES · `27fe504` YES  
**Worktree product status:** CLEAN  

**Firebase project:** `tutorial-multi-language-70gx4j`  
**Admin source:** `admin/Admi`  
**Functions source (ONLY):** `admin/Admi/firebase/functions`  
**Functions codebase:** `admin_functions`  

## Live Admin Hosting (before)

| Field | Value |
|---|---|
| Channel | live |
| Last release | 2026-09-04 11:27:30 |
| version.json | 1.0.15+2017 |
| build_provenance.git_commit | `358783a83977e608c35658601961a54e934a40e9` |

## Live Firestore rules (before)

| Field | Value |
|---|---|
| ruleset | `projects/.../rulesets/aeed881c-4d83-4891-bead-fcb614ab136c` |
| updateTime | 2026-08-29T13:17:12.266556Z |

## Target Functions (before)

| Export | Exists | Codebase | Region | Runtime | State | Hash |
|---|---|---|---|---|---|---|
| createPanelUser | YES | admin_functions | us-central1 | nodejs20 | ACTIVE | `7d4a7bc6…` |
| assignActiveCountryAgent | NO (new) | admin_functions | us-central1 | — | — | — |
| reassignActiveCountryAgent | NO (new) | admin_functions | us-central1 | — | — | — |
| deactivateCountryAgent | NO (new) | admin_functions | us-central1 | — | — | — |
| updateCountryAgentAssignment | NO (new) | admin_functions | us-central1 | — | — | — |

## Live assignment scan (Step 1)

| Metric | Value |
|---|---|
| 0 active | 4 |
| 1 active | 9 |
| 2+ | 0 |
| conflicts | 0 |
| existing locks | 0 |

## Admin Web isolation note

Full branch Admin ≠ live Admin (F1/F2 + Phase4D drift).  
C3D Admin deploy builds from live provenance `358783a` + **only** C3 Admin file patches:
- `edet_agent_widget.dart`
- `admin_user_creation.dart`
- `cloud_functions_client.dart` (C3 callables only)
