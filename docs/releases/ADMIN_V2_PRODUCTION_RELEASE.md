# TOURi TAXI — ADMIN V2 PRODUCTION RELEASE

**DATE:** 2026-09-07  
**MODE:** Release / integration only — no new features  

---

## A — Canonical source

| Item | Value |
|------|-------|
| CURRENT BRANCH | `release/admin-production-v2` |
| REMOTE MAIN / PRODUCTION BRANCH | `origin/main` |
| RENDER WATCHED BRANCH | **`main`** (confirmed by prior production pushes + Render build provenance history; Blueprint root `admin/Admi`) |
| CURRENT MAIN HEAD | `0365f8df8d60e0d5ea1e8b5b81c84b821102acbf` |
| RELEASE TAG | `admin-v2.0.0` |
| CURRENT PRODUCTION ADMIN VERSION (source) | `1.0.17+2021` |
| PREVIOUS RENDER LIVE | `1.0.15+2017` @ `1e2ccb1f65a3c8c69fffe5467ce40931a675ff68` |
| FIREBASE HOSTING LIVE | `1.0.17+2021` @ `414eaab` (already promoted) |

Render SPA uses `--base-href=/` → primary URL  
https://touri-ban-1.onrender.com/  
(`/admin/` also returns 200 via SPA rewrite but is not the Firebase-style `/admin/` base.)

---

## B — Ancestry map (vs `origin/main`)

| Approved work | Commit | Status |
|---------------|--------|--------|
| UI V2.1 | `52f853a` | **ALREADY INCLUDED** |
| Auth Navigation P0 | `b508587` | **ALREADY INCLUDED** |
| Accountant read access chain | `fea6445` | **ALREADY INCLUDED** |
| PERF-P4C | `d2d2216` | **ALREADY INCLUDED** |
| C3 one-active-agent | `27fe504` | **ALREADY INCLUDED** |
| P2B | `1266206` / `e6a26f8` | **MISSING (correct — DO NOT MERGE)** |

**MISSING APPROVED COMMITS:** none  
**CONFLICT RISK:** none (no additional merge required)  
**ALREADY INCLUDED:** full Accountant + Perf P1–P4C + Auth-nav + UI V2.1 lineage via PR #2  

---

## C–E — Integration strategy

Created `release/admin-production-v2` **from `origin/main`**.  
No cherry-picks required — approved work already on canonical main.

---

## F — Firestore Rules

| Item | Value |
|------|-------|
| REPO RULE SHA256 | `65fcb6beac7eedfddbf17b5bfe0bd290f742c4fc6f877e8b3c2277783cb5389f` |
| Matches approved Accountant patch | **YES** (`isFinance()` claim **or** `isAdminRule==5`) |
| Deployed ruleset | `a7926d10-e41b-45d3-863f-3575dde72062` (already live) |
| RULES DEPLOY | **NOT REQUIRED** |

---

## G — P2B

P2B commits **not** ancestors of `main`.  
Branch `recovery/admin-performance-p2b-operational-tables` remains separate.

---

## H — Driver Edit

No new Driver Edit deferred work imported in this release phase.  
Driver profile/activation files present only as prior approved recovery lineage already on main.  
**Driver Edit deferred:** not expanded in this phase.

---

## I — Test gate

| Gate | Result |
|------|--------|
| `flutter clean` / `pub get` | PASS |
| `flutter analyze` | **PASS** (0 errors; pre-existing infos/warnings) |
| Auth Navigation P0 | PASS |
| Accountant RBAC + Settlements R/W | PASS |
| Accountant Finance Read | PASS |
| F1 / F2 / B1 | PASS |
| P1 / P2A / P3 / P3F / P4A / P4B / P4C | PASS |
| UI V2.1 design tests | PASS |
| NEW FAILURES | **0** |
| `phase_8a_csv_errors_test` | **KNOWN_PRE_EXISTING_FINANCE_TEST_FAILURE** (unchanged; not fixed in release) |
| C3 node emulator suite | skipped here (needs local emulator :8080); C3 already production-deployed |

---

## J — Release build (`bash scripts/render_build.sh`)

| Item | Value |
|------|-------|
| BUILD | **PASS** |
| BUILD SIZE | ~52MB (`build/web`) |
| main.dart.js | 12,029,481 bytes · sha256 `fe55dd27a21ef0b0ced8c2240a0eae4efc2767671123d8cedf6ebf086f3d7fef` |
| version | `1.0.17+2021` |
| engine | `0cd610717b…` (Flutter 3.44.8 pin) |

---

## K — Release candidate preview

| Item | Value |
|------|-------|
| Channel | `admin-final-release-candidate` |
| URL | https://tutorial-multi-language-70gx4j--admin-final-release-ca-ma5mf6uq.web.app/admin/ |
| version.json | `1.0.17` / `2021` |

---

## Rollback

| Item | Value |
|------|-------|
| PREVIOUS RENDER SHA | `1e2ccb1f65a3c8c69fffe5467ce40931a675ff68` |
| PREVIOUS RENDER VERSION | `1.0.15+2017` |
| READY | **YES** — redeploy prior `main` commit / clear cache Manual Deploy to `1e2ccb1` tip of old live |

---

## T–W — Render status

| Item | Value |
|------|-------|
| Auto-deploy after main push | **Did not fire** (still serving 1.0.15+2017) |
| Render CLI | installed; requires interactive `render login` |
| Deploy Hook / API key | **not available** in this environment |
| FIREBASE HOSTING | **LIVE** `1.0.17+2021` |
| RENDER LIVE | **PENDING Manual Deploy** |

### Required Manual Deploy

Render Dashboard → Static Site **touri-ban-1** / `touri-ban-admin`:

1. Branch = `main`
2. Root = `admin/Admi`
3. Build = `bash scripts/render_build.sh`
4. Publish = `build/web`
5. **Clear build cache & Manual Deploy**
6. Verify `https://touri-ban-1.onrender.com/version.json` → `1.0.17` / `2021`
7. Hard reload + compare `build_provenance.json` `git_commit` ≠ `1e2ccb1…`

---

## FINAL

| Gate | Status |
|------|--------|
| SOURCE MAIN | integrated (`a17dc63`) |
| GITHUB | PUSHED (main already contains approved lineage) |
| RENDER | **NOT LIVE YET** (Manual Deploy required) |
| ADMIN_V2_PRODUCTION | **BLOCKED** on Render cutover only |
| ACCOUNTANT_READY_FOR_REAL_USER | **NO** until Render LIVE + human prod smoke |

STOP.
