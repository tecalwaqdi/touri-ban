# TOURi TAXI — ADMIN UI V2.1 FINAL PRODUCTION INTEGRATION

**MODE:** Production promote (no UI redesign)  
**DATE:** 2026-09-07  

---

## Approved source

| Item | Value |
|------|-------|
| Human QA | **PASS** |
| Approved UI commit | `52f853a0ce9f85a9a66ef5f07ac9a87b149369cb` |
| Production version | `1.0.17+2021` |
| Release stamp commit | `414eaab5bc5ac17364b1e9aba313157e2fa36e6e` |
| GitHub `main` tip | see live `origin/main` |

## Canonical production surfaces

| Surface | URL | Status |
|---------|-----|--------|
| GitHub `main` | https://github.com/tecalwaqdi/touri-ban | **MERGED** (PR #2 + nudge #3 + artifacts #4) |
| Firebase Hosting | https://tutorial-multi-language-70gx4j.web.app/admin/ | **LIVE 1.0.17+2021** |
| Render | https://touri-ban-1.onrender.com | **PENDING Manual Deploy** (auto-deploy did not fire; CLI needs `render login`) |

## Render Manual Deploy (required to finish)

Dashboard → Static Site **touri-ban-admin** / `touri-ban-1`:

1. Confirm branch = `main`
2. Build Command = `bash scripts/render_build.sh`
3. Root Directory = `admin/Admi`
4. Publish Directory = `build/web`
5. **Clear build cache & deploy** (Manual Deploy)
6. Verify `https://touri-ban-1.onrender.com/version.json` → `1.0.17` / `2021`

## Safety

| Gate | Status |
|------|--------|
| UI redesign during release | NONE |
| Finance formulas | UNCHANGED |
| F1/F2/B1 semantics | UNCHANGED |
| Auth / RBAC | PRESERVED |
| Accountant write | DENY |
| P2B | NOT MERGED |
| Driver Edit | UNCHANGED |
| Rules/Functions redeploy this step | NO (hosting + git only) |

## PRs

- https://github.com/tecalwaqdi/touri-ban/pull/2 — UI V2.1 → main
- https://github.com/tecalwaqdi/touri-ban/pull/3 — Render nudge
- https://github.com/tecalwaqdi/touri-ban/pull/4 — Firebase hosting artifact stamp

STOP.
