# TOURi TAXI — ADMIN UI V2.1 FINAL PRODUCTION INTEGRATION

**MODE:** Production promote (no UI redesign)  
**DATE:** 2026-09-07  

---

## Approved source

| Item | Value |
|------|-------|
| Human QA | **PASS** |
| Approved UI commit | `52f853a0ce9f85a9a66ef5f07ac9a87b149369cb` |
| Branch | `recovery/admin-ui-v21-polish` |
| Preview | https://tutorial-multi-language-70gx4j--admin-ui-v21-accountan-n012b5bb.web.app/admin/ |
| Production version | `1.0.17+2021` |

## Scope of promote

Includes the recovery lineage already Human-QA’d on preview:

- AUTH-NAV-P0
- Accountant finance read access
- Finance F1/F2/B1/B2 surfaces (read)
- Admin performance P1–P4C
- Admin UI V2 + V2.1 polish

**Explicitly excluded / unchanged this release:**

- UI redesign beyond approved V2.1
- P2B operational tables (not merged)
- Driver Edit deferred work
- Customer / Driver app UI
- New Firestore Rules / Functions deploys (already live for Accountant/C3; not re-fired unless required for hosting)

## Canonical production surfaces

| Surface | URL | Role |
|---------|-----|------|
| Render | https://touri-ban-1.onrender.com | Primary Admin SPA (`base-href=/`) |
| Firebase Hosting | https://tutorial-multi-language-70gx4j.web.app/admin/ | Admin SPA (`base-href=/admin/`) |
| GitHub `main` | `origin/main` | Canonical production source |

## Release steps (executed)

1. Stamp production version `1.0.17+2021` on recovery tip (no visual redesign)
2. Merge recovery → `main` (GitHub)
3. Build + deploy Firebase Hosting `/admin/`
4. Trigger Render rebuild from `main` (pinned Flutter 3.44.8 via `scripts/render_build.sh`)
5. Verify live `version.json` + `build_provenance.json`

## Safety

| Gate | Status |
|------|--------|
| Finance formulas | UNCHANGED |
| F1/F2/B1 semantics | UNCHANGED |
| Auth / RBAC | PRESERVED |
| Accountant write | DENY (Super Admin only) |
| P2B | NOT MERGED |
| Driver Edit | UNCHANGED |

STOP.


## Live verification

| Surface | Result |
|---------|--------|
| GitHub `main` | `66d88e7` (includes UI V2.1 + Render nudge) |
| Firebase Hosting `/admin/version.json` | **1.0.17+2021** LIVE |
| Approved UI commit on main | `52f853a` ancestor YES |
| Render | pending rebuild / Manual Deploy if auto-deploy inactive |

PR: https://github.com/tecalwaqdi/touri-ban/pull/2  
